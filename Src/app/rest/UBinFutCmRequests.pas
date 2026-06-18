unit UBinFutCmRequests;

interface

uses
  System.Classes, System.SysUtils,
  REST.Client,  Rest.Types,
  UApiTypes, UTypes,
  URestBase
  ;

type
  TBinFutCmReuqest = class(TRestBase)
  private
    procedure sig(var sData: string);
  public
    procedure RequestNewOrder( sData, sRef : string );  override;
    procedure RequestCnlOrder( sData, sRef : string );  override;
    procedure RequestBalance( sData, sRef : string );   override;
    procedure RequestPosition( sData, sRef : string );   override;
    procedure RequestOrderList( sData, sRef : string );  override;
    procedure RequestTradeAmt( sData, sRef : string );
  end;

implementation

uses
  GApp, GLibs , system.DateUtils
  , UEncrypts
  , UApiConsts
  , USharedConsts
  ;

{ TBinFutReuqest }

procedure TBinFutCmReuqest.sig(var sData : string);
var
  sig : string;
begin
  sig   := CalculateHMACSHA256(sData,App.ApiConfig.GetSceretKey( ekBinance, eaFutUsdt) );
  sData := sData + Format('&signature=%s', [ sig ]);

  RestReq.Req.AddParameter('X-MBX-APIKEY',
      App.ApiConfig.GetApiKey( ekBinance, ExApiType) , pkHTTPHEADER );
end;


procedure TBinFutCmReuqest.RequestPosition(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  //
  sTime := GetTimestamp;
  if sData = '' then
    sBody := Format('timestamp=%s', [sTime])
  else
    sBody := Format('symbol=%s&timestamp=%s', [sData, sTime]);

  sig(sBody);

  if not Request( ekBinance,rmGET, '/dapi/v1/positionRisk?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBinFutPosition (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_REQ_POS, outJson, sRef );

end;


procedure TBinFutCmReuqest.RequestBalance(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  sTime := GetTimestamp;
  sBody := Format('timestamp=%s', [sTime]);

  sig(sBody);

//  sSig  := CalculateHMACSHA256(sBody,App.ApiConfig.GetSceretKey( ekBinance, mtFutures) );
//  sBody := sBody + Format('&signature=%s', [ sSig ]);
//
//  RestReq.AddParameter('X-MBX-APIKEY',
//      App.ApiConfig.GetApiKey( ekBinance, mtFutures) , pkHTTPHEADER );

  if not Request( ekBinance,rmGET, '/dapi/v1/account?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBinFutCmAccount (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_REQ_BAL, outJson, sRef );

end;

procedure TBinFutCmReuqest.RequestOrderList(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  sTime := GetTimestamp;
  if sData = '' then
    sBody := Format('timestamp=%s', [sTime])
  else
    sBody := Format('symbol=%s&timestamp=%s', [sData, sTime]);

  sig(sBody);

  if not Request( ekBinance,rmGET, '/dapi/v1/openOrders?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBinFutCmOrderList (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_REQ_ORD, outJson, sRef );

end;


procedure TBinFutCmReuqest.RequestTradeAmt(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  sTime := GetTimestamp;
  sBody := Format('startTime=%s&timestamp=%s', [sData, sTime]);
  sig(sBody);

  if not Request( ekBinance,rmGET, '/dapi/v1/userTrades?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestTradeAmt (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_TRD_AMT, outJson, sData );

end;

procedure TBinFutCmReuqest.RequestCnlOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
  sTime, sBody, outJson, outRes : string;
begin
  if not CheckShareddData( sArr, sData, BC_CNT, 'BinFutCnlOrder') then Exit;

  sTime := GetTimestamp;
  sBody := Format('symbol=%s&orderId=%s&timestamp=%s',
    [ UpperCase(sArr[BC_CODE]), sArr[BC_OID], sTime ]);

  App.DebugLog('RequestBinFutCnlOrder : %s', [ sBody ] );

  sig(sBody);
//  sSig  := CalculateHMACSHA256(sBody,App.ApiConfig.GetSceretKey( ekBinance, mtFutures) );
//  sBody := sBody + Format('&signature=%s', [ sSig ]);
//
//  RestReq.AddParameter('X-MBX-APIKEY',
//      App.ApiConfig.GetApiKey( ekBinance, mtFutures) , pkHTTPHEADER );

  if not Request( ekBinance,rmDELETE, '/dapi/v1/order?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBinFutCnlOrder (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_CNL_ORD, outJson, sRef );

end;

procedure TBinFutCmReuqest.RequestNewOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
  outJson, outRes : string;
  sTime, sBody, sSig : string;
begin
  if not CheckShareddData( sArr, sData, BO_CNT, 'BinFutNewOrder') then Exit;

  sTime := GetTimestamp;
  sBody := Format('symbol=%s&side=%s&type=%s&timeInForce=%s&quantity=%s&price=%s'+
                '&newClientOrderId=%s&reduceOnly=%s&timestamp=%s',
    [ UpperCase(sArr[BO_CODE]),sArr[BO_LS], sArr[BO_TYPE], sArr[BO_TIF]
      , sArr[BO_QTY], sArr[BO_PRC], sArr[BO_CID], sArr[BO_RDO], sTime ]);

  App.DebugLog('RequestBinFutNewOrder : %s', [ sBody ] );

  sig(sBody);

//  sSig  := CalculateHMACSHA256(sBody,App.ApiConfig.GetSceretKey( ekBinance, mtFutures) );
//  sBody := sBody + Format('&signature=%s', [ sSig ]);
//
//  RestReq.AddParameter('X-MBX-APIKEY',
//      App.ApiConfig.GetApiKey( ekBinance, mtFutures) , pkHTTPHEADER );

  if not Request( ekBinance ,rmPOST, '/dapi/v1/order?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBinFutNewOrder (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TExApiTypeDesc[ExApiType], outRes, outJson] );

  PushData( ekBinance, ExApiType, TR_NEW_ORD, outJson, sRef );

end;


end.
