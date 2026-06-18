unit UUpbitRequests;

interface

uses
  System.Classes, System.SysUtils,
  REST.Client,  Rest.Types,
  JOSE.Core.JWT   ,JOSE.Core.Builder, JOSE.Core.JWA ,
  UApiTypes, UTypes,
  URestBase, URestRequests
  ;

type
  TUpbitRequest = class(TRestBase)
  private
    procedure SetToken(aReq : TRequest; var jwt : TJWT; const sQuery: string);
    procedure OnResult(ReqType : char; OutJosn, Ref : string); override;
    function ErrToStr(bLimit: boolean) : string;

    procedure UpdateLRemainValue(const sRemain: string); override;
    procedure MarkExhausted(const sRemain: string); override;
  public
    procedure RequestNewOrder( sData, sRef : string ); override;
    procedure RequestCnlOrder( sData, sRef : string ); override;
    procedure RequestOrderList(sData, sRef : string ); override;
    procedure RequestPosition( sData, sRef : string ); override;
    procedure RequestBalance( sData, sRef : string ); override;
    procedure RequestOrdDetail( sData, sRef : string ); override;

    function IsAvailable: boolean; override;
    function TryGetBucket(sGroup: string): boolean;
  end;

implementation

uses
  GApp, GLibs
  , UApiConsts, USharedConsts
  , UEncrypts
  , system.Hash
  , System.Json
  , FRestMain
  ;

{ TUpbitRequest }

function ParseRemain(const sRemain: string; var AGroup: string;
   var ACapacity, ARemain: integer): boolean;
var
  Parts: TArray<string>;
  Part, Tmp: string;
begin
  Result := true;
  try
    Parts := sRemain.Split([';']);
    for Part in Parts do
    begin
      Tmp := Trim(Part);
      if Tmp.StartsWith('group=') then
        AGroup := Copy(Tmp, 7, Length(Tmp))
      else if Tmp.StartsWith('min=') then
        TryStrToInt(Copy(Tmp, 5, Length(Tmp)), ACapacity)
      else if Tmp.StartsWith('sec=') then
        TryStrToInt(Copy(Tmp, 5, Length(Tmp)), ARemain);
    end;
  except
    Result := false;
  end;
end;

procedure TUpbitRequest.UpdateLRemainValue(const sRemain: string);
var
  Group: string;
  SecRemaining, ACapacity: Integer;
  Bucket: TTokenBucket;
begin
  // ÆÄ½Ì: "group=default; min=1800; sec=29"
  if sRemain = '' then Exit;
  SecRemaining := -1;
  if not ParseRemain(sRemain, Group, ACapacity, SecRemaining) then Exit;
  if SecRemaining >= 0 then
  begin
    Bucket := GetOrCreateBucket(Group);
    if Bucket = nil then
      Bucket  := New(Group, ACapacity div 60);
    Bucket.SetTokens(SecRemaining);
  end;
end;

procedure TUpbitRequest.MarkExhausted(const sRemain: string);
var
  Group: string;
  SecRemaining, ACapacity: Integer;
  Bucket: TTokenBucket;
begin
  // ÆÄ½Ì: "group=default; min=1800; sec=29"
  if sRemain = '' then Exit;
  if not ParseRemain(sRemain, Group, ACapacity, SecRemaining) then Exit;
  Bucket := GetOrCreateBucket(Group);
  if Bucket = nil then
    Bucket  := New(Group, ACapacity div 60);
  Bucket.MarkExhausted;
end;

procedure TUpbitRequest.SetToken(aReq: TRequest; var jwt: TJWT;
  const sQuery: string);
var
  vHash : THashSHA2;
  sToken, sSig: string;
begin
  with jwt do
  begin
    Claims.SetClaimOfType<string>('access_key', App.ApiConfig.GetApiKey(ExKind, ExApiType));
    Claims.SetClaimOfType<string>('nonce', GetUUID );
    if not sQuery.IsEmpty then
    begin
      Claims.SetClaimOfType<string>('query_hash', vHash.gethashstring( sQuery, SHA512 ) );
      Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );
    end;
  end;

  sSig := TJOSE.SerializeCompact(App.ApiConfig.GetSceretKey(ExKind, ExApiType),
                                 TJOSEAlgorithmId.HS256, jwt);
  sToken:= Format('Bearer %s', [sSig]);

  aReq.Req.
    AddParameter('Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );
end;

function TUpbitRequest.TryGetBucket(sGroup: string): boolean;
var
  bucket: TTokenBucket;
begin
  bucket := GetOrCreateBucket(sGroup);
  if bucket = nil then Exit (true);

  Result := bucket.TryAcquire;
  App.DebugLog('%s Rate Limit  :%s, %d', [TExchangeKindDesc[ExKind], sGroup, bucket.Tokens] );
end;

function TUpbitRequest.ErrToStr(bLimit: boolean): string;
begin
  if bLImit then

  Result :=
    '{'+
      '"error": {'+
        '"name": "rate_limit",'+
        '"message": "Too many requests order"'+
      '}'+
    '}'
  else

  Result :=
    '{'+
      '"error": {'+
        '"name": "send_error",'+
        '"message": "Failed send order"'+
      '}'+
    '}'
end;

function TUpbitRequest.IsAvailable: boolean;
begin
  Result := AsyncRESTs.GetReqCount(1100) < 8;
//  App.DebugLog('available : %d, %d',[AsyncRESTs.Wroks.Count,AsyncRESTs.GetReqCount]) ;
end;



procedure TUpbitRequest.OnResult(ReqType: char; OutJosn, Ref: string);
begin
  PushData(ReqType, OutJosn, Ref );
end;

procedure TUpbitRequest.RequestBalance(sData, sRef: string);
var
  sArr  : TArray<string>;
  //aExKind : TExchangeKind;
  aReq : TRequest;

  LToken: TJWT;
  guid : TGUID;
  sSig, sID, sToken, outRes, sRsrc, outJson : string;
begin

  //if not CheckShareddData( sArr, sData, TL_CNT, 'UptBalance') then Exit;

  aReq := AsyncRESTs.GetItem;
  if aReq = nil then
  begin
    App.Log(llError, '%s RequestBalance Req not enough ', [TExchangeKindDesc[ExKind]] );
    Exit;
  end;

  LToken:= TJWT.Create(TJWTClaims);
  try
    sID := GetUUID;
    sRsrc := '/v1/accounts';

    SetToken(aReq, LToken, '');

    aReq.SetParam(rmGET, sRsrc, TR_REQ_BAL, sRef);
    if not AsyncRESTs.RequestAsync(aReq) then
    begin
      App.Log(llError, '%s Failed RequestBalance %s', [TExchangeKindDesc[ExKind], sRef] );
      Exit;
    end;

//    if not Request( aExKind ,rmGET, sRsrc, outJson, outRes ) then
//      App.Log( llError, '', 'Failed %s RequestBitOrderList (%s, %s)',
//      [ TExchangeKindDesc[aExKind], outRes, outJson] );
//
//    PushData(TR_REQ_BAL, outJson, sRef );

  finally
    LToken.Free;
  end;
end;

procedure TUpbitRequest.RequestCnlOrder(sData, sRef: string);
var
  sArr  : TArray<string>;
  aExKind : TExchangeKind;

  LToken: TJWT;
  sQuery, outRes, sRsrc, outJson : string;
  aReq : TRequest;
begin

  if not TryGetBucket('default') then
  begin
    App.Log(llError, '%s Failed RequestCnlOrder --> Order Limit %s (%d,%d) ', [TExchangeKindDesc[ExKind], sRef,
      AsyncRESTs.Wroks.Count,AsyncRESTs.GetReqCount] );
    PushData(TR_CNL_ORD, ErrToStr(true), sRef );
    Exit;
  end;

  if not CheckShareddData( sArr, sData, UC_CNT, 'UptCnlOrder') then Exit;

  LToken:= TJWT.Create(TJWTClaims);
  try

    sQuery := 'uuid='+sArr[UC_UID];
    sRsrc  := '/v1/order?'+sQuery;

    if FrmRestMain.CheckBox1.Checked then
    begin
        SetToken(RestReq, LToken, sQuery);

        if not Request(ExKind ,rmDELETE, sRsrc, outJson, outRes ) then
          App.Log( llError, '', 'Failed %s RequestUptCnlOrder (%s, %s)',
          [ TExchangeKindDesc[aExKind], outRes, outJson] );

        PushData(TR_CNL_ORD, outJson, sRef );
    end else
    begin

        aReq := AsyncRESTs.GetItem;
        if aReq = nil then
        begin
          App.Log(llError, '%s RequestCnlOrder %s Req not enough ', [TExchangeKindDesc[ExKind], sRef] );
          Exit;
        end;

        SetToken(aReq, LToken, sQuery);

        aReq.SetParam(rmDELETE, sRsrc, TR_CNL_ORD, sRef);
        if not AsyncRESTs.RequestAsync(aReq) then
        begin
          App.Log(llError, '%s Failed RequestCnlOrder %s ', [TExchangeKindDesc[ExKind], sRef] );
          PushData(TR_CNL_ORD, ErrToStr(false), sRef );
          Exit;
        end;
    end;

  finally
    LToken.Free;
  end;
end;

procedure TUpbitRequest.RequestNewOrder(sData, sRef: string);
var
  sArr  : TArray<string>;

  LToken: TJWT;

  sQuery, outRes, sRsrc, outJson : string;
  aObj : TJsonObject;
  aReq : TRequest;
begin

  if not TryGetBucket('order') then
  begin
    App.Log(llError, '%s Failed RequestNewOrder --> Order Limit %s (%d,%d) ', [TExchangeKindDesc[ExKind], sRef,
      AsyncRESTs.Wroks.Count,AsyncRESTs.GetReqCount] );
    PushData(TR_NEW_ORD, ErrToStr(true), sRef );
    Exit;
  end;

  if not CheckShareddData( sArr, sData, UO_CNT, 'UptNewOrder') then Exit;

  aObj  := TJsonObject.Create;
  LToken:= TJWT.Create(TJWTClaims);
  try

    sQuery := format('market=%s&side=%s&price=%s&volume=%s&order_type=%s&identifier=%s', [
      sArr[UO_CODE], sArr[UO_LS], sArr[UO_PRC], sArr[UO_QTY], sArr[UO_TYPE], sRef
      ]);
    sRsrc  := '/v1/orders?'+sQuery;

    with aObj do
    begin
      AddPair('market', sArr[UO_CODE] );
      AddPair('side',   sArr[UO_LS]);
      AddPair('price',  sArr[UO_PRC]);
      AddPair('volume', sArr[UO_QTY]);
      AddPair('order_type',sArr[UO_TYPE]);
      AddPair('identifier', sRef);
    end;


    if FrmRestMain.CheckBox1.Checked then
    begin
          SetToken(RestReq, LToken, sQuery);
          RestReq.Req.Body.Add(aObj);
          if not Request( ExKind ,rmPOST, sRsrc, outJson, outRes ) then
            App.Log( llError, '', 'Failed %s RequestUptNewOrder (%s, %s)',
            [ TExchangeKindDesc[ExKind], outRes, outJson] );

          PushData(TR_NEW_ORD, outJson, sRef );

    end else
    begin

          aReq := AsyncRESTs.GetItem;
          if aReq = nil then
          begin
            App.Log(llError, '%s RequestNewOrder %s Req not enough ', [TExchangeKindDesc[ExKind], sRef] );
            Exit;
          end;

          SetToken(aReq, LToken, sQuery);
          aReq.Req.Body.Add(aObj);

          aReq.SetParam(rmPOST, sRsrc, TR_NEW_ORD, sRef);
          if not AsyncRESTs.RequestAsync(aReq) then
          begin
            App.Log(llError, '%s Failed RequestNewOrder %s ', [TExchangeKindDesc[ExKind], sRef] );
            PushData(TR_NEW_ORD, ErrToStr(false), sRef );
            Exit;
          end;
    end;

  finally
    LToken.Free;
    aObj.Free;
  end;

end;

procedure TUpbitRequest.RequestOrdDetail(sData, sRef: string);
var
  sArr  : TArray<string>;
  //aExKind : TExchangeKind;
  aReq : TRequest;

  LToken: TJWT;

  sSig, sID, sToken, sRsrc, sQuery : string;
begin

  //if not CheckShareddData( sArr, sData, TL_CNT, 'UptBalance') then Exit;

  aReq := AsyncRESTs.GetItem;
  if aReq = nil then
  begin
    App.Log(llError, '%s RequestOrdDetail Req not enough ', [TExchangeKindDesc[ExKind]] );
    Exit;
  end;

  LToken:= TJWT.Create(TJWTClaims);
  try
    sID := GetUUID;

    if sRef.IsEmpty then
      sQuery  := 'uuid='+sData
    else
      sQuery  := 'identifier='+sRef;

    sRsrc := '/v1/order?'+sQuery;

    SetToken(aReq, LToken, sQuery);

    aReq.SetParam(rmGET, sRsrc, TR_ORD_DETAIL, sData);
    if not AsyncRESTs.RequestAsync(aReq) then
    begin
      App.Log(llError, '%s Failed RequestOrdDetail %s', [TExchangeKindDesc[ExKind], sRef] );
      PushData(TR_ORD_DETAIL, ErrToStr(false), sData );
      Exit;
    end;

  finally
    LToken.Free;
  end;

end;

procedure TUpbitRequest.RequestOrderList(sData, sRef: string);
begin
  inherited;

end;

procedure TUpbitRequest.RequestPosition(sData, sRef: string);
begin
  inherited;

end;



end.
