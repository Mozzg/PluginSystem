unit uMainCore;

interface

uses System.Classes, Vcl.Dialogs;

{$M+}
type TTest = class(TInterfacedObject, IInterface)
     public
       FInt:integer;
       constructor Create; virtual;
       destructor Destroy; override;
     end;
{$M-}

implementation

constructor TTest.Create;
begin
  inherited;
  FInt:=10;
  Showmessage('TTest constructor done');
end;

destructor TTest.Destroy;
begin
  Showmessage('TTest destructor');
end;

procedure ForceReferenceToClass(C: TClass);
begin
end;

initialization

  ForceReferenceToClass(TTest);

end.
