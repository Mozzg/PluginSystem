unit uSafecallExceptions;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

function CustomHandleSafeCallException(Caller: TObject; ExceptObj: TObject; ErrorAddr: Pointer): HRESULT;

implementation

uses
  SysUtils
  ,Winapi.Windows
  ,Winapi.ActiveX
  ,System.Win.ComObj
  ,VarUtils
  ,uHRESULTCodeHelper
  ,PluginAPI_TLB
  ,uCustomClasses
  ,uInitSystem
  ;

const
  EAbortRaisedHRESULT  = HRESULT(E_ABORT or CUSTOMER_BIT);

var
  OldSafeCallProc: TSafeCallErrorProc;
  uSafecallExceptionsInitialized: boolean = false;

function CustomSetErrorInfo(const ErrorCode: HRESULT; const ErrorIID: TGUID;
  const Source, Description, HelpFileName: WideString;
  const HelpContext: Integer): HRESULT;
var
  CreateError: ICreateErrorInfo;
  ErrorInfo: IErrorInfo;
begin
  Result := E_UNEXPECTED;
  if Succeeded(CreateErrorInfo(CreateError)) then
  begin
    CreateError.SetGUID(ErrorIID);
    if Source <> '' then
      CreateError.SetSource(PWideChar(Source));
    if HelpFileName <> '' then
      CreateError.SetHelpFile(PWideChar(HelpFileName));
    if Description <> '' then
      CreateError.SetDescription(PWideChar(Description));
    if HelpContext <> 0 then
      CreateError.SetHelpContext(HelpContext);
    if ErrorCode <> 0 then
      Result := ErrorCode;
    if CreateError.QueryInterface(IErrorInfo, ErrorInfo) = S_OK then
      Winapi.ActiveX.SetErrorInfo(0, ErrorInfo);
  end;
end;

function CustomGetErrorInfo(out ErrorIID: TGUID; out Source, Description, HelpFileName: WideString; out HelpContext: Longint): Boolean;
var
  ErrorInfo: IErrorInfo;
begin
  if Winapi.ActiveX.GetErrorInfo(0, ErrorInfo) = S_OK then
  begin
    ErrorInfo.GetGUID(ErrorIID);
    ErrorInfo.GetSource(Source);
    ErrorInfo.GetDescription(Description);
    ErrorInfo.GetHelpFile(HelpFileName);
    ErrorInfo.GetHelpContext(HelpContext);
    //Result := (Description <> '') or (Source <> '') or (not CompareMem(@ErrorIID, @GUID_NULL, SizeOf(ErrorIID)));
    Result := (Description <> '') or (Source <> '') or (not (ErrorIID = GUID_NULL));
  end
  else
  begin
    FillChar(ErrorIID, SizeOf(ErrorIID), 0);
    Source := '';
    Description := '';
    HelpFileName := '';
    HelpContext := 0;
    Result := False;
  end;
end;

// Немного изменённая копия кода из SysUtils
// К сожалению, он не публичный, поэтому копируем
// Устанавливает соответствие между
// системными кодами NTStatus и классами исключений
function CustomMapNTStatus(const ANTStatus: DWORD): ExceptClass;
begin
  case ANTStatus of
    STATUS_INTEGER_DIVIDE_BY_ZERO:
      Result := EDivByZero;
    STATUS_ARRAY_BOUNDS_EXCEEDED:
      Result := ERangeError;
    STATUS_INTEGER_OVERFLOW:
      Result := EIntOverflow;
    STATUS_FLOAT_INEXACT_RESULT,
    STATUS_FLOAT_INVALID_OPERATION,
    STATUS_FLOAT_STACK_CHECK:
      Result := EInvalidOp;
    STATUS_FLOAT_DIVIDE_BY_ZERO:
      Result := EZeroDivide;
    STATUS_FLOAT_OVERFLOW:
      Result := EOverflow;
    STATUS_FLOAT_UNDERFLOW,
    STATUS_FLOAT_DENORMAL_OPERAND:
      Result := EUnderflow;
    STATUS_ACCESS_VIOLATION:
      Result := EAccessViolation;
    STATUS_PRIVILEGED_INSTRUCTION:
      Result := EPrivilege;
    STATUS_CONTROL_C_EXIT:
      Result := EControlC;
    STATUS_STACK_OVERFLOW:
    {$WARNINGS OFF}
      Result := EStackOverflow;
    {$WARNINGS ON}
    else
      Result := EExternal;
  end;
end;

function CustomNTSTATUSFromException(const E: EExternal): DWORD;
begin
  if E.InheritsFrom(EDivByZero) then
    Result := STATUS_INTEGER_DIVIDE_BY_ZERO
  else
  if E.InheritsFrom(ERangeError) then
    Result := STATUS_ARRAY_BOUNDS_EXCEEDED
  else
  if E.InheritsFrom(EIntOverflow) then
    Result := STATUS_INTEGER_OVERFLOW
  else
  if E.InheritsFrom(EInvalidOp) then
    Result := STATUS_FLOAT_INVALID_OPERATION
  else
  if E.InheritsFrom(EZeroDivide) then
    Result := STATUS_FLOAT_DIVIDE_BY_ZERO
  else
  if E.InheritsFrom(EOverflow) then
    Result := STATUS_FLOAT_OVERFLOW
  else
  if E.InheritsFrom(EUnderflow) then
    Result := STATUS_FLOAT_UNDERFLOW
  else
  if E.InheritsFrom(EAccessViolation) then
    Result := STATUS_ACCESS_VIOLATION
  else
  if E.InheritsFrom(EPrivilege) then
    Result := STATUS_PRIVILEGED_INSTRUCTION
  else
  if E.InheritsFrom(EControlC) then
    Result := STATUS_CONTROL_C_EXIT
  else
  {$WARNINGS OFF}
  if E.InheritsFrom(EStackOverflow) then
  {$WARNINGS ON}
    Result := STATUS_STACK_OVERFLOW
  else
    Result := STATUS_NONCONTINUABLE_EXCEPTION;
end;

function CustomMapException(const ACode: DWORD): ExceptClass;
begin
  Result := GetExceptionClass(ACode);
end;

function Exception2HRESULT(const E: TObject): HRESULT;
begin
  if E = nil then
    Result := E_UNEXPECTED
  else
  if not E.InheritsFrom(Exception) then
    Result := E_UNEXPECTED
  else
  if E.ClassType = Exception then
    Result := E_FAIL
  else
  if E.InheritsFrom(ESafecallException) then
    Result := E_FAIL
  else
  if E.InheritsFrom(EAssertionFailed) then
    Result := E_UNEXPECTED
  else
  if E.InheritsFrom(EAbort) then
    Result := EAbortRaisedHRESULT
  else
  if E.InheritsFrom(EOutOfMemory) then
    Result := E_OUTOFMEMORY
  else
  if E.InheritsFrom(ENotImplemented) then
    Result := E_NOTIMPL
  else
  if E.InheritsFrom(ENotSupportedException) then
    Result := E_NOINTERFACE
  else
  if E.InheritsFrom(EOleSysError) and (not(E.InheritsFrom(EBaseCustomOleSysError))) then
    Result := EOleSysError(E).ErrorCode
  else
  if E.InheritsFrom(ESafeArrayError) then
    Result := ESafeArrayError(E).ErrorCode
  else
  if E.InheritsFrom(EOSError) then
    Result := HResultFromWin32(EOSError(E).ErrorCode)
  else
  if E.InheritsFrom(EExternal) then
    if Failed(HRESULT(EExternal(E).ExceptionRecord.ExceptionCode)) then
      Result := HResultFromNT(Integer(EExternal(E).ExceptionRecord.ExceptionCode))
    else
      Result := HResultFromNT(Integer(CustomNTSTATUSFromException(EExternal(E))))
  else
    Result := MakeResult(SEVERITY_ERROR, FACILITY_ITF, GetExceptionCode(E.ClassName)) or CUSTOMER_BIT;
end;

function HRESULT2Exception(const E: HRESULT; var ErrorAddr: Pointer): Exception;
var
  NTStatus: DWORD;
  ErrorIID: TGUID;
  Source: WideString;
  Description: WideString;
  HelpFileName: WideString;
  HelpContext: Integer;
  TempExcept: ExceptClass;
begin
  if CustomGetErrorInfo(ErrorIID, Source, Description, HelpFileName, HelpContext) then
  begin
    if Pointer(StrToInt64Def(Source, 0)) <> nil then
      ErrorAddr := Pointer(StrToInt64(Source));
  end
  else
    Description := SysErrorMessage(DWORD(E));

  if (E = E_FAIL) or (E = E_UNEXPECTED) then
    Result := Exception.Create(Description)
  else
  if E = EAbortRaisedHRESULT then
    Result := EAbort.Create(Description)
  else
  if E = E_OUTOFMEMORY then
  begin
    OutOfMemoryError;
    Result := nil;
  end
  else
  if E = E_NOTIMPL then
    Result := ENotImplemented.Create(Description)
  else
  if E = E_NOINTERFACE then
    Result := ENotSupportedException.Create(Description)
  else
  if HResultFacility(E) = FACILITY_WIN32 then
  begin
    Result := EOSError.Create(Description);
    EOSError(Result).ErrorCode := HResultCode(E);
  end
  else
  if E and FACILITY_NT_BIT <> 0 then
  begin
    // Получаем класс исключения по коду
    NTStatus := Cardinal(E) and (not FACILITY_NT_BIT);
    Result := CustomMapNTStatus(NTStatus).Create(Source + Description);

    // На всякий случай делаем заглушку для ExceptionRecord
    ReallocMem(Pointer(Result), Result.InstanceSize + SizeOf(TExceptionRecord));
    EExternal(Result).ExceptionRecord := Pointer(NativeUInt(Result) + Cardinal(Result.InstanceSize));
    FillChar(EExternal(Result).ExceptionRecord^, SizeOf(TExceptionRecord), 0);

    EExternal(Result).ExceptionRecord.ExceptionCode := cDelphiException;
    EExternal(Result).ExceptionRecord.ExceptionAddress := ErrorAddr;
  end
  else
  if (E and CUSTOMER_BIT <> 0) and
  (HResultFacility(E) = FACILITY_ITF) and
  //CompareMem(@IID_ExceptionHandlerIID, @ErrorIID, SizeOf(ErrorIID))
  (IID_ExceptionHandlerIID = ErrorIID)
  then
  begin
    TempExcept := CustomMapException(HResultCode(E));
    //Result := TempExcept.Create(Source + Description);
    Result := EBaseCustomException.Create(Description, E, Source, HelpFileName, HelpContext, TempExcept);
    {if TempExcept.InheritsFrom(EOleSysError) then
    begin
      EOleSysError(Result).ErrorCode := E;
      EOleSysError(Result).HelpContext := HelpContext;
      if TempExcept.InheritsFrom(EOleException) then
      begin
        EOleException(Result).Source := Source;
        EOleException(Result).HelpFile := HelpFileName;
      end
      else
        Result.Message := Source + Result.Message;
    end
    else
      Result.Message := Source + Result.Message;    }
  end
  else
    Result := EOleException.Create(Description, E, Source, HelpFileName, HelpContext);
end;

function CustomHandleSafeCallException(Caller: TObject; ExceptObj: TObject; ErrorAddr: Pointer): HRESULT;
var
  ErrorMessage: String;
  HelpFileName: String;
  ExceptionStackTrace: string;
  SourceString: string;
  HelpContext: Integer;
begin
  if ExceptObj is Exception then
  begin
    ErrorMessage := Exception(ExceptObj).Message;
    ExceptionStackTrace := Exception(ExceptObj).StackTrace;
  end
  else
    ErrorMessage := SysErrorMessage(DWORD(E_FAIL));
  if ExceptObj is EOleException then
  begin
    HelpFileName := EOleException(ExceptObj).HelpFile;
    HelpContext := EOleException(ExceptObj).HelpContext;
  end
  else
  begin
    HelpFileName := '';
    if ExceptObj is Exception then
      HelpContext := Exception(ExceptObj).HelpContext
    else
      HelpContext := 0;
  end;

  if Caller = nil then
    SourceString := ExceptObj.ClassName + ' at Unknown caller.' + IntToHex(NativeUInt(ErrorAddr), SizeOf(ErrorAddr) * 2) + sLineBreak + ExceptionStackTrace
  else
    SourceString := ExceptObj.ClassName + ' at ' + Caller.UnitName + '@' + Caller.ClassName + '.' + IntToHex(NativeUInt(ErrorAddr), SizeOf(ErrorAddr) * 2) + sLineBreak + ExceptionStackTrace;


  Result := CustomSetErrorInfo(
    Exception2HRESULT(ExceptObj),
    IID_ExceptionHandlerIID,
    SourceString,
    ErrorMessage,
    HelpFileName,
    HelpContext);
end;

procedure RaiseSafeCallException(ErrorCode: HResult; ErrorAddr: Pointer);
var
  E: Exception;
begin
  E := HRESULT2Exception(ErrorCode, ErrorAddr);
  raise E at ErrorAddr;
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if uSafecallExceptionsInitialized = false then
  begin
    OldSafeCallProc := SafeCallErrorProc;
    SafeCallErrorProc := RaiseSafeCallException;
    uSafecallExceptionsInitialized := true;
  end;
end;

procedure DoneModule(const AOptional: IUnknown);
begin
  if uSafecallExceptionsInitialized = true then
  begin
    SafeCallErrorProc := OldSafeCallProc;
    uSafecallExceptionsInitialized := false;
  end;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, DoneModule)
  else
    InitModule(nil);

finalization
  if System.IsLibrary = false then
    DoneModule(nil);

end.
