unit Unit5;

interface

implementation

uses
  SysUtils
  ,Windows
  ,Classes
  ,uPluginAPIDLLHeader
  ,uPluginAPIHeader
  ,PluginAPI_TLB
  ,uCustomClasses
  ,uPluginConsts
  ,Unit6
  ;

type
  TMainThreadEvent = class(TCheckedInterfacedObject, IInterface, IAPIWeakRefSupport, IAPIEvent)
  private
    FSubscribers: TSubscriberArray;

    function DeleteInternalSubscriber(AIndex: integer): boolean;
    //IAPIEvent
    function get_EventSubscribersCount: Integer; safecall;
  public
    destructor Destroy; override;

    //IAPIEvent
    procedure FireEvent(const AParam: WideString); safecall;
    function Subscribe(var ASubscriber: IAPIEventSubscriber; const ASubscriberDescription: WideString): WordBool; safecall;
    function Unsubscribe(var ASubscriber: IAPIEventSubscriber): WordBool; safecall;
    function UnsubscribeAll: WordBool; safecall;
    function GetSubscribersDescriptions: WideString; safecall;

    property EventSubscribersCount: Integer read get_EventSubscribersCount;
  end;

  TMainThread = class(TThread)
  private
    FEventID: integer;
  protected
    procedure Delay(ms: integer);
  public
    FEvent: IAPIEvent;
    //FEvent: TMainThreadEvent;

    constructor Create(Suspended: boolean);
    destructor Destroy; override;

    procedure Execute; override;

    property EventID: integer read FEventID write FEventID;
  end;

var
  mainThr: TMainThread;


{ TMainThread }

constructor TMainThread.Create(Suspended: boolean);
begin
  inherited Create(Suspended);

  FEvent := TMainThreadEvent.Create;
  FreeOnTerminate := false;
end;

destructor TMainThread.Destroy;
begin
  FEvent.UnsubscribeAll;
  FEvent := nil;

  inherited;
end;

procedure TMainThread.Delay(ms: integer);
var start, finish, cur: integer;
begin
  cur := Gettickcount;
  start := cur;
  finish := start + ms;
  while (Terminated = false)and(cur < finish) do
  begin
    sleep(5);
    cur := Gettickcount;
  end;
end;

procedure TMainThread.Execute;
begin
  while not(Terminated) do
  begin
    Delay(5000);

    FEvent.FireEvent(GUIDtoString(cModuleGUID)+' event fired, event ref count='+inttostr((FEvent as TCheckedInterfacedObject).RefCount));
  end;
end;

{ TMainThreadEvent }

destructor TMainThreadEvent.Destroy;
begin
  UnsubscribeAll;
  inherited;
end;

function TMainThreadEvent.DeleteInternalSubscriber(AIndex: integer): boolean;
var i: integer;
begin
  Result := false;

  if (AIndex < Low(FSubscribers))or(AIndex > High(FSubscribers)) then exit;

  for i := AIndex+1 to High(FSubscribers) do
  begin
    FSubscribers[i-1].Subscriber := nil;
    FSubscribers[i-1].Subscriber := FSubscribers[i].Subscriber;
    FSubscribers[i-1].Description := FSubscribers[i].Description;
    FSubscribers[i].Subscriber := nil;
  end;
  SetLength(FSubscribers, Length(FSubscribers)-1);

  Result := true;
end;

procedure TMainThreadEvent.FireEvent(const AParam: WideString); safecall;
var i: integer;
begin
  for i := Low(FSubscribers) to High(FSubscribers) do
    FSubscribers[i].Subscriber.EventFired(AParam);
end;

function TMainThreadEvent.Subscribe(var ASubscriber: IAPIEventSubscriber; const ASubscriberDescription: WideString): WordBool; safecall;
var i: integer;
begin
  Result := false;

  if ASubscriber = nil then exit;

  i := Length(FSubscribers);
  Setlength(FSubscribers, i+1);
  FSubscribers[i].Subscriber := ASubscriber;
  FSubscribers[i].Description := ASubscriberDescription;

  Result := true;
end;

function TMainThreadEvent.Unsubscribe(var ASubscriber: IAPIEventSubscriber): WordBool; safecall;
var i, j: integer;
begin
  Result := false;

  j := -1;
  for i := Low(FSubscribers) to High(FSubscribers) do
    if integer(FSubscribers[i].Subscriber) = integer(ASubscriber) then
    begin
      j := i;
      break;
    end;

  if j = -1 then exit;

  if DeleteInternalSubscriber(j) = false then exit;

  Result := true;
end;

function TMainThreadEvent.UnsubscribeAll: WordBool; safecall;
var i: integer;
begin
  Result := false;

  for i := Low(FSubscribers) to High(FSubscribers) do
    FSubscribers[i].Subscriber := nil;
  Setlength(FSubscribers, 0);

  Result := true;
end;

function TMainThreadEvent.get_EventSubscribersCount: Integer; safecall;
begin
  Result := Length(FSubscribers);
end;

function TMainThreadEvent.GetSubscribersDescriptions: WideString; safecall;
var i: integer;
begin
  Result := '';

  if EventSubscribersCount = 0 then
  begin
    Result := 'Subscribers empty';
    exit;
  end;

  Result := 'Subscribers:' + sLineBreak;

  for i := Low(FSubscribers) to High(FSubscribers) do
  begin
    Result := Result + '#'+ inttostr(i)+' = '+FSubscribers[i].Description;
    if i <> High(FSubscribers) then Result := Result + sLineBreak;
  end;
end;

{ Functions }

function ModuleInit(const ACoreIntf: IUnknown): boolean;
var temp: IAPICoreEventCollection;
b: boolean;
begin
  Result := false;

  if Supports(ACoreIntf, IAPICoreEventCollection, temp) = false then exit;

  mainThr := TMainThread.Create(true);
  mainThr.FEventID := temp.RegisterEvent(cModuleGUID, 'DLLMainThread.Event1', mainThr.FEvent);
  mainThr.Start;

  Form6 := TForm6.Create(ACoreIntf);

  b := Form6.InitializeForm(ACoreIntf);

  temp := nil;

  if (mainThr.FEventID <> -1)and(b <> false) then Result := true;
end;

procedure ModuleDone(const ACoreIntf: IUnknown);
var temp: IAPICoreEventCollection;
begin
  mainThr.Terminate;
  mainThr.WaitFor;

  if Supports(ACoreIntf, IAPICoreEventCollection, temp) = false then EPluginAPIInitializeError.Create('Core interface does not support IAPIEventCollection');
  if temp.UnregisterEvent(mainThr.FEventID) = false then EPluginAPIInitializeError.Create('IAPIEventCollection can''t unregister event');
  temp := nil;

  mainThr.Free;
  mainThr := nil;

  Form6.FinalizeForm(ACoreIntf);
  Form6.Free;

  sleep(100);
  //APIObject.Free;
  //APIObject:=nil;
  //APIObjectIntf := nil;
end;

procedure OnAfterGetAPI(const AIID: TGUID);
begin
  //i:=(GlobAPIObjectIntf as TPluginAPIObject).RefCount;
  //outputdebugstring(PChar(inttostr(i)));
  sleep(100);
end;

initialization
  GlobAPIDLLInitializeFunc := ModuleInit;
  GlobAPIDLLFinalizeFunc := ModuleDone;
  GlobGetAPIOnExit := OnAfterGetAPI;

finalization
  GlobAPIDLLInitializeFunc := nil;
  GlobAPIDLLFinalizeFunc := nil;

end.
