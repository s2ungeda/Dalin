unit FAssetsMonitor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  UAccounts, UAssets, UApiTypes, Vcl.Grids
  ;

type
  TFrmAssetMonitor = class(TForm)
    Panel1: TPanel;
    edtCode: TEdit;
    sgKRW: TStringGrid;
    sgCoin: TStringGrid;
    mKRW: TMemo;
    Timer1: TTimer;
    mKRW2: TMemo;
    mCoin: TMemo;
    mCoin2: TMemo;
    CheckBox1: TCheckBox;
    Button1: TButton;
    ComboBox1: TComboBox;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FAccount : TAccount;
    FAsset   : TAsset;
    FExKind  : TExchangeKind;

    procedure DoLog(m:TMemo; stLog: string);

    procedure UpdateAssetCoin;
    procedure UpdateAssetKRW;
  public
    { Public declarations }

  end;

var
  FrmAssetMonitor: TFrmAssetMonitor;

implementation

uses
  GApp, GLibs
  ;

{$R *.dfm}

procedure TFrmAssetMonitor.Button1Click(Sender: TObject);
begin
  mKRW.Clear;
  mCoin.Clear;
  mKRW2.Clear;
  mCoin2.Clear;
end;

procedure TFrmAssetMonitor.Button2Click(Sender: TObject);
begin
  case ComboBox1.ItemIndex of
    0 : FExKind := ekUpbit;
    1 : FExKind := ekBithumb;
  end;

  FAccount  := App.Engine.TradeCore.FindAccount(FExKind);
  FAsset    := FAccount.Assets.Find(edtCode.Text);
end;

procedure TFrmAssetMonitor.CheckBox1Click(Sender: TObject);
begin
  Timer1.Enabled := Checkbox1.Checked;
end;

procedure TFrmAssetMonitor.ComboBox1Change(Sender: TObject);
begin
  //
end;

procedure TFrmAssetMonitor.DoLog(m: TMemo; stLog: string);
var
  i:Integer;
begin

  m.Lines.Insert(0, FormatDateTime('hh:nn:ss', now) + '  ' + stLog);

  if m.Lines.Count > 120 then
    while m.Lines.Count > 100 do
      m.Lines.Delete(m.Lines.Count-1);


end;

procedure TFrmAssetMonitor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmAssetMonitor.FormCreate(Sender: TObject);
begin
  FAccount := nil;
  FAsset   := nil;

  with sgCoin do
  begin
    Cells[1, 0] := 'Balance';
    Cells[2, 0] := 'Lock';
    Cells[3, 0] := 'Available';

    Cells[0, 1] := '자체';
    Cells[0, 2] := '패킷';
  end;

  with sgKRW do
  begin
    Cells[1, 0] := 'Balance';
    Cells[2, 0] := 'Lock';
    Cells[3, 0] := 'Available';

    Cells[0, 1] := '자체';
    Cells[0, 2] := '패킷';
  end;

end;

procedure TFrmAssetMonitor.Timer1Timer(Sender: TObject);
begin
  //
  UpdateAssetKRW;
  UpdateAssetCoin;
end;

procedure TFrmAssetMonitor.UpdateAssetCoin;
begin
  if FAsset = nil then Exit;

  with sgCoin do
  begin
    Cells[1, 1] := DoubleToStr(FAsset.Balance, 2);
    Cells[2, 1] := DoubleToStr(FAsset.Locked, 2);
    Cells[3, 1] := DoubleToStr(FAsset.Available, 2);

    DoLog(mCoin, Format('%s - B: %s, L: %s', [FAsset.Currency,
      DoubleToStr(FAsset.Balance, 2), DoubleToStr(FAsset.Locked, 2)]) );

    Cells[1, 2] := DoubleToStr(FAsset.Balance2, 2);
    Cells[2, 2] := DoubleToStr(FAsset.Locked2, 2);
    Cells[3, 2] := DoubleToStr(FAsset.Balance2 - FAsset.Locked2, 2);

    DoLog(mCoin2, Format('%s - B: %s, L: %s', [FAsset.Currency,
      DoubleToStr(FAsset.Balance2, 2), DoubleToStr(FAsset.Locked2, 2)]) );
  end;
end;

procedure TFrmAssetMonitor.UpdateAssetKRW;
var
  iPre: integer;
begin

  iPre  := 2;

  with sgKRW, FAccount do
  begin
    Cells[1, 1] := DoubleToStr(Asset.Balance, iPre);
    Cells[2, 1] := DoubleToStr(Asset.Locked, iPre);
    Cells[3, 1] := DoubleToStr(Asset.Available, iPre);

    DoLog(mKRW, Format('%s - B: %s, L: %s', [Asset.Currency,
      DoubleToStr(Asset.Balance, iPre), DoubleToStr(Asset.Locked, iPre)]) );

    Cells[1, 2] := DoubleToStr(Asset.Balance2, iPre);
    Cells[2, 2] := DoubleToStr(Asset.Locked2, iPre);
    Cells[3, 2] := DoubleToStr(Asset.Balance2 - Asset.Locked2, iPre);

    DoLog(mKRW2, Format('%s - B: %s, L: %s', [Asset.Currency,
      DoubleToStr(Asset.Balance2, iPre), DoubleToStr(Asset.Locked2, iPre)]) );
  end;
end;

end.
