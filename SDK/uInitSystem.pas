unit uInitSystem;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

type
  TInitDoneFunc = procedure(const AOptional: IUnknown);
  TInitDoneRec = record
    Init: TInitDoneFunc;
    Done: TInitDoneFunc;
  end;

procedure RegisterInitFunc(const AInitFunc: TInitDoneFunc; const ADoneFunc: TInitDoneFunc);
procedure ExecuteRegisteredInit(const AOptional: IUnknown);
procedure ExecuteRegisteredDone(const AOptional: IUnknown);

implementation

var
  InitDoneFuncsArray: array of TInitDoneRec;

procedure RegisterInitFunc(const AInitFunc: TInitDoneFunc; const ADoneFunc: TInitDoneFunc);
var i: integer;
begin
  i := Length(InitDoneFuncsArray);
  SetLength(InitDoneFuncsArray, i+1);
  InitDoneFuncsArray[i].Init := AInitFunc;
  InitDoneFuncsArray[i].Done := ADoneFunc;
end;

procedure ExecuteRegisteredInit(const AOptional: IUnknown);
var i: integer;
begin
  for i := Low(InitDoneFuncsArray) to High(InitDoneFuncsArray) do
    if Assigned(InitDoneFuncsArray[i].Init) then
      InitDoneFuncsArray[i].Init(AOptional);
end;

procedure ExecuteRegisteredDone(const AOptional: IUnknown);
var i: integer;
begin
  for i := High(InitDoneFuncsArray) downto Low(InitDoneFuncsArray) do
    if Assigned(InitDoneFuncsArray[i].Done) then
      InitDoneFuncsArray[i].Done(AOptional);
end;

end.
