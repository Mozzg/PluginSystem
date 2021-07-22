unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ComObj,
  SampleHeader
  //,JclDebug
  //,uCallStackTrace
  ;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
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
    procedure Button14Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  ITestInterface1 = interface
  ['{BBB27994-376E-44BC-B27A-A139277BE85F}']
    function TestProc1(i:integer):string;
  end;

  ITestInterface2 = interface
  ['{81ED516A-04D5-4A75-A97F-833CAA7244C1}']
    function TestProc2(str:string):string;
  end;

  ITestInterface3 = interface(ITestInterface2)
  ['{930B2F61-4C33-4623-B791-66487F43BAB2}']
    function TestProc3:string;
  end;

  TIntfObject = class(TInterfacedObject, ITestInterface1)
  public
    function TestProc1(i:integer):string;
  end;

  TIntfObjectChild = class(TIntfObject, ITestInterface1, ITestInterface3)
  public
    //function TestProc1(i:integer):string;
    function TestProc2(str:string):string;
    function TestProc3:string;
  end;

var
  Form1: TForm1;

  PluginHandle: HMODULE;
  PluginFunction: TExportedFunction;
  PluginAPI: ISampleDLLAPI;

  TestObj: TIntfObject;
  TestIntf: IUnknown;

implementation

uses
  uCustomClasses
  ,uPluginAPIHeader
  ,RTTI
  ;

{$R *.dfm}

procedure Log(mess:string);
begin
  form1.Memo1.Lines.Add(mess);
end;

function TIntfObject.TestProc1(i:integer):string;
begin
  Result := 'TIntfObject.TestProc1 exec with parameter='+inttostr(i);
end;

{function TIntfObjectChild.TestProc1(i:integer):string;
begin
  Result := 'TIntfObjectChild.TestProc1 exec with parameter='+inttostr(i);
end;   }

function TIntfObjectChild.TestProc2(str:string):string;
begin
  result := 'TIntfObjectChild.TestProc2 exec with parameter='+str;
end;

function TIntfObjectChild.TestProc3:string;
begin
  result := 'TIntfObjectChild.TestProc3 exec';
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  try
    raise Exception.Create('Error Message');
  except
    on E: Exception do
    begin
      form1.Memo1.Lines.Add(E.StackTrace);
    end;
  end;
  //raise Exception.Create('Error Message');
end;

procedure TForm1.Button11Click(Sender: TObject);
var obj: TIntfObjectChild;
//Intt: IUnknown;
ResultList: TStringArray;
i:integer;
begin
  obj:=TIntfObjectChild.Create;

  //form1.Memo1.Lines.Add(DumpInterfaces(obj.ClassType));
  //form1.Memo1.Lines.Add(DumpInterfaces(Self.ClassType));

  GetImplementedInterfaces(obj.ClassType,ResultList,true);

  for i := Low(ResultList) to High(ResultList) do
    form1.Memo1.Lines.Add(ResultList[i]);

  Log(obj.TestProc3);

  obj.Free;
end;

procedure TForm1.Button12Click(Sender: TObject);
var obj: TIntfObject;
int1: IUnknown;
int2: ITestInterface1;
begin
  obj:= TIntfObject.Create;
  int1:=obj;
  int2:=ITestInterface1(int1);
  int2.TestProc1(445);
end;

procedure TForm1.Button13Click(Sender: TObject);
var b: boolean;
begin
  TestObj := TIntfObject.Create;
  //TestIntf := TestObj;
  b:=Supports(TestObj, ITestInterface1, TestIntf);
  Log('Supports returned '+booltostr(b, true));
  Log('Object created');
end;

procedure TForm1.Button14Click(Sender: TObject);
var temp: IUnknown;
temp2: ITestInterface1;
begin
  if TestIntf = nil then
  begin
    Log('Interface is nil');
    exit;
  end;

  temp := TestIntf;
  temp2 := ITestInterface1(temp);

  Log(temp2.TestProc1(567));
end;

procedure TForm1.Button1Click(Sender: TObject);
var path:string;
begin
  path:=ExtractFilePath(ParamStr(0))+'..\..\..\TestDLLProgram\Win32\Debug\TestDLL.dll';
  form1.Memo1.Lines.Add('Path='+path);
  //PluginHandle := SafeLoadLibraryEx(path, SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  PluginHandle := LoadDLL(path);
  Win32Check(PluginHandle <> 0);
  PluginFunction := GetProcAddress(PluginHandle, SampleDLLProcName);
  Win32Check(Assigned(PluginFunction));
  form1.Memo1.Lines.Add('Load DLL sucsess');
end;

procedure TForm1.Button2Click(Sender: TObject);
var obj:IInterface;
IntInstance:ITestInterface1;
begin
  obj:=TIntfObjectChild.Create;

  if Supports(obj,ITestInterface1,IntInstance) then
  begin
    form1.Memo1.Lines.Add('Interface supported');
    form1.Memo1.Lines.Add(IntInstance.TestProc1(123));
  end;


  //form1.Memo1.Lines.Add(obj.TestProc1);
  form1.Memo1.Lines.Add((obj as ITestInterface2).TestProc2('321'));

  //obj.Free;
  //obj := nil;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Win32Check(Assigned(PluginFunction));
  PluginAPI := PluginFunction;
  form1.Memo1.Lines.Add('Load API sucsess');
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Win32Check(PluginAPI <> nil);
  try
    PluginAPI.TryAbort;
  except
    on E: Exception do
    begin
      if E is EOleException then
      begin
        Application.MessageBox(PChar(Format(
          'Класс: %s' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d',
         [E.ClassName,
          E.Message,
          IntToHex(EOleException(E).ErrorCode, 8),
          'не сохраняется в EOleException',
          EOleException(E).Source,
          EOleException(E).HelpFile,
          EOleException(E).HelpContext])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
        raise;
    end;
  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
var strClass:string;
begin
  Win32Check(PluginAPI <> nil);
  try
    PluginAPI.TryAccessViolation;
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
      end;


      {strClass := E.ClassName;
      strMessage := E.Message;
      strGUID := 'not supported';
      if E.InheritsFrom(EOleSysError) then
        strCode := Inttohex(EOleSysError(E).ErrorCode,8);
      if E.InheritsFrom(EOleException) then
      begin
        strSource := EOleException(E).Source;
      end;

      Application.MessageBox(PChar(Format(
          'Класс: %s' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d',
         [E.ClassName,
          E.Message,
          strCode,
          strGUID,
          strSource,
          '',
          0
          ])),
        'Исключение', MB_OK or MB_ICONERROR);  }

      {if E is EOleException then
      begin
        Application.MessageBox(PChar(Format(
          'Класс: %s' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d',
         [E.ClassName,
          E.Message,
          IntToHex(EOleException(E).ErrorCode, 8),
          'не сохраняется в EOleException',
          EOleException(E).Source,
          EOleException(E).HelpFile,
          EOleException(E).HelpContext
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
      begin
        Application.MessageBox(PChar(Format(
          'Класс: %s' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d',
         [E.ClassName,
          E.Message,
          '',
          '',
          '',
          '',
          0
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
        //raise;
      end;  }
    end;
  end;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Win32Check(PluginAPI <> nil);
  PluginAPI.TryWin32Exception;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  Win32Check(PluginAPI <> nil);
  try
    PluginAPI.TrySoftwareException;
  except
    on E: Exception do
    begin
      if E.InheritsFrom(EBaseCustomException) then
      begin
        Application.MessageBox(PChar(Format(
          'Класс: %s' + sLineBreak +
          'Сообщение: %s' + sLineBreak +
          'Код: %s' + sLineBreak +
          'Источник (GUID): %s' + sLineBreak +
          'Источник (ProgID): %s' + sLineBreak +
          'Файл справки: %s' + sLineBreak +
          'Номер темы: %d' + sLineBreak +
          'Оригинальное исключение: %s',
         [E.ClassName,
          E.Message,
          IntToHex(EBaseCustomException(E).ErrorCode, 8),
          'don''t have one',
          EBaseCustomException(E).Source,
          EBaseCustomException(E).HelpFile,
          EBaseCustomException(E).HelpContext,
          //EBaseCustomException(E).WrappedException.ClassName
          ''
          ])),
        'Исключение', MB_OK or MB_ICONERROR);
      end
      else
      begin
        Application.MessageBox(PWideChar('Exception '+e.ClassName+' with message: '+e.Message), 'Исключение', MB_OK or MB_ICONERROR);
      end;
    end;
  end;
end;

procedure TForm1.Button8Click(Sender: TObject);
var obj:TCheckedInterfacedObject;
begin
  obj:=TCheckedInterfacedObject.Create;
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  Memo1.Lines.Add(booltostr(EBaseCustomOleSysError.InheritsFrom(EOutOfMemory),true));
end;

end.
