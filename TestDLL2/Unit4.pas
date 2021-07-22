unit Unit4;

interface

uses
  PluginAPI_TLB
  ;

//function DLLExportFunc(const ACore: IPluginAPIBase): IPluginAPIBase; safecall;

implementation
 (*
uses
  SysUtils
  ,uCustomClasses
  ,uInitSystem
  ,uPluginAPIHeader
  ;

const
  cModuleGUID: TGUID = '{0AC2F539-BAA9-4F09-A39F-3F80F928AD72}';
  cModuleVerMajor = 1;
  cModuleVerMinor = 0;
  cModuleVerRelease = 0;
  cModuleVerBuild = 0;
  cModuleName = 'TestDLL v2';
  cModuleDesc = 'Test DLL to test plugin API';

type
  TPluginObject = class(TCheckedInterfacedObject, IPluginAPIBase)
  private
  public
    function GetSupportedIntf: IAPIIntfCollection; safecall;
    function Initialize(const ACoreIntf: IUnknown): WordBool; safecall;
    procedure Finalize(const ACoreIntf: IUnknown); safecall;
  end;

  TCollectionRec = record
    InterfaceName: string;
    Intf: IUnknown;
  end;

  TPluginIntfCollection = class(TCheckedInterfacedObject, IAPIIntfCollection, IModuleInfo)
  private
    FCollection: array of TCollectionRec;

    //IAPIIntfCollection
    function get_IntfCollectionCount: Integer; safecall;
    //
    function get_ModuleGUID: TGUID; safecall;
    function get_ModuleVersion: LongWord; safecall;
    function get_ModuleName: WideString; safecall;
    function get_ModuleDescription: WideString; safecall;
    function get_ModuleAPIVersion: LongWord; safecall;
  public
    destructor Destroy; override;

    procedure RegisterInterface(const AIntf: IUnknown; AName: string);
    //IAPIIntfCollection
    function GetIntfName(AIndex: Integer): WideString; safecall;
    function GetIntfByIndex(AIndex: Integer; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByName(const AName: WideString; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByGUID(AGUID: TGUID; out AIntf: IUnknownWorkaround): WordBool; safecall;
    property IntfCollectionCount: Integer read get_IntfCollectionCount;
    //IModuleInfo
    property ModuleGUID: TGUID read get_ModuleGUID;
    property ModuleVersion: LongWord read get_ModuleVersion;
    property ModuleName: WideString read get_ModuleName;
    property ModuleDescription: WideString read get_ModuleDescription;
    property ModuleAPIVersion: LongWord read get_ModuleAPIVersion;
  end;

var
  UnitsInitialized: boolean = false;
  DLLInitialized: boolean = false;
  DLLFinalized: boolean = false;

  //PluginBase: IPluginAPIBase;
  PluginIntfCollection: IAPIIntfCollection;
  //CoreIntf: IPluginAPIBase;


{ TPluginObject }

function TPluginObject.GetSupportedIntf: IAPIIntfCollection; safecall;
begin
  if DLLInitialized = false then
  begin
    Result := nil;
    exit;
  end;

  Result := PluginIntfCollection;
end;

function TPluginObject.Initialize(const ACoreIntf: IUnknown): WordBool; safecall;
begin
  //initialization
  Result := false;
  if DLLFinalized = true then exit;
  if DllInitialized = true then
  begin
    Result := true;
    exit;
  end;

  PluginIntfCollection := TPluginIntfCollection.Create;
  with TPluginIntfCollection(PluginIntfCollection) do
  begin
    RegisterInterface(PluginBase,'IPluginAPIBase');
    RegisterInterface(PluginIntfCollection,'IAPIIntfCollection');
  end;

  DLLInitialized := true;
  Result := true;
end;

procedure TPluginObject.Finalize(const ACoreIntf: IUnknown); safecall;
begin
  //finalization
  if DLLFinalized = true then exit;
  CoreIntf := nil;
  PluginIntfCollection := nil;
  if UnitsInitialized = true then
  begin
    ExecuteRegisteredDone(ACoreIntf);
    UnitsInitialized := false;
  end;

  DLLInitialized := false;
  DLLFinalized := true;
end;

function DLLExportFunc(const ACore: IPluginAPIBase): IPluginAPIBase; safecall;
begin
  Result := nil;

  if DLLFinalized = true then exit;

  if UnitsInitialized = false then
  begin
    ExecuteRegisteredInit(ACore);
    UnitsInitialized := true;
  end;

  CoreIntf := nil;
  CoreIntf := ACore;

  if PluginBase = nil then
    PluginBase := TPluginObject.Create;
  Result := PluginBase;
end;

{ TPluginIntfCollection }

destructor TPluginIntfCollection.Destroy;
var i: integer;
begin
  for i := Low(FCollection) to High(FCollection) do
    FCollection[i].Intf := nil;
  SetLength(FCollection, 0);
end;

procedure TPluginIntfCollection.RegisterInterface(const AIntf: IUnknown; AName: string);
var exists: boolean;
i: integer;
begin
  exists := false;
  for i := Low(FCollection) to High(FCollection) do
    if FCollection[i].InterfaceName = AName then
    begin
      exists := true;
      break;
    end;

  if exists = true then exit;

  i := Length(FCollection);
  SetLength(FCollection, i+1);
  i := High(FCollection);
  FCollection[i].InterfaceName := AName;
  FCollection[i].Intf := AIntf;
end;

function TPluginIntfCollection.get_IntfCollectionCount: Integer; safecall;
begin
  Result := Length(FCollection);
end;

function TPluginIntfCollection.GetIntfName(AIndex: Integer): WideString; safecall;
begin
  Result := '';
  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  if (AIndex < Low(FCollection))or(AIndex > High(FCollection)) then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBounds, [AIndex]));

  Result := FCollection[AIndex].InterfaceName;
end;

function TPluginIntfCollection.GetIntfByIndex(AIndex: Integer; out AIntf: IUnknownWorkaround): WordBool; safecall;
begin
  {Result := nil;
  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  if (AIndex < Low(FCollection))or(AIndex > High(FCollection)) then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBounds, [AIndex]));

  Result := FCollection[AIndex].Intf;  }
end;

function TPluginIntfCollection.GetIntfByName(const AName: WideString; out AIntf: IUnknownWorkaround): WordBool; safecall;
var i: integer;
begin
  {Result := nil;
  if IntfCollectionCount = 0 then raise EPluginAPIIndexOutOfBounds.Create(Format(rsAPIOutOfBoundsEmpty, []));
  for i := Low(FCollection) to High(FCollection) do
    if FCollection[i].InterfaceName = AName then
    begin
      Result := FCollection[i].Intf;
      exit;
    end;  }
end;

function TPluginIntfCollection.GetIntfByGUID(AGUID: TGUID; out AIntf: IUnknownWorkaround): WordBool; safecall;
begin

end;

function TPluginIntfCollection.get_ModuleGUID: TGUID; safecall;
begin

end;

function TPluginIntfCollection.get_ModuleVersion: LongWord; safecall;
begin
  Result := EncodeModuleVersion(cModuleVerMajor, cModuleVerMinor, cModuleVerRelease, cModuleVerBuild);
end;

function TPluginIntfCollection.get_ModuleName: WideString; safecall;
begin

end;

function TPluginIntfCollection.get_ModuleDescription: WideString; safecall;
begin

end;

function TPluginIntfCollection.get_ModuleAPIVersion: LongWord; safecall;
begin

end;
                *)

end.
