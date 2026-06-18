unit USPOrders;

interface

uses
  System.Classes, System.SysUtils, System.DateUtils, vcl.ExtCtrls,

  USymbols, UOrders, UAccounts, UDistributor,

  USymbolCore, UQuoteBroker, UQuoteMerge,

  USPItems, UApiTypes, UTypes

  ;

type

  TSPSymbolArray  = array [TSPType] of TSymbol;
  TMergedQuoteArray = array [TSPType] of TMergedQuote;
  TSPAccountArray = array [TSPType] of TAccount;
  TSPPositionArray = array [TSPType] of TSPPosition;
  TSPAssetArray = array [TSPType] of TAsset;
  TSPArray  = array [TAutoOrderType] of double;

  TSPOrdUnitArray = array [TAutoOrderType] of TSpOrderUnit;
  TReadyArray = array [TAutoOrderType] of boolean;

  TQuoteNotifiy = procedure ( Sender : TObject; sType : TSPType ) of object;

  TSPOrder = class( TCollectionItem )
  private
    FAccounts: TSPAccountArray;
    FSymbols: TSPSymbolArray;
    FParam: TSPParam;
    FRun: boolean;
    FSPValue: TSPArray;
    FName: string;
    FMgQuotes: TMergedQuoteArray;
    FOnSPNotify: TTextNotifyEvent;
    FPositions: TSPPositionArray;

    FOrderUnit: TSPOrdUnitArray;
    FReady: TReadyArray;
    FCompPrice: TSPArray;
    FOrderPrice: TSPArray;
    FBasePrice: TSPArray;
    FTargetPrice: TSPArray;
    FModifyList: TList;

    FTimer  : array [TAutoOrderType] of TTimer;
    FModifyOrderList : array [TAutoOrderType] of TModifyOrderList;
    FAssets: TSPAssetArray;
    FBasePosQty: double;
    FOnQuoteNotify: TQuoteNotifiy;
    FNo: integer;

    procedure DoLog( stLog : string; bShow : boolean = false );
    procedure QuoteProc(Sender, Receiver: TObject; DataID: Integer;
                    DataObj: TObject; EventID: TDistributorID);

    procedure TradeProc(Sender, Receiver: TObject; DataID: Integer;
                    DataObj: TObject; EventID: TDistributorID);
    procedure OnOrder( aOrder : TOrder; iEventID : integer );
    procedure OnFill( aOrder : TOrder );

    procedure OnDelayTimer(Sender:TObject);
    procedure OnQuote( aSymbol : TSymbol );

    function IsRun : boolean;

    procedure CalcSPValue;
    procedure SetParam(const Value: TSPParam);

    procedure OnPave(bEntry: boolean);
    procedure OnEntry;
    procedure OnWatchEntryOrder;
    function CheckEntryLimit : boolean;

    procedure OnLiquid;
    procedure OnWatchLiquidOrder;
    function CheckLiquidLimit: boolean;

    function GetMajorBasePrice( bEntry : boolean ): TMarketDepth;
    function GetSubCompPrice(bEntry : boolean ) : double;
    function GetSubEntryPrice(dTargetPrice, dBasePrice: double; var dEntryPrice : double): boolean;
    function GetSubLiquidPrice(dTargetPrice, dBasePrice: double; var dLiqPrice: double): boolean;

    function DoOrder( aAcnt : TAccount; aSymbol : TSymbol; iSide : integer;
        dPrice : double; dOrderVol : double; bEntry : boolean ) : TOrder;
    function SetPrice(bEntry: boolean): boolean;
    function CheckPositionLimit(bEntry:boolean): boolean;

    procedure OnOrderUnitLog (Sender: TObject; Value: String);
    procedure CheckAutoPutOrder(aType : TAutoOrderType; aOrder: TOrder);
    procedure SetReady(aType: TAutoOrderType; bValue: boolean);

    procedure OnModifyOrderLog(Sender: TObject; Value: String);
    function GetTradeRate: double;
    function GetTradePL  : integer;
  public
    AccVolume: array [TSPType] of double;
    constructor Create( aColl : TCollection ); override;
    Destructor  Destroy; override;

    function Start : boolean;
    procedure Stop ;
    procedure Init( aItem : TSPParam ); overload;
    procedure Init( aSymbols : TSPSymbolArray;  aMsgQuotes : TMergedQuoteArray;
      aItem : TSPParam ); overload;
    procedure OnParam( aItem : TSPParam );

    procedure OnMajorQuote( aSymbol : TSymbol );
    procedure OnSubQuote( aSymbol : TSymbol );

    property Symbols : TSPSymbolArray read FSymbols;
    property Accounts: TSPAccountArray read FAccounts;
    property Positions: TSPPositionArray read FPositions;
    property MgQuotes: TMergedQuoteArray read FMgQuotes;
    property Assets : TSPAssetArray read FAssets;

    // 주문관리
    property OrderUnit  : TSPOrdUnitArray read FOrderUnit;
    property ModifyList : TList read FModifyList;

    property Run : boolean read FRun;
    property Param : TSPParam read FParam write SetParam;
    property SPValue : TSPArray read FSPValue;
    property Name : string read FName write FName;
    property No   : integer read FNo write FNo;

    // 모니터링용
    property BasePrice : TSPArray read FBasePrice;
    property TargetPrice : TSPArray read FTargetPrice;
    property OrderPrice: TSPArray read FOrderPrice;
    property CompPrice : TSPArray read FCompPrice;

    property TradeRate : double read GetTradeRate;
    property TradePL : integer read GetTradePL;
    property BasePosQty: double read FBasePosQty;

    property OnSPNotify : TTextNotifyEvent read FOnSPNotify write FOnSPNotify;
    property OnQuoteNofity : TQuoteNotifiy read FOnQuoteNotify write FOnQuoteNotify;
    // flag
    property Ready : TReadyArray read FReady write FReady;

  end;

  TSPOrders = class( TCollection )
  private
    FSelect: TSPOrder;
    function GetSPOrders(i: Integer): TSPOrder;
    procedure QuoteProc(Sender, Receiver: TObject; DataID: Integer;
      DataObj: TObject; EventID: TDistributorID);
  public
    constructor Create;
    destructor Destroy; override;

    function New( stCode : string ) : TSPOrder; overload;
    function New( idx : integer ) : TSPOrder; overload;
    function Find( stCode : string ) : TSPOrder;

    procedure init( aParam : TSPParam; aNotify : TTextNotifyEvent );

    property SPOrders[i : Integer] : TSPOrder read GetSPOrders; default;
    property Select : TSPOrder read FSelect write FSelect;
  end;

implementation

uses
  GApp, GLibs
  , Math
  , UConsts


  ;

{ TSPOrder }

procedure TSPOrder.CalcSPValue;
begin

  if CheckZero( FSymbols[spMajor].Bids[0].Price ) then
    FSPValue[aoEntry] := 0
  else
    FSPValue[aoEntry] := ( FSymbols[spSub].Last - FSymbols[spMajor].Bids[0].Price )
      / FSymbols[spMajor].Bids[0].Price;

  if CheckZero( FSymbols[spMajor].Asks[0].Price ) then
    FSPValue[aoExit] := 0
  else
    FSPValue[aoExit] := ( FSymbols[spSub].Last - FSymbols[spMajor].Asks[0].Price )
      / FSymbols[spMajor].Asks[0].Price;
end;

constructor TSPOrder.Create(aColl: TCollection);
var
  I: TSPType;
  j: TAutoOrderType;
begin
  inherited Create( aColl );

  FRun := false;

  for I := spMajor to High(TSPType) do
  begin
    FSymbols[i]   := nil;
    FAccounts[i]  := nil;

    FMgQuotes[i]  := TMergedQuote.Create;
    FPositions[i] := nil;//TSPPosition.Create( nil );
  end;

  for j := aoEntry to High(TAutoOrderType) do
  begin
    FTimer[j] := TTimer.Create(nil);
    FTimer[j].OnTimer  := OnDelayTimer;
    FTimer[j].Enabled  := false;
    FTimer[j].Tag      := integer(j);

    FOrderUnit[j] := TSpOrderUnit.Create;

    FModifyOrderList[j] := TModifyOrderList.Create;
  end;

end;

destructor TSPOrder.Destroy;
var
   I: TSPType;
   j: TAutoOrderType;
begin

  for j := aoEntry to High(TAutoOrderType) do
  begin
    FTimer[j].Free;
    FOrderUnit[j].Free;
    FModifyOrderList[j].Free;
  end;

  for I := spMajor to High(TSPType) do
  begin
    FMgQuotes[i].Free;
    FPositions[i].Free;
  end;

  inherited;
end;

procedure TSPOrder.DoLog(stLog: string; bShow : boolean );
begin
  App.Log( llInfo, FParam.Code + '_SP', '%s : %s', [FName, stLog]  );
  if bShow and  Assigned( FOnSPNotify) then
    FOnSPNotify( Self, stLog );
end;

function TSPOrder.DoOrder( aAcnt : TAccount; aSymbol : TSymbol; iSide: integer; dPrice: double;
  dOrderVol : double;  bEntry: boolean): TOrder;
  var
    stTmp : string;
//    dQty : double;
begin

  Result := nil;

  if (aAcnt=nil) or (aSymbol=nil)  then Exit;

  if IsZero(dPrice) or IsZero(dOrderVol) then
  begin
    DoLog( Format('%s wrong parameter %f, %f', [ ifThenStr( bEntry,'Entry','Liquid')
      , dPrice, dOrderVol ]));
    Exit;
  end;

  Result := App.Engine.TradeCore.Orders[ aSymbol.Spec.ExchangeType ].NewOrder(
    aAcnt, aSymbol, iSide, dOrderVol, pcLimit, dPrice, tmGTC
  );

  if bEntry then begin
    if iSide > 0 then
      stTmp := ExKindToStr( FParam.SubEx )
    else
      stTmp := ExKindToStr( FParam.MajorEx );
  end else
  begin
    if iSide < 0 then
      stTmp := ExKindToStr( FParam.SubEx	 )
    else
      stTmp := ExKindToStr( FParam.MajorEx );
  end;

  if Result <> nil then
  begin
    Result.StgType  := stSPOrder;
    Result.Entry    := bEntry;
    App.Engine.TradeBroker.Send(Result);

    DoLog( Format('%s %s 주문 : %s, %s, %s', [ stTmp, ifThenStr( bEntry,'Entry','Liquid'),
      Result.SideToStr, aSymbol.PriceToStr(dPrice), aSymbol.QtyToStr(dOrderVol) ]  ), true );
  end else
  begin
    DoLog( Format('%s %s %s 주문 생성 실패', [ stTmp, ifThenStr( bEntry, 'Entry','Liquid'),
      ifThenStr( iSide = 1, '매수','매도') ]), true ) ;
    Exit;
  end;
end;

procedure TSPOrder.Init( aItem : TSPParam );
var
  I: TSPType;
begin

  FSymbols[spMajor] := App.Engine.SymbolCore.BaseSymbols.FindSymbol(aItem.Code, aItem.MajorEx);
  FSymbols[spSub]   := App.Engine.SymbolCore.BaseSymbols.FindSymbol(aItem.Code, aItem.SubEx  );

  FAccounts[spMajor]  := App.Engine.TradeCore.FindAccount( aItem.MajorEx );
  FAccounts[spSub]    := App.Engine.TradeCore.FindAccount( aItem.SubEx );

  FMgQuotes[spMajor].SetSymbol( FSymbols[spMajor], aItem.HogaMergeUnit );
  FMgQuotes[spSub].SetSymbol( FSymbols[spSub], aItem.HogaMergeUnit );

  FBasePosQty := 0;
  for I := spMajor to High(TSPType) do
  begin
    if FPositions[i] <> nil then
      FPositions[i].Free;
    FPositions[i] := TSPPosition.Create(nil);
    FPositions[i].Account := FAccounts[i];
    FPositions[i].Symbol  := FSymbols[i];

    FOrderUnit[TAutoOrderType(i)].Init( OnOrderUnitLog, TAutoOrderType(i) = aoEntry );
    FReady[TAutoOrderType(i)] := false;

    if FAccounts[i] <> nil then begin
      FAssets[i]  := FAccounts[i].Assets.Find(aItem.Code);
      if FAssets[i] = nil then
        FAssets[i]  := FAccounts[i].Assets.New(aItem.Code, FAccounts[i]);
    end;

    AccVolume[i] := 0;

    FBasePosQty := FBasePosQty + FAssets[i].Balance;
  end;
  FParam  := aItem;
end;

procedure TSPOrder.Init(aSymbols: TSPSymbolArray; aMsgQuotes: TMergedQuoteArray;
  aItem: TSPParam);
var
  I: TSPType;
begin
  for I := spMajor to High(TSPType) do
  begin
    FSymbols[I] := aSymbols[I];
    FMgQuotes[i]:= aMsgQuotes[I];
  end;

  FAccounts[spMajor]  := App.Engine.TradeCore.FindAccount( aItem.MajorEx );
  FAccounts[spSub]    := App.Engine.TradeCore.FindAccount( aItem.SubEx );

  FBasePosQty := 0;

  FBasePosQty := 0;
  for I := spMajor to High(TSPType) do
  begin
    if FPositions[i] <> nil then
      FPositions[i].Free;
    FPositions[i] := TSPPosition.Create(nil);
    FPositions[i].Account := FAccounts[i];
    FPositions[i].Symbol  := FSymbols[i];

    FOrderUnit[TAutoOrderType(i)].Init( OnOrderUnitLog, TAutoOrderType(i) = aoEntry );
    FReady[TAutoOrderType(i)] := false;

    if FAccounts[i] <> nil then begin
      FAssets[i]  := FAccounts[i].Assets.Find(aItem.Code);
      if FAssets[i] = nil then
        FAssets[i]  := FAccounts[i].Assets.New(aItem.Code, FAccounts[i]);
    end;

    AccVolume[i] := 0;

    FBasePosQty := FBasePosQty + FAssets[i].Balance;
  end;

  FParam  := aItem;

end;

function TSPOrder.IsRun: boolean;
begin
  Result := false;

  if not FRun then Exit;
  if ( FSymbols[spMajor] = nil ) or ( FSymbols[spSub] = nil ) then Exit;
  if ( FAccounts[spMajor] = nil ) or ( FAccounts[spSub] = nil ) then Exit;

  Result := true;
end;

function TSPOrder.GetMajorBasePrice( bEntry : boolean ) : TMarketDepth;
var
  aDepths : TMarketDepths;
begin

  if FParam.UseHogaMerge then begin
    if bEntry then
      aDepths := FMgQuotes[spMajor].Bids
    else
      aDepths := FMgQuotes[spMajor].Asks;
  end else
  begin
    if bEntry then
      aDepths := FSymbols[spMajor].Bids//.GetBiggerDepth(FParam.MinVolume)
    else
      aDepths := FSymbols[spMajor].Asks;//.GetBiggerDepth(FParam.MinVolume);
  end;

  Result := aDepths.GetBiggerDepth(FParam.MinVolume);
end;

function TSPOrder.GetSubCompPrice(bEntry: boolean): double;
begin
  case FParam.BasePrice of
    0 : if bEntry then
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].Asks[0].Price, -FParam.BaseTick )
        else
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].Bids[0].Price, FParam.BaseTick );
    1 : if bEntry then
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].Last, -FParam.BaseTick )
        else
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].Last, FParam.BaseTick );
    2 : if bEntry then
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].Bids[0].Price, -FParam.BaseTick )
        else
          Result := TicksFromPrice( FSymbols[spSub], FSymbols[spSub].ASks[0].Price, FParam.BaseTick );
  end;
end;

function TSPOrder.GetSubEntryPrice( dTargetPrice, dBasePrice : double; var dEntryPrice : double ) : boolean;
var
  i : integer;
  dPrice : double;
begin
  Result := false;

  if dTargetPrice - DOUBLE_EPSILON > dBasePrice then begin
    dEntryPrice  := dBasePrice;
    Result       := true;
  end else
  begin
    i := 1;
    while (true) do
    begin
      dPrice  := TicksFromPrice( FSymbols[spSub], dBasePrice, -i );
      inc(i);
      if dTargetPrice - DOUBLE_EPSILON > dPrice then
      begin
        dEntryPrice := dPrice;
        Result      := true;
        break;
      end;
    end;
  end;
end;
                                                 // compPrice
function TSPOrder.GetSubLiquidPrice( dTargetPrice, dBasePrice : double; var dLiqPrice : double ) : boolean;
var
  i : integer;
  dPrice : double;
begin
  Result := false;

  if dTargetPrice < dBasePrice - DOUBLE_EPSILON then begin
    dLiqPrice  := dBasePrice;
    Result       := true;
  end else
  begin
    i := 1;
    while (true) do
    begin
      dPrice  := TicksFromPrice( FSymbols[spSub], dBasePrice, i );
      inc(i);
      // targetPrice 보다 큰 호가..
      //if dTargetPrice < dPrice - DOUBLE_EPSILON then
      if dTargetPrice - DOUBLE_EPSILON < dPrice  then
      begin
        dLiqPrice := dPrice;
        Result    := true;
        break;
      end;
    end;
  end;
end;

function TSPOrder.GetTradePL: integer;
var
  dTmp : double;
begin
  Result := 0;
  if (FPositions[spMajor] = nil) or (FPositions[spSub]=nil) then Exit;

  dTmp := (FPositions[spMajor].SellAmt + FPositions[spSub].SellAmt) -
              (FPositions[spMajor].BuyAmt + FPositions[spSub].BuyAmt) -
                (FPositions[spMajor].Fee + FPositions[spSub].Fee) ;

  Result := Round(dTmp / 10000);
end;

function TSPOrder.GetTradeRate: double;
var
  dVol : double;
begin
  Result := 0;
//  if (FPositions[spMajor] = nil) or (FPositions[spSub]=nil) then Exit;
//
//  dVol  := abs(FPositions[spMajor].Volume) + abs(FPositions[spSub].Volume);

  if CheckZero(FBasePosQty) then
    Exit
  else
    Result :=  AccVolume[spMajor] / FBasePosQty * 100;
end;



function TSPOrder.SetPrice( bEntry : boolean ) : boolean;
var
  aDepth : TMarketDepth;
  dOrdPrice, dCompPrice, dTargetPrice : double;
  aType : TAutoOrderType;
  iDelay : integer;
begin

  Result := false;

  // 시세 딜레이 3초 이상이면...Exit;
  iDelay := App.Engine.ApiManager.ExManagers[FParam.MajorEx].QuoteSock[0].DelaySec;
  if iDelay >= 3 then Exit;
  iDelay := App.Engine.ApiManager.ExManagers[FParam.SubEx].QuoteSock[0].DelaySec;
  if iDelay >= 3 then Exit;


  aDepth := GetMajorBasePrice(bEntry);
  if aDepth = nil then Exit;

  if bEntry then
  begin
    dTargetPrice:= aDepth.Price * (1 + (FParam.EntryRate)/100);
    dCompPrice  := GetSubCompPrice(bEntry);

    if not GetSubEntryPrice( dTargetPrice, dCompPrice, dOrdPrice ) then
    begin
    //DoLog( Format(' not Found lesser than %s ', [ FSymbols[spSub].PriceToStr( dTargetPrice) ]));
      Exit;
    end;
    aType := aoEntry;
  end else
  begin
    dTargetPrice:= aDepth.Price * (1 + (FParam.LiquidRate)/100);
    dCompPrice  := GetSubCompPrice(bEntry);

    if not GetSubLiquidPrice( dTargetPrice, dCompPrice, dOrdPrice ) then
    begin
    //DoLog( Format(' not Found lesser than %s ', [ FSymbols[spSub].PriceToStr( dTargetPrice) ]));
      Exit;
    end;

    aType := aoExit;
  end;

  FTargetPrice[aType] := dTargetPrice;
  FBasePrice[aType] := aDepth.Price;
  FOrderPrice[aType]:= dOrdPrice;
  FCompPrice[aType] := dCompPrice;

  REsult := true;

end;

procedure TSPOrder.OnDelayTimer(Sender: TObject);
begin
  try
    FReady[ TAutoOrderType( (Sender as TComponent).Tag )] := false;
  finally
    (Sender as TTimer).Enabled := false;
  end;
end;

procedure TSPOrder.OnPave( bEntry : boolean );
var
  dTradeRate : double;
begin
  if not SetPrice(bEntry) then Exit;

  if GetTradePL < FParam.LimitPL then
  begin
    FRun := false;
    DoLog('--- Stop 손익 한도---', true);
    Exit;
  end;

  dTradeRate := GetTradeRate;
  if dTradeRate > FParam.LimitTradeAmt then
  begin
    FRun := false;
    DoLog( Format('--- Stop 회전율 한도 %.0f%% ---' , [dTradeRate]) , true);
    Exit;
  end;

  if bEntry then
    OnEntry
  else
    OnLiquid;
end;

procedure TSPOrder.OnEntry;
var
  i : integer;
//  dAvailable, dOrderAmt,
  dOrderPrice : double;
//  aAsset : TAsset;
begin

  if not CheckEntryLimit then
  begin
//    FRun := false;
    FParam.UseEntry := false;
    DoLog( '-- 진입 Stop ---' , true );
    Exit;
  end;

  for I := 0 to FParam.EntryCount-1 do
  begin
    var aOrder : TOrder;
    dOrderPrice := TicksFromPrice( FSymbols[spSub], FOrderPrice[aoEntry], -1*i*FParam.EntryTick );
    aOrder := DoOrder( FAccounts[spSub], FSymbols[spSub], 1, dOrderPrice, FParam.EntryQty, true );

    if aOrder <> nil then
      FOrderUnit[aoEntry].OrderList[spSub].Add( aOrder );
  end;

  if FOrderUnit[aoEntry].OrderList[spSub].Count > 0 then
  begin
    FOrderUnit[aoEntry].BasePrice     := FBasePrice[aoEntry] ;
    FOrderUnit[aoEntry].BasePriceStr  := FSymbols[spMajor].PriceToStr(FBasePrice[aoEntry]);

    FOrderUnit[aoEntry].OrderPrice    := FOrderPrice[aoEntry];
    FOrderUnit[aoEntry].OrderPriceStr := FSymbols[spSub].PriceToStr(FOrderPrice[aoEntry]);

    FReady[aoEntry] := true;
  end;
end;

procedure TSPOrder.OnLiquid;
var
  i : integer;
  dAvailable, dOrdQty , dOrderPrice : double;
  aAsset : TAsset;
begin

  if not CheckLiquidLimit then
  begin
    FParam.UseLiquid := false;
    DoLog( '-- 청산 Stop ---' , true );
    Exit;
  end;

  for I := 0 to FParam.LiquidCount-1 do
  begin
    var aOrder : TOrder;
    dOrderPrice := TicksFromPrice( FSymbols[spSub], FOrderPrice[aoExit], i*FParam.LiquidTick );
    aOrder := DoOrder( FAccounts[spSub], FSymbols[spSub], -1, dOrderPrice, FParam.LiquidQty, false );

    if aOrder <> nil then
      FOrderUnit[aoExit].OrderList[spSub].Add( aOrder );
  end;

  if FOrderUnit[aoExit].OrderList[spSub].Count > 0 then
  begin
    FOrderUnit[aoExit].BasePrice     := FBasePrice[aoExit] ;
    FOrderUnit[aoExit].BasePriceStr  := FSymbols[spMajor].PriceToStr(FBasePrice[aoExit]);

    FOrderUnit[aoExit].OrderPrice    := FOrderPrice[aoExit];
    FOrderUnit[aoExit].OrderPriceStr := FSymbols[spSub].PriceToStr(FOrderPrice[aoExit]);

    FReady[aoExit] := true;
  end;

end;


procedure TSPOrder.OnWatchEntryOrder;
var
  stPrice: string;
begin
  if not SetPrice(true) then Exit;

  stPrice := FSymbols[spMajor].PriceToStr( FBasePrice[aoEntry] );
  if stPrice = FOrderUnit[aoEntry].BasePriceStr then Exit;

  stPrice := FSymbols[spSub].PriceToStr( FOrderPrice[aoEntry] );
  if stPrice = FOrderUnit[aoEntry].OrderPriceStr then Exit;

  if FOrderUnit[aoEntry].BasePrice - EPSILON > FBasePrice[aoEntry] then begin
    // 기준가 하락.
    //DoLog( Format('Entry Orders 기준가하락에 의한 취소 %s --> %s', [ FOrderUnit[aoEntry].BasePriceStr, stPrice ]), true);
    FOrderUnit[aoEntry].DoCancelOrder;
  end
  else if FBasePrice[aoEntry] - EPSILON > FOrderUnit[aoEntry].BasePrice then begin
    // 기준가 상승.
    //DoLog( Format('Entry Orders 기준가상승에 의한 취소 %s --> %s', [ FOrderUnit[aoEntry].BasePriceStr, stPrice ]), true);
    FOrderUnit[aoEntry].DoCancelOrder;
  end else
    Exit;
end;

procedure TSPOrder.OnWatchLiquidOrder;
var
  stPrice: string;
begin
  if not SetPrice(false) then Exit;

  stPrice := FSymbols[spMajor].PriceToStr( FBasePrice[aoExit] );
  if stPrice = FOrderUnit[aoExit].BasePriceStr then Exit;
  stPrice := FSymbols[spSub].PriceToStr( FOrderPrice[aoExit] );
  if stPrice = FOrderUnit[aoExit].OrderPriceStr then Exit;

  if FOrderUnit[aoExit].BasePrice - EPSILON > FBasePrice[aoExit] then begin
    // 기준가 하락.
    //DoLog( Format('Exit Orders 기준가하락에 의한 취소 %s --> %s', [ FOrderUnit[aoExit].BasePriceStr, stPrice ]), true);
    FOrderUnit[aoExit].DoCancelOrder;
  end
  else if FBasePrice[aoExit] - EPSILON > FOrderUnit[aoExit].BasePrice then begin
    // 기준가 상승.
    //DoLog( Format('Exit Orders 기준가상승에 의한 취소 %s --> %s', [ FOrderUnit[aoExit].BasePriceStr, stPrice ]), true);
    FOrderUnit[aoExit].DoCancelOrder;
  end else
    Exit;
end;

procedure TSPOrder.OnMajorQuote(aSymbol: TSymbol);
begin

  if not IsRun then Exit;

  if FParam.UseEntry then begin
    if not FReady[aoEntry] then
      OnPave(true)
    else
      OnWatchEntryOrder;
  end;

  // 청산
  if FParam.UseLiquid then begin
    if not FReady[aoExit] then
      OnPave(false)
    else
      OnWatchLiquidOrder;
  end;

  if Assigned(FOnQuoteNotify) then
    FOnQuoteNotify(Self, spMajor);

end;

procedure TSPOrder.OnSubQuote(aSymbol: TSymbol);
begin
  if not IsRun then Exit;
  // 진입
//  if not FReady[aoEntry] then
//    OnEntry
//  else
//    OnWatchEntryOrder;
  if Assigned(FOnQuoteNotify) then
    FOnQuoteNotify(Self, spSub);
end;

procedure TSPOrder.OnModifyOrderLog(Sender: TObject; Value: String);
begin
  DoLog( Value, true );
end;

procedure TSPOrder.CheckAutoPutOrder( aType : TAutoOrderType; aOrder : TOrder );
var
  i : integer;
  ord : TOrder;
begin
  for I := 0 to FOrderUnit[aType].OrderList[spSub].Count-1 do
  begin
    ord := FOrderUnit[aType].OrderList[spSub].Orders[i];
    if ord = aOrder then
      if ( ord.OrderType = otCancel ) and ( ord.State = osCanceled ) then
      begin
        FOrderUnit[aType].OrderList[spSub].Delete(i);
        break;
      end;
  end;

  FOrderUnit[aType].CheckOrderList(spSub);

  if FOrderUnit[aType].OrderList[spSub].Count <= 0 then
  begin
//    FReady[aType] := false;
    SetReady(aType, false );
    DoLog( '전체취소 -> Re ' + IfThenStr(aType=aoEntry,'Entry', 'Liquid'), true );
  end;
end;

function TSPOrder.CheckEntryLimit: boolean;
var
  aAsset : TAsset;
  dAvailable, dOrderPrice, dOrderAmt, dQty : double;
  i : integer;
  stLog : string;
begin
  Result := false;

  try
    // 메인 매도 주문이니 잔고 가 있어야 한다..
    aAsset  := FAssets[spMajor];// FAccounts[spMajor].Assets.Find(FParam.Code);
    if aAsset = nil then begin stLog :='Entry : 주거래소 매도 잔고없음'; Exit; end;
    if aAsset.Balance < FParam.EntryQty * FParam.EntryCount then begin
      stLog := 'Entry : 주거래소 매도 잔고 부족';
      Exit;
    end;

    // 서브 거래서 잔고 한도 체크..
    aAsset  := FAssets[spSub];// FAccounts[spSub].Assets.Find(FParam.Code);
    if aAsset = nil then
      aAsset  := FAccounts[spSub].Assets.New( FParam.Code, FAccounts[spSub] );

    // 매수잔고 + 미체결주문 + 나가야할주문 > 매수잔고 한도
    dQty  := App.Engine.TradeCore.Orders[FAccounts[spSub].ExchangeKind].GetActiveOrderQty(FAccounts[spSub], FSymbols[spSub], 1);
    if aAsset.Balance + dQty + (FParam.EntryQty * FParam.EntryCount) >= FParam.LimitSubPos then
    begin
      stLog := 'Entry : 서브거래소 포지션 한도';
      Exit;
    end;

    // 주문가능금액 체크   ( 잔고 - 미체결주문금액 - 미접수주문금액 )
    dAvailable  := FAccounts[spSub].Asset.Balance - FAccounts[spSub].Asset.Locked - //  aAsset.Balance - aAsset.Locked -
      App.Engine.TradeCore.Orders[FAccounts[spSub].ExchangeKind].GetUnAcceptOrderAmt(FAccounts[spSub], FSymbols[spSub], 1);
    //dOrderAmt := FBasePrice[aoEntry] * FParam.EntryQty * FParam.EntryCount;
    dOrderAmt := 0;
    for I := 0 to FParam.EntryCount-1 do
    begin
      dOrderPrice := TicksFromPrice( FSymbols[spSub], FOrderPrice[aoEntry], i*FParam.EntryTick );
      dOrderAmt   := dOrderAmt + ( dOrderPrice * FParam.EntryQty );
    end;

    if dAvailable < dOrderAmt then
    begin
      stLog := 'Entry : 서브거래소 주문가능 금액 부족';
      Exit;
    end;

    Result := true;
  finally
    if not Result then
      DoLog( stLog , true );
  end;
end;

function TSPOrder.CheckLiquidLimit: boolean;
var
  aAsset : TAsset;
  dAvailable, dOrderPrice, dOrderAmt, dQty : double;
  i : integer;
  stLog : string;
begin
  Result := false;

  try
    // 서브 매도 주문이니 잔고 가 있어야 한다..
    aAsset  := FAssets[spSub];//FAccounts[spSub].Assets.Find(FParam.Code);
    if aAsset = nil then begin stLog := 'Liquid : 서브거래소 매도 잔고 없음'; Exit; end;
    if aAsset.Balance < FParam.LiquidQty * FParam.LiquidCount then begin
      stLog := 'Liquid : 서브거래소 매도 잔고 부족';
      Exit;
    end;

    // 메인 거래서 잔고 한도 체크..
    aAsset  := FAssets[spMajor];//FAccounts[spMajor].Assets.Find(FParam.Code);
    if aAsset = nil then
      aAsset := FAccounts[spMajor].Assets.New(FParam.Code,FAccounts[spMajor]);

    dQty  := App.Engine.TradeCore.Orders[FAccounts[spMajor].ExchangeKind].GetActiveOrderQty(FAccounts[spMajor], FSymbols[spMajor], 1);
    if aAsset.Balance + dQty + (FParam.LiquidQty * FParam.LiquidCount)  >= FParam.LimitMajorPos then
    begin
      stLog := 'Liquid : 주거래소 포지션 한도';
      Exit;
    end;

    dAvailable  := FAccounts[spMajor].Asset.Balance - FAccounts[spMajor].Asset.Locked - //aAsset.Balance - aAsset.Locked -
      App.Engine.TradeCore.Orders[FAccounts[spMajor].ExchangeKind].GetUnAcceptOrderAmt(FAccounts[spMajor], FSymbols[spMajor], 1);
    dOrderAmt := FBasePrice[aoExit] * FParam.LiquidQty * FParam.LiquidCount;
    if dAvailable < dOrderAmt then
    begin
      stLog := 'Liquid : 주거래소 주문가능 금액 부족';
      Exit;
    end;

    Result := true;
  finally
    if not Result then
      DoLog(stLog, true );
  end;
end;

function TSPOrder.CheckPositionLimit(bEntry: boolean): boolean;
var
  aAsset : TAsset;
  sSell, sBuy : TSPType;
  dAvailable, dOrderAmt : double;
  i, j : integer;
begin

  Result := false;

  if bEntry then
  begin
    // 매도                   // 매수
    sSell := spMajor;        sBuy := spSub;

  end else
  begin
    // 매도                   // 매수
    sSell := spSub;          sBuy := spMajor;
  end;

  // 메인 매도 주문이니 잔고 가 있어야 한다..
  aAsset  := FAccounts[sSell].Assets.Find(FParam.Code);
  if aAsset = nil then Exit;

  if aAsset.Balance < FParam.EntryQty * FParam.LiquidCount then
    Exit;

  // 서브 거래서 잔고 한도 체크..
  aAsset  := FAccounts[sBuy].Assets.Find(FParam.Code);
  if aAsset = nil then Exit;
  // 매수잔고 한도
  if aAsset.Balance >= FParam.LimitSubPos then Exit;
  // 주문가능금액 체크   ( 잔고 - 미체결주문금액 - 미접수주문금액 )
  dAvailable  := aAsset.Balance - aAsset.Locked -
    App.Engine.TradeCore.Orders[FAccounts[sBuy].ExchangeKind].GetUnAcceptOrderAmt(FAccounts[sBuy], FSymbols[sBuy], 1);
  if dAvailable < (FParam.EntryQty * FParam.LiquidCount) then Exit;

  Result := true;

end;

procedure TSPOrder.SetReady( aType : TAutoOrderType; bValue : boolean) ;
begin
  if FParam.UseMdodifyDelay then
  begin
    FTimer[aType].Interval  := FParam.ModifyDelaySec * 1000;
    FTimer[aType].Enabled := true
  end
  else
    FReady[aType] := bValue;
end;

procedure TSPOrder.OnOrder(aOrder: TOrder; iEventID : integer);
var
  dPrice : double;
  iTick  : integer;
  aNewOrder : TOrder;
  aModOrder : TAutoModifyOrder;
begin
  if not (aOrder.StgType in [stSPOrder])  then Exit;

  // 매수, 매도, 종목에 따라 처리 분기
  if aOrder.Symbol = FSymbols[spMajor] then
  begin
    var aType : TAutoOrderType;
    if aOrder.Side > 0 then
      aType := aoExit
    else
      aType := aoEntry;

    case aOrder.OrderType of
      otNormal:
        case aOrder.State of
          osActive:
            begin
            //  FModifyOrderList[aoEntry].New( FParam, OnModifyOrderLog ).SetOrder( aOrder, true )  ;
            end;
          osSrvRjt,
          osRejected:
            begin
              DoLog( Format('주거래소%s 주문 거부 : %s, %s, %s, %s', [ aOrder.OrderTypeToStr,
                ifThenStr(aType=aoEntry,'Entry','Liquid'),
                ifThenStr(aOrder.Side >0 , '매수','매도'), aOrder.Symbol.PriceToStr( aOrder.Price ),
                aOrder.Symbol.QtyToStr( aOrder.OrderQty ) ] ), true);
                // 거부면 어떻게 하지?...
            end;
        end;

      otCancel:
        if aOrder.State = osCanceled then
        begin
          aModOrder := FModifyOrderList[aType].Find(aOrder);
          if aModOrder <> nil then
          begin
            iTick := ifThen( aModOrder.Count < FParam.AutoModifyCount, FParam.AutoModifyTick, FParam.AutoModifyLastTick );
            if aType = aoEntry then
              iTick := iTick * -1;
            dPrice:= TicksFromPrice( aOrder.Symbol, aOrder.Price, iTick);
            aNewOrder := DoOrder( aOrder.Account, aOrder.Symbol, aOrder.Side, dPrice, aOrder.CanceledQty, aType = aoEntry);
            if aNewOrder <> nil then begin
              FOrderUnit[aType].OrderList[spMajor].Add( aNewOrder );
              aModOrder.SetOrder( aNewOrder, true);
//              FModifyOrderList[aType].New( FParam, OnModifyOrderLog ).SetOrder( aNewOrder, true )  ;
            end;
          end;
        end;
    end;


  end else
  if aOrder.Symbol = FSymbols[spSub] then
  begin
    if aOrder.Side > 0  then begin
      // 진입...까는 주문
      CheckAutoPutOrder( aoEntry, aOrder );
    end else
    begin
      // 청산...까는 주문
      CheckAutoPutOrder( aoExit, aOrder );
    end;
  end
  else
    Exit;
end;

procedure TSPOrder.OnFill(aOrder: TOrder);
var
  ord, newOrd : TOrder;
  i   : integer;
  aType : TAutoOrderType;
  sType : TSPType;
begin
  if not (aOrder.StgType in [stSPOrder])  then Exit;
  // 매수, 매도, 종목에 따라 처리 분기
  if aOrder.Symbol = FSymbols[spMajor] then
  begin
    if aOrder.Side > 0  then begin
      // 청산...치는 주문
      aType := aoExit;
    end else
    begin
      // 진입.. 치는 주문
      aType := aoEntry;
    end;
    sType := spMajor;
  end
  else if aOrder.Symbol = FSymbols[spSub] then
  begin
    if aOrder.Side > 0  then begin
      // 진입...까는 주문
      //CheckAutoPutOrder( aoEntry, aOrder );
      aType := aoEntry;
    end else
    begin
      // 청산...까는 주문
      //CheckAutoPutOrder( aoExit, aOrder );
      aType := aoExit;
    end;
    sType := spSub;
  end else
    Exit;

  ord := FOrderUnit[aType].OrderList[sType].FindOrder( aOrder.OrderNo );
  if ord = nil then Exit;

  // 서브거래소 주문이 체결 되면..주거래소로 주문.
  with ord.Fills do
  begin
    DoLog( Format('%s %s 주문 체결: %s, %s, %s', [ ExKindToStr( aOrder.Account.ExchangeKind),
      ifThenStr(aType=aoEntry,'Entry','Liquid'),   ifThenStr(LastFill.Side >0 , '매수','매도'),
      aOrder.Symbol.PriceToStr( LastFill.Price ),   aOrder.Symbol.QtyToStr( LastFill.Volume )
     ] ), true);

    // 주거래소로 주문..
    if sType = spSub then begin
      newOrd  := DoOrder( FAccounts[spMajor], FSymbols[spMajor],  ifThen(aType=aoEntry,-1,1),
          FBasePrice[aType], LastFill.Volume, true );
          //FSymbols[spMajor].Asks[3].Price, LastFill.Volume, true );
      if newOrd <> nil then begin
        FOrderUnit[aType].OrderList[spMajor].Add( newOrd );
        FModifyOrderList[aType].New( FParam, OnModifyOrderLog ).SetOrder( newOrd, true )  ;
      end;
    end;

    // 주거래소 누적 거래량.
    if sType = spMajor then
      AccVolume[sType] := AccVolume[sType] + LastFill.Volume;
  end;

  FOrderUnit[aType].CheckOrderList(sType);

  if FOrderUnit[aType].OrderList[spSub].Count <= 0 then
  begin
    SetReady(aType, false );
    //FReady[aType] := false;
    DoLog( '전량 체결 - > Re ' + IfThenStr(aType=aoEntry,'Entry', 'Liquid'),true );
  end;



  if FPositions[sType] = nil then Exit;

  FPositions[sType].AddFill( ord.Fills.LastFill );

end;

procedure TSPOrder.OnOrderUnitLog(Sender: TObject; Value: String);
begin
  DoLog( Value, true );
end;

procedure TSPOrder.OnParam(aItem: TSPParam);
begin
  FParam  := aItem;

  if FSymbols[spMajor] <> nil then
    FMgQuotes[spMajor].SetSymbol( FSymbols[spMajor], aItem.HogaMergeUnit );

  if FSymbols[spSub] <> nil then
    FMgQuotes[spSub].SetSymbol( FSymbols[spSub], aItem.HogaMergeUnit );
end;

procedure TSPOrder.OnQuote(aSymbol: TSymbol);
begin
  if not IsRun then Exit;

  CalcSPValue;

  if aSymbol = FSymbols[spMajor] then
    OnMajorQuote( aSymbol )
  else if aSymbol = FSymbols[spSub] then
    OnSubQuote( aSymbol );

end;

procedure TSPOrder.QuoteProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin
  if (Self <> Receiver ) or (DataObj = nil ) then Exit;

  OnQuote(( DataObj as TQuote).Symbol );
end;

procedure TSPOrder.SetParam(const Value: TSPParam);
begin
  FParam := Value;
end;

function TSPOrder.Start: boolean;
begin

  if ( FSymbols[spMajor] = nil ) or ( FSymbols[spSub] = nil ) then Exit (false);
  if ( FAccounts[spMajor] = nil ) or ( FAccounts[spSub] = nil ) then Exit (false);

  FRun  := true;

//  App.Engine.QuoteBroker.Brokers[FParam.MajorEx].Subscribe( Self, FSymbols[spMajor], QuoteProc);
//  App.Engine.QuoteBroker.Brokers[FParam.SubEx].Subscribe( Self, FSymbols[spSub], QuoteProc);
//
//  App.Engine.TradeBroker.Subscribe( Self, TradeProc );

  Result := true;

  DoLog('Start', true);
end;

procedure TSPOrder.Stop;
begin
  FRun  := false;

  FOrderUnit[aoEntry].DoCancelOrder;
  FOrderUnit[aoExit].DoCancelOrder;

//  App.Engine.QuoteBroker.Cancel( Self );
//  App.Engine.TradeBroker.Unsubscribe(Self );

  DoLog('Stop', true);
end;

procedure TSPOrder.TradeProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin

  if not IsRun then Exit;

  if ( Receiver <> Self ) or ( DataObj = nil ) then Exit;

  case Integer(EventID) of
    ORDER_ACCEPTED,
    ORDER_REJECTED,
    ORDER_CANCELED : OnOrder(DataObj as TOrder, Integer(EventID) );
    ORDER_FILLED: OnFill(DataObj as TOrder);

//    POSITION_UPDATE : OnPosition( DataObj as TPosition);
  end;
end;

{ TSPOrders }

constructor TSPOrders.Create;
begin
  inherited Create( TSPOrder );

  FSelect := nil;
end;

destructor TSPOrders.Destroy;
begin

  inherited;
end;

function TSPOrders.Find(stCode: string): TSPOrder;
var
  I: Integer;
  aSP : TSPOrder;
begin
  Result := nil;
  for I := 0 to Count-1 do
  begin
    aSP := GetSPOrders(i);
    if (aSP <> nil) and ( aSP.Name = stCode ) then
    begin
      Result := aSP;
      break;
    end;
  end;
end;

function TSPOrders.GetSPOrders(i: Integer): TSPOrder;
begin
  if (i < 0 ) or ( i >= Count )  then
    Result := nil
  else
    Result := Items[i] as TSPOrder;
end;

procedure TSPOrders.init(aParam: TSPParam; aNotify: TTextNotifyEvent);
var
  i : Integer;
begin
  for I := 0 to Count-1 do begin
    GetSPOrders(i).Init( aParam);
    GetSPOrders(i).OnSPNotify := aNotify;
  end;
end;

function TSPOrders.New(idx: integer): TSPOrder;
begin
  Result := Add as TSPOrder;
  Result.No := idx;
  Result.Name := Format('SP_%03d', [ idx ] );
end;

function TSPOrders.New(stCode: string): TSPOrder;
begin
  Result := Add as TSPOrder;
  Result.Name   := stCode;
end;

procedure TSPOrders.QuoteProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin

end;

end.
