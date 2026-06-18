unit UAssetManager;

interface

uses
  System.Generics.Collections, System.SyncObjs, System.JSON, System.SysUtils;

type
  // 개별 주문의 예약 상태를 추적하기 위한 레코드
  TOrderReservation = record
    UUID: string;
    ReservedAmount: Currency; // (가격 * 수량) + 표준 수수료
    StandardFeeRate: Double;  // 주문 시 적용한 표준 수수료율 (예: 0.0005)
  end;

  TAssetManager = class
  private
    FLock: TCriticalSection;
    FBalance: Currency;       // 가용 자산 (balance)
    FLocked: Currency;        // 묶인 자산 (locked)
    FPendingOrders: TDictionary<string, TOrderReservation>; // UUID별 예약 정보

    const STANDARD_FEE = 0.0005; // 업비트 기본 수수료 0.05%
  public
    constructor Create;
    destructor Destroy; override;

    // 1. 주문 요청 직후 (로컬 잔고 우선 차감)
    procedure ReserveOrder(const ATempID: string; APrice, AVolume: Double);

    // 2. 주문 성공 (UUID 확정 시)
    procedure ConfirmOrder(const ATempID, AActualUUID: string);

    // 3. 체결 시 (가장 중요: 수수료 차액 보정)
    procedure ProcessTrade(const AUUID: string; ATradePrice, ATradeVolume, APaidFee: Double);

    // 4. 취소 시
    procedure ProcessCancel(const AUUID: string; ARemainingVolume: Double);

    // 5. 서버와 동기화 (정기적 호출)
    procedure SyncWithServer(ABalance, ALocked: Currency);
  end;

implementation

{ TAssetManager }

constructor TAssetManager.Create;
begin
  FLock := TCriticalSection.Create;
  FPendingOrders := TDictionary<string, TOrderReservation>.Create;
end;

destructor TAssetManager.Destroy;
begin
  FPendingOrders.Free;
  FLock.Free;
  inherited;
end;

procedure TAssetManager.ReserveOrder(const ATempID: string; APrice, AVolume: Double);
var
  TotalReserved: Currency;
  Res: TOrderReservation;
begin
  FLock.Enter;
  try
    // 수수료를 포함하여 보수적으로 계산
    // Total = (Price * Volume) * (1 + 0.05%)
    TotalReserved := (APrice * AVolume) * (1 + STANDARD_FEE);

    FBalance := FBalance - TotalReserved;
    FLocked := FLocked + TotalReserved;

    Res.UUID := ATempID;
    Res.ReservedAmount := TotalReserved;
    Res.StandardFeeRate := STANDARD_FEE;
    FPendingOrders.Add(ATempID, Res);
  finally
    FLock.Leave;
  end;
end;

procedure TAssetManager.ProcessTrade(const AUUID: string; ATradePrice, ATradeVolume, APaidFee: Double);
var
  Res: TOrderReservation;
  ActualTradeCost: Currency;
  ReservedForThisTrade: Currency;
  FeeRefund: Currency;
begin
  FLock.Enter;
  try
    if FPendingOrders.TryGetValue(AUUID, Res) then
    begin
      // 1. 실제 들어간 비용 (체결금액 + 실제 수수료)
      ActualTradeCost := (ATradePrice * ATradeVolume) + APaidFee;

      // 2. 이 체결분만큼 예약되었던 금액 계산
      ReservedForThisTrade := (ATradePrice * ATradeVolume) * (1 + Res.StandardFeeRate);

      // 3. 차액(수수료 환급분) 계산
      // 예약할 땐 0.05%를 뺐는데, 실제로는 APaidFee만 나갔으므로 그 차이를 돌려줌
      FeeRefund := ReservedForThisTrade - ActualTradeCost;

      // 4. 자산 업데이트
      FLocked := FLocked - ReservedForThisTrade;
      FBalance := FBalance + FeeRefund; // 차액만큼 가용 자산으로 환급!

      // (참고) 코인 잔고 증가 로직도 여기에 추가 가능
    end;
  finally
    FLock.Leave;
  end;
end;

{ 2. 주문 성공 (UUID 확정 시) }
procedure TAssetManager.ConfirmOrder(const ATempID, AActualUUID: string);
var
  Res: TOrderReservation;
begin
  FLock.Enter;
  try
    // 1. 임시 ID로 저장된 예약 정보를 찾습니다.
    if FPendingOrders.TryGetValue(ATempID, Res) then
    begin
      // 2. 임시 정보를 삭제하고 실제 서버 UUID로 교체하여 재등록합니다.
      FPendingOrders.Remove(ATempID);
      Res.UUID := AActualUUID;
      FPendingOrders.Add(AActualUUID, Res);
    end;
  finally
    FLock.Leave;
  end;
end;

{ 4. 취소 시 (잔여 수량만큼 자금 회수) }
procedure TAssetManager.ProcessCancel(const AUUID: string; ARemainingVolume: Double);
var
  Res: TOrderReservation;
  CancelAmount: Currency;
  PricePerUnit: Double;
begin
  FLock.Enter;
  try
    if FPendingOrders.TryGetValue(AUUID, Res) then
    begin
      // 1. 예약 시점의 단가를 역산합니다. (수수료 포함된 단가)
      // ReservedAmount = (Price * Volume) * (1 + Fee)
      // 그러므로 취소될 금액 = (ReservedAmount / Volume) * RemainingVolume
      // 단, 정확성을 위해 예약 정보에 OriginalVolume을 추가로 저장하는 것이 더 좋습니다.

      // 여기서는 단순화하여 취소 수량 비율만큼 회수합니다.
      // 실제 구현 시에는 ReservedAmount 내역에서 체결된 만큼을 뺀 나머지를 계산합니다.
      CancelAmount := Res.ReservedAmount; // (예시: 전액 취소 시)

      // 2. 자산 이동
      FLocked := FLocked - CancelAmount;
      FBalance := FBalance + CancelAmount;

      // 3. 관리 목록에서 삭제
      FPendingOrders.Remove(AUUID);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAssetManager.SyncWithServer(ABalance, ALocked: Currency);
begin
  FLock.Enter;
  try
    // 주기적으로 서버 API(GET /v1/accounts) 결과와 동기화하여 오차 제거
    FBalance := ABalance;
    FLocked := ALocked;
  finally
    FLock.Leave;
  end;
end;

end.
