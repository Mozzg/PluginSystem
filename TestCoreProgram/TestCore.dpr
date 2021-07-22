program TestCore;

{$I PluginSystem.inc}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  SampleHeader in '..\SDK\SampleHeader.pas',
  Unit1 in 'Unit1.pas' {Form1},
  uInitSystem in '..\SDK\uInitSystem.pas';

{$R *.res}
{$IFNDEF PluginSYS_INC}{$Message Error 'Warinng, wrong include file'}{$ENDIF ~PluginSYS_INC}

begin
  IsMultiThread := true;
  Application.Initialize;
  Application.Title := 'Rich Edit Control Demo';
  {$IFDEF UNICODE}
  Application.MainFormOnTaskBar := True;    //????
  {$ENDIF}
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

