unit URMRFiles;
{ This unit contains some classes to read and write resource leak information
  to or from a file. This file is used by the ResourceLeakViewer application
  to display the resource leaks.

  The Resource Monitor Report (RMR) files have the following format:
  -MemoryList
  -USERList
  -GDIList
  -KERNELList
  where each list has the following format:
  -Count (Cardinal): Number of unreleased resources
   and for each unreleased resource:
   -Resource (Cardinal): Resource handle or pointer address
   -ResType (TResourceType): The type of resource
   -StackTraceCount (Cardinal): Number of stack trace entries,
    with for each stack trace entry:
    -CallerAddress (Cardinal) }

interface

uses
  UResourceMonitor, SysUtils;

type
  ERMRError = class(Exception);

type
  TRMRWriter = class
  { This class writes found resource leaks to a file }
  private
    FFile: Integer;
  protected
    procedure WriteList(const List: TResourceList);
    procedure WriteListEntry(const Entry: PResourceEntry);
  public
    constructor Create(const Filename: String; const MemoryList, USERList,
      GDIList, KERNELList: TResourceList);
    { Creates the file and writes the resources leaks in the 4 list parameters.
      After that, the object becomes useless, so you can free it immediately. }
  end;

type
  PRMRResource = ^TRMRResource;
  TRMRResource = record
    Resource: Cardinal;
    ResType: TResourceType;
    StackTrace: array of Cardinal;
  end;

  TRMRResources = array of TRMRResource;

  TRMRList = class
  { This class is used by TRMRReader to store a list of resource leak.
    Every entry in the list is of type TRMRResource }
  private
    FResources: TRMRResources;
    function GetCount: Integer;
    function GetResource(const Index: Integer): PRMRResource;
  public
    constructor Create(const AFile: Integer);
    { Reads the resources from AFile }

    property Count: Integer read GetCount;
    { Number of resources in the list }
    property Resources[const Index: Integer]: PRMRResource read GetResource; default;
    { The resources in the list }
  end;

type
  TRMRReader = class
  { This class is used by the ResourceLeakViewer application to read the
    resource leaks from a file. }
  private
    FMemoryList: TRMRList;
    FUSERList: TRMRList;
    FGDIList: TRMRList;
    FKERNELList: TRMRList;
  public
    constructor Create(const Filename: String);
    { Reads the resource leaks from Filename }

    property MemoryList: TRMRList read FMemoryList;
    { A list containing all memory leaks }
    property USERList: TRMRList read FUSERList;
    { A list containing all USER32 resource leaks }
    property GDIList: TRMRList read FGDIList;
    { A list containing all GDI32 resource leaks }
    property KERNELList: TRMRList read FKERNELList;
    { A list containing all KERNEL32 resource leaks }
  end;

implementation

uses
  UCallStackTracer;

{ TRMRWriter }

constructor TRMRWriter.Create(const Filename: String;
  const MemoryList, USERList,GDIList, KERNELList: TResourceList);
begin
  inherited Create;
  FFile := FileCreate(Filename);
  if FFile < 0 then
    raise ERMRError.Create('Error creating file: ' + ExpandFileName(FileName));
  try
    WriteList(MemoryList);
    WriteList(USERList);
    WriteList(GDIList);
    WriteList(KERNELList);
  finally
    FileClose(FFile);
  end;
end;

procedure TRMRWriter.WriteList(const List: TResourceList);
var
  C: Cardinal;
begin
  C := List.Count;
  FileWrite(FFile,C,SizeOf(C));
  List.ForEach(WriteListEntry);
end;

procedure TRMRWriter.WriteListEntry(const Entry: PResourceEntry);
var
  I, C: Cardinal;
begin
  FileWrite(FFile,Entry.Resource,SizeOf(Entry.Resource));
  FileWrite(FFile,Entry.ResType,SizeOf(Entry.ResType));
  {$IFDEF ResMonST}
  C := 0;
  for I := 0 to MaxTraceLevel - 1 do
    if Entry.StackTrace[I] = 0 then
      Break
    else
      Inc(C);
  FileWrite(FFile,C,SizeOf(C));
  for I := 0 to C - 1 do
    FileWrite(FFile,Entry.StackTrace[I],SizeOf(Cardinal));
  {$ELSE}
  C := 0;
  FileWrite(FFile,C,SizeOf(C));
  {$ENDIF}
end;

{ TRMRList }

constructor TRMRList.Create(const AFile: Integer);
var
  I, ResCount, TraceCount: Integer;
begin
  inherited Create;
  FileRead(AFile,ResCount,SizeOf(ResCount));
  SetLength(FResources,ResCount);
  for I := 0 to ResCount - 1 do begin
    FileRead(AFile,FResources[I].Resource,SizeOf(Cardinal));
    FileRead(AFile,FResources[I].ResType,SizeOf(TResourceType));
    FileRead(AFile,TraceCount,SizeOf(TraceCount));
    SetLength(FResources[I].StackTrace,TraceCount);
    if TraceCount > 0 then
      FileRead(AFile,FResources[I].StackTrace[0],TraceCount * SizeOf(Cardinal));
  end;
end;

function TRMRList.GetCount: Integer;
begin
  Result := Length(FResources);
end;

function TRMRList.GetResource(const Index: Integer): PRMRResource;
begin
  Result := @FResources[Index];
end;

{ TRMRReader }

constructor TRMRReader.Create(const Filename: String);
var
  F: Integer;
begin
  inherited Create;
  F := FileOpen(Filename,fmOpenRead or fmShareDenyWrite);
  if F < 0 then
    raise ERMRError.Create('Error opening file: ' + ExpandFileName(FileName));
  try
    FMemoryList := TRMRList.Create(F);
    FUSERList := TRMRList.Create(F);
    FGDIList := TRMRList.Create(F);
    FKERNELList := TRMRList.Create(F);
  finally
    FileClose(F);
  end;
end;

end.
