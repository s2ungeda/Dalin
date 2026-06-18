unit FMarginType;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls

  , UPositions

  ;

type
  TFrmPosConfig = class(TForm)
    g1: TGroupBox;
    rbIsolated: TRadioButton;
    rbCross: TRadioButton;
    g2: TGroupBox;
    edtLeverage: TLabeledEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private

    { Private declarations }
  public
    { Public declarations }
    Position : TPosition;
    function Open(aPos: TPosition; iDiv : integer): boolean;
  end;

var
  FrmPosConfig: TFrmPosConfig;

implementation

uses
  GApp
  , UApiTypes
  , System.Threading
  ;

{$R *.dfm}


procedure TFrmPosConfig.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmPosConfig.btnOKClick(Sender: TObject);
var
  bRes : boolean;
  sRes : string;
begin

  bRes := false;

  if g1.Visible then begin
    var stType : string;

    if rbIsolated.Checked then
      stType := 'ISOLATED'
    else
      stType := 'CROSSED';

    if Position.Isolated <> rbIsolated.Checked then

    sRes := '';
    bRes := App.Engine.ApiManager.ExManagers[ekBinance].Exchanges[Position.Symbol.Spec.ExApiType].RequestChangeMarginType(
          Position.Symbol.OrgCode, stType, sRes );

    if bRes then
      Position.Isolated :=  rbIsolated.Checked
    else
      ShowMessage( sRes );
  end
  else if g2.Visible then
  begin

    bRes := App.Engine.ApiManager.ExManagers[ekBinance].Exchanges[Position.Symbol.Spec.ExApiType].RequestChangeLeverage(
          Position.Symbol.OrgCode, edtLeverage.Text );
    if bRes then
      Position.Leverage := StrToInt( edtLeverage.Text );
  end;

  ModalResult := mrOK;
end;

procedure TFrmPosConfig.FormCreate(Sender: TObject);
begin
  Position := nil;

  g1.Visible := false;
  g2.Visible := false;
end;

procedure TFrmPosConfig.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    btnOKClick( btnOK )
  else if key = VK_ESCAPE then
    btnCancelClick( btnCancel );
end;

function TFrmPosConfig.Open(aPos: TPosition; iDiv : integer): boolean;
var
  gb : TGroupBox;
begin

  Position := aPos;

  edtLeverage.Text  := IntToStr( Position.Leverage );
  if Position.Isolated then
    rbIsolated.Checked := true
  else
    rbCross.Checked := true;

  if iDiv = 1 then
    gb  := g1
  else
    gb  := g2;

  gb.Left := 8;
  gb.Top  := 8;
  gb.Visible := true;

  Result :=  (ShowModal = mrOK);
end;

end.
