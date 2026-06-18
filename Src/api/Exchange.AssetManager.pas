unit Exchange.AssetManager;

interface

uses
  System.Generics.Collections, System.SyncObjs, System.SysUtils, Exchange.Types;

type

  TAssetManager = class
  private
    FLock: TCriticalSection;
    { 모든 자산(KRW 및 코인 자산)을 심볼별로 관리하는 딕셔너리 }
    FAssets: TDictionary<string, TAssetStatus>;
    FPendingOrders: TDictionary<string, POrderReservation>;
    FStandardFeeRate: Double;

    { 내부 자산 상태 변경 함수 }
    procedure UpdateAsset(const ASymbol: string; ADeltaBalance, ADeltaLocked: Currency);
  public
    constructor Create(ADefaultFee: Double = 0.0005);
    destructor Destroy; override;

    { 주문 예약: 매수(KRW 차감) / 매도(코인 수량 차감) }
    procedure ReserveOrder(ASide: integer; const ASymbol, AIdentifier: string; APrice, AVolume: Double);

    { 주문 확인: 임시 ID를 실제 UUID로 교체 }
    procedure ConfirmOrder(const AIdentifier, AActualUUID: string);

    { 체결 처리: 매수/매도 방향별 자산 반환 및 잔고 변동 }
    procedure ProcessTrade(const AUUID: string; ATradePrice, ATradeVolume, APaidFee: Double);

    { 취소 처리: 예치금 복원 }
    procedure ProcessCancel(const AUUID: string);

    { 실제 데이터와 내부 동기화 }
    procedure SyncAsset(const ASymbol: string; AActualBalance, AActualLocked: Currency);

    { 특정 자산 상태 조회 }
    function GetAssetStatus(const ASymbol: string): TAssetStatus;
  end;

implementation

const
  VOLUME_EPSILON = 1E-8;

{ TAssetManager }

{ 주문 확인: 임시 ID(Identifier)를 실제 발급 UUID로 교체 }
procedure TAssetManager.ConfirmOrder(const AIdentifier, AActualUUID: string);
var
  Order: POrderReservation;
begin
  FLock.Enter;
  try
    if not FPendingOrders.TryGetValue(AIdentifier, Order) then
      raise Exception.CreateFmt('ConfirmOrder 실패: Identifier "%s"에 해당하는 주문 없음', [AIdentifier]);

    Order^.UUID := AActualUUID;
    FPendingOrders.ExtractPair(AIdentifier);
    FPendingOrders.Add(AActualUUID, Order);
  finally
    FLock.Leave;
  end;
end;

constructor TAssetManager.Create(ADefaultFee: Double);
begin
  FLock := TCriticalSection.Create;
  FAssets := TDictionary<string, TAssetStatus>.Create;
  FPendingOrders := TDictionary<string, POrderReservation>.Create;
  FStandardFeeRate := ADefaultFee;
end;

destructor TAssetManager.Destroy;
var
  Order: POrderReservation;
begin
  for Order in FPendingOrders.Values do
    Dispose(Order);
  FPendingOrders.Free;
  FAssets.Free;
  FLock.Free;
  inherited;
end;

procedure TAssetManager.UpdateAsset(const ASymbol: string; ADeltaBalance, ADeltaLocked: Currency);
var
  Status: TAssetStatus;
begin
  if not FAssets.TryGetValue(ASymbol, Status) then
  begin
    Status.Balance := 0;
    Status.Locked := 0;
  end;
  Status.Balance := Status.Balance + ADeltaBalance;
  Status.Locked := Status.Locked + ADeltaLocked;
  FAssets.AddOrSetValue(ASymbol, Status);
end;

procedure TAssetManager.ReserveOrder(ASide: integer; const ASymbol, AIdentifier: string; APrice, AVolume: Double);
var
  NewOrder: POrderReservation;
  ReservedQty: Currency;
  Status: TAssetStatus;
begin
  FLock.Enter;
  try
    if ASide > 0 then
    begin
      ReservedQty := (APrice * AVolume) * (1 + FStandardFeeRate);
      if FAssets.TryGetValue('KRW', Status) and (Status.Balance < ReservedQty) then
        raise Exception.CreateFmt('KRW 잔고 부족: 필요 %m, 가용 %m', [ReservedQty, Status.Balance]);
    end
    else
    begin
      ReservedQty := AVolume;
      if FAssets.TryGetValue(ASymbol, Status) and (Status.Balance < ReservedQty) then
        raise Exception.CreateFmt('%s 잔고 부족: 필요 %f, 가용 %m', [ASymbol, Double(ReservedQty), Status.Balance]);
    end;

    New(NewOrder);
    NewOrder^.Side := ASide;
    NewOrder^.Symbol := ASymbol;
    NewOrder^.Price := APrice;
    NewOrder^.OriginalVolume := AVolume;
    NewOrder^.RemainingVolume := AVolume;
    NewOrder^.StandardFeeRate := FStandardFeeRate;

    if ASide > 0 then
      UpdateAsset('KRW', -ReservedQty, ReservedQty)
    else
      UpdateAsset(ASymbol, -ReservedQty, ReservedQty);

    NewOrder^.ReservedAmount := ReservedQty;
    FPendingOrders.Add(AIdentifier, NewOrder);
  finally
    FLock.Leave;
  end;
end;

procedure TAssetManager.ProcessTrade(const AUUID: string; ATradePrice, ATradeVolume, APaidFee: Double);
var
  Order: POrderReservation;
  ReservedPart, ActualKRW, RefundKRW: Currency;
begin
  FLock.Enter;
  try
    if FPendingOrders.TryGetValue(AUUID, Order) then
    begin
      if Order^.Side > 0 then
      begin
        { [매수 체결 처리] }
        ReservedPart := (Order^.Price * ATradeVolume) * (1 + Order^.StandardFeeRate);
        ActualKRW := (ATradePrice * ATradeVolume) + APaidFee;
        RefundKRW := ReservedPart - ActualKRW;

        // 1. KRW 잠금: 예약 분 풀고, 차액(환불분)은 Balance로
        UpdateAsset('KRW', RefundKRW, -ReservedPart);
        // 2. 코인 획득: 체결된 수량만큼 코인 Balance 증가
        UpdateAsset(Order^.Symbol, ATradeVolume, 0);
      end
      else
      begin
        { [매도 체결 처리] }
        // 1. 코인 차감: 잠겨있는 코인 수량 차감
        UpdateAsset(Order^.Symbol, 0, -ATradeVolume);
        // 2. KRW 획득: 매도 대금에서 수수료를 뺀 금액 Balance 증가
        ActualKRW := (ATradePrice * ATradeVolume) - APaidFee;
        UpdateAsset('KRW', ActualKRW, 0);
      end;

      Order^.RemainingVolume := Order^.RemainingVolume - ATradeVolume;
      if Order^.RemainingVolume < VOLUME_EPSILON then
      begin
        FPendingOrders.Remove(AUUID);
        Dispose(Order);
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAssetManager.ProcessCancel(const AUUID: string);
var
  Order: POrderReservation;
  Refund: Currency;
begin
  FLock.Enter;
  try
    if FPendingOrders.TryGetValue(AUUID, Order) then
    begin
      if Order^.Side > 0 then
      begin
        { 매수 취소: 잔여 예약금만큼 KRW 복원 }
        Refund := (Order^.Price * Order^.RemainingVolume) * (1 + Order^.StandardFeeRate);
        UpdateAsset('KRW', Refund, -Refund);
      end
      else
      begin
        { 매도 취소: 잔여 코인 수량만큼 코인 복원 }
        Refund := Order^.RemainingVolume;
        UpdateAsset(Order^.Symbol, Refund, -Refund);
      end;
      FPendingOrders.Remove(AUUID);
      Dispose(Order);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAssetManager.SyncAsset(const ASymbol: string; AActualBalance, AActualLocked: Currency);
var
  NewStatus: TAssetStatus;
begin
  FLock.Enter;
  try
    NewStatus.Balance := AActualBalance;
    NewStatus.Locked := AActualLocked;
    FAssets.AddOrSetValue(ASymbol, NewStatus);
  finally
    FLock.Leave;
  end;
end;

function TAssetManager.GetAssetStatus(const ASymbol: string): TAssetStatus;
begin
  FLock.Enter;
  try
    if not FAssets.TryGetValue(ASymbol, Result) then
    begin
      Result.Balance := 0;
      Result.Locked := 0;
    end;
  finally
    FLock.Leave;
  end;
end;

end.
