library TestDLL3;

{$R *.res}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Unit5 in 'Unit5.pas',
  uPluginAPIHeader in '..\SDK\uPluginAPIHeader.pas',
  uPluginConsts in 'uPluginConsts.pas',
  uPluginAPIDLLHeader in '..\SDK\uPluginAPIDLLHeader.pas',
  Unit6 in 'Unit6.pas' {Form6},
  Unit7 in 'Unit7.pas' {Form7},
  Unit8 in 'Unit8.pas' {Form8};

exports
  GetAPI name cAPIProcName;

end.
