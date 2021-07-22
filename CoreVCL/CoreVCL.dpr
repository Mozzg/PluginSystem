program CoreVCL;

{$I PluginSystem.inc}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {Form10},
  uPluginAPIHeader in '..\SDK\uPluginAPIHeader.pas'
  ;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm10, Form10);
  Application.Run;
end.
