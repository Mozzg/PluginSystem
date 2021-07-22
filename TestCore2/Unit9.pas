unit Unit9;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm9 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TMyMethod = function(var x, y: integer; ResX, ResY: integer): boolean of object;
  TMyMethod2 = procedure(var x, y: integer; ResX, ResY: integer) of object;

  TMyClass = class(TObject)
  private
    FOnActivate: TMyMethod;
    FOnDeactivate: TMyMethod2;
  public
    constructor Create;

    function Activate: boolean;
    procedure Initialize;

    function ActivateMethod(var x, y: integer; ResX, ResY: integer): boolean;
  published
    property OnActivate: TMyMethod read FonActivate write FonActivate;
    property OnDeactivate: TMyMethod2 read FOnDeactivate write FOnDeactivate;
  end;

var
  Form9: TForm9;

implementation

uses
  Rtti
  ,TypInfo
  ;

{$R *.dfm}

procedure Log(message: string);
begin
  form9.Memo1.Lines.Add(message);
end;

function GetMousePosX: integer;
begin

end;

function GetMousePosY: integer;
begin

end;

function GetWindowWidth: integer;
begin

end;

function GetWindowHeight: integer;
begin

end;

constructor TMyClass.Create;
begin
  inherited;
  OnActivate := ActivateMethod;
end;

function TMyClass.ActivateMethod(var x, y: integer; ResX, ResY: integer): boolean;
begin
  Log('ActivateMethod call, parameters:');
  Log('X='+inttostr(x));
  Log('Y='+inttostr(y));
  Log('ResX='+inttostr(ResX));
  Log('ResY='+inttostr(ResX));
end;

function TMyClass.Activate: boolean;
var initialX, initialY, x, y: integer;
begin
  Result := false;
  if Assigned(OnActivate) then
  begin
    initialX := GetMousePosX;
    initialY := GetMousePosY;
    x := initialX;
    y := initialY;
    Result := OnActivate(x, y, GetWindowWidth, GetWindowHeight);
    if Result and (x <> initialX) and (y <> initialY) then
      Result := true
    else
      Result := false;
  end;
end;

procedure TMyClass.Initialize;
var LContext: TRttiContext;
LType: TRttiType;
LProp: TRttiProperty;
LValue, LRetValue, ClassValue: TValue;
LMethodType: TRttiMethodType;
LMethod: TRttiMethod;
args: array of TValue;
begin
  LContext := TRttiContext.Create;
  try
    LType := LContext.GetType(Self.ClassType);

    LType.GetMethod('');
    LProp := LType.GetProperty('OnActivate'); //will be raplaced with for loop: for Lprop in Ltype.GetProperties do
    //LProp := LType.GetProperty('OnDeactivate');
    LValue := LProp.GetValue(Self);
    LMethodType := LContext.GetType(LValue.TypeInfo) as TRttiMethodType;
    //LMethod := TRttiInstanceMethodClassic.Create;

    Log('MethodTypeKind='+GetEnumName(System.TypeInfo(TTypeKind),ord(LMethodType.TypeKind)));
    Log('MethodSignature='+LMethodType.ToString);

    //if LValue.IsEmpty = true then
    begin
      //something
      setlength(args, 4);
      args[0] := 15;
      args[1] := 20;
      args[2] := 100;
      args[3] := 200;

      ClassValue := Self;

      //LMethodType.ReturnType

      LRetValue := LMethodType.Invoke(LValue, args);

      Log('ReturnType='+LMethodType.ReturnType.ToString);
      Log('RetValue='+LRetValue.ToString + '   Empty='+booltostr(LRetValue.IsEmpty,true));

      Log('Sig='+LMethod.ToString);
    end;
  finally
    Lcontext.Free;
  end;
end;

procedure TForm9.Button1Click(Sender: TObject);
var inst: TMyClass;
begin
  inst := TMyClass.Create;
  try
    inst.Initialize;
  finally
    inst.Free;
  end;
end;

end.
