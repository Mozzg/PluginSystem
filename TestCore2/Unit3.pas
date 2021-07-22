unit Unit3;

interface

uses
  SysUtils
  ,Forms
  ,Vcl.StdCtrls
  ,System.Classes
  ,Vcl.Controls
  ,uPluginAPIHeader
  ,PluginAPI_TLB
  ,uCustomPluginHeader
  ,uCustomClasses
  ,Rtti, Vcl.ExtCtrls, Vcl.ComCtrls
  ;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button14: TButton;
    Button15: TButton;
    Button16: TButton;
    Button17: TButton;
    Button18: TButton;
    Button19: TButton;
    Button20: TButton;
    Memo2: TMemo;
    Button21: TButton;
    Button22: TButton;
    Button23: TButton;
    Button24: TButton;
    Button25: TButton;
    Button26: TButton;
    Button27: TButton;
    Button28: TButton;
    Button29: TButton;
    TabControl1: TTabControl;
    Panel1: TPanel;
    TestButton: TButton;
    Button30: TButton;
    Button31: TButton;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button17Click(Sender: TObject);
    procedure Button18Click(Sender: TObject);
    procedure Button19Click(Sender: TObject);
    procedure Button20Click(Sender: TObject);
    procedure Button21Click(Sender: TObject);
    procedure Button22Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button23Click(Sender: TObject);
    procedure Button24Click(Sender: TObject);
    function FormAlignInsertBefore(Sender: TWinControl; C1,
      C2: TControl): Boolean;
    procedure Button25Click(Sender: TObject);
    procedure Button26Click(Sender: TObject);
    procedure FormDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure FormDblClick(Sender: TObject); virtual;
    procedure Button27Click(Sender: TObject);
    procedure Button28Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button29Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure TestButtonClick(Sender: TObject);
    procedure TabControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure Panel1Enter(Sender: TObject);
    procedure Button30Click(Sender: TObject);
    procedure Button31Click(Sender: TObject);
  private
    { Private declarations }

    Fcontext: TRttiContext;
    FmethImplem: TMethodImplementation;
  public
    { Public declarations }
    procedure CallBackHack(UserData: Pointer; const Args: TArray<TValue>; out Result: TValue);
    procedure HookTest(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>; var Result: TValue);
  end;

  TEventSubscriberClass = class(TCheckedInterfacedObjectNoCount, IAPIEventSubscriber)
  public
    procedure EventFired(const AParameter: WideString); safecall;
  end;

  TEventSubscriberClass2 = class(TCheckedInterfacedObjectNoCount, IAPIEventSubscriber)
  public
    procedure EventFired(const AParameter: WideString); safecall;
  end;

  TUserParamClass = class(TObject)
  public
    rtMethod: TRttiMethod;
    methID: integer;
  end;

var
  Form3: TForm3;

  Plugin: TPluginWrapper;
  CoreVar: TCoreWrapper;
  //Subscriber: TEventSubscriberClass;
  //Subscriber2: TEventSubscriberClass2;
  Subscribers: array of TEventSubscriberClass;

  FDLLHandle: HMODULE;
  FDLLProc: TExportedFunction_safecall;

  TempIntf: IUnknown;

  intfDebugRefCount: IDebugRefCount = nil;

  //WeakRefTestObj:TCheckedInterfacedObject;
  WeakRefTestObj: IUnknown;
  WeakRef: IAPIWeakRef;
  WeakRef2: IAPIWeakRef;

  //t1: TCheckedInterfacedObject;
  t1: IUnknown;

  Interceptor: TVirtualMethodInterceptor;

  UserParams: TUserParamClass;

implementation

uses
  Windows
  ,ActiveX
  ,TypInfo
  ,ObjAuto
  , Unit9;

{$R *.dfm}

type
  PPublishedMethod = ^TPublishedMethod;
  TPublishedMethod = packed record
    Size: word;
    Address: Pointer;
    Name: {packed} ShortString; // на самом деле string[Length(Name)]
  end;
  TPublishedMethods = packed array[0..High(Word)-1] of TPublishedMethod;
  PPublishedMethodTable = ^TPublishedMethodTable;
  TPublishedMethodTable = packed record
    Count: Word;
    Methods: TPublishedMethods; // на самом деле [0..Count-1]
  end;

  PMethodParam = ^TMethodParam;
  TMethodParam = record
    Flags: TParamFlags;
    ParamName: PShortString;
    TypeName: PShortString;
  end;
  TMethodParamList = array of TMethodParam;
  PMethodSignature = ^TMethodSignature;
  TMethodSignature = record
    MethodKind: TMethodKind;
    ParamCount: Byte;
    ParamList: TMethodParamList;
    ResultType: PShortString;
  end;

{$M+}
  TMyClass = class(TObject)
  published
    procedure FirstPublished;
    procedure SecondPublished(A: integer);
    procedure ThirdPublished(A: integer); stdcall;
  end;
  {$M-}

procedure TMyClass.FirstPublished;
begin

end;

procedure TMyClass.SecondPublished(A: integer);
begin

end;

procedure TMyClass.ThirdPublished(A: integer); stdcall;
begin

end;

procedure Log(mess: string);
begin
  form3.Memo1.Lines.Add(mess);
end;

function PackedShortString(Value: PShortstring; var NextField{: Pointer}): PShortString; overload;
begin
  Result := Value;
  PShortString(NextField) := Value;
  Inc(PChar(NextField), SizeOf(Result^[0]) + Length(Result^));
end;

function PackedShortString(var NextField{: Pointer}): PShortString; overload;
begin
  Result := PShortString(NextField);
  Inc(PChar(NextField), SizeOf(Result^[0]) + Length(Result^));
end;

function GetMethodSignature(meth: PTypeData): TMethodSignature;
type
  PParamListRecord = ^TParamListRecord;
  TParamListRecord = packed record
    Flags: TParamFlags;
    ParamName: {packed} ShortString; // на самом деле: string[Length(ParamName)]
    TypeName:  {packed} ShortString; // на самом деле: string[Length(TypeName)]
  end;
var
  EventData: PTypeData;
  i: integer;
  MethodParam: PMethodParam;
  ParamListRecord: PParamListRecord;
begin
  EventData := meth;
  Result.MethodKind := EventData.MethodKind;
  Result.ParamCount := EventData.ParamCount;
  SetLength(Result.ParamList, Result.ParamCount);

  ParamListRecord := PParamListRecord (@(EventData.ParamList));

  for i := 0 to Result.ParamCount - 1 do
  begin
    Result.ParamList[i].Flags:=ParamListRecord^.Flags;
    Result.ParamList[i].ParamName:=@ParamListRecord^.ParamName;
    Result.ParamList[i].TypeName:=Pointer(Integer(ParamListRecord) + sizeof(TParamFlags) + Length(Result.ParamList[i].ParamName^) + 1);

    ParamListRecord := Pointer(Integer(ParamListRecord) + sizeof(TParamFlags) + Length(Result.ParamList[i].ParamName^) + 1 + Length(Result.ParamList[i].TypeName^) + 1);
    //MethodParam := @Result.ParamList[i];
    //MethodParam.Flags     := ParamListRecord.Flags;
    //MethodParam.ParamName := PackedShortString(@ParamListRecord.ParamName, ParamListRecord);
    //MethodParam.TypeName  := PackedShortString(ParamListRecord);
  end;
  //Result.ResultType := PackedShortString(ParamListRecord);
  Result.ResultType := Pointer(ParamListRecord);
end;

procedure DumpPublishedMethods(AClass: TClass);
var p: ^Pointer;
ppmt: PPublishedMethodTable;
ppm: PPublishedMethod;
i: integer;
begin
  while Assigned(AClass) do
  begin
    p := Pointer(Integer(AClass) + vmtMethodtable);
    ppmt := p^;
    ppm := @ppmt^.Methods[0];

    Log('Published methods in '+AClass.ClassName+', Method count='+inttostr(ppmt^.Count));
    for i := 1 to ppmt^.Count do
    begin
      with ppm^ do
        Log(format('  %d: len: %d, adr: %p, name: %s', [i, Size, Address, Name]));

      ppm := Pointer(Integer(ppm) + ppm^.Size);
    end;

    AClass := AClass.ClassParent;
  end;
end;

procedure TForm3.Button10Click(Sender: TObject);
begin
  if Assigned(WeakRef)=false then
  begin
    Log('Reference is not assigned');
    exit;
  end;

  Log('Alive='+booltostr(WeakRef.IsWeakRefAlive,true));
  {if WeakRef.GetRef(temp)=false then
  begin
    Log('GetRef failed');
    exit;
  end;      }

  //Log('Object='+(temp as TCheckedInterfacedObject).DebugName);

  Log('Done test')
end;

procedure TEventSubscriberClass.EventFired(const AParameter: WideString); safecall;
begin
  Log('Event fired with parameter='+AParameter);
end;

procedure TEventSubscriberClass2.EventFired(const AParameter: WideString); safecall;
begin
  form3.Memo2.Lines.Add('Event, message='+AParameter);
end;

procedure TForm3.Button11Click(Sender: TObject);
begin
  //WeakRefTestObj.Free;
  WeakRefTestObj := nil;
  //WeakRef := nil;

  Log('Free done');
end;

procedure TForm3.Button12Click(Sender: TObject);
var WeakRefSupp: IAPIWeakRefSupport;
begin
  t1:=TCheckedInterfacedObject.Create;

  if Supports(t1, IAPIWeakRefSupport, WeakRefSupp) = true then
  begin
    Log('WeakRef supported');

    WeakRefSupp.GetWeakRef(WeakRef);
  end
  else
  begin
    Log('WeakRef not supported');
  end;

  WeakRefSupp := nil;

  Log('Created');
end;

procedure TForm3.Button13Click(Sender: TObject);
begin
  //t1.Free;
  t1:=nil;

  WeakRef := nil;

  Log('Freed');
end;

procedure TForm3.Button14Click(Sender: TObject);
begin
  if Assigned(t1) then
    Log('RefCount='+inttostr((t1 as TCheckedInterfacedObject).RefCount))
  else
    Log('t1 is not assigned');

  if Assigned(WeakRef) then
    Log('WeakRef refcount='+inttostr((WeakRef as TWeakRef).RefCount))
  else
    Log('WeakRef is not assigned');
end;

procedure TForm3.Button15Click(Sender: TObject);
var WeakRefSupp: IAPIWeakRefSupport;
begin
  if Supports(t1, IAPIWeakRefSupport, WeakRefSupp) = true then
  begin
    Log('WeakRef supported');

    WeakRefSupp.GetWeakRef(WeakRef2);
    Log('Weak ref2 generated');
    Log('RefCount='+inttostr((t1 as TCheckedInterfacedObject).RefCount));
  end
  else
  begin
    Log('WeakRef not supported');
  end;

  WeakRefSupp := nil;

  Log('Done');
  Log('RefCount='+inttostr((t1 as TCheckedInterfacedObject).RefCount))
end;

procedure TForm3.Button16Click(Sender: TObject);
var temp: IUnknown;
//temp: Pointer;
begin
  Log('RefCount on enter='+inttostr((t1 as TCheckedInterfacedObject).RefCount));
  if WeakRef2.GetRef(temp)=false then
  begin
    Log('GetRef failed');
    exit;
  end;
  Log('RefCount after getref='+inttostr((t1 as TCheckedInterfacedObject).RefCount));

  Log('Name='+(temp as TCheckedInterfacedObject).DebugName);
  //Log('Name='+(IUnknown(temp) as TCheckedInterfacedObject).DebugName);
  //Log('RefCount='+inttostr((temp as TCheckedInterfacedObject).RefCount));
  temp:=nil;
  Log('RefCount after nil='+inttostr((t1 as TCheckedInterfacedObject).RefCount));

  Log('Done');
end;

procedure TForm3.Button17Click(Sender: TObject);
begin
  Log('-------Status-------');
  Log(Plugin.GetPluginStatus);
end;

procedure TForm3.Button18Click(Sender: TObject);
type
  TMethodtableEntry = packed record
    len: Word;
    adr: Pointer;
    name: ShortString;
  end;
  //Note: name occupies only the size required, so it is not a true shortstring! The actual
  //entry size is variable, so the method table is not an array of TMethodTableEntry!
var aClass: TClass;
pp: ^Pointer;
pMethodTable: Pointer;
pMethodEntry: ^TMethodTableEntry;
i, numEntries: Word;
begin
  //AClass := form3.ClassType;
  AClass := TMyClass;

  if aClass = nil then
    Exit;
  pp := Pointer(Integer(aClass) + vmtMethodtable);
  pMethodTable := pp^;
  memo2.Lines.Add(format('Class %s: method table at %p', [aClass.Classname,
    pMethodTable]));
  if pMethodtable <> nil then
  begin
    //first word of the method table contains the number of entries
    numEntries := PWord(pMethodTable)^;
    memo2.Lines.Add(format('  %d published methods', [numEntries]));
    //make pointer to first method entry, it starts at the second word of the table
    pMethodEntry := Pointer(Integer(pMethodTable) + 2);
    for i := 1 to numEntries do
    begin
      with pMethodEntry^ do
        memo2.Lines.Add(format('  %d: len: %d, adr: %p, name: %s', [i, len, adr,
          name]));
      //make pointer to next method entry
      pMethodEntry := Pointer(Integer(pMethodEntry) + pMethodEntry^.len);
    end;
  end;

  {procedure GetMethodList(AClass: TClass; AList: TStrings);
type
  TMethodNameRec = packed record
    name : pshortstring;
    addr : pointer;
  end;

  TMethodNameTable = packed record
    count : dword;
    entries : packed array[0..0] of TMethodNameRec;
  end;

  pMethodNameTable =  ^TMethodNameTable;

var
  methodTable : pMethodNameTable;
  i : dword;
  vmt: TClass;
  idx: integer;
begin
  AList.Clear;
  vmt := aClass;
  while assigned(vmt) do
  begin
    methodTable := pMethodNameTable((Pointer(vmt) + vmtMethodTable)^);
    if assigned(MethodTable) then
    begin
      for i := 0 to MethodTable^.count - 1 do
      begin
        idx := aList.IndexOf(MethodTable^.entries[i].name^);
        if (idx <> - 1) then
        //found overridden method so delete it
          aList.Delete(idx);
        aList.AddObject(MethodTable^.entries[i].name^, TObject(MethodTable^.entries[i].addr));
      end;
    end;
    vmt := pClass(pointer(vmt) + vmtParent)^;
  end;
end;    }

{procedure EnumMethods(aClass: TClass; lines: TStrings);

type
  TMethodtableEntry = packed record
    len: Word;
    adr: Pointer;
    name: ShortString;
  end;
  Note: name occupies only the size required, so it is not a true shortstring! The actual
  entry size is variable, so the method table is not an array of TMethodTableEntry!

var
  pp: ^Pointer;
  pMethodTable: Pointer;
  pMethodEntry: ^TMethodTableEntry;
  i, numEntries: Word;
begin
  if aClass = nil then
    Exit;
  pp := Pointer(Integer(aClass) + vmtMethodtable);
  pMethodTable := pp^;
  lines.Add(format('Class %s: method table at %p', [aClass.Classname,
    pMethodTable]));
  if pMethodtable <> nil then
  begin
    first word of the method table contains the number of entries
    numEntries := PWord(pMethodTable)^;
    lines.Add(format('  %d published methods', [numEntries]));
    make pointer to first method entry, it starts at the second word of the table
    pMethodEntry := Pointer(Integer(pMethodTable) + 2);
    for i := 1 to numEntries do
    begin
      with pMethodEntry^ do
        lines.Add(format('  %d: len: %d, adr: %p, name: %s', [i, len, adr,
          name]));
      make pointer to next method entry
      pMethodEntry := Pointer(Integer(pMethodEntry) + pMethodEntry^.len);
    end;
  end;
  EnumMethods(aClass.ClassParent, lines);
end;}
end;

procedure TForm3.Button19Click(Sender: TObject);
var count, i: integer;
name, module: widestring;
guid: TGUID;
temp: IAPIEvent;
begin
  if CoreVar = nil then
  begin
    Log('CoreVar is nil, exiting');
    exit;
  end;

  count := CoreVar.EventCollectionCount;
  Log('Event count='+inttostr(count));

  form3.ListBox1.Items.Clear;

  for i := 0 to count-1 do
  begin
    if CoreVar.GetEventName(i, name) = false then Log('Failed to retrieve event name');
    if CoreVar.GetEventModule(i, guid) = false then Log('Failed to retrieve event module');

    form3.ListBox1.Items.Add(name);

    module := GUIDtoString(guid);
    Log('Event #'+inttostr(i)+': Name='+name+', Module='+module);

    if CoreVar.GetEventByIndex(i, temp) = false then Log('Failed to retrieve event')
    else Log(temp.GetSubscribersDescriptions);

    temp := nil;
  end;
end;

procedure TForm3.Button1Click(Sender: TObject);
var path, strClass, str: string;
cl: TClass;
begin
  try
  if CoreVar = nil then CoreVar:=TCoreWrapper.Create;
  //if Subscriber = nil then Subscriber:=TEventSubscriberClass.Create;
  //if Subscriber2 = nil then Subscriber2:=TEventSubscriberClass2.Create;

  path := ExtractFilePath(ParamStr(0))+'..\..\..\TestDLL3\Win32\Debug\TestDLL3.dll';
  Log('Path='+path);

  Plugin := TPluginWrapper.Create(path, CoreVar);
  if Plugin.DLLLoaded = true then
    Log('Loaded sucsessfuly')
  else
    Log('Error loading plugin');

  if Plugin.InitializeModule = false then
    Log('Module failed to initialize')
  else
    Log('Initialize sucsessfuly');

  //Log('Module name='+Plugin.ModuleName);

  Log('RefCount='+inttostr(Plugin.GetModuleRefCount));

  {PluginHandle := LoadDLL(path);
  if PluginHandle <> 0 then
  begin
    Log('Failed to load plugin: '+path);
    exit;
  end;

  PluginFunc := GetProcAddress(PluginHandle, APIProcName);
  if not(Assigned(PluginFunc)) then
  begin
    Log('Failed to load plugin function');
    UnloadDLL(PluginHandle);
    exit;
  end;    }
  except
    on E: Exception do
    begin
      if E.InheritsFrom(EBaseCustomException) then
      begin
        strClass:=EBaseCustomException(E).WrappedException;
        str:=e.ClassName;

        Application.MessageBox(PChar(Format(
          'Класс: %s(%s)' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d'
          //'Оригинальное исключение: %s'
          ,
         [//E.ClassName,
          str,
          strClass,
          E.Message,
          IntToHex(EBaseCustomException(E).ErrorCode, 8),
          'don''t have one',
          EBaseCustomException(E).Source,
          EBaseCustomException(E).HelpFile,
          EBaseCustomException(E).HelpContext
          //EBaseCustomException(E).WrappedException.ClassName
          //strClass
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
      begin
        Application.MessageBox(PWideChar('Exception '+e.ClassName+' with message: '+e.Message), 'Исключение', MB_OK or MB_ICONERROR);
        //raise;
      end;
    end;
  end;
end;

procedure TForm3.Button20Click(Sender: TObject);
var event: IAPIEvent;
sub: IAPIEventSubscriber;
weak: IAPIWeakRef;
unk: IUnknown;
i: integer;
begin
  if CoreVar = nil then
  begin
    Log('CoreVar is nill, exiting');
    exit;
  end;

  {if Subscriber = nil then
  begin
    Log('Subscriber is nill, exiting');
    exit;
  end;

  if Subscriber2 = nil then
  begin
    Log('Subscriber2 is nill, exiting');
    exit;
  end;   }

  if CoreVar.EventCollectionCount < 1 then
  begin
    Log('No events to subscribe, exiting');
    exit;
  end;

  i := form3.ListBox1.ItemIndex;
  if i = -1 then exit;

  if CoreVar.GetEventByIndexWeak(i, weak) = false then Log('Error retrieving weak event reference');
  if weak.GetRef(unk) = false then Log('Error retrieving normal reference from weak');
  if Supports(unk, IAPIEvent, event) = false then Log('Error retrieving event interface');
  
  i := length(Subscribers);
  setlength(Subscribers, i+1);
  Subscribers[i] := TEventSubscriberClass.Create;
  if Supports(Subscribers[i], IAPIEventSubscriber, sub) = false then Log('Failed to extract subscriber interface');
  if event.Subscribe(sub, 'Main memo event') = false then Log('Error subscribing to event 1');

  //sub := nil;
  //if Supports(Subscriber2, IAPIEventSubscriber, sub) = false then Log('Failed to extract subscriber2 interface');
  //if event.Subscribe(sub, 'Secondary memo event') = false then Log('Error subscribing to event 2');

  weak := nil;
  unk := nil;
  event := nil;
  sub:=nil;


  {if CoreVar.GetEventByIndex(0, event) = false then Log('Error retrieving event');
  if Supports(Subscriber, IAPIEventSubscriber, sub) = false then Log('Failed to extract subscriber interface');
  if event.Subscribe(sub) = false then Log('Error subscribing to event');

  event := nil;
  sub:=nil;  }

  Log('Subscribed sucsessfuly');
end;

procedure TForm3.Button21Click(Sender: TObject);
var count, i: integer;
name, module: widestring;
guid: TGUID;
//temp: IAPIEvent;
begin
  if CoreVar = nil then
  begin
    Log('CoreVar is nil, exiting');
    exit;
  end;

  count := CoreVar.WndsCollectionCount;
  Log('Windows count='+inttostr(count));

  for i := 0 to count-1 do
  begin
    if CoreVar.GetWindowName(i, name) = false then Log('Failed to retrieve window name');
    if CoreVar.GetWindowModule(i, guid) = false then Log('Failed to retrieve window module');

    module := GUIDtoString(guid);
    Log('Window #'+inttostr(i)+': Name='+name+', Module='+module);

    //if CoreVar.GetEventByIndex(i, temp) = false then Log('Failed to retrieve event')
    //else Log(temp.GetSubscribersDescriptions);
    //temp := nil;
  end;
end;

procedure TForm3.Button22Click(Sender: TObject);
var temp: IAPIWindow;
begin
  if CoreVar = nil then
  begin
    Log('CoreVar is nill, exiting');
    exit;
  end;

  if CoreVar.GetWindowByIndex(0, temp) = false then Assert(false);

  temp.ShowWindow;

  temp := nil;
end;

procedure TForm3.Button23Click(Sender: TObject);
var context: TRTTIContext;
ltype: TRttiType;
lmethod: TRttiMethod;
lmettype: TRttiMethodType;
lprop: TRttiProperty;
lfield: TRttiField;
str:string;
val: TValue;
met: TMethod;
methodsig: TMethodSignature;
i: integer;
handlerImpl : TMethodImplementationCallback;
mi : TMethodImplementation;
begin
  context := TRTTIContext.Create;
  try
    ltype := context.GetType(form3.ClassType);

    {Log('Methods:');
    for lmethod in ltype.GetDeclaredMethods do
      Log(lmethod.ToString);   }

    Log('Properties:');
    for lprop in ltype.GetProperties do
    begin
      if lprop.PropertyType.TypeKind = tkMethod then
      //if pos('event', lowercase(lprop.PropertyType.Name)) <> 0 then
      begin
        val := lprop.GetValue(form3);

        //val.Make()
        //mi := TRttiMethod.CreateImplementation(nil, handlerImpl);

        met.Code := nil;
        met.Data := nil;

        val.ExtractRawData(@met);

        //if (met.Code <> nil)or(met.Data <> nil) then
        begin
          str:=lprop.Name;
          str:=str+slinebreak+' PropKind='+GetEnumName(System.TypeInfo(TTypeKind),ord(lprop.PropertyType.TypeKind));
          //Log(lprop.ToString);
          //if lprop.IsReadable then str:=str+' Readable';
          //if lprop.IsWritable then str:=str+' Writable';
          str:=str+slinebreak+' PropTypeName='+lprop.PropertyType.Name;

          str:=str+slinebreak+' ValKind='+GetEnumName(System.TypeInfo(TTypeKind),ord(val.Kind));
          str:=str+slinebreak+' Value='+val.ToString;
          str:=str+slinebreak+' ValDataSize='+inttostr(val.DataSize);

          if val.IsType<TMethod> then str:=str+slinebreak+' isMethod';
          if val.IsClass then str:=str+slinebreak+' isClass';
          if val.IsObject then str:=str+slinebreak+' isObject';
          if val.IsEmpty then str:=str+slinebreak+'  Empty';

          str:=str+slinebreak+' Code='+inttohex(integer(met.Code),8)+' Data='+inttohex(integer(met.Data),8);

          methodsig := GetMethodSignature(val.TypeData);

          str:=str+slinebreak+' SignatureMetKind='+GetEnumName(System.TypeInfo(TMethodKind),ord(methodsig.MethodKind));
          str:=str+slinebreak+' SignatureParamCount='+inttostr(methodsig.ParamCount);
          str:=str+slinebreak+'      Params:';
          for i := 0 to length(methodsig.ParamList)-1 do
          begin
            str:=str+slinebreak+'      #'+inttostr(i)+' = ';
            if pfVar in methodsig.ParamList[i].Flags then str:=str+'var ';
            if pfConst in methodsig.ParamList[i].Flags then str:=str+'const ';
            if pfArray in methodsig.ParamList[i].Flags then str:=str+'array ';
            if pfAddress in methodsig.ParamList[i].Flags then str:=str+'adress ';
            if pfReference in methodsig.ParamList[i].Flags then str:=str+'ref ';
            if pfOut in methodsig.ParamList[i].Flags then str:=str+'out ';
            if pfResult in methodsig.ParamList[i].Flags then str:=str+'result ';

            str:=str+methodsig.ParamList[i].ParamName^+':'+methodsig.ParamList[i].TypeName^;
          end;

          if methodsig.MethodKind = mkFunction then
            str:=str+slinebreak+'      Return:'+methodsig.ResultType^;

          str:=str+slinebreak+'---------------';
          Log(str);
        end;
      end;
    end;

    {Log('Fields:');
    for lfield in ltype.GetFields do
      Log(lfield.ToString);  }

    (*
    http://docwiki.embarcadero.com/CodeExamples/Sydney/en/Event_RTTI_Invocation_(Delphi)
    http://docwiki.appmethod.com/appmethod/1.13/topics/en/Events
  !!!  https://www.transl-gunsmoker.ru/2011/07/hack-10-getting-parameters-of-published.html
    https://delphisources.ru/pages/faq/base/list_events.html
    https://delphisources.ru/pages/faq/base/rtti_set_event.html
    http://teran.karelia.pro/articles/item_4508.html
  !  https://stackoverflow.com/questions/64155936/how-to-assign-event-handler-to-event-property-using-rtti
    http://delphi2010.ru/%D0%B4%D0%B5%D1%82%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE-%D0%BE-tvalue/
    http://robstechcorner.blogspot.com/2009/09/exploring-trttimember-descendants-in_17.html
  !!!  https://stackoverflow.com/questions/9330541/is-it-possible-to-create-trttimethod-instance-for-trttitype-with-typekind-tkmeth
    http://hallvards.blogspot.com/2006/09/extended-class-rtti.html
    *)

  finally
    context.Free;
  end;
end;

procedure TForm3.Button24Click(Sender: TObject);
begin
  DumpPublishedMethods(TForm3);
end;

procedure TForm3.Button25Click(Sender: TObject);
begin
  form9.show;
end;

procedure TForm3.CallBackHack(UserData: Pointer; const Args: TArray<TValue>; out Result: TValue);
var i: integer;
//rt: TRttiMethod;
arg: TArray<TValue>;
up: TUserParamClass;
begin
  Log('UserData='+inttohex(integer(UserData),8));

  up := TUserParamClass(UserData);

  //rt := TRttiMethod(UserData);
  //Result := Rtti.Invoke(rt.CodeAddress, Args, rt.CallingConvention, Result.TypeInfo);
  //Args[0].
  //rt.Invoke(Self, []);

  SetLength(arg, Length(Args)-1);
  for i := 1 to Length(Args)-1 do
    arg[i-1] := Args[i];

  Result := up.rtMethod.Invoke(Self, arg);

  Log('Method='+up.rtMethod.ToString);
  Log('Hooked ParamCount='+inttostr(Length(up.rtMethod.GetParameters)));
  Log('UserParamID='+inttostr(up.methID));
  {Log('Callback hack execute, userdata='+inttostr(integer(UserData))+', Args:');
  for i := Low(Args) to High(Args) do
    Log('#'+inttostr(i)+'='+Args[i].ToString);  }

  {Log('new args:');
  for i := Low(Arg) to High(Arg) do
    Log('#'+inttostr(i)+'='+Arg[i].ToString);    }
end;

function GetComponentFullName(Instance: TComponent): string;
var str: string;
begin
  str:='';

  if Instance.HasParent = true then
    str := GetComponentFullName(Instance.GetParentComponent)+'.'+Instance.Name
  else
    str := Instance.Name;


  result:=str;
  {if Instance.HasParent = true then
    Result := GetComponentFullName(Instance.GetParentComponent)+'.'+Instance.Name
  else
    Result := Instance.Name;   }
end;

procedure LogEvents(Ins: TComponent; contx: TRttiContext);
const tab = '     ';
var rtType: TRttiType;
rtMethArr: TArray<TRttiMethod>;
rtMethArrInst: TArray<TRttiMethod>;
rtProp: TRttiProperty;
propInfo: PPropInfo;
rtMethod: TRttiMethod;
methInfo: TMethod;
i: integer;
str: string;
CompArr: TArray<TComponent>;
begin
  SetLength(CompArr, Ins.ComponentCount+1);

  //todo: потестить если onclick у разных кнопок ссылается на 1 метод

  for i := 0 to Ins.ComponentCount-1 do
    CompArr[i] := Ins.Components[i];
  CompArr[length(CompArr)-1] := Ins;

  rtType := contx.GetType(Ins.ClassType);
  rtMethArrInst := rtType.GetMethods;

  for i := Low(CompArr) to High(CompArr) do
  begin
    rtType := contx.GetType(CompArr[i].ClassType);
    rtMethArr := rtType.GetMethods;
    str:=GetComponentFullName(CompArr[i]);
    Log('Events for class '+str+':'+CompArr[i].UnitName+'.'+CompArr[i].ClassName);

    for rtProp in rtType.GetProperties do
      if (rtProp.PropertyType.TypeKind = tkMethod)and(rtProp.GetValue(CompArr[i]).IsEmpty = false) then
      begin
        propInfo := GetPropInfo(CompArr[i],rtProp.Name);
        if propInfo <> nil then
        begin
          methInfo := GetMethodProp(CompArr[i],rtProp.Name);
          for rtMethod in rtMethArr do
            if rtMethod.CodeAddress = methInfo.Code then
            begin
              Log(tab+str+'.'+rtProp.Name+'='+str+'.'+rtMethod.Name);
            end;
          if (rtMethArrInst <> nil)and(CompArr[i] <> Ins) then
            for rtMethod in rtMethArrInst do
              if rtMethod.CodeAddress = methInfo.Code then
              begin
                Log(tab+str+'.'+rtProp.Name+'='+Ins.Name+'.'+rtMethod.Name);
              end;

          //Log(tab+Instance.UnitName+'.'+Instance.ClassName+'.'+rtProp.Name+'=');
        end;
      end;
  end;
end;

procedure TForm3.Button26Click(Sender: TObject);
const tab = '     ';
var Inst: TObject;
InstClass: TClass;
propInfo: PPropInfo;
methInfo, newMethod: TMethod;
//context: TRttiContext;
rtType: TRttiType;
rtProp: TRttiProperty;
rtMethodArr: TArray<TRttiMethod>;
rtMethod: TRttiMethod;
//Callback : TMethodImplementationCallback;
p: Pointer;
begin
  //initialization
  Inst := Self;

  InstClass := Inst.ClassType;

  try
    rtType := Fcontext.GetType(InstClass);
    rtMethodArr := rtType.GetMethods;

    Log('Properties for class '+InstClass.ClassName+':');
    Log('Object adress='+inttohex(integer(Inst),8));
    for rtProp in rtType.GetProperties do
      if rtProp.PropertyType.TypeKind = tkMethod then
      begin
        propInfo := GetPropInfo(Inst,rtProp.Name);

        Log(rtProp.Name);
        if (propInfo <> nil)and(rtProp.Name = 'OnMouseDown') then
        begin
          Log(tab+'PropType='+GetEnumName(System.TypeInfo(TTypeKind),ord(propInfo^.PropType^.Kind)));
          Log(tab+'Getter='+inttohex(integer(propInfo^.GetProc),8));
          Log(tab+'Setter='+inttohex(integer(propInfo^.SetProc),8));

          methInfo := GetMethodProp(Inst,rtProp.Name);
          Log(tab+'Method.code='+inttohex(integer(methInfo.Code),8));
          Log(tab+'Method.data='+inttohex(integer(methInfo.Data),8));

          if methInfo.Data = Inst then
          begin
            for rtMethod in rtMethodArr do
              if rtMethod.CodeAddress = methInfo.Code then
              begin
                Log(tab+'Implementation= '+rtMethod.ToString);

                if Userparams = nil then
                begin
                  userparams := TUserParamClass.Create;
                  userparams.rtMethod := rtMethod;
                  userparams.methID := 100;
                end;

                FmethImplem := rtMethod.CreateImplementation(Userparams, CallBackHack);

                newMethod.Data := Inst;
                newMethod.Code := FmethImplem.CodeAddress;

                SetMethodProp(Inst, rtProp.Name, newMethod);
                //Self.OnDblClick := TNotifyEvent(newMethod);

                Log(tab+'Method hook set');
              end;
          end;
        end
        else Log('PropInfo is nil');
      end;
  finally

  end;
end;

procedure TForm3.HookTest(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; var Result: TValue);
var i: Integer;
str: string;
begin
  if Method.Name <> 'OnDblClick' then exit;

  Application.MessageBox(pchar(Method.Name), 'Hook');
  //Log('[OnBefore] Calling ' +  Method.Name + ' with args: ');
  {str:='';
  for i := 0 to Length(Args) - 1 do
    str:=str+Args[i].ToString + ' ';
  Log(str);   }
end;

procedure TForm3.Memo1Change(Sender: TObject);
var i: integer;
begin
  inc(i);
end;

procedure TForm3.Panel1Enter(Sender: TObject);
begin
  asm
  end;
end;

procedure TForm3.TabControl1Changing(Sender: TObject; var AllowChange: Boolean);
begin
  asm
  end;
end;

procedure TForm3.TestButtonClick(Sender: TObject);
begin
  asm
  end;
end;

procedure TForm3.Button27Click(Sender: TObject);
begin
  Interceptor := TVirtualMethodInterceptor.Create(form3.ClassType);

  Interceptor.OnBefore := nil;
  Interceptor.OnAfter := HookTest;

  Interceptor.Proxify(form3);

  Log('Hook complete');
end;

procedure TForm3.Button28Click(Sender: TObject);
begin
  //if Interceptor <> nil then
  //  Interceptor.Unproxify(form3);

  Interceptor.Free;
end;

procedure TForm3.Button29Click(Sender: TObject);
begin
  LogEvents(Self, FContext);
end;

procedure TForm3.Button2Click(Sender: TObject);
var i: integer;
begin
  if Plugin <> nil then
  begin
    //FreeAndNil(Plugin);
    Plugin.FinalizeModule;

    if CoreVar <> nil then
    begin
      CoreVar.Free;
    end;

    for i := Low(Subscribers) to High(Subscribers) do
      if Subscribers[i] <> nil then
        Subscribers[i].Free;
    Setlength(Subscribers, 0);

    {if Subscriber <> nil then
    begin
      Subscriber.Free;
    end;

    if Subscriber2 <> nil then
    begin
      Subscriber2.Free;
    end;  }

    Plugin.Free;
    Plugin:=nil;
  end;

  Log('Unload sucsess');
end;

procedure TForm3.Button30Click(Sender: TObject);
begin
  inc(UserParams.methID);
  Log('increased, current='+inttostr(UserParams.methID));
end;

procedure TForm3.Button31Click(Sender: TObject);
begin
  UserParams.Free;
  UserParams := nil;
end;

procedure TForm3.Button3Click(Sender: TObject);
var path: string;
begin
  path:= ExtractFilePath(ParamStr(0))+'..\..\..\TestDLL3\Win32\Debug\TestDLL3.dll';

  FDLLHandle := LoadDLL(path);
  if FDLLHandle = 0 then exit;
  FDLLProc := GetProcAddress(FDLLHandle, cAPIProcName);
  if Assigned(FDLLProc) = false then exit;

  Log('Load sucsessful');
end;

procedure TForm3.Button4Click(Sender: TObject);
var //intt: IUnknown;
strClass: string;
int1: IAPIInitDone;
int2: IAPIIntfCollection;
int3: IAPIModuleInfo;
v1,v2,v3,v4: byte;
i: integer;
begin
  //intt := nil;
  TempIntf := TInterfacedObject.Create;
  try
    {//intt:= FDLLProc(IAPIInitDone);
    FDLLProc(IAPIInitDone, IUnknown(int1));
    if intt = nil then
    begin
      Log('Failed to load interface');
      exit;
    end;
    int1 := IAPIInitDone(intt);
    intt:=nil;
    if int1.Initialize(TempIntf) = false then
    begin
      Log('Initialize false');
      exit;
    end;
    Log('Initialize sucsess');
    int1:=nil;

    int2:= IAPIIntfCollection(FDLLProc(IAPIIntfCollection));
    if int2 = nil then
    begin
      Log('Failed to load interface');
      exit;
    end;
    Log('Interface collection count='+inttostr(int2.IntfCollectionCount));
    for i := 0 to int2.IntfCollectionCount-1 do
      Log('#'+inttostr(i)+' = '+int2.GetIntfName(i));

    //int2:=nil;

    if int2.GetIntfByGUID(IModuleInfo, intt)=false then
    begin
      Log('Return of moduleinfo failed');
      TempIntf := nil;
      int1:=nil;
      int2:=nil;
      int3:=nil;
      exit;
    end;
    int3:=IModuleInfo(intt);
    intt:=nil;
    Log('Module name='+int3.ModuleName);
    Log('Module description='+int3.ModuleDescription);
    DecodeModuleVersion(int3.ModuleVersion, v1,v2,v3,v4);
    Log('ModuleVersion='+inttostr(v1)+'.'+inttostr(v2)+'.'+inttostr(v3)+'.'+inttostr(v4));
    Log('Module GUID='+guidtostring(int3.ModuleGUID));      }

    if FDLLProc(IAPIInitDone, IUnknown(int1)) = false then
    begin
      Log('Failed to load interface');
      exit;
    end;
    if int1.Initialize(TempIntf, cReasonInitialLoad) = false then
    //if int1.Initialize(nil) = false then
    begin
      Log('Initialize false');
      exit;
    end;
    Log('Initialize sucsess');

    if FDLLProc(IAPIIntfCollection, IUnknown(int2)) = false then
    begin
      Log('Failed to load interface');
      exit;
    end;
    Log('Interface collection count='+inttostr(int2.IntfCollectionCount));
    for i := 0 to int2.IntfCollectionCount-1 do
      Log('#'+inttostr(i)+' = '+int2.GetIntfName(i));

    if int2.GetIntfByGUID(IAPIModuleInfo, IUnknown(int3))=false then
    begin
      Log('Return of moduleinfo failed');
      TempIntf := nil;
      int1:=nil;
      int2:=nil;
      int3:=nil;
      exit;
    end;
    Log('Module name='+int3.ModuleName);
    Log('Module description='+int3.ModuleDescription);
    DecodeModuleVersion(int3.ModuleVersion, v1,v2,v3,v4);
    Log('ModuleVersion='+inttostr(v1)+'.'+inttostr(v2)+'.'+inttostr(v3)+'.'+inttostr(v4));
    Log('Module GUID='+guidtostring(int3.ModuleGUID));


    if int2.GetIntfByGUID(IDebugRefCount, IUnknown(intfDebugRefCount))=false then
    begin
      Log('Failed to load DebugRefCount');
      exit;
    end;
    Log('Debug ref count loaded');

  except
    on E: Exception do
    begin
      if E.InheritsFrom(EBaseCustomException) then
      begin
        strClass:=EBaseCustomException(E).WrappedException;

        Application.MessageBox(PChar(Format(
          'Класс: %s(%s)' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d'
          //'Оригинальное исключение: %s'
          ,
         [E.ClassName, strClass,
          E.Message,
          IntToHex(EBaseCustomException(E).ErrorCode, 8),
          'don''t have one',
          EBaseCustomException(E).Source,
          EBaseCustomException(E).HelpFile,
          EBaseCustomException(E).HelpContext
          //EBaseCustomException(E).WrappedException.ClassName
          //strClass
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
      begin
        Application.MessageBox(PWideChar('Exception '+e.ClassName+' with message: '+e.Message), 'Исключение', MB_OK or MB_ICONERROR);
        //raise;
      end;
    end;
  end;

  //if intt = nil then Log('Execute failed')
  //else Log('Execute sucsess');

  TempIntf := nil;
  int1:=nil;
  int2:=nil;
  int3:=nil;
end;

procedure TForm3.Button5Click(Sender: TObject);
var strclass: string;
int1: IAPIInitDone;
begin
  try
    //int1:=IAPIInitDone(FDLLProc(IAPIInitDone));
    FDLLProc(IAPIInitDone, IUnknown(int1));

    //intfDebugRefCount := nil;
    int1.Finalize(nil, cReasonProgramErrorExit);
  except
    on E: Exception do
    begin
      if E.InheritsFrom(EBaseCustomException) then
      begin
        strClass:=EBaseCustomException(E).WrappedException;

        Application.MessageBox(PChar(Format(
          'Класс: %s(%s)' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d'
          //'Оригинальное исключение: %s'
          ,
         [E.ClassName, strClass,
          E.Message,
          IntToHex(EBaseCustomException(E).ErrorCode, 8),
          'don''t have one',
          EBaseCustomException(E).Source,
          EBaseCustomException(E).HelpFile,
          EBaseCustomException(E).HelpContext
          //EBaseCustomException(E).WrappedException.ClassName
          //strClass
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
      begin
        Application.MessageBox(PWideChar('Exception '+e.ClassName+' with message: '+e.Message), 'Исключение', MB_OK or MB_ICONERROR);
        //raise;
      end;
    end;
  end;

  Log('Finalize done');
end;

procedure TForm3.Button6Click(Sender: TObject);
begin
  if Assigned(intfDebugRefCount) then
    Log('RefCount='+inttostr(intfDebugRefCount.GetDebugRefCount))
  else
    Log('Ref count interface is not assigned');
end;

procedure TForm3.Button7Click(Sender: TObject);
begin
  intfDebugRefCount := nil;
end;

procedure TForm3.Button8Click(Sender: TObject);
begin
  Log('RefCount='+inttostr(Plugin.GetModuleRefCount));
end;

procedure TForm3.Button9Click(Sender: TObject);
//WeakRefTestObj:TCheckedInterfacedObject;
//WeakRef: IAPIWeakRef;
var WeakRefSupp: IAPIWeakRefSupport;
begin
  WeakRefTestObj:=TCheckedInterfacedObject.Create;

  if Supports(WeakRefTestObj, IAPIWeakRefSupport, WeakRefSupp) = true then
  begin
    Log('WeakRef supported');

    WeakRefSupp.GetWeakRef(WeakRef);
  end
  else
  begin
    Log('WeakRef not supported');
  end;

  WeakRefSupp := nil;

  //WeakRefTestObj.GetWeakRef(WeakRef);

  Log('Created');
end;

function TForm3.FormAlignInsertBefore(Sender: TWinControl; C1,
  C2: TControl): Boolean;
begin
  sleep(10);
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  FContext := TRttiContext.Create;
end;

procedure TForm3.FormDblClick(Sender: TObject);
begin
  Log('on form Double click');
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  //if FContext <> nil then
  FContext.Free;
  FmethImplem.Free;
end;

procedure TForm3.FormDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Log('On drag over form');
end;

procedure TForm3.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  log('Form key down');
end;

procedure TForm3.FormKeyPress(Sender: TObject; var Key: Char);
begin
  log('Form key press');
end;

function GetOrdValue(Info: PTypeInfo; const SetParam): Integer;
begin
  Result := 0;

  case GetTypeData(Info)^.OrdType of
    otSByte, otUByte:
      Result := Byte(SetParam);
    otSWord, otUWord:
      Result := Word(SetParam);
    otSLong, otULong:
      Result := Integer(SetParam);
  end;
end;

procedure TForm3.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Log('on Form mouse down, button='+GetEnumName(System.TypeInfo(TMouseButton),ord(Button))+', shift='+SetToString(PTypeInfo(System.TypeInfo(TShiftState)), Pointer(@Shift), true)+', X,Y='+inttostr(X)+','+inttostr(y));
end;

procedure TForm3.FormShow(Sender: TObject);
begin
  memo2.Lines.Add('On form show');
end;

end.
