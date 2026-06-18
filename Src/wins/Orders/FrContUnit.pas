unit FrContUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TFrControlUnit = class(TFrame)
    edtKip: TEdit;
    edtOrderQty: TEdit;
    edtCount: TEdit;
    edtInterval: TEdit;
    ckOn: TCheckBox;
    procedure ckOnClick(Sender: TObject);
    procedure edtKipKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TFrControlUnit.ckOnClick(Sender: TObject);
begin
  if ckOn.Checked then
    Color := clYellow
  else
    Color := clBtnFace;
end;

procedure TFrControlUnit.edtKipKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key in ['0'..'9','.',#8]) then
    Key := #0;
end;

end.
