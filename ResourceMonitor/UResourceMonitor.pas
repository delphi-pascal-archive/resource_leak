unit UResourceMonitor;
{ Use of this unit:
  -Add UResourceMonitor as the very first unit to the projects uses-clause.
  -Modify some settings in the "Project Options" dialog:
    -On the "Directories/Conditionals" tab, add the define "ResMon" to the
     Conditional defines. If you want to enable stack tracing in you reports,
     use the define "ResMonST" instead. However, this consumes more memory and
     slows down the application. If you use the "ResMonST" define, you also need
     to set the following options:
      -On the "Linker" tab, set "Map file" to "Detailed" to include symbolic
       information in the stack trace.
      -On the "Compiler" tab, check the option "Use Debug DCUs" if you want the
       stack trace to contain line number information of VCL units too.
  -Rebuild the project.

  You also need to build the ResourceLeakViewer project first and put the
  executable in you applications build directory or in a directory on your
  systems path.

  If you want to modify this unit, read the following:

  This unit may not use other units that directly or indirectly use the
  Classes-unit. This includes most of the VCL-units. Units that are allowed are
  some RTL-units like SysUtils and Windows.
  The reason for this has to do with the initialization and finalization order
  of units in an application. The initialization-sections of units are called
  in the order that the Delphi compiler encounters them while building the
  project. The finalization-sections are called in reverse order.
  The initialization-section of this unit MUST be called before the
  initialization-section of the Classes-unit because the finalization-section
  of the Classes-unit MUST be called before the finalization-section of this
  unit. Otherwise, not all resources in the Classes-unit are cleaned up and the
  resource monitor will detect some false resource leaks.
  That's why we cannot create a form in this unit to display any found resource
  leak, because the Forms-unit uses the Classes-unit. We could build a form by
  hand using only the Windows-unit, but that would be very laborious.
  Instead, I've opted to store the resource leaks in a datafile (using the
  URMRFiles unit) and call a separate view executable (ResourceLeakViewer) to
  display the actual resource leaks from this file. }

{$IFDEF ResMonST}
  {$DEFINE ResMon}
{$ENDIF}

{$IFNDEF ResMon}
// This unit is empty if the ResMon define is not set.
// This way, this unit has no impact on the application without this define.

interface

implementation

{$ELSE}

interface

uses
  Windows, UCallStackTracer;

const
  { TResourceList uses a hash table of 1024 entries
    to quickly retrieve stored resources }
  ResourceHashSize = 1 shl 10;
  ResourceHashMask = ResourceHashSize - 1;

type
  TResourceType = (
    // Memory
    rtMemory,
    // USER32 Resources
    rtAcceleratorTable,
    rtCursor,
    rtIcon,
    rtMenu,
    rtTimer,
    // GDI32 Resources
    rtBitmap,
    rtBrush,
    rtColorSpace,
    rtDC,
    rtEnhMetaFile,
    rtFont,
    rtMetaFile,
    rtPalette,
    rtPen,
    rtRegion,
    // KERNEL32 Resources
    rtFile,
    rtFileMapping);

  PResourceEntry = ^TResourceEntry;
  TResourceEntry = record
    Resource: Cardinal;
    ResType: TResourceType;
    Next: PResourceEntry;
    {$IFDEF ResMonST}
    StackTrace: TStackTrace;
    {$ENDIF}
  end;

  TResourceBuckets = array [0..ResourceHashSize - 1] of PResourceEntry;

  TResourceCallback = procedure(const Entry: PResourceEntry) of Object;

  TResourceList = class
  { Contains a list of allocated resources. A hash table is used to quickly
    find a resource in the list based on its handle. The hash table uses
    chaining to handle collisions. A very simple hash function is used that is
    both fast and efficient. }
  private
    FBuckets: TResourceBuckets;
    FCount: Integer;
  protected
    procedure FreeBuckets;
    function Hash(const Resource: Cardinal): Cardinal;
  public
    destructor Destroy; override;
    procedure Add(const Resource: Cardinal; const ResType: TResourceType);
    { Adds the Resource to the list }
    function Remove(const Resource: Cardinal): Boolean;
    { Removes the Resource from the list. Returns False if the Resource was not
      in the list }
    procedure ForEach(const Callback: TResourceCallback);
    { Calls the Callback procedure for every resource in the list }

    property Count: Integer read FCount;
    { Number of resources in the list }
  end;

type
  TResourceMonitor = class
  { The main class that tracks the use of resources }
  private
    FLockCount: Integer;
    FLocked: Boolean;

    { Memory monitoring }
    FOriginalMemoryManager: TMemoryManager;
    FMemoryList: TResourceList;

    { Resource monitoring }
    FUSERList: TResourceList;
    FGDIList: TResourceList;
    FKERNELList: TResourceList;
  protected
    procedure Lock;
    procedure Unlock;
    function DetectResourceLeaks: Boolean;
    procedure ReportResourceLeaks;

    { Memory monitoring }
    procedure HookMemoryManager;
    procedure UnhookMemoryManager;

    { Resource monitoring }
    procedure HookAPIs;
    function HookAPI(const TargetProc, HookedProc: Pointer): Pointer;
    procedure UnhookAPIs;
    procedure UnhookAPI(const TargetProc, OrigProc: Pointer);
  public
    constructor Create;
    destructor Destroy; override;

    { Memory monitoring }
    function FreeMem(P: Pointer): Integer;
    function GetMem(Size: Integer): Pointer;
    function ReallocMem(P: Pointer; Size: Integer): Pointer;

    { Resource monitoring }
    procedure GDIResourceAllocated(const ResType: TResourceType;
      const Handle: THandle);
    procedure GDIResourceReleased(const Handle: THandle);
    procedure USERResourceAllocated(const ResType: TResourceType;
      const Handle: THandle);
    procedure USERResourceReleased(const Handle: THandle);
    procedure KERNELResourceAllocated(const ResType: TResourceType;
      const Handle: THandle);
    procedure KERNELResourceReleased(const Handle: THandle);
  end;

implementation

uses
  SysUtils, URMRFiles;

type
  PPointer = ^Pointer;

var
  ResourceMonitor: TResourceMonitor = nil;
  CallStackTracer: TCallStackTracer = nil;

{ Monitored Memory Manager.
  These functions just call the corresponding functions of the resource monitor }

function MonitoredFreeMem(P: Pointer): Integer;
begin
  Result := ResourceMonitor.FreeMem(P);
end;

function MonitoredGetMem(Size: Integer): Pointer;
begin
  Result := ResourceMonitor.GetMem(Size);
end;

function MonitoredReallocMem(P: Pointer; Size: Integer): Pointer;
begin
  Result := ResourceMonitor.ReallocMem(P,Size);
end;

const
  MonitoredMemoryManager: TMemoryManager = (
    GetMem: MonitoredGetMem;
    FreeMem: MonitoredFreeMem;
    ReallocMem: MonitoredReallocMem);

{ Resource monitoring }

{ Variables containing original USER32 APIs }

var
  OrigCreateAcceleratorTable: function(var Accel; Count: Integer): HACCEL; stdcall = nil;
  OrigCreateCursor: function(hInst: HINST; xHotSpot, yHotSpot, nWidth, nHeight: Integer;
    pvANDPlaneter, pvXORPlane: Pointer): HCURSOR; stdcall = nil;
  OrigCreateIconIndirect: function(var piconinfo: TIconInfo): HICON; stdcall = nil;
  OrigCreateMenu: function: HMENU; stdcall = nil;
  OrigCreatePopupMenu: function: HMENU; stdcall = nil;
  OrigDestroyAcceleratorTable: function(hAccel: HACCEL): BOOL; stdcall = nil;
  OrigDestroyCursor: function(hCursor: HICON): BOOL; stdcall = nil;
  OrigDestroyIcon: function(hIcon: HICON): BOOL; stdcall = nil;
  OrigDestroyMenu: function(hMenu: HMENU): BOOL; stdcall = nil;
  OrigLoadBitmap: function(hInstance: HINST; lpBitmapName: PAnsiChar): HBITMAP; stdcall = nil;
  OrigLoadMenu: function(hInstance: HINST; lpMenuName: PAnsiChar): HMENU; stdcall = nil;
  OrigKillTimer: function(hWnd: HWND; uIDEvent: UINT): BOOL; stdcall = nil;
  OrigSetTimer: function(hWnd: HWND; nIDEvent, uElapse: UINT;
    lpTimerFunc: TFNTimerProc): UINT; stdcall = nil;

{ Variables containing original GDI32 APIs }

var
  OrigCloseEnhMetaFile: function(DC: HDC): HENHMETAFILE; stdcall = nil;
  OrigCloseMetaFile: function(DC: HDC): HMETAFILE; stdcall = nil;
  OrigCreateBitmap: function(Width, Height: Integer; Planes, BitCount: Longint;
    Bits: Pointer): HBITMAP; stdcall = nil;
  OrigCreateBitmapIndirect: function(const p1: TBitmap): HBITMAP; stdcall = nil;
  OrigCreateBrushIndirect: function(const p1: TLogBrush): HBRUSH; stdcall = nil;
  OrigCreateColorSpace: function(var ColorSpace: TLogColorSpace): HCOLORSPACE; stdcall = nil;
  OrigCreateCompatibleBitmap: function(DC: HDC; Width, Height: Integer): HBITMAP; stdcall = nil;
  OrigCreateCompatibleDC: function(DC: HDC): HDC; stdcall = nil;
  OrigCreateDC: function(lpszDriver, lpszDevice, lpszOutput: PChar;
    lpdvmInit: PDeviceMode): HDC; stdcall = nil;
  OrigCreateDIBitmap: function(DC: HDC; var InfoHeader: TBitmapInfoHeader;
    dwUsage: DWORD; InitBits: PChar; var InitInfo: TBitmapInfo;
    wUsage: UINT): HBITMAP; stdcall = nil;
  OrigCreateDIBPatternBrush: function(p1: HGLOBAL; p2: UINT): HBRUSH; stdcall = nil;
  OrigCreateDIBPatternBrushPt: function(const p1: Pointer; p2: UINT): HBRUSH; stdcall = nil;
  OrigCreateDIBSection: function(DC: HDC; const p2: TBitmapInfo; p3: UINT;
    var p4: Pointer; p5: THandle; p6: DWORD): HBITMAP; stdcall = nil;
  OrigCreateDiscardableBitmap: function(DC: HDC; p2, p3: Integer): HBITMAP; stdcall = nil;
  OrigCreateEllipticRgn: function(p1, p2, p3, p4: Integer): HRGN; stdcall = nil;
  OrigCreateEllipticRgnIndirect: function(const p1: TRect): HRGN; stdcall = nil;
  OrigCreateFont: function(nHeight, nWidth, nEscapement, nOrientaion, fnWeight: Integer;
    fdwItalic, fdwUnderline, fdwStrikeOut, fdwCharSet, fdwOutputPrecision,
    fdwClipPrecision, fdwQuality, fdwPitchAndFamily: DWORD; lpszFace: PChar): HFONT; stdcall = nil;
  OrigCreateFontIndirect: function(const p1: TLogFont): HFONT; stdcall = nil;
  OrigCreateHalftonePalette: function(DC: HDC): HPALETTE; stdcall = nil;
  OrigCreateHatchBrush: function(p1: Integer; p2: COLORREF): HBRUSH; stdcall = nil;
  OrigCreateIC: function(lpszDriver, lpszDevice, lpszOutput: PChar; lpdvmInit: PDeviceMode): HDC; stdcall = nil;
  OrigCreatePalette: function(const LogPalette: TLogPalette): HPalette; stdcall = nil;
  OrigCreatePatternBrush: function(Bitmap: HBITMAP): HBRUSH; stdcall = nil;
  OrigCreatePen: function(Style, Width: Integer; Color: COLORREF): HPEN; stdcall = nil;
  OrigCreatePenIndirect: function(const LogPen: TLogPen): HPEN; stdcall = nil;
  OrigCreatePolygonRgn: function(const Points; Count, FillMode: Integer): HRGN; stdcall = nil;
  OrigCreatePolyPolygonRgn: function(const pPtStructs; const pIntArray; p3, p4: Integer): HRGN; stdcall = nil;
  OrigCreateRectRgn: function(p1, p2, p3, p4: Integer): HRGN; stdcall = nil;
  OrigCreateRectRgnIndirect: function(const p1: TRect): HRGN; stdcall = nil;
  OrigCreateRoundRectRgn: function(p1, p2, p3, p4, p5, p6: Integer): HRGN; stdcall = nil;
  OrigCreateSolidBrush: function(p1: COLORREF): HBRUSH; stdcall = nil;
  OrigDeleteColorSpace: function(ColorSpace: HCOLORSPACE): BOOL; stdcall = nil;
  OrigDeleteDC: function(DC: HDC): BOOL; stdcall = nil;
  OrigDeleteEnhMetaFile: function(p1: HENHMETAFILE): BOOL; stdcall = nil;
  OrigDeleteMetaFile: function(p1: HMETAFILE): BOOL; stdcall = nil;
  OrigDeleteObject: function(p1: HGDIOBJ): BOOL; stdcall = nil;
  OrigExtCreatePen: function(PenStyle, Width: DWORD; const Brush: TLogBrush;
    StyleCount: DWORD; Style: Pointer): HPEN; stdcall = nil;
  OrigExtCreateRegion: function(XForm: PXForm; Count: DWORD; const RgnData: TRgnData): HRGN; stdcall = nil;

{ Variables containing original KERNEL32 APIs }

var
  OrigCloseHandle: function(hObject: THandle): BOOL; stdcall = nil;
  OrigCreateFile: function(lpFileName: PChar; dwDesiredAccess, dwShareMode: DWORD;
    lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
    hTemplateFile: THandle): THandle; stdcall = nil;
  OrigCreateFileMapping: function(hFile: THandle; lpFileMappingAttributes: PSecurityAttributes;
    flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName: PChar): THandle; stdcall = nil;
  OrigOpenFileMapping: function(dwDesiredAccess: DWORD; bInheritHandle: BOOL; lpName: PChar): THandle; stdcall = nil;

{ Hooked USER32 APIs }

function HookedCreateAcceleratorTable(var Accel; Count: Integer): HACCEL; stdcall;
begin
  Result := OrigCreateAcceleratorTable(Accel,Count);
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtAcceleratorTable,Result);
end;

function HookedCreateCursor(hInst: HINST; xHotSpot, yHotSpot, nWidth, nHeight: Integer;
  pvANDPlaneter, pvXORPlane: Pointer): HCURSOR; stdcall;
begin
  Result := OrigCreateCursor(hInst,xHotSpot,yHotSpot,nWidth,nHeight,
    pvANDPlaneter,pvXORPlane);
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtCursor,Result);
end;

function HookedCreateIconIndirect(var piconinfo: TIconInfo): HICON; stdcall;
begin
  Result := OrigCreateIconIndirect(piconinfo);
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtIcon,Result);
end;

function HookedCreateMenu: HMENU; stdcall;
begin
  Result := OrigCreateMenu;
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtMenu,Result);
end;

function HookedCreatePopupMenu: HMENU; stdcall;
begin
  Result := OrigCreatePopupMenu;
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtMenu,Result);
end;

function HookedDestroyAcceleratorTable(hAccel: HACCEL): BOOL; stdcall;
begin
  Result := OrigDestroyAcceleratorTable(hAccel);
  if Result then
    ResourceMonitor.USERResourceReleased(hAccel);
end;

function HookedDestroyCursor(hCursor: HICON): BOOL; stdcall;
begin
  Result := OrigDestroyCursor(hCursor);
  if Result then
    ResourceMonitor.USERResourceReleased(hCursor);
end;

function HookedDestroyIcon(hIcon: HICON): BOOL; stdcall;
begin
  Result := OrigDestroyIcon(hIcon);
  if Result then
    ResourceMonitor.USERResourceReleased(hIcon);
end;

function HookedDestroyMenu(hMenu: HMENU): BOOL; stdcall;
begin
  Result := OrigDestroyMenu(hMenu);
  if Result then
    ResourceMonitor.USERResourceReleased(hMenu);
end;

function HookedLoadBitmap(hInstance: HINST; lpBitmapName: PAnsiChar): HBITMAP; stdcall;
begin
  Result := OrigLoadBitmap(hInstance,lpBitmapName);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedLoadMenu(hInstance: HINST; lpMenuName: PAnsiChar): HMENU; stdcall;
begin
  Result := OrigLoadMenu(hInstance,lpMenuName);
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtMenu,Result);
end;

function HookedKillTimer(hWnd: HWND; uIDEvent: UINT): BOOL; stdcall;
begin
  Result := OrigKillTimer(hWnd,uIDEvent);
  if Result then
    ResourceMonitor.USERResourceReleased(hWnd);
end;

function HookedSetTimer(hWnd: HWND; nIDEvent, uElapse: UINT;
  lpTimerFunc: TFNTimerProc): UINT; stdcall;
begin
  Result := OrigSetTimer(hWnd,nIDEvent,uElapse,lpTimerFunc);
  if Result <> 0 then
    ResourceMonitor.USERResourceAllocated(rtTimer,hWnd);
end;

{ Hooked GDI32 APIs }

function HookedCloseEnhMetaFile(DC: HDC): HENHMETAFILE; stdcall;
begin
  Result := OrigCloseEnhMetaFile(DC);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtEnhMetaFile,Result);
end;

function HookedCloseMetaFile(DC: HDC): HMETAFILE; stdcall;
begin
  Result := OrigCloseMetaFile(DC);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtMetaFile,Result);
end;

function HookedCreateBitmap(Width, Height: Integer; Planes, BitCount: Longint;
  Bits: Pointer): HBITMAP; stdcall;
begin
  Result := OrigCreateBitmap(Width,Height,Planes,BitCount,Bits);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateBitmapIndirect(const p1: TBitmap): HBITMAP; stdcall;
begin
  Result := OrigCreateBitmapIndirect(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateBrushIndirect(const p1: TLogBrush): HBRUSH; stdcall;
begin
  Result := OrigCreateBrushIndirect(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedCreateColorSpace(var ColorSpace: TLogColorSpace): HCOLORSPACE; stdcall;
begin
  Result := OrigCreateColorSpace(ColorSpace);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtColorSpace,Result);
end;

function HookedCreateCompatibleBitmap(DC: HDC; Width, Height: Integer): HBITMAP; stdcall;
begin
  Result := OrigCreateCompatibleBitmap(DC,Width,Height);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateCompatibleDC(DC: HDC): HDC; stdcall;
begin
  Result := OrigCreateCompatibleDC(DC);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtDC,Result);
end;

function HookedCreateDC(lpszDriver, lpszDevice, lpszOutput: PChar;
  lpdvmInit: PDeviceMode): HDC; stdcall;
begin
  Result := OrigCreateDC(lpszDriver,lpszDevice,lpszOutput,lpdvmInit);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtDC,Result);
end;

function HookedCreateDIBitmap(DC: HDC; var InfoHeader: TBitmapInfoHeader;
  dwUsage: DWORD; InitBits: PChar; var InitInfo: TBitmapInfo;
  wUsage: UINT): HBITMAP; stdcall;
begin
  Result := OrigCreateDIBitmap(DC,InfoHeader,dwUsage,InitBits,InitInfo,wUsage);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateDIBPatternBrush(p1: HGLOBAL; p2: UINT): HBRUSH; stdcall;
begin
  Result := OrigCreateDIBPatternBrush(p1,p2);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedCreateDIBPatternBrushPt(const p1: Pointer; p2: UINT): HBRUSH; stdcall;
begin
  Result := OrigCreateDIBPatternBrushPt(p1,p2);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedCreateDIBSection(DC: HDC; const p2: TBitmapInfo; p3: UINT;
  var p4: Pointer; p5: THandle; p6: DWORD): HBITMAP; stdcall;
begin
  Result := OrigCreateDIBSection(DC,p2,p3,p4,p5,p6);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateDiscardableBitmap(DC: HDC; p2, p3: Integer): HBITMAP; stdcall;
begin
  Result := OrigCreateDiscardableBitmap(DC,p2,p3);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBitmap,Result);
end;

function HookedCreateEllipticRgn(p1, p2, p3, p4: Integer): HRGN; stdcall;
begin
  Result := OrigCreateEllipticRgn(p1,p2,p3,p4);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateEllipticRgnIndirect(const p1: TRect): HRGN; stdcall;
begin
  Result := OrigCreateEllipticRgnIndirect(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateFont(nHeight, nWidth, nEscapement, nOrientaion, fnWeight: Integer;
  fdwItalic, fdwUnderline, fdwStrikeOut, fdwCharSet, fdwOutputPrecision,
  fdwClipPrecision, fdwQuality, fdwPitchAndFamily: DWORD; lpszFace: PChar): HFONT; stdcall;
begin
  Result := OrigCreateFont(nHeight,nWidth,nEscapement,nOrientaion,fnWeight,
    fdwItalic,fdwUnderline,fdwStrikeOut,fdwCharSet,fdwOutputPrecision,
    fdwClipPrecision,fdwQuality,fdwPitchAndFamily,lpszFace);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtFont,Result);
end;

function HookedCreateFontIndirect(const p1: TLogFont): HFONT; stdcall;
begin
  Result := OrigCreateFontIndirect(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtFont,Result);
end;

function HookedCreateHalftonePalette(DC: HDC): HPALETTE; stdcall;
begin
  Result := OrigCreateHalftonePalette(DC);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtPalette,Result);
end;

function HookedCreateHatchBrush(p1: Integer; p2: COLORREF): HBRUSH; stdcall;
begin
  Result := OrigCreateHatchBrush(p1,p2);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedCreateIC(lpszDriver, lpszDevice, lpszOutput: PChar; lpdvmInit: PDeviceMode): HDC; stdcall;
begin
  Result := OrigCreateIC(lpszDriver,lpszDevice,lpszOutput,lpdvmInit);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtDC,Result);
end;

function HookedCreatePalette(const LogPalette: TLogPalette): HPalette; stdcall;
begin
  Result := OrigCreatePalette(LogPalette);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtPalette,Result);
end;

function HookedCreatePatternBrush(Bitmap: HBITMAP): HBRUSH; stdcall;
begin
  Result := OrigCreatePatternBrush(Bitmap);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedCreatePen(Style, Width: Integer; Color: COLORREF): HPEN; stdcall;
begin
  Result := OrigCreatePen(Style,Width,Color);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtPen,Result);
end;

function HookedCreatePenIndirect(const LogPen: TLogPen): HPEN; stdcall;
begin
  Result := OrigCreatePenIndirect(LogPen);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtPen,Result);
end;

function HookedCreatePolygonRgn(const Points; Count, FillMode: Integer): HRGN; stdcall;
begin
  Result := OrigCreatePolygonRgn(Points,Count,FillMode);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreatePolyPolygonRgn(const pPtStructs; const pIntArray; p3, p4: Integer): HRGN; stdcall;
begin
  Result := OrigCreatePolyPolygonRgn(pPtStructs,pIntArray,p3,p4);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateRectRgn(p1, p2, p3, p4: Integer): HRGN; stdcall;
begin
  Result := OrigCreateRectRgn(p1,p2,p3,p4);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateRectRgnIndirect(const p1: TRect): HRGN; stdcall;
begin
  Result := OrigCreateRectRgnIndirect(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateRoundRectRgn(p1, p2, p3, p4, p5, p6: Integer): HRGN; stdcall;
begin
  Result := OrigCreateRoundRectRgn(p1,p2,p3,p4,p5,p6);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

function HookedCreateSolidBrush(p1: COLORREF): HBRUSH; stdcall;
begin
  Result := OrigCreateSolidBrush(p1);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtBrush,Result);
end;

function HookedDeleteColorSpace(ColorSpace: HCOLORSPACE): BOOL; stdcall;
begin
  Result := OrigDeleteColorSpace(ColorSpace);
  if Result then
    ResourceMonitor.GDIResourceReleased(ColorSpace);
end;

function HookedDeleteDC(DC: HDC): BOOL; stdcall;
begin
  Result := OrigDeleteDC(DC);
  if Result then
    ResourceMonitor.GDIResourceReleased(DC);
end;

function HookedDeleteEnhMetaFile(p1: HENHMETAFILE): BOOL; stdcall;
begin
  Result := OrigDeleteEnhMetaFile(p1);
  if Result then
    ResourceMonitor.GDIResourceReleased(p1);
end;

function HookedDeleteMetaFile(p1: HMETAFILE): BOOL; stdcall;
begin
  Result := OrigDeleteMetaFile(p1);
  if Result then
    ResourceMonitor.GDIResourceReleased(p1);
end;

function HookedDeleteObject(p1: HGDIOBJ): BOOL; stdcall;
begin
  Result := OrigDeleteObject(p1);
  if Result then
    ResourceMonitor.GDIResourceReleased(p1);
end;

function HookedExtCreatePen(PenStyle, Width: DWORD; const Brush: TLogBrush;
  StyleCount: DWORD; Style: Pointer): HPEN; stdcall;
begin
  Result := OrigExtCreatePen(PenStyle,Width,Brush,StyleCount,Style);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtPen,Result);
end;

function HookedExtCreateRegion(XForm: PXForm; Count: DWORD; const RgnData: TRgnData): HRGN; stdcall;
begin
  Result := OrigExtCreateRegion(XForm,Count,RgnData);
  if Result <> 0 then
    ResourceMonitor.GDIResourceAllocated(rtRegion,Result);
end;

{ Hooked KERNEL32 APIs }

function HookedCloseHandle(hObject: THandle): BOOL; stdcall;
begin
  Result := OrigCloseHandle(hObject);
  if Result then
    ResourceMonitor.KERNELResourceReleased(hObject);
end;

function HookedCreateFile(lpFileName: PChar; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle; stdcall;
begin
  Result := OrigCreateFile(lpFilename,dwDesiredAccess,dwShareMode,
    lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,
    hTemplateFile);
  if Result <> INVALID_HANDLE_VALUE then
    ResourceMonitor.KERNELResourceAllocated(rtFile,Result);
end;

function HookedCreateFileMapping(hFile: THandle; lpFileMappingAttributes: PSecurityAttributes;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName: PChar): THandle; stdcall;
begin
  Result := OrigCreateFileMapping(hFile,lpFileMappingAttributes,flProtect,
    dwMaximumSizeHigh,dwMaximumSizeLow,lpName);
  if Result <> 0 then
    ResourceMonitor.KERNELResourceAllocated(rtFileMapping,Result);
end;

function HookedOpenFileMapping(dwDesiredAccess: DWORD; bInheritHandle: BOOL; lpName: PChar): THandle; stdcall;
begin
  Result := OrigOpenFileMapping(dwDesiredAccess,bInheritHandle,lpName);
  if Result <> 0 then
    ResourceMonitor.KERNELResourceAllocated(rtFileMapping,Result);
end;

{ TResourceMonitor }

constructor TResourceMonitor.Create;
begin
  inherited;
  FMemoryList := TResourceList.Create;
  FUSERList := TResourceList.Create;
  FGDIList := TResourceList.Create;
  FKERNELList := TResourceList.Create;
  HookMemoryManager;
  HookAPIs;
end;

destructor TResourceMonitor.Destroy;
begin
  Lock;
  UnhookAPIs;
  UnhookMemoryManager;
  if DetectResourceLeaks then
    ReportResourceLeaks;
  FKERNELList.Free;
  FGDIList.Free;
  FUSERList.Free;
  FMemoryList.Free;
  inherited;
end;

procedure TResourceMonitor.Lock;
begin
  Inc(FLockCount);
  FLocked := True;
end;

procedure TResourceMonitor.Unlock;
begin
  if FLockCount > 0 then
    Dec(FLockCount);
  FLocked := (FLockCount > 0);
end;

function TResourceMonitor.DetectResourceLeaks: Boolean;
begin
  Result := (FMemoryList.Count > 0) or (FUSERList.Count > 0)
    or (FGDIList.Count > 0) or (FKERNELList.Count > 0);
end;

procedure TResourceMonitor.ReportResourceLeaks;
const
  ViewerProg = 'ResourceLeakViewer.exe';
var
  Filename: String;
  RMRFile: TRMRWriter;
begin
  { When this unit is used in the viewer application itself, don't start the
    viewer again }
  if not SameText(ExtractFilename(ParamStr(0)),ViewerProg) then begin
    Filename := ChangeFileExt(ParamStr(0),'.rmr');
    RMRFile := TRMRWriter.Create(Filename,FMemoryList,FUSERList,FGDIList,FKERNELList);
    RMRFile.Free;
    Filename := ViewerProg + ' "' + ParamStr(0) + '"';
    if WinExec(PChar(Filename),SW_SHOWNORMAL) < 32 then
      MessageBox(0,'Unable to execute ' + ViewerProg + #13+
        'Build this program first and place it in your applications build ' +
        'directory or in a directory in your systems path.','Error',MB_OK or MB_ICONERROR);
  end;
end;

{ Memory monitoring }

procedure TResourceMonitor.HookMemoryManager;
begin
  GetMemoryManager(FOriginalMemoryManager);
  SetMemoryManager(MonitoredMemoryManager);
end;

procedure TResourceMonitor.UnhookMemoryManager;
begin
  SetMemoryManager(FOriginalMemoryManager);
end;

function TResourceMonitor.GetMem(Size: Integer): Pointer;
begin
  Result := FOriginalMemoryManager.GetMem(Size);
  if (not FLocked) and Assigned(Result) then begin
    Lock;
    // No try..finally here for performance reasons
    FMemoryList.Add(Cardinal(Result),rtMemory);
    Unlock;
  end;
end;

function TResourceMonitor.FreeMem(P: Pointer): Integer;
begin
  Result := FOriginalMemoryManager.FreeMem(P);
  if (not FLocked) and (Result = 0) then begin
    Lock;
    FMemoryList.Remove(Cardinal(P));
    Unlock;
  end;
end;

function TResourceMonitor.ReallocMem(P: Pointer; Size: Integer): Pointer;
begin
  Result := FOriginalMemoryManager.ReallocMem(P,Size);
  if not FLocked then begin
    if (Size = 0) then
      if Assigned(P) then begin
        { Size=0, P<>nil: An existing pointer is reallocated to 0 bytes, which
          effectively means that it is freed. }
        Lock;
        FMemoryList.Remove(Cardinal(P));
        Unlock;
      end else
    else
      if not Assigned(P) then begin
        { Size<>0, P=nil: A non-existing pointer is reallocated, which
          corresponds to a new memory allocation (like GetMem) }
        Lock;
        FMemoryList.Add(Cardinal(Result),rtMemory);
        Unlock;
      end else if Assigned(Result) and (P <> Result) then begin
        { P<>nil, Result<>nil, P<>Result: P is reallocated to a new address }
        Lock;
        FMemoryList.Remove(Cardinal(P));
        FMemoryList.Add(Cardinal(Result),rtMemory);
        Unlock;
      end;
  end;
end;

{ Resource monitoring }

procedure TResourceMonitor.HookAPIs;
begin
  // USER32 hooks
  @OrigCreateAcceleratorTable   := HookAPI(@CreateAcceleratorTable,   @HookedCreateAcceleratorTable);
  @OrigCreateCursor             := HookAPI(@CreateCursor,             @HookedCreateCursor);
  @OrigCreateIconIndirect       := HookAPI(@CreateIconIndirect,       @HookedCreateIconIndirect);
  @OrigCreateMenu               := HookAPI(@CreateMenu,               @HookedCreateMenu);
  @OrigCreatePopupMenu          := HookAPI(@CreatePopupMenu,          @HookedCreatePopupMenu);
  @OrigDestroyAcceleratorTable  := HookAPI(@DestroyAcceleratorTable,  @HookedDestroyAcceleratorTable);
  @OrigDestroyIcon              := HookAPI(@DestroyIcon,              @HookedDestroyIcon);
  @OrigDestroyMenu              := HookAPI(@DestroyMenu,              @HookedDestroyMenu);
  @OrigDestroyCursor            := HookAPI(@DestroyCursor,            @HookedDestroyCursor);
  @OrigLoadBitmap               := HookAPI(@LoadBitmap,               @HookedLoadBitmap);
  @OrigLoadMenu                 := HookAPI(@LoadMenu,                 @HookedLoadMenu);
  @OrigKillTimer                := HookAPI(@KillTimer,                @HookedKillTimer);
  @OrigSetTimer                 := HookAPI(@SetTimer,                 @HookedSetTimer);

  // GDI32 hooks
  @OrigCloseEnhMetaFile         := HookAPI(@CloseEnhMetaFile,         @HookedCloseEnhMetaFile);
  @OrigCloseMetaFile            := HookAPI(@CloseMetaFile,            @HookedCloseMetaFile);
  @OrigCreateBitmap             := HookAPI(@CreateBitmap,             @HookedCreateBitmap);
  @OrigCreateBitmapIndirect     := HookAPI(@CreateBitmapIndirect,     @HookedCreateBitmapIndirect);
  @OrigCreateBrushIndirect      := HookAPI(@CreateBrushIndirect,      @HookedCreateBrushIndirect);
  @OrigCreateColorSpace         := HookAPI(@CreateColorSpace,         @HookedCreateColorSpace);
  @OrigCreateCompatibleDC       := HookAPI(@CreateCompatibleDC,       @HookedCreateCompatibleDC);
  @OrigCreateCompatibleBitmap   := HookAPI(@CreateCompatibleBitmap,   @HookedCreateCompatibleBitmap);
  @OrigCreateDC                 := HookAPI(@CreateDC,                 @HookedCreateDC);
  @OrigCreateDIBitmap           := HookAPI(@CreateDIBitmap,           @HookedCreateDIBitmap);
  @OrigCreateDIBPatternBrush    := HookAPI(@CreateDIBPatternBrush,    @HookedCreateDIBPatternBrush);
  @OrigCreateDIBPatternBrushPt  := HookAPI(@CreateDIBPatternBrushPt,  @HookedCreateDIBPatternBrushPt);
  @OrigCreateDIBSection         := HookAPI(@CreateDIBSection,         @HookedCreateDIBSection);
  @OrigCreateDiscardableBitmap  := HookAPI(@CreateDiscardableBitmap,  @HookedCreateDiscardableBitmap);
  @OrigCreateEllipticRgn        := HookAPI(@CreateEllipticRgn,        @HookedCreateEllipticRgn);
  @OrigCreateEllipticRgnIndirect:= HookAPI(@CreateEllipticRgnIndirect,@HookedCreateEllipticRgnIndirect);
  @OrigCreateFont               := HookAPI(@CreateFont,               @HookedCreateFont);
  @OrigCreateFontIndirect       := HookAPI(@CreateFontIndirect,       @HookedCreateFontIndirect);
  @OrigCreateHalftonePalette    := HookAPI(@CreateHalftonePalette,    @HookedCreateHalftonePalette);
  @OrigCreateHatchBrush         := HookAPI(@CreateHatchBrush,         @HookedCreateHatchBrush);
  @OrigCreateIC                 := HookAPI(@CreateIC,                 @HookedCreateIC);
  @OrigCreatePalette            := HookAPI(@CreatePalette,            @HookedCreatePalette);
  @OrigCreatePatternBrush       := HookAPI(@CreatePatternBrush,       @HookedCreatePatternBrush);
  @OrigCreatePen                := HookAPI(@CreatePen,                @HookedCreatePen);
  @OrigCreatePenIndirect        := HookAPI(@CreatePenIndirect,        @HookedCreatePenIndirect);
  @OrigCreatePolyPolygonRgn     := HookAPI(@CreatePolyPolygonRgn,     @HookedCreatePolyPolygonRgn);
  @OrigCreatePolygonRgn         := HookAPI(@CreatePolygonRgn,         @HookedCreatePolygonRgn);
  @OrigCreateRectRgn            := HookAPI(@CreateRectRgn,            @HookedCreateRectRgn);
  @OrigCreateRectRgnIndirect    := HookAPI(@CreateRectRgnIndirect,    @HookedCreateRectRgnIndirect);
  @OrigCreateRoundRectRgn       := HookAPI(@CreateRoundRectRgn,       @HookedCreateRoundRectRgn);
  @OrigCreateSolidBrush         := HookAPI(@CreateSolidBrush,         @HookedCreateSolidBrush);
  @OrigDeleteColorSpace         := HookAPI(@DeleteColorSpace,         @HookedDeleteColorSpace);
  @OrigDeleteDC                 := HookAPI(@DeleteDC,                 @HookedDeleteDC);
  @OrigDeleteEnhMetaFile        := HookAPI(@DeleteEnhMetaFile,        @HookedDeleteEnhMetaFile);
  @OrigDeleteMetaFile           := HookAPI(@DeleteMetaFile,           @HookedDeleteMetaFile);
  @OrigDeleteObject             := HookAPI(@DeleteObject,             @HookedDeleteObject);
  @OrigExtCreatePen             := HookAPI(@ExtCreatePen,             @HookedExtCreatePen);
  @OrigExtCreateRegion          := HookAPI(@ExtCreateRegion,          @HookedExtCreateRegion);

  // KERNEL32 hooks
  @OrigCloseHandle              := HookAPI(@CloseHandle,              @HookedCloseHandle);
  @OrigCreateFile               := HookAPI(@CreateFile,               @HookedCreateFile);
  @OrigCreateFileMapping        := HookAPI(@CreateFileMapping,        @HookedCreateFileMapping);
  @OrigOpenFileMapping          := HookAPI(@OpenFileMapping,          @HookedOpenFileMapping);
end;

procedure TResourceMonitor.UnhookAPIs;
begin
  // USER32 hooks
  UnhookAPI(@CreateAcceleratorTable,   @OrigCreateAcceleratorTable);
  UnhookAPI(@CreateCursor,             @OrigCreateCursor);
  UnhookAPI(@CreateIconIndirect,       @OrigCreateIconIndirect);
  UnhookAPI(@CreateMenu,               @OrigCreateMenu);
  UnhookAPI(@CreatePopupMenu,          @OrigCreatePopupMenu);
  UnhookAPI(@DestroyAcceleratorTable,  @OrigDestroyAcceleratorTable);
  UnhookAPI(@DestroyIcon,              @OrigDestroyIcon);
  UnhookAPI(@DestroyMenu,              @OrigDestroyMenu);
  UnhookAPI(@DestroyCursor,            @OrigDestroyCursor);
  UnhookAPI(@LoadBitmap,               @OrigLoadBitmap);
  UnhookAPI(@LoadMenu,                 @OrigLoadMenu);
  UnhookAPI(@KillTimer,                @OrigKillTimer);
  UnhookAPI(@SetTimer,                 @OrigSetTimer);

  // GDI32 hooks
  UnhookAPI(@CloseEnhMetaFile,         @OrigCloseEnhMetaFile);
  UnhookAPI(@CloseMetaFile,            @OrigCloseMetaFile);
  UnhookAPI(@CreateBitmap,             @OrigCreateBitmap);
  UnhookAPI(@CreateBitmapIndirect,     @OrigCreateBitmapIndirect);
  UnhookAPI(@CreateBrushIndirect,      @OrigCreateBrushIndirect);
  UnhookAPI(@CreateColorSpace,         @OrigCreateColorSpace);
  UnhookAPI(@CreateCompatibleDC,       @OrigCreateCompatibleDC);
  UnhookAPI(@CreateCompatibleBitmap,   @OrigCreateCompatibleBitmap);
  UnhookAPI(@CreateDC,                 @OrigCreateDC);
  UnhookAPI(@CreateDIBitmap,           @OrigCreateDIBitmap);
  UnhookAPI(@CreateDIBPatternBrush,    @OrigCreateDIBPatternBrush);
  UnhookAPI(@CreateDIBPatternBrushPt,  @OrigCreateDIBPatternBrushPt);
  UnhookAPI(@CreateDIBSection,         @OrigCreateDIBSection);
  UnhookAPI(@CreateDiscardableBitmap,  @OrigCreateDiscardableBitmap);
  UnhookAPI(@CreateEllipticRgn,        @OrigCreateEllipticRgn);
  UnhookAPI(@CreateEllipticRgnIndirect,@OrigCreateEllipticRgnIndirect);
  UnhookAPI(@CreateFont,               @OrigCreateFont);
  UnhookAPI(@CreateFontIndirect,       @OrigCreateFontIndirect);
  UnhookAPI(@CreateHalftonePalette,    @OrigCreateHalftonePalette);
  UnhookAPI(@CreateHatchBrush,         @OrigCreateHatchBrush);
  UnhookAPI(@CreateIC,                 @OrigCreateIC);
  UnhookAPI(@CreatePalette,            @OrigCreatePalette);
  UnhookAPI(@CreatePatternBrush,       @OrigCreatePatternBrush);
  UnhookAPI(@CreatePen,                @OrigCreatePen);
  UnhookAPI(@CreatePenIndirect,        @OrigCreatePenIndirect);
  UnhookAPI(@CreatePolyPolygonRgn,     @OrigCreatePolyPolygonRgn);
  UnhookAPI(@CreatePolygonRgn,         @OrigCreatePolygonRgn);
  UnhookAPI(@CreateRectRgn,            @OrigCreateRectRgn);
  UnhookAPI(@CreateRectRgnIndirect,    @OrigCreateRectRgnIndirect);
  UnhookAPI(@CreateRoundRectRgn,       @OrigCreateRoundRectRgn);
  UnhookAPI(@CreateSolidBrush,         @OrigCreateSolidBrush);
  UnhookAPI(@DeleteColorSpace,         @OrigDeleteColorSpace);
  UnhookAPI(@DeleteDC,                 @OrigDeleteDC);
  UnhookAPI(@DeleteEnhMetaFile,        @OrigDeleteEnhMetaFile);
  UnhookAPI(@DeleteMetaFile,           @OrigDeleteMetaFile);
  UnhookAPI(@DeleteObject,             @OrigDeleteObject);
  UnhookAPI(@ExtCreatePen,             @OrigExtCreatePen);
  UnhookAPI(@ExtCreateRegion,          @OrigExtCreateRegion);

  // KERNEL32 hooks
  UnhookAPI(@CloseHandle,              @OrigCloseHandle);
  UnhookAPI(@CreateFile,               @OrigCreateFile);
  UnhookAPI(@CreateFileMapping,        @OrigCreateFileMapping);
  UnhookAPI(@OpenFileMapping,          @OrigOpenFileMapping);
end;

function TResourceMonitor.HookAPI(const TargetProc,
  HookedProc: Pointer): Pointer;
var
  JmpAddress, TableAddress: PPointer;
begin
  { Modify the DLL import table entry for TargetProc by replacing it with
    the address of HookedProc. Returns the address in the original entry.
    TargetProc contains an indirect JMP instruction, for example:
      jmp [$12345678]
    First check if TargetProc contains such a JMP instruction. }
  if PWord(TargetProc)^ <> $25FF then begin
    Assert(False,'Trying to hook a routine that does not use an import table');
    Result := nil;
  end else begin
    { The jmp-opcode itself occupies 2 bytes, so to get to the address itself,
      increment it with 2: }
    JmpAddress := TargetProc;
    Inc(PByte(JmpAddress),2);
    { Next, retrieve the address in the import table ($12345678 in this case) }
    TableAddress := JmpAddress^;
    { At this address, the address of the original API is located }
    Result := TableAddress^;
    { Replace this with the address of the hooked API }
    TableAddress^ := HookedProc;
  end;
end;

procedure TResourceMonitor.UnhookAPI(const TargetProc, OrigProc: Pointer);
var
  JmpAddress, TableAddress: PPointer;
begin
  { See the HookAPI method for details }
  if PWord(TargetProc)^ <> $25FF then
    Assert(False,'Trying to unhook a routine that does not use an import table')
  else begin
    JmpAddress := TargetProc;
    Inc(PByte(JmpAddress),2);
    TableAddress := JmpAddress^;
    TableAddress^ := OrigProc;
  end;
end;

procedure TResourceMonitor.GDIResourceAllocated(
  const ResType: TResourceType; const Handle: THandle);
begin
  Lock;
  FGDIList.Add(Handle,ResType);
  Unlock;
end;

procedure TResourceMonitor.GDIResourceReleased(const Handle: THandle);
begin
  Lock;
  FGDIList.Remove(Handle);
  Unlock;
end;

procedure TResourceMonitor.USERResourceAllocated(
  const ResType: TResourceType; const Handle: THandle);
begin
  Lock;
  FUSERList.Add(Handle,ResType);
  Unlock;
end;

procedure TResourceMonitor.USERResourceReleased(const Handle: THandle);
begin
  Lock;
  FUSERList.Remove(Handle);
  Unlock;
end;

procedure TResourceMonitor.KERNELResourceAllocated(
  const ResType: TResourceType; const Handle: THandle);
begin
  Lock;
  FKERNELList.Add(Handle,ResType);
  Unlock;
end;

procedure TResourceMonitor.KERNELResourceReleased(const Handle: THandle);
begin
  Lock;
  FKERNELList.Remove(Handle);
  Unlock;
end;

{ TResourceList }

procedure TResourceList.Add(const Resource: Cardinal;
  const ResType: TResourceType);
var
  HashCode: Cardinal;
  Entry: PResourceEntry;
begin
  HashCode := Hash(Resource);

  { Create a new resource entry and add it to the beginning of the
    appropriate chain in the hash table }
  New(Entry);
  Entry.Resource := Resource;
  Entry.ResType := ResType;
  Entry.Next := FBuckets[HashCode];
  FBuckets[HashCode] := Entry;
  Inc(FCount);

  {$IFDEF ResMonST}
  CallStackTracer.Trace(Entry.StackTrace);
  {$ENDIF}
end;

function TResourceList.Remove(const Resource: Cardinal): Boolean;
var
  HashCode: Cardinal;
  Entry, Prev: PResourceEntry;
begin
  HashCode := Hash(Resource);

  { Find the resource in the hash table }
  Prev := nil;
  Entry := FBuckets[HashCode];
  while Assigned(Entry) and (Entry.Resource <> Resource) do begin
    Prev := Entry;
    Entry := Entry.Next;
  end;

  Result := Assigned(Entry);
  if Result then begin
    { If there is a previous entry in the chain, then modify its Next-member
      to skip this entry. Otherwise, this entry was the first entry in the
      chain. }
    if Assigned(Prev) then
      Prev.Next := Entry.Next
    else
      FBuckets[HashCode] := Entry.Next;
    Dispose(Entry);
    Dec(FCount);
  end;
end;

destructor TResourceList.Destroy;
begin
  FreeBuckets;
  inherited;
end;

procedure TResourceList.FreeBuckets;
var
  I: Integer;
  Entry, Next: PResourceEntry;
begin
  for I := 0 to ResourceHashSize - 1 do begin
    Entry := FBuckets[I];
    while Assigned(Entry) do begin
      Next := Entry.Next;
      Dispose(Entry);
      Entry := Next;
    end;
  end;
end;

function TResourceList.Hash(const Resource: Cardinal): Cardinal;
begin
  { This simple hash function just ignores the lower two bits of the Resource
    handle. Many resources, including pointers, are multiples of 4, so the
    lower two bits contain no useful information }
  Result := (Resource shr 2) and ResourceHashMask;
end;

procedure TResourceList.ForEach(const Callback: TResourceCallback);
var
  I: Integer;
  Entry: PResourceEntry;
begin
  for I := 0 to ResourceHashSize - 1 do begin
    Entry := FBuckets[I];
    while Assigned(Entry) do begin
      Callback(Entry);
      Entry := Entry.Next;
    end;
  end;
end;

initialization
  {$IFDEF ResMonST}
  CallStackTracer := TCallStackTracer.Create;
  {$ENDIF};
  ResourceMonitor := TResourceMonitor.Create;

finalization
  FreeAndNil(ResourceMonitor);
  FreeAndNil(CallStackTracer);

{$ENDIF} // IFNDEF ResMon

end.
