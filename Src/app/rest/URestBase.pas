unit URestBase;

interface

uses
  System.Classes, System.SysUtils,  System.Generics.Collections,  System.SyncObjs,

  {REST.Client,}  Rest.Types,

  UApiTypes, UTypes,

  URestRequests, USharedData ,

  USmartRequest

  ;
type

  TTokenBucket = class
  private
    FLock: TCriticalSection;
    FCapacity: Integer;        // 최대 토큰 수
    FTokens:   Integer;          // 현재 토큰 수
    FRefillRate: Double;      // 초당 토큰 충전량
    FLastRefill: Int64;       // 마지막 충전 시각 (밀리초)
    procedure Refill;
    function GetTickMs: Int64;
  public
    constructor Create(ACapacity: Integer);
    destructor Destroy; override;
    /// <summary>논블로킹 토큰 획득 시도</summary>
    function TryAcquire(ATokens: Integer = 1): Boolean;
    /// <summary>블로킹 토큰 획득 (타임아웃 지원)</summary>
    function Acquire(ATokens: Integer = 1; ATimeoutMs: Cardinal = INFINITE): Boolean;
    /// <summary>현재 토큰 수 조회</summary>
    function GetAvailableTokens: Double;
    /// <summary>토큰 수 직접 설정 (서버 응답 동기화용)</summary>
    procedure SetTokens(ATokens: Integer);
    /// <summary>토큰 소진 처리 (429 응답 시)</summary>
    procedure MarkExhausted;
    property Capacity: Integer read FCapacity;
    property RefillRate: Double read FRefillRate;
    property Tokens: integer read FTokens;
  end;

  TRestBase = class
  private
    FRestReq: TRequest;//TRESTRequest;
    FParent: TObject;
    FExApiType: TExchangeApiType;
    FExchangeKind: TExchangeKind;
    FOnPushData: TSharedPushData;
    FBaseUrl: string;
    FAsyncRESTs: TAsyncRequestMngr;
    FAsyncReq: TRequest;

    FBuckets: TObjectDictionary<string, TTokenBucket>;

  public
    constructor Create( aParent : TObject ; aExApiType: TExchangeApiType; aExKind : TExchangeKind);
    Destructor  Destroy; override;
    procedure Init;

    function New(const AGroup: string; ACapacity: integer): TTokenBucket;
    // common
    function Request( aExKind : TExchangeKind; AMethod : TRESTRequestMethod;  AResource : string;
       var outJson, outRes : string ) : boolean;

    procedure RequestAsync(aReq: TRequest; AMethod : TRESTRequestMethod;  AResource : string);

    function CheckShareddData(var sArr: TArray<string>; sData: string;
      iCount: integer; aPrcName: string): boolean;

    procedure PushData(aExKind: TExchangeKind; aExApiType : TExchangeApiType; c3: char;
      sData, sRef: string); overload;
    procedure PushData(c3: char; sData, sRef: string); overload;
    //
    procedure UpdateLRemainValue(const sRemain: string); virtual;
    procedure MarkExhausted(const sRemain: string); virtual;

    function GetOrCreateBucket(const AGroup: string): TTokenBucket;

    function IsAvailable : boolean; virtual;

    procedure RequestNewOrder( sData, sRef : string ); virtual; abstract;
    procedure RequestCnlOrder( sData, sRef : string ); virtual; abstract;
    procedure RequestOrderList( sData, sRef : string ); virtual; abstract;
    procedure RequestPosition( sData, sRef : string ); virtual; abstract;
    procedure RequestBalance( sData, sRef : string ); virtual; abstract;
    procedure RequestOrdDetail( sData, sRef : string ); virtual; abstract;

    //  async result
    procedure OnResult(ReqType : char; OutJosn, Ref : string); virtual; abstract;

    // 거래소로 보내지 않고 신규주문을 거부할 때, Dalin 파서가 주문거부로 처리하는 형식으로 응답한다
    procedure RejectNewOrder(const sName, sMsg, sRef : string);
    // 비동기 요청이 HTTP 응답 없이 실패했을 때의 처리 (TAsyncRequestMngr 가 호출)
    procedure OnRequestFailed(ReqType : char; const sRef : string); virtual;

    property RestReq : TRequest read FRestReq; //TRESTRequest read FRestReq;
    property Parent  : TObject read FParent ;
    property ExApiType : TExchangeApiType read FExApiType;
    property ExKind : TExchangeKind read FExchangeKind;
    property BaseUrl: string read FBaseUrl;

    property AsyncRESTs : TAsyncRequestMngr read FAsyncRESTs;

    property OnPushData : TSharedPushData read FOnPushData write FOnPushData;

  end;

implementation

uses
  GApp, UApiConsts
  , USharedConsts
  , URestManager
  , System.Math
  ;

{ TRestBase }


constructor TRestBase.Create(aParent: TObject; aExApiType: TExchangeApiType; aExKind: TExchangeKind);
begin
  FRestReq := TRequest.Create;
  //FRestReq.OnNotify :=  RecvRequest;
  FParent  := aParent;
  FExApiType := aExApiType;
  FExchangeKind := aExKind;
  FAsyncRESTs   := nil;


  FBuckets := TObjectDictionary<string, TTokenBucket>.Create([doOwnsValues]);
end;

destructor TRestBase.Destroy;
begin
  FRestReq.Free;
  FAsyncRESTs.Free;

  FBuckets.Free;
  inherited;
end;


function TRestBase.GetOrCreateBucket(const AGroup: string): TTokenBucket;
begin
//  FLock.Enter;
  try
    FBuckets.TryGetValue(LowerCase(AGroup), Result);
  finally
//    FLock.Leave;
  end;
end;

procedure TRestBase.Init;
begin
  FBaseUrl  := App.ApiConfig.GetBaseUrl(FExchangeKind, FExApiType);
  FRestReq.Client.BaseURL := FBaseUrl;

  FAsyncRESTs := TAsyncRequestMngr.Create(Self, 10);
end;

function TRestBase.IsAvailable: boolean;
begin
  Result := true;
end;

procedure TRestBase.MarkExhausted(const sRemain: string);
begin

end;


function TRestBase.New(const AGroup: string; ACapacity: integer): TTokenBucket;
begin
  Result := TTokenBucket.Create(ACapacity);
  FBuckets.Add(LowerCase(AGroup), Result);

  App.DebugLog('%s Bucket 생성 :%s, %d', [TExchangeKindDesc[FExchangeKind], AGroup, ACapacity] );
end;

procedure TRestBase.PushData(c3: char; sData, sRef: string);
   var
    c1, c2 : char;
begin

  if Assigned( OnPushData ) then
  begin
    case FExchangeKind of
      ekBinance:c1 := EX_BN;
      ekUpbit:  c1 := EX_UP;
      ekBithumb:c1 := EX_BI;
    end;

    case FExApiType of
      eaSpot:   c2 := 'S';
      eaFutUsdt:c2 := 'F';
      eaFutCoin:c2 := 'P';
    end;

    App.DebugLog('Send : %s, %s, %s, %s, %s', [c1, c2, c3, sData, sRef]) ;
    OnPushData( c1, c2, c3, sData, sRef );

  end;
end;

procedure TRestBase.PushData( aExKind : TExchangeKind; aExApiType : TExchangeApiType;
   c3 : char; sData, sRef: string);
   var
    c1, c2 : char;
begin

  if Assigned( OnPushData ) then
  begin
    case aExKind of
      ekBinance:c1 := EX_BN;
      ekUpbit:  c1 := EX_UP;
      ekBithumb:c1 := EX_BI;
    end;

    case aExApiType of
      eaSpot:   c2 := 'S';
      eaFutUsdt:c2 := 'F';
      eaFutCoin:c2 := 'P';
    end;

    App.DebugLog('Send : %s, %s, %s, %s, %s', [c1, c2, c3, sData, sRef]) ;
    OnPushData( c1, c2, c3, sData, sRef );

  end;
end;


function TRestBase.CheckShareddData(var sArr : TArray<string>; sData: string;
   iCount : integer; aPrcName : string): boolean;
var
  iLen : integer;
begin

  sArr  := sData.Split(['|']);
  iLen  := high( sArr );

  if ( iLen < 0 ) or ( iLen + 1 <> iCount ) then
  begin
    App.Log(llError, '%s data is empty (%s) ', [ aPrcName, sData ] );
    Result := false;
  end else
    Result := true;
end;

procedure TRestBase.RejectNewOrder(const sName, sMsg, sRef: string);
begin
  if FExchangeKind = ekBinance then
    // 바이낸스 파서 : code 가 있고 clientOrderId 가 없으면 거부로 처리한다
    PushData(TR_NEW_ORD, Format('{"code":-9999,"msg":"%s"}', [sMsg]), sRef)
  else
    // 업비트/빗썸 파서 : error 객체가 있으면 거부로 처리한다
    PushData(TR_NEW_ORD, Format('{"error":{"name":"%s","message":"%s"}}', [sName, sMsg]), sRef);
end;

procedure TRestBase.OnRequestFailed(ReqType: char; const sRef: string);
begin
  case ReqType of
    TR_NEW_ORD :
      // 주문이 거래소에 도달했는지 알 수 없으므로 거부로 단정하지 않고 주문조회로 확인한다.
      // 조회 결과(있음/없음)는 Dalin 의 묶인 주문 확인과 같은 경로로 처리된다.
      // (바이낸스는 동기 요청만 쓰고 RequestOrdDetail 이 없으므로 제외)
      if (sRef <> '') and (FExchangeKind <> ekBinance) then
        RequestOrdDetail(sRef, sRef);
    TR_CNL_ORD :
      // 취소 실패로 알린다. 실제로는 취소됐더라도 거래소의 주문 이벤트로 반영된다.
      PushData(TR_CNL_ORD,
        '{"error":{"name":"send_error","message":"cancel request failed without response"}}', sRef);
  end;
end;

function TRestBase.Request(aExKind: TExchangeKind;
  AMethod: TRESTRequestMethod; AResource: string; var outJson,
  outRes: string): boolean;
begin

  Result := false;

  with FRestReq.Req do
  begin
    Method   := AMethod;
    Resource := AResource;
  end;

  try
    try

      with FRestReq.Req do
      begin
        Execute;

        OutJson:= Response.Content;

        if Response.StatusCode <> 200 then
        begin
          OutRes := Format( 'status : %d, %s', [ Response.StatusCode, Response.StatusText ] );
          Exit;
        end;

        Result  := true;
      end;

    except
      on E: Exception do
      begin
        OutRes := E.Message;
        Exit(false);
      end
    end;
  finally
    FRestReq.Req.Params.Clear;
    FRestReq.Req.Body.ClearBody;
  end;

end;

procedure TRestBase.RequestAsync(aReq: TRequest; AMethod: TRESTRequestMethod;
  AResource: string);
begin
  with aReq.Req do
  begin
    Method   := AMethod;
    Resource := AResource;
  end;
  aReq.RequestAsync;
end;

procedure TRestBase.UpdateLRemainValue(const sRemain: string);
begin

end;

{ TTokenBucket }

function TTokenBucket.Acquire(ATokens: Integer; ATimeoutMs: Cardinal): Boolean;
begin

end;

constructor TTokenBucket.Create(ACapacity: Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FCapacity := ACapacity;
  FTokens := ACapacity;
  FRefillRate := ACapacity;
  FLastRefill := TThread.GetTickCount64;
end;

destructor TTokenBucket.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TTokenBucket.GetAvailableTokens: Double;
begin
  FLock.Enter;
  try
    Refill;
    Result := FTokens;
  finally
    FLock.Leave;
  end;
end;

function TTokenBucket.GetTickMs: Int64;
begin
  Result := TThread.GetTickCount64;
end;

procedure TTokenBucket.MarkExhausted;
begin
  FLock.Enter;
  try
    FTokens := 0;
    FLastRefill := GetTickMs;
  finally
    FLock.Leave;
  end;
end;

procedure TTokenBucket.Refill;
var
  Now: Int64;
  ElapsedMs: Int64;
  AddTokens: Integer;
begin
  Now := TThread.GetTickCount64;
  ElapsedMs := Now - FLastRefill;
  AddTokens := Trunc(ElapsedMs * FRefillRate / 1000);
  if AddTokens > 0 then
  begin
    FTokens := Min(FCapacity, FTokens + AddTokens);
    // 충전에 사용된 시간만 전진
    FLastRefill := FLastRefill + Trunc(AddTokens * 1000 / FRefillRate);
  end;

end;

procedure TTokenBucket.SetTokens(ATokens: Integer);
begin
  FLock.Enter;
  try
    FTokens := Min(FCapacity, Max(0, ATokens));
    FLastRefill := GetTickMs;
  finally
    FLock.Leave;
  end;
end;

function TTokenBucket.TryAcquire(ATokens: Integer): Boolean;
begin
  FLock.Enter;
  try
    Refill;
    Result := FTokens >= ATokens;
    if Result then
      FTokens := FTokens - ATokens;
  finally
    FLock.Leave;
  end;
end;

end.
