unit UNormalOrder;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ExtCtrls, Vcl.StdCtrls

  , UApiTypes, UApiConsts, UTypes

  , USymbols, UOrders, UAccounts, UPositions, UAssets

  , UDistributor, UStorage, Vcl.Mask, Vcl.ComCtrls

  ;

type
  TFrmNormalOrder = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    edtQty: TLabeledEdit;
    edtPrice: TLabeledEdit;
    cbExKind: TComboBox;
    edtCode: TEdit;
    rbBuy: TRadioButton;
    rbSell: TRadioButton;
    cbReduce: TCheckBox;
    btnOrder: TButton;
    sgHoga: TStringGrid;
    sgBal: TStringGrid;
    Button1: TButton;
    btnQueryOrder: TButton;
    Timer1: TTimer;
    Button3: TButton;
    rgPrice: TRadioGroup;
    lbDepth: TLabel;
    cbMarket: TComboBox;
    Button4: TButton;
    edtEstPrice: TLabeledEdit;
    sgPos: TStringGrid;
    cbTest: TButton;
    stBar: TStatusBar;
    lbmin: TLabel;
    edtTick: TEdit;
    UpDown1: TUpDown;
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
    procedure cbMarketChange(Sender: TObject);
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
  private
    FExKind : TExchangeKind;
    FAccMarket : TAccountMarketType;
    FSymbol : TSymbol;
    FAccount: TAccount;
    FPosition : TPosition;
    FAsset    : TAsset;
    FCol, FRow : integer;

    procedure initControls;
    procedure DoPosition(aPos: TPosition);
    procedure DoAccountUpdate(aAcnt : TAccount);
    procedure DoAsset(aAsset : TAsset );
    procedure DoAlert(aOrder : TOrder; bSuccess : boolean);
    procedure UpdateAssets(bFirst : boolean = false);
    procedure UpdatePosition;
    procedure ClearBalGrid( aGrid : TStringGrid );
    procedure SetOrderObjects;
    procedure SetAccMarkets;

    function  SetPrice( dPrice : double ) : string;
    function  GetExApiType : TExchangeApiType;
    procedure CalcCostNMax;
    procedure UpdateControls;
    procedure UpdateTest;
    function CalcMaxQuantity(iSide: integer): double;
    function CalcMaxQuantity2(iSide: integer): double;
    function CalcCost(iSide: integer; dQty: double): double;
    function CalcMaxQuantity3(iSide: integer): double;

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
  FrmNormalOrder: TFrmNormalOrder;

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

procedure TFrmNormalOrder.btnOrderClick(Sender: TObject);
var
  iSide : integer;
  dOrderQty, dPrice : double;
  aOrder  : TOrder;
  aTIF    : TTimeInForce;
begin

  if (edtQty.Text = '') or ( edtPrice.Text = '') then
  begin
    ShowMessage('필수항목 입력');
    Exit;
  end;

  iSide := 0;
  if rbBuy.Checked then iSide := 1;
  if rbSell.Checked then iSide := -1;

  if ( not TryStrToFloat( edtPrice.Text, dPrice ))
    or ( not TryStrToFloat( edtqty.Text, dOrderQty )) then
  begin
    ShowMessage( '주문가격 or 수량이 잘못 됨 ');
    Exit;
  end;

  if not App.Engine.TradeCore.CheckLimitOrder( FAccount, FSymbol, iSide, dPrice, dOrderQty, ORD_SEMI_AUTO) then
  begin
    ShowMessage('주문 제한에 걸림');
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

procedure TFrmNormalOrder.Button1Click(Sender: TObject);
begin
//	App.Engine.SharedManager.RequestData(
//  	FExKind , mtSpot, rtBalance, 
//  )
//	if FSymbol <> nil then
//  	App.Engine.ApiManager.ExManagers[FExKind].RequestBalance( FSymbol)	;
end;

procedure TFrmNormalOrder.btnQueryOrderClick(Sender: TObject);
begin
	//
  if FSymbol <> nil then
		App.Engine.ApiManager.ExManagers[FExKind].RequestOrderList( FSymbol );
end;

procedure TFrmNormalOrder.Button3Click(Sender: TObject);
begin
  if FSymbol <> nil then
		App.Engine.ApiManager.ExManagers[FExKind].RequestTradeAmt( FSymbol );
end;

procedure TFrmNormalOrder.Button4Click(Sender: TObject);
begin
  if ( FExKind = ekBinance ) and ( GetExApiType <> eaSpot ) and ( FSymbol <> nil ) then
    App.Engine.ApiManager.ExManagers[FExKind].RequestPosition( FSymbol );
end;

procedure TFrmNormalOrder.Button5Click(Sender: TObject);
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

procedure TFrmNormalOrder.Button6Click(Sender: TObject);
var
  i : integer;
begin
  for I := 0 to 20-1 do
    btnOrderClick(nil);
end;

procedure TFrmNormalOrder.UpdateControls;
begin
  btnQueryOrder.Visible := false;
  if ( FExKind = ekBinance ) and ( GetExApiType <> eaSpot ) and ( FSymbol <> nil ) then begin
    sgPos.Visible   := true;
    Button4.Visible := true;
    cbPostOnly.Visible  := true;

    edtLimitBuy.Visible := true;
    edtLimitSell.Visible  := true;
//    if (FAccount <> nil) and (FAccount.MultiAssetsMode) then
//      sgBal.Cells[0,0]  := '보유수량'
//    else
//      sgBal.Cells[0,0]  := 'Equity';
  end else
  begin
    sgPos.Visible   := false;
    Button4.Visible := false;
    cbPostOnly.Visible  := false;

//    if FExKind = ekBithumb then
//      btnQueryOrder.Visible := true;

    edtLimitBuy.Visible := false;
    edtLimitSell.Visible:= false;
  end;
end;


procedure TFrmNormalOrder.cbExKindChange(Sender: TObject);
//var
//  aKind : TExchangeKind;
begin
//  aKind     := TExchangeKind( cbExKind.ItemIndex );
//
//  if aKind <> FExKind then
//    FSymbol := nil;
//
//  FExKind   := aKind;
  SetAccMarkets;
  //SetOrderObjects;
end;

procedure TFrmNormalOrder.cbMarketChange(Sender: TObject);
//var
//  aAccount : TAccount;
begin
//  FAccMarket := TAccountMarketType( cbMarket.ItemIndex +1 );
//  aAccount  := App.Engine.TradeCore.FindAccount( FExKind, FAccMarket);
//
//  if aAccount <> FAccount then
//    FAccount := aAccount;
//
//  SetOrderObjects;
end;


procedure TFrmNormalOrder.cbTestClick(Sender: TObject);
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

procedure TFrmNormalOrder.SetOrderObjects;
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

    FAsset := FAccount.Asset;

    UpdateAssets(true);
    UpdatePosition;
  end else
  begin
    aAsset  := FAccount.Assets.Find( FSymbol.Spec.BaseCode);
    if (aAsset <> FAsset) or (aAsset = nil) then
    begin
      ClearBalGrid(sgPos);
      ClearBalGrid(sgBal);
      FAsset := aAsset;
    end;

    UpdateAssets;
    FPosition := nil;
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

function TFrmNormalOrder.SetPrice(dPrice: double): string;
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

procedure TFrmNormalOrder.SetAccMarkets;
begin
  cbMarket.Clear;
  case TExchangeKind( cbExKind.ItemIndex ) of
    ekBinance:
      begin
        cbMarket.Items.Add('Spot');
        cbMarket.Items.Add('USDⓢ-M');
        cbMarket.Items.Add('COIN-M');
        cbMarket.ItemIndex := 1;
      end;
    ekBithumb, ekUpbit:
      begin
        cbMarket.Items.Add('Spot');
        cbMarket.ItemIndex := 0;
      end;
  end;
//  if cbMarket.Items.Count > 0 then
//    cbMarketChange(nil);
end;

procedure TFrmNormalOrder.SetLimitPrice(aSymbol: TSymbol);
begin
  if aSymbol = nil then Exit;
  if aSymbol.Spec.Market = mtFutures then
  begin
    edtLImitBuy.Text  := aSymbol.PriceToStr(aSymbol.GetLimitOrderPrice(true));
    edtLImitSell.Text  := aSymbol.PriceToStr(aSymbol.GetLimitOrderPrice(false));
  end;

end;

procedure TFrmNormalOrder.ClearBalGrid( aGrid : TStringGrid );
begin

  with aGrid do
  begin
  	Cells[1,0]	:= '';
    Cells[1,1]	:= '';
    Cells[1,2]	:= '';

    Cells[3,0]	:= '';
		Cells[3,1]	:= '';
    Cells[3,2]	:= '';
  end;

end;

procedure TFrmNormalOrder.edtCodeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    sText : string;
    aSymbol : TSymbol;
    aAccount: TAccount;
begin
  if Key = VK_RETURN then
  begin
    sText := edtCode.Text;

    if sText <> '' then
    begin

      aAccount    := App.Engine.TradeCore.FindAccount(
        TExchangeKind( cbExKind.ItemIndex ), TAccountMarketType( cbMarket.ItemIndex +1 ));

      if aAccount = nil then
      begin
        ShowMessage('계좌 없음');
        Exit;
      end;

      FAccount    := aAccount;
      FExKind     := TExchangeKind( cbExKind.ItemIndex );
      FAccMarket  := TAccountMarketType( cbMarket.ItemIndex +1 );

      aSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( sText, FExKind, GetExApiType );
      if aSymbol = FSymbol then
      begin
        if aSymbol = nil then
          ShowMessage('해당종목없음');
        Exit;
      end;

      if FSymbol <> nil then
        App.Engine.QuoteBroker.Brokers[FSymbol.Spec.ExchangeType].Cancel( Self, FSymbol);
      if aSymbol <> nil then
        App.Engine.QuoteBroker.Brokers[FExKind].Subscribe( Self, aSymbol, QuoteProc);

      initGrid( sgHoga, false );
      edtQty.Text := '';

      FSymbol     := aSymbol;

      SetOrderObjects;

      Button4Click(nil);

      UpdateControls;
    end;
  end;
end;

procedure TFrmNormalOrder.edtPriceKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key in [VK_DOWN, VK_UP] then
    Key := 0;
end;

procedure TFrmNormalOrder.edtPriceKeyUp(Sender: TObject; var Key: Word;
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

procedure TFrmNormalOrder.edtTickChange(Sender: TObject);
begin
  DispPrice;
end;

procedure TFrmNormalOrder.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmNormalOrder.FormCreate(Sender: TObject);
begin
  initControls;

  FSymbol 	:= nil;
  FPosition	:= nil;
  FAsset    := nil;

  App.Engine.TradeBroker.Subscribe( Self, TradeProc );
end;

procedure TFrmNormalOrder.FormDestroy(Sender: TObject);
begin
  //
  App.Engine.QuoteBroker.Cancel(Self );
  App.Engine.TradeBroker.Unsubscribe( Self );

end;

function TFrmNormalOrder.GetExApiType: TExchangeApiType;
begin
  Result := TExchangeApiType( cbMarket.ItemIndex );
end;

procedure TFrmNormalOrder.rbBuyClick(Sender: TObject);
begin
  btnOrder.Caption  := '매수 주문';
end;

procedure TFrmNormalOrder.rbSellClick(Sender: TObject);
begin
  btnOrder.Caption  := '매도 주문';
end;


procedure TFrmNormalOrder.rgPriceClick(Sender: TObject);
begin
  edtTick.Visible := rgPrice.ItemIndex = 0;
  Updown1.Visible := rgPrice.ItemIndex = 0;
  lbDepth.Visible := rgPrice.ItemIndex = 0;
end;

procedure TFrmNormalOrder.SaveEnv(aStorage: TStorage);
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
  end;
end;

procedure TFrmNormalOrder.sgBalSelectCell(Sender: TObject; ACol, ARow: Integer;
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
      ekUpbit,
      ekBithumb:
        begin
          if TStringGrid(Sender) <> sgBal then Exit;
          if FAsset = nil then Exit ;
          bInit.convert(FAsset.Balance);
          edtQty.Text := Format('%.*f', [ bInit.Precision, FAsset.Balance ]);
        end;
    end;
  end;

end;

procedure TFrmNormalOrder.sgHogaDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    aFont, aBack : TColor;
    dFormat : word;
    aRect : TRect;
    stTxt : string;
begin

  aFont := clBlack;
  aBack := clWhite;
  aRect := Rect;
  dFormat := DT_RIGHT ;

  with sgHoga do
  begin
    stTxt := Cells[ACol, ARow];

    if ACol = 1 then
    begin
      dFormat := DT_CENTER;

      if Objects[ACol, ARow] <> nil then
        if Integer( Objects[ACol, ARow] ) = 100 then
          aBack :=  SELECTED_COLOR;
    end;


    aRect.Top := Rect.Top + 2;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;

    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );
  end;
end;

procedure TFrmNormalOrder.sgHogaMouseDown(Sender: TObject; Button: TMouseButton;
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
//  if (aCol = 0) and ( aRow <=4) then begin
//    //sTxt := sgHoga.Cells[aCol, aRow];
//    dPrice  := FSymbol.Asks[aRow].Price;
//  end
//  else if ( aCol = 2 ) and ( aRow > 4 ) then begin
//    //sTxt := sgHoga.Cells[aCol, aRow];
//    dPrice  := FSymbol.Bids[aRow-5].Price;
//  end;

  if rgPrice.ItemIndex = 0 then begin

    if (aCol = 0) and ( aRow <=9) then begin
      //sTxt := sgHoga.Cells[aCol, aRow];
      dPrice  := FSymbol.Asks[abs(aRow-9)].Price;
    end
    else if ( aCol = 2 ) and ( aRow > 9 ) then begin
      //sTxt := sgHoga.Cells[aCol, aRow];
      dPrice  := FSymbol.Bids[aRow-10].Price;
    end;

    if (aCol=0) and (aRow in [0..9] ) then
    begin
      //lbDepth.Caption := Format( '매도 %d 호가 - %d ' , [ abs(aRow-9), UpDown1.Position ] );
      bIn := true;
    end else
    if (aCol=2) and ( aRow>=10) then
    begin
      //lbDepth.Caption := Format( '매수 %d 호가 + %d', [ aRow-10, UpDown1.Position ] );
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

    if ( aRow <=9 ) then begin
      //sTxt := sgHoga.Cells[aCol, aRow];
      dPrice  := FSymbol.Asks[abs(aRow-9)].Price;
    end
    else if ( aRow > 9 ) then begin
      //sTxt := sgHoga.Cells[aCol, aRow];
      dPrice  := FSymbol.Bids[aRow-10].Price;
    end;

//    if  (aRow in [0..4] ) then
//    begin
//      lbDepth.Caption := Format( '매도 %d 호가', [ abs(aRow-5) ] );
//    end else
//    if  ( aRow>=5) then
//    begin
//      lbDepth.Caption := Format( '매수 %d 호가', [ aRow-4 ] );
//    end;

  end;

  if IsZero( dPrice ) then Exit;

	sTxt	:= SetPrice(dPrice);// FmtString( GetPrecision( FSymbol, dPrice ), dPrice , 1 );

  if sTxt <> '' then begin
    edtPrice.Text := sTxt;
    CalcCostNMax;
  end;

end;


procedure TFrmNormalOrder.CalcCostNMax;
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


procedure TFrmNormalOrder.LoadEnv(aStorage: TStorage);
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
//      cbMarketChange(nil);
    end;

    if edtcode.Text <> '' then begin
      var key : word;
      key := VK_RETURN;
      edtCodeKeyDown( edtcode, key, [ssShift] );
    end;
  end;
end;


procedure TFrmNormalOrder.initControls;
begin
  cbExKindChange( nil );

  with sgBal do
  begin
    Cells[0,0] 	:= '보유수량';
    Cells[0,1]	:= '평가금액';
    Cells[0,2]	:= '주문가능';

    Cells[2,0] 	:= '총보유자산';
    Cells[2,1]	:= '보유현금';
    Cells[2,2]	:= '총평가액';
  end;

  with sgPos do
  begin
    Cells[0,0]  := '평가손익';
    Cells[0,1]  := 'Mark Pr.';
    Cells[0,2]  := 'Liq. Pr.';

    Cells[2,0] 	:= 'Margin';
    Cells[2,1]	:= 'MarginType';
    Cells[2,2]	:= 'Leverage';
  end;

  rgPriceClick(nil);
end;


procedure TFrmNormalOrder.Timer1Timer(Sender: TObject);
begin
	if FExKind <> ekBinance then Exit;

  SetLimitPrice(FSymbol);
  //

end;

procedure TFrmNormalOrder.TradeProc(Sender, Receiver: TObject; DataID: Integer;
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
    ACCOUNT_ASS_MODE  :
      begin
//        with sgBal do
//        begin
//          if ( DataObj as TAccount).MultiAssetsMode then begin
//            Cells[0,0] 	:= 'Equity';
//          end else
//          begin
//            Cells[0,0] 	:= '보유수량';
//          end;
//        end;

        UpdatePosition;
//        DoAccountUpdate( DataObj as TAccount );
      end;
  end;
end;


procedure TFrmNormalOrder.DoAlert(aOrder: TOrder; bSuccess : boolean);
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

procedure TFrmNormalOrder.DoAsset(aAsset: TAsset);
begin
  if aAsset = nil then Exit;
  if FAsset <> aAsset then Exit;

  if ( FAccount = nil ) or ( FSymbol = nil ) then Exit;
  if ( aAsset.Symbol = FSymbol ) and ( aAsset.Account = FAccount) then
    FAsset := aAsset;

  UpdateAssets;
end;

procedure TFrmNormalOrder.DoPosition( aPos : TPosition );
begin
  if (aPos.Account = FAccount) and (aPos.Symbol = FSymbol) and (FPosition = nil ) then
    FPosition := aPos;

	if FPosition <> aPos then
    Exit;

  UpdatePosition;
end;

// 바이낸스선물 처리
procedure TFrmNormalOrder.DispPrice;
begin
  if (FCol=0) and (FRow in [0..9] ) then
  begin
    lbDepth.Caption := Format( '매도 %d 호가 %s %s ' , [ abs(FRow-9), ifThenStr(rbBuy.Checked, '+', '-'), edtTick.Text ] );
  end else
  if (FCol=2) and ( FRow>=10) then
  begin
    lbDepth.Caption := Format( '매수 %d 호가 %s %s', [ FRow-10, ifThenStr(rbBuy.Checked, '+', '-'), edtTick.Text ] );
  end;
end;

procedure TFrmNormalOrder.DoAccountUpdate(aAcnt: TAccount);
var
//	dTotCoin : double;
  iPre : integer;
begin

	if aAcnt = nil then Exit;
  if aACnt <> FAccount then Exit;

  iPre := 0;
  if FExKind = ekBinance then
    if aAcnt.AccountType = amFutureCm then
      iPre := 4
    else
      iPre := 2;

  with sgBal do
  begin

//    Cells[1,2]	:= Format('%.*n', [ iPre, ifThen( FExKind = ekBinance,
//      aAcnt.AvailableAmt[scUSDT],
//      Floor( aAcnt.AvailableAmt[scKRW] ) + 0.001 ) ]  );

//    dTotCoin		:= App.Engine.TradeCore.Positions[FExKind].GetOpenPL( aAcnt );

//    Cells[3,0]	:= Format('%.*n', [ iPre, ifThen( FExKind = ekBinance, dTotCoin + aAcnt.Balance[scUSDT],
//      Floor( dTotCoin + aAcnt.Balance[scKRW] ) + 0.001 ) ] );
//		Cells[3,1]	:= Format('%.*n', [ iPre, ifThen( FExKind = ekBinance, aAcnt.Balance[scUSDT],
//      Floor( aAcnt.Balance[scKRW] ) + 0.001 ) ]  );
//    Cells[3,2]	:= Format('%.*n', [ iPre, ifThen( FExKind = ekBinance, dTotCoin,
//      Floor( dTotcoin ) + 0.001 ) ] );// FPosition.Symbol.QtyToStr( dTotCoin );
    //Cells[1,2]  := Format('%.*n', [ iPre, aAcnt.Asset.Available ]);
    Cells[1,2]  := Format('%.*n', [ iPre, aAcnt.Available ]);
    Cells[3,1]  := Format('%.*n', [ iPre, aAcnt.Balance ]);
  end;
end;

procedure TFrmNormalOrder.UpdateAssets( bFirst : boolean );
var
  iPre : integer;
  dTotCoin : double;
  bInit : TDecimalHelper;
begin
  if FAsset = nil then Exit;

  if (FExKind = ekBinance) and (FAccMarket <> amSpot) then
  begin
    if bFirst then
    begin
      iPre  := ifThen(FAccMarket = amFuture , 2, 4);
      with sgBal do begin
        Cells[1,2]  := Format('%.*n', [ iPre, FAccount.Available] );
        Cells[3,1]  := Format('%.*n', [ iPre, FAccount.Balance ] );
      end;
    end;
    Exit;
  end;

  with sgBal do
  begin

    Cells[1,0] := bInit.DoubleToStr(FAsset.Balance);// Format('%.*n', [ bInit.Precision, FAsset.Balance ]);

    iPre := 0;
    if FExKind = ekBinance then iPre := 4;

    Cells[1,1]  := Format('%.*n', [ iPre, FAsset.Balance * FSymbol.Last ] );
    Cells[1,2]  := Format('%.*n', [ iPre, FAccount.Asset.Available] );

    dTotCoin  := FAccount.Assets.GetTotalCoin;

    Cells[3,0]  := Format('%.*n', [ iPre,  FAccount.Asset.Balance + dTotCoin ] );
    Cells[3,1]  := Format('%.*n', [ iPre,  FAccount.Asset.Balance ] );
    Cells[3,2]  := Format('%.*n', [ iPre,  dTotCoin ] );
  end;
end;

procedure TFrmNormalOrder.UpdatePosition;
var
	dTotCoin, dTotInitMargin, dTmp, dPrice : double;
  bInit : TDecimalHelper;
  iPre : integer;
begin

	if FPosition = nil then Exit;

//  iPre := 0;
//  if FExKind = ekBinance then
  if FPosition.Symbol.Spec.FutureType = ftCoin then begin
    iPre := 4;
    dTmp := 0.00001;
  end
  else begin
    iPre := 2;
    dTmp := 0.001;
  end;

  with sgBal do
  begin

    Cells[1,0]  := bInit.DoubleToStr(FPosition.Volume);
//    Cells[1,1]	:= Format('%.*n', [ iPre, FPosition.GetOpenAnmt] )  ;

    dTotCoin		:= App.Engine.TradeCore.Positions[FExKind].GetOpenPL( FPosition.Account );
    //dFixedPL    := App.Engine.TradeCore.Positions[FExKind].GetFixedPL( FPosition.Account );
    dTotInitMargin  := App.Engine.TradeCore.Positions[FExKind].GetTotInitMargin(FPosition.Account);

//    Cells[1,2]	:= Format('%.*n', [ iPre, FPosition.Account.Asset.Balance + dTotCoin- dTotInitMargin ]  );
//    Cells[3,0]	:= Format('%.*n', [ iPre, FPosition.Account.Asset.Balance + dTotCoin]);
//		Cells[3,1]	:= Format('%.*n', [ iPre, FPosition.Account.Asset.Balance]);

    Cells[3,0]	:= Format('%.*n', [ iPre, FPosition.Account.Balance + dTotCoin]);
		Cells[3,1]	:= Format('%.*n', [ iPre, FPosition.Account.Balance]);
    Cells[1,2]	:= Format('%.*n', [ iPre, FPosition.Account.Available ]  );


    Cells[3,2]	:= Format('%.*n', [ iPre, ifThen( FExKind = ekBinance, dTotCoin,
      Floor( dTotcoin ) + dTmp ) ] );

  end;

  with sgPos do
  begin
    Cells[1,0]  := Format('%.*n', [ iPre, FPosition.EntryOTE ] )  ;
    Cells[1,1]	:= FPosition.Symbol.PriceToStr( (FPosition.Symbol as TFuture).MarkPrice );
    Cells[1,2]	:= FPosition.Symbol.PriceToStr( FPosition.LiqPrice );

    Cells[3,0]	:= Format('%.*n', [ iPre, FPosition.GetInitMargin ] )  ;
    Cells[3,1]	:= ifthenStr( FPosition.Isolated, 'ISOLATED', 'CROSSED');
    Cells[3,2]  := IntToStr( FPosition.Leverage );
  end;



end;


procedure TFrmNormalOrder.UpDown1Changing(Sender: TObject;
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

procedure TFrmNormalOrder.QuoteProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
var
  I : Integer;
  sCurPrice, sTmp : string;
  dQty : double;

  procedure SetCurPrice( iRow : integer );
  begin
    with sgHoga do
      if Cells[1,iRow] = sCurPrice then
        Objects[1,iRow] := Pointer(100)
      else
        Objects[1,iRow] := nil;
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
  for I := 0 to 9 do //Fsymbol.Asks.Count-1 do
  begin

    Cells[1, 9-i] := FSymbol.PriceToStr( FSymbol.Asks[i].Price );

    sTmp := GetVol( FSymbol.Asks[i].Price,  FSymbol.Asks[i].Volume );
    Cells[0, 9-i] := sTmp;

    SetCurPrice( 9-i );

    if (rgPrice.ItemIndex = 0 ) and  ( FCol = 0 ) and ( FRow = 9-i ) then
      edtPrice.Text := SetPrice(FSymbol.Asks[i].Price);//   FmtString( GetPrecision( FSymbol, FSymbol.Asks[i].Price ),  FSymbol.Asks[i].Price , 1 );
  end;

  with sgHoga do
  for I := 0 to 9 do //Fsymbol.Bids.Count-1 do
  begin
    Cells[1, 10+i] := FSymbol.PriceToStr( FSymbol.Bids[i].Price );

    sTmp := GetVol( FSymbol.Bids[i].Price,  FSymbol.Bids[i].Volume );
    Cells[2, 10+i] := sTmp;

    SetCurPrice( 10+i );

    if (rgPrice.ItemIndex = 0 ) and ( FCol = 2 ) and ( FRow = 10+i ) then
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

function TFrmNormalOrder.CalcMaxQuantity(iSide : integer) : double;
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

function TFrmNormalOrder.CalcMaxQuantity2(iSide : integer) : double;
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
function TFrmNormalOrder.CalcMaxQuantity3(iSide : integer) : double;
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

function TFrmNormalOrder.CalcCost(iSide : integer; dQty : double) : double;
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

procedure TFrmNormalOrder.UpdateTest;
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
