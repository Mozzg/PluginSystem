{$ALIGN 8}         //record aligning on 8 bytes
{$CODEALIGN 4}     //code align. 4 is default
{$ASSERTIONS ON}   //include assertion
{-$EXTENSION exe}
{$FINITEFLOAT ON}  //real overflow/underflow/zerodivision checks
{$MINENUMSIZE 4}   //4 bytes for enum types
{$HINTS ON}        //generate hints
{.$STRONGLINKTYPES ON}  //RTTI information

{$WARN SYMBOL_PLATFORM OFF}      //warning about platform dependent code

//define custom identifier
{$IFNDEF PluginSYS_INC}
  {$DEFINE PluginSYS_INC}
{$ENDIF ~PluginSYS_INC}

{$IFDEF DEBUG}
  {$D+}  //include debug info
  {$L+}  //include debug symbols
{$ENDIF ~DEBUG}


{$IFDEF FPC}
  {$MODE Delphi}
  {$PACKRECORDS C}
  {$DEFINE RecordOperators}
{$ENDIF ~FPC}

{$I PluginJEDI.inc}

{$IFDEF WIN32}
  {$DEFINE MSWINDOWS}
{$ENDIF}

{$IFDEF WIN64}
  {$DEFINE MSWINDOWS}
  {$UNDEF WIN32}
{$ENDIF}

{$IFDEF MSWINDOWS}
  {$DEFINE WINDOWS}
{$ENDIF}

