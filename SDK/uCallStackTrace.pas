unit uCallStackTrace;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

implementation

uses
  Classes
  ,SysUtils
  ,JclDebug
  ,uInitSystem
  ;

var
  uCallStackTraceInitialized: boolean = false;

function GetExceptionStackInfo(P: PExceptionRecord): Pointer;
var
LLines: TStringList;
LText: String;
LResult: PChar;
//TestResult: AnsiString;
stack: TJclStackInfoList;
begin
  LLines := TStringList.Create;
  stack := JclCreateStackList(false, 3, P^.ExceptAddr);
  try
    //JclLastExceptStackListToStrings(LLines, True, False, False, False);
    stack.AddToStrings(LLines);
    LText := LLines.Text;
    GetMem(LResult, SizeOf(Char) * (length(LText)+1));
    StrCopy(LResult, PChar(LText));
    Result:=LResult;

    //TestResult := LText;
    //LResult := StrAlloc(Length(LText));
    //StrCopy(LResult, PChar(LText));
    //Result := LResult;
    //Result := @TestResult;
  finally
    LLines.Free;
    stack.Free;
  end;
end;

function GetStackInfoString(Info: Pointer): string;
begin
  Result := string(PChar(Info));
  //Result := string(AnsiString(Info));
end;

procedure CleanUpStackInfo(Info: Pointer);
begin
  //StrDispose(PChar(Info));
  //SetLength(AnsiString(Info),0);
  FreeMem(PChar(Info));
end;

(*  jcldebug

function GetExceptionStackInfo(P: PExceptionRecord): Pointer;
const
    cDelphiException = $0EEDFADE;
var
    stack: TJclStackInfoList;
    strings: TStringList;
    text: string;
    size: integer;
begin
    Result := nil;
    //Получаем трассировку стека.
    if P^.ExceptionCode = cDelphiException then
      stack := JclCreateStackList(false, 3, P^.ExceptAddr)
    else
      stack := JclCreateStackList(false, 3, P^.ExceptionAddress);
    //Формируем строку.
    strings := TStringList.Create;
    try
      //Здесь можно с помощью последних четырёх параметров задать, какую информацию нужно записать в строку.
      //Я отключу всю дополнительную информацию.
      stack.AddToStrings(strings, true, false, false, false);
      text := strings.Text;
    finally
      strings.Free;
    end;
    //Выделяем память и копируем в неё строку с трассировкой стека.
    if not text.IsEmpty then
    begin
      size := (text.Length + 1) * SizeOf(char);
      GetMem(Result, size);
      Move(Pointer(text)^, Result^, size);
    end;
end;

function GetStackInfoString(Info: Pointer): string;
begin
  //Здесь отдаём строку со стеком вызовов сохранённую в функции GetExceptionStackInfo.
  Result := PChar(Info);
end;

procedure CleanUpStackInfo(Info: Pointer);
begin
  //Освобождаем память, занятую под строку со стеком.
  FreeMem(Info);
end;
         *)
   {  for EurekaLog


    unit ExceptionEurekaLogSupport;

    interface

    implementation

    uses
      SysUtils, Classes, ExceptionLog;

    function GetExceptionStackInfoEurekaLog(P: PExceptionRecord): Pointer;
    const
      cDelphiException = $0EEDFADE;
    var
      Stack: TEurekaStackList;
      Str: TStringList;
      Trace: String;
      Sz: Integer;
      DI: PEurekaDebugInfo;
    begin
      Stack := GetCurrentCallStack;
      try
        New(DI);
        DI^.ModuleInfo := ModuleInfoByAddr(Cardinal(P^.ExceptAddr));
        if P^.ExceptionCode = cDelphiException then
          GetSourceInfoByAddr(Cardinal(P^.ExceptAddr), DI)
        else
          GetSourceInfoByAddr(Cardinal(P^.ExceptionAddress), DI);
        Stack.Insert(0, DI);

        Str := TStringList.Create;
        try
          CallStackToStrings(Stack, Str);
          Trace := Str.Text;
        finally
          FreeAndNil(Str);
        end;
      finally
        FreeAndNil(Stack);
      end;

      if Trace <> '' then
      begin
        Sz := (Length(Trace) + 1) * SizeOf(Char);
        GetMem(Result, Sz);
        Move(Pointer(Trace)^, Result^, Sz);
      end
      else
        Result := nil;
    end;

    function GetStackInfoStringEurekaLog(Info: Pointer): string;
    begin
      Result := PChar(Info);
    end;

    procedure CleanUpStackInfoEurekaLog(Info: Pointer);
    begin
      FreeMem(Info);
    end;

    initialization
      Exception.GetExceptionStackInfoProc := GetExceptionStackInfoEurekaLog;
      Exception.GetStackInfoStringProc := GetStackInfoStringEurekaLog;
      Exception.CleanUpStackInfoProc := CleanUpStackInfoEurekaLog;
    end.}

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if uCallStackTraceInitialized = false then
  begin
    if JclStartExceptionTracking then
    begin
      Exception.GetExceptionStackInfoProc := GetExceptionStackInfo;
      Exception.GetStackInfoStringProc := GetStackInfoString;
      Exception.CleanUpStackInfoProc := CleanUpStackInfo;
    end;
    uCallStackTraceInitialized := true;
  end;
end;

procedure DoneModule(const AOptional: IUnknown);
begin
  if uCallStackTraceInitialized = true then
  begin
    if JclExceptionTrackingActive then
    begin
      Exception.GetExceptionStackInfoProc := nil;
      Exception.GetStackInfoStringProc := nil;
      Exception.CleanUpStackInfoProc := nil;
      JclStopExceptionTracking;
    end;
    uCallStackTraceInitialized := false;
  end;
end;

initialization
  if System.IsLibrary = true then
    RegisterInitFunc(InitModule, DoneModule)
  else
    InitModule(nil);

finalization
  if System.IsLibrary = false then
    DoneModule(nil);
end.
