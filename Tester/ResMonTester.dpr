program ResMonTester;

uses
  UResourceMonitor,
  Forms,
  FMain in 'FMain.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Resource Monitor Tester';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
