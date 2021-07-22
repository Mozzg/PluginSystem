unit uPluginAPIHeader;

interface

uses
  Winapi.Windows
  ,System.Rtti
  ,PluginAPI_TLB
  ;

{ Consts }

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

  cAPIProcName = 'F54B619FEA024CD69D8D4638101B8556';

  cMaxID = 2147483000;

{ Types }

type
  TStringArray = array of string;
  TGUIDArray = array of TGUID;

  TNameGUIDPairRec = record
    GUID: TGUID;
    Name: string;
  end;
  TNameGUIDArray = array of TNameGUIDPairRec;

  TWeakIntfCollectionRec = record
    InterfaceName: string;
    InterfaceInstance: IAPIWeakRef;
  end;
  TWeakIntfCollectionArray = array of TWeakIntfCollectionRec;

  TSubscriberRec = record
    Subscriber: IAPIEventSubscriber;
    Description: string;
  end;
  TSubscriberArray = array of TSubscriberRec;

  TExportedFunction = function(const AIID: TGUID; out Intf: IUnknown; out RetVal: WordBool): HRESULT; stdcall;
  TExportedFunction_safecall = function(const AIID: TGUID; out Intf: IUnknown): WordBool; safecall;
  TExportedFunctionGUIDEvent = procedure(const AIID: TGUID);
  TExportedFunctionReasonEvent = procedure(AReason: Integer);
  TExportedFunctionExceptionEvent = procedure(const AIID: TGUID; const AExcClass: string);

  TLogProcedure = procedure(message: string);

{ Variables }

var
  GlobSetDllDirectory: function(lpPathName: PChar): BOOL; stdcall;
  GlobSetSearchPathMode: function(Flags: DWORD): BOOL; stdcall;
  GlobAddDllDirectory: function(Path: PWideChar): Pointer; stdcall;
  GlobRemoveDllDirectory: function(Cookie: Pointer): BOOL; stdcall;
  GlobSetDefaultDllDirectories: function(DirectoryFlags: DWORD): BOOL; stdcall;


{ Functions }

function LoadDLL(const ADLLName: UnicodeString; ErrorMode: UINT = SEM_NOOPENFILEERRORBOX): HMODULE;
function UnloadDLL(AHandle: HMODULE): LongBool;
function EncodeModuleVersion(Major, Minor, Release, Build: byte): LongWord;
procedure DecodeModuleVersion(const Version: LongWord; out Major, Minor, Release, Build: byte);
function GetImplementedInterfaces(AClass: TClass): string; overload;
procedure GetImplementedInterfaces(AClass: TClass; var ResultList: TStringArray; IgnoreRepeated: boolean = true); overload;
procedure GetImplementedInterfaces(AClass: TClass; var ResultList: TNameGUIDArray; IgnoreRepeated: boolean = true); overload;

implementation

uses
  SysUtils
  ,uInitSystem
  ,uSafecallExceptions
  ,uCustomClasses
  ,uHRESULTCodeHelper
  ;

var
  LocuPluginAPIHeaderInitialized: boolean = false;

  LocMajorShift: Word = 0;
  LocMinorShift: Word = 0;
  LocReleaseShift: Word = 0;
  LocBuildShift: Word = 0;

function IsKB2533623Installed: Boolean; // Vista/7 with KB2533623
begin
  Result := Assigned(GlobAddDllDirectory);
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
      if Assigned(GlobSetDllDirectory) then
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

function UnloadDLL(AHandle: HMODULE): LongBool;
begin
  Result := false;
  if AHandle <> 0 then Result := FreeLibrary(AHandle);
end;

procedure CalculateModuleVersionShifts;
var Temp: LongWord;
begin
  //major
  LocMajorShift := 0;
  Temp := cMajorVersionMask;
  while (Temp and 1) = 0 do
  begin
    inc(LocMajorShift);
    Temp := Temp shr 1;
  end;
  //minor
  LocMinorShift := 0;
  Temp := cMinorVersionMask;
  while (Temp and 1) = 0 do
  begin
    inc(LocMinorShift);
    Temp := Temp shr 1;
  end;
  //release
  LocReleaseShift := 0;
  Temp := cReleaseVersionMask;
  while (Temp and 1) = 0 do
  begin
    inc(LocReleaseShift);
    Temp := Temp shr 1;
  end;
  //build
  LocBuildShift := 0;
  Temp := cBuildVersionMask;
  while (Temp and 1) = 0 do
  begin
    inc(LocBuildShift);
    Temp := Temp shr 1;
  end;
end;

function EncodeModuleVersion(Major, Minor, Release, Build: byte): LongWord;
begin
  Result := ((Major shl LocMajorShift)and cMajorVersionMask)
          or((Minor shl LocMinorShift)and cMinorVersionMask)
          or((Release shl LocReleaseShift)and cReleaseVersionMask)
          or((Build shl LocBuildShift)and cBuildVersionMask);
  Result := Result and cVersionMask;
end;

procedure DecodeModuleVersion(const Version: LongWord; out Major, Minor, Release, Build: byte);
var TempVersion: LongWord;
begin
  TempVersion := Version and cVersionMask;

  Major := (TempVersion and cMajorVersionMask) shr LocMajorShift;
  Minor := (TempVersion and cMinorVersionMask) shr LocMinorShift;
  Release := (TempVersion and cReleaseVersionMask) shr LocReleaseShift;
  Build := (TempVersion and cBuildVersionMask) shr LocBuildShift;
end;

procedure LoadFuncs;
var
  LibKernel32: HMODULE;
begin
  LibKernel32 := GetModuleHandle(kernel32);
  GlobSetDllDirectory := GetProcAddress(LibKernel32, {$IFDEF SUPPORTS_UNICODE}'SetDllDirectoryW'{$ELSE}'SetDllDirectoryA'{$ENDIF});
  GlobSetSearchPathMode := GetProcAddress(LibKernel32, 'SetSearchPathMode');
  GlobAddDllDirectory := GetProcAddress(LibKernel32, 'AddDllDirectory');
  GlobRemoveDllDirectory := GetProcAddress(LibKernel32, 'RemoveDllDirectory');
  GlobSetDefaultDllDirectories := GetProcAddress(LibKernel32, 'SetDefaultDllDirectories');
end;

function GetInterfaceNames(AIIDArr: TGUIDArray): string; overload;
var Context: TRttiContext;
ItemType: TRttiType;
i: integer;
TempArr: array of string;
begin
  Result := '';
  i := Length(AIIDArr);
  if i = 0 then exit;
  SetLength(TempArr, i);
  Context := TRttiContext.Create;
  try
    for ItemType in Context.GetTypes do
      if ItemType is TRTTIInterfaceType then
        for i := Low(TempArr) to High(TempArr) do
          if TRTTIInterfaceType(ItemType).GUID = AIIDArr[i] then
          begin
            TempArr[i] := ItemType.Name;
            break;
          end;


    for i := Low(TempArr) to High(TempArr) do
    begin
      Result := Result + TempArr[i];
      if i <> High(TempArr) then Result := Result + ', ';
    end;
  finally
    Context.Free;
    SetLength(TempArr, 0);
  end;
end;

procedure GetInterfaceNames(AIIDArr: TGUIDArray; var IntfNames: TStringArray); overload;
var Context: TRttiContext;
ItemType: TRttiType;
i: integer;
TempArr: array of string;
begin
  SetLength(IntfNames, 0);
  i := Length(AIIDArr);
  if i = 0 then exit;
  SetLength(TempArr, i);
  Context := TRttiContext.Create;
  try
    for ItemType in Context.GetTypes do
      if ItemType is TRTTIInterfaceType then
        for i := Low(TempArr) to High(TempArr) do
          if TRTTIInterfaceType(ItemType).GUID = AIIDArr[i] then
          begin
            TempArr[i] := ItemType.Name;
            //break;
          end;

    SetLength(IntfNames, Length(TempArr));
    for i := Low(TempArr) to High(TempArr) do
      IntfNames[i] := TempArr[i];
  finally
    Context.Free;
    SetLength(TempArr, 0);
  end;
end;

function GetImplementedInterfaces(AClass: TClass): string;
var i, j: integer;
InterfaceTable: PInterfaceTable;
InterfaceEntry: PInterfaceEntry;
TempClass: TClass;
IntfArr: TGUIDArray;
begin
  TempClass := AClass;
  Result := '';
  SetLength(IntfArr, 0);

  try
    while Assigned(TempClass) do
    begin
      InterfaceTable := TempClass.GetInterfaceTable;
      if Assigned(InterfaceTable) then
        for i := 0 to InterfaceTable.EntryCount-1 do
        begin
          InterfaceEntry := @InterfaceTable.Entries[i];
          j := Length(IntfArr);
          SetLength(IntfArr, j+1);
          IntfArr[j]:=InterfaceEntry.IID;
        end;
      TempClass := TempClass.ClassParent;
    end;

    Result := GetInterfaceNames(IntfArr);
  finally
    SetLength(IntfArr, 0);
  end;
end;

procedure GetImplementedInterfaces(AClass: TClass; var ResultList: TStringArray; IgnoreRepeated: boolean = true);
var i, j, k: integer;
InterfaceTable: PInterfaceTable;
InterfaceEntry: PInterfaceEntry;
TempClass: TClass;
IntfArr: TGUIDArray;
begin
  TempClass := AClass;
  SetLength(ResultList, 0);
  SetLength(IntfArr, 0);

  try
    while Assigned(TempClass) do
    begin
      InterfaceTable := TempClass.GetInterfaceTable;
      if Assigned(InterfaceTable) then
        for i := 0 to InterfaceTable.EntryCount-1 do
        begin
          InterfaceEntry := @InterfaceTable.Entries[i];
          j := Length(IntfArr);
          SetLength(IntfArr, j+1);
          IntfArr[j]:=InterfaceEntry.IID;
        end;
      TempClass := TempClass.ClassParent;
    end;

    GetInterfaceNames(IntfArr, ResultList);
    if IgnoreRepeated = true then
    begin
      //looking for repeating entries and deleting them
      i := Low(ResultList);
      while i <= (High(ResultList)-1) do
      begin
        j := i+1;
        while j <= High(ResultList) do
        begin
          if AnsiLowerCase(ResultList[i]) = AnsiLowerCase(ResultList[j]) then
          begin
            for k := j+1 to High(ResultList) do
              ResultList[k-1] := ResultList[k];
            SetLength(ResultList, Length(ResultList)-1);
            continue;
          end;
          inc(j);
        end;
        inc(i);
      end;
    end;
  finally
    SetLength(IntfArr, 0);
  end;
end;

procedure GetImplementedInterfaces(AClass: TClass; var ResultList: TNameGUIDArray; IgnoreRepeated: boolean = true); overload;
var i, j, k: integer;
InterfaceTable: PInterfaceTable;
InterfaceEntry: PInterfaceEntry;
TempClass: TClass;
IntfArr: TGUIDArray;
TempArr: TStringArray;
begin
  TempClass := AClass;
  SetLength(ResultList, 0);
  SetLength(IntfArr, 0);
  SetLength(TempArr, 0);

  try
    while Assigned(TempClass) do
    begin
      InterfaceTable := TempClass.GetInterfaceTable;
      if Assigned(InterfaceTable) then
        for i := 0 to InterfaceTable.EntryCount-1 do
        begin
          InterfaceEntry := @InterfaceTable.Entries[i];
          j := Length(IntfArr);
          SetLength(IntfArr, j+1);
          IntfArr[j]:=InterfaceEntry.IID;
        end;
      TempClass := TempClass.ClassParent;
    end;

    GetInterfaceNames(IntfArr, TempArr);

    //creating resulting array
    SetLength(ResultList, Length(IntfArr));
    for i := Low(ResultList) to High(ResultList) do
    begin
      ResultList[i].GUID := IntfArr[i];
      ResultList[i].Name := TempArr[i];
    end;

    if IgnoreRepeated = true then
    begin
      //looking for repeating entries and deleting them
      i := Low(ResultList);
      while i <= (High(ResultList)-1) do
      begin
        j := i+1;
        while j <= High(ResultList) do
        begin
          if ResultList[i].GUID = ResultList[j].GUID then
          begin
            for k := j+1 to High(ResultList) do
            begin
              ResultList[k-1].GUID := ResultList[k].GUID;
              ResultList[k-1].Name := ResultList[k].Name;
            end;
            SetLength(ResultList, Length(ResultList)-1);
            continue;
          end;
          inc(j);
        end;
        inc(i);
      end;
    end;
  finally
    SetLength(IntfArr, 0);
    SetLength(TempArr, 0);
  end;
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if LocuPluginAPIHeaderInitialized = false then
  begin
    LoadFuncs;
    CalculateModuleVersionShifts;
    LocuPluginAPIHeaderInitialized := true;
  end;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, nil)
  else
    InitModule(nil);

finalization

end.
