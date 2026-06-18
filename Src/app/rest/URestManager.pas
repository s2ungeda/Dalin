unit URestManager;

interface

uses
  System.Classes, System.SysUtils, Windows,

  System.JSON,  Rest.Json , REST.Client,  Rest.Types,

  UApiTypes , UTypes,

  USharedData   , USharedConsts ,

  UUpbitRequests, UBithumbRequests,

  UBinFutRequests,  UBinSpotRequests, UBinFutCmRequests

  , System.Diagnostics, System.TimeSpan

  , URestBase
  ;

type

  TRestManager = class
  private
  {
    FRestReq : array [TExchangeKind] of TRESTRequest ;
    FRestReq2: TRESTRequest;
    FRestFutCm: TRESTRequest;
     }

    FRestReq  : array [TSharedThreadType] of TRestBase;

//    FBinFutReq: TBinFutReuqest;
//    FBinSpotReq: TBinSpotRequest;
//    FBinFutCmReq : TBinFutCmReuqest;
//    FUpbitReq: TUpbitRequest;
//    FBithumbReq: TBithumbRequest;

    function CheckShareddData( var sArr : TArray<string>; sData: string;
               iCount : integer; aPrcName : string ) : boolean;

    procedure PushData( aExKind : TExchangeKind; aMarket : TMarketType; c3 : char;  sData, sRef : string );

    //  bithumb
    procedure RequestBitOrderList( sData, sRef : string );
    procedure RequestBitBalance( sData, sRef : string );
    procedure RequestBitNewOrder( sData, sRef : string );
    procedure RequestBitCnlOrder( sData, sRef : string );
    procedure RequestBitOrderDetail( sData, sRef : string );
    procedure RequestBitTradeAmt( sData, sRef : string );

    //  upbit
    procedure RequestUptOrderList( sData, sRef : string; cDiv : char = TR_REQ_ORD );
    procedure RequestUptTradeAmt( sData, sRef : string );
    procedure RequestUptBalance( sData, sRef : string );
    procedure RequestUptAvailableOrder( sData, sRef : string );
    procedure RequestUptNewOrder( sData, sRef : string );
    procedure RequestUptCnlOrder( sData, sRef : string );
    procedure RequestUptOrderDetail( sData, sRef : string );

    function  RequestUptFailMessage( sReq : string ) : string;

    function Request( aExKind : TExchangeKind; AMethod : TRESTRequestMethod;  AResource : string;
       var outJson, outRes : string ) : boolean;
    function GetRest(sType: TSharedThreadType): TRestBase;
  public
    Constructor Create;
    Destructor  Destroy; override;
    procedure init(stType : TSharedThreadType; aPushProc : TSharedPushData);

    procedure OnSharedDataNotify( aData : TDataItem );

    function IsAbleReq(stType: TSharedThreadType) : boolean;

    property Rest[sType: TSharedThreadType] : TRestBase read GetRest;
//    property BinFutReq : TBinFutReuqest read FBinFutReq write FBinFutReq;
//    property BinSpotReq : TBinSpotRequest read FBinSpotReq write FBinSpotReq;
//    property BinFutCmReq : TBinFutCmReuqest read FBinFutCmReq write FBinFutCmReq;
//
//    property UpbitReq : TUpbitRequest read FUpbitReq write FUpbitReq;
//    property BithumbReq : TBithumbRequest read FBithumbReq write FBithumbReq;

  end;

implementation

uses
  GApp, GLibs
  , UApiConsts
  , UEncrypts
  , IdCoderMIME, IdGlobal
  , system.Hash

  , JOSE.Core.JWT   ,JOSE.Core.Builder, JOSE.Core.JWA
  ;

{ TRestManager }

function TRestManager.CheckShareddData(var sArr : TArray<string>; sData: string;
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

constructor TRestManager.Create;
var
  i : TSharedThreadType;
begin
{
  FRestReq[ekBinance] := nil;
  FRestReq[ekUpbit]   := nil;
  FrestReq[ekBithumb] := nil;
  FRestReq2 := nil;
  FRestFutCm := nil;
}
  for I := stBnSThread to High(TSharedThreadType) do
    case i of
      stBnSThread: FRestReq[i] := TBinSpotRequest.Create(Self, eaSpot, ekBinance);
      stBnFThread: FRestReq[i] := TBinFutReuqest.Create(Self, eaFutUsdt, ekBinance);
      stBnCThread: FRestReq[i] := TBinFutCmReuqest.Create(Self, eaFutCoin, ekBinance);
      stUpSThread: FRestReq[i] := TUpbitRequest.Create(Self, eaSpot, ekUpbit);
      stBtSThread: FRestReq[i] := TBithumbRequest.Create(Self, eaSpot, ekBithumb);
    end;
end;

destructor TRestManager.Destroy;
var
  i : TSharedThreadType;
begin
  for I := stBnSThread to High(TSharedThreadType) do
    FRestReq[i].Free;
//  FBinFutReq.Free;
//  FBinSpotReq.Free;
//  FBinFutCmReq.Free;
//  FUpbitReq.Free;
//  FBithumbReq.Free;
  inherited;
end;

function TRestManager.GetRest(sType: TSharedThreadType): TRestBase;
begin
  Result := FRestReq[sType];
end;

procedure TRestManager.init(stType : TSharedThreadType; aPushProc : TSharedPushData);
begin
  FRestReq[stType].OnPushData  := aPushProc;
  FRestReq[stType].Init;
{
  FRestReq[ekBinance] := bn;
  FRestReq[ekUpbit]   := up;
  FrestReq[ekBithumb] := bt;
  FRestReq2           := bnSpot;
  FRestFutCm          := bnFutCm;

  FBinFutReq  := TBinFutReuqest.Create(Self, eaFutUsdt, ekBinance);
  FBinSpotReq := TBinSpotRequest.Create(Self, eaSpot, ekBinance);
  FBinFutCmReq := TBinFutCmReuqest.Create(Self, eaFutCoin, ekBinance);

  FUpbitReq    := TUpbitRequest.Create(Self, eaSpot, ekUpbit);
  FBithumbReq  := TBithumbRequest.Create(Self, eaSpot, ekBithumb);
}
end;


function TRestManager.IsAbleReq(stType: TSharedThreadType): boolean;
begin
  Result := FRestReq[stType].IsAvailable
end;

procedure TRestManager.OnSharedDataNotify(aData: TDataItem);
var
  idx : TSharedThreadType;
  StartTick : int64;
begin
  //if (aData.exKind <> EX_UP ) and ( aData.trDiv <> TR_REQ_ORD )  then
  App.DebugLog('Recv : %s, %s, %s, %s, %s', [ aData.exKind, aData.exApiType, aData.trDiv, AnsiString( aData.data ), aData.ref ] );

//  StartTick := GetTickCount64;

  try
    case aData.exKind of
      EX_BN :
        case aData.exApiType of
          'F': idx := stBnFThread;
          'P': idx := stBnCThread;
          'S': idx := stBnSThread;
        end;
      EX_UP : idx := stUpSThread;
      EX_BI : idx := stBtSThread;
    end;

    case aData.trDiv of
      TR_NEW_ORD : FRestReq[idx].RequestNewOrder(AnsiString(aData.data), aData.ref);   // 신규 주문
      TR_CNL_ORD : FRestReq[idx].RequestCnlOrder(AnsiString(aData.data), aData.ref);   // 취소 주문
      TR_REQ_ORD : FRestReq[idx].RequestOrderList(AnsiString(aData.data), aData.ref);  // 주문 조회..
      TR_REQ_POS : FRestReq[idx].RequestPosition(AnsiString(aData.data), aData.ref);   // 포지션 조회..
      TR_REQ_BAL : FRestReq[idx].RequestBalance(AnsiString(aData.data), aData.ref);    // 잔고 조회...
      TR_ORD_DETAIL: FRestReq[idx].RequestOrdDetail(AnsiString(aData.data), aData.ref);    // 주문상세조회..

//      TR_ABLE_ORD= 'A';			// 주문가능금액..
//      TR_ORD_DETAIL = 'D';	// 주문상세조회.
//      TR_TRD_AMT  = 'T';    // 거래액
//      TR_ORD_BOOK = 'H';    // 마켓뎁스..
//      TR_DNW_STATE  = 'W';  // 입출금 조회
    end;
//    if (aData.trDiv = TR_CNL_ORD) or (aData.trDiv = TR_NEW_ORD)  then
//      App.Log(llInfo, '%s : %s %d', [aData.exKind, aData.trDiv, GetTickCount64 - StartTick]);
  finally
  end;

end;

procedure TRestManager.PushData( aExKind : TExchangeKind; aMarket : TMarketType;
   c3 : char; sData, sRef: string);
//   var
//    c1, c2 : char;
begin
//  if Assigned( FOnPushData ) then
//  begin
//    case aExKind of
//      ekBinance:c1 := EX_BN;
//      ekUpbit:  c1 := EX_UP;
//      ekBithumb:c1 := EX_BI;
//    end;
//
//    case aMarket of
//      mtSpot:   c2 := 'S';
//      mtFutures:c2 := 'F' ;
//    end;
//
//    FOnPushData( c1, c2, c3, sData, sRef );
//
//    App.DebugLog('Send : %s, %s, %s, %s, %s', [c1, c2, c3, sData, sRef]) ;
//
//  end;
end;

function TRestManager.Request(aExKind: TExchangeKind;
  AMethod: TRESTRequestMethod; AResource: string; var outJson,
  outRes: string): boolean;
begin

  Result := false;

//  with FRestReq[aExKind] do
//  begin
//    Method   := AMethod;
//    Resource := AResource;
//  end;
//
//  try
//    try
//
//      with FRestReq[aExKind] do
//      begin
//        Execute;
//
//        OutJson:= Response.Content;
//
//        if not (Response.StatusCode in [200..201]) then
//        begin
//          OutRes := Format( 'status : %d, %s', [ Response.StatusCode, Response.StatusText ] );
//          Exit;
//        end;
//
//        Result  := true;
//      end;
//
//    except
//      on E: Exception do
//      begin
//        OutRes := E.Message;
//        Exit(false);
//      end
//    end;
//  finally
//    FRestReq[aExKind].Params.Clear;
//    FRestReq[aExKind].Body.ClearBody;
//  end;

end;

// bithumb api --------------------------------------------------------------------------------------


procedure TRestManager.RequestBitBalance(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  sParam1 : string;
  I: Integer;
  aExKind : TExchangeKind;

begin
  if not CheckShareddData( sArr, sData, TB_CNT, 'BitBalance') then Exit;

  try
  	aExKind	:= ekBithumb;

    sParam1	:= sArr[TB_CODE];
    sRsrc 	:= '/info/balance';
    sTime 	:= GetTimestamp;
    sVal		:= EncodePath( sRsrc, Format('endPoint=%s&currency=%s', [ sRsrc, sParam1 ] ), sTime );

    sSig	:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
    sBody	:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );

//    FRestReq[aExKind].AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    FRestReq[aExKind].AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//    FRestReq[aExKind].AddParameter('currency', sParam1, TRESTRequestParameterKind.pkREQUESTBODY);

    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
      App.Log( llError, '', 'Failed %s RequestBitBalance (%s, %s)',
      [ TExApiTypeDesc[eaSpot], outRes, outJson] );

   	PushData( aExKind, mtSpot, TR_REQ_BAL, outJson, sRef );
	except
  end;
end;

procedure TRestManager.RequestBitCnlOrder(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  aExKind : TExchangeKind;

begin
//  if not CheckShareddData( sArr, sData, TC_CNT, 'BitCnlOrder') then Exit;
//
//  try
//
//  	aExKind	:= ekBithumb;
//
//    sRsrc 	:= '/trade/cancel';
//    sTime 	:= GetTimestamp;
//    sBody		:= Format('endPoint=%s&order_currency=%s&payment_currency=%s&order_id=%s&type=%s', [
//    		sRsrc, sArr[TC_CODE], sArr[TC_STT], sArr[TC_OID], sArr[TC_LS]
//    	]);
//    sVal		:= EncodePath( sRsrc, sBody, sTime );
//
//    sSig	:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
//    sBody	:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );
//
//    with  FRestReq[aExKind] do
//    begin
//
//    	AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    	AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    	AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    	AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//
//  		AddParameter('order_currency', 	sArr[TC_CODE], 	TRESTRequestParameterKind.pkREQUESTBODY);
//  		AddParameter('payment_currency',sArr[TC_STT], 	TRESTRequestParameterKind.pkREQUESTBODY);
//  		AddParameter('order_id', 				sArr[TC_OID], 	TRESTRequestParameterKind.pkREQUESTBODY);
//  		AddParameter('type', 						sArr[TC_LS], 		TRESTRequestParameterKind.pkREQUESTBODY);
//    end;
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then begin
//      App.Log( llError, '', 'Failed %s RequestBitCnlOrder (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//      if outJson.IsEmpty then
//        outJson := format('{"status":"%d","message":"%s"}', [
//          FRestReq[aExKind].Response.StatusCode,
//          FRestReq[aExKind].Response.StatusText
//          ] );
//    end;
//
//   	PushData( aExKind, mtSpot, TR_CNL_ORD, outJson, sRef );
//
//	except
//  end;

end;

procedure TRestManager.RequestBitNewOrder(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  sParam1 : string;
  I: Integer;
  aExKind : TExchangeKind;

begin
//  if not CheckShareddData( sArr, sData, TO_CNT, 'BitNewOrder') then Exit;
//
//  try
//
//  	aExKind	:= ekBithumb;
//
//    sRsrc 	:= '/trade/place';
//    sTime 	:= GetTimestamp;
//    sBody		:= Format('endPoint=%s&order_currency=%s&payment_currency=%s&units=%s&price=%s&type=%s', [
//    		sRsrc, sArr[TO_CODE], sArr[TO_STT], sArr[TO_QTY], sArr[TO_PRC], sArr[TO_LS]
//    	]);
//
//    sVal		:= EncodePath( sRsrc, sBody,  sTime );
//
//    sSig		:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
//    sBody		:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );
//
//    FRestReq[aExKind].AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    FRestReq[aExKind].AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//
//    with FRestReq[aExKind] do
//    begin
//      AddParameter('order_currency', 		sArr[TO_CODE], TRESTRequestParameterKind.pkREQUESTBODY);
//      AddParameter('payment_currency', 	sArr[TO_STT], TRESTRequestParameterKind.pkREQUESTBODY);
//      AddParameter('units', sArr[TO_QTY], TRESTRequestParameterKind.pkREQUESTBODY);
//      AddParameter('price', sArr[TO_PRC], TRESTRequestParameterKind.pkREQUESTBODY);
//      AddParameter('type',  sArr[TO_LS], TRESTRequestParameterKind.pkREQUESTBODY);
//    end;
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then begin
//      App.Log( llError, '', 'Failed %s RequestBitNewOrder (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//      if outJson.IsEmpty then
//        outJson := format('{"status":"%d","message":"%s"}', [
//          FRestReq[aExKind].Response.StatusCode,
//          FRestReq[aExKind].Response.StatusText
//          ] );
//    end;
//
//   	PushData( aExKind, mtSpot, TR_NEW_ORD, outJson, sRef );
//
//	except
//  end;
end;



procedure TRestManager.RequestBitOrderDetail(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  I: Integer;
  aExKind : TExchangeKind;

begin
//  if not CheckShareddData( sArr, sData, TD_CNT, 'BitOrderDetail') then Exit;
//
//  try
//  	aExKind	:= ekBithumb;
//    sRsrc 	:= '/info/order_detail';
//    sTime 	:= GetTimestamp;
//    sVal		:= EncodePath( sRsrc, Format('endPoint=%s&order_id=%s&order_currency=%s',
//      [ sRsrc, sArr[TD_OID], sArr[TD_CODE]] ), sTime )  ;
//
//    sSig	:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
//    sBody	:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );
//
//    with FRestReq[aExKind] do
//    begin
//    	AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    	AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    	AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    	AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//    	AddParameter('order_id', 			sArr[TD_OID] , TRESTRequestParameterKind.pkREQUESTBODY);
//    	AddParameter('order_currency',sArr[TD_CODE], TRESTRequestParameterKind.pkREQUESTBODY);
//    end;
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitOrderDetail (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//   	PushData( aExKind, mtSpot, TR_ORD_DETAIL, outJson, sRef );
//	except
//  end;

end;




procedure TRestManager.RequestBitOrderList(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//
//	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
//  sParam1 : string;
//  I: Integer;
//  aExKind : TExchangeKind;
//
//  // 유니코드 이스케이프 문자열(\uXXXX)을 디코딩
//  function DecodeUnicodeEscape(const AStr: string): string;
//  var
//    JsonStr: string;
//    JsonValue: TJSONValue;
//  begin
//    JsonStr := Format('{"str":"%s"}', [AStr]);
//    JsonValue := TJSONObject.ParseJSONValue(JsonStr);
//    try
//      if (JsonValue is TJSONObject) and (TJSONObject(JsonValue).Count = 1) then
//      begin
//        Result := TJSONObject(JsonValue).GetValue('str').Value;
//      end
//      else
//      begin
//        Result := AStr;
//      end;
//    finally
//      JsonValue.Free;
//    end;
//  end;
//
//begin
//  if not CheckShareddData( sArr, sData, TL_CNT, 'BitOrderList') then Exit;
//
//  try
//  	aExKind	:= ekBithumb;
//
//    sParam1	:= sArr[TL_CODE];
////    sParam2 := trim( sArr[TL_OID] );
//    sRsrc 	:= '/info/orders';
//    sTime 	:= GetTimestamp;
//
////    if sParam2 = '' then
//	    sVal	:= EncodePath( sRsrc, Format('endPoint=%s&order_currency=%s', [ sRsrc, sParam1] ), sTime )  ;
////    else begin
////	    sVal	:= EncodePath( sRsrc, Format('endPoint=%s&order_id=%s&order_currency=%s', [ sRsrc, sParam2, sParam1 ] ), sTime );
////      FRestReq[aExKind].AddParameter('order_id', sParam2, TRESTRequestParameterKind.pkREQUESTBODY);
////    end;
//
//    sSig	:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
//    sBody	:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );
//
//    FRestReq[aExKind].AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    FRestReq[aExKind].AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//    FRestReq[aExKind].AddParameter('order_currency', sParam1, TRESTRequestParameterKind.pkREQUESTBODY);
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitOrderList (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//   	PushData( aExKind, mtSpot, TR_REQ_ORD, outJson, sRef );
//	except
//  end;

end;

procedure TRestManager.RequestBitTradeAmt(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//
//	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
//  sParam1 : string;
//  I: Integer;
//  aExKind : TExchangeKind;
//
//begin
//  if not CheckShareddData( sArr, sData, TL_CNT, 'BitTradeAmt') then Exit;
//
//  try
//  	aExKind	:= ekBithumb;
//
//    sParam1	:= sArr[TL_CODE];
//
//    sRsrc 	:= '/info/ticker';
//    sTime 	:= GetTimestamp;
//
//    sVal	:= EncodePath( sRsrc, Format('endPoint=%s&order_currency=%s', [ sRsrc, sParam1] ), sTime )  ;
//    sSig	:= CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey( aExKind, eaSpot) );
//    sBody	:= TIdEncoderMIME.EncodeString( sSig, IndyTextEncoding_UTF8 );
//
//    FRestReq[aExKind].AddParameter('Api-Key', App.ApiConfig.GetApiKey( aExKind, eaSpot), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
//    FRestReq[aExKind].AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
//
//    FRestReq[aExKind].AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
//    FRestReq[aExKind].AddParameter('order_currency', sParam1, TRESTRequestParameterKind.pkREQUESTBODY);
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitTradeAmt (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//   	PushData( aExKind, mtSpot, TR_TRD_AMT, outJson, sRef );
//	except
//  end;
end;

// bithumb api --------------------------------------------------------------------------------------

// upbit api --------------------------------------------------------------------------------------


procedure TRestManager.RequestUptAvailableOrder(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  guid : TGUID;     vHash : THashSHA2;
//  sSig, sToken, sQuery, outRes, sRsrc, outJson : string;
//begin
//
//  if not CheckShareddData( sArr, sData, UA_CNT, 'UptAvailableOrder') then Exit;
//
//  aExKind := ekUpbit;
//
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//
//    sQuery := 'market='+sArr[UA_CODE];
//    sRsrc  := '/v1/orders/chance?'+sQuery;
//
//    LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//    LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//    LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//    LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//    sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//             TJOSEAlgorithmId.HS256, LToken);
//    sToken:= Format('Bearer %s', [sSig ]);
//
//    with FRestReq[aExKind] do
//    begin
//      AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//    end;
//
//    if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitOrderList (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//    PushData( aExKind, mtSpot, TR_ABLE_ORD, outJson, sRef );
//
//  finally
//    LToken.Free;
//  end;
end;

procedure TRestManager.RequestUptBalance(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  guid : TGUID;
//  sSig, sID, sToken, outRes, sRsrc, outJson : string;
//begin
//
//  //if not CheckShareddData( sArr, sData, TL_CNT, 'UptBalance') then Exit;
//
//  aExKind := ekUpbit;
//
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//    sID := GetUUID;
//    sRsrc := '/v1/accounts';
//
//    LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//    LToken.Claims.SetClaimOfType<string>('nonce', sID );
//    sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//             TJOSEAlgorithmId.HS256, LToken);
//    sToken:= Format('Bearer %s', [sSig ]);
//
//    with FRestReq[aExKind] do
//    begin
//      AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//    end;
//
//    if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitOrderList (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//    PushData( aExKind, mtSpot, TR_REQ_BAL, outJson, sRef );
//
//  finally
//    LToken.Free;
//  end;

end;

procedure TRestManager.RequestUptCnlOrder(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  guid : TGUID;     vHash : THashSHA2;
//  sSig, sToken, sQuery, outRes, sRsrc, outJson : string;
//begin
//
//  if not CheckShareddData( sArr, sData, UC_CNT, 'UptCnlOrder') then Exit;
//  aExKind := ekUpbit;
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//
//    sQuery := 'uuid='+sArr[UC_UID];
//    sRsrc  := '/v1/order?'+sQuery;
//
//    LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//    LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//    LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//    LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//    sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//             TJOSEAlgorithmId.HS256, LToken);
//    sToken:= Format('Bearer %s', [sSig ]);
//
//    with FRestReq[aExKind] do
//    begin
//      AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//    end;
//
//    if not Request( aExKind ,rmDELETE, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestUptCnlOrder (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//    PushData( aExKind, mtSpot, TR_CNL_ORD, outJson, sRef );
//
//  finally
//    LToken.Free;
//  end;
end;

function TRestManager.RequestUptFailMessage( sReq : string ): string;
begin
  Result := '{"error":{"name": "request_failed", "message": "'+sReq+' request failed."}}';
end;

procedure TRestManager.RequestUptNewOrder(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  guid : TGUID;     vHash : THashSHA2;
//  sSig, sToken, sQuery, outRes, sRsrc, outJson : string;
//  aObj : TJsonObject;
//begin
//
//  if not CheckShareddData( sArr, sData, UO_CNT, 'UptNewOrder') then Exit;
//  aExKind := ekUpbit;
//
//  aObj  := TJsonObject.Create;
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//
//    sQuery := format('market=%s&side=%s&price=%s&volume=%s&order_type=%s&identifier=%s', [
//      sArr[UO_CODE], sArr[UO_LS], sArr[UO_PRC], sArr[UO_QTY], sArr[UO_TYPE], sRef
//      ]);
//    sRsrc  := '/v1/orders?'+sQuery;
//
//    with aObj do
//    begin
//      AddPair('market', sArr[UO_CODE] );
//      AddPair('side',   sArr[UO_LS]);
//      AddPair('price',  sArr[UO_PRC]);
//      AddPair('volume', sArr[UO_QTY]);
//      AddPair('order_type',sArr[UO_TYPE]);
//      AddPair('identifier', sRef);
//    end;
//
//    LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//    LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//    LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//    LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//    sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//             TJOSEAlgorithmId.HS256, LToken);
//    sToken:= Format('Bearer %s', [sSig ]);
//
//    with FRestReq[aExKind] do
//    begin
//      AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//      Body.Add(aObj);
//    end;
//
//    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestUptNewOrder (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//    //App.DebugLog('UptNewOrder : %s', [ outJson ] );
//
//    PushData( aExKind, mtSpot, TR_NEW_ORD, outJson, sRef );
//
//  finally
//    LToken.Free;
//    aObj.Free;
//  end;
end;

procedure TRestManager.RequestUptOrderDetail(sData, sRef: string);
begin
//var
//  sArr , sUids  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  vHash : THashSHA2;
//  sSig, sToken, sRsrc ,sQuery, outRes,  outJson : string;
//  I: Integer;
//begin
//
//  if not CheckShareddData( sArr, sData, UD_CNT, 'UptOrderDetail') then Exit;
//
//  aExKind := ekUpbit;
//  LToken:= TJWT.Create(TJWTClaims);
//
//  try
//
//      sUids  := sArr[UD_UID].Split([',']);
//      for I := 0 to High(sUids) do
//      begin
//
//        sQuery := 'uuid=' + sUids[i];
//        sRsrc  := '/v1/order?'+sQuery;
//
//        try
//          LToken.Clear;
//          LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//          LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//          LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//          LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//          sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//                   TJOSEAlgorithmId.HS256, LToken);
//          sToken:= Format('Bearer %s', [sSig ]);
//
//          with FRestReq[aExKind] do
//          begin
//            AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//          end;
//
//          if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//            App.Log( llError, '', 'Failed %s RequestUptOrderDetail (%s, %s)',
//            [ TExchangeKindDesc[aExKind], outRes, outJson] )
//
//        except
//          outJson := RequestUptFailMessage('OrderDetail');
//        end;
//
//        //App.DebugLog('UptOrderDetail : %s', [ outJson ] );
//        PushData( aExKind, mtSpot, TR_ORD_DETAIL, outJson, sUids[i] );
//      end;
//
//  finally
//    LToken.Free;
//  end;


end;

procedure TRestManager.RequestUptOrderList(sData, sRef: string; cDiv : char);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  vHash : THashSHA2;
//  sSig, sToken, sQuery, outRes, sRsrc, outJson : string;
//begin
//
//  if not CheckShareddData( sArr, sData, UL_CNT, 'UptOrderList') then Exit;
//
//  aExKind := ekUpbit;
//
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//
//    try
//      sQuery := format('state=%s&order_by=%s', [ sArr[UL_STATE], sArr[UL_ASC] ]);
//      sRsrc  := '/v1/orders?'+sQuery;
//
//      LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//      LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//      LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//      LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//      sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//               TJOSEAlgorithmId.HS256, LToken);
//      sToken:= Format('Bearer %s', [sSig ]);
//
//      with FRestReq[aExKind] do
//      begin
//        AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//      end;
//
//      if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//        App.Log( llError, '', 'Failed %s RequestUptOrderList (%s, %s)',
//        [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//      PushData( aExKind, mtSpot, cDiv, outJson, sRef );
//    except
//    end;
//
//  finally
//    LToken.Free;
//  end;

end;


procedure TRestManager.RequestUptTradeAmt(sData, sRef: string);
begin
//var
//  sArr  : TArray<string>;
//  aExKind : TExchangeKind;
//
//  LToken: TJWT;
//  guid : TGUID;     vHash : THashSHA2;
//  sSig, sToken, sQuery, outRes, sRsrc, outJson : string;
//begin
//
////  UT_CNT = 2;
////  UT_STATE = 0;
////  UT_ASC = 1;
//  if not CheckShareddData( sArr, sData, UT_CNT, 'UptTradeAmt') then Exit;
//
//  aExKind := ekUpbit;
//
//  LToken:= TJWT.Create(TJWTClaims);
//  try
//
//    try
//      sQuery := format('state=%s&order_by=%s', [ sArr[UL_STATE], sArr[UL_ASC] ]);
//      sRsrc  := '/v1/orders?'+sQuery;
//
//      LToken.Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey( aExKind, eaSpot));
//      LToken.Claims.SetClaimOfType<string>('nonce', GetUUID );
//      LToken.Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
//      LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
//
//      sSig  := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey( aExKind, eaSpot),
//               TJOSEAlgorithmId.HS256, LToken);
//      sToken:= Format('Bearer %s', [sSig ]);
//
//      with FRestReq[aExKind] do
//      begin
//        AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
//      end;
//
//      if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//        App.Log( llError, '', 'Failed %s RequestUptTradeAmt (%s, %s)',
//        [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//      PushData( aExKind, mtSpot, TR_TRD_AMT, outJson, sRef );
//    except
//    end;
//
//  finally
//    LToken.Free;
//  end;

end;


// upbit api --------------------------------------------------------------------------------------


end.
