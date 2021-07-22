unit uSafecallFix;

{$IFNDEF PluginSYS_INC}{$I PluginSystem.inc}{$ENDIF ~PluginSYS_INC}

interface

implementation

uses
  Winapi.Windows
  ,uInitSystem
  ;

{$IFDEF WIN32}
// Исправление https://quality.embarcadero.com/browse/RSP-24652

var
  uSafecallFixInitialized: boolean = false;

const
  cDelphiException = $0EEDFADE;

type
  PExceptionRecord = ^TExceptionRecord;
  TExceptionRecord = record
    ExceptionCode: Cardinal;
    ExceptionFlags: Cardinal;
    ExceptionRecord: PExceptionRecord;
    ExceptionAddress: Pointer;
    NumberParameters: Cardinal;
    case {IsOsException:} Boolean of
      True:  (ExceptionInformation : array [0..14] of NativeUInt);
      False: (ExceptAddr: Pointer; ExceptObject: Pointer);
    end;
  TExceptClsProc = function(P: PExceptionRecord): Pointer{ExceptClass};
  TExceptObjProc = function(P: PExceptionRecord): Pointer{Exception};
  TRaiseExceptObjProc = procedure(P: PExceptionRecord);

const
  cNonContinuable     = 1;
  cUnwinding          = 2;
  cUnwindingForExit   = 4;
  cUnwindInProgress   = cUnwinding or cUnwindingForExit;
  EXCEPTION_CONTINUE_SEARCH    = 0;

type
  TAbsJump = packed record
    MovOpCode: Byte; // B8 - MOV EAX, xyz
    Ref: Pointer;
    JMP: Word;       // FF20 - JMP [EAX]
    Addr: Pointer;
  end;

const
  JumpToMemSz = SizeOf(TAbsJump);

type
  JmpInstruction =
  packed record
    opCode:   Byte;
    distance: Longint;
  end;

  PExcDescEntry = ^TExcDescEntry;
  TExcDescEntry = record
    vTable:  Pointer;
    handler: Pointer;
  end;

  PExcDesc = ^TExcDesc;
  TExcDesc = packed record
    jmp: JmpInstruction;
    case Integer of
    0:      (instructions: array [0..0] of Byte);
    1{...}: (cnt: Integer; excTab: array [0..0{cnt-1}] of TExcDescEntry);
  end;

  PExcFrame = ^TExcFrame;
  TExcFrame = record
    next: PExcFrame;
    desc: PExcDesc;
    hEBP: Pointer;
    case Integer of
    0:  ( );
    1:  ( ConstructedObject: Pointer );
    2:  ( SelfOfMethod: Pointer );
  end;

function Fix(excPtr: PExceptionRecord; errPtr: PExcFrame): PExceptionRecord;

  procedure Init;

    procedure FPUInit; assembler;
    asm
      CLD
      FNINIT
      FWAIT
    end;

  begin
    FPUInit;
    Set8087CW(Default8087CW);
  end;

var
  Rslt: TExceptionRecord;
  ExObj: TObject;
begin
  Result := excPtr;
  if (excPtr.ExceptionFlags = cUnwindInProgress) or
     (excPtr.ExceptionCode = cDelphiException) or
     (ExceptObjProc = nil) then
    Exit;

  Init;

  ExObj := TExceptObjProc(ExceptObjProc)(excPtr);

  FillChar(Rslt, SizeOf(Rslt), 0);
  Rslt.ExceptionCode := cDelphiException;
  Rslt.ExceptionFlags := cNonContinuable;
  Rslt.NumberParameters := 7;
  Rslt.ExceptAddr := excPtr^.ExceptionAddress;
  Rslt.ExceptObject := ExObj;

  Move(Rslt, excPtr^, SizeOf(Rslt));
  Result := excPtr;
end;

procedure _FpuInit;
asm
        FNINIT
        FWAIT
{$IFDEF PIC}
        CALL    GetGOT
        MOV     EAX,[EAX].OFFSET Default8087CW
        FLDCW   [EAX]
{$ELSE}
        FLDCW   Default8087CW
{$ENDIF}
end;

procedure FixedHandleAutoException; assembler;
asm
  MOV   EAX,[ESP+4]
  MOV   EDX,[ESP+8]
  CALL  FIX

        { ->    [ESP+ 4] excPtr: PExceptionRecord       }
        {       [ESP+ 8] errPtr: PExcFrame              }
        {       [ESP+12] ctxPtr: Pointer                }
        {       [ESP+16] dspPtr: Pointer                }
        { <-    EAX return value - always one           }

        MOV     EAX,[ESP+4]
        TEST    [EAX].TExceptionRecord.ExceptionFlags,cUnwindInProgress
        JNE     @@exit

        CMP     [EAX].TExceptionRecord.ExceptionCode,cDelphiException
        CLD
        CALL    _FpuInit
        JE      @@DelphiException
        CMP     BYTE PTR JITEnable,0
        JBE     @@DelphiException
        CMP     BYTE PTR DebugHook,0
        JA      @@DelphiException

@@DoUnhandled:
        LEA     EAX,[ESP+4]
        PUSH    EAX
        CALL    UnhandledExceptionFilter
        CMP     EAX,EXCEPTION_CONTINUE_SEARCH
        JE      @@exit
        MOV     EAX,[ESP+4]
        JMP     @@GoUnwind

@@DelphiException:
        CMP     BYTE PTR JITEnable,1
        JBE     @@GoUnwind
        CMP     BYTE PTR DebugHook,0
        JA      @@GoUnwind
        JMP     @@DoUnhandled

@@GoUnwind:
        OR      [EAX].TExceptionRecord.ExceptionFlags,cUnwinding

        PUSH    ESI
        PUSH    EDI
        PUSH    EBP

        MOV     EDX,[ESP+8+3*4]

        PUSH    0
        PUSH    EAX
        PUSH    offset @@returnAddress
        PUSH    EDX
        CALL    RtlUnwindProc

@@returnAddress:
        POP     EBP
        POP     EDI
        POP     ESI
        MOV     EAX,[ESP+4]
        MOV     EBX,8000FFFFH
        CMP     [EAX].TExceptionRecord.ExceptionCode,cDelphiException
        JNE     @@done

        MOV     EDX,[EAX].TExceptionRecord.ExceptObject
        MOV     ECX,[EAX].TExceptionRecord.ExceptAddr
        MOV     EAX,[ESP+8]
        MOV     EAX,[EAX].TExcFrame.SelfOfMethod
        TEST    EAX,EAX
        JZ      @@freeException
        MOV     EBX,[EAX]
        CALL    DWORD PTR [EBX] + VMTOFFSET TObject.SafeCallException
        MOV     EBX,EAX
@@freeException:
        MOV     EAX,[ESP+4]
        MOV     EAX,[EAX].TExceptionRecord.ExceptObject
        CALL    TObject.Free
@@done:
        XOR     EAX,EAX
        MOV     ESP,[ESP+8]
        POP     ECX
        MOV     FS:[EAX],ECX
        POP     EDX
        POP     EBP
        LEA     EDX,[EDX].TExcDesc.instructions
        POP     ECX
        JMP     EDX
@@exit:
        MOV     EAX,1
end;

function GetHandleAutoExceptionPointer: Pointer; assembler;
asm
  LEA EAX, System.@HandleAutoException
end;

procedure JumpToMem(const AAddr, AJump: Pointer);
var
  JumpOpCode: TAbsJump;
begin
  JumpOpCode.MovOpCode := $B8; // MOV EAX, xyz
  JumpOpCode.Ref := Pointer(NativeUInt(AAddr) + Cardinal(SizeOf(JumpOpCode.MovOpCode) + SizeOf(JumpOpCode.Ref) + SizeOf(JumpOpCode.JMP)));
  JumpOpCode.JMP := $20FF; // FF20 - JMP [EAX]
  JumpOpCode.Addr := AJump;
  Move(JumpOpCode, AAddr^, SizeOf(JumpOpCode));
end;

procedure FixSafeCallExceptions;
var
  P: Pointer;
  OldProtectionCode: DWORD;
begin
  P := GetHandleAutoExceptionPointer;
  if VirtualProtect(P, JumpToMemSz, PAGE_EXECUTE_READWRITE, @OldProtectionCode) then
  try
    JumpToMem(P, @FixedHandleAutoException);
  finally
    VirtualProtect(P, JumpToMemSz, OldProtectionCode, @OldProtectionCode);
  end;
  FlushInstructionCache(GetCurrentProcess, P, JumpToMemSz);
end;

{ Initialization/Finalization }

procedure InitModule(const AOptional: IUnknown);
begin
  if uSafecallFixInitialized = false then
  begin
    FixSafeCallExceptions;
    uSafecallFixInitialized := true;
  end;
end;
{$ENDIF}

initialization
  {$IFDEF WIN32}
    if System.IsLibrary = true then
      RegisterInitFunc(InitModule, nil)
    else
      InitModule(nil);
  {$ENDIF}

end.
