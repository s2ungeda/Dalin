unit Exchange.Types;

interface

type
  { 표준 자산 모델 }
  TAssetInfo = record
    Symbol: string;
    Available: Currency;
    Locked: Currency;
    Total: Currency;
    AvgPrice: Double;
  end;

  { 개별 심볼(KRW, BTC 등)의 자산 상태 }
  TAssetStatus = record
    Balance: Currency; // 즉시 사용 가능한 수량 (Upbit의 balance 필드 대응)
    Locked: Currency;  // 주문 등에 묶인 수량 (Upbit의 locked 필드 대응)
  end;


  { 주문 예약 추적 모델 }
  POrderReservation = ^TOrderReservation;
  TOrderReservation = record
    Identifier: string;
    UUID: string;

    Side: integer;          // 매수/매도 구분 추가
    Symbol: string;         // 대상 코인 (예: BTC)

    Price: Currency;
    OriginalVolume: Double;
    RemainingVolume: Double;
    ReservedAmount: Currency;
    StandardFeeRate: Double;
  end;

  { 거래소 어댑터 인터페이스 }
  IExchangeAdapter = interface
    ['{A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}']
    function GetExchangeName: string;
    function ParseAssetResponse(const AJsonResponse: string): TArray<TAssetInfo>;
  end;

implementation

end.
