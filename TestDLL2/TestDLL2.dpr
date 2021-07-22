library TestDLL2;

{$I PluginSystem.inc}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  uPluginAPIHeader in '..\SDK\uPluginAPIHeader.pas',
  Unit4 in 'Unit4.pas',
  uPluginAPIDLLHeader in '..\SDK\uPluginAPIDLLHeader.pas';

{$R *.res}

exports
  GetAPI name cAPIProcName;

begin
end.
