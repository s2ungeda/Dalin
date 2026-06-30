unit FTotalBalance;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,

  UAccounts, UAssets, UPositions, USymbols, UDistributor, UStorage,

  UApiConsts, UApiTypes, UTypes, UDecimalHelper,

  URestItems, URestThread, Vcl.Buttons, Vcl.Menus

  ;

const

  CW = 130;
  TW = 85;

  ww : array [0..14] of integer = (
    90, CW, CW, TW, CW,
    TW, CW, TW, CW, 90,
    90, 90, 90, TW, CW
  );

  tt : array [0..14] of string = (
    {'해외합($/원)'}'Est-Balance', '0', '0', '국내KRW', '0',
    '국내코인',     '0', '국내총합', '0', 'KIP(해/국)',
    '0', '국내진입', '0', '해외+국내', '0'
  );

  tbs : array [0..2] of string = ('환율','바이낸S','Est Balance');
  bbs : array [0..2] of string = ('자산','수량','평가금액');

  tbf : array [0..3] of string = ('바이낸F','Wallet Balance','Unreal-PL','유지증거금');
  bbf : array [0..3] of string = ('종목명','수량','mark price','평가손익');

  tbfc : array [0..3] of string = ('바이낸F','보유BTC','Unreal-PL','Margin');
  bbfc_p : array [0..3] of string = ('종목명','수량','체결차','평가금액(원화)');
//  bbfc_p_2 : array [0..3] of string = ('종목명','수량','Balance','평가금액');
  bbfc_A : array [0..3] of string = ('자산','수량','I.Margin','Unreal-PL');

  tub : array [0..3] of string = ('Upbit','보유KRW','코인평가','총합산');
  bub : array [0..3] of string = ('자산','수량','현재가','평가금액');

  ASSET_COL = 0;

type

  TFrmTotalBalance = class(TForm)
    Panel1: TPanel;
    sgBbt: TStringGrid;
    sgBbs: TStringGrid;
    sgBup: TStringGrid;
    sgBbf: TStringGrid;
    StatusBar1: TStatusBar;
    Panel3: TPanel;
    sgTbs: TStringGrid;
    sgTbf: TStringGrid;
    sgTup: TStringGrid;
    sgTbt: TStringGrid;
    Timer1: TTimer;
    Timer2: TTimer;
    sgBbfc: TStringGrid;
    sgTbfc: TStringGrid;
    PopupMenu1: TPopupMenu;
    BinnaceSpot1: TMenuItem;
    BinanceFuturesUSDM1: TMenuItem;
    BinanceFuturesCOINM1: TMenuItem;
    Upbit1: TMenuItem;
    Bithumb1: TMenuItem;
    PopupMenu2: TPopupMenu;
    Assets1: TMenuItem;
    Positions1: TMenuItem;
    PopupMenu3: TPopupMenu;
    ppAsset: TMenuItem;
    ppPosGap: TMenuItem;
    Panel2: TPanel;
    sgTot: TStringGrid;
    Button1: TButton;
    btnSaveCSV: TButton;
    Bevel1: TBevel;
    dlgSave: TSaveDialog;
    puUpbit: TPopupMenu;
    puBithumb: TPopupMenu;
    puUpbitLast: TMenuItem;
    N2: TMenuItem;
    puBithumbLast: TMenuItem;
    N3: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure sgTotDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure sgTbsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

    procedure UpdateBithumb( bUpdate : boolean = true);
    procedure UpdateUpbit( bUpdate : boolean = true);
    procedure UpdateBinanceSpot( bUpdate : boolean = true);
    procedure UpdateBinanceFut( bUpdate : boolean = true);
    procedure UpdateBinanceFutCm( bUpdate : boolean = true);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure BinnaceSpot1Click(Sender: TObject);
    procedure Assets1Click(Sender: TObject);
    procedure ppAssetClick(Sender: TObject);
    procedure sgBbfMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgBbsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MarkPrice1Click(Sender: TObject);
    procedure MultiAssetBalance1Click(Sender: TObject);
    procedure btnSaveCSVClick(Sender: TObject);
    procedure puUpbitLastClick(Sender: TObject);
    procedure puBithumbLastClick(Sender: TObject);

  private

    FAccounts : array [TExchangeKind] of TAccount;
    FAccount  : TAccount;           // 바이낸스 선물
    FAccountCm: TAccount;

    FAssets   : array [TExchangeKind] of TList;
    FAssetFut : TList;
    FAssetCm  : TList;
    FPositions: array [TFuturesType] of TList;

    FRestThread : TRestThread;

    dBin : array [0..2] of double;
    dKor : array [0..1] of double;
    dtot : array [0..1] of double;

    FCol, FRow : array [0..4] of integer;

    FCount  : integer;

    { Private declarations }
    procedure ChangeTitle;

    procedure SetGridWidth( aGrid : TStringGrid );
    procedure SetGridWidth2(aGrid : TStringGrid );
    procedure SetGridWidth3(aGrid: TStringGrid);

    function GetPosVolSum(aPos: TPosition): string;
    function IsAcntsNull : boolean;
    procedure ClearGrid(sg: TStringGrid);

    procedure UpdateTotalBalance;

    procedure UpdateTopGridBinan(aExApiType: TExchangeApiType);
    procedure UpdateTopGridKr(ekKind: TExchangeKind; aGrid: TStringGrid);

    procedure UpdateBottomGridKr(ekKind: TExchangeKind; aGrid: TStringGrid);
    procedure UpdateBottomGridBinanSpot;
    procedure UpdateBottomGridBinanFut;

    procedure ReSizeGridColWidth(exKind : TExchangeKind; aGrid: TStringGrid); overload;
    procedure ReSizeGridColWidth(aExApiType: TExchangeApiType; aGrid: TStringGrid); overload;
    procedure SetAssets(exKind: TExchangeKind; aGrid: TStringGrid);
    procedure RSize;
    procedure UpdateBottomGridBinanFutCm;
    procedure ChangeTitle2;

  public
    { Public declarations }
//    FColWidth : integer;
    procedure ResponseNotify(aItem : TBalanceRequestItem );
    procedure LoadEnv( aStorage : TStorage );
    procedure SaveEnv( aStorage : TStorage );
  end;

var
  FrmTotalBalance: TFrmTotalBalance;

  function CompareOpenAmt(Data1,Data2: Pointer): Integer;
  function CompareOpenAmt2(Data1,Data2: Pointer): Integer;

implementation

uses
  GApp, GLibs, UConsts
  , System.Math
  , REST.Types
  , Clipbrd
  ;

{$R *.dfm}

function CompareOpenAmt(Data1,Data2: Pointer): Integer;
var
  asset1: TAsset absolute Data1;
  asset2: TAsset absolute Data2;
begin

  if asset1.OpenAmt < asset2.OpenAmt then
    Result := 1
  else if asset1.OpenAmt > asset2.OpenAmt  then
    Result := -1
  else
    Result := 0;
end;

function CompareOpenAmt2(Data1,Data2: Pointer): Integer;
var
  aPos1: TPosition absolute Data1;
  aPos2: TPosition absolute Data2;
begin

  if aPos1.EntryOTE < aPos2.EntryOTE then
    Result := 1
  else if aPos1.EntryOTE > aPos2.EntryOTE  then
    Result := -1
  else
    Result := 0;
end;

function CompareBalance(Data1,Data2: Pointer): Integer;
var
  asset1: TAsset absolute Data1;
  asset2: TAsset absolute Data2;
begin

  if asset1.Balance < asset2.Balance then
    Result := 1
  else if asset1.Balance > asset2.Balance  then
    Result := -1
  else
    Result := 0;
end;


procedure TFrmTotalBalance.RSize;
  var
    iLeft : integer;

//  function W(sg : TStringGrid) : integer;
//  begin
//    Result := 0;
//    if sg.Visible then
//    begin
//      Result := sg.Width;
//      inc(iCnt, 4);
//    end;
//  end;

  procedure L(sg1, sg2 : TStringGrid);
  begin
    if sg1.Visible then begin
      sg1.Left  := iLeft;
      sg2.Left  := iLeft;
      inc(iLeft, sg1.Width);
    end;
  end;

begin

  iLeft  := 0;
  L(sgTbs,sgBbs);L(sgTbf,sgBbf);L(sgTbfc,sgBbfc);L(sgTup,sgBup);L(sgTbt,sgBbt);
  Width  := iLeft + 16;

end;

procedure TFrmTotalBalance.Assets1Click(Sender: TObject);
begin
  UpdateBinanceFutCm;
  ChangeTitle;
end;

procedure TFrmTotalBalance.BinnaceSpot1Click(Sender: TObject);
var
  bCheck: boolean;
  sgT, sgB : TStringGrid;
begin

  bCheck  := TMenuItem(Sender).Checked;

  case TComponent(Sender).Tag of
    0 : begin sgT := sgTbs;  sgB := sgBbs; end;
    1 : begin sgT := sgTbf;  sgB := sgBbf; end;
    2 : begin sgT := sgTbfc; sgB := sgBbfc; end;
    3 : begin sgT := sgTup;  sgB := sgBup; end;
    4 : begin sgT := sgTbt;  sgB := sgBbt; end;
  end;

  sgT.Visible := bCheck;
  sgB.Visible := bCheck;

  RSize;
end;

procedure TFrmTotalBalance.btnSaveCSVClick(Sender: TObject);
var
  sFileName: string;
begin

  dlgSave.FileName := Format('%s_TotalBalance', [FormatDateTime('yyyy-mm-dd', now)]);
  if dlgSave.Execute(Self.Handle) then
    SaveToCSVFile(sgTot, dlgSave.FileName);
end;

procedure TFrmTotalBalance.Button1Click(Sender: TObject);
var
  aItem : TBalanceRequestItem;
  j: TExchangeKind;
begin

  Button1.Enabled := false;

  for j := ekBinance to High(TExchangeKind) do
  begin
    aItem := TBalanceRequestItem.Create;
    aItem.ExKind := j;
    FRestThread.PushQueue( aItem );
  end;

end;

procedure TFrmTotalBalance.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmTotalBalance.FormCreate(Sender: TObject);
var
  I: Integer;
  j: TExchangeKind;
  aInfo : TDivInfo;
  aRect : TRect;
begin

  for j := ekBinance to High(TExchangeKind) do
  begin
//    if j = ekBinance then
//      FAccounts[j]  := App.Engine.TradeCore.FindAccount(j, amFuture)
//    else
      FAccounts[j]  := App.Engine.TradeCore.FindAccount(j);

    FAssets[j]  := TList.Create;
  end;

  FAssetFut := TList.Create;
  FAssetCm  := TList.Create;

  FAccount := App.Engine.TradeCore.FindAccount(ekBinance, amFuture);
  FAccountCm := App.Engine.TradeCore.FindAccount(ekBinance, amFutureCm);
  FPositions[ftUsdt]:= TList.Create;
  FPositions[ftCoin]:= TList.Create;

  for i := 0 to 1 do
  begin
   dBin[i] := 0;
   dKor[i] := 0;
   dtot[i] := 0;
  end;
  dBin[2] := 0;

  SetGridWidth(sgBbs);
  SetGridWidth(sgTbs);

  SetGridWidth2(sgTbf);
  SetGridWidth2(sgTUp);
  SetGridWidth2(sgTBt);

  SetGridWidth2(sgBbf);
  SetGridWidth2(sgBup);
  SetGridWidth2(sgBbt);

  // 바이낸스 선물 COIN-M
  SetGridWidth3(sgTbfc);
  SetGridWidth3(sgBbfc);

  for I := 0 to sgTot.ColCount-1 do begin
    sgTot.Colwidths[i] := ww[i];
    sgTot.Cells[i,0]   := tt[i];
  end;

  for I := 0 to sgBbs.ColCount-1 do begin
    sgTbs.Cells[i,0] := tbs[i];
    sgBbs.Cells[i,0] := bbs[i];
  end;

  for I := 0 to sgBup.ColCount-1 do begin
    sgTbf.Cells[i,0] := tbf[i];
    sgTUp.Cells[i,0] := tub[i];
    if i = 0 then
      sgTBt.Cells[i,0] := '빗썸'
    else
      sgTBt.Cells[i,0] := tub[i];

    sgBbf.Cells[i,0] := bbf[i];
    sgBup.Cells[i,0] := bub[i];
    sgBbt.Cells[i,0] := bub[i];

    sgTbfc.Cells[i,0]:= tbfc[i];
    sgBbfc.Cells[i,0]:= bbfc_P[i];
  end;

  sgTbf.Cells[0,1]  := 'USDⓢ-M';
  sgTbfc.Cells[0,1] := 'COIN-M';

  UpdateBithumb;
  UpdateUpbit;
  UpdateBinanceSpot;
  UpdateBinanceFut;
  UpdateBinanceFutCm;

  // 그냥 임의로 만든다. 별 의미 없다.
  aInfo.Kind  := ekUpbit;
  aInfo.Market:= mtSpot;
  aInfo.Index := 0;
  aInfo.WaitTime  := 500;  // <-- 스레드 주기를 10ms

  FCount  := 0;

  FRestThread := TRestThread.Create(aInfo);
  FRestThread.OnResNotify := ResponseNotify;

  dlgSave.InitialDir  := App.DataDir;

  Caption := Caption +  Format(' [ 해외는 %d 초 에 한번씩 자동 조회 됨, 국내는 수동조회]', [
    TExThreadTimeout[ekBinance] div 1000]);
end;

procedure TFrmTotalBalance.FormDestroy(Sender: TObject);
var
  j: TExchangeKind;
  i: TFuturesType;
begin

  FRestThread.Terminate;
  FRestThread.WaitFor;
  FreeAndNil(FRestThread);

  FAssetCm.Free;
  FAssetFut.Free;

  for j := ekBinance to High(TExchangeKind) do
    FAssets[j].Free;

  for i := ftUsdt to High(TFuturesType) do
    FPositions[i].Free;
end;

function TFrmTotalBalance.GetPosVolSum(aPos: TPosition): string;
var
  aAss: TAsset;
  dSum : double;
  I: TExchangeKind;
begin
  //  국내 잔고들을 더한다.
//  App.Engine.TradeCore.fin
  dSum := aPos.Volume;
  for I := ekUpbit to High(TExchangeKind) do
  begin
    aAss  := FAccounts[i].Assets.Find(aPos.Symbol.Spec.BaseCode);
    if aAss = nil then continue;
    dSum := dSum + aAss.Balance;
  end;

  // 체결차는 4자리
  Result  := Format('%.4n', [dSum]);
//  Result  := DoubleToStr(dSum);
end;

function TFrmTotalBalance.IsAcntsNull: boolean;
var
  j: TExchangeKind;
begin
  for j := ekBinance to High(TExchangeKind) do
    if FAccounts[j] = nil then Exit (false);

  Result := true;
end;




{
tbs : array [0..2] of string = ('바이낸S','보유$','코인평가');
bbs : array [0..2] of string = ('종목명','수량','평가금액');

tbf : array [0..3] of string = ('바이낸F','보유$','코인평가','유지증거금');
bbf : array [0..3] of string = ('종목명','수량','mark pr.','');

tub : array [0..3] of string = ('','보유KRW','코인평가','총합산');
bub : array [0..3] of string = ('종목명','수량','현재가','평가금액');
}


procedure TFrmTotalBalance.SetGridWidth( aGrid : TStringGrid );
begin
  with aGrid do
  begin
    Colwidths[0] := 70;
    Colwidths[1] := 150;
    Colwidths[2] := CW;

    Width := Colwidths[0] + Colwidths[1] + Colwidths[2] + 7;
  end;
end;

procedure TFrmTotalBalance.SetGridWidth2( aGrid : TStringGrid );
begin

  with aGrid do
  begin
    Colwidths[0] := 70;
    Colwidths[1] := 150;//CW;
    Colwidths[2] := 120;
    Colwidths[3] := CW;

    Width := Colwidths[0] + Colwidths[1] + Colwidths[2] + Colwidths[3] + 8;
  end
end;

procedure TFrmTotalBalance.SetGridWidth3( aGrid : TStringGrid );
begin

  with aGrid do
  begin
    Colwidths[0] := 110;
    Colwidths[1] := 110;//CW;
    Colwidths[2] := 120;
    Colwidths[3] := CW;

    Width := Colwidths[0] + Colwidths[1] + Colwidths[2] + Colwidths[3] + 8;
  end
end;

procedure TFrmTotalBalance.sgBbfMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    iTag : integer;
begin
  iTag  := TStringGrid(Sender).Tag;
  TStringGrid(Sender).MouseToCell(X,Y, FCol[iTag], FRow[iTag]);

  TStringGrid(Sender).Invalidate;


end;

procedure TFrmTotalBalance.sgBbsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    iTag : integer;
begin

  iTag := TStringGrid(Sender).Tag;
  if (FCol[iTAg] < 0) or (FRow[iTag] < 0) then Exit;

  if (Key = Ord('C')) and (ssCtrl in Shift) then
    Clipboard.AsText := (Sender as TStringGrid).Cells[FCol[iTAg], FRow[iTag]];
end;

procedure TFrmTotalBalance.sgTbsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
  	aRect : TRect;
    aFont, aBack : TColor;
    dFormat	: WORD;
    stTxt	: string;
begin

  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;

	with Sender as TStringGrid do
  begin
  	stTxt := Cells[ ACol, ARow];

    if ARow = 0 then begin
      if Tag in [1..4] then begin
        aBack := clGray;
        aFont := clWhite;
      end
      else
        aBack := clSilver;
    end
    else begin
      if ACol <> 0 then
        dFormat := DT_RIGHT;

      if (ACol = FCol[Tag]) and (ARow = FRow[Tag]) and (RowCount > 3) then
        aBack := LONG_COLOR;
    end;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;
    aRect.Top := Rect.Top + 2;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );

  end;

end;

procedure TFrmTotalBalance.sgTotDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
  	aRect : TRect;
    aFont, aBack : TColor;
    dFormat	: WORD;
    stTxt	: string;
begin
  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;

	with sgTot do
  begin
  	stTxt := Cells[ ACol, ARow];

    case ACol of
      0,3,5,7,9,11,13 : aBack := clBtnFace;
      1,2,4,6,8,10,12,14 : dFormat := DT_RIGHT;
    end;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;
    aRect.Top := Rect.Top + 2;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );
  end;

end;

procedure TFrmTotalBalance.Timer1Timer(Sender: TObject);
begin
  //
  try
    if FCount > 60 then
    begin
      FCount := 0;
      if BinnaceSpot1.Checked then UpdateBinanceSpot;
      if BinanceFuturesUSDM1.Checked then UpdateBinanceFut;
      if BinanceFuturesCOINM1.Checked then UpdateBinanceFutCm;
      if Upbit1.Checked then UpdateUpbit;
      if Bithumb1.Checked then UpdateBithumb;
    end;

    sgTbs.Cells[0,1]  := Format('%.2n', [App.Engine.ApiManager.ExRate.GetExRate] );

    if BinnaceSpot1.Checked then UpdateBinanceSpot(false);
    if BinanceFuturesUSDM1.Checked then UpdateBinanceFut(false);
    if BinanceFuturesCOINM1.Checked then UpdateBinanceFutCm(false);
    if Upbit1.Checked then UpdateUpbit(false);
    if Bithumb1.Checked then UpdateBithumb(false);

    UpdateTotalBalance;
  finally
    inc(FCount);
  end;
end;



procedure TFrmTotalBalance.Timer2Timer(Sender: TObject);
begin
  if not Button1.Enabled then
    Button1.Enabled := true;
end;

procedure TFrmTotalBalance.ChangeTitle;
var
  i : integer;
begin
  with sgBbfc do
    for I := 0 to High(bbfc_p) do
      Cells[i,0]  := ifThenStr( Positions1.Checked, bbfc_P[i], bbfc_A[i] );


  if Positions1.Checked then begin
    SetGridWidth3(sgBbfc);
    SetGridWidth3(sgTbfc);
  end
  else begin
    SetGridWidth2(sgBbfc);
    SetGridWidth2(sgTbfc);
  end;
end;

procedure TFrmTotalBalance.ChangeTitle2;
var
  i : integer;
begin
  with sgBbf do
    for I := 0 to High(bbfc_P) do
      if ppPosGap.Checked then
        Cells[i,0] := bbfc_p[i]
      else
        Cells[i,0] := bbfc_A[i];

  if not ppAsset.Checked then begin
    SetGridWidth3(sgBbf);
    SetGridWidth3(sgTbf);
  end
  else begin
    SetGridWidth2(sgBbf);
    SetGridWidth2(sgTbf);
  end;
end;

procedure TFrmTotalBalance.ClearGrid( sg : TStringGrid );
var
  I: Integer;
begin
  for I := 1 to sg.RowCount-1 do
    sg.Rows[i].Clear;
end;



procedure TFrmTotalBalance.UpdateTotalBalance;
var
  d, d1, d2 : double;
  dSum, dTmp : double;
begin
  with sgTot do
  begin

    dSum  := dbin[0] + dBin[1] + dBin[2] ;
    // 해외합($/원)
    Cells[1,0]  := FmtString(0, dSum );
    dTmp  := dSum * App.Engine.ApiManager.ExRate.GetExRate;
    Cells[2,0]  := FmtString(0, dTmp );

    d1 := 0;  d2 := 0;
    if FAccounts[ekUpbit].Asset <> nil then d1 :=  FAccounts[ekUpbit].Asset.Balance;
    if FAccounts[ekBithumb].Asset <> nil then d2 :=  FAccounts[ekBithumb].Asset.Balance;

    // 국내 KRW
    Cells[4,0]  := FmtString(0, d1 + d2);
    // 국내 코인
    Cells[6,0]  := FmtString(0, dKor[0] + dKor[1]);
    // 국내 총 합산
    Cells[8,0]  := FmtString(0, d1 + d2 + dKor[0] + dKor[1]);
    // 해외/국내
    //d := CalcDiv(dTmp, dTmp + d1 + d2 + dKor[0] + dKor[1]) * 100;
    // spot 은 제외하고.
    d := CalcDiv(dBin[1] * App.Engine.ApiManager.ExRate.GetExRate, d1 + d2 + dKor[0] + dKor[1]) * 100;
    Cells[10,0] := FmtString(2, d)+'%';
    // 국내 진입
    d := CalcDiv(dKor[0] + dKor[1], d1+d2+dKor[0]+dKor[1] ) * 100;
    Cells[12,0] := FmtString(2, d)+'%';
    // 해외+국내
    Cells[14,0] := FmtString(0, dTmp + d1 + d2 + dKor[0] + dKor[1] );

  end;
end;

procedure TFrmTotalBalance.UpdateTopGridKr( ekKind : TExchangeKind; aGrid : TStringGrid );
var
  dTotCoin, dBal : double;
begin
  if FAccounts[ekKind] = nil then Exit;

  dTotCoin  := FAccounts[ekKind].Assets.GetTotalCoin;

  if FAccounts[ekKind].Asset = nil then
    dBal := 0
  else
    dBal  :=  FAccounts[ekKind].Asset.Balance;

  with aGrid do
  begin
    Cells[1,1]  := Format('%.0n', [ dBal ] );
    Cells[2,1]  := Format('%.0n', [ dTotCoin ] );
    Cells[3,1]  := Format('%.0n', [ dBal + dTotCoin ] );

    dKor[ integer(ekKind)-1]  := dTotCoin;
  end;
end;


procedure TFrmTotalBalance.UpdateBottomGridKr( ekKind : TExchangeKind; aGrid : TStringGrid );
var
  i, iRow : integer;
  aAsset  : TAsset;
  bLast   : boolean;
  dPrice  : double;
begin

  case ekKind of
    ekBinance: Exit;
    ekUpbit: bLast := puUpbitLast.Checked;
    ekBithumb: bLast := puBithumbLast.Checked;
  end;

  with aGrid do
    if bLast then
    begin
      Cells[2, 0] := '현재가';
      Cells[3, 0] := '평가금액';
    end else
    begin
      Cells[2, 0] := '평균가';
      Cells[3, 0] := '평가손익';
    end;

  iRow := 1;

  with aGrid do
    for I := 0 to FAssets[ekKind].Count-1 do
    begin
      aAsset  := TAsset( FAssets[ekKind].Items[i] );
//      Objects[ASSET_COL, i+1] := aAsset;
      if FAccounts[ekKind].Asset = aAsset then Continue;

      Cells[0, iRow] := UpperCase(aAsset.Currency);
      Cells[1, iRow] := DoubleToStr(aAsset.Balance) ;

      // 국내는 종목이 하나뿐이기에.
      if bLast then begin
        if aAsset.Symbol <> nil then
          Cells[2, iRow] := aAsset.Symbol.PriceToStr(aAsset.Symbol.Last)
        else
          Cells[2, iRow] := '0';
        Cells[3, iRow] := Format('%.0n', [ aAsset.OpenAmt ]);
      end else
      begin
        if aAsset.Symbol <> nil then
          Cells[2, iRow] := aAsset.Symbol.PriceToStr(aAsset.AvgPrice)
        else
          Cells[2, iRow] := DoubleToStr(aAsset.AvgPrice, 2);
        Cells[3, iRow] := Format('%.0n', [ aAsset.OpenAmt - aAsset.EntryAmt]);
      end;


      inc(iRow);
    end;
end;


// 조회 버튼 눌렀을때 처리

procedure TFrmTotalBalance.UpdateTopGridBinan( aExApiType: TExchangeApiType );
var
  dTotCoin : double;
  bInt : TDecimalHelper;
begin

  if aExApiType = eaFutUsdt then
  begin
    if FAccount = nil then Exit;

    dTotCoin  := App.Engine.TradeCore.Positions[ekBinance].GetOpenPL(FAccount);

    with sgTbf do
    begin
//      멀티에셋으로 바꿔달라함.
//      다시 월렛 발란스로 바꿔달라함..
      Cells[1,1]  := Format('%.0n', [ FAccount.TotWalletBalance] );
      Cells[2,1]  := Format('%.0n', [ dTotCoin ] );
      Cells[3,1]  := Format('%.0n', [ FAccount.Asset.MainMargin ] );
    end;

    dBin[1] := FAccount.TotWalletBalance + dTotCoin;
  end else
  if aExApiType = eaFutCoin then
  begin
    if FAccountCm = nil then Exit;
    dTotCoin  := App.Engine.TradeCore.Positions[ekBinance].GetOpenPL(FAccountCm, 'BTC');
    with sgTbfc do
    begin
      Cells[1,1]  := DoubleToStr(FAccountCm.Asset.Balance); // Format('%.4n', [ FAccountCm.Asset.Balance ] );
      Cells[2,1]  := DoubleToStr(dTotCoin);  //Format('%.4n', [ dTotCoin ] );
      Cells[3,1]  := DoubleToStr(FAccountCm.Asset.MainMargin);  //Format('%.4n', [ FAccountCm.Asset.MainMargin ] );
    end ;

    dBin[2] := FAccountCm.TotWalletBalance + dTotCoin;
  end else
  begin

    if FAccounts[ekBinance] = nil then Exit;
    dTotCoin  := FAccounts[ekBinance].Assets.GetTotalCoin;

    with sgTbs do
    begin
      if FAccounts[ekBinance].Asset = nil then
        Cells[1,1]  := '0'
      else
        Cells[1,1]  := Format('%.0n', [FAccounts[ekBinance].Asset.Balance ] );
      Cells[2,1]  := Format('%.0n', [ dTotCoin ] );
    end;

    dBin[0] := dTotCoin;
  end;
end;

procedure TFrmTotalBalance.UpdateBottomGridBinanSpot;
var
  i, iRow : integer;
  aAsset  : TAsset;
  bInit   : TDecimalHelper;
begin

  iRow := 1;

  with sgBbs do
    for I := 0 to FAssets[ekBinance].Count-1 do
    begin
      aAsset  := TAsset( FAssets[ekBinance].Items[i] );
//      Objects[ASSET_COL, i+1] := aAsset;
      if FAccounts[ekBinance].Asset = aAsset then Continue;

      Cells[0, iRow] := UpperCase(aAsset.Currency);
      //bInit.convert(aAsset.Balance);
      Cells[1, iRow] :=  DoubleToStr(aAsset.Balance);// Format('%.*n', [ bInit.Precision, aAsset.Balance ]);
      //Cells[1, iRow] := aAsset.Symbol.QtyToStr( aAsset.Balance );
      if aAsset.Symbol <> nil then
        Cells[2, iRow] := Format('%.0n', [ aAsset.Balance * aAsset.Symbol.Last])
      else
        Cells[2, iRow] := '0';

      inc(iRow);
    end;
end ;


procedure TFrmTotalBalance.UpdateBottomGridBinanFut;
var
  I: integer;
  aPos : TPosition;
  aAss : TAsset;
  dTotCoin : double;
  scType : TSettleCurType;
begin
  with  sgBbf do
    if not ppAsset.Checked then
    begin

      for I := 0 to FPositions[ftUsdt].Count-1 do
      begin
        aPos  := TPosition( FPositions[ftUsdt].Items[i] );
        Cells[0, i+1] := Uppercase( aPos.Symbol.OrgCode );
        Cells[1, i+1] := aPos.Symbol.QtyToStr( aPos.Volume );
        //Cells[2, i+1] := Format('%.2n', [ abs(aPos.Volume * (aPos.Symbol as TFuture).MarkPrice) ] )  ;
        Cells[2, i+1] := GetPosVolSum(aPos);
        //Cells[3, i+1] := Format('%.2n', [ aPos.EntryOTE ] )  ;
        Cells[3, i+1] := Format('%.0n', [aPos.Volume * (aPos.Symbol as TFuture).MarkPrice
          * App.Engine.ApiManager.ExRate.GetExRate]) ;
      end;

    end else
    begin
      for I := 0 to FAssetFut.Count-1 do
      begin
        aAss  := TAsset( FAssetFut.Items[i] );
        Cells[0, i+1] := Uppercase( aAss.Currency);
        Cells[1, i+1] := DoubleToStr(aAss.Balance, 2);
        //Cells[2, i+1] := Format('%.2n', [ abs(aPos.Volume * (aPos.Symbol as TFuture).MarkPrice) ] )  ;

        Cells[2, i+1] := DoubleToStr(aAss.InitMargin, 2);

        scType := GetSettleType(aAss.Currency);
        dTotCoin  := App.Engine.TradeCore.Positions[ekBinance].GetOpenPL(FAccount, scType);
        Cells[3, i+1] := Format('%.2n', [ dTotCoin] );
      end;
    end;
end;


procedure TFrmTotalBalance.UpdateBottomGridBinanFutCm;
var
  I: integer;
  aPos : TPosition;
  aAss : TAsset;
  dTotCoin : double;
  scType : TSettleCurType;
begin
  with  sgBbfc do
    if Positions1.Checked then
    begin
      for I := 0 to FPositions[ftCoin].Count-1 do
      begin
        aPos  := TPosition( FPositions[ftCoin].Items[i] );
        Cells[0, i+1] := Uppercase( aPos.Symbol.OrgCode );
        Cells[1, i+1] := DoubleToStr(aPos.Volume);
        //Cells[2, i+1] := Format('%.2n', [ abs(aPos.Volume * (aPos.Symbol as TFuture).MarkPrice) ] )  ;
        Cells[2, i+1] := aPos.Symbol.PriceToStr((aPos.Symbol as TFuture).MarkPrice);
        //Cells[3, i+1] := bInt.DoubleToStr(aPos.EntryOTE)  ;
        Cells[3, i+1] := Format('%.0n', [aPos.Volume * (aPos.Symbol as TFuture).MarkPrice])  ;
      end;
    end else
    begin

      for I := 0 to FAssetCm.Count-1 do
      begin
        aAss  := TAsset( FAssetCm.Items[i] );
        Cells[0, i+1] := Uppercase( aAss.Currency);
        Cells[1, i+1] := DoubleToStr(aAss.Balance, 2);

        Cells[2, i+1] := DoubleToStr(aAss.InitMargin, 2);
        scType := GetSettleType(aAss.Currency);
        dTotCoin  := App.Engine.TradeCore.Positions[ekBinance].GetOpenPL(FAccount, scType);
        Cells[3, i+1] := Format('%.2n', [ dTotCoin] );
      end;
    end;
end;


procedure TFrmTotalBalance.UpdateBinanceFut(bUpdate : boolean);
var
  I: Integer;
begin
  if FAccount = nil then Exit;

  UpdateTopGridBinan(eaFutUsdt);

  if bUpdate then
  begin
    ClearGrid(sgBbf);
    if not ppAsset.Checked then
    begin
      FPositions[ftUsdt].Clear;

      for I := 0 to App.Engine.TradeCore.Positions[ekBinance].Count-1 do
        if App.Engine.TradeCore.Positions[ekBinance].Positions[i] <> nil then
          if App.Engine.TradeCore.Positions[ekBinance].Positions[i].Account = FAccount then
            if not CheckZero( App.Engine.TradeCore.Positions[ekBinance].Positions[i].Volume ) then
              FPositions[ftUsdt].Add(App.Engine.TradeCore.Positions[ekBinance].Positions[i]);

      if FPositions[ftUsdt].Count > 0 then
        FPositions[ftUsdt].Sort(CompareOpenAmt2);
    end else
    begin
      FAssetFut.Clear;
      for I := 0 to FAccount.Assets.Count-1 do
        if FAccount.Assets.Assets[i] <> nil then
          if not CheckZero( FAccount.Assets.Assets[i].Balance ) then
            FAssetFut.Add(FAccount.Assets.Assets[i]);

      if FAssetFut.Count > 0 then
        FAssetFut.Sort(CompareBalance);
    end;

    ReSizeGridColWidth(eaFutUsdt, sgBbf);
  end;

  UpdateBottomGridBinanFut;

end;

procedure TFrmTotalBalance.UpdateBinanceFutCm(bUpdate : boolean);
var
  i : integer;
begin
  if FAccountCm = nil then Exit;
  UpdateTopGridBinan(eaFutCoin);

  if bUpdate then
  begin
    ClearGrid(sgBbfc);
    if Positions1.Checked then
    begin
      FPositions[ftCoin].Clear;

      for I := 0 to App.Engine.TradeCore.Positions[ekBinance].Count-1 do
        if App.Engine.TradeCore.Positions[ekBinance].Positions[i] <> nil then
          if App.Engine.TradeCore.Positions[ekBinance].Positions[i].Account = FAccountCm then
            if not CheckZero( App.Engine.TradeCore.Positions[ekBinance].Positions[i].Volume ) then
              FPositions[ftCoin].Add(App.Engine.TradeCore.Positions[ekBinance].Positions[i]);

      if FPositions[ftCoin].Count > 0 then
        FPositions[ftCoin].Sort(CompareOpenAmt2);
    end else
    begin
      FAssetCm.Clear;

      for I := 0 to FAccountCm.Assets.Count-1 do
        if FAccountCm.Assets.Assets[i] <> nil then
          if not CheckZero( FAccountCm.Assets.Assets[i].Balance ) then
            FAssetCm.Add(FAccountCm.Assets.Assets[i]);

      if FAssetCm.Count > 0 then
        FAssetCm.Sort(CompareBalance);
    end;
    ReSizeGridColWidth(eaFutCoin, sgBbfc);
  end;

  UpdateBottomGridBinanFutCm;

end;

procedure TFrmTotalBalance.UpdateBinanceSpot(bUpdate : boolean);
begin
  if FAccounts[ekBinance] = nil then Exit;

  UpdateTopGridBinan(eaSpot);

  if bUpdate then SetAssets(ekBinance, sgBbs);

  UpdateBottomGridBinanSpot;//(ekBinance, sgBbs);
end;

procedure TFrmTotalBalance.UpdateUpbit(bUpdate : boolean);
begin
  // sgTbt, sgBbt
  if FAccounts[ekUpbit] = nil then Exit;

  UpdateTopGridKr(ekUpbit, sgTup);

  if bUpdate then SetAssets(ekUpbit, sgBup);

  UpdateBottomGridKr(ekUpbit, sgBup);
end;

procedure TFrmTotalBalance.UpdateBithumb(bUpdate : boolean);
begin
  // sgTbt, sgBbt
  if FAccounts[ekBithumb] = nil then Exit;

  UpdateTopGridKr(ekBithumb, sgTbt);

  if bUpdate then SetAssets(ekBithumb, sgBbt);

  UpdateBottomGridKr(ekBithumb, sgBbt);

end;

procedure TFrmTotalBalance.LoadEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  BinnaceSpot1.Checked  := aStorage.FieldByName('ShowBinanSpot').AsBooleanDef(true);
  BinanceFuturesUSDM1.Checked := aStorage.FieldByName('ShowBinanFut').AsBooleanDef(true);
  BinanceFuturesCOINM1.Checked:= aStorage.FieldByName('ShowBinanFutCmt').AsBooleanDef(false);
  Upbit1.Checked  := aStorage.FieldByName('ShowUpbit').AsBooleanDef(true);
  Bithumb1.Checked:= aStorage.FieldByName('ShowBithumb').AsBooleanDef(true);

  sgTbs.Visible := BinnaceSpot1.Checked;
  sgBbs.Visible := BinnaceSpot1.Checked;
  sgTbf.Visible := BinanceFuturesUSDM1.Checked;
  sgBbf.Visible := BinanceFuturesUSDM1.Checked;

  sgTbfc.Visible := BinanceFuturesCOINM1.Checked;
  sgBbfc.Visible := BinanceFuturesCOINM1.Checked;

  sgTup.Visible := Upbit1.Checked;
  sgBup.Visible := Upbit1.Checked;

  sgTBt.Visible := Bithumb1.Checked;
  sgBbt.Visible := Bithumb1.Checked;

  Positions1.Checked  := aStorage.FieldByName('ShowPosition').AsBooleanDef(true);
  Assets1.Checked := not Positions1.Checked;

  ppAsset.Checked   := aStorage.FieldByName('ShowAsset').AsBoolean;
  ppPosGap.Checked  := not ppAsset.Checked;

  Assets1Click(nil);

  ChangeTitle2;
end;

procedure TFrmTotalBalance.MarkPrice1Click(Sender: TObject);
begin
  //
  UpdateBinanceFut;
  ChangeTitle2;
end;

procedure TFrmTotalBalance.ppAssetClick(Sender: TObject);
var
  I, iSum: Integer;
begin
  iSum := 0;
  for I := 0 to PopupMenu3.Items.Count - 1 do
    if PopupMenu3.Items[I].Checked then
      inc(iSum);
  if iSum = 0 then
    (Sender as TMenuItem).Checked := True;
  //
  UpdateBinanceFut;
  ChangeTitle2;
end;

procedure TFrmTotalBalance.puBithumbLastClick(Sender: TObject);
var
  I, iSum: Integer;
begin
  iSum := 0;
  for I := 0 to puBithumb.Items.Count - 1 do
    if puBithumb.Items[I].Checked then
      inc(iSum);
  if iSum = 0 then
    (Sender as TMenuItem).Checked := True;

  // 빗썸 현재가, 평균가
  UpdateBottomGridKr(ekBithumb, sgBbt);
end;

procedure TFrmTotalBalance.puUpbitLastClick(Sender: TObject);
var
  I, iSum: Integer;
begin
  iSum := 0;
  for I := 0 to puUpbit.Items.Count - 1 do
    if puUpbit.Items[I].Checked then
      inc(iSum);
  if iSum = 0 then
    (Sender as TMenuItem).Checked := True;
  // 업비트 현재가, 평균가
  UpdateBottomGridKr(ekUpbit, sgBup);
end;

procedure TFrmTotalBalance.MultiAssetBalance1Click(Sender: TObject);
begin
  UpdateTopGridBinan(eaFutUsdt);
end;

procedure TFrmTotalBalance.SaveEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  aStorage.FieldByName('ShowBinanSpot').AsBoolean  := BinnaceSpot1.Checked;
  aStorage.FieldByName('ShowBinanFut').AsBoolean  := BinanceFuturesUSDM1.Checked;
  aStorage.FieldByName('ShowBinanFutCmt').AsBoolean  := BinanceFuturesCOINM1.Checked;
  aStorage.FieldByName('ShowUpbit').AsBoolean  := Upbit1.Checked;
  aStorage.FieldByName('ShowBithumb').AsBoolean  := Bithumb1.Checked;

  aStorage.FieldByName('ShowAsset').AsBoolean   := ppAsset.Checked;

  aStorage.FieldByName('ShowPosition').AsBoolean  := Positions1.Checked;
end;

procedure TFrmTotalBalance.SetAssets( exKind : TExchangeKind; aGrid: TStringGrid );
var
  i : integer;
begin
  ClearGrid(aGrid);
  FAssets[exKind].Clear;

  for I := 0 to FAccounts[exKind].Assets.Count-1 do
    if FAccounts[exKind].Assets.Assets[i] <> FAccounts[exKind].Asset then
      if not CheckZero(FAccounts[exKind].Assets.Assets[i].Balance) then
        FAssets[exKind].Add(FAccounts[exKind].Assets.Assets[i]);

  if FAssets[exKind].Count > 0 then
    FAssets[exKind].Sort(CompareOpenAmt);

  ReSizeGridColWidth(exKind, aGrid);
end;

procedure TFrmTotalBalance.ReSizeGridColWidth( exKind : TExchangeKind; aGrid : TStringGrid );
var
  i : integer;
begin

  i := FAssets[exKind].Count - 5;
  if i >= 1 then begin
    aGrid.RowCount := 6 + i;
    aGrid.ColWidths[aGrid.ColCount-1] := CW - 18;
  end
  else begin
    aGrid.RowCount := 6;
    aGrid.ColWidths[aGrid.ColCount-1] := CW;
  end;

end;

procedure TFrmTotalBalance.ReSizeGridColWidth(aExApiType: TExchangeApiType;
  aGrid: TStringGrid);
  var
    iCnt : integer;
begin
  case aExApiType of
    eaSpot: Exit;
    eaFutUsdt: iCnt := FPositions[ftUsdt].Count-5;
    eaFutCoin:
      if Positions1.Checked then
        iCnt  := FPositions[ftCoin].Count-5
      else
        iCnt  := FAssetCm.Count-5;
  end;

  if iCnt >= 1 then begin
    aGrid.RowCount := aGrid.RowCount + iCnt;
    aGrid.ColWidths[aGrid.ColCount-1] := CW - 18;
  end
  else begin
    aGrid.RowCount := 6;
    aGrid.ColWidths[aGrid.ColCount-1] := CW;
  end;
end;

procedure TFrmTotalBalance.ResponseNotify(aItem: TBalanceRequestItem);
begin
  if aItem.Result then
    case aItem.ExKind of
      ekBinance : begin UpdateBinanceSpot; UpdateBinanceFut; UpdateBinanceFutCm; end;
      ekUpbit   : UpdateUpbit;
      ekBithumb : UpdateBithumb;
    end;
end;

end.

