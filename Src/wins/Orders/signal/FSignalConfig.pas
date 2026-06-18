unit FSignalConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,

  UTypes, USignalTypes

  ;

type

  TFindStgName = function (const s : string): boolean of Object;

  TFrmSignalConfig = class(TForm)
    GroupBox1: TGroupBox;
    edtOrderQtyF: TLabeledEdit;
    GroupBox2: TGroupBox;
    edtOrderQtyS: TLabeledEdit;
    edtTradeTotQty: TLabeledEdit;
    cbMethod: TComboBox;
    btnOK: TButton;
    btnClose: TButton;
    edtStgCode: TLabeledEdit;
    ckManualInput: TCheckBox;
    edtmanualinput: TEdit;
    ckEntryBaseKip: TCheckBox;
    ckExitBaseKip: TCheckBox;
    edtEntryBaseKip: TEdit;
    edtExitBaseKip: TEdit;
    edtVolRateS: TLabeledEdit;
    Label2: TLabel;
    edtVolRateF: TLabeledEdit;
    Label4: TLabel;
    Label5: TLabel;
    edtHogaRateS: TLabeledEdit;
    Label6: TLabel;
    edtHogaRateF: TLabeledEdit;
    Label7: TLabel;
    Label8: TLabel;
    ckDiffClear: TCheckBox;
    edtKipAdjust: TLabeledEdit;
    procedure edtDelayFKeyPress(Sender: TObject; var Key: Char);
    procedure btnOKClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FConfig: TSignalConfig;
    FBaseKip: array [TAutoOrderType] of double;
    FFindStgName: TFindStgName;
    { Private declarations }
    function ChkecBaseKip : boolean;
  public
    { Public declarations }
    function Open(const aCfg: TSignalConfig) : boolean;
    property Config : TSignalConfig read FConfig;

    property FindStgName : TFindStgName read FFindStgName write FFindStgName;
  end;

var
  FrmSignalConfig: TFrmSignalConfig;

implementation

uses
  GApp, GLibs
  ;

{$R *.dfm}

procedure TFrmSignalConfig.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmSignalConfig.btnOKClick(Sender: TObject);
var
  bRes : boolean;
  iErr: integer;
  dDelay : array [TMethodType] of double;
  dMin   : double;
begin

  bRes := false;
  try
    with FConfig do
    begin
      iErr := 0;

      dDelay[mtF] := 0;
      dDelay[mtS] := 0;   dMin := 0;

//      if not TryStrToFloat(edtDelayF.Text, dDelay[mtF]) then Exit;
      if not TryStrToFloat(edtOrderQtyF.Text, Input[mtF].OrderQty) then Exit;
      if not TryStrToInt(edtVolRateF.Text, Input[mtF].VolRate) then Exit;

//      if not TryStrToFloat(edtDelayS.Text, dDelay[mtS]) then Exit;
      if not TryStrToFloat(edtOrderQtyS.Text, Input[mtS].OrderQty) then Exit;
      if not TryStrToInt(edtVolRateS.Text, Input[mtS].VolRate) then Exit;

      if not TryStrToFloat(edtTradeTotQty.Text, TradeTotQty) then Exit;
      if TradeTotQty <= 0 then Exit;

      Method    := cbMethod.ItemIndex ;

      if not TryStrToFloat(edtKipAdjust.Text, KipAdjust) then Exit;

//      if not TryStrToInt(edtDelayKipMin.Text, DelayKipMin) then Exit;
//      if not TryStrToFloat(edtDelayKip.Text, DelayKip) then Exit;

      //if (Input[mtF].Delay < 0) or (Input[mtS].Delay < 0) then
      if (dDelay[mtF] < 0) or (dDelay[mtS] < 0) then
      begin
        iErr := 1;
        Exit;
      end;

//      Input[mtF].Delay  := Round(dDelay[mtF]* 1000);
//      Input[mtS].Delay  := Round(dDelay[mtS]* 1000);

      if (Input[mtF].VolRate <= 0) or (Input[mtS].VolRate <= 0) then
      begin
        iErr := 3;
        Exit;
      end;

//      if (DelayKipMin < 0) then
//      begin
//        iErr := 2;
//        Exit;
//      end;

      if Assigned(FFindStgName) then
        if FFindStgName(edtStgCode.Text) then
        begin
          iErr := 10;
          Exit;
        end;

      StgCode := edtStgCode.Text;

      if not ChkecBaseKip then
      begin
        iErr := 4;
        Exit;
      end;

      bRes := true;
    end;
  finally
    if not bRes then
    begin
      var s : string;
      case iErr of
        1  : s := '딜레이는 0 이상 입력';
        2  : s := '지연KIP(분) 은 0 이상';
        3  : s := '잔량비는 0 보다 커야 함';
        4  : s := '청산, 진입 BaseKip 차이가 너무 낮음';
        10 : s := '전략코드 중복';
        else s := '입력값이 잘못 됨';
      end;
      ShowMessageAtCursor(s, TMsgDlgType.mtWarning, [mbOK]);
      ModalResult := mrNone;
    end;
  end;

  if bRes then
    ModalResult := mrOK;

end;

function TFrmSignalConfig.ChkecBaseKip: boolean;
var
  d1, d2 : double;
begin
  Result := false;
  // all 체크

  if ckEntryBaseKip.Checked and ckExitBaseKip.Checked then
  begin
    if not tryStrToFloat(edtEntryBaseKip.Text, d1) then Exit;
    if not tryStrToFloat(edtExitBaseKip.Text, d2) then Exit;
  end
  // 진입만 체크
  else if ckEntryBaseKip.Checked and not ckExitBaseKip.Checked then
  begin
    if not tryStrToFloat(edtEntryBaseKip.Text, d1) then Exit;
    d2 := FBaseKip[aoExit];
  end
  // 청산만 체크.
  else if not ckEntryBaseKip.Checked and ckExitBaseKip.Checked then
  begin
    d1 := FBaseKip[aoEntry];
    if not tryStrToFloat(edtExitBaseKip.Text, d2) then Exit;
  end else Exit (true);

  if (d1 > d2) or (abs(d1 - d2) < gAOConfig.Result.MinKipGap) then Exit;

  Result := true;
end;

procedure TFrmSignalConfig.edtDelayFKeyPress(Sender: TObject; var Key: Char);
begin
  if not (CharInSet(Key , ['-','0'..'9','.',#8])) then
    Key := #0;
end;

procedure TFrmSignalConfig.FormCreate(Sender: TObject);
begin
//{$IFDEF DEBUG}
  Label8.Visible    := true;
  cbMethod.Visible  := true;
//{$ENDIF}
end;

function TFrmSignalConfig.Open(const aCfg: TSignalConfig): boolean;
begin
  //
  with aCfg do
  begin
    edtStgCode.Text   := StgCode;

//    edtDelayF.Text    := (Input[mtF].Delay / 1000).ToString;
    edtOrderQtyF.Text := Input[mtF].OrderQty.ToString;
    edtVolRateF.Text  := Input[mtF].VolRate.ToString;

//    edtDelayS.Text    := (Input[mtS].Delay / 1000).ToString;
    edtOrderQtyS.Text := Input[mtS].OrderQty.ToString;
    edtVolRateS.Text  := Input[mtS].VolRate.ToString;

    edtKipAdjust.Text   := KipAdjust.ToString;
    cbMethod.ItemIndex  := Method;
    edtTradeTotQty.Text := TradeTotQty.ToString;

//    edtDelayKipMin.Text := DelayKipMin.ToString;
//    edtDelayKip.Text    := DelayKip.ToString;
    FBaseKip[aoEntry] := BaseKip[aoEntry];
    FBaseKip[aoExit]  := BaseKip[aoExit];

  end;

  Result := ShowModal = mrOK;
end;

end.
