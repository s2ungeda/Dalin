program KeyMngr;

uses
  Vcl.Forms,
  FApiKeyMngr in 'FApiKeyMngr.pas' {FrmApiKeyMngr},
  FInputEntropy in 'FInputEntropy.pas' {FrmInputEntropy},
  USecureString in '..\..\engine\utils\USecureString.pas',
  UEncrypts in '..\..\engine\common\UEncrypts.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmApiKeyMngr, FrmApiKeyMngr);
  Application.Run;
end.
