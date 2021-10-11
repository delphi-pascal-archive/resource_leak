program ResourceLeakViewer;

uses
  Forms,
  FMain in 'FMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Resource Leak Viewer';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
