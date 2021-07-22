program TestCore2;

{$I PluginSystem.inc}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  uPluginAPIHeader in '..\SDK\uPluginAPIHeader.pas',
  Vcl.Forms,
  Unit3 in 'Unit3.pas' {Form3},
  uCustomPluginHeader in 'uCustomPluginHeader.pas',
  Unit9 in 'Unit9.pas' {Form9};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm9, Form9);
  Application.Run;
end.
