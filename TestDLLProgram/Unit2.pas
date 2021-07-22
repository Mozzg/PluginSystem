unit Unit2;

interface

uses
  SampleHeader
  ,uCustomClasses
  ;

type
  TPluginWork = class(TCheckedInterfacedObject, ISampleDLLAPI)
  protected
    function GetVersion: Integer; safecall;
    procedure InitializeModule(Intf: IUnknown); safecall;
    procedure FinalizeModule; safecall;

    procedure TryAbort; safecall;
    //function TryAbort: HRESULT; stdcall;
    procedure TryAccessViolation; safecall;
    procedure TryWin32Exception; safecall;
    procedure TrySoftwareException; safecall;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

var
  APIInstance:ISampleDLLAPI;
  PluginInitialized: boolean = false;

procedure Level3;

implementation

uses
  SysUtils
  ,Windows
  ,Classes
  ,uInitSystem
  ;

procedure Level3;
begin
  //raise ECheckedInterfacedObjectUseDeletedError.Create('Test message access');
  raise EInvalidCast.Create('Test message invalid cast');
end;

procedure Level2Trace;
begin
  Level3;
end;

procedure Level1Stack;
begin
  Level2Trace;
end;

{ TPluginWork }

constructor TPluginWork.Create;
begin
  //Include(JclStackTrackingOptions, stRawMode);
  //Include(JclStackTrackingOptions, stStaticModuleList);
  //JclStartExceptionTracking;
end;

destructor TPluginWork.Destroy;
begin
  //JclStopExceptionTracking;
end;

function TPluginWork.GetVersion;
begin
  result := 1;
end;

procedure TPluginWork.InitializeModule(Intf: IUnknown);
begin
  PluginInitialized := true;
end;

procedure TPluginWork.FinalizeModule;
begin
  APIInstance := nil;
end;

procedure TPluginWork.TryAbort;
//function TPluginWork.TryAbort: HRESULT; stdcall;
begin
  {try
    //Abort;
    PInteger(nil)^ := 0;
  except
    on E: Exception do
      Result := CustomHandleSafeCallException(Self, E, ExceptAddr);
  end;     }
  //raise ECheckedInterfacedObjectDeleteError.Create('Test message');
  Abort;
end;

procedure TPluginWork.TryAccessViolation;
begin
  //PInteger(nil)^ := 0;
  //raise ECheckedInterfacedObjectUseDeletedError.Create('Test message access');
  Level1Stack;
  //raise EBaseCustomOleSysError.Create('Test message 123');
  //raise EInvalidCast.Create('Test message');
  //raise ENewError.Create('Error Message');
  //obj:=TCheckedInterfacedObject.Create;
  //i:=obj;
  //obj.Free;
  //obj.Free;
  //i:=nil;
end;

procedure TPluginWork.TryWin32Exception;
begin
  SetLastError(ERROR_ACCESS_DENIED);
  Win32Check(False);
end;

procedure TPluginWork.TrySoftwareException;
var List:TStringList;
begin
  List := TStringList.Create;
  try
    List[0];
  finally
    FreeAndNil(List);
  end;
end;


procedure InitModule(const AOptional: IUnknown);
begin

end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, nil)
  else
    InitModule(nil);

end.
