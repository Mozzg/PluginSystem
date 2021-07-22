unit SampleHeader;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

uses
  Winapi.Windows
  ,SysUtils
  ,Winapi.ActiveX
  ,System.Win.ComObj
  ,VarUtils
  //,uSafecallFix
  ,uCustomClasses  //uses uHRESULTCodeHelper, PluginAPI_TLB
  //,JclDebug
  //,uCallStackTrace
  ;

type
  ISampleDLLAPI = interface
  ['{57DA24D0-4A9D-4BFA-B899-A940F5DE0ECF}']
    function GetVersion: Integer; safecall;
    procedure InitializeModule(Intf: IUnknown); safecall;
    procedure FinalizeModule; safecall;

    procedure TryAbort; safecall;
    //function TryAbort: HRESULT; stdcall;
    procedure TryAccessViolation; safecall;
    procedure TryWin32Exception; safecall;
    procedure TrySoftwareException; safecall;
  end;

  IMyDll = interface
  ['{39518EFF-099C-4718-A45B-B07088B666BD}']
    procedure InitDLL(AOptional: IUnknown = nil); safecall;
    procedure DoneDLL; safecall;
    // ...
  end;

  TExportedFunction = function:ISampleDLLAPI; safecall;

var
  LoadLibraryEx: function(lpFileName: PChar; Reserved: THandle; dwFlags: DWORD): HMODULE; stdcall;
  SetDllDirectory: function(lpPathName: PChar): BOOL; stdcall;
  SetSearchPathMode: function(Flags: DWORD): BOOL; stdcall;
  AddDllDirectory: function(Path: PWideChar): Pointer; stdcall;
  RemoveDllDirectory: function(Cookie: Pointer): BOOL; stdcall;
  SetDefaultDllDirectories: function(DirectoryFlags: DWORD): BOOL; stdcall;

const
  // LoadLibraryEx:
  DONT_RESOLVE_DLL_REFERENCES         = $00000001;
  LOAD_LIBRARY_AS_DATAFILE            = $00000002;
  LOAD_WITH_ALTERED_SEARCH_PATH       = $00000008;
  LOAD_IGNORE_CODE_AUTHZ_LEVEL        = $00000010;
  LOAD_LIBRARY_AS_IMAGE_RESOURCE      = $00000020;
  LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE  = $00000040;
  LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR    = $00000100;
  LOAD_LIBRARY_SEARCH_APPLICATION_DIR = $00000200;
  LOAD_LIBRARY_SEARCH_USER_DIRS       = $00000400;
  LOAD_LIBRARY_SEARCH_SYSTEM32        = $00000800;
  LOAD_LIBRARY_SEARCH_DEFAULT_DIRS    = $00001000;

  // SetSearchPathMode:
  BASE_SEARCH_PATH_ENABLE_SAFE_SEARCHMODE  = $00000001;
  BASE_SEARCH_PATH_PERMANENT               = $00008000;
  BASE_SEARCH_PATH_DISABLE_SAFE_SEARCHMODE = $00010000;

  SampleDLLProcName = 'GetAPIProc';

  APIProcName = 'F54B619FEA024CD69D8D4638101B8556';

function LoadDLL(const ADLLName: UnicodeString; ErrorMode: UINT = SEM_NOOPENFILEERRORBOX): HMODULE;
//function HandleSafeCallException(Caller: TObject; ExceptObj: TObject; ErrorAddr: Pointer): HRESULT;
//function SafeLoadLibraryEx(const Filename: string; ErrorMode: UINT): HMODULE;

implementation

uses
  TypInfo
  ,Classes
  ,PluginAPI_TLB
  ,uHRESULTCodeHelper
  ,uSafecallExceptions
  ,uInitSystem
  ;


function SafeLoadLibraryEx(const Filename: string; ErrorMode: UINT): HMODULE;
const
  LOAD_WITH_ALTERED_SEARCH_PATH    = $008;
var
  OldMode: UINT;
  FPUControlWord: Word;
begin
  OldMode := SetErrorMode(ErrorMode);
  try
    {$IFNDEF CPUX64}
    asm
      FNSTCW  FPUControlWord
    end;
    try
    {$ENDIF ~CPUX64}
      Result := LoadLibraryEx(PChar(Filename), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
    {$IFNDEF CPUX64}
    finally
      asm
        FNCLEX
        FLDCW FPUControlWord
      end;
    end;
    {$ENDIF ~CPUX64}
  finally
    SetErrorMode(OldMode);
  end;
end;

function IsKB2533623Installed: Boolean; // Vista/7 with KB2533623
begin
  Result := Assigned(AddDllDirectory);
end;

function LoadDLL(const ADLLName: UnicodeString; ErrorMode: UINT): HMODULE;
var
  DLLPath: String;
  OldDir: String;
  OldPath: UnicodeString;
  OldMode: UINT;
  {$IFDEF WIN32}
  FPUControlWord: Word;
  {$ENDIF}
  {$IFDEF WIN64}
  FPUControlWord: Word;
  {$ENDIF}
begin
  OldDir := GetCurrentDir;
  OldPath := GetEnvironmentVariable('PATH');
  OldMode := SetErrorMode(ErrorMode);
  try
    DLLPath := ExtractFilePath(ADLLName);
    SetEnvironmentVariableW('PATH', PWideChar(UnicodeString(DLLPath) + ';' + OldPATH));
    SetCurrentDir(DLLPath);

    {$IFDEF WIN32}
    asm
      FNSTCW  FPUControlWord
    end;
    {$ENDIF}
    {$IFDEF WIN64}
    FPUControlWord := Get8087CW();
    {$ENDIF}
    try

      if IsKB2533623Installed then
        Result := LoadLibraryExW(PWideChar(ADLLName), 0, LOAD_WITH_ALTERED_SEARCH_PATH)
      else
      if Assigned(SetDllDirectory) then
      begin
        SetDllDirectory(PWideChar(DLLPath));
        try
          Result := LoadLibraryW(PWideChar(ADLLName));
          Win32Check(Result <> 0);
        finally
          SetDllDirectory(nil);
        end;
      end
      else
        Result := LoadLibraryW(PWideChar(ADLLName));
      Win32Check(Result <> 0);

    finally
      {$IFDEF WIN32}
      asm
        FNCLEX
        FLDCW FPUControlWord
      end;
      {$ENDIF}
      {$IFDEF WIN64}
      //TestAndClearFPUExceptions(0);
      Set8087CW(FPUControlWord);
      {$ENDIF}
    end;
  finally
    SetErrorMode(OldMode);
    SetEnvironmentVariableW('PATH', PWideChar(OldPATH));
    SetCurrentDir(OldPath);
  end;
  SetLastError(0);
end;

function ObjDescr(const AObj: TObject): String;
begin
  if AObj = nil then
  begin
    Result := 'nil';
    Exit;
  end;

  if AObj.InheritsFrom(TCheckedInterfacedObject) then
  begin
    Result := String(TCheckedInterfacedObject(AObj).DebugName);
    if Result <> '' then
      Exit;
  end;

  if AObj.InheritsFrom(TComponent) then
  begin
    Result := AObj.ClassName;
    if Result <> '' then
      Result := Format('[%s] %s', [Result, TComponent(AObj).Name]);
    if Result <> '' then
      Exit;
  end;

  Result := AObj.ClassName;
  Result := Format({$IFDEF CPU32}'[%s] $%.8x'{$ENDIF}{$IFDEF CPU64}'[%s] $%.16x'{$ENDIF}, [Result, NativeUInt(AObj)]);
end;

function MethodDescr(const AMethod): String;
var
  M: TMethod;
begin
  Move(AMethod, M, SizeOf(M));

  Result := TObject(M.Data).MethodName(M.Code);
  if Result <> '' then
    Result := Format({$IFDEF CPU32}'$%.8x (possible %s method)'{$ENDIF}{$IFDEF CPU64}'$%.16x (possible %s method)'{$ENDIF}, [NativeUInt(M.Code), Result])
  else
    Result := '$' + IntToHex(NativeUInt(M.Code), SizeOf(Pointer) * 2);
  Result := ObjDescr(TObject(M.Data)) + ' ' + Result;
end;


procedure LoadFuncs;
var
  LibKernel32: HMODULE;
begin
  LibKernel32 := GetModuleHandle(kernel32);
  LoadLibraryEx := GetProcAddress(LibKernel32, {$IFDEF UNICODE}'LoadLibraryExW'{$ELSE}'LoadLibraryExA'{$ENDIF});
  SetDllDirectory := GetProcAddress(LibKernel32, {$IFDEF UNICODE}'SetDllDirectoryW'{$ELSE}'SetDllDirectoryA'{$ENDIF});
  SetSearchPathMode := GetProcAddress(LibKernel32, 'SetSearchPathMode');
  AddDllDirectory := GetProcAddress(LibKernel32, 'AddDllDirectory');
  RemoveDllDirectory := GetProcAddress(LibKernel32, 'RemoveDllDirectory');
  SetDefaultDllDirectories := GetProcAddress(LibKernel32, 'SetDefaultDllDirectories');
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  LoadFuncs;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, nil)
  else
    InitModule(nil);

finalization

end.
