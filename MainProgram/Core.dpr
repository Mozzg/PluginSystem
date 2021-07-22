program Core;

{$I PluginSystem.inc}

uses
  FastMM4,
  Vcl.Forms,
  System.TypInfo,
  System.Rtti,
  System.Classes,
  Vcl.Dialogs,
  uMainCore in 'uMainCore.pas',
  System.SysUtils,
  SampleHeader;

{$R *.res}

{$IFNDEF PluginSYS_INC}{$Message Error 'Warinng, wrong include file'}{$ENDIF ~PluginSYS_INC}

var Obj:TTest;
state:TFastMM_MemoryManagerInstallationState;
str:widestring;

procedure CreateInstance;
var
  c: TRttiContext;
  t: TRttiType;
  t1:TRttiInstanceType;
  methods:TArray<TRttiMethod>;
  types:TArray<TRttiType>;
  v: TValue;
  human1: TObject;
  //i: TRttiMethod;
  i1:TRttiType;
  typekind:TTypeKind;
  str:string;
  f:textfile;
begin
  // Invoke RTTI
  c:= TRttiContext.Create;
  types:=c.GetTypes;

  assignfile(f,'TypeDump.txt');
  rewrite(f);
  str:='';
  for i1 in types do
  begin
    typekind:=i1.TypeKind;
    str:=str+GetEnumName(System.TypeInfo(TTypeKind),ord(typekind))
     +' ' + i1.Name + ' '+ i1.QualifiedName+#13+#10;
  end;
  //blockwrite(f,str[1],length(str));
  writeln(f,str);
  closefile(f);

  t:=c.FindType('uMainCore.TTest');
  t1:=t.AsInstance;
  //t1:=(c.FindType('uMainCore.TTest') as TRttiInstanceType);
  //t:=c.GetType(TTest);
  if t1<>nil then
    Showmessage(t1.QualifiedName)
  else
  begin
    Showmessage('Instance is nil');
    exit;
  end;

  // Variant 2 - works fine
  methods:=t1.GetMethods;
  {str:='';
  for i in methods do
  begin
    str:=str+i.ToString+#13+#10;
  end;
  Showmessage(str);  }

  v:= t1.GetMethod('Create').Invoke(t1.MetaclassType,[]);
  human1:= v.AsObject;
  //RegisterClass(t1.MetaclassType);
  //ObjectTextToBinary
  //FindClassHInstance
  // free RttiContext record (see text below) and the rest
  c.Free;

  human1.Destroy;
end;

procedure CreateInstance2;
//var t:TPersistentClass;
begin
  //RegisterClass(TTest);

  //t:=FindClass('TTest');

  //t.Create;

end;


begin
  IsMultiThread:=true;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Run;

  try
    CreateInstance;
    //SafeLoadLibrary(
    //Win32Check

  //CreateInstance2;

    Obj:=TTest.Create;
  except

  end;

  state:=FastMM_GetInstallationState;
  //LogMemoryManagerStateToFile('manager_state.txt','');
  str:=GetEnumName(System.TypeInfo(TFastMM_MemoryManagerInstallationState),ord(state));
  Application.MessageBox(PWideChar('Hello world'+#13+#10+'Enum='+str),'Caption',0);
end.
