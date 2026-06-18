unit UQuoteMerge;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,  System.Generics.Defaults,

  USymbols, UQuoteBroker

  ;

const
  BID = 0;
  ASK = 1;

type
   TDepthSide = (dsBid, dsAsk);

  TMergedQuote = class
  private
    FSymbol: TSymbol;
    FBids: TMarketDepths;
    FAsks: TMarketDepths;
    FMergeSize: integer;
    function OnMakeMergeQuote2(aSymbol: TSymbol): boolean;
    procedure AggregateDepthsToBucketReuse(const ASource: TMarketDepths;
      const ABucketSize: Double; const ASide: TDepthSide;
      ATarget: TMarketDepths);
  public
    Constructor Create( aSymbol : TSymbol; iSize : integer ); overload;
    Constructor Create; overload;
    Destructor  Destroy; override;

    procedure SetSymbol( aSymbol : TSymbol; iSize : integer );
    procedure OnQuote( aSymbol : TSymbol );
    function OnMakeMergeQuote(aSymbol : TSymbol) : boolean;

    function OnAggregateHoga(aSymbol: TSymbol; ABucketSize: Double): boolean;

    property Symbol : TSymbol read FSymbol;
    property Asks : TMarketDepths read FAsks;
    property Bids : TMarketDepths read FBids;
    property MergeSize : integer read FMergeSize;
  end;


implementation

uses
  System.Math, System.Types
  , USymbolCore
  , UApiTypes
  , UTypes
  , GApp
  ;

{ TMergedQuote }

function PriceToBucketIndex(const APrice, ABucketSize: Double): Int64;
var
  x: Double;
begin
  if ABucketSize <= 0 then
    raise Exception.Create('Bucket size must be > 0');
  x := APrice / ABucketSize;
  Result := Trunc(Floor(x));  // 항상 아래로
end;

function BucketIndexToPrice(const AIndex: Int64; const ABucketSize: Double): Double;
begin
  Result := AIndex * ABucketSize;
end;

procedure SortDepthsByPrice(const ADepths: TMarketDepths; const ASide: TDepthSide);
var
  arr: TArray<TMarketDepth>;
  i: Integer;
begin
  SetLength(arr, ADepths.Size);
  for i := 0 to ADepths.Size - 1 do
    arr[i] := ADepths[i];

  TArray.Sort<TMarketDepth>(arr,
    TComparer<TMarketDepth>.Construct(
      function(const L, R: TMarketDepth): Integer
      begin
        case ASide of
          dsBid: Result := -CompareValue(L.Price, R.Price); // Bid: 높은 가격 위
        else
          Result :=  CompareValue(L.Price, R.Price);        // Ask: 낮은 가격 위
        end;
      end));

  for i := 0 to High(arr) do
    arr[i].Index := i;
end;


constructor TMergedQuote.Create(aSymbol: TSymbol; iSize: integer);
begin

end;

constructor TMergedQuote.Create;
begin
  FSymbol := nil;
  FAsks := TMarketDepths.Create(0);
  FBids := TMarketDepths.Create(0);

  FMergeSize  := 0;
end;

destructor TMergedQuote.Destroy;
begin

  FAsks.Free;
  FBids.Free;

  inherited;
end;

function TMergedQuote.OnMakeMergeQuote2(aSymbol: TSymbol) : boolean;
var
  dUnit, dBidAccVol, dAskAccVol, dBidPrice, dAskPrice, dPow : double;
  i, jB, jA, iLoop, iPre, iUnit, iPrice, iMod : Integer;
  aDepth : TMarketDepth;
  res : TValueRelationship;
  bResult, bRes, bBidBreak, bAskBreak : boolean;

  procedure Add( dPrice, dVol : double; iDiv : integer );
  begin
    if iDiv = 0 then
      aDepth := FBids.Add as TMarketDepth
    else
      aDepth := FAsks.Add as TMarketDepth;

    aDepth.Price  := dPrice;
    aDepth.Volume := dVol;
  end;
begin

  try

    dUnit     := FMergeSize * UnitFromPrice( FSymbol, FSymbol.Last );
    JB := 0; jA := 0;

    dBidPrice := FSymbol.Bids[0].Price;
    dAskPrice := FSymbol.Asks[0].Price;

    if (dBidPrice < EPSILON) or (dASkPrice < EPSILON) then Exit;

    bBidBreak := false; bAskBreak := false;

    bRes := false;  i:= 0;
    while bRes = false do
    begin
      dBidPrice := TicksFromPrice( aSymbol, dBidPrice, i );
      i := -1;

      iPre  := GetPrecision( aSymbol, dBidPrice );
      dPow  := Power(10, iPre);
      dUnit := FMergeSize * UnitFromPrice( aSymbol, dBidPrice );
      iUnit := Round( dPow * dUnit );
      iPrice  := Round( dBidPrice * dPOw );

      iMod    := iPrice mod iUnit;
      bRes    := iMod = 0;


    end;

    bRes := false;  i:= 0;
    while bRes = false do
    begin
      dAskPrice := TicksFromPrice( aSymbol, dAskPrice, i );
      i := 1;

      iPre  := GetPrecision( aSymbol, dAskPrice );
      dPow  := Power(10, iPre);
      //iUnit := Round( dPow * FMergeSize * UnitFromPrice( aSymbol, dAskPrice ));

      dUnit := FMergeSize * UnitFromPrice( aSymbol, dAskPrice );
      iUnit := Round( dPow * dUnit );

      iPrice  := Round( dAskPrice * dPOw );

      iMod    := iPrice mod iUnit;
      bRes    := iMod = 0;

    end;

    FAsks.Clear;
    FBids.Clear;

    iLoop := 0;

    while true do
    begin

      inc(iLoop);

      if iLoop > 100 then
      begin
        bResult := false;
 //       break;
      end;

      // bids.....................................................................
  //    dMod := FMod(dBidPrice, dUnit);
  //    if IsZero(dMod) then
  //    begin
        dBidAccVol := 0;
        for I := jB to FSymbol.Bids.Count-1 do
        begin
          res := CompareValue( FSymbol.Bids[i].Price, dBidPrice ) ;
          if res >= 0 then
            dBidAccVol := dBidAccVol + FSymbol.Bids[i].Volume
          else begin
            if FSymbol.Bids[i].Price > 0 then
              break;
          end;
        end;
        jB := i;
        if dBidAccVol > 0 then
          Add( dBidPrice, dBidAccVol, BID );
  //    end;
      dBidPrice  := dBidPrice - dUnit;

      if (dBidAccVol = 0) and (jB >= FSymbol.Bids.Count-1) then
        bBidBreak := true;

      // asks.....................................................................
  //    dMod := FMod(dAskPrice, dUnit);
  //    if IsZero(dMod) then
  //    begin
        dAskAccVol := 0;
        for I := jA to FSymbol.Asks.Count-1 do
        begin
          res := CompareValue( dAskPrice, FSymbol.Asks[i].Price ) ;
          if res >= 0 then
            dAskAccVol := dAskAccVol + FSymbol.Asks[i].Volume
          else
            break;
        end;
        jA := i;
        if dAskAccVol > 0 then
          Add( dAskPrice, dAskAccVol, ASK );
  //    end;
      dAskPrice  := dAskPrice + dUnit;

      if (dAskAccVol = 0) and (jA >= FSymbol.Asks.Count-1) then
        bAskBreak := true;

      if bBidBreak and bAskBreak then
      begin
        bResult := true;
        Break;
      end;
    end;

  except
    bResult := false;
  end;

  Result := bResult;


end;


function TMergedQuote.OnAggregateHoga(aSymbol: TSymbol; ABucketSize: Double): boolean;
begin
  AggregateDepthsToBucketReuse(aSymbol.Asks, ABucketSize, dsAsk, FAsks);
  AggregateDepthsToBucketReuse(aSymbol.Bids, ABucketSize, dsBid, FBids);
end;

procedure TMergedQuote.AggregateDepthsToBucketReuse(const ASource: TMarketDepths;
  const ABucketSize: Double; const ASide: TDepthSide; ATarget: TMarketDepths);
var
  bucketMap : TDictionary<Int64,Integer>; // bucketIdx -> row index
  i, idx, usedCount: Integer;
  src : TMarketDepth;
  bucketIdx: Int64;
  d   : TMarketDepth;
begin
  if (ASource = nil) then Exit;
  if (ATarget = nil) then Exit;
  if (ABucketSize <= 0) then
    raise Exception.Create('Bucket size must be > 0');

  // 전체 통계 초기화
  ATarget.VolumeTotal := 0;
  ATarget.CntTotal    := 0;
  ATarget.RealVolSum  := 0;
  ATarget.RealCount   := 0;
  ATarget.RealTimeAvg := 0;

  // 기존 아이템들 내용만 초기화 (객체는 그대로 둠)
  for i := 0 to ATarget.Size - 1 do
  begin
    d := ATarget[i];
    d.Price  := 0;
    d.Volume := 0;
    d.Cnt    := 0;
  end;

  bucketMap := TDictionary<Int64,Integer>.Create;
  try
    usedCount := 0;

    for i := 0 to ASource.Size - 1 do
    begin
      src := ASource[i];
      if src.Volume = 0 then
        Continue;

      bucketIdx := PriceToBucketIndex(src.Price, ABucketSize);

      if not bucketMap.TryGetValue(bucketIdx, idx) then
      begin
        // 새로운 버켓 → 새 row 할당 (기존 아이템 재사용 우선)
        if usedCount < ATarget.Size then
          idx := usedCount
        else
        begin
          d := TMarketDepth(ATarget.Add);
          idx := d.Index;
        end;

        d := ATarget[idx];
        d.Price  := BucketIndexToPrice(bucketIdx, ABucketSize);
        d.Volume := 0;
        d.Cnt    := 0;

        bucketMap.Add(bucketIdx, idx);
        Inc(usedCount);
      end;

      d := ATarget[idx];
      d.Volume := d.Volume + src.Volume;
      d.Cnt    := d.Cnt    + src.Cnt;

      ATarget.VolumeTotal := ATarget.VolumeTotal + src.Volume;
      ATarget.CntTotal    := ATarget.CntTotal    + src.Cnt;
    end;

    // 남는 아이템(예전에 쓰던 버켓 수가 더 많았던 경우)은 잘라줌
    while ATarget.Size > usedCount do
      ATarget.Delete(ATarget.Size - 1);

    if ATarget.CntTotal > 0 then
    begin
      ATarget.RealVolSum  := Round(ATarget.VolumeTotal);
      ATarget.RealCount   := ATarget.CntTotal;
      ATarget.RealTimeAvg := ATarget.VolumeTotal / ATarget.CntTotal;
    end;

    SortDepthsByPrice(ATarget, ASide);
  finally
    bucketMap.Free;
  end;
end;

function TMergedQuote.OnMakeMergeQuote(aSymbol: TSymbol) : boolean;
var
  dUnit, dMod, dBidAccVol, dAskAccVol, dBidPrice, dAskPrice, dVol : double;
  i, jB, jA, iLoop : Integer;
  aDepth : TMarketDepth;
  res : TValueRelationship;
  bResult, bRes, bBidBreak, bAskBreak : boolean;

  procedure Add( dPrice, dVol : double; iDiv : integer );
  begin
    if iDiv = 0 then
      aDepth := FBids.Add as TMarketDepth
    else
      aDepth := FAsks.Add as TMarketDepth;

    aDepth.Price  := dPrice;
    aDepth.Volume := dVol;
  end;
begin

  if ( FSymbol = nil ) or ( aSymbol <> FSymbol ) then Exit (false);

  Result := OnMakeMergeQuote2( aSymbol );
  Exit;

  try

    dUnit     := FMergeSize * UnitFromPrice( FSymbol, FSymbol.Last );
    JB := 0; jA := 0;

    dBidPrice := FSymbol.Bids[0].Price;
    dAskPrice := FSymbol.Asks[0].Price;

    bBidBreak := false; bAskBreak := false;

    bRes := false;  i:= 0;
    while bRes = false do
    begin
      dBidPrice := TicksFromPrice( aSymbol, dBidPrice, i );
      i := -1;
      dMod := FMod(dBidPrice, dUnit);
      bRes := IsZero(dMod);
    end;

    bRes := false;  i:= 0;
    while bRes = false do
    begin
      dAskPrice := TicksFromPrice( aSymbol, dAskPrice, i );
      i := 1;
      dMod := FMod(dAskPrice, dUnit);
      bRes := IsZero(dMod);
    end;

    FAsks.Clear;
    FBids.Clear;

    iLoop := 0;

    while true do
    begin

      inc(iLoop);

      if iLoop > 100 then
      begin
        bResult := false;
 //       break;
      end;

      // bids.....................................................................
  //    dMod := FMod(dBidPrice, dUnit);
  //    if IsZero(dMod) then
  //    begin
        dBidAccVol := 0;
        for I := jB to FSymbol.Bids.Count-1 do
        begin
          res := CompareValue( FSymbol.Bids[i].Price, dBidPrice ) ;
          if res >= 0 then
            dBidAccVol := dBidAccVol + FSymbol.Bids[i].Volume
          else begin
            if FSymbol.Bids[i].Price > 0 then
              break;
          end;
        end;
        jB := i;
        if dBidAccVol > 0 then
          Add( dBidPrice, dBidAccVol, BID );
  //    end;
      dBidPrice  := dBidPrice - dUnit;

      if (dBidAccVol = 0) and (jB >= FSymbol.Bids.Count-1) then
        bBidBreak := true;

      // asks.....................................................................
  //    dMod := FMod(dAskPrice, dUnit);
  //    if IsZero(dMod) then
  //    begin
        dAskAccVol := 0;
        for I := jA to FSymbol.Asks.Count-1 do
        begin
          res := CompareValue( dAskPrice, FSymbol.Asks[i].Price ) ;
          if res >= 0 then
            dAskAccVol := dAskAccVol + FSymbol.Asks[i].Volume
          else
            break;
        end;
        jA := i;
        if dAskAccVol > 0 then
          Add( dAskPrice, dAskAccVol, ASK );
  //    end;
      dAskPrice  := dAskPrice + dUnit;

      if (dAskAccVol = 0) and (jA >= FSymbol.Asks.Count-1) then
        bAskBreak := true;

      if bBidBreak and bAskBreak then
      begin
        bResult := true;
        Break;
      end;
    end;

  except
    bResult := false;
  end;

  Result := bResult;

end;

procedure TMergedQuote.OnQuote(aSymbol: TSymbol);
var
  aDepth : TMarketDepth;
  dUnit, dMod : double;
  dAccVol   : array [0..1] of double;
  dPrevMod  : array [0..1] of double;

  i : integer;

  procedure Add( dPrice, dVol : double; iDiv : integer );
  begin
    if iDiv = 0 then
      aDepth := FBids.Add as TMarketDepth
    else
      aDepth := FAsks.Add as TMarketDepth;

    aDepth.Price  := dPrice;
    aDepth.Volume := dVol;
  end;

begin

  if ( FSymbol = nil ) or ( aSymbol <> FSymbol ) then Exit;

  try
    FAsks.Clear;
    FBids.Clear;
    dMod  := 0;
    for I := 0 to 1 do
    begin
      dAccVol[i]  := 0;
      dPrevMod[i] := 0;
    end;

    dUnit := FMergeSize * UnitFromPrice( FSymbol, FSymbol.Last );

    for I := 0 to FSymbol.Bids.Count-1 do
    begin

      if ( i > 14 ) and ( aSymbol.Spec.ExchangeType = ekUpbit ) then break;
      // 매수..
      dMod  := FMod( FSymbol.Bids[i].Price, dUnit );

      if IsZero( dMod ) then begin
        dAccVol[BID]  := dAccVol[BID] + FSymbol.Bids[i].Volume;
        Add( FSymbol.Bids[i].Price, dAccVol[BID], BID );
        dAccVol[BID]  := 0;
      end else
      if ((dMod - dPrevMod[BID]) >= 0) and ( not IsZero(dPrevMod[BID])) then begin
        Add( FSymbol.Bids[i-1].Price, dAccVol[BID], 0 );
        dAccVol[BID]  := FSymbol.Bids[i].Volume;
      end else
      begin
        dAccVol[BID]  := dAccVol[BID] + FSymbol.Bids[i].Volume;

        var bNew : boolean; bNew := false;
        if (FSymbol.Spec.ExchangeType = ekUpbit) and (i = 14) then
          bNew := true
        else  if i = FSymbol.Bids.Count-1 then
          bNew := true;

        if bNew then
          Add( FSymbol.Bids[i].Price, dAccVol[BID], BID );
      end;
      dPrevMod[BID] := dMod;

      // 매도
      dMod  := FMod( FSymbol.Asks[i].Price, dUnit );
      if IsZero( dMod ) then begin
        dAccVol[ASK]  := dAccVol[ASK] + FSymbol.Asks[i].Volume;
        Add( FSymbol.Asks[i].Price, dAccVol[ASK], ASK );
        dAccVol[ASK]  := 0;
      end else
      if ((dPrevMod[ASK]-dMod) >= 0) and ( not IsZero(dPrevMod[ASK])) then begin
        Add( FSymbol.Asks[i-1].Price, dAccVol[ASK], ASK );
        dAccVol[ASK]  := FSymbol.Asks[i].Volume;
      end else
      begin
        dAccVol[ASK]  := dAccVol[ASK] + FSymbol.Asks[i].Volume;

        var bNew : boolean; bNew := false;
        if (FSymbol.Spec.ExchangeType = ekUpbit) and (i = 14) then
          bNew := true
        else  if i = FSymbol.Asks.Count-1 then
          bNew := true;

        if bNew then
          Add( FSymbol.Asks[i].Price, dAccVol[ASK], ASK );
      end;
      dPrevMod[ASK] := dMod;

    end;


//    for I := 0 to FSymbol.Asks.Count-1 do
//    begin
//      App.Log(llDebug, 'mgTest', '[%02d]:%s, %s', [i,
//        FSymbol.PriceToStr( FSymbol.Asks[i].Price ), FSymbol.QtyToStr( FSymbol.Asks[i].Volume) ] );
//    end;
//
//    for I := 0 to Asks.Count-1 do
//    begin
//      App.Log(llDebug, 'mgTest', '--- [%02d]:%s, %s', [i,
//        FSymbol.PriceToStr( Asks[i].Price ), FSymbol.QtyToStr( Asks[i].Volume) ] );
//    end;

  except
  end;
end;



procedure TMergedQuote.SetSymbol(aSymbol: TSymbol; iSize: integer);
begin
  FSymbol    := aSymbol;
  FMergeSize := iSize;

  FAsks.Clear;
  FBids.Clear;

//  OnQuote( aSymbol );
end;

end.
