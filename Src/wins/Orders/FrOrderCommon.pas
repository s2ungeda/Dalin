unit FrOrderCommon;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Mask, Vcl.ExtCtrls;

type
  TFrCommon = class(TFrame)
    GroupBox1: TGroupBox;
    dtLimitStart1: TDateTimePicker;
    dtLimitEnd1: TDateTimePicker;
    ckLimitTime1: TCheckBox;
    dtLimitStart2: TDateTimePicker;
    dtLimitEnd2: TDateTimePicker;
    ckLimitTime2: TCheckBox;
    dtLimitStart3: TDateTimePicker;
    dtLimitEnd3: TDateTimePicker;
    ckLimitTime3: TCheckBox;
    GroupBox2: TGroupBox;
    edtMoveAvgPeriod: TLabeledEdit;
    edtExDisparity: TLabeledEdit;
    Label1: TLabel;
    Label2: TLabel;
    GroupBox3: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    edtFutOrdTick: TLabeledEdit;
    edtSpotOrdTick: TLabeledEdit;
    procedure edtExDisparityKeyPress(Sender: TObject; var Key: Char);
    procedure edtMoveAvgPeriodKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TFrCommon.edtExDisparityKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key in ['0'..'9',#8]) then
    Key := #0;
end;

procedure TFrCommon.edtMoveAvgPeriodKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key in ['0'..'9',#8]) then
    Key := #0;
end;

end.
