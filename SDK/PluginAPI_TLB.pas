unit PluginAPI_TLB;

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
// File generated on 12.11.2020 10:55:05 from Type Library described below.

// ************************************************************************  //
// Type Lib: H:\RADStudioProjects\Evgeny\PluginSystemTest\SDKTypeLib\PluginAPIWrapper.tlb (1)
// LIBID: {59B571B1-F6B7-4198-92AD-7895CBAFBE40}
// LCID: 0
// Helpfile: 
// HelpString: 
// DepndLst: 
//   (1) v2.0 stdole, (C:\Windows\System32\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// Cmdline:
//   "H:\RAD\Studio\21\bin64\tlibimp.exe"  -C -P -D"H:\RADStudioProjects\Evgeny\PluginSystemTest\SDK" -Pt -XM "H:\RADStudioProjects\Evgeny\PluginSystemTest\SDKTypeLib\PluginAPIWrapper.tlb"
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

  IID_IAPIModuleInfo: TGUID = '{5A16A90B-E0EE-4AE2-B904-8665387E7C6C}';
  IID_ExceptionHandlerIID: TGUID = '{65E7E850-4A23-4C7A-84A0-F2928B9E23CB}';
  IID_IAPIIntfCollection: TGUID = '{458979CE-EADD-4EC4-BE70-8EF4086B10DD}';
  IID_IAPIInitDone: TGUID = '{57CAF06D-D28B-4ACE-87E1-FA85E5F760B0}';
  IID_IAPIInitDoneModuleEvents: TGUID = '{467BF164-2DB2-4570-8A6B-9F7A825A6A8E}';
  IID_IDebugRefCount: TGUID = '{BB492DB2-5AAA-45DC-96C3-7147869773E3}';
  IID_IAPIEvent: TGUID = '{9A2F79C5-7E5C-4DF3-8A34-1990F91A7A33}';
  IID_IAPICoreEventCollection: TGUID = '{5DC17996-1E2D-496C-A601-5B7FAA14CE19}';
  IID_IAPICoreAppWnds: TGUID = '{2C99285A-73BC-4514-8C80-DDD65710C0AC}';
  IID_IAPIWeakRef: TGUID = '{0BEE6565-C48A-4BE9-B183-80718ED1CF8B}';
  IID_IAPIWeakRefSupport: TGUID = '{D11995B9-9A3F-4CF6-8D6F-303103D0AFEE}';
  IID_IAPIEventSubscriber: TGUID = '{6B650F8A-9FE6-4BDB-B230-AB382A25E052}';
  IID_IAPICoreWndsCollection: TGUID = '{DEFDB06D-E905-4C86-8117-5D302149B5F5}';
  IID_IAPICoreUIControlsCollection: TGUID = '{4E504300-853B-47FC-849D-690BA62B935C}';
  IID_IAPIWindow: TGUID = '{83AD36D7-878A-442D-B654-4C1A8B113FDE}';

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
  E_C_BaseCustomException = $00000252;
  E_C_CheckedInterfacedObjectError = $00000253;
  E_C_CheckedInterfacedObjectDeleteError = $00000254;
  E_C_CheckedInterfacedObjectDoubleFreeError = $00000255;
  E_C_CheckedInterfacedObjectUseDeletedError = $00000256;
  E_C_BaseCustomOleSysError = $00000257;
  E_C_PluginAPIError = $00000258;
  E_C_PluginAPIIndexOutOfBounds = $00000259;
  E_C_PluginAPIInterfaceNotSupported = $0000025A;
  E_C_PluginAPIInitializeError = $0000025B;

// Constants for enum CustomConsts
type
  CustomConsts = TOleEnum;
const
  cDelphiException = $0EEDFADE;
  CUSTOMER_BIT = $20000000;

// Constants for enum ModuleVersionMaskConsts
type
  ModuleVersionMaskConsts = TOleEnum;
const
  cMajorVersionMask = $7F000000;
  cMinorVersionMask = $00FF0000;
  cReleaseVersionMask = $0000FF00;
  cBuildVersionMask = $000000FF;
  cVersionMask = $7FFFFFFF;

// Constants for enum ModuleInitDoneReasonsConsts
type
  ModuleInitDoneReasonsConsts = TOleEnum;
const
  cReasonInitialLoad = $00000000;
  cReasonModuleReload = $00000001;
  cReasonErrorUnload = $00000002;
  cReasonProgramExit = $00000003;
  cReasonProgramErrorExit = $00000004;

type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  IAPIModuleInfo = interface;
  ExceptionHandlerIID = interface;
  IAPIIntfCollection = interface;
  IAPIInitDone = interface;
  IAPIInitDoneModuleEvents = interface;
  IDebugRefCount = interface;
  IAPIEvent = interface;
  IAPICoreEventCollection = interface;
  IAPICoreAppWnds = interface;
  IAPIWeakRef = interface;
  IAPIWeakRefSupport = interface;
  IAPIEventSubscriber = interface;
  IAPICoreWndsCollection = interface;
  IAPICoreUIControlsCollection = interface;
  IAPIWindow = interface;

// *********************************************************************//
// Declaration of structures, unions and aliases.                         
// *********************************************************************//
  PTGUID = ^TGUID; 

  BSTR = WideString; 
  LPSTR = PAnsiChar; 
  LPWSTR = PWideChar; 
  IUnknownWorkaround = IUnknown; 

// *********************************************************************//
// Interface: IAPIModuleInfo
// Flags:     (0)
// GUID:      {5A16A90B-E0EE-4AE2-B904-8665387E7C6C}
// *********************************************************************//
  IAPIModuleInfo = interface(IUnknown)
    ['{5A16A90B-E0EE-4AE2-B904-8665387E7C6C}']
    function get_ModuleGUID: TGUID; safecall;
    function get_ModuleVersion: LongWord; safecall;
    function get_ModuleName: WideString; safecall;
    function get_ModuleDescription: WideString; safecall;
    function get_ModuleAPIVersion: LongWord; safecall;
    property ModuleGUID: TGUID read get_ModuleGUID;
    property ModuleVersion: LongWord read get_ModuleVersion;
    property ModuleName: WideString read get_ModuleName;
    property ModuleDescription: WideString read get_ModuleDescription;
    property ModuleAPIVersion: LongWord read get_ModuleAPIVersion;
  end;

// *********************************************************************//
// Interface: ExceptionHandlerIID
// Flags:     (0)
// GUID:      {65E7E850-4A23-4C7A-84A0-F2928B9E23CB}
// *********************************************************************//
  ExceptionHandlerIID = interface(IUnknown)
    ['{65E7E850-4A23-4C7A-84A0-F2928B9E23CB}']
  end;

// *********************************************************************//
// Interface: IAPIIntfCollection
// Flags:     (0)
// GUID:      {458979CE-EADD-4EC4-BE70-8EF4086B10DD}
// *********************************************************************//
  IAPIIntfCollection = interface(IUnknown)
    ['{458979CE-EADD-4EC4-BE70-8EF4086B10DD}']
    function get_IntfCollectionCount: Integer; safecall;
    function GetIntfName(AIndex: Integer): WideString; safecall;
    function GetIntfByIndex(AIndex: Integer; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByName(const AName: WideString; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByGUID(AGUID: TGUID; out AIntf: IUnknownWorkaround): WordBool; safecall;
    function GetIntfByIndexWeak(AIndex: Integer; out AIntf: IAPIWeakRef): WordBool; safecall;
    function GetIntfByNameWeak(const AName: WideString; out AIntf: IAPIWeakRef): WordBool; safecall;
    function GetIntfByGUIDWeak(AGUID: TGUID; out AIntf: IAPIWeakRef): WordBool; safecall;
    property IntfCollectionCount: Integer read get_IntfCollectionCount;
  end;

// *********************************************************************//
// Interface: IAPIInitDone
// Flags:     (0)
// GUID:      {57CAF06D-D28B-4ACE-87E1-FA85E5F760B0}
// *********************************************************************//
  IAPIInitDone = interface(IUnknown)
    ['{57CAF06D-D28B-4ACE-87E1-FA85E5F760B0}']
    function Initialize(const ACoreIntf: IUnknown; AReason: Integer): WordBool; safecall;
    procedure Finalize(const ACoreIntf: IUnknown; AReason: Integer); safecall;
  end;

// *********************************************************************//
// Interface: IAPIInitDoneModuleEvents
// Flags:     (0)
// GUID:      {467BF164-2DB2-4570-8A6B-9F7A825A6A8E}
// *********************************************************************//
  IAPIInitDoneModuleEvents = interface(IUnknown)
    ['{467BF164-2DB2-4570-8A6B-9F7A825A6A8E}']
    procedure AfterPluginsInitialize(AReason: Integer); safecall;
    procedure BeforePluginsFinalize(AReason: Integer); safecall;
  end;

// *********************************************************************//
// Interface: IDebugRefCount
// Flags:     (0)
// GUID:      {BB492DB2-5AAA-45DC-96C3-7147869773E3}
// *********************************************************************//
  IDebugRefCount = interface(IUnknown)
    ['{BB492DB2-5AAA-45DC-96C3-7147869773E3}']
    function GetDebugRefCount: Integer; safecall;
  end;

// *********************************************************************//
// Interface: IAPIEvent
// Flags:     (0)
// GUID:      {9A2F79C5-7E5C-4DF3-8A34-1990F91A7A33}
// *********************************************************************//
  IAPIEvent = interface(IUnknown)
    ['{9A2F79C5-7E5C-4DF3-8A34-1990F91A7A33}']
    procedure FireEvent(const AParam: WideString); safecall;
    function Subscribe(var ASubscriber: IAPIEventSubscriber; 
                       const ASubscriberDescription: WideString): WordBool; safecall;
    function Unsubscribe(var ASubscriber: IAPIEventSubscriber): WordBool; safecall;
    function UnsubscribeAll: WordBool; safecall;
    function get_EventSubscribersCount: Integer; safecall;
    function GetSubscribersDescriptions: WideString; safecall;
    property EventSubscribersCount: Integer read get_EventSubscribersCount;
  end;

// *********************************************************************//
// Interface: IAPICoreEventCollection
// Flags:     (0)
// GUID:      {5DC17996-1E2D-496C-A601-5B7FAA14CE19}
// *********************************************************************//
  IAPICoreEventCollection = interface(IUnknown)
    ['{5DC17996-1E2D-496C-A601-5B7FAA14CE19}']
    function RegisterEvent(AModule: TGUID; const AEventName: WideString; const AEvent: IAPIEvent): Integer; safecall;
    function UnregisterEvent(AID: Integer): WordBool; safecall;
    function get_EventCollectionCount: Integer; safecall;
    function GetEventName(AIndex: Integer; out AName: WideString): WordBool; safecall;
    function GetEventModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
    function GetEventByIndex(AIndex: Integer; out AEvent: IAPIEvent): WordBool; safecall;
    function GetEventByID(AID: Integer; out AEvent: IAPIEvent): WordBool; safecall;
    function GetEventByIndexWeak(AIndex: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
    function GetEventByIDWeak(AID: Integer; out AEvent: IAPIWeakRef): WordBool; safecall;
    property EventCollectionCount: Integer read get_EventCollectionCount;
  end;

// *********************************************************************//
// Interface: IAPICoreAppWnds
// Flags:     (0)
// GUID:      {2C99285A-73BC-4514-8C80-DDD65710C0AC}
// *********************************************************************//
  IAPICoreAppWnds = interface(IUnknown)
    ['{2C99285A-73BC-4514-8C80-DDD65710C0AC}']
    function get_ApplicationWnd: Pointer; safecall;
    function get_MainWnd: Pointer; safecall;
    function get_ActiveWnd: Pointer; safecall;
    function get_MDIClientWnd: Pointer; safecall;
    procedure ModalStart; safecall;
    procedure ModalFinish; safecall;
    property ApplicationWnd: Pointer read get_ApplicationWnd;
    property MainWnd: Pointer read get_MainWnd;
    property ActiveWnd: Pointer read get_ActiveWnd;
    property MDIClientWnd: Pointer read get_MDIClientWnd;
  end;

// *********************************************************************//
// Interface: IAPIWeakRef
// Flags:     (0)
// GUID:      {0BEE6565-C48A-4BE9-B183-80718ED1CF8B}
// *********************************************************************//
  IAPIWeakRef = interface(IUnknown)
    ['{0BEE6565-C48A-4BE9-B183-80718ED1CF8B}']
    function IsWeakRefAlive: WordBool; safecall;
    function GetRef(out Referance: IUnknownWorkaround): WordBool; safecall;
  end;

// *********************************************************************//
// Interface: IAPIWeakRefSupport
// Flags:     (0)
// GUID:      {D11995B9-9A3F-4CF6-8D6F-303103D0AFEE}
// *********************************************************************//
  IAPIWeakRefSupport = interface(IUnknown)
    ['{D11995B9-9A3F-4CF6-8D6F-303103D0AFEE}']
    procedure GetWeakRef(out ReturnValue: IAPIWeakRef); safecall;
  end;

// *********************************************************************//
// Interface: IAPIEventSubscriber
// Flags:     (0)
// GUID:      {6B650F8A-9FE6-4BDB-B230-AB382A25E052}
// *********************************************************************//
  IAPIEventSubscriber = interface(IUnknown)
    ['{6B650F8A-9FE6-4BDB-B230-AB382A25E052}']
    procedure EventFired(const AParameter: WideString); safecall;
  end;

// *********************************************************************//
// Interface: IAPICoreWndsCollection
// Flags:     (0)
// GUID:      {DEFDB06D-E905-4C86-8117-5D302149B5F5}
// *********************************************************************//
  IAPICoreWndsCollection = interface(IUnknown)
    ['{DEFDB06D-E905-4C86-8117-5D302149B5F5}']
    function get_WndsCollectionCount: Integer; safecall;
    function RegisterWindow(AModule: TGUID; const AWindowName: WideString; const AWindow: IAPIWindow): Integer; safecall;
    function UnregisterWindow(AID: Integer): WordBool; safecall;
    function GetWindowName(AIndex: Integer; out AName: WideString): WordBool; safecall;
    function GetWindowModule(AIndex: Integer; out AModule: TGUID): WordBool; safecall;
    function GetWindowByIndex(AIndex: Integer; out AWindow: IAPIWindow): WordBool; safecall;
    function GetWindowByID(AID: Integer; out AWindow: IAPIWindow): WordBool; safecall;
    function GetWindowByIndexWeak(AIndex: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
    function GetWindowByIDWeak(AID: Integer; out AWindow: IAPIWeakRef): WordBool; safecall;
    property WndsCollectionCount: Integer read get_WndsCollectionCount;
  end;

// *********************************************************************//
// Interface: IAPICoreUIControlsCollection
// Flags:     (0)
// GUID:      {4E504300-853B-47FC-849D-690BA62B935C}
// *********************************************************************//
  IAPICoreUIControlsCollection = interface(IUnknown)
    ['{4E504300-853B-47FC-849D-690BA62B935C}']
    function get_UIControlsCollectionCount: Integer; safecall;
    property UIControlsCollectionCount: Integer read get_UIControlsCollectionCount;
  end;

// *********************************************************************//
// Interface: IAPIWindow
// Flags:     (0)
// GUID:      {83AD36D7-878A-442D-B654-4C1A8B113FDE}
// *********************************************************************//
  IAPIWindow = interface(IUnknown)
    ['{83AD36D7-878A-442D-B654-4C1A8B113FDE}']
    procedure ShowWindow; safecall;
    function ShowModalWindow: Integer; safecall;
    procedure CloseWindow; safecall;
  end;

implementation

uses System.Win.ComObj;

end.
