unit FNSConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,

  UNS1Items

  ;

type
  TFrmNSConfig = class(TForm)
    edtStartHoga: TLabeledEdit;
    Button1: TButton;
    Button2: TButton;
    edtOrderQty: TLabeledEdit;
    edtTick: TLabeledEdit;
    edtCount: TLabeledEdit;
    edtLimitHoga: TLabeledEdit;
    cbLimitHoga: TCheckBox;
    GroupBox1: TGroupBox;
    edtModCnt: TLabeledEdit;
    edtRemainVol: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure edtOrderQtyKeyPress(Sender: TObject; var Key: Char);
  private
    FParam: TNS1Param;
    { Private declarations }
  public
    { Public declarations }
    function Open( const aParam : TNS1Param) : boolean;

    property Param : TNS1Param read FParam;
  end;

var
  FrmNSConfig: TFrmNSConfig;

implementation

uses
  System.UITypes
  ;

{$R *.dfm}

procedure TFrmNSConfig.Button1Click(Sender: TObject);
var
  i, i2, i3, i4, i5 : integer;
  d1 : double;
begin

  if( edtOrderQty.Text = '' ) or ( edtCount.Text = '') or ( edtTick.Text = '' ) or
    (edtStartHoga.Text = '' ) or (edtModCnt.Text = '') or (edtLimitHoga.Text = '') then
  begin
    ShowMessagePos('설정값 입력', Left, Top);
    ModalResult := mrNone;
    Exit;
  end;

  if (not TryStrToInt(edtCount.Text, i)) or
     (not TryStrToInt(edtTick.Text, i2)) or
     (not TryStrToInt(edtStartHoga.Text, i3)) or
     (not TryStrToInt(edtModCnt.Text, i4)) or
     (not TryStrToInt(edtLimitHoga.Text, i5)) or
     (not TryStrToFloat(edtRemainVol.Text, d1))
     then
  begin
    ShowMessagePos('설정값 잘못 입력', Left, Top);
    ModalResult := mrNone;
    Exit;
  end;

  if (i3 <= 0) or ( i3 > 5) then
  begin
    ShowMessagePos('시작호가는 (1~5) 사이 입력', Left, Top);
    ModalResult := mrNone;
    Exit;
  end;

  if i <= 0 then
  begin
    ShowMessagePos('갯수는 0 보다 커야 함', Left, Top);
    ModalResult := mrNone;
    Exit;
  end;

  FParam.SetParm(edtOrderQty.Text, i3, i2, i, i4, i5, d1, cbLimitHoga.Checked);

  ModalResult := mrOK;
end;

procedure TFrmNSConfig.Button2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmNSConfig.edtOrderQtyKeyPress(Sender: TObject; var Key: Char);
begin
  if not (CharInSet(Key , ['0'..'9','.',#8])) then
    Key := #0;
end;

function TFrmNSConfig.Open( const aParam : TNS1Param): boolean;
begin
  edtOrderQty.Text  := aParam.orderQty_s;
  edtCount.Text     := aParam.count.ToString;
  edtTick.Text      := aParam.tick.ToString;
  edtStartHoga.Text := aParam.startHoga.ToString;

  edtLimitHoga.Text := aParam.limitHoga.ToString;
  edtModCnt.Text    := aParam.modCnt.ToString;

  cbLimitHoga.Checked := aParam.useLimitHoga;
  edtRemainVol.Text := aParam.modForVol.ToString;

  FParam.Assign(aParam);

  Result := ShowModal = mrOK;
end;

end.
