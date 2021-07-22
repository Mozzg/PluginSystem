unit uHRESULTCodeHelper;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

uses
  SysUtils;

procedure RegisterExceptionCode(Code: Word; ExcClass: ExceptClass);
function GetExceptionCode(const ExceptionName: string): Word; overload;
function GetExceptionCode(ExcClass: ExceptClass): Word; overload;
function GetExceptionClass(Code: Word): ExceptClass;

implementation

uses
  Classes
  ,PluginAPI_TLB
  ,uInitSystem
  ;

type
  TNameString = string[99];
  THResultCodeRec = record
    HResult: Word;
    ExceptionName: TNameString;
    ExceptionClass: ExceptClass;
  end;

var
  HResultCodeArray: array of THResultCodeRec;
  uHRESULTCodeHelperInitialized: boolean = false;

procedure RegisterExceptionCode(Code: Word; ExcClass: ExceptClass);
var i: integer;
begin
  i := Length(HResultCodeArray);
  SetLength(HResultCodeArray, i+1);
  HResultCodeArray[i].HResult := Code;
  HResultCodeArray[i].ExceptionName := ExcClass.ClassName;
  HResultCodeArray[i].ExceptionClass := ExcClass;
end;

function GetExceptionCode(const ExceptionName: string): Word;
var i: integer;
begin
  Result := E_C_UnregisteredException;
  for i := 0 to Length(HResultCodeArray)-1 do
    if ExceptionName = string(HResultCodeArray[i].ExceptionName) then
    begin
      Result := HResultCodeArray[i].HResult;
      Break;
    end;
end;

function GetExceptionCode(ExcClass: ExceptClass): Word;
var i: integer;
begin
  Result := E_C_UnregisteredException;
  for i := 0 to Length(HResultCodeArray)-1 do
    if ExcClass.ClassName = HResultCodeArray[i].ExceptionClass.ClassName then
    begin
      Result := HResultCodeArray[i].HResult;
      Break;
    end;
end;

function GetExceptionClass(Code: Word): ExceptClass;
var i: integer;
begin
  Result := Exception;
  for i := 0 to Length(HResultCodeArray)-1 do
    if Code = HResultCodeArray[i].HResult then
    begin
      Result := HResultCodeArray[i].ExceptionClass;
      Break;
    end;
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if uHRESULTCodeHelperInitialized = false then
  begin
    //RegisterExceptionCode(E_C_UnregisteredException,
    RegisterExceptionCode(E_C_AbstractError, EAbstractError);
    RegisterExceptionCode(E_C_ArgumentException, EArgumentException);
    RegisterExceptionCode(E_C_ArgumentNilException, EArgumentNilException);
    RegisterExceptionCode(E_C_ArgumentOutOfRangeException, EArgumentOutOfRangeException);
    RegisterExceptionCode(E_C_BitsError, EBitsError);
    RegisterExceptionCode(E_C_ClassNotFound, EClassNotFound);
    //RegisterExceptionCode(E_C_CodesetConversion, ECodesetConversion);
    RegisterExceptionCode(E_C_ComponentError, EComponentError);
    RegisterExceptionCode(E_C_ConvertError, EConvertError);
    RegisterExceptionCode(E_C_DirectoryNotFoundException, EDirectoryNotFoundException);
    RegisterExceptionCode(E_C_External, EExternal);
    RegisterExceptionCode(E_C_ExternalException, EExternalException);
    RegisterExceptionCode(E_C_FCreateError, EFCreateError);
    RegisterExceptionCode(E_C_FileNotFoundException, EFileNotFoundException);
    RegisterExceptionCode(E_C_FilerError, EFilerError);
    RegisterExceptionCode(E_C_FileStreamError, EFileStreamError);
    RegisterExceptionCode(E_C_FOpenError, EFOpenError);
    RegisterExceptionCode(E_C_HeapException, EHeapException);
    RegisterExceptionCode(E_C_InOutError, EInOutError);
    RegisterExceptionCode(E_C_IntError, EIntError);
    RegisterExceptionCode(E_C_IntfCastError, EIntfCastError);
    RegisterExceptionCode(E_C_InvalidCast, EInvalidCast);
    RegisterExceptionCode(E_C_InvalidContainer, EInvalidContainer);
    RegisterExceptionCode(E_C_InvalidImage, EInvalidImage);
    RegisterExceptionCode(E_C_InvalidInsert, EInvalidInsert);
    RegisterExceptionCode(E_C_InvalidOperation, EInvalidOperation);
    RegisterExceptionCode(E_C_InvalidOpException, EInvalidOpException);
    RegisterExceptionCode(E_C_InvalidPointer, EInvalidPointer);
    RegisterExceptionCode(E_C_ListError, EListError);
    RegisterExceptionCode(E_C_MathError, EMathError);
    RegisterExceptionCode(E_C_MethodNotFound, EMethodNotFound);
    RegisterExceptionCode(E_C_Monitor, EMonitor);
    RegisterExceptionCode(E_C_MonitorLockException, EMonitorLockException);
    RegisterExceptionCode(E_C_NoConstructException, ENoConstructException);
    RegisterExceptionCode(E_C_NoMonitorSupportException, ENoMonitorSupportException);
    RegisterExceptionCode(E_C_OutOfResources, EOutOfResources);
    RegisterExceptionCode(E_C_PackageError, EPackageError);
    RegisterExceptionCode(E_C_ParserError, EParserError);
    RegisterExceptionCode(E_C_PathTooLongException, EPathTooLongException);
    RegisterExceptionCode(E_C_ProgrammerNotFound, EProgrammerNotFound);
    RegisterExceptionCode(E_C_PropReadOnly, EPropReadOnly);
    RegisterExceptionCode(E_C_PropWriteOnly, EPropWriteOnly);
    //RegisterExceptionCode(E_C_Quit, EQuit);
    RegisterExceptionCode(E_C_RangeError, ERangeError);
    RegisterExceptionCode(E_C_ReadError, EReadError);
    RegisterExceptionCode(E_C_ResNotFound, EResNotFound);
    RegisterExceptionCode(E_C_StreamError, EStreamError);
    RegisterExceptionCode(E_C_StringListError, EStringListError);
    RegisterExceptionCode(E_C_VariantError, EVariantError);
    RegisterExceptionCode(E_C_WriteError, EWriteError);
    uHRESULTCodeHelperInitialized := true;
  end;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, nil)
  else
    InitModule(nil);

end.
