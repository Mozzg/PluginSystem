// JCL_DEBUG_EXPERT_INSERTJDBG OFF
library TestDLL;

{$I PluginSystem.inc}

uses
  FastMM4 in '..\ThirdParty\FastMM4\FastMM4.pas',
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  SysUtils,
  Windows,
  Classes,
  Unit2 in 'Unit2.pas',
  uSafecallExceptions in '..\SDK\uSafecallExceptions.pas' {/,JclDebug},
  SampleHeader in '..\SDK\SampleHeader.pas',
  uInitSystem;

{$R *.res}
{$IFNDEF PluginSYS_INC}{$Message Error 'Warinng, wrong include file'}{$ENDIF ~PluginSYS_INC}


//---------------------------
{function GetAPI:ISampleDLLAPI; safecall;
begin
  raise EInvalidCast.Create('Test message invalid cast');

  if APIInstance=nil then
  begin
    ExecuteRegisteredInit(nil);
    APIInstance:=TPluginWork.Create;
  end;

  Result:=APIInstance;
end;    }

function GetAPI(out Res:ISampleDLLAPI): HRESULT; stdcall;
begin
  try
    Result := E_UNEXPECTED;

    if APIInstance=nil then
    begin
      ExecuteRegisteredInit(nil);
      APIInstance:=TPluginWork.Create;
    end;

    Res:=APIInstance;
    Result := S_OK;

    raise EInvalidCast.Create('Test message invalid cast 33333');
  except
    on E: Exception do
      Result := uSafecallExceptions.CustomHandleSafeCallException(APIInstance as TObject, E, ExceptAddr);
  end;
end;

exports
  GetAPI name SampleDLLProcName;


end.
