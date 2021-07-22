unit uPluginAPIDLLHeader;

interface

uses
  SysUtils
  ,uPluginAPIHeader
  ,uCustomClasses
  ,PluginAPI_TLB
  ;

{ Types }

type
  TInitFunc = function(const ACoreIntf: IUnknown): boolean;
  TDoneFunc = procedure(const ACoreIntf: IUnknown);

  IIntfCollectionRegistration = interface(IUnknown)
  ['{29D7FD63-7FAE-4812-9A9C-C241925C2E32}']
    function RegisterAllImplementedInterfaces(AObj: TObject): boolean;
    function RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TStringArray): boolean; overload;
    function RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TGUIDArray): boolean; overload;
  end;

  TPluginAPIObject = class(TCheckedInterfacedObject, IAPIInitDone, IAPIInitDoneModuleEvents, IAPIModuleInfo, IAPIIntfCollection, IAPIWeakRefSupport, IDebugRefCount, IIntfCollectionRegistration)
  private
    FInterfaceCollectionArr: TWeakIntfCollectionArray;

    //IModuleInfo
    function get_ModuleGUID: TGUID; safecall;
    function get_ModuleVersion: LongWord; safecall;
    function get_ModuleName: WideString; safecall;
    function get_ModuleDescription: WideString; safecall;
    function get_ModuleAPIVersion: LongWord; safecall;

    //IAPIIntfCollection
    function get_IntfCollectionCount: Integer; safecall;

    class var FUnitsInitializedInitial: boolean;
    class var FUnitsInitializedFull: boolean;
  protected
    procedure ClearObject;

    //IDebugRefCount
    function GetDebugRefCount: Integer; safecall;

    //IModuleInfo
    property ModuleGUID: TGUID read get_ModuleGUID;
    property ModuleVersion: LongWord read get_ModuleVersion;
    property ModuleName: WideString read get_ModuleName;
    property ModuleDescription: WideString read get_ModuleDescription;
    property ModuleAPIVersion: LongWord read get_ModuleAPIVersion;

    //IAPIInitDoneModuleEvents
    procedure AfterPluginsInitialize(AReason: Integer); safecall;
    procedure BeforePluginsFinalize(AReason: Integer); safecall;

    //IAPIInitDone
    function Initialize(const ACoreIntf: IUnknown; AReason: Integer): WordBool; safecall;
    procedure Finalize(const ACoreIntf: IUnknown; AReason: Integer); safecall;
  public
    constructor Create;
    destructor Destroy; override;

    function RegisterAllImplementedInterfaces(AObj: TObject): boolean;
    function RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TStringArray): boolean; overload;
    function RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TGUIDArray): boolean; overload;

    //IAPIIntfCollection
    function GetIntfName(AIndex: Integer): WideString; safecall;
    function GetIntfByIndex(AIndex: Integer; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByName(const AName: WideString; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByGUID(AGUID: TGUID; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByIndexWeak(AIndex: Integer; out AIntf: IAPIWeakRef): WordBool; safecall;
    function GetIntfByNameWeak(const AName: WideString; out AIntf: IAPIWeakRef): WordBool; safecall;
    function GetIntfByGUIDWeak(AGUID: TGUID; out AIntf: IAPIWeakRef): WordBool; safecall;
    property IntfCollectionCount: Integer read get_IntfCollectionCount;

    class property UnitsInitializedInitial: boolean read FUnitsInitializedInitial write FUnitsInitializedInitial default false;
    class property UnitsInitializedFull: boolean read FUnitsInitializedFull write FUnitsInitializedFull default false;
  end;

{ Functions }

function HandleGetAPIException(AObj: TObject; AExc: Exception; AAddr: Pointer; var AResult: IUnknown; var RetVal: WordBool): HRESULT;
function GetAPI(const AIID: TGUID; out Intf: IUnknown; out RetVal: WordBool): HRESULT; stdcall;

{ Variables }

var
  //initialize and finalize functions for custom modules to rewrite
  GlobAPIDLLInitializeFunc: TInitFunc = nil;
  GlobAPIDLLFinalizeFunc: TDoneFunc = nil;
  GlobAPIDLLAfterInitializeFunc: TExportedFunctionReasonEvent = nil;
  GlobAPIDLLBeforeFinalizeFunc: TExportedFunctionReasonEvent = nil;
  //GetAPI funciton and events
  GlobGetAPIFunc: TExportedFunction = nil;
  GlobAPIObjCreateFunc: TExportedFunctionGUIDEvent = nil;
  GlobGetAPIOnEnter: TExportedFunctionGUIDEvent = nil;
  GlobGetAPIOnExit: TExportedFunctionGUIDEvent = nil;
  GlobGetAPIOnAfterModuleInit: TExportedFunctionGUIDEvent = nil;
  GlobGetAPIOnAfterCreateIntfObject: TExportedFunctionGUIDEvent = nil;
  GlobGetAPIOnExceptionEnter: TExportedFunctionExceptionEvent = nil;
  GlobGetAPIOnExceptionExit: TExportedFunctionExceptionEvent = nil;
  //global object for module interaction
  GlobAPIObjectIntf: IUnknown = nil;

implementation

uses
  ActiveX
  ,Rtti
  ,uInitSystem
  ,uPluginConsts
  ,uSafecallExceptions
  ;

{ TPluginAPIObject }

constructor TPluginAPIObject.Create;
begin
  inherited Create;
  SetName(Format('%s@[$%s] %s %s', [Self.UnitName, IntToHex(PtrUInt(Self), SizeOf(Pointer) * 2), ClassName, GUIDtoString(cModuleGUID)]));
  if UnitsInitializedInitial = false then
  begin
    ExecuteRegisteredInit(nil);
    UnitsInitializedInitial := true;
  end;

  Setlength(FInterfaceCollectionArr, 0);

  //RegisterAllImplementedInterfaces(Self);
  RegisterImplementedInterfaces(Self, [IAPIInitDone, IAPIModuleInfo, IAPIIntfCollection, IAPIInitDoneModuleEvents, IDebugRefCount]);
end;

destructor TPluginAPIObject.Destroy;
begin
  ClearObject;
  inherited;
end;

//IAPIInitDone
function TPluginAPIObject.Initialize(const ACoreIntf: IUnknown; AReason: Integer): WordBool; safecall;
begin
  Result := false;
  if ACoreIntf = nil then raise EPluginAPIInitializeError.Create(Format(rsAPIInitializeNoCoreInterface, [GUIDtoString(cModuleGUID)]));

  if UnitsInitializedFull = false then
  begin
    ExecuteRegisteredInit(ACoreIntf);
    UnitsInitializedInitial := true;
    UnitsInitializedFull := true;
  end;

  if Assigned(GlobAPIDLLInitializeFunc) then
    if GlobAPIDLLInitializeFunc(ACoreIntf) = false then exit;

  Result := true;
end;

procedure TPluginAPIObject.Finalize(const ACoreIntf: IUnknown; AReason: Integer); safecall;
begin
  if UnitsInitializedFull = true then
  begin
    ExecuteRegisteredDone(ACoreIntf);
    UnitsInitializedInitial := false;
    UnitsInitializedFull := false;
  end;

  if Assigned(GlobAPIDLLFinalizeFunc) then
    GlobAPIDLLFinalizeFunc(ACoreIntf);

  ClearObject;

  GlobAPIObjectIntf := nil;
end;

procedure TPluginAPIObject.AfterPluginsInitialize(AReason: Integer); safecall;
begin
  if Assigned(GlobAPIDLLAfterInitializeFunc) then GlobAPIDLLAfterInitializeFunc(AReason);
end;

procedure TPluginAPIObject.BeforePluginsFinalize(AReason: Integer); safecall;
begin
  if Assigned(GlobAPIDLLBeforeFinalizeFunc) then GlobAPIDLLBeforeFinalizeFunc(AReason);
end;

function TPluginAPIObject.GetDebugRefCount: Integer; safecall;
begin
  Result := RefCount;
end;

procedure TPluginAPIObject.ClearObject;
var i: integer;
begin
  for i := Low(FInterfaceCollectionArr) to High(FInterfaceCollectionArr) do
    FInterfaceCollectionArr[i].InterfaceInstance := nil;
  Setlength(FInterfaceCollectionArr, 0);
end;

//IModuleInfo
function TPluginAPIObject.get_ModuleGUID: TGUID; safecall;
begin
  Result := cModuleGUID;
end;

function TPluginAPIObject.get_ModuleVersion: LongWord; safecall;
begin
  Result := EncodeModuleVersion(cModuleVerMajor, cModuleVerMinor, cModuleVerRelease, cModuleVerBuild);
end;

function TPluginAPIObject.get_ModuleName: WideString; safecall;
begin
  Result := cModuleName;
end;

function TPluginAPIObject.get_ModuleDescription: WideString; safecall;
begin
  Result := cModuleDesc;
end;

function TPluginAPIObject.get_ModuleAPIVersion: LongWord; safecall;
begin
  Result := EncodeModuleVersion(PluginAPIMajorVersion, PluginAPIMinorVersion, 0, 0);
end;

function TPluginAPIObject.RegisterAllImplementedInterfaces(AObj: TObject): boolean;
var InterfaceArr: TNameGUIDArray;
i, j: integer;
duplicate: boolean;
temp: IAPIWeakRefSupport;
begin
  Result := false;
  GetImplementedInterfaces(AObj.ClassType, InterfaceArr, true);
  if Length(InterfaceArr) = 0 then exit;
  if Supports(AObj, IAPIWeakRefSupport, temp) = false then
  begin
    temp := nil;
    exit;
  end;

  //check for duplicates and add
  for i := Low(InterfaceArr) to High(InterfaceArr) do
  begin
    duplicate := false;
    for j := Low(FInterfaceCollectionArr) to High(FInterfaceCollectionArr) do
      if FInterfaceCollectionArr[j].InterfaceName = InterfaceArr[i].Name then
      begin
        duplicate := true;
        break;
      end;

    if duplicate = false then
    begin
      j := Length(FInterfaceCollectionArr);
      Setlength(FInterfaceCollectionArr, j+1);
      FInterfaceCollectionArr[j].InterfaceName := InterfaceArr[i].Name;
      //AObj.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
      temp.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
    end;
  end;

  SetLength(InterfaceArr, 0);
  temp := nil;

  Result := true;
end;

function TPluginAPIObject.RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TStringArray): boolean;
var InterfaceArr: TNameGUIDArray;
i, j: integer;
duplicate: boolean;
temp: IAPIWeakRefSupport;
begin
  Result := false;
  GetImplementedInterfaces(AObj.ClassType, InterfaceArr, true);
  if Length(InterfaceArr) = 0 then exit;
  if Supports(AObj, IAPIWeakRefSupport, temp) = false then
  begin
    temp := nil;
    exit;
  end;

  //check wich interfaces should be added and delete rest
  i := Low(InterfaceArr);
  while i <= High(InterfaceArr) do
  begin
    duplicate := false;
    for j := Low(AIntfList) to High(AIntfList) do
      if InterfaceArr[i].Name = AIntfList[j] then
      begin
        duplicate := true;
        break;
      end;
    if duplicate = false then
    begin
      for j := i+1 to High(InterfaceArr) do
      begin
        InterfaceArr[j-1].GUID := InterfaceArr[j].GUID;
        InterfaceArr[j-1].Name := InterfaceArr[j].Name;
      end;
      Setlength(InterfaceArr, Length(InterfaceArr)-1);
      continue;
    end;
    inc(i);
  end;

  //check for duplicates and add
  for i := Low(InterfaceArr) to High(InterfaceArr) do
  begin
    duplicate := false;
    for j := Low(FInterfaceCollectionArr) to High(FInterfaceCollectionArr) do
      if FInterfaceCollectionArr[j].InterfaceName = InterfaceArr[i].Name then
      begin
        duplicate := true;
        break;
      end;

    if duplicate = false then
    begin
      j := Length(FInterfaceCollectionArr);
      Setlength(FInterfaceCollectionArr, j+1);
      FInterfaceCollectionArr[j].InterfaceName := InterfaceArr[i].Name;
      //AObj.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
      temp.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
    end;
  end;

  SetLength(InterfaceArr, 0);
  temp := nil;

  Result := true;
end;

function TPluginAPIObject.RegisterImplementedInterfaces(AObj: TObject; const AIntfList: TGUIDArray): boolean;
var InterfaceArr: TNameGUIDArray;
i, j: integer;
duplicate: boolean;
temp: IAPIWeakRefSupport;
begin
  Result := false;
  GetImplementedInterfaces(AObj.ClassType, InterfaceArr, true);
  if Length(InterfaceArr) = 0 then exit;
  if Supports(AObj, IAPIWeakRefSupport, temp) = false then
  begin
    temp := nil;
    exit;
  end;

  //check witch interfaces should be added and delete rest
  i := Low(InterfaceArr);
  while i <= High(InterfaceArr) do
  begin
    duplicate := false;
    for j := Low(AIntfList) to High(AIntfList) do
      if InterfaceArr[i].GUID = AIntfList[j] then
      begin
        duplicate := true;
        break;
      end;
    if duplicate = false then
    begin
      for j := i+1 to High(InterfaceArr) do
      begin
        InterfaceArr[j-1].GUID := InterfaceArr[j].GUID;
        InterfaceArr[j-1].Name := InterfaceArr[j].Name;
      end;
      Setlength(InterfaceArr, Length(InterfaceArr)-1);
      continue;
    end;
    inc(i);
  end;

  //check for duplicates and add
  for i := Low(InterfaceArr) to High(InterfaceArr) do
  begin
    duplicate := false;
    for j := Low(FInterfaceCollectionArr) to High(FInterfaceCollectionArr) do
      if FInterfaceCollectionArr[j].InterfaceName = InterfaceArr[i].Name then
      begin
        duplicate := true;
        break;
      end;

    if duplicate = false then
    begin
      j := Length(FInterfaceCollectionArr);
      Setlength(FInterfaceCollectionArr, j+1);
      FInterfaceCollectionArr[j].InterfaceName := InterfaceArr[i].Name;
      //AObj.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
      temp.GetWeakRef(FInterfaceCollectionArr[j].InterfaceInstance);
    end;
  end;

  SetLength(InterfaceArr, 0);
  temp := nil;

  Result := true;
end;

//IAPIIntfCollection
function TPluginAPIObject.get_IntfCollectionCount: Integer; safecall;
begin
  Result := Length(FInterfaceCollectionArr);
end;

function TPluginAPIObject.GetIntfName(AIndex: Integer): WideString; safecall;
begin
  Result := '';
  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  if (AIndex < Low(FInterfaceCollectionArr))or(AIndex > High(FInterfaceCollectionArr)) then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBounds, [AIndex]));

  Result := FInterfaceCollectionArr[AIndex].InterfaceName;
end;

function TPluginAPIObject.GetIntfByIndex(AIndex: Integer; out AIntf: IUnknownWorkaround): WordBool; safecall;
var TempWeak: IAPIWeakRef;
begin
  Result := false;
  AIntf := nil;

  if GetIntfByIndexWeak(AIndex, TempWeak) = false then exit;

  Result := TempWeak.GetRef(AIntf);
end;

function TPluginAPIObject.GetIntfByName(const AName: WideString; out AIntf: IUnknownWorkaround): WordBool; safecall;
var TempWeak: IAPIWeakRef;
begin
  Result := false;
  AIntf := nil;

  if GetIntfByNameWeak(AName, TempWeak) = false then exit;

  Result := TempWeak.GetRef(AIntf);
end;

function TPluginAPIObject.GetIntfByGUID(AGUID: TGUID; out AIntf: IUnknownWorkaround): WordBool; safecall;
var TempWeak: IAPIWeakRef;
begin
  Result := false;
  AIntf := nil;

  if GetIntfByGUIDWeak(AGUID, TempWeak) = false then exit;

  Result := TempWeak.GetRef(AIntf);
end;

function TPluginAPIObject.GetIntfByIndexWeak(AIndex: Integer; out AIntf: IAPIWeakRef): WordBool; safecall;
begin
  Result := false;
  AIntf := nil;

  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  if (AIndex < Low(FInterfaceCollectionArr))or(AIndex > High(FInterfaceCollectionArr)) then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBounds, [AIndex]));

  AIntf := FInterfaceCollectionArr[AIndex].InterfaceInstance;
  Result := true;
end;

function TPluginAPIObject.GetIntfByNameWeak(const AName: WideString; out AIntf: IAPIWeakRef): WordBool; safecall;
var i: integer;
begin
  Result := false;
  AIntf := nil;

  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  for i := Low(FInterfaceCollectionArr) to High(FInterfaceCollectionArr) do
    if FInterfaceCollectionArr[i].InterfaceName = AName then
    begin
      AIntf := FInterfaceCollectionArr[i].InterfaceInstance;
      Result := true;
      exit;
    end;
end;

function TPluginAPIObject.GetIntfByGUIDWeak(AGUID: TGUID; out AIntf: IAPIWeakRef): WordBool; safecall;
var Context: TRttiContext;
ItemType: TRttiType;
IntfName: string;
begin
  Result := false;
  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  //look for GUID in Rtti
  Context := TRttiContext.Create;
  IntfName := '';
  try
    for ItemType in Context.GetTypes do
      if ItemType is TRTTIInterfaceType then
        if TRTTIInterfaceType(ItemType).GUID = AGUID then
        begin
          IntfName := ItemType.Name;
          break;
        end;
  finally
    Context.Free;
  end;
  //return by name
  Result := GetIntfByNameWeak(IntfName, AIntf);
end;

{ Functions }

function HandleGetAPIException(AObj: TObject; AExc: Exception; AAddr: Pointer; var AResult: IUnknown; var RetVal: WordBool): HRESULT;
begin
  AResult := nil;
  RetVal := false;
  ActiveX.SetErrorInfo(0, nil);
  Result := uSafecallExceptions.CustomHandleSafeCallException(AObj, AExc, AAddr);
end;

procedure GlobalAPIObjectCreate(const AIID: TGUID);
begin
  GlobAPIObjectIntf := TPluginAPIObject.Create;
end;

function GetAPIWrapped(const AIID: TGUID; out Intf: IUnknown; out RetVal: WordBool): HRESULT; stdcall;
var IntfCollectionTemp: IAPIIntfCollection;
begin
  try
    Result := E_UNEXPECTED;
    Intf := nil;
    RetVal := false;

    if Assigned(GlobGetAPIOnEnter) then GlobGetAPIOnEnter(AIID);

    if TPluginAPIObject.UnitsInitializedInitial = false then
    begin
      ExecuteRegisteredInit(nil);
      TPluginAPIObject.UnitsInitializedInitial := true;
      if Assigned(GlobGetAPIOnAfterModuleInit) then GlobGetAPIOnAfterModuleInit(AIID);
    end;

    if GlobAPIObjectIntf = nil then
    begin
      if Assigned(GlobAPIObjCreateFunc) then
        GlobAPIObjCreateFunc(AIID)
      else
        GlobalAPIObjectCreate(AIID);
      if Assigned(GlobGetAPIOnAfterCreateIntfObject) then GlobGetAPIOnAfterCreateIntfObject(AIID);
    end;

    if GlobAPIObjectIntf = nil then raise EPluginAPIInitializeError.Create(Format(rsAPIInitializeNoAPIObject, []));

    if Supports(GlobAPIObjectIntf, IAPIIntfCollection, IntfCollectionTemp) = false then
      raise EPluginAPIInterfaceNotSupported.Create(Format(rsAPIInterfaceNotSupported, [GUIDtoString(AIID)]));

    if IntfCollectionTemp.GetIntfByGUID(AIID, Intf) = false then
      raise EPluginAPIInterfaceNotSupported.Create(Format(rsAPIInterfaceNotSupported, [GUIDtoString(AIID)]));

    IntfCollectionTemp := nil;

    RetVal := true;
    Result := S_OK;

    if Assigned(GlobGetAPIOnExit) then GlobGetAPIOnExit(AIID);
  except
    on E: Exception do
    begin
      if Assigned(GlobGetAPIOnExceptionEnter) then GlobGetAPIOnExceptionEnter(AIID, E.ClassName);

      if GlobAPIObjectIntf <> nil then
        Result := HandleGetAPIException((GlobAPIObjectIntf as TPluginAPIObject), E, ExceptAddr, Intf, RetVal)
      else
        Result := HandleGetAPIException(nil, E, ExceptAddr, Intf, RetVal);

      if Assigned(GlobGetAPIOnExceptionExit) then GlobGetAPIOnExceptionExit(AIID, E.ClassName);
    end;
  end;
end;

function GetAPI(const AIID: TGUID; out Intf: IUnknown; out RetVal: WordBool): HRESULT; stdcall;
begin
  if Assigned(GlobGetAPIFunc) then
    Result := GlobGetAPIFunc(AIID, Intf, RetVal)
  else
    Result := GetAPIWrapped(AIID, Intf, RetVal);
end;

initialization
  GlobGetAPIFunc := GetAPIWrapped;
  GlobAPIObjCreateFunc := GlobalAPIObjectCreate;

end.
