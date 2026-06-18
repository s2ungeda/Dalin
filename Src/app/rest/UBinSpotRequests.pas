unit UBinSpotRequests;

interface

uses
  System.Classes, System.SysUtils,
  REST.Client,  Rest.Types,
  UApiTypes, UTypes,
  URestBase
  ;

type
  TBinSpotRequest = class(TRestBase)
  private
    procedure sig(var sData: string);
  public
    procedure RequestNewOrder( sData, sRef : string );  override;
    procedure RequestCnlOrder( sData, sRef : string );  override;
    procedure RequestBalance( sData, sRef : string );   override;
    procedure RequestOrderList( sData, sRef : string ); override;
    procedure RequestOrderbook( aData, sRef : string );
    procedure RequestDnwState(aData, sRef : string );
  end;

implementation

uses
  GApp, GLibs
  , UEncrypts
  , UApiConsts
  , USharedConsts
  ;

{ TBinFutReuqest }

procedure TBinSpotRequest.sig(var sData : string);
var
  sig : string;
begin
  sig   := CalculateHMACSHA256(sData,App.ApiConfig.GetSceretKey( ekBinance, eaSpot) );
  sData := sData + Format('&signature=%s', [ sig ]);

  RestReq.Req.AddParameter('X-MBX-APIKEY',
      App.ApiConfig.GetApiKey( ekBinance, eaSpot) , pkHTTPHEADER );
end;


procedure TBinSpotRequest.RequestBalance(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  sTime := GetTimestamp;
  sBody := Format('timestamp=%s', [sTime]);

  sig(sBody);

  if not Request( ekBinance,rmGET, '/api/v3/account?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestBalance (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_REQ_BAL, outJson, sRef );
end;

// 미체결 리스트..
procedure TBinSpotRequest.RequestOrderbook(aData, sRef: string);
var
  sBody, outJson, outRes : string;
begin
  sBody := Format('symbol=%s&limit=1000', [ Uppercase( aData ) ]);

  if not Request( ekBinance,rmGET, '/api/v3/depth?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestOrderbook (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_ORD_BOOK, outJson, sRef );
end;

procedure TBinSpotRequest.RequestOrderList(sData, sRef: string);
var
  sBody, sTime, outJson, outRes : string;
begin
  sTime := GetTimestamp;
  if sData = '' then
    sBody := Format('timestamp=%s', [sTime])
  else
    sBody := Format('symbol=%s&timestamp=%s', [sData, sTime]);

  sig(sBody);

  if not Request( ekBinance,rmGET, '/api/v3/openOrders?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestOrderList (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_REQ_ORD, outJson, sRef );

end;

procedure TBinSpotRequest.RequestCnlOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
  sTime, sBody, sSig, outJson, outRes : string;
begin
  if not CheckShareddData( sArr, sData, BC_CNT, 'BinSpotCnlOrder') then Exit;

  sTime := GetTimestamp;
  sBody := Format('symbol=%s&orderId=%s&timestamp=%s',
    [ sArr[BC_CODE], sArr[BC_OID], sTime ]);

  App.DebugLog('Bin Spot RequestCnlOrder : %s', [ sBody ] );

  sig(sBody);

  if not Request( ekBinance,rmDELETE, '/api/v3/order?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestCnlOrder (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_CNL_ORD, outJson, sRef );

end;

procedure TBinSpotRequest.RequestDnwState(aData, sRef: string);
var
  outJson, outRes, sTime, sBody, sig : string;
begin
  sTime := GetTimestamp;
  sBody := Format('timestamp=%s', [sTime]);

  sig   := CalculateHMACSHA256(sBody,App.ApiConfig.GetSceretKey( ekBinance, eaSpot) );

  RestReq.Req.AddParameter('timestamp', sTime, pkGETorPOST );
  RestReq.Req.AddParameter('signature', sig, pkGETorPOST );
  RestReq.Req.AddParameter('X-MBX-APIKEY',  App.ApiConfig.GetApiKey( ekBinance, eaSpot) , pkHTTPHEADER );

  if not Request( ekBinance,rmGET, '/sapi/v1/capital/config/getall', outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestDnwState (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_DNW_STATE, outJson, sRef );
end;

procedure TBinSpotRequest.RequestNewOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
  sRsrc, outJson, outRes : string;
  sTime, sBody, sSig : string;
begin
  if not CheckShareddData( sArr, sData, BO_CNT, 'BinSpotRequestNewOrder') then Exit;

  sTime := GetTimestamp;
  sBody := Format('symbol=%s&side=%s&type=%s&timeInForce=GTC&quantity=%s&price=%s'+
                '&newClientOrderId=%s&timestamp=%s',
    [ sArr[BO_CODE],sArr[BO_LS], sArr[BO_TYPE], sArr[BO_QTY], sArr[BO_PRC]
      , sArr[BO_CID], sTime ]);

  App.DebugLog('Bin Spot RequestNewOrder : %s', [ sBody ] );

  sig(sBody);

  if not Request( ekBinance ,rmPOST, '/api/v3/order?'+sBody, outJson, outRes ) then
    App.Log( llError, '', 'Failed %s %s RequestNewOrder (%s, %s)',
    [ TExchangeKindDesc[ekBinance], TMarketTypeDesc[mtSpot], outRes, outJson] );

  PushData( ekBinance, eaSpot, TR_NEW_ORD, outJson, sRef );

end;


end.

