unit uCustomForms;

interface

uses
  Vcl.Forms
  ,System.Classes
  ,System.Rtti
  ,PluginAPI_TLB
  ,uPluginAPIHeader
  ,uCustomClasses
  ;

type
  //forward declaration
  TComponentEvent = class;

  TEventRec = record
    Event: TComponentEvent;
    EventName: string;
    ModuleGUID: TGUID;
    EventID: integer;
    HookedMethod: TRttiMethod;
    MethodImpl: TMethodImplementation;
    ObjInstance: TComponent;
    PropertyName: string;
  end;
  TEventArray = array of TEventRec;

  TForm = class abstract(Vcl.Forms.TForm, IAPIWindow, IAPIWeakRefSupport)
  private
    FCoreApp: IAPICoreAppWnds;
    FCoreEventCollection: IAPICoreEventCollection;
    FSelfWeakRef: IAPIWeakRef;
    FCurWndID: integer;
    FRttiContext: TRttiContext;
    FContextCreated: boolean;
    FEventArr: TEventArray;
    FEventExclusionArr: TStringArray;

    function GetComponentFullName(Instance: TComponent): string;
    function MatchesMasks(AString: string; const AMasks: TStringArray): boolean;
  protected
    function CreateNewEvent(AInstance: TComponent; AHookedMethod: TRttiMethod; AEventName: string; AGUID: TGUID; APropName: string): boolean;
    procedure CreateEvents;
    procedure CallBackHook(UserData: Pointer; const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create(const ACore: IUnknown); reintroduce;
    destructor Destroy; override;

    function InitializeForm(const ACoreIntf: IUnknown): boolean;
    procedure FinalizeForm(const ACoreIntf: IUnknown);
    procedure Log(message: string); virtual; abstract;

    procedure ClearEventExclusions;
    function AddEventExclusionMask(AMask: string): boolean;
    procedure InitializeEventExclusions; virtual;
    function ActivateEventHook(AID: integer): boolean;

    //IAPIWindow
    procedure ShowWindow; safecall;
    function ShowModalWindow: Integer; safecall;
    procedure CloseWindow; safecall;

    //IAPIWeakRefSupport
    procedure GetWeakRef(out ReturnValue: IAPIWeakRef); safecall;

    property CurrentWindowID: integer read FCurWndID;
  end;

  IHookInterface = interface(IUnknown)
  ['{7719E8F1-2A32-498C-A851-ACA2B116385F}']
    function GetHookedMethod: TRttiMethod;
    procedure GetEvent(out AEvent: IAPIEvent);
  end;

  TComponentEvent = class(TCheckedInterfacedObjectNoCount, IAPIEvent, IAPIWeakRefSupport{TCheckedInterfacedObject}, IHookInterface)
  private
    FSubscribers: TSubscriberArray;
    FHookedMethod: TRttiMethod;
    FEventID: integer;
    FOwner: uCustomForms.TForm;

    function DeleteInternalSubscriber(AIndex: integer): boolean;

    //IAPIEvent
    function get_EventSubscribersCount: Integer; safecall;
  public
    constructor Create(AMethod: TRttiMethod; AOwner: uCustomForms.TForm);
    destructor Destroy; override;

    //IAPIEvent
    procedure FireEvent(const AParam: WideString); safecall;
    function Subscribe(var ASubscriber: IAPIEventSubscriber; const ASubscriberDescription: WideString): WordBool; safecall;
    function Unsubscribe(var ASubscriber: IAPIEventSubscriber): WordBool; safecall;
    function UnsubscribeAll: WordBool; safecall;
    function GetSubscribersDescriptions: WideString; safecall;
    property EventSubscribersCount: Integer read get_EventSubscribersCount;

    //IHookInterface
    function GetHookedMethod: TRttiMethod;
    procedure GetEvent(out AEvent: IAPIEvent);

    property EventID: integer read FEventID write FEventID;
  end;

implementation

uses
  SysUtils
  ,System.Masks
  ,System.TypInfo
  ,uPluginConsts
  ;

{ TForm }

constructor TForm.Create(const ACore: IUnknown);
begin
  inherited Create(nil);

  FContextCreated := false;

  if Supports(ACore, IAPICoreAppWnds, FCoreApp) = false then EPluginAPIInitializeError.Create('Failed to initialize form, Core doesn''t support IAPICoreAppWnds');
  if Supports(ACore, IAPICoreEventCollection, FCoreEventCollection) = false then EPluginAPIInitializeError.Create('Failed to initialize form, Core doesn''t support IAPICoreAppWnds');

  FRttiContext := TRttiContext.Create;
  FContextCreated := true;
end;

destructor TForm.Destroy;
var i: integer;
begin
  for i := Low(FEventArr) to High(FEventArr) do
  begin
    FEventArr[i].Event.UnsubscribeAll;
    FCoreEventCollection.UnregisterEvent(FEventArr[i].EventID);
    if FEventArr[i].Event <> nil then
      FEventArr[i].Event.Free;
    FEventArr[i].Event := nil;
    if FEventArr[i].MethodImpl <> nil then
      FEventArr[i].MethodImpl.Free;
    FEventArr[i].MethodImpl := nil;
    FEventArr[i].ObjInstance := nil;
  end;
  SetLength(FEventArr, 0);

  if FContextCreated = false then
    FRttiContext.Free;

  FCoreApp := nil;
  FCoreEventCollection := nil;
  FSelfWeakRef := nil;

  inherited;
end;

function TForm.GetComponentFullName(Instance: TComponent): string;
begin
  Result := '';

  if Instance.HasParent = true then
    Result := GetComponentFullName(Instance.GetParentComponent)+'.'+Instance.Name
  else
    Result := Instance.Name;
end;

function TForm.MatchesMasks(AString: string; const AMasks: TStringArray): boolean;
var i: integer;
begin
  Result := false;

  for i := Low(AMasks) to High(AMasks) do
    if System.Masks.MatchesMask(AString, AMasks[i]) = true then
    begin
      Result := true;
      exit;
    end;
end;

procedure TForm.CallBackHook(UserData: Pointer; const Args: TArray<TValue>; out Result: TValue);
var WeakRef: IAPIWeakRef;
unk: IUnknown;
hookIntf: IHookInterface;
event: IAPIEvent;
newargs: TArray<TValue>;
rtMethod: TRttiMethod;
i: integer;
begin
  //Log('Hooked proc enter');
  WeakRef := IAPIWeakRef(UserData);
  unk := nil;
  hookIntf := nil;
  event := nil;
  rtMethod := nil;

  if WeakRef.GetRef(unk) = true then
    if Supports(unk, IHookInterface, hookIntf) = false then
      hookIntf := nil;

  if hookIntf = nil then
  begin
    //Log('Can''t get event reference');
    exit;
  end;

  rtMethod := hookIntf.GetHookedMethod;
  if rtMethod = nil then
  begin
    //Log('Wrong method reference');
    exit;
  end;

  SetLength(newargs, Length(Args)-1);
  for i := 1 to Length(Args)-1 do
    newargs[i-1] := Args[i];
  Result := rtMethod.Invoke(Self, newargs);
  //Log('Invoked method='+rtMethod.ToString);

  hookIntf.GetEvent(event);
  if event = nil then
  begin
    //Log('Wrong event reference');
    exit;
  end;

  event.FireEvent('Hooked event for method='+rtMethod.ToString);
end;

function TForm.CreateNewEvent(AInstance: TComponent; AHookedMethod: TRttiMethod; AEventName: string; AGUID: TGUID; APropName: string): boolean;
var i: integer;
begin
  Result := false;

  if AHookedMethod = nil then exit;

  i := Length(FEventArr);
  Setlength(FEventArr, i+1);

  FEventArr[i].Event := TComponentEvent.Create(AHookedMethod, Self);
  FEventArr[i].EventName := AEventName;
  FEventArr[i].ModuleGUID := AGUID;
  FEventArr[i].EventID := -1;
  FEventArr[i].HookedMethod := AHookedMethod;
  FEventArr[i].MethodImpl := nil;
  FEventArr[i].ObjInstance := AInstance;
  FEventArr[i].PropertyName := APropName;

  Result := true;
end;

procedure TForm.CreateEvents;
var ComponentArr: TArray<TComponent>;
i: integer;
str: string;
rtType: TRttiType;
rtProp: TRttiProperty;
rtMethod: TRttiMethod;
rtMethArr: TArray<TRttiMethod>;
rtMethArrSelf: TArray<TRttiMethod>;
propInfo: PPropInfo;
methInfo: TMethod;
WeakUserData: IAPIWeakRef;
begin
  SetLength(ComponentArr, Self.ComponentCount+1);

  for i := 0 to Self.ComponentCount-1 do
    ComponentArr[i] := Self.Components[i];
  ComponentArr[length(ComponentArr)-1] := Self;

  rtType := FRttiContext.GetType(Self.ClassType);
  rtMethArrSelf := rtType.GetMethods;

  for i := Low(ComponentArr) to High(ComponentArr) do
  begin
    rtType := FRttiContext.GetType(ComponentArr[i].ClassType);
    rtMethArr := rtType.GetMethods;

    for rtProp in rtType.GetProperties do
      if (rtProp.PropertyType.TypeKind = tkMethod)and(rtProp.GetValue(ComponentArr[i]).IsEmpty = false) then
      begin
        propInfo := GetPropInfo(ComponentArr[i], rtProp.Name);
        if propInfo <> nil then
        begin
          methInfo := GetMethodProp(ComponentArr[i], rtProp.Name);
          str := cModuleName + '.' + GetComponentFullName(ComponentArr[i]) + '.' + rtProp.Name;
          for rtMethod in rtMethArr do
            if rtMethod.CodeAddress = methInfo.Code then
            begin
              if MatchesMasks(str, FEventExclusionArr) = false then
                if CreateNewEvent(ComponentArr[i], rtMethod, str, cModuleGUID, rtProp.Name) = false then
                  raise Exception.Create('Failed to create event hook for event '+ str + '.' + rtProp.Name);
            end;
          if (rtMethArrSelf <> nil)and(ComponentArr[i] <> Self) then
            for rtMethod in rtMethArrSelf do
              if rtMethod.CodeAddress = methInfo.Code then
              begin
                if MatchesMasks(str, FEventExclusionArr) = false then
                  if CreateNewEvent(ComponentArr[i], rtMethod, str, cModuleGUID, rtProp.Name) = false then
                    raise Exception.Create('Failed to create event hook for event '+ str + '.' + rtProp.Name);
              end;
        end;
      end;
  end;
end;

function TForm.InitializeForm(const ACoreIntf: IUnknown): boolean;
var temp: IAPICoreWndsCollection;
temp2: IAPICoreEventCollection;
i: integer;
begin
  Result := false;

  if Supports(ACoreIntf, IAPICoreWndsCollection, temp) = false then exit;
  if Supports(ACoreIntf, IAPICoreEventCollection, temp2) = false then exit;

  FCurWndID := temp.RegisterWindow(cModuleGUID, cModuleName+'.'+UnitName+'.'+ClassName, Self);
  temp := nil;

  InitializeEventExclusions;
  CreateEvents;
  for i := Low(FEventArr) to High(FEventArr) do
  begin
    FEventArr[i].EventID := temp2.RegisterEvent(FEventArr[i].ModuleGUID, FEventArr[i].EventName, FEventArr[i].Event);
    FEventArr[i].Event.EventID := FEventArr[i].EventID;
  end;

  Result := true;
end;

procedure TForm.FinalizeForm(const ACoreIntf: IUnknown);
var temp: IAPICoreWndsCollection;
begin
  if Supports(ACoreIntf, IAPICoreWndsCollection, temp) = false then exit;

  if temp.UnregisterWindow(CurrentWindowID) = false then EPluginAPIInitializeError.Create('IAPIEventCollection can''t unregister window');
end;

procedure TForm.ShowWindow; safecall;
begin
  Self.Show;
end;

function TForm.ShowModalWindow: Integer; safecall;
begin
  FCoreApp.ModalStart;
  try
    Result := inherited ShowModal;
  finally
    FCoreApp.ModalFinish;
  end;
end;

procedure TForm.CloseWindow; safecall;
begin
  Close;
end;

procedure TForm.GetWeakRef(out ReturnValue: IAPIWeakRef); safecall;
begin
  if FSelfWeakRef = nil then
    FSelfWeakRef := GenerateWeakRef(Self);
  ReturnValue := FSelfWeakRef;
end;

procedure TForm.InitializeEventExclusions;
begin
  ClearEventExclusions;
end;

procedure TForm.ClearEventExclusions;
begin
  Setlength(FEventExclusionArr, 0);;
end;

function TForm.AddEventExclusionMask(AMask: string): boolean;
var i: integer;
begin
  Result := false;

  try
    MatchesMask('Test string', AMask);
  except
    on E: Exception do
      exit;
  end;

  i := Length(FEventExclusionArr);
  SetLength(FEventExclusionArr, i+1);
  FEventExclusionArr[i] := AMask;

  Result := true;
end;

function TForm.ActivateEventHook(AID: integer): boolean;
var i: integer;
WeakRef: IAPIWeakRef;
NewMethod: TMethod;
begin
  Result := false;

  for i := Low(FEventArr) to High(FEventArr) do
    if FEventArr[i].EventID = AID then
    begin
      if FEventArr[i].MethodImpl <> nil then
      begin
        Result := true;
        exit;
      end;

      FEventArr[i].Event.GetWeakRef(WeakRef);

      FEventArr[i].MethodImpl := FEventArr[i].HookedMethod.CreateImplementation(WeakRef, Self.CallBackHook);
      if FEventArr[i].MethodImpl = nil then exit;

      NewMethod.Data := FEventArr[i].ObjInstance;
      NewMethod.Code := FEventArr[i].MethodImpl.CodeAddress;
      SetMethodProp(FEventArr[i].ObjInstance, FEventArr[i].PropertyName, NewMethod);

      Result := true;
      exit;
    end;
end;

{ TComponentEvent }

constructor TComponentEvent.Create(AMethod: TRttiMethod; AOwner: uCustomForms.TForm);
begin
  inherited Create;

  FHookedMethod := AMethod;
  FEventID := -1;
  FOwner := AOwner;
end;

destructor TComponentEvent.Destroy;
begin
  FHookedMethod := nil;

  inherited;
end;

function TComponentEvent.DeleteInternalSubscriber(AIndex: integer): boolean;
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

//IAPIEvent
procedure TComponentEvent.FireEvent(const AParam: WideString); safecall;
var i: integer;
begin
  for i := Low(FSubscribers) to High(FSubscribers) do
    FSubscribers[i].Subscriber.EventFired(AParam);
end;

function TComponentEvent.Subscribe(var ASubscriber: IAPIEventSubscriber; const ASubscriberDescription: WideString): WordBool; safecall;
var i: integer;
begin
  Result := false;

  if ASubscriber = nil then exit;

  if FOwner.ActivateEventHook(EventID) = false then exit;

  i := Length(FSubscribers);
  Setlength(FSubscribers, i+1);
  FSubscribers[i].Subscriber := ASubscriber;
  FSubscribers[i].Description := ASubscriberDescription;

  Result := true;
end;

function TComponentEvent.Unsubscribe(var ASubscriber: IAPIEventSubscriber): WordBool; safecall;
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

function TComponentEvent.UnsubscribeAll: WordBool; safecall;
var i: integer;
begin
  Result := false;

  for i := Low(FSubscribers) to High(FSubscribers) do
    FSubscribers[i].Subscriber := nil;
  Setlength(FSubscribers, 0);

  Result := true;
end;

function TComponentEvent.GetSubscribersDescriptions: WideString; safecall;
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

function TComponentEvent.get_EventSubscribersCount: Integer; safecall;
begin
  Result := Length(FSubscribers);
end;

//IHookInterface
function TComponentEvent.GetHookedMethod: TRttiMethod;
begin
  Result := FHookedMethod;
end;

procedure TComponentEvent.GetEvent(out AEvent: IAPIEvent);
begin
  AEvent := Self;
end;

end.
