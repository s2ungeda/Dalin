program updater;

uses
  Vcl.Forms,
  FMKPUpdater in 'FMKPUpdater.pas' {FrmMKPUpdater};

{$R *.res}

begin
  Application.Initialize;
  //Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := false;
  Application.CreateForm(TFrmMKPUpdater, FrmMKPUpdater);
  Application.Run;
end.
