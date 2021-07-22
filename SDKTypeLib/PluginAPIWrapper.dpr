// JCL_DEBUG_EXPERT_INSERTJDBG OFF
library PluginAPIWrapper;

uses
  System.Win.ComServ,
  PluginAPI_TLB_internal in 'PluginAPI_TLB_internal.pas',
  PluginAPI_TLB in '..\SDK\PluginAPI_TLB.pas',
  SampleHeader in '..\SDK\SampleHeader.pas',
  uCallStackTrace in '..\SDK\uCallStackTrace.pas',
  uCustomClasses in '..\SDK\uCustomClasses.pas',
  uHRESULTCodeHelper in '..\SDK\uHRESULTCodeHelper.pas',
  uInitSystem in '..\SDK\uInitSystem.pas',
  uPluginAPIHeader in '..\SDK\uPluginAPIHeader.pas',
  uSafecallExceptions in '..\SDK\uSafecallExceptions.pas',
  uSafecallFix in '..\SDK\uSafecallFix.pas',
  uCustomForms in '..\SDK\uCustomForms.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.RES}

begin
end.
