unit UBithumbRequests;

interface

uses
  System.Classes, System.SysUtils,
  REST.Client,  Rest.Types,
  UApiTypes, UTypes,
  URestBase , URestRequests
  , JOSE.Core.JWT
  ;


const
  TOO_MANY : array [0..1] of string = ('rate_limit','Too many requests order');
  CNL_ERR : array [0..1] of string = ('send_error','Failed Cancel Request');
  NEW_ERR : array [0..1] of string = ('send_error','Failed NewOrder Request');

type
  TBithumbRequest = class(TRestBase)
  private
    procedure SetSig(aReq : TRequest; const sVal, sTime, sRsrc: string); overload;
    procedure SetSig(const sVal, sTime, sRsrc: string); overload;
    procedure SetToken(aReq: TRequest; var jwt: TJWT; const sQuery: string);
    procedure OnResult(ReqType : char; OutJosn, Ref : string); override;

    function ErrorMessage(s:array of string): string;
  public
    procedure RequestNewOrder(sData, sRef : string ); override;
    procedure RequestCnlOrder(sData, sRef : string ); override;
    procedure RequestOrderList(sData, sRef : string ); override;
    procedure RequestPosition( sData, sRef : string ); override;
    procedure RequestBalance( sData, sRef : string ); override;
    procedure RequestOrdDetail( sData, sRef : string ); override;

    function IsAvailable : boolean; override;
  end;

implementation

uses
  GApp, GLibs
  , UApiConsts, USharedConsts
  , FRestMain
  , UEncrypts
  , IdCoderMIME, IdGlobal, System.Hash
  , JOSE.Core.Builder, JOSE.Core.JWA
  , JOSE.Types.JSON

  ;

{ TBithumbRequest }

procedure TBithumbRequest.SetSig(const sVal, sTime, sRsrc : string);
var
  sBody : string;
begin

  sBody	:= TIdEncoderMIME.EncodeString(
    CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey(ExKind, ExApiType) )
    , IndyTextEncoding_UTF8 );

  with RestReq.Req do
  begin
    AddParameter('Api-Key', App.ApiConfig.GetApiKey(ExKind, ExApiType), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
    AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
    AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
    AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
  end;

end;

procedure TBithumbRequest.SetToken(aReq: TRequest; var jwt: TJWT;
  const sQuery: string);
var
  vHash : THashSHA2;
  sToken, sSig: string;
begin
  with jwt do
  begin
    Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey(ExKind, ExApiType, 1));
    Claims.SetClaimOfType<string>('nonce', GetUUID );
    Claims.SetClaimOfType<int64>('timestamp', StrToInt64(GetTimestamp) );
    if not sQuery.IsEmpty then
    begin
      Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
      Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
    end;
  end;

  sSig := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey(ExKind, ExApiType, 1),
                                 TJOSEAlgorithmId.HS256, jwt);
  sToken:= Format('Bearer %s', [sSig]);

  aReq.Req.AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
end;

function TBithumbRequest.ErrorMessage(s:array of string): string;
begin
  Result := '{"error":{"name":"'+s[0]+'","message":"'+s[1]+'"}}';
end;

function TBithumbRequest.IsAvailable: boolean;
begin
  Result := AsyncRESTs.GetReqCount <= 100;
end;

procedure TBithumbRequest.OnResult(ReqType : char; OutJosn, Ref : string);
begin
  PushData(ReqType, OutJosn, Ref );
end;

// 발란스가 아닌 Assets 조회...함수명 바꾸기 귀찮아서.
procedure TBithumbRequest.RequestBalance(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  sParam1 : string;
  I: Integer;

  aReq : TRequest;

begin
  if not CheckShareddData( sArr, sData, TB_CNT, 'BitBalance') then Exit;

  aReq := AsyncRESTs.GetItem;
  if aReq = nil then
  begin
    App.Log(llError, '%s RequestBalance Req not enough ', [TExchangeKindDesc[ExKind]] );
    Exit;
  end;

  try
    sParam1	:= sArr[TB_CODE];
    sRsrc 	:= '/info/balance';
    sTime 	:= GetTimestamp;
    sVal		:= EncodePath( sRsrc, Format('endPoint=%s&currency=%s', [ sRsrc, sParam1 ] ), sTime );

    SetSig(aReq, sVal, sTime, sRsrc);

    with aReq.Req do
    begin
      AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
      AddParameter('currency', sParam1, TRESTRequestParameterKind.pkREQUESTBODY);
    end;

    aReq.SetParam(rmPOST, sRsrc, TR_REQ_BAL);
    if not AsyncRESTs.RequestAsync(aReq) then
    begin
      App.Log(llError, '%s Failed RequestBalance', [TExchangeKindDesc[ExKind]] );
      Exit;
    end;
           {
//
    RestReq.Req.AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
    RestReq.Req.AddParameter('currency', sParam1, TRESTRequestParameterKind.pkREQUESTBODY);

    if not Request(ExKind ,rmPOST, sRsrc, outJson, outRes ) then
      App.Log( llError, '', 'Failed %s RequestBitBalance (%s, %s)',
      [ TExApiTypeDesc[eaSpot], outRes, outJson] );

   	PushData(TR_REQ_BAL, outJson, sRef );

     //RequestAsync(aReq, rmPOST, sRsrc);
         }
	except
  end;

end;

procedure TBithumbRequest.RequestCnlOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
	sRsrc, sTime, sBody, sVal, outJson, outRes : string;
  aReq : TRequest;
  LToken: TJWT;
begin

  if not IsAvailable then
  begin
    App.Log(llError, '%s Failed RequestCnlOrder --> Order Limit %s (%d,%d) ', [TExchangeKindDesc[ExKind], sRef,
      AsyncRESTs.Wroks.Count,AsyncRESTs.GetReqCount] );
    PushData(TR_CNL_ORD, ErrorMessage(TOO_MANY), sRef );
    Exit;
  end;

  if not CheckShareddData( sArr, sData, TC_CNT, 'BitCnlOrder') then
  begin
    PushData(TR_CNL_ORD, ErrorMessage(CNL_ERR), sRef );
    Exit;
  end;

  if FrmRestMain.CheckBox1.Checked then
  begin
    PushData(TR_CNL_ORD, ErrorMessage(CNL_ERR), sRef );
  end else
  begin

      aReq := AsyncRESTs.GetItem;
      if aReq = nil then
      begin
        App.Log(llError, '%s RequestCnlOrder Req not enough ', [TExchangeKindDesc[ExKind]] );
        PushData(TR_CNL_ORD, ErrorMessage(CNL_ERR), sRef );
        Exit;
      end;

      LToken:= TJWT.Create(TJWTClaims);
      try
        try
          sRsrc 	:= '/v2/order';
          sTime 	:= GetTimestamp;
          sVal		:= 'order_id='+ sArr[TC_OID];

          SetToken(aReq, LToken, sVal);
          aReq.SetParam(rmDELETE, sRsrc+'?'+sVal, TR_CNL_ORD, sRef);

          if not AsyncRESTs.RequestAsync(aReq) then
          begin
            App.Log(llError, '%s Failed RequestCnlOrder %s ', [TExchangeKindDesc[ExKind], sRef] );
            PushData(TR_CNL_ORD, ErrorMessage(CNL_ERR), sRef );
            Exit;
          end;
        except
          on e: Exception do
          begin
            PushData(TR_CNL_ORD, ErrorMessage(CNL_ERR), sRef );
            App.Log(llError, '%s Fatal RequestCnlOrder %s %s', [TExchangeKindDesc[ExKind],
              sRef, e.Message]  )
          end;
        end;
      finally
        LToken.Free;
      end;
  end;
end;

procedure TBithumbRequest.RequestNewOrder(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, sTime, sBody, sVal, outJson, outRes : string;
  sParam1 : string;
  I: Integer;
  aReq : TRequest;
  LToken: TJWT;
  aBody : TJsonObject;
begin

  if not IsAvailable then
  begin
    App.Log(llError, '%s Failed RequestNewOrder --> Order Limit %s (%d,%d) ', [TExchangeKindDesc[ExKind], sRef,
      AsyncRESTs.Wroks.Count,AsyncRESTs.GetReqCount] );
    PushData(TR_NEW_ORD, ErrorMessage(TOO_MANY), sRef );
    Exit;
  end;

  if not CheckShareddData( sArr, sData, TO_CNT, 'BitNewOrder') then
  begin
    PushData(TR_NEW_ORD, ErrorMessage(NEW_ERR), sRef );
    Exit;
  end;


    if FrmRestMain.CheckBox1.Checked then
    begin
      PushData(TR_NEW_ORD, ErrorMessage(NEW_ERR), sRef );
    end else
    begin

      var sKey := App.ApiConfig.GetApiKey(ExKind, eaSpot, 1);
      if (sKey = DEFAULT_STR) or (sKey.IsEmpty) then
        Exit;

      aBody := TJsonObject.Create;
      LToken:= TJWT.Create(TJWTClaims);
      try
        try
          aReq := AsyncRESTs.GetItem;
          if aReq = nil then
          begin
            App.Log(llError, '%s RequestNewOrder Req not enough ', [TExchangeKindDesc[ExKind]] );
            PushData(TR_NEW_ORD, ErrorMessage(NEW_ERR), sRef );
            Exit;
          end;

          ////
          ///   New Version
          with aBody do
          begin
            AddPair('market',     sArr[TO_CODE]);
            AddPair('side',       sArr[TO_LS]);
            AddPair('order_type', sArr[TO_TYPE]);
            AddPair('price',      sArr[TO_PRC]);
            AddPair('volume',     sArr[TO_QTY]);
            AddPair('client_order_id',  sRef);
          end;

          sRsrc 	:= '/v2/orders';
          sVal		:= Format('market=%s&side=%s&order_type=%s&price=%s&volume=%s&client_order_id=%s', [
              sArr[TO_CODE], sArr[TO_LS], sArr[TO_TYPE], sArr[TO_PRC], sArr[TO_QTY], sRef
            ]);

          SetToken(aReq, LToken, sVal);
          aReq.SetParam(rmPOST, sRsrc+'?'+sVal, TR_NEW_ORD, sRef);
          aReq.Req.Body.Add(aBody);

          if not AsyncRESTs.RequestAsync(aReq) then
          begin
            App.Log(llError, '%s Failed RequestNewOrder %s ', [TExchangeKindDesc[ExKind], sRef] );
            PushData(TR_NEW_ORD, ErrorMessage(NEW_ERR), sRef );
            Exit;
          end;
        except
          on e: Exception do
          begin
            PushData(TR_NEW_ORD, ErrorMessage(NEW_ERR), sRef );
            App.Log(llError, '%s Fatal NewOrder Request %s %s', [TExchangeKindDesc[ExKind],
              sRef, e.Message] );
          end;
        end;
      finally
        LToken.Free;
        aBody.Free;
      end;
    end;


end;

procedure TBithumbRequest.RequestOrdDetail(sData, sRef: string);
var
	sRsrc, sJson, sOut, sVal, sKey : string;
  LToken: TJWT;
  aReq : TRequest;
  vHash : THashSHA2;
begin

  sKey := App.ApiConfig.GetApiKey(ExKind, eaSpot, 1);
  if (sKey = DEFAULT_STR) or (sKey.IsEmpty) then
    Exit;

  LToken:= TJWT.Create(TJWTClaims);
  try
    try

      aReq  := AsyncRESTs.GetItem;

      if sRef.IsEmpty then
        sVal	:= 'uuid='+ sData
      else
        sVal  := 'client_order_id='+sRef;

      sRsrc := '/v1/order?'+sVal;

      SetToken(aReq, LToken, sVal);

      aReq.SetParam(rmGET, sRsrc, TR_ORD_DETAIL, sRef);
      if not AsyncRESTs.RequestAsync(aReq) then
      begin
        App.Log(llError, '%s Failed RequestOrdDetail %s ', [TExchangeKindDesc[ExKind], sRef] );
        PushData(TR_NEW_ORD, '{"status":"999","message":"Failed RequestOrdDetail Request"}', sRef );
        Exit;
      end;

//      if Request(rmGET, sRsrc+'?'+sVal, '', sJson, sOut ) then
//      begin
//        gBithReceiver.ParseOrders( sJson );
//      end else
//      begin
//        App.Log( llError, '', 'Failed %s RequestOrders (%s, %s)',
//          [ TExchangeKindDesc[GetExKind], sOut, sJson] );
//        Exit( false );
//      end;

    except
    end;
  finally
    LToken.Free;
  end;


end;

procedure TBithumbRequest.RequestOrderList(sData, sRef: string);
var
  sArr  : TArray<string>;

	sRsrc, outJson, outRes, sTime, sBody, sVal, sSig : string;
  I: Integer;
  aExKind : TExchangeKind;

  aReq : TRequest;
begin
  if not CheckShareddData( sArr, sData, TL_CNT, 'BitOrderList') then Exit;

  aReq := AsyncRESTs.GetItem;
  if aReq = nil then
  begin
    App.Log(llError, '%s RequestOrderList Req not enough ', [TExchangeKindDesc[aExKind]] );
    Exit;
  end;

  try
    sRsrc 	:= '/info/orders';
    sTime 	:= GetTimestamp;
    sVal	:= EncodePath( sRsrc, Format('endPoint=%s&order_currency=%s', [ sRsrc, sArr[TL_CODE]] ), sTime );

    SetSig(aReq, sVAl, sTime, sRsrc);

    with aReq.Req do
    begin
    	AddParameter('order_currency',sArr[TL_CODE], TRESTRequestParameterKind.pkREQUESTBODY);
    end;

    aReq.SetParam(rmPOST, sRsrc, TR_REQ_ORD);
    if not AsyncRESTs.RequestAsync(aReq)  then
    begin
      App.Log(llError, '%s Failed RequestOrderList ', [TExchangeKindDesc[aExKind]] );
      Exit;
    end;

//    with RestReq.Req do
//    begin
//    	AddParameter('order_currency',sArr[TL_CODE], TRESTRequestParameterKind.pkREQUESTBODY);
//    end;

    //  sync
    {
    if not Request( aExKind ,rmPOST, sRsrc, outJson, outRes ) then
      App.Log( llError, '', 'Failed %s RequestBithumbOrderList (%s, %s)',
      [ TExchangeKindDesc[aExKind], outRes, outJson] );

   	PushData(TR_REQ_ORD, outJson, sRef );
    }

	except
  end;
end;

procedure TBithumbRequest.RequestPosition(sData, sRef: string);
begin
  inherited;

end;

procedure TBithumbRequest.SetSig(aReq: TRequest; const sVal, sTime,
  sRsrc: string);
var
  sBody : string;
begin

  sBody	:= TIdEncoderMIME.EncodeString(
    CalculateHMACSHA512( sVal, App.ApiConfig.GetSceretKey(ExKind, ExApiType) )
    , IndyTextEncoding_UTF8 );

  with aReq.Req do
  begin
    AddParameter('Api-Key', App.ApiConfig.GetApiKey(ExKind, ExApiType), TRESTRequestParameterKind.pkHTTPHEADER );//, [poDoNotEncode]);
    AddParameter('Api-Sign', sBody , TRESTRequestParameterKind.pkHTTPHEADER , [poDoNotEncode]);
    AddParameter('Api-Nonce', sTime , TRESTRequestParameterKind.pkHTTPHEADER );
    AddParameter('endPoint', sRsrc, TRESTRequestParameterKind.pkREQUESTBODY);
  end;

end;

end.
