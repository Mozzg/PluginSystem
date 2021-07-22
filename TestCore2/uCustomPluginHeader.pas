unit uCustomPluginHeader;

interface

uses
  uPluginAPIHeader
  ,PluginAPI_TLB
  ,uCustomClasses
  ;

type
  TWeakInterfaceWrapper = record
    InterfaceName: string;
    Intf: IAPIWeakRef;
  end;

  TEventCollectionRec = record
    Module: TGUID;
    Name: string;
    ID: integer;
    EventWeak: IAPIWeakRef;
  end;

  TWndsCollectionRec = record
    Module: TGUID;
    Name: string;
    ID: integer;
    WndWeak: IAPIWeakRef;
  end;

  TCoreWrapper = class(TCheckedInterfacedObjectNoCount, IUnknown, IAPIWeakRefSupport, IAPICoreEventCollection, IAPICoreWndsCollection, IAPICoreAppWnds)
  private
    FInternalEvents: array of TEventCollectionRec;
    FCurrentEventID: integer;

    FInternalWnds: array of TWndsCollectionRec;
    FCurrentWndsID: integer;

    function DeleteInternalEvent(AIndex: integer): boolean;
    function DeleteInternalWindow(AIndex: integer): boolean;

    //IAPIEventCollection
    function get_EventCollectionCount: Integer; safecall;

    //IAPICoreWndsCollection
    function get_WndsCollectionCount: Integer; safecall;

    //IAPICoreAppWnds
    function get_ApplicationWnd: Pointer; safecall;
    function get_MainWnd: Pointer; safecall;
    function get_ActiveWnd: Pointer; safecall;
    function get_MDIClientWnd: Pointer; safecall;
  public
    constructor Create;
    destructor Destroy; override;

    //IAPICoreEventCollection
    function RegisterEvent(AModule: TGUID; const AEventName: WideString; const AEvent: IAPIEvent): Integer; safecall;
    function UnregisterEvent(AID: Integer): WordBool; safecall;
    function GetEventName(AIndex: Integer; out AName: WideString): WordBool; safecall;
    function GetEventModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
    function GetEventByIndex(AIndex: Integer; out AEvent: IAPIEvent): WordBool; safecall;
    function GetEventByID(AID: Integer; out AEvent: IAPIEvent): WordBool; safecall;
    function GetEventByIndexWeak(AIndex: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
    function GetEventByIDWeak(AID: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
    property EventCollectionCount: Integer read get_EventCollectionCount;

    //IAPICoreWndsCollection
    function RegisterWindow(AModule: TGUID; const AWindowName: WideString; const AWindow: IAPIWindow): Integer; safecall;
    function UnregisterWindow(AID: Integer): WordBool; safecall;
    function GetWindowName(AIndex: Integer; out AName: WideString): WordBool; safecall;
    function GetWindowModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
    function GetWindowByIndex(AIndex: Integer; out AWindow: IAPIWindow): WordBool; safecall;
    function GetWindowByID(AID: Integer; out AWindow: IAPIWindow): WordBool; safecall;
    function GetWindowByIndexWeak(AIndex: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
    function GetWindowByIDWeak(AID: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
    property WndsCollectionCount: Integer read get_WndsCollectionCount;

    //IAPICoreAppWnds
    procedure ModalStart; safecall;
    procedure ModalFinish; safecall;
    property ApplicationWnd: Pointer read get_ApplicationWnd;
    property MainWnd: Pointer read get_MainWnd;
    property ActiveWnd: Pointer read get_ActiveWnd;
    property MDIClientWnd: Pointer read get_MDIClientWnd;
  end;

  TPluginWrapper = class(TCheckedInterfacedObject, IInterface)
  private
    FCore: TCoreWrapper;
    FDLLHandle: HMODULE;
    FExportedFunction: TExportedFunction_safecall;
    {FInterfaceInitDone: IAPIInitDone;
    FInterfaceInitDoneEvents: IAPIInitDoneEvents;
    FInterfaceModuleInfo: IAPIModuleInfo;
    //FInterfaceModuleInfo: Pointer;
    FInterfaceCollection: IAPIIntfCollection;
    FDebugInterface: IDebugRefCount;   }
    FExportedInterfaces: array of TWeakInterfaceWrapper;
    FLoaded: boolean;

    function GetModuleName: string;

  public
    constructor Create(ADLLPath: string; ACore: TCoreWrapper);
    destructor Destroy; override;

    function InitializeModule: boolean;
    procedure FinalizeModule;
    procedure OnAfterModulesInitialize(AReason: integer);
    procedure FreeModule;

    function GetExportedWeakRef(const ARefName: string; out AWeakRef: IAPIWeakRef): boolean;

    function GetModuleRefCount: integer;
    function GetPluginStatus: string;

    property DLLLoaded: boolean read FLoaded;
    property ModuleName: string read GetModuleName;
    //property ModuleRefCount: integer read GetModuleRefCount;
  end;

implementation

uses
  Windows
  ,SysUtils
  ,Forms
  ;

//var temp: Pointer;

{ TPluginWrapper }

constructor TPluginWrapper.Create(ADLLPath: string; ACore: TCoreWrapper);
begin
  inherited Create;

  FCore := ACore;

  try
    FLoaded := false;
    FDLLHandle := LoadDLL(ADLLPath);
    if FDLLHandle = 0 then exit;
    FExportedFunction := GetProcAddress(FDLLHandle, cAPIProcName);
    if Assigned(FExportedFunction) = false then exit;
    //if FExportedFunction(IAPIInitDone, IUnknown(FInterfaceInitDone)) = false then exit;
    FLoaded := true;
  except
    on E: Exception do
    begin
      //FreeModule;
      FLoaded := false;
      raise;
    end;
  end;
end;

destructor TPluginWrapper.Destroy;
begin
  FreeModule;
  FLoaded := false;
  inherited;
end;

function TPluginWrapper.InitializeModule: boolean;
var i, count: integer;
InitDoneIntf: IAPIInitDone;
IntfCollection: IAPIIntfCollection;
temp: IUnknown;
begin
  try
    Result := false;
    if DLLLoaded = false then exit;

    //init
    if FExportedFunction(IAPIInitDone, temp) = false then exit;
    if Supports(temp, IAPIInitDone, InitDoneIntf) = false then exit;
    if InitDoneIntf.Initialize(FCore, cReasonInitialLoad) = false then exit;
    InitDoneIntf := nil;

    //geting interface collection
    if FExportedFunction(IAPIIntfCollection, temp) = false then exit;
    //filling exported interfaces
    if Supports(temp, IAPIIntfCollection, IntfCollection) = false then exit;
    //count := IntfCollection.get_IntfCollectionCount;
    count := IntfCollection.IntfCollectionCount;
    Setlength(FExportedInterfaces, count);
    for i := 0 to count-1 do
    begin
      FExportedInterfaces[i].InterfaceName := IntfCollection.GetIntfName(i);
      IntfCollection.GetIntfByIndexWeak(i, FExportedInterfaces[i].Intf);
    end;
    IntfCollection := nil;

    temp := nil;

    (*if Assigned(FInterfaceInitDone) then
    begin
      if FInterfaceInitDone.Initialize(Self, cReasonInitialLoad) = false then exit;
    end
    else exit;

    if FExportedFunction(IAPIIntfCollection, IUnknown(FInterfaceCollection)) = false then exit;
    if FInterfaceCollection.GetIntfByGUID(IAPIInitDoneEvents, IUnknown(FInterfaceInitDoneEvents)) = false then exit;
    if FInterfaceCollection.GetIntfByGUID(IAPIModuleInfo, IUnknown(FInterfaceModuleInfo)) = false then exit;
    if FInterfaceCollection.GetIntfByGUID(IDebugRefCount, IUnknown(FDebugInterface)) = false then exit;

    {temp := FInterfaceModuleInfo;
    IAPIModuleInfo(FInterfaceModuleInfo) := nil;
    FInterfaceModuleInfo := temp;
    temp := nil;  }

    count := FInterfaceCollection.IntfCollectionCount;
    Setlength(FExportedInterfaces, count);
    for i := 0 to count-1 do
    begin
      FExportedInterfaces[i].InterfaceName := FInterfaceCollection.GetIntfName(i);
      FInterfaceCollection.GetIntfByIndexWeak(i, FExportedInterfaces[i].Intf);
    end;
          *)
    Result := true;
  finally
    //on E: Exception do
    begin
      //FreeModule;
      FLoaded := false;
      //raise;
    end;
  end;
end;

procedure TPluginWrapper.FinalizeModule;
var temp_weak: IAPIWeakRef;
unk: IUnknown;
initdone: IAPIInitDone;
begin
  if GetExportedWeakRef('IAPIInitDone', temp_weak) = false then raise Exception.Create('No exported interface');
  temp_weak.GetRef(unk);
  if Supports(unk,IAPIInitDone,initdone)=false then raise Exception.Create('No exported interface');

  initdone.Finalize(FCore, cReasonProgramExit);

  unk := nil;
  initdone := nil;
  temp_weak := nil;
{var temp_weak: IAPIWeakRef;
unk: IUnknown;
debug: IDebugRefCount;
i: integer;
begin
  if GetExportedWeakRef('IDebugRefCount', temp_weak) = false then raise Exception.Create('No exported interface');
  temp_weak.GetRef(unk);
  if Supports(unk,IDebugRefCount,debug)=false then raise Exception.Create('No exported interface');

  i:=debug.GetDebugRefCount;
  unk := nil;
  debug := nil;
  temp_weak := nil;

  Application.MessageBox(PWideChar('RefCount='+inttostr(i)), 'Caption', MB_OK);}
end;

procedure TPluginWrapper.OnAfterModulesInitialize(AReason: integer);
begin
  //FInterfaceInitDoneEvents.AfterPluginsInitialize(AReason);
end;

procedure TPluginWrapper.FreeModule;
var i: integer;
begin
  for i := Low(FExportedInterfaces) to High(FExportedInterfaces) do
    FExportedInterfaces[i].Intf := nil;
  SetLength(FExportedInterfaces, 0);

  {if Assigned(FInterfaceInitDone) then
    FInterfaceInitDone.Finalize(Self, cReasonProgramExit);

  FInterfaceInitDone := nil;
  FInterfaceInitDoneEvents := nil;
  FInterfaceModuleInfo := nil;
  FInterfaceCollection := nil;
  FDebugInterface := nil;   }

  FExportedFunction := nil;
  UnloadDLL(FDLLHandle);
end;

function TPluginWrapper.GetModuleName: string;
begin
  //Result := FInterfaceModuleInfo.ModuleName;

end;

function TPluginWrapper.GetModuleRefCount: integer;
var temp_weak: IAPIWeakRef;
unk: IUnknown;
debug: IDebugRefCount;
begin
  Result := -3;

  if GetExportedWeakRef('IDebugRefCount', temp_weak) = false then raise Exception.Create('No exported interface');
  temp_weak.GetRef(unk);
  if Supports(unk,IDebugRefCount,debug)=false then raise Exception.Create('No exported interface');

  Result := debug.GetDebugRefCount;
  unk := nil;
  debug := nil;
  temp_weak := nil;
end;

function TPluginWrapper.GetExportedWeakRef(const ARefName: string; out AWeakRef: IAPIWeakRef): boolean;
var i: integer;
begin
  Result := false;
  AWeakRef := nil;

  for i := Low(FExportedInterfaces) to High(FExportedInterfaces) do
    if FExportedInterfaces[i].InterfaceName = ARefName then
    begin
      AWeakRef := FExportedInterfaces[i].Intf;
      Result := true;
      exit;
    end;
end;

function TPluginWrapper.GetPluginStatus: string;
var temp_weak: IAPIWeakRef;
unk: IUnknown;
ModuleInfo: IAPIModuleInfo;
IntfCollection: IAPIIntfCollection;
ver, i: integer;
minor, major, release, build: byte;
begin
  Result := '';

  if GetExportedWeakRef('IAPIIntfCollection', temp_weak) = false then raise Exception.Create('No exported interface');
  temp_weak.GetRef(unk);
  if unk.QueryInterface(IAPIIntfCollection, IntfCollection) <> S_OK then raise Exception.Create('No exported interface');

  Result:=Result+'Exported interfaces('+inttostr(IntfCollection.IntfCollectionCount)+'):'+sLineBreak;
  for i := 0 to IntfCollection.IntfCollectionCount-1 do
    Result:=Result+IntfCollection.GetIntfName(i)+sLineBreak;

  if GetExportedWeakRef('IAPIModuleInfo', temp_weak) = false then raise Exception.Create('No exported interface');
  temp_weak.GetRef(unk);
  if unk.QueryInterface(IAPIModuleInfo, ModuleInfo) <> S_OK then raise Exception.Create('No exported interface');

  ver := ModuleInfo.ModuleVersion;
  DecodeModuleVersion(ver, major, minor, release, build);
  Result := Result +
  'Name='+ModuleInfo.ModuleName+sLineBreak+
  'Description='+ModuleInfo.ModuleDescription+sLineBreak+
  'GUID='+GUIDtostring(ModuleInfo.ModuleGUID)+sLineBreak+
  'Version='+inttostr(major)+'.'+inttostr(minor)+'.'+inttostr(release)+'.'+inttostr(build);
  ModuleInfo := nil;
end;

{ TCoreWrapper }

constructor TCoreWrapper.Create;
begin
  inherited Create;
  FCurrentEventID := 1;
  FCurrentWndsID := 1;
end;

destructor TCoreWrapper.Destroy;
var i: integer;
begin
  for i := Low(FInternalEvents) to High(FInternalEvents) do
    FInternalEvents[i].EventWeak := nil;
  Setlength(FInternalEvents, 0);

  for i := Low(FInternalWnds) to High(FInternalWnds) do
    FInternalWnds[i].WndWeak := nil;
  Setlength(FInternalWnds, 0);

  inherited;
end;

function TCoreWrapper.DeleteInternalEvent(AIndex: integer): boolean;
var i: integer;
begin
  Result := false;

  if (AIndex < Low(FInternalEvents))or(AIndex > High(FInternalEvents)) then exit;

  for i := AIndex+1 to High(FInternalEvents) do
  begin
    FInternalEvents[i-1].EventWeak := nil;

    FInternalEvents[i-1].Module := FInternalEvents[i].Module;
    FInternalEvents[i-1].Name := FInternalEvents[i].Name;
    FInternalEvents[i-1].ID := FInternalEvents[i].ID;
    FInternalEvents[i-1].EventWeak := FInternalEvents[i].EventWeak;

    FInternalEvents[i].EventWeak := nil;
  end;
  SetLength(FInternalEvents, Length(FInternalEvents)-1);
end;

function TCoreWrapper.DeleteInternalWindow(AIndex: integer): boolean;
var i: integer;
begin
  Result := false;

  if (AIndex < Low(FInternalWnds))or(AIndex > High(FInternalWnds)) then exit;

  for i := AIndex+1 to High(FInternalWnds) do
  begin
    FInternalWnds[i-1].WndWeak := nil;

    FInternalWnds[i-1].Module := FInternalWnds[i].Module;
    FInternalWnds[i-1].Name := FInternalWnds[i].Name;
    FInternalWnds[i-1].ID := FInternalWnds[i].ID;
    FInternalWnds[i-1].WndWeak := FInternalWnds[i].WndWeak;

    FInternalWnds[i].WndWeak := nil;
  end;
  SetLength(FInternalWnds, Length(FInternalWnds)-1);
end;

//IAPIEventCollection
function TCoreWrapper.RegisterEvent(AModule: TGUID; const AEventName: WideString; const AEvent: IAPIEvent): Integer; safecall;
var i: integer;
weak_temp: IAPIWeakRefSupport;
begin
  Result := -1;

  if Supports(AEvent, IAPIWeakRefSupport, weak_temp) = false then exit;

  inc(FCurrentEventID);
  if FCurrentEventID > cMaxID then FCurrentEventID := 0;
  i := EventCollectionCount;
  SetLength(FInternalEvents, i+1);
  FInternalEvents[i].Module := AModule;
  FInternalEvents[i].Name := AEventName;
  FInternalEvents[i].ID := FCurrentEventID;
  weak_temp.GetWeakRef(FInternalEvents[i].EventWeak);

  weak_temp := nil;

  Result := FCurrentEventID;
end;

function TCoreWrapper.UnregisterEvent(AID: Integer): WordBool; safecall;
var i, j: integer;
temp: IUnknown;
EventTemp: IAPIEvent;
begin
  Result := false;

  j := -1;
  for i := Low(FInternalEvents) to High(FInternalEvents) do
    if FInternalEvents[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  //FInternalEvents[j].Event.UnsubscribeAll;
  if FInternalEvents[j].EventWeak.GetRef(temp) = true then
    if Supports(temp, IAPIEvent, EventTemp) = true then
      EventTemp.UnsubscribeAll;
  temp := nil;
  EventTemp := nil;

  if DeleteInternalEvent(j) = false then exit;

  Result := true;
end;

function TCoreWrapper.get_EventCollectionCount: Integer; safecall;
begin
  Result := Length(FInternalEvents);
end;

function TCoreWrapper.GetEventByIndex(AIndex: Integer; out AEvent: IAPIEvent): WordBool; safecall;
var temp: IUnknown;
begin
  Result := false;
  AEvent := nil;

  if (AIndex < Low(FInternalEvents))or(AIndex > High(FInternalEvents)) then exit;
  if FInternalEvents[AIndex].EventWeak.GetRef(temp) = true then
    if Supports(temp, IAPIEvent, AEvent) = true then
      Result := true;

  temp := nil;
end;

function TCoreWrapper.GetEventName(AIndex: Integer; out AName: WideString): WordBool; safecall;
begin
  Result := false;

  if (AIndex < Low(FInternalEvents))or(AIndex > High(FInternalEvents)) then exit;
  AName := FInternalEvents[AIndex].Name;

  Result := true;
end;

function TCoreWrapper.GetEventModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
begin
  Result := false;

  if (AIndex < Low(FInternalEvents))or(AIndex > High(FInternalEvents)) then exit;
  AModule := FInternalEvents[AIndex].Module;

  Result := true;
end;

function TCoreWrapper.GetEventByID(AID: Integer; out AEvent: IAPIEvent): WordBool; safecall;
var i, j: integer;
temp: IUnknown;
begin
  Result := false;
  AEvent := nil;

  j := -1;
  for i := Low(FInternalEvents) to High(FInternalEvents) do
    if FInternalEvents[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  if FInternalEvents[j].EventWeak.GetRef(temp) = true then
    if Supports(temp, IAPIEvent, AEvent) = true then
      Result := true;

  temp := nil;
end;

function TCoreWrapper.GetEventByIndexWeak(AIndex: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
begin
  Result := false;
  AEvent := nil;

  if (AIndex < Low(FInternalEvents))or(AIndex > High(FInternalEvents)) then exit;
  AEvent := FInternalEvents[AIndex].EventWeak;

  Result := true;
end;

function TCoreWrapper.GetEventByIDWeak(AID: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
var i, j: integer;
begin
  Result := false;
  AEvent := nil;

  j := -1;
  for i := Low(FInternalEvents) to High(FInternalEvents) do
    if FInternalEvents[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;


  AEvent := FInternalEvents[j].EventWeak;
  Result := true;
end;

//IAPICoreWndsCollection
function TCoreWrapper.get_WndsCollectionCount: Integer; safecall;
begin
  Result := Length(FInternalWnds);
end;

function TCoreWrapper.RegisterWindow(AModule: TGUID; const AWindowName: WideString; const AWindow: IAPIWindow): Integer; safecall;
var i: integer;
weak_temp: IAPIWeakRefSupport;
begin
  Result := -1;

  if Supports(AWindow, IAPIWeakRefSupport, weak_temp) = false then exit;

  inc(FCurrentWndsID);
  if FCurrentWndsID > cMaxID then FCurrentEventID := 0;
  i := WndsCollectionCount;
  SetLength(FInternalWnds, i+1);
  FInternalWnds[i].Module := AModule;
  FInternalWnds[i].Name := AWindowName;
  FInternalWnds[i].ID := FCurrentWndsID;
  weak_temp.GetWeakRef(FInternalWnds[i].WndWeak);

  weak_temp := nil;

  Result := FCurrentWndsID;
end;

function TCoreWrapper.UnregisterWindow(AID: Integer): WordBool; safecall;
var i, j: integer;
temp: IUnknown;
WndTemp: IAPIWindow;
begin
  Result := false;

  j := -1;
  for i := Low(FInternalWnds) to High(FInternalWnds) do
    if FInternalWnds[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  //FInternalEvents[j].Event.UnsubscribeAll;
  if FInternalWnds[j].WndWeak.GetRef(temp) = true then
    if Supports(temp, IAPIWindow, WndTemp) = true then
      WndTemp.CloseWindow;
  temp := nil;
  WndTemp := nil;

  if DeleteInternalWindow(j) = false then exit;

  Result := true;
end;

function TCoreWrapper.GetWindowName(AIndex: Integer; out AName: WideString): WordBool; safecall;
begin
  Result := false;

  if (AIndex < Low(FInternalWnds))or(AIndex > High(FInternalWnds)) then exit;
  AName := FInternalWnds[AIndex].Name;

  Result := true;
end;

function TCoreWrapper.GetWindowModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
begin
  Result := false;

  if (AIndex < Low(FInternalWnds))or(AIndex > High(FInternalWnds)) then exit;
  AModule := FInternalWnds[AIndex].Module;

  Result := true;
end;

function TCoreWrapper.GetWindowByIndex(AIndex: Integer; out AWindow: IAPIWindow): WordBool; safecall;
var temp: IUnknown;
begin
  Result := false;
  AWindow := nil;

  if (AIndex < Low(FInternalWnds))or(AIndex > High(FInternalWnds)) then exit;
  if FInternalWnds[AIndex].WndWeak.GetRef(temp) = true then
    if Supports(temp, IAPIWindow, AWindow) = true then
      Result := true;

  temp := nil;
end;

function TCoreWrapper.GetWindowByID(AID: Integer; out AWindow: IAPIWindow): WordBool; safecall;
var i, j: integer;
temp: IUnknown;
begin
  Result := false;
  AWindow := nil;

  j := -1;
  for i := Low(FInternalWnds) to High(FInternalWnds) do
    if FInternalWnds[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  if FInternalWnds[j].WndWeak.GetRef(temp) = true then
    if Supports(temp, IAPIWindow, AWindow) = true then
      Result := true;

  temp := nil;
end;

function TCoreWrapper.GetWindowByIndexWeak(AIndex: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
begin
  Result := false;
  AWindow := nil;

  if (AIndex < Low(FInternalWnds))or(AIndex > High(FInternalWnds)) then exit;
  AWindow := FInternalWnds[AIndex].WndWeak;

  Result := true;
end;

function TCoreWrapper.GetWindowByIDWeak(AID: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
var i, j: integer;
temp: IUnknown;
begin
  Result := false;
  AWindow := nil;

  j := -1;
  for i := Low(FInternalWnds) to High(FInternalWnds) do
    if FInternalWnds[i].ID = AID then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  AWindow := FInternalWnds[j].WndWeak;

  Result := true;
  temp := nil;
end;

function TCoreWrapper.get_ApplicationWnd: Pointer; safecall;
begin
  Result := Pointer(Application.Handle);
end;

function TCoreWrapper.get_MainWnd: Pointer; safecall;
begin
  Result := Pointer(Application.MainFormHandle);
end;

function TCoreWrapper.get_ActiveWnd: Pointer; safecall;
begin
  Result := Pointer(Application.ActiveFormHandle);
end;

function TCoreWrapper.get_MDIClientWnd: Pointer; safecall;
begin
  Result := Pointer(Application.MainForm.ClientHandle);
end;

procedure TCoreWrapper.ModalStart; safecall;
begin
  Application.ModalStarted;
end;

procedure TCoreWrapper.ModalFinish; safecall;
begin
  Application.ModalFinished;
end;

end.
