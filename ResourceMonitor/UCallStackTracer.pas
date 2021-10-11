unit UCallStackTracer;
{ This unit is based on Hallvard Vassbotn's YAST stack tracer.
  Hallvard has written some excellent articles about stack tracing in
  The Delphi Magazine:
  -Issue 7: "YAST: Yet Another Stack Tracer!"
  -Issue 50: "Exceptional Stack Tracing"
  The stack tracer in this unit is based on his 32 bit version of YAST as found
  in the unit hvyast32 accompanying issue 50. The Brute-Force Stack Tracing
  algorithm is used because it finds more callers.
  Please read Hallvard's articles to better understand this unit. }
interface

uses
  SysUtils;

const
  MaxTraceLevel = 25;
  { For every stack trace, a maximum of 25 levels are searched to reduce
    memory cost and computation time. Increase this constant if you need
    more history. }

type
  ECallStackTracerError = class(Exception);

type
  TStackTrace = array [0..MaxTraceLevel - 1] of Cardinal;
  { The stack trace only includes caller information (of type Cardinal).
    This is the only information we need for our purposes. }

type
  TCallStackTracer = class
  { The object used to trace call stacks }
  private
    FTopOfStack: Cardinal;
    FBaseOfCode: Cardinal;
    FTopOfCode: Cardinal;
  protected
    function ValidCallSite(Addr: Cardinal): Boolean;
  public
    constructor Create;
    procedure Trace(var StackTrace: TStackTrace);
    { Traces the current call stack and places the callers in the
      StackTrace parameter }
  end;

implementation

uses
  Windows;

type
  PCardinal = ^Cardinal;

function GetTopOfStack: Cardinal; assembler;
asm
  mov eax,fs:[4]
end;

function GetESP: Pointer; assembler;
asm
  mov eax,esp
end;

function GetImageNtHeader(Base: Pointer): PImageNtHeaders;
var
  DOSHeader: PImageDOSHeader;
begin
  DOSHeader := PImageDOSHeader(Base);
  if DOSHeader.e_magic <> IMAGE_DOS_SIGNATURE then
    raise ECallStackTracerError.Create('Not a valid MZ-file!');
  Result := PImageNtHeaders(DWORD(Base) + DWORD(DOSHeader._lfanew));
  if Result.Signature <> IMAGE_NT_SIGNATURE then
    raise ECallStackTracerError.Create('Not a valid PE-file!');
end;

{ TCallStackTracer }

constructor TCallStackTracer.Create;
var
  NTHeader: PImageNTHeaders;
begin
  inherited;
  FTopOfStack := GetTopOfStack;
  NTHeader := GetImageNtHeader(Pointer(HInstance));
  FBaseOfCode := DWord(HInstance) + NTHeader.OptionalHeader.BaseOfCode;
  FTopOfCode := FBaseOfCode + NTHeader.OptionalHeader.SizeOfCode;
end;

procedure TCallStackTracer.Trace(var StackTrace: TStackTrace);
var
  Level: Integer;
  PrevCaller: Cardinal;
  StackPtr: PCardinal;
begin
  PrevCaller := 0;
  StackPtr := GetESP;
  Level := -4;
  { We can ignore the first 4 levels of every stack trace. These are the calls
    to this routine (TCallStackTracer.Trace) and the 3 routines that precede
    this call: TResourceList.Add, TResourceMonitor.<AllocResource> and <Hook>
    (where <AllocResource> is the method called to allocate memory or windows
    resources, and <Hook> is the hooked API or memory manager that calls the
    TResourceMonitor).
    Including these calls in the stack trace is not helpful and wastes memory,
    so we can ignore them by setting the starting level at -4 }

  while (Cardinal(StackPtr) < FTopOfStack) and (Level < MaxTraceLevel) do begin
    if (StackPtr^ <> PrevCaller) and ValidCallSite(StackPtr^) then begin
      if Level >= 0 then
        StackTrace[Level] := StackPtr^ - FBaseOfCode;
      PrevCaller := StackPtr^;
      Inc(Level);
    end;
    Inc(StackPtr);
  end;

  { Terminate the stack trace with a 0 to mark its end }
  if Level < MaxTraceLevel then
    if Level < 0 then
      StackTrace[0] := 0
    else
      StackTrace[Level] := 0;
end;

function TCallStackTracer.ValidCallSite(Addr: Cardinal): Boolean;
var
  Code4: Cardinal;
  Code8: Cardinal;
begin
  Result := (Addr >= FBaseOfCode) and (Addr < FTopOfCode);
  if Result then begin
    Code4 := PCardinal(Addr - 4)^;
    Code8 := PCardinal(Addr - 8)^;
    Result := ((Code8 and $FF000000) = $E8000000)
           or ((Code4 and $38FF0000) = $10FF0000)
           or ((Code4 and $0038FF00) = $0010FF00)
           or ((Code4 and $000038FF) = $000010FF)
           or ((Code8 and $38FF0000) = $10FF0000)
           or ((Code8 and $0038FF00) = $0010FF00)
           or ((Code4 and $FF000000) = $C3000000);
  end;
end;

end.
