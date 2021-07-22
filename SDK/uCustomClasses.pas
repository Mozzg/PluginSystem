unit uCustomClasses;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

uses
  System.Win.ComObj
  ,SysUtils
  ,PluginAPI_TLB
  ;

type
  {$IFNDEF UNICODE}
  NativeInt = Integer;
  NativeUInt = Cardinal;
  {$ENDIF}

  {$IFDEF UNICODE}
  PtrUInt = NativeUInt;
  PtrInt = NativeInt;
  {$ELSE}
  PtrUInt = Cardinal;
  PtrInt = Integer;
  {$ENDIF}

{ TCheckedInterfacedObject }

  TDebugName = string[99];

  TCheckedInterfacedObject = class(TInterfacedObject, IInterface, IAPIWeakRefSupport)
  private
    FName: TDebugName;
    FWeakRef: IAPIWeakRef;

    function GetRefCount: Integer;
  protected
    procedure SetName(const AName: String);
    //IInterface
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure BeforeDestruction; override;
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
    //IAPIWeakRefSupport
    procedure GetWeakRef(out ReturnValue: IAPIWeakRef); safecall;

    property RefCount: Integer read GetRefCount;
    property DebugName: TDebugName read FName;
  end;

{ TCheckedInterfacedObjectNoCount }

  TCheckedInterfacedObjectNoCount = class(TCheckedInterfacedObject, IInterface, IAPIWeakRefSupport)
  protected
    function _AddRef: Integer; override; stdcall;
    function _Release: Integer; override; stdcall;
  end;

{ TWeakRef }

  TWeakRef = class(TCheckedInterfacedObjectNoCount, IAPIWeakRef)
  private
    FOwner: Pointer;
  public
    constructor Create(AOwner: Pointer);
    destructor Destroy; override;

    procedure _Clean;
    //IAPIWeakRef
    function IsWeakRefAlive: WordBool; safecall;
    function GetRef(out Referance: IUnknownWorkaround): WordBool; safecall;
  end;

{ Exceptions }

  EBaseCustomOleSysError = class(EOleSysError)
  //EBaseCustomOleSysError = class(EOleException)
  protected
    function GetDefaultCode: HRESULT;
  public
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    constructor CreateRes(Ident: Integer); overload;
    constructor CreateRes(ResStringRec: PResStringRec); overload;
    constructor CreateResFmt(Ident: Integer; const Args: array of const); overload;
    constructor CreateResFmt(ResStringRec: PResStringRec; const Args: array of const); overload;
    constructor CreateHelp(const Msg: string; AHelpContext: Integer);
    constructor CreateFmtHelp(const Msg: string; const Args: array of const; AHelpContext: Integer);
    constructor CreateResHelp(Ident: Integer; AHelpContext: Integer); overload;
    constructor CreateResHelp(ResStringRec: PResStringRec; AHelpContext: Integer); overload;
    constructor CreateResFmtHelp(ResStringRec: PResStringRec; const Args: array of const; AHelpContext: Integer); overload;
    constructor CreateResFmtHelp(Ident: Integer; const Args: array of const; AHelpContext: Integer); overload;
  end;

  EBaseCustomException = class(EBaseCustomOleSysError)
  private
    FSource: string;
    FHelpFile: string;
    FWrappedException: string;
  public
    constructor Create(const AMessage: string); overload;
    constructor Create(const AMessage: string; AErrorCode: HRESULT; const ASource, AHelpFile: string; AHelpContext: Integer; AWrappedException: ExceptClass = nil); overload;
    destructor Destroy; override;
    property Source: string read FSource write FSource;
    property HelpFile: string read FHelpFile write FHelpFile;
    property WrappedException: string read FWrappedException;
  end;

  EUnregisteredException = class(EBaseCustomException);

  ECheckedInterfacedObjectError = class(EBaseCustomException);
    ECheckedInterfacedObjectDeleteError = class(ECheckedInterfacedObjectError);
    ECheckedInterfacedObjectDoubleFreeError = class(ECheckedInterfacedObjectError);
    ECheckedInterfacedObjectUseDeletedError = class(ECheckedInterfacedObjectError);

  EPluginAPIError = class(EBaseCustomException);
    EPluginAPIIndexOutOfBounds = class(EPluginAPIError);
    EPluginAPIInterfaceNotSupported = class(EPluginAPIError);
    EPluginAPIInitializeError = class(EPluginAPIError);

{ Functions }

function GenerateWeakRef(const AOwner: IUnknown): TWeakRef;

{ Custom }

//must be global
resourcestring
  rsAPIOutOfBounds = 'Попытка получить интерфейс с неправильным индексом, индекс: %d';
  rsAPIOutOfBoundsEmpty = 'Попытка получить интерфейс при пустом списке';
  rsAPIInterfaceNotSupported = 'Интерфейс %s не поддерживается';
  rsAPIInitializeNoCoreInterface = 'Отсутствует интерфейс ядра при инициализации модуля %s';
  rsAPIInitializeNoAPIObject = 'Отсутствует объект для взаимодействия модуля';

implementation

uses
  Winapi.ActiveX
  ,Winapi.Windows
  ,uHRESULTCodeHelper
  ,uSafecallExceptions
  ,uInitSystem
  ;

resourcestring
  rsInvalidDelete  = 'Попытка удалить объект %s при активной интерфейсной ссылке; счётчик ссылок: %d';
  rsDoubleFree     = 'Попытка повторно удалить уже удалённый объект %s';
  rsUseDeleted     = 'Попытка использовать уже удалённый объект %s';

var
  uCustomClassesInitialized: boolean = false;
  WeakRefArr: array of TWeakRef;

{ TCheckedInterfacedObject }

constructor TCheckedInterfacedObject.Create;
begin
  FName := TDebugName(Format('%s@[$%s] %s', [Self.UnitName, IntToHex(PtrUInt(Self), SizeOf(Pointer) * 2), ClassName]));
  inherited;
end;

destructor TCheckedInterfacedObject.Destroy;
begin
  if FWeakRef <> nil then
  begin
    (FWeakRef as TWeakRef)._Clean;
    FWeakRef := nil;
  end;
end;

procedure TCheckedInterfacedObject.SetName(const AName: String);
begin
  FillChar(FName, SizeOf(FName), 0);
  FName := TDebugName(AName);
end;

procedure TCheckedInterfacedObject.BeforeDestruction;
begin
  if FRefCount < 0 then
    raise ECheckedInterfacedObjectDoubleFreeError.CreateFmt(rsDoubleFree, [String(FName)])
  else
  if FRefCount <> 0 then
    raise ECheckedInterfacedObjectDeleteError.CreateFmt(rsInvalidDelete, [String(FName), FRefCount]);
  inherited;
  FRefCount := -1;
end;

function TCheckedInterfacedObject.GetRefCount: Integer;
begin
  if FRefCount < 0 then
    Result := 0
  else
    Result := FRefCount;
end;

function TCheckedInterfacedObject._AddRef: Integer;
begin
  if FRefCount < 0 then
    raise ECheckedInterfacedObjectUseDeletedError.CreateFmt(rsUseDeleted, [String(FName)]);
  Result := InterlockedIncrement(FRefCount);
end;

function TCheckedInterfacedObject._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

function TCheckedInterfacedObject.SafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer): HResult;
begin
  Result := CustomHandleSafeCallException(Self, ExceptObject, ExceptAddr);
end;

procedure TCheckedInterfacedObject.GetWeakRef(out ReturnValue: IAPIWeakRef); safecall;
begin
  if FWeakRef = nil then
    FWeakRef := GenerateWeakRef(Self);
  ReturnValue := FWeakRef;
end;

{ TCheckedInterfacedObjectNoCount }

function TCheckedInterfacedObjectNoCount._AddRef: integer;
begin
  Result := -1;
end;

function TCheckedInterfacedObjectNoCount._Release: integer;
begin
  Result := -1;
end;

{ TWeakRef }

constructor TWeakRef.Create(AOwner: Pointer);
begin
  inherited Create;

  FOwner := AOwner;
end;

destructor TWeakRef.Destroy;
begin
  inherited;
end;

procedure TWeakRef._Clean;
begin
  FOwner := nil;
end;

//IAPIWeakRef
function TWeakRef.IsWeakRefAlive: WordBool; safecall;
begin
  Result := Assigned(FOwner);
end;

function TWeakRef.GetRef(out Referance: IUnknownWorkaround): WordBool; safecall;
begin
  Result := false;
  Referance := nil;

  if IsWeakRefAlive = true then
  begin
    Referance := IUnknown(FOwner);
    Result := true;
  end;
end;

{ EBaseException }

function EBaseCustomOleSysError.GetDefaultCode: HRESULT;
begin
  Result := MakeResult(SEVERITY_ERROR, FACILITY_ITF, GetExceptionCode(ClassName));
end;

constructor EBaseCustomOleSysError.Create(const Msg: string);
begin
  inherited Create(Msg, GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateFmt(const Msg: string; const Args: array of const);
begin
  inherited Create(Format(Msg, Args), GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateFmtHelp(const Msg: string; const Args: array of const; AHelpContext: Integer);
begin
  inherited Create(Format(Msg, Args), GetDefaultCode, AHelpContext);
end;

constructor EBaseCustomOleSysError.CreateHelp(const Msg: string; AHelpContext: Integer);
begin
  inherited Create(Msg, GetDefaultCode, AHelpContext);
end;

constructor EBaseCustomOleSysError.CreateRes(Ident: Integer);
begin
  inherited Create(LoadStr(Ident), GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateRes(ResStringRec: PResStringRec);
begin
  inherited Create(LoadResString(ResStringRec), GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateResFmt(Ident: Integer; const Args: array of const);
begin
  inherited Create(Format(LoadStr(Ident), Args), GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateResFmt(ResStringRec: PResStringRec; const Args: array of const);
begin
  inherited Create(Format(LoadResString(ResStringRec), Args), GetDefaultCode, 0);
end;

constructor EBaseCustomOleSysError.CreateResFmtHelp(ResStringRec: PResStringRec; const Args: array of const; AHelpContext: Integer);
begin
  inherited Create(Format(LoadResString(ResStringRec), Args), GetDefaultCode, AHelpContext);
end;

constructor EBaseCustomOleSysError.CreateResFmtHelp(Ident: Integer; const Args: array of const; AHelpContext: Integer);
begin
  inherited Create(Format(LoadStr(Ident), Args), GetDefaultCode, AHelpContext);
end;

constructor EBaseCustomOleSysError.CreateResHelp(Ident, AHelpContext: Integer);
begin
  inherited Create(LoadStr(Ident), GetDefaultCode, AHelpContext);
end;

constructor EBaseCustomOleSysError.CreateResHelp(ResStringRec: PResStringRec; AHelpContext: Integer);
begin
  inherited Create(LoadResString(ResStringRec), GetDefaultCode, AHelpContext);
end;

{ EBaseCustomException }

constructor EBaseCustomException.Create(const AMessage: string; AErrorCode: HRESULT; const ASource, AHelpFile: string; AHelpContext: Integer; AWrappedException: ExceptClass = nil);
begin
  inherited CreateHelp(AMessage, AHelpContext);
  ErrorCode := AErrorCode;
  FSource := ASource;
  FHelpFile := AHelpFile;
  if AWrappedException <> nil then
    FWrappedException := AWrappedException.ClassName;
end;

constructor EBaseCustomException.Create(const AMessage: string);
begin
  Create(AMessage, GetDefaultCode, '', '', 0);
end;

destructor EBaseCustomException.Destroy;
begin
  inherited;
end;

{ Functions }

function GenerateWeakRef(const AOwner: IUnknown): TWeakRef;
var i: integer;
temp_p: Pointer;
begin
  temp_p := AOwner;

  i := Length(WeakRefArr);
  SetLength(WeakRefArr, i+1);
  WeakRefArr[i] := TWeakRef.Create(temp_p);
  Result := WeakRefArr[i];
end;

procedure CleanWeakRefArray;
var i: integer;
begin
  for i := Low(WeakRefArr) to High(WeakRefArr) do
  begin
    WeakRefArr[i]._Clean;
    WeakRefArr[i].Free;
    WeakRefArr[i] := nil;
  end;
  SetLength(WeakRefArr, 0);
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if uCustomClassesInitialized = false then
  begin
    RegisterExceptionCode(E_C_UnregisteredException, EUnregisteredException);

    RegisterExceptionCode(E_C_BaseCustomException, EBaseCustomException);
    RegisterExceptionCode(E_C_BaseCustomOleSysError, EBaseCustomOleSysError);
    RegisterExceptionCode(E_C_CheckedInterfacedObjectError, ECheckedInterfacedObjectError);
    RegisterExceptionCode(E_C_CheckedInterfacedObjectDeleteError, ECheckedInterfacedObjectDeleteError);
    RegisterExceptionCode(E_C_CheckedInterfacedObjectDoubleFreeError, ECheckedInterfacedObjectDoubleFreeError);
    RegisterExceptionCode(E_C_CheckedInterfacedObjectUseDeletedError, ECheckedInterfacedObjectUseDeletedError);

    RegisterExceptionCode(E_C_PluginAPIError, EPluginAPIError);
    RegisterExceptionCode(E_C_PluginAPIIndexOutOfBounds, EPluginAPIIndexOutOfBounds);
    RegisterExceptionCode(E_C_PluginAPIInterfaceNotSupported, EPluginAPIInterfaceNotSupported);
    RegisterExceptionCode(E_C_PluginAPIInitializeError, EPluginAPIInitializeError);

    uCustomClassesInitialized := true;
  end;
end;

procedure DoneModule(const AOptional: IUnknown);
begin
  CleanWeakRefArray;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, nil)
  else
    InitModule(nil);

finalization
  //if System.IsLibrary = false then
  DoneModule(nil);

end.
