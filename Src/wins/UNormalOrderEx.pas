unit UNormalOrderEx;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask , System.Generics.Collections

  , UApiTypes, UApiConsts, UTypes

  , USymbols, UOrders, UAccounts, UPositions, UAssets

  , UDistributor, UStorage

  ;

const
  AskRow = 7;

type
  TFrmNormalOrderEx = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    cbReduce: TCheckBox;
    sgHoga: TStringGrid;
    Button1: TButton;
    btnQueryOrder: TButton;
    Timer1: TTimer;
    Button3: TButton;
    Button4: TButton;
    edtEstPrice: TLabeledEdit;
    cbTest: TButton;
    stBar: TStatusBar;
    lbmin: TLabel;
    Button5: TButton;
    cbPostOnly: TCheckBox;
    lbTest: TLabel;
    lbTest2: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    edtLimitBuy: TEdit;
    edtLImitSell: TEdit;
    Button2: TButton;
    Button6: TButton;
    Panel3: TPanel;
    lbDepth: TLabel;
    rgPrice: TRadioGroup;
    edtQty: TLabeledEdit;
    edtPrice: TLabeledEdit;
    cbExKind: TComboBox;
    edtCode: TEdit;
    rbBuy: TRadioButton;
    rbSell: TRadioButton;
    cbMarket: TComboBox;
    edtTick: TEdit;
    UpDown1: TUpDown;
    cbSettle: TComboBox;
    Panel4: TPanel;
    sgBal: TStringGrid;
    sgPos: TStringGrid;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    Button7: TButton;
    btnOrder: TSpeedButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    procedure rbSellClick(Sender: TObject);
    procedure rbBuyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOrderClick(Sender: TObject);
    procedure cbExKindChange(Sender: TObject);
    procedure edtCodeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure sgHogaDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure sgHogaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnQueryOrderClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);

    procedure cbTestClick(Sender: TObject);
    procedure sgBalSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure edtPriceKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtPriceKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure rgPriceClick(Sender: TObject);
    procedure UpDown1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure edtTickChange(Sender: TObject);
    procedure DispPrice;
    procedure Button5Click(Sender: TObject);
    procedure SetLimitPrice(aSymbol : TSymbol);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure sgPosDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
  private
    FExKind : TExchangeKind;
    FAccMarket : TAccountMarketType;
    FSCType    : TSettleCurType;
    FSymbol : TSymbol;
    FAccount: TAccount;
    FPosition : TPosition;
    FAsset    : TAsset;

    FOrders   : TList<TOrder>;

    FCol, FRow : integer;

    procedure initControls;
    procedure DoPosition(aPos: TPosition);
    procedure DoAccountUpdate(aAcnt : TAccount);
    procedure DoAsset(aAsset : TAsset );
    procedure DoAlert(aOrder : TOrder; bSuccess : boolean);
    procedure UpdateAssets;
    procedure UpdatePosition;
    procedure ClearBalGrid( aGrid : TStringGrid );
    procedure SetOrderObjects;
    procedure SetAccMarkets;
    procedure SetSymbol;

    function  SetPrice( dPrice : double ) : string;
    function  GetExApiType : TExchangeApiType;
    procedure CalcCostNMax;
    procedure UpdateControls;
    procedure UpdateTest;
    function CalcMaxQuantity(iSide: integer): double;
    function CalcMaxQuantity2(iSide: integer): double;
    function CalcCost(iSide: integer; dQty: double): double;
    function CalcMaxQuantity3(iSide: integer): double;
    function GetAvailable: double;
    procedure OnOrder(aOrder: TOrder; iEventID: integer);
    function GetCaption: string;

    { Private declarations }
  public
    { Public declarations }
    procedure QuoteProc(Sender, Receiver: TObject; DataID: Integer;
      DataObj: TObject; EventID: TDistributorID);
    procedure TradeProc(Sender, Receiver: TObject; DataID: Integer;
      DataObj: TObject; EventID: TDistributorID);

    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );
  end;

var
  FrmNormalOrderEx: TFrmNormalOrderEx;

implementation

uses
  GApp, GLibs
  , UConsts
  , UDecimalHelper
  , UQuoteBroker
  , USymbolCore
  , Math

  ;

{$R *.dfm}

procedure TFrmNormalOrderEx.btnOrderClick(Sender: TObject);
var
  iSide : integer;
  dOrderQty, dPrice : double;
  aOrder  : TOrder;
  aTIF    : TTimeInForce;

begin

  if (edtQty.Text = '') or ( edtPrice.Text = '') then
  begin
    ShowMessageAtCursor('필수항목 입력',TMsgDlgType.mtError, [mbOK]);
    Exit;
  end;

  iSide := 0;
  if rbBuy.Checked then iSide := 1;
  if rbSell.Checked then iSide := -1;

  if ( not TryStrToFloat( edtPrice.Text, dPrice ))
    or ( not TryStrToFloat( edtqty.Text, dOrderQty )) then
  begin
    ShowMessageAtCursor('주문가격 or 수량이 잘못 됨',TMsgDlgType.mtError, [mbOK]);
    Exit;
  end;

  if not App.Engine.TradeCore.CheckLimitOrder( FAccount, FSymbol, iSide, dPrice, dOrderQty, ORD_NORMAL) then
  begin
    ShowMessageAtCursor('주문 제한에 걸림',TMsgDlgType.mtError, [mbOK]);
    Exit;
  end;

  if cbPostOnly.Visible and cbPostOnly.Checked then
    aTIF := tmGTX
  else
    aTIF := tmGTC;

  // 주문가격, 수량, 방향, 현재가, 거래소타입
  aOrder  := App.Engine.TradeCore.Orders[FExKind].NewOrder( FAccount, FSymbol,
    iSide, edtQty.Text , pcLimit, edtPrice.Text, aTIF );

  if aOrder <> nil then
  begin
    aOrder.ReduceOnly := cbReduce.Checked;
    App.Engine.TradeBroker.Send( aOrder );
  end;
end;

procedure TFrmNormalOrderEx.Button1Click(Sender: TObject);
begin
//
end;

procedure TFrmNormalOrderEx.btnQueryOrderClick(Sender: TObject);
begin
	//
  if FSymbol <> nil then
		App.Engine.ApiManager.ExManagers[FExKind].RequestOrderList( FSymbol );
end;

procedure TFrmNormalOrderEx.Button3Click(Sender: TObject);
begin
  if FSymbol <> nil then
		App.Engine.ApiManager.ExManagers[FExKind].RequestTradeAmt( FSymbol );
end;

procedure TFrmNormalOrderEx.Button4Click(Sender: TObject);
begin
  if ( FExKind = ekBinance ) and ( GetExApiType <> eaSpot ) and ( FSymbol <> nil ) then
    App.Engine.ApiManager.ExManagers[FExKind].RequestPosition( FSymbol );
end;

procedure TFrmNormalOrderEx.Button5Click(Sender: TObject);
var
  sKey : string;
  iSide, iTag, I: Integer;
  aOrder, cOrder, nOrder: TOrder;
  bFind : boolean;
  aTIF    : TTimeInForce;
  dPrice : double;
begin

  if (FSymbol = nil) or (FAccount = nil) then
  begin
    ShowMessage('종목선택 먼저');
    Exit;
  end;

  if edtPrice.Text = '' then
  begin
    ShowMessage('종목선택 먼저');
    edtPrice.SetFocus;
    Exit;
  end;


  iTag := (Sender as TButton).Tag;

  for I := 0 to App.Engine.TradeCore.Orders[FExKind].ActiveOrders.Count-1 do
  begin
    aOrder  := App.Engine.TradeCore.Orders[FExKind].ActiveOrders.Orders[i];
    if (aOrder <> nil) and (aOrder.Symbol = FSymbol) then
    begin
      bFind := true;
      break;
    end;
  end;

  if not bFind then
  begin
    ShowMessage('종목선택 먼저');
    Exit;
  end;

  iSide := 0;
  if rbBuy.Checked then iSide := 1;
  if rbSell.Checked then iSide := -1;

  if cbPostOnly.Visible and cbPostOnly.Checked then
    aTIF := tmGTX
  else
    aTIF := tmGTC;

//  dPrice  := StrToFloatDef(edtPrice.Text, 0);
//  if dPrice < EPSILON then Exit;
//  case iSide of
//    1 : dPrice :=TicksFromPrice( FSymbol, dPrice, -1 );
//    -1: dPrice :=TicksFromPrice( FSymbol, dPrice, 1 );
//    else Exit;
//  end;
//  edtPrice.Text := FmtString( GetPrecision( FSymbol, dPrice ), dPrice , 1 );

  nOrder  := App.Engine.TradeCore.Orders[FExKind].NewOrder( FAccount, FSymbol,
      iSide, edtQty.Text , pcLimit, edtPrice.Text, aTIF );

  cOrder  := App.Engine.TradeCore.Orders[FExKind].NewCancelOrder(aOrder, aOrder.ActiveQty);

  if iTag >= 0 then begin
    // 신규 취소
    App.Engine.TradeBroker.Send(nOrder);
    App.Engine.TradeBroker.Send(cOrder);
  end else
  begin
    // 취소 신규..
    App.Engine.TradeBroker.Send(cOrder);
    App.Engine.TradeBroker.Send(nOrder);
  end;


end;

procedure TFrmNormalOrderEx.Button6Click(Sender: TObject);
var
  i : integer;
begin
  for I := 0 to 20-1 do
    btnOrderClick(nil);
end;

procedure TFrmNormalOrderEx.Button7Click(Sender: TObject);
begin
  SetSymbol;
end;

function TFrmNormalOrderEx.GetCaption: string;
begin
  Result := '-';

  if FSymbol = nil then Exit;

  case FSymbol.Spec.ExchangeType of
    ekBinance : begin
      case GetSettleType(FSymbol.Spec.SettleCode) of
        scUSDT : Result := FSymbol.Spec.BaseCode+'-DT';
        scUSDC : Result := FSymbol.Spec.BaseCode+'-DC';
      end;
    end
    else
      Result := FSymbol.Spec.BaseCode;
  end;
end;

procedure TFrmNormalOrderEx.UpdateControls;
begin
  //
  btnOrder.Caption  := Format('%s %s', [GetCaption, ifThenStr(rbBuy.Checked, '매수', '매도')]);
end;


procedure TFrmNormalOrderEx.cbExKindChange(Sender: TObject);
begin
  SetAccMarkets;
end;

procedure TFrmNormalOrderEx.cbTestClick(Sender: TObject);
var
  I, iSide : Integer;
  dPrice, dOrderQty : double;
  aOrder : TOrder;
  stTmp : string;
begin
  iSide := 0;
  if rbBuy.Checked then iSide := 1;
  if rbSell.Checked then iSide := -1;

  if ( not TryStrToFloat( edtPrice.Text, dPrice ))
    or ( not TryStrToFloat( edtqty.Text, dOrderQty )) then
  begin
    ShowMessage( '주문가격 or 수량이 잘못 됨 ');
    Exit;
  end;

//  for I := 0 to 12345 do
//  begin
//    stTmp := (i+1).ToString;
//    aOrder  := App.Engine.TradeCore.Orders[FExKind].NewOrder( FAccount, FSymbol,
//      iSide, stTmp , pcLimit, edtPrice.Text, tmGTC );
//    aOrder.Cancel(dOrderQty);
//  end;
end;

procedure TFrmNormalOrderEx.SetOrderObjects;
var
  aPosition : TPosition;
  aAsset : TAsset;
begin
  if( FSymbol = nil )  or ( FAccount = nil ) then
    Exit;

  if (FSymbol.Spec.Market <> mtSpot) then
  begin
    aPosition := App.Engine.TradeCore.FindPosition( FAccount, FSymbol );

    if (aPosition <> FPosition) or (aPosition = nil) then begin
      ClearBalGrid(sgPos);
      ClearBalGrid(sgBal);
      FPosition := aPosition;
    end;

    case FSCType of
      scUSDT: FAsset := FAccount.Asset;
      scUSDC: FAsset := FAccount.DCAss;
      else FAsset := nil;
    end;

    UpdatePosition;
  end else
  begin
    // 해외 spot 은 BTCUSDT, BTCUSDC, ..  settle code 별로 존재
    // FSCType : scUSDT, scUSDC, scKRW  중에 하나.
    aAsset  := FAccount.Assets.Find(FSymbol.Spec.BaseCode);
    if (aAsset <> FAsset) or (aAsset = nil) then
    begin
      ClearBalGrid(sgPos);
      ClearBalGrid(sgBal);
      FAsset := aAsset;
    end;

    FPosition := nil;
    UpdateAssets;
  end;

  if FExKind = ekBinance then
  begin
    lbMin.Caption := '최소수량 : ' + FSymbol.QtyToStr( FSymbol.Spec.QtySize) ;//

    if cbMarket.ItemIndex = 2 then
      lbMin.Caption :=  lbMin.Caption + ' , Contract Size : ' + FSymbol.Spec.ContractSize.ToString
    else
      lbMin.Caption :=  lbMin.Caption + ' , 최소금액 : ' + FSymbol.Spec.MinNotional.ToString;

    SetLimitPrice(FSymbol);

  end else
    lbMin.Caption := '';
end;

function TFrmNormalOrderEx.SetPrice(dPrice: double): string;
var
  i : integer;
begin
  if (not TryStrToInt(edtTick.Text, i )) or (FSymbol = nil) then Exit ('');

  if rgPrice.ItemIndex = 0 then
  begin
    if rbBuy.Checked then
      dPrice  := TicksFromPrice( FSymbol, dPrice, i )
    else
      dPrice  := TicksFromPrice( FSymbol, dPrice, -i );
  end;

  Result:= FmtString( GetPrecision( FSymbol, dPrice ), dPrice , 1 );
end;

procedure TFrmNormalOrderEx.SetSymbol;
var
  aAccount: Taccount;
  aSymbol : Tsymbol;
  sText   : string;
begin

  sText := edtCode.Text;

  if sText.IsEmpty then Exit;

  aAccount    := App.Engine.TradeCore.FindAccount(
    TExchangeKind( cbExKind.ItemIndex ), TAccountMarketType( cbMarket.ItemIndex +1 ));

  if aAccount = nil then
  begin
    ShowMessageAtCursor('계좌 없음', TMsgDlgType.mtWarning, [mbOK]);
    Exit;
  end;

  FAccount    := aAccount;
  FExKind     := TExchangeKind(cbExKind.ItemIndex);
  FAccMarket  := TAccountMarketType(cbMarket.ItemIndex + 1);

  case FExKind of
    ekBinance: case cbSettle.ItemIndex of
                 0 : FSCType := scUSDT;
                 1 : FSCType := scUSDC;
               end;
    else FSCType := scKRW;
  end;

  aSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( sText, FExKind, GetExApiType, FSCType);
  if aSymbol = nil then begin
    ShowMessageAtCursor('종목을 찾을 수 없음', TMsgDlgType.mtWarning, [mbOK]);
    Exit;
  end;

  if FSymbol <> nil then
    App.Engine.QuoteBroker.Brokers[FSymbol.Spec.ExchangeType].Cancel(Self, FSymbol);
  if aSymbol <> nil then
    App.Engine.QuoteBroker.Brokers[FExKind].Subscribe( Self, aSymbol, QuoteProc);

  initGrid(sgHoga, false );
  edtQty.Text := '';

  FSymbol     := aSymbol;

  SetOrderObjects;

  Button4Click(nil);

  UpdateControls;
end;

procedure TFrmNormalOrderEx.SetAccMarkets;
begin
  cbMarket.Clear;
  cbSettle.Clear;
  case TExchangeKind( cbExKind.ItemIndex ) of
    ekBinance:
      begin
        cbMarket.Items.Add('Spot');
        cbMarket.Items.Add('USDⓢ-M');
        cbMarket.Items.Add('COIN-M');
        cbMarket.ItemIndex := 1;

        cbSettle.Items.Add('DT');
        cbSettle.Items.Add('DC');
        cbSettle.ItemIndex := 0;

        sgPos.Cells[0,2]  := 'Liq. Prc';
//        sgPos.Cells[0,3]  := 'Leverge';

        CheckBox3.Visible := true;
        CheckBox4.Visible := true;
      end;
    ekBithumb, ekUpbit:
      begin
        cbMarket.Items.Add('Spot');
        cbMarket.ItemIndex := 0;

        cbSettle.Items.Add('KRW');
        cbSettle.ItemIndex := 0;

        sgPos.Rows[2].Clear;
//        sgPos.Rows[3].Clear;

        CheckBox3.Visible := false;
        CheckBox4.Visible := false;
      end;
  end;
//  if cbMarket.Items.Count > 0 then
//    cbMarketChange(nil);
end;

procedure TFrmNormalOrderEx.SetLimitPrice(aSymbol: TSymbol);
begin
  if aSymbol = nil then Exit;
  if aSymbol.Spec.Market = mtFutures then
  begin
    edtLImitBuy.Text  := aSymbol.PriceToStr(aSymbol.GetLimitOrderPrice(true));
    edtLImitSell.Text  := aSymbol.PriceToStr(aSymbol.GetLimitOrderPrice(false));
  end;

end;

procedure TFrmNormalOrderEx.ClearBalGrid( aGrid : TStringGrid );
var
  I: Integer;
begin

  with aGrid do
    for I := 0 to RowCount-1 do
      Cells[1, i]	:= '';
end;

procedure TFrmNormalOrderEx.edtCodeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    SetSymbol;
end;

procedure TFrmNormalOrderEx.edtPriceKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key in [VK_DOWN, VK_UP] then
    Key := 0;
end;

procedure TFrmNormalOrderEx.edtPriceKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    dPrice : double;
begin
  if (rgPrice.ItemIndex = 1) and (FSymbol <> nil) then
  begin
    dPrice  := StrToFloatDef(edtPrice.Text, 0);
    if dPrice < EPSILON then Exit;
    case Key of
      VK_DOWN : dPrice :=TicksFromPrice( FSymbol, dPrice, -1 );
      VK_UP   : dPrice :=TicksFromPrice( FSymbol, dPrice, 1 );
      else Exit;
    end;
    edtPrice.Text := FmtString( GetPrecision( FSymbol, dPrice ), dPrice , 1 );
  end;

  //edtPrice.ReadOnly := false;
end;

procedure TFrmNormalOrderEx.edtTickChange(Sender: TObject);
begin
  DispPrice;
end;

procedure TFrmNormalOrderEx.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmNormalOrderEx.FormCreate(Sender: TObject);
begin
  initControls;

  FSymbol 	:= nil;
  FPosition	:= nil;
  FAsset    := nil;

  FOrders   := TList<TOrder>.Create;


  App.Engine.TradeBroker.Subscribe( Self, TradeProc );
end;

procedure TFrmNormalOrderEx.FormDestroy(Sender: TObject);
begin
  //
  App.Engine.QuoteBroker.Cancel(Self );
  App.Engine.TradeBroker.Unsubscribe( Self );

  FOrders.free;
end;

function TFrmNormalOrderEx.GetExApiType: TExchangeApiType;
begin
  Result := TExchangeApiType( cbMarket.ItemIndex );
end;

procedure TFrmNormalOrderEx.rbBuyClick(Sender: TObject);
begin
  UpdateControls;
  btnOrder.Font.Color := clRed;
end;

procedure TFrmNormalOrderEx.rbSellClick(Sender: TObject);
begin
  UpdateControls;
  btnOrder.Font.Color := clBlue;
end;


procedure TFrmNormalOrderEx.rgPriceClick(Sender: TObject);
begin
  edtTick.Visible := rgPrice.ItemIndex = 0;
  Updown1.Visible := rgPrice.ItemIndex = 0;
  lbDepth.Visible := rgPrice.ItemIndex = 0;
end;

procedure TFrmNormalOrderEx.SaveEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
    //
    FieldByName('ExKin').AsInteger   := cbExKind.ItemIndex;
    FieldByName('ExApiType').AsInteger := cbMarket.ItemIndex;
    FieldByName('Code').AsString     := edtCode.Text;
    FieldByName('rgPrice').AsInteger   := rgPrice.ItemIndex;
    FieldByName('Tick').AsString       := edtTick.Text;
    FieldByName('Settle').AsInteger    := cbSettle.ItemIndex;
  end;
end;

procedure TFrmNormalOrderEx.sgBalSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
  var
    bInit : TDecimalHelper;
begin
  if (ACol = 1) and (ARow = 0) then
  begin
    case FExKind of
      ekBinance:
        begin
          if TStringGrid(Sender) <> sgBal then Exit;
          if cbMarket.ItemIndex = 0 then
          begin
            if FAsset = nil then Exit ;
            bInit.convert(FAsset.Balance);
            edtQty.Text := Format('%.*f', [ bInit.Precision, FAsset.Balance ]);
          end else
          begin
            if FPosition = nil then Exit;
            bInit.convert(FPosition.Volume);
            edtQty.Text := Format('%.*f', [ bInit.Precision, abs(FPosition.Volume) ]);
          end;
        end;
      ekUpbit, ekBithumb:
        begin
          if TStringGrid(Sender) <> sgBal then Exit;
          if FAsset = nil then Exit ;
          bInit.convert(FAsset.Balance);
          edtQty.Text := Format('%.*f', [ bInit.Precision, FAsset.Balance ]);
        end;
    end;
  end;

end;

procedure TFrmNormalOrderEx.sgHogaDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    aFont, aBack : TColor;
    dFormat : word;
    aRect : TRect;
    stTxt, sLeft, sRight : string;
    nPos  : Integer;
begin

  aFont := clBlack;
  aBack := clWhite;
  aRect := Rect;
  dFormat := DT_RIGHT ;
  nPos  := 0;

  with sgHoga do
  begin
    stTxt := Cells[ACol, ARow];

    if Acol = 1 then begin
      if ARow > AskRow then
        aBAck := LONG_COLOR
      else
        aBack := SHORT_COLOR;


      nPos := Pos('|', stTxt);
      if nPos > 0 then begin
         sLeft  := '(' + Copy(stTxt, 1, nPos - 1) + ')';
         sRight := Copy(stTxt, nPos + 1, MaxInt);
      end;
    end;

    if ACol = 0 then
    begin
      dFormat := DT_CENTER;

      if Objects[ACol, ARow] <> nil then
        if Integer( Objects[ACol, ARow] ) = 100 then
          aBack := clYellow;//  SELECTED_COLOR;
    end;

    aRect.Top := Rect.Top + 2;
    if (ACol = 1) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;

    Canvas.FillRect( Rect);

    if nPos = 0 then
      DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat )
    else begin
      var wRight := Canvas.TextWidth(sRight);
      Canvas.TextOut(Rect.Right - wRight - 4, Rect.Top + 2, sRight);

      var SaveDC := SaveDC(Canvas.Handle);
      try
        var  rClip := Rect;
        rClip.Right := Rect.Right - wRight - 8;  // 우측 텍스트 앞까지
        if rClip.Right > rClip.Left then
        begin
          IntersectClipRect(Canvas.Handle,
            rClip.Left, rClip.Top, rClip.Right, rClip.Bottom);
          if ARow <= AskRow then
            Canvas.Font.Color := clBlue
          else
            Canvas.Font.Color := clRed;
          Canvas.TextOut(Rect.Left + 4, Rect.Top + 2, sLeft);
        end;
      finally
        RestoreDC(Canvas.Handle, SaveDC);
      end;
    end;

  end;
end;

procedure TFrmNormalOrderEx.sgHogaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    i, aCol, aRow : integer;
    sTxt : string;
    dPrice: double;
    bIn : boolean;

begin

  sgHoga.MouseToCell( X, Y, aCol, aRow );
  bIn  := false;

  if FSymbol = nil then Exit;

  dPrice := 0.0;

  // 호가...
  if rgPrice.ItemIndex = 0 then begin

    if (aCol = 1) and (aRow <= AskRow) then begin
      dPrice  := FSymbol.Asks[abs(aRow-AskRow)].Price;
    end
    else if (aCol = 1) and (aRow > AskRow) then begin

      dPrice  := FSymbol.Bids[aRow - AskRow -1].Price;
    end;

    if (aCol = 1) and (aRow in [0..9] ) then
    begin
      bIn := true;
    end else
    if (aCol = 1) and ( aRow > AskRow) then
    begin

      bIn := true;
    end;

    if bIn then
    begin
      FCol := aCol;
      FRow := aRow;

      DispPrice;
    end;
  end else
  begin
    lbDepth.Caption := '';

    if (aRow <= AskRow) then begin
      dPrice  := FSymbol.Asks[abs(aRow-AskRow)].Price;
    end
    else if (aRow > AskRow) then begin
      dPrice  := FSymbol.Bids[aRow - AskRow -1].Price;
    end;
  end;

  if IsZero( dPrice ) then Exit;

	sTxt	:= SetPrice(dPrice);// FmtString( GetPrecision( FSymbol, dPrice ), dPrice , 1 );

  if sTxt <> '' then begin
    edtPrice.Text := sTxt;
    CalcCostNMax;
  end;

end;


procedure TFrmNormalOrderEx.sgPosDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    sTxt: string;
    dFmt: DWORD;
    cBack: TColor;
    aRect: TRect;
begin

  dFmt := DT_SINGLELINE or DT_VCENTER;
  cBack:= clWhite;
  aRect:= Rect;

  with (Sender as TStringGrid) do
  begin
    sTxt := Cells[ACol, ARow];

    case ACol of
      0 : begin
            dFmt := dFmt or DT_CENTER;
            cBack:= clBtnFace;
          end;
      1 : begin
            dFmt := dFmt or DT_RIGHT;
            aRect.Right := aRect.Right-2;
          end;
    end;

    DrawText(Canvas.Handle, PChar(sTxt), Length(sTxt), aRect, dFmt);
  end;
end;

procedure TFrmNormalOrderEx.CalcCostNMax;
var
  stData : string;
  iDiv : integer;
  dCost, dMax, dPrice, dQty : double;
begin
  Exit;

  if ( FExKind = ekBinance ) and ( GetExApiType <> eaSpot ) and ( FSymbol <> nil ) and ( FPosition <> nil ) and (FAccount <> nil) then
  begin
    stData := 'Cost : 0.00   Max : 0.00';

    try
      if not tryStrToFloat(edtQty.Text, dQty) then Exit;
      if not TryStrToFloat(edtPrice.Text, dPrice) then Exit;

      iDiv := ifThen( rbBuy.Checked, 1, -1);

      dCost := abs( min(0, iDiv * ((FSymbol as TFuture).MarkPrice  - dPrice)) ) +
        CalcDiv(  ( dPrice * dQty ), FPosition.Leverage );

      dMax  := CalcDiv( FAccount.Asset.Available, dCost);

//      stData:= Format('Cost : %.*n Max : %.*n', [ FSymbol.Spec.Precision, dCost,
//        FSymbol.Spec.QtyPrecision,    ]);

    finally
//      lbCost.Caption  := stData;
    end;
  end;
end;


procedure TFrmNormalOrderEx.LoadEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
    //
    cbExKind.ItemIndex  := FieldByName('ExKin').AsInteger;//Def( cbExKind.ItemIndex );
    edtCode.Text        := FieldByName('Code').AsString ;
    rgPrice.ItemIndex   := FieldByName('rgPrice').AsInteger ;
    UpDown1.Position    := FieldByName('Tick').AsString.ToInteger;

    rgPriceClick(nil);

    cbExKindChange(nil);
    if FExKind = ekBinance then
    begin
      cbMarket.ItemIndex  := FieldByName('ExApiType').AsInteger;
    end;

    cbSettle.ItemIndex  := FieldByName('Settle').AsInteger;

    if edtcode.Text <> '' then
      SetSymbol;

  end;
end;


procedure TFrmNormalOrderEx.initControls;
begin
  cbExKindChange( nil );

  with sgBal do
  begin
    Cells[0,0] 	:= '보유수량';
    Cells[0,1]	:= '평가금액';
    Cells[0,2]	:= '주문가능';
  end;

  with sgPos do
  begin
    Cells[0,0]  := '평가손익';
    Cells[0,1]  := '평균단가';
    Cells[0,2]  := 'Liq. Pr.';
  end;

  rgPriceClick(nil);
end;


procedure TFrmNormalOrderEx.Timer1Timer(Sender: TObject);
begin
	if FExKind <> ekBinance then Exit;

  SetLimitPrice(FSymbol);
  //

end;

procedure TFrmNormalOrderEx.TradeProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin
  if ( Receiver <> Self ) or ( DataObj = nil  ) then Exit;

  case integer(EventID) of
    ORDER_REJECTED : DoAlert( DataObj as TOrder, false ) ;
    ORDER_NEW    ,
    ORDER_ACCEPTED,
    ORDER_CANCELED : DoAlert( DataObj as TOrder, true ) ;
    ORDER_FILLED  :   ;

      // position Event;
    POSITION_NEW    ,
    POSITION_UPDATE ,
    POSITION_ABLEQTY : DoPosition( DataObj as TPosition )    ;

     // 잔고 조회 시 spot 은 요기호
    ASSET_NEW,
    ASSET_UPDATE : DoAsset( DataObj as TAsset );

     // 바이낸스선물
     // 잔고 조회 시 선물은 요기호
    ACCOUNT_INFO ,
    ACCOUNT_AMT  : DoAccountUpdate( DataObj as TAccount );
    ACCOUNT_ASS_MODE  :    UpdatePosition;
  end;
end;

procedure TFrmNormalOrderEx.OnOrder(aOrder: TOrder; iEventID: integer);
begin
  if (aOrder.Account <> FAccount) or (aOrder.Symbol <> FSymbol) then Exit;

  case iEventID of
    ORDER_NEW,
    ORDER_CANCELED : begin

    end;
    ORDER_FILLED : begin

    end;
  end;

end;

procedure TFrmNormalOrderEx.DoAlert(aOrder: TOrder; bSuccess : boolean);
var
  sTmp : string;
begin
  if bSuccess then
  begin

    if aOrder.OrderType = otNormal then
      sTmp := '신규'
    else
      sTmp := '취소';

    sTmp := Format('%s %s 주문 성공 %s', [ aOrder.OrderTypeToStr, aOrder.SideToStr, aOrder.OrderNo ]);

  end else
  begin
    // 신규 주문 거부
    if aOrder.State = osRejected then
    begin
      sTmp := '신규';
    end else
    // 취소 주문 거부
    if aOrder.State = osActive then
    begin
      sTmp := '취소';
    end;

    sTmp := Format('%s 주문 거부 %s', [ sTmp, aOrder.RejectReason ]);
  end;

  stBar.Panels[0].Text := FormatDateTime('hh:nn:ss', now);
  stBar.Panels[1].Text := sTmp;
end;

procedure TFrmNormalOrderEx.DoAsset(aAsset: TAsset);
begin
  if aAsset = nil then Exit;
  if FAsset <> aAsset then Exit;
  if (FAccount = nil) or (FSymbol = nil) then Exit;

  UpdateAssets;
end;

procedure TFrmNormalOrderEx.DoPosition( aPos : TPosition );
begin
  if (aPos.Account = FAccount) and (aPos.Symbol = FSymbol) and (FPosition = nil ) then
    FPosition := aPos;

	if FPosition <> aPos then
    Exit;

  UpdatePosition;
end;

// 바이낸스선물 처리
procedure TFrmNormalOrderEx.DispPrice;
begin
  if (FCol = 1) and (FRow <= AskRow) then
  begin
    lbDepth.Caption := Format( '매도%d호가 %s%s ' , [ abs(FRow-AskRow) + 1, ifThenStr(rbBuy.Checked, '+', '-'), edtTick.Text ] );
  end else
  if (FCol = 1) and (FRow > AskRow) then
  begin
    lbDepth.Caption := Format( '매수%d호가 %s%s', [ FRow-AskRow, ifThenStr(rbBuy.Checked, '+', '-'), edtTick.Text ] );
  end;
end;

procedure TFrmNormalOrderEx.DoAccountUpdate(aAcnt: TAccount);
begin

	if aAcnt = nil then Exit;
  if aACnt <> FAccount then Exit;

  UpdateAssets;
end;

// KRW, USDT, USDC 주문가능금액..
function  TFrmNormalOrderEx.GetAvailable: double;
begin
  Result := 0;

  if FAccount = nil then Exit;

  if (FExKind = ekBinance) and (FSCType = scUSDC) then
  begin
    if FAccount.DCAss <> nil then
      Result := FAccount.DCAss.Available;
  end else
    Result := FAccount.Asset.Available;
end;

procedure TFrmNormalOrderEx.UpdateAssets;
begin
  if (FAsset = nil) or (FAccount = nil) then Exit;

  if (FExKind = ekBinance) and (FAccMarket <> amSpot) then
  begin
    sgBal.Cells[1,2]	:= DoubleToStr(GetAvailable, 2);
    Exit;
  end;

  with sgBal do
  begin
    Cells[1,0]  := DoubleToStr(FAsset.Balance);
    Cells[1,1]  := DoubleToStr(FAsset.Balance * FSymbol.Last, 0);
    Cells[1,2]  := DoubleToStr(GetAvailable, 0);
  end;

  with sgPos do
  begin
    Cells[1,0]  := DoubleToStr(FAsset.Balance * (FSymbol.Last - FAsset.AvgPrice), 0);
    Cells[1,1]  := FSymbol.PriceToStr(FAsset.AvgPrice);
  end;
end;

procedure TFrmNormalOrderEx.UpdatePosition;
var
  iPre : integer;
begin
  if FExKind <> ekBinance then Exit;

  iPre := 2;
  sgBal.Cells[1,2]	:= DoubleToStr(GetAvailable, iPre);

	if FPosition = nil then Exit;

  with sgBal do
  begin
    Cells[1,0]  := DoubleToStr(FPosition.Volume);
    Cells[1,1]	:= DoubleToStr(FPosition.GetOpenAmt, iPre);
  end;

  with sgPos do
  begin
    Cells[1,0]  := DoubleToStr(FPosition.EntryOTE, iPre);
    Cells[1,1]	:= FPosition.Symbol.PriceToStr(FPosition.AvgPrice);
    Cells[1,2]	:= FPosition.Symbol.PriceToStr(FPosition.LiqPrice);
//    Cells[1,3]  := IntToStr( FPosition.Leverage );
  end;

end;


procedure TFrmNormalOrderEx.UpDown1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin

end;

{
사용자 요청에 의한 수량 표시 변경
해당호가 100만원 이상 : 수량 - 소수점 4자리 표시
해당호가 100만원 미만 10만원 이상 : 수량 - 소수점 3자리 표시
해당호가 10만원 미만 : 수량 - 소수점 2자리 표시
해당호가 1만원 미만 : 수량 - 소수점 1자리 표시
해당호가 1천원 미만 : 수량 - 정수 표시
해당호가 1원 미만 : 수량 - 천단위 이하를 k 로 표시
}

procedure TFrmNormalOrderEx.QuoteProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
var
  iCnt, I : Integer;
  sCurPrice, sTmp : string;
  dQty : double;

  procedure SetCurPrice( iRow : integer );
  begin
    with sgHoga do
      if Cells[0,iRow] = sCurPrice then
        Objects[0,iRow] := Pointer(100)
      else
        Objects[0,iRow] := nil;
  end;

  function GetVol( dPrice : double; dVolume : double) : string;
  var
    iPre : integer;
    dVol : double;
  begin
    iPre := GetQtyPrecision( FSymbol, dPrice );
    if iPre < 0 then
    begin
      dVol := FloorEx(dVolume / 1000);
      result := Format('%sk', [ FmtString( 0,  dVol ) ] );
    end
    else
      result := FmtString( iPre, dVolume );
  end;

begin
  if ( Receiver <> Self ) or ( DataObj = nil ) then Exit;

  if (DataObj as TQuote).Symbol <> FSymbol Then Exit;

  sCurPrice := FSymbol.PriceToStr( FSymbol.Last );

  sgHoga.BeginUpdate;

  with sgHoga do
  for I := 0 to AskRow do //Fsymbol.Asks.Count-1 do
  begin

    Cells[0, AskRow-i] := FSymbol.PriceToStr( FSymbol.Asks[i].Price );

    iCnt  := App.Engine.TradeCore.Orders[FExKind].ActiveOrders.FindOrderCount(FSymbol, FSymbol.Asks[i].Price);

    sTmp := GetVol( FSymbol.Asks[i].Price,  FSymbol.Asks[i].Volume );
    if iCnt > 0 then
      sTmp := iCnt.ToString + '|' + sTmp;
    Cells[1, AskRow-i] := sTmp;

    SetCurPrice( AskRow-i );

    if (rgPrice.ItemIndex = 0 ) and  ( FCol = 1 ) and ( FRow = AskRow-i ) then
      edtPrice.Text := SetPrice(FSymbol.Asks[i].Price);//   FmtString( GetPrecision( FSymbol, FSymbol.Asks[i].Price ),  FSymbol.Asks[i].Price , 1 );
  end;

  with sgHoga do
  for I := 0 to AskRow do //Fsymbol.Bids.Count-1 do
  begin

    Cells[0, AskRow+i+1] := FSymbol.PriceToStr( FSymbol.Bids[i].Price );

    iCnt  := App.Engine.TradeCore.Orders[FExKind].ActiveOrders.FindOrderCount(FSymbol, FSymbol.Bids[i].Price);

    sTmp := GetVol( FSymbol.Bids[i].Price,  FSymbol.Bids[i].Volume );

    if iCnt > 0 then
      sTmp := iCnt.ToString + '|' + sTmp;
    Cells[1, AskRow+i+1] := sTmp;

    SetCurPrice( AskRow+i+1 );

    if (rgPrice.ItemIndex = 0 ) and ( FCol = 1 ) and ( FRow = AskRow+i+1 ) then
      edtPrice.Text := SetPrice(FSymbol.Bids[i].Price);
        // FmtString( GetPrecision( FSymbol, FSymbol.Bids[i].Price ), FSymbol.Bids[i].Price , 1 );
  end;

  sgHoga.EndUpdate;

  if( TryStrToFloat( edtQty.Text, dQty ) ) then
    edtEstPrice.Text := FSymbol.PriceToStr( FSymbol.CalcEstPrice( ifThen( rbBuy.Checked, 1, -1) , dQty))
  else
    edtEstPrice.Text := '0';

  UpdateAssets;
  UpdatePosition;

  UpdateTest;

end;

function TFrmNormalOrderEx.CalcMaxQuantity(iSide : integer) : double;
var
  dTmp, dPrice, dim, dAmt, dAvailable : double;
begin
  Result := 0;

  if FPosition = nil then Exit;
  if not (FSymbol is TFuture) then Exit;

  try

    dPrice  := StrToFloatDef(edtPrice.Text, 0);
    if CheckZero(dPrice) then Exit;

//    dPrice:= max(dTmp, (FSymbol as TFuture).MarkPrice);
    dim   := abs(min(0, ((FSymbol as TFuture).MarkPrice - dPrice) * iSide));
    dAvailable  := FAccount.Available;// min(FAccount.Available, FPosition.MaxNotional) + FPosition.GetOpenAmt;


    dAvailable  := min(FAccount.Available, FPosition.MaxNotional) + FPosition.GetOpenAmt;
    dAmt  := dAvailable / (dim * FPosition.Leverage + dPrice);
    dAmt  := dAvailable / ( dim + (dPrice / FPosition.Leverage) );
    dAmt  := (dAvailable * FPosition.Leverage) / (dim  + dPrice + (dim / FPosition.Leverage) );
//
//
    Result:= dAmt + abs(FPosition.Volume);
  except
  end;
end;

function TFrmNormalOrderEx.CalcMaxQuantity2(iSide : integer) : double;
var
  dTmp, dPrice, dim, dAmt, dAvailable : double;
begin
  Result := 0;

  if FPosition = nil then Exit;
  if not (FSymbol is TFuture) then Exit;

  try

    dTmp  := StrToFloatDef(edtPrice.Text, 0);
    if CheckZero(dTmp) then Exit;

    dPrice:= max(dTmp, (FSymbol as TFuture).MarkPrice);
    dim   := max(0, iSide * FPosition.Leverage*(dPrice - (FSymbol as TFuture).MarkPrice));
    //dim   := max(0, iSide * FPosition.Leverage*((FSymbol as TFuture).MarkPrice - dPrice));
    dAvailable  := min(FAccount.Available, FPosition.MaxNotional);// + FPosition.GetOpenAmt;

//    if CheckBox2.Checked then
//      dAmt  := (dAvailable * FPosition.Leverage) / (dPrice + dim + (dim/FPosition.Leverage))
//    else
      dAmt  := (dAvailable * FPosition.Leverage) / (dPrice + dim);

    Result := dAmt;

  except
  end;
end;

// 포지션 없을때는 정확
function TFrmNormalOrderEx.CalcMaxQuantity3(iSide : integer) : double;
var
  dTmp, dPrice, dim, dAmt, dAvailable : double;
begin
  Result := 0;

  if FPosition = nil then Exit;
  if not (FSymbol is TFuture) then Exit;

  try

    dTmp  := StrToFloatDef(edtPrice.Text, 0);
    if CheckZero(dTmp) then Exit;

//    if iSide = -1 then
////      if dTmp > (FSymbol as TFuture).MarkPrice then
////        dPrice := dTmp
////      else
////        dPrice := (FSymbol as TFuture).MarkPrice
//
//      dPrice:= dTmp//min(dTmp, (FSymbol as TFuture).MarkPrice)
//    else
//      dPrice:= min(dTmp, (FSymbol as TFuture).MarkPrice);
//
//    dPrice:= dTmp;max(dTmp, (FSymbol as TFuture).MarkPrice);
//    if Checkbox1.Checked then
//      dPrice := (FSymbol as TFuture).MarkPrice
//    else
      dPrice := dTmp;


    if Checkbox1.Checked then
      dim   := max(0, iSide * FPosition.Leverage*((FSymbol as TFuture).MarkPrice - dPrice))
    else
      dim   := max(0, iSide * FPosition.Leverage*(dPrice - (FSymbol as TFuture).MarkPrice));

//    dim   := max(0, iSide * FPosition.Leverage*(dPrice - (FSymbol as TFuture).MarkPrice));
    //dim   := max(0, iSide * FPosition.Leverage*((FSymbol as TFuture).MarkPrice - dPrice));
    dAvailable  := min(FAccount.Available, FPosition.MaxNotional);// + FPosition.GetOpenAmt;

    if CheckBox2.Checked then begin
      if iSide = -1 then
        dAmt  := (dAvailable * FPosition.Leverage) / (dPrice + dim + (dim/FPosition.Leverage))
      else
        dAmt  := (dAvailable * FPosition.Leverage) / (dPrice + dim);
    end
    else
      dAmt  := (dAvailable * FPosition.Leverage) / (dPrice + dim);

    Result := dAmt;

  except
  end;
end;

function TFrmNormalOrderEx.CalcCost(iSide : integer; dQty : double) : double;
var
  dPrice : double;
begin
  Result := 0;

  if FPosition = nil then Exit;
  if not (FSymbol is TFuture) then Exit;

  try

    dQty  := StrToFloatDef(edtQty.Text, 0);
    dPrice  := StrToFloatDef(edtPrice.Text, 0);
    if CheckZero(dPrice) then Exit;
    if CheckZero(dQty) then Exit;

    var dim, dOpen : double;

    dim := (dPrice * dQty) / FPosition.Leverage;
    dOpen := dQty * abs(min(0, iSide * ((FSymbol as TFuture).MarkPrice - dPrice)));

    if iSide = -1 then
      Result := dim + dOpen + dOpen/FPosition.Leverage
    else
      Result := dim + dOpen;

  except
  end;
end;

procedure TFrmNormalOrderEx.UpdateTest;
var
  dim2, dim, dTmp, dQty2, dMg, dPrice, dQty, dAmt, dAmt2, dAvailable : double;

  dmm : array [TPositionType] of double;
begin
  if FSymbol = nil then Exit;
  if FPosition = nil then Exit;

  if not (FSymbol is TFuture) then Exit;

  dQty  := StrToFloatDef(edtQty.Text, 0);
  dTmp  := StrToFloatDef(edtPrice.Text, 0);

    dQty := CalcMaxQuantity3(1);
    dQty2:= CalcMaxQuantity3(-1);
    lbTest2.Caption  := Format('Cost : %s  Cost : %s', [
      FSymbol.PriceToStr(CalcCost(1,dQty)),
      FSymbol.PriceToStr(CalcCost(-1,dQty2)) ] );
    lbTest.Caption  := Format('Max : %s  Max : %s', [
      FSymbol.QtyToStr(dQty),
      FSymbol.QtyToStr(dQty2) ] );

      exit;

  if dPrice < EPSILON then begin
    lbTest.Caption := 'Max : 0  Max : 0';
 //   lbTest2.Caption :='Cost: 0  Cost: 0';
  end
  else begin

//    dPrice := max(dTmp, (FSymbol as TFuture).MarkPrice);
//    dAvailable  := min(FAccount.Available, FPosition.MaxNotional) + FPosition.GetOpenAmt;
//
//    dmm[ptLong] :=  abs(min(0, (FSymbol as TFuture).MarkPrice - dPrice ));
//    dmm[ptShort] := abs(min(0, ((FSymbol as TFuture).MarkPrice - dPrice )) * -1 );
//
//    dTmp := (FSymbol as TFuture).MarkPrice - dPrice;
//
//    dQty2 := FPosition.Volume + dQty;
//    // 매수구하기
//    if FPosition.Side < 0 then begin
//      if dQty2 > 0 then
//        dQty  := dQty2
//    end;
//
//    dMg  := (dPrice*dQty) / FPosition.Leverage;
//
//    dim  :=  dQty * abs(min(0, dTmp));
//    dim2 :=  dQty * abs(min(0,-1* dTmp));
//
//    if FPosition.Side >= 0 then
//    begin
//      // 매수 비용
//      dAmt := dMg + dQty * abs(min(0, dTmp));
//    end else
//    begin
//      dQty2 := FPosition.Volume + dQty;
//      if dQty2 <= 0 then
//        dAmt := 0
//      else begin
//        dMg  := (dPrice*dQty2) / FPosition.Leverage;
//        dAmt := dMg + dQty2 * abs(min(0, dTmp));
//      end;
//    end;
//
//    dMg  := (dPrice*dQty) / FPosition.Leverage;
//        // 매도 비용
//    if FPosition.Side <= 0 then
//    begin
//      dAmt2:= dMg + dQty * dim2;
//    end else
//    begin
//      dQty2 := FPosition.Volume - dQty;
//      if dQty2 >= 0 then
//        dAmt2 := 0
//      else begin
//        dMg := (dPrice*abs(dQty2)) / FPosition.Leverage;
//        dAmt2 := dMg + abs(dQty2) * dim2;
//      end;
//    end;
//
//    lbTest2.Caption := Format('Cost: %s Cost: %s', [
//      FSymbol.PriceToStr(dAmt), FSymbol.PriceToStr(dAmt2+(dim2/FPosition.Leverage)) ]);
//
//
//    dQty := (dAvailable * FPosition.Leverage) / (dPrice +dim);
//    dQty2:= (dAvailable * FPosition.Leverage) / (dPrice +dim2);

  end;
end;

end.
