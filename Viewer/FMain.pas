unit FMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ImgList, URMRFiles, UMapParser,
  UResourceMonitor;

type
  TFrmMain = class(TForm)
    Tree: TTreeView;
    SplitterVert: TSplitter;
    Images: TImageList;
    PnlClient: TPanel;
    Memo: TMemo;
    SplitterHorz: TSplitter;
    PnlStackTrace: TPanel;
    LVStackTrace: TListView;
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FSourceExe: String;
    FRMRReader: TRMRReader;
    FMapParser: TMapParser;
  protected
    procedure AddNodes(const Category: String; const ImageIndex: TImageIndex;
      const List: TRMRList);
    procedure Report(const Msg: String); overload;
    procedure Report(const Msg: String; const Args: array of const); overload;
    procedure ReportStackTrace(const Res: PRMRResource);
    procedure ReportSummary;
    procedure ReportLeakCount(const Kind: String; const List: TRMRList);
    procedure ReportMemoryLeak(const Res: PRMRResource);
    procedure ReportResourceLeak(const Res: PRMRResource; const Kind: String);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

const
  OneSecond = 1 / SecsPerDay; 
  // In Delphi 6 and up, this constant is declared in the unit DateUtils

const // Image Indices
  iiSummary = 0;
  iiMemory  = 1;
  iiUSER    = 2;
  iiGDI     = 3;
  iiKERNEL  = 4;

{ TFrmResourceLeakReport }

procedure TFrmMain.FormCreate(Sender: TObject);
var
  Filename: String;
  ExeTime, MapTime: TDateTime;
begin
  if ParamCount > 0 then begin
    FSourceExe := ParamStr(1);

    Filename := ChangeFileExt(FSourceExe,'.rmr');
    if FileExists(Filename) then begin
      FRMRReader := TRMRReader.Create(Filename);

      Filename := ChangeFileExt(FSourceExe,'.map');
      if FileExists(Filename) then begin
        { Only use map file if it is about the same age as the executable }
        ExeTime := FileDateToDateTime(FileAge(FSourceExe));
        MapTime := FileDateToDateTime(FileAge(Filename));
        if Abs(MapTime - ExeTime) < (15 * OneSecond) then
          FMapParser := TMapParser.Create(Filename);
      end;

      Tree.Items.BeginUpdate;
      try
        Tree.Items.AddChild(nil,'Summary').ImageIndex := iiSummary;
        AddNodes('Memory',iiMemory,FRMRReader.MemoryList);
        AddNodes('USER Resources',iiUSER,FRMRReader.USERList);
        AddNodes('GDI Resources',iiGDI,FRMRReader.GDIList);
        AddNodes('KERNEL Resources',iiKERNEL,FRMRReader.KERNELList);
        Tree.FullExpand;
      finally
        Tree.Items.EndUpdate;
      end;
    end;
  end;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FRMRReader.Free;
  FMapParser.Free;
end;

procedure TFrmMain.TreeChange(Sender: TObject;
  Node: TTreeNode);
var
  Res: PRMRResource;
begin
  Memo.Lines.Clear;
  LVStackTrace.Items.Clear;
  if Assigned(Node) then begin
    if Node.ImageIndex = iiSummary then
      ReportSummary
    else if Node.Level = 1 then begin
      Res := Node.Data;
      case Node.ImageIndex of
        iiMemory: ReportMemoryLeak(Res);
        iiUSER  : ReportResourceLeak(Res,'USER');
        iiGDI   : ReportResourceLeak(Res,'GDI');
        iiKERNEL: ReportResourceLeak(Res,'KERNEL');
      end;
      ReportStackTrace(Res);
    end;
  end;
end;

procedure TFrmMain.AddNodes(const Category: String;
  const ImageIndex: TImageIndex; const List: TRMRList);
var
  Parent, Child: TTreeNode;
  I: Integer;
  Res: PRMRResource;
begin
  if List.Count > 0 then begin
    Parent := Tree.Items.AddChild(nil,Category);
    Parent.ImageIndex := ImageIndex;
    Parent.SelectedIndex := ImageIndex;
    for I := 0 to List.Count - 1 do begin
      Res := List[I];
      Child := Tree.Items.AddChild(Parent,Format('$%.8x',[Res.Resource]));
      Child.Data := Res;
      Child.ImageIndex := ImageIndex;
      Child.SelectedIndex := ImageIndex;
    end;
  end;
end;

procedure TFrmMain.Report(const Msg: string;
  const Args: array of const);
begin
  Memo.Lines.Add(Format(Msg,Args));
end;

procedure TFrmMain.Report(const Msg: String);
begin
  Memo.Lines.Add(Msg);
end;

procedure TFrmMain.ReportMemoryLeak(const Res: PRMRResource);
begin
  Report('Unreleased memory at address: $%.8x',[Res.Resource]);
end;

procedure TFrmMain.ReportResourceLeak(const Res: PRMRResource;
  const Kind: String);
const
  ResourceTypes: array [TResourceType] of String = (
    'Memory','Accelerator Table','Cursor','Icon','Menu','Timer','Bitmap',
    'Brush','Color Space','Device Context','Enhanced Meta File','Font',
    'Meta File','Palette','Pen','Region','File or Object Handle','File Mapping');
begin
  Report('Unreleased %s resource: $%.8x',[Kind,Res.Resource]);
  Report('Resource type: %s',[ResourceTypes[Res.ResType]]);
end;

procedure TFrmMain.ReportStackTrace(const Res: PRMRResource);
var
  I, LineNr: Integer;
  Caller: Cardinal;
  Symbol, UnitName: String;
  Item: TListItem;
begin
  LVStackTrace.Items.BeginUpdate;
  try
    for I := 0 to Length(Res.StackTrace) - 1 do begin
      Caller := Res.StackTrace[I];
      Item := LVStackTrace.Items.Add;
      Item.Caption := Format('$%.8x',[Caller]);
      if Assigned(FMapParser) and FMapParser.FindSymbol(Caller,Symbol) then begin
        Item.SubItems.Add(Symbol);
        if FMapParser.FindLineNr(Caller,UnitName,LineNr) then begin
          Item.SubItems.Add(UnitName);
          Item.SubItems.Add(IntToStr(LineNr));
        end;
      end;
    end;
  finally
    LVStackTrace.Items.EndUpdate;
  end;
end;

procedure TFrmMain.ReportSummary;
begin
  Report('Resource leaks detected in ' + ExtractFilename(FSourceExe) + ':');
  ReportLeakCount('memory',FRMRReader.MemoryList);
  ReportLeakCount('USER resource',FRMRReader.USERList);
  ReportLeakCount('GDI resource',FRMRReader.GDIList);
  ReportLeakCount('KERNEL resource',FRMRReader.KERNELList);
  Report('');
  Report('Select the resources on the left for detailed information.');
  if not Assigned(FMapParser) then begin
    Report('');
    Report('For symbolic information in stack traces, enable the');
    Report('"Detailed map file" linker option and rebuild the project.');
  end;
  Memo.SelStart := 0;
  Memo.SelLength := 0;
end;

procedure TFrmMain.ReportLeakCount(const Kind: String; const List: TRMRList);
begin
  if List.Count > 0 then
    Report('- Number of %s leaks: %d',[Kind,List.Count]);
end;

end.
