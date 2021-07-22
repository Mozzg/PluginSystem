unit PluginAPI_TLB_internal;

// ************************************************************************ //
// WARNING
// -------
// The types declared in this file were generated from data read from a
// Type Library. If this type library is explicitly or indirectly (via
// another type library referring to this type library) re-imported, or the
// 'Refresh' command of the Type Library Editor activated while editing the
// Type Library, the contents of this file will be regenerated and all
// manual modifications will be lost.
// ************************************************************************ //

// $Rev: 98336 $
// File generated on 11.09.2020 12:21:50 from Type Library described below.

// ************************************************************************  //
// Type Lib: H:\RADStudioProjects\Evgeny\PluginSystemTest\SDKTypeLib\PluginAPI (1)
// LIBID: {59B571B1-F6B7-4198-92AD-7895CBAFBE40}
// LCID: 0
// Helpfile:
// HelpString:
// DepndLst:
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, System.Variants, System.Win.StdVCL, Vcl.Graphics, Winapi.ActiveX;


// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:
//   Type Libraries     : LIBID_xxxx
//   CoClasses          : CLASS_xxxx
//   DISPInterfaces     : DIID_xxxx
//   Non-DISP interfaces: IID_xxxx
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  PluginAPIMajorVersion = 1;
  PluginAPIMinorVersion = 0;

  LIBID_PluginAPI: TGUID = '{59B571B1-F6B7-4198-92AD-7895CBAFBE40}';

  IID_IModuleInfo: TGUID = '{5A16A90B-E0EE-4AE2-B904-8665387E7C6C}';
  IID_ExceptionHandlerIID: TGUID = '{65E7E850-4A23-4C7A-84A0-F2928B9E23CB}';

// *********************************************************************//
// Declaration of Enumerations defined in Type Library
// *********************************************************************//
// Constants for enum CustomHResults
type
  CustomHResults = TOleEnum;
const
  CustomHResultCodeOffset = $00000220;
  E_C_UnregisteredException = $00000221;
  E_C_AbstractError = $00000222;
  E_C_ArgumentException = $00000223;
  E_C_ArgumentNilException = $00000224;
  E_C_ArgumentOutOfRangeException = $00000225;
  E_C_BitsError = $00000226;
  E_C_ClassNotFound = $00000227;
  E_C_ComponentError = $00000228;
  E_C_ConvertError = $00000229;
  E_C_DirectoryNotFoundException = $0000022A;
  E_C_External = $0000022B;
  E_C_ExternalException = $0000022C;
  E_C_FCreateError = $0000022D;
  E_C_FileNotFoundException = $0000022E;
  E_C_FilerError = $0000022F;
  E_C_FileStreamError = $00000230;
  E_C_FOpenError = $00000231;
  E_C_HeapException = $00000232;
  E_C_InOutError = $00000233;
  E_C_IntError = $00000234;
  E_C_IntfCastError = $00000235;
  E_C_InvalidCast = $00000236;
  E_C_InvalidContainer = $00000237;
  E_C_InvalidImage = $00000238;
  E_C_InvalidInsert = $00000239;
  E_C_InvalidOperation = $0000023A;
  E_C_InvalidOpException = $0000023B;
  E_C_InvalidPointer = $0000023C;
  E_C_ListError = $0000023D;
  E_C_MathError = $0000023E;
  E_C_MethodNotFound = $0000023F;
  E_C_Monitor = $00000240;
  E_C_MonitorLockException = $00000241;
  E_C_NoConstructException = $00000242;
  E_C_NoMonitorSupportException = $00000243;
  E_C_OutOfResources = $00000244;
  E_C_PackageError = $00000245;
  E_C_ParserError = $00000246;
  E_C_PathTooLongException = $00000247;
  E_C_ProgrammerNotFound = $00000248;
  E_C_PropReadOnly = $00000249;
  E_C_PropWriteOnly = $0000024A;
  E_C_RangeError = $0000024B;
  E_C_ReadError = $0000024C;
  E_C_ResNotFound = $0000024D;
  E_C_StreamError = $0000024E;
  E_C_StringListError = $0000024F;
  E_C_VariantError = $00000250;
  E_C_WriteError = $00000251;

// Constants for enum CustomConsts
type
  CustomConsts = TOleEnum;
const
  cDelphiException = $0EEDFADE;
  CUSTOMER_BIT = $20000000;

type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary
// *********************************************************************//
  IModuleInfo = interface;
  ExceptionHandlerIID = interface;

// *********************************************************************//
// Declaration of structures, unions and aliases.
// *********************************************************************//
  PTGUID = ^TGUID;

  BSTR = WideString;
  LPSTR = PAnsiChar;
  LPWSTR = PWideChar;

// *********************************************************************//
// Interface: IModuleInfo
// Flags:     (0)
// GUID:      {5A16A90B-E0EE-4AE2-B904-8665387E7C6C}
// *********************************************************************//
  IModuleInfo = interface(IUnknown)
    ['{5A16A90B-E0EE-4AE2-B904-8665387E7C6C}']
    function Get_ModuleGUID: TGUID; safecall;
    function Get_ModuleVersion: LongWord; safecall;
    function Get_ModuleName: WideString; safecall;
    property ModuleGUID: TGUID read Get_ModuleGUID;
    property ModuleVersion: LongWord read Get_ModuleVersion;
    property ModuleName: WideString read Get_ModuleName;
  end;

// *********************************************************************//
// Interface: ExceptionHandlerIID
// Flags:     (0)
// GUID:      {65E7E850-4A23-4C7A-84A0-F2928B9E23CB}
// *********************************************************************//
  ExceptionHandlerIID = interface(IUnknown)
    ['{65E7E850-4A23-4C7A-84A0-F2928B9E23CB}']
  end;

implementation

uses System.Win.ComObj;

end.

