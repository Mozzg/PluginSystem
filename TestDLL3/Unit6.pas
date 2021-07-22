unit Unit6;

interface

uses
  uCustomForms, Vcl.StdCtrls, System.Classes, Vcl.Controls
  ;

type
  TForm6 = class(uCustomForms.TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClick(Sender: TObject);
  private
  protected
    procedure InitializeEventExclusions; override;
  public
    { Public declarations }
    procedure Log(message: string); override;
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

uses
  SysUtils
  ,TypInfo
  ;

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

function GetPublishedMethodCount(AClass: TClass): word;
var p: ^Pointer;
ppmt: PPublishedMethodTable;
begin
  Result := 0;
  p := Pointer(Integer(AClass) + vmtMethodtable);
  ppmt := p^;
  Result := ppmt^.Count;
end;

function GetFirstPublishedMethod(AClass: TClass): PPublishedMethod;
var p: ^Pointer;
ppmt: PPublishedMethodTable;
begin
  p := Pointer(Integer(AClass) + vmtMethodtable);
  ppmt := p^;
  Result := @ppmt^.Methods[0];
end;

function GetNextPublishedMethod(AClass:TClass; AMethod: PPublishedMethod): PPublishedMethod;
begin
  Result := Pointer(Integer(AMethod) + AMethod^.Size);
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

    form6.Log('Published methods in '+AClass.UnitName+'.'+AClass.ClassName+', Method count='+inttostr(ppmt^.Count));
    for i := 1 to ppmt^.Count do
    begin
      with ppm^ do
        form6.Log(format('  %d: len: %d, adr: %p, name: %s', [i, Size, Address, Name]));

      ppm := Pointer(Integer(ppm) + ppm^.Size);
    end;

    AClass := AClass.ClassParent;
  end;
end;

function FindEventProperty(Instance: TObject; Code: Pointer): PPropInfo;
var
  Count: integer;
  PropList: PPropList;
  i: integer;
  Method: TMethod;
begin
  Assert(Assigned(Instance));
  Count := GetPropList(Instance, PropList);
  if Count > 0 then
    try
      for i := 0 to Count - 1 do
      begin
        Result := PropList^[i];
        if Result.PropType^.Kind = tkMethod then
        begin
          Method := GetMethodProp(Instance, Result);
          if Method.Code = Code then
            Exit;
        end;
      end;
    finally
      FreeMem(PropList);
    end;
  Result := nil;
end;

function FindEventFor(Instance: TObject; Code: Pointer): PPropInfo;
var
  i: integer;
  Component: TComponent;
begin
  Result := FindEventProperty(Instance, Code);
  if Assigned(Result) then
    Exit;

  if Instance is TComponent then
  begin
    Component := TComponent(Instance);
    for i := 0 to Component.ComponentCount - 1 do
    begin
      Result := FindEventFor(Component.Components[i], Code);
      if Assigned(Result) then
        Exit;
    end;
  end;
  Result := nil;
  // TODO: проверить published поля
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

function GetMethodSignature(Event: PPropInfo): TMethodSignature;
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
  Assert(Assigned(Event) and Assigned(Event.PropType));
  Assert(Event.PropType^.Kind = tkMethod);
  EventData := GetTypeData(Event.PropType^);
  Result.MethodKind := EventData.MethodKind;
  Result.ParamCount := EventData.ParamCount;
  SetLength(Result.ParamList, Result.ParamCount);
  ParamListRecord := @EventData.ParamList;
  for i := 0 to Result.ParamCount - 1 do
  begin
    MethodParam := @Result.ParamList[i];
    MethodParam.Flags     := ParamListRecord.Flags;
    MethodParam.ParamName := PackedShortString(@ParamListRecord.ParamName, ParamListRecord);
    MethodParam.TypeName  := PackedShortString(ParamListRecord);
  end;
  Result.ResultType := PackedShortString(ParamListRecord);
end;

function FindPublishedMethodSignature(Instance: TObject; Code: Pointer; var MethodSignature: TMethodSignature): boolean;
var
  Event: PPropInfo;
begin
  Assert(Assigned(Code));
  Event := FindEventFor(Instance, Code);
  Result := Assigned(Event);
  if Result then
    MethodSignature := GetMethodSignature(Event);
end;

function MethodKindString(MethodKind: TMethodKind): string;
begin
  case MethodKind of
    mkSafeProcedure,
    mkProcedure     : Result := 'procedure';
    mkSafeFunction,
    mkFunction      : Result := 'function';
    mkConstructor   : Result := 'constructor';
    mkDestructor    : Result := 'destructor';
    mkClassProcedure: Result := 'class procedure';
    mkClassFunction : Result := 'class function';
  end;
end;

function MethodParamString(const MethodParam: TMethodParam; ExcoticFlags: boolean = False): string;
begin
       if pfVar       in MethodParam.Flags then Result := 'var '
  else if pfConst     in MethodParam.Flags then Result := 'const '
  else if pfOut       in MethodParam.Flags then Result := 'out '
  else                                          Result := '';
  if ExcoticFlags then
  begin
    if pfAddress   in MethodParam.Flags then Result := '{addr} ' + Result;
    if pfReference in MethodParam.Flags then Result := '{ref} ' + Result;
  end;
  Result := Result + MethodParam.ParamName^ + ': ';
  if pfArray in MethodParam.Flags then
    Result := Result + 'array of ';
  Result := Result + MethodParam.TypeName^;
end;

function MethodParametesString(const MethodSignature: TMethodSignature): string;
var
  i: integer;
  MethodParam: PMethodParam;
begin
  Result := '';
  for i := 0 to MethodSignature.ParamCount - 1 do
  begin
    MethodParam := @MethodSignature.ParamList[i];
    Result := Result + MethodParamString(MethodParam^);
    if i < MethodSignature.ParamCount-1 then
      Result := Result + '; ';
  end;
end;

function MethodSignatureToString(const Name: string; const MethodSignature: TMethodSignature): string;
begin
  Result := Format('%s %s(%s)', [MethodKindString(MethodSignature.MethodKind), Name, MethodParametesString(MethodSignature)]);
  if Length(MethodSignature.ResultType^) > 0 then
    Result := Result + ': ' + MethodSignature.ResultType^;
  Result := Result + ';';
end;

function PublishedMethodToString(Instance: TObject; Method: PPublishedMethod): string;
var
  MethodSignature: TMethodSignature;
begin
  if FindPublishedMethodSignature(Instance, Method.Address, MethodSignature) then
    Result := MethodSignatureToString(Method.Name, MethodSignature)
  else
    Result := Format('procedure %s(???);', [Method.Name]);
end;

procedure GetPublishedMethodsWithParameters(Instance: TObject; List: TStrings);
var
  i: integer;
  Method: PPublishedMethod;
  AClass: TClass;
  Count: integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    AClass := Instance.ClassType;
    while Assigned(AClass) do
    begin
      Count := GetPublishedMethodCount(AClass);
      if Count > 0 then
      begin
        List.Add(Format('Published methods in %s', [AClass.ClassName]));
        Method := GetFirstPublishedMethod(AClass);
        for i := 0 to Count - 1 do
        begin
          List.Add(PublishedMethodToString(Instance, Method));
          Method := GetNextPublishedMethod(AClass, Method);
        end;
      end;
      AClass := AClass.ClassParent;
    end;
  finally
    List.EndUpdate;
  end;
end;

procedure DumpPublishedMethodsParameters2(Instance: TObject);
var
  i : integer;
  List: TStringList;
begin
  List := TStringList.Create;
  try
    GetPublishedMethodsWithParameters(Instance, List);
    for i := 0 to List.Count - 1 do
      form6.Log(List[i]);
  finally
    List.Free;
  end;
end;

procedure DumpPublishedMethodsParameters(Instance: TObject);
var
  i : integer;
  List: TStringList;
begin
  List := TStringList.Create;
  try
    GetPublishedMethodsWithParameters(Instance, List);
    for i := 0 to List.Count - 1 do
      WriteLn(List[i]);
  finally
    List.Free;
  end;
end;

procedure TMyClass.FirstPublished;
begin

end;

procedure TMyClass.SecondPublished(A: integer);
begin

end;

procedure TMyClass.ThirdPublished(A: integer); stdcall;
begin

end;

procedure TForm6.Button2Click(Sender: TObject);
begin
  Log('Begin published methods');

  //DumpPublishedMethodsParameters2(Form6);
end;

procedure TForm6.Button3Click(Sender: TObject);
begin
  Log('Test message');
end;

procedure TForm6.FormClick(Sender: TObject);
begin
  Log('Form OnClick event');
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  sleep(10);
end;

procedure TForm6.FormDblClick(Sender: TObject);
begin
  sleep(10);
end;

procedure TForm6.FormDestroy(Sender: TObject);
begin
  sleep(10);
end;

procedure TForm6.FormResize(Sender: TObject);
begin
  sleep(10);
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  Log('Form OnShow event');
end;

procedure TForm6.Button1Click(Sender: TObject);
begin
  Memo1.Lines.Add('Adding to memo');
end;

procedure TForm6.Log(message: string);
begin
  Self.Memo1.Lines.Add(message);
end;

procedure TForm6.InitializeEventExclusions;
begin
  ClearEventExclusions;
  //AddEventExclusionMask('*');
end;

end.
