unit FInputEntropy;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls;

type
  TFrmInputEntropy = class(TForm)
    edtInput: TLabeledEdit;
    edtConfirm: TLabeledEdit;
    Label1: TLabel;
    Button1: TButton;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    FIsInput : boolean;
  public
    { Public declarations }

    function Open(bInput: boolean) : boolean;
  end;

var
  FrmInputEntropy: TFrmInputEntropy;

implementation

{$R *.dfm}

procedure TFrmInputEntropy.Button1Click(Sender: TObject);
begin
  if edtInput.Text = '' then
  begin
    ShowMessage('Entropy 값을 입력하세요');
    Exit;
  end;

  if not FIsInput then
    if edtInput.Text <> edtConfirm.Text then
    begin
      ShowMessage('Entropy 값이 일치 하지 않음');
      Exit;
    end;

  ModalResult := mrOK;
end;

procedure TFrmInputEntropy.FormCreate(Sender: TObject);
begin
  //FIsInput := false;
end;

procedure TFrmInputEntropy.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Button1Click(Button1);
  end;
end;

function TFrmInputEntropy.Open(bInput: boolean): boolean;
begin
  FIsInput := bInput;

  if FIsInput then
  begin
    edtConfirm.Visible := false;
//    Label1.Visible     := false;
  end;

  Result := ShowModal = mrOK;
end;

end.
