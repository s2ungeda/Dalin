unit UUpbitDepositList;

interface

uses
  System.Classes, System.SysUtils,

  UApiWithdraw,

  UApiTypes, UApiConsts

  ;

type

  TUpbitDepositList = class( TApiWithdraw )
  private
    procedure RequestDepositList;
    procedure DoWithdraw; override;
    procedure Parse(const aType, aData: string);
  public
    Constructor Create; override;
    Destructor  Destroy; override;
    procedure RecvRequest(Sender : TObject);  override;
  end;

implementation

uses
  GApp, GLibs
  , UBithSpot
  , REST.Types
  , System.JSON
  , IdGlobal
  , idcodermime
  , Web.HTTPApp
  , UEncrypts
  , System.Hash
  , JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.JWS,
  JOSE.Core.JWA,
  JOSE.Core.Builder,
  JOSE.Types.JSON,
  JOSE.Encoding.Base64
  ;

{ TBitWithdraw }


constructor TUpbitDepositList.Create;
begin
  inherited Create;

end;

destructor TUpbitDepositList.Destroy;
begin

  inherited;
end;

procedure TUpbitDepositList.DoWithdraw;
begin
  RequestDepositList;
end;


procedure TUpbitDepositList.RequestDepositList;
var
  LToken: TJWT;
  guid : TGUID;
  sSig, sID, sToken, sOut, sJson, sRsrc : string;
  vHash : THashSHA2;
begin

  LToken:= TJWT.Create(TJWTClaims);
  try
    sID := GetUUID;

    sJson  := format('currency=%s&limit=3', [ Param.currency]) ;
    sOut  := vHash.gethashstring( sJson, SHA512 );

    LToken.Claims.SetClaimOfType<string>('access_key', App.Engine.ApiConfig.GetApiKey( ekUpbit, mtSpot));
    LToken.Claims.SetClaimOfType<string>('nonce', sID );
    LToken.Claims.SetClaimOfType<string>('query_hash', sOut );

    LToken.Claims.SetClaimOfType<string>('query_hash_alg', 'SHA512' );

    Req.Client.Params.Clear;
    Req.Req.Params.Clear;

    sSig := TJOSE.SerializeCompact(App.Engine.ApiConfig.GetSceretKey(ekUpbit, mtSpot),  TJOSEAlgorithmId.HS512, LToken);
    sToken := Format('Bearer %s', [sSig ]);

    with Req do
      Req.AddParameter( 'Authorization', sToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode] );

    sRsrc := '/v1/deposits?'+sJson;
    Req.init(rmGET, 'https://api.upbit.com', sRsrc, 'deposit' )  ;

    Req.RequestAsync;
  finally
    LToken.Free;
  end;

end;


procedure TUpbitDepositList.Parse(const aType, aData: string);
var
  aObj, aSub : TJsonObject;
  aArr  : TJsonArray;
  aErr, aVal : TJsonValue;
  aPair: TJsonPair;
  i: Integer;
  stTmp : string;
  bOK : boolean;
begin
  if aDAta = '' then
  begin
    DoNotify( '출금 요청 실패', 999);
    Exit;
  end;

  if aType = 'deposit' then
  begin
    aArr  := TJsonObject.ParseJSONValue( aData) as TJsonArray;
    try
      aErr  := aObj.GetValue('error');
      if aErr <> nil then
      begin
        DoNotify(aErr.GetValue<string>('message'), 999 );
        Exit;
      end;

      for I := 0 to aArr.Size-1 do
      begin
        aVal  := aArr.Get(i) ;
        if (Req.Field1 = aVal.GetValue<string>('currency')) and ( Req.Field2 = aVal.GetValue<string>('net_type')) then
        begin
          stTmp := aVal.GetValue<string>('secondary_address', '');
//          FAddress.Add(aVal.GetValue<string>('withdraw_address')+','+stTmp);
        end;
      end;

      DoNotify(aType);

    finally
      FreeAndNil(aArr);
      Req.Field1 := ''; Req.Field2 := '';
    end;
  end;

end;

procedure TUpbitDepositList.RecvRequest(Sender: TObject);
begin
  Parse( Req.Name, Req.Rsp.Content );
end;


end.
