unit FMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TFrmMain = class(TForm)
    PnlMemory: TPanel;
    BtnGetMem: TButton;
    BtnNew: TButton;
    BtnCreate: TButton;
    LblMemory: TLabel;
    PnlUSER32: TPanel;
    LblUSER32: TLabel;
    BtnLoadBitmap: TButton;
    BtnCreateMenu: TButton;
    BtnSetTimer: TButton;
    CBLeak: TCheckBox;
    BtnClose: TButton;
    PnlGDI32: TPanel;
    LblGDI32: TLabel;
    BtnCreateCompatibleDC: TButton;
    BtnCreateSolidBrush: TButton;
    BtnCreatePen: TButton;
    PnlKERNEL32: TPanel;
    LblKERNEL32: TLabel;
    BtnCreateFileDirect: TButton;
    BtnCreateFileStream: TButton;
    procedure BtnGetMemClick(Sender: TObject);
    procedure BtnNewClick(Sender: TObject);
    procedure BtnCreateClick(Sender: TObject);
    procedure BtnLoadBitmapClick(Sender: TObject);
    procedure CBLeakClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnCreateMenuClick(Sender: TObject);
    procedure BtnSetTimerClick(Sender: TObject);
    procedure BtnCreateCompatibleDCClick(Sender: TObject);
    procedure BtnCreateSolidBrushClick(Sender: TObject);
    procedure BtnCreatePenClick(Sender: TObject);
    procedure BtnCreateFileDirectClick(Sender: TObject);
    procedure BtnCreateFileStreamClick(Sender: TObject);
  private
    { Private declarations }
    FRelease: Boolean;
    procedure TimerExpired(Sender: TObject);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}
{$R SampleResources.res}

procedure TFrmMain.CBLeakClick(Sender: TObject);
var
  Find, Replace, S: String;
  I, J: Integer;
  C: TComponent;
  B: TButton;
begin
  FRelease := not CBLeak.Checked;
  { Adjust the captions of all buttons }
  if FRelease then begin
    Find := ' w/o ';
    Replace := ' with ';
  end else begin
    Find := ' with ';
    Replace := ' w/o ';
  end;
  for I := 0 to ComponentCount - 1 do begin
    C := Components[I];
    if C is TButton then begin
      B := TButton(C);
      S := B.Caption;
      J := Pos(Find,S);
      if J > 0 then begin
        Delete(S,J,Length(Find));
        Insert(Replace,S,J);
        B.Caption := S;
      end;
    end;
  end;
end;

procedure TFrmMain.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMain.BtnGetMemClick(Sender: TObject);
var
  P: Pointer;
begin
  GetMem(P,1000);                                    
  ZeroMemory(P,1000);
  if FRelease then
    FreeMem(P);
end;

procedure TFrmMain.BtnNewClick(Sender: TObject);
var
  P: PInteger;
begin
  New(P);
  P^ := 0;
  if FRelease then
    Dispose(P);
end;

procedure TFrmMain.BtnCreateClick(Sender: TObject);
var
  List: TList;
begin
  List := TList.Create;
  if FRelease then
    List.Free;
end;

procedure TFrmMain.BtnLoadBitmapClick(Sender: TObject);
var
  Bitmap: HBitmap;
begin
  Bitmap := LoadBitmap(HInstance,'SAMPLEBITMAP');
  if Bitmap = 0 then
    raise Exception.Create('Error loading bitmap');
  if FRelease then
    DeleteObject(Bitmap);
end;

procedure TFrmMain.BtnCreateMenuClick(Sender: TObject);
var
  Menu: HMenu;
begin
  Menu := CreateMenu;
  if Menu = 0 then
    raise Exception.Create('Error creating menu');
  if FRelease then
    DestroyMenu(Menu);
end;

procedure TFrmMain.BtnSetTimerClick(Sender: TObject);
var
  Timer: TTimer;
begin
  { The TTimer component uses SetTimer and KillTimer.
    This method creates 2 resource leaks: one for the unreleased TTimer object
    and one for an unreleased Timer resource. }
  Timer := TTimer.Create(nil);
  Timer.OnTimer := TimerExpired;
  if FRelease then
    Timer.Free;
end;

procedure TFrmMain.TimerExpired(Sender: TObject);
begin
  // Dummy TTimer.OnTimer event
end;

procedure TFrmMain.BtnCreateCompatibleDCClick(Sender: TObject);
var
  DC: HDC;
begin
  DC := CreateCompatibleDC(0);
  if DC = 0 then
    raise Exception.Create('Error creating compatible DC');
  if FRelease then
    DeleteDC(DC);
end;

procedure TFrmMain.BtnCreateSolidBrushClick(Sender: TObject);
var
  Brush: HBrush;
begin
  Brush := CreateSolidBrush(clBlack);
  if Brush = 0 then
    raise Exception.Create('Error creating solid brush');
  if FRelease then
    DeleteObject(Brush);
end;

procedure TFrmMain.BtnCreatePenClick(Sender: TObject);
var
  Pen: TPen;
begin
  { Instead of calling CreatePen, a TPen object is created, which creates a pen
    resource using the CreatePenIndirect API. Not releasing this pen creates
    3 resources leak: one for the unreleased HPEN resource, one for the
    unreleased TPen object and one for an unreleased PResource record which is
    added to a TResourceManager in Graphics.pas }
  Pen := TPen.Create;
  if FRelease then
    Pen.Free;
end;

procedure TFrmMain.BtnCreateFileDirectClick(Sender: TObject);
var
  F: THandle;
begin
  F := CreateFile('TestFile1.dat',GENERIC_WRITE,0,nil,CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,0);
  if F = INVALID_HANDLE_VALUE then
    raise Exception.Create('Error creating file');
  if FRelease then
    CloseHandle(F);
end;

procedure TFrmMain.BtnCreateFileStreamClick(Sender: TObject);
var
  F: TFileStream;
begin
  { Instead of calling CreateFile, a TFileStream object is created, which calls
    the CreateFile API to create the actual file. Not releasing this stream
    creates 2 resource leaks: one for the unrelease file handle and one for
    the unreleased TFileStream object. }
  F := TFileStream.Create('TestFile2.dat',fmCreate);
  if FRelease then
    F.Free;
end;

end.
