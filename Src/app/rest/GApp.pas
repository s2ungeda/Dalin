unit GApp;

interface

uses
  System.Classes, System.SysUtils

  , UConfig, UTypes

  , ULogWriter , UApiConfigManager

  , URestManager

  , USecureString
  ;

type

  TApp = class
  private

    FEntropy : TSecureString;
    FLog    : TLogger;
    FRootDir: string;
    FLogDir: string;
    FQuoteDir: string;

    FDataDir: string;

    FErrorString: string;
    FApiConfig: TApiConfigManager;
    FConfig: TConfig;

    FPreFix : string;
    FRestManasger: TRestManager;
    function  IsLogLevel(lLevel: TLogLevel): boolean;
    procedure SetEntropy(const Value: string);
    function GetEntropy: string;


  public
    constructor Create;
    destructor  Destroy; override;

    function LoadConfig : boolean;
    function LoadKeys: boolean;
    function SetDirInfo : boolean;

    procedure Log( lLevel : TLogLevel; stPrefix, stData : string ); overload;
    procedure Log( lLevel : TLogLevel; stData : string ); overload;
    procedure Log( lLevel : TLogLevel; const fmt: string; const Args: array of const ); overload;
    procedure Log( lLevel : TLogLevel; stPrefix : string; const fmt: string; const Args: array of const ); overload;
    procedure DebugLog( const fmt: string; const Args: array of const ); overload;
    procedure DebugLog( const fmt: string ); overload;

    procedure CreateWinConfig;

    property Entropy : string read GetEntropy write SetEntropy;

    property  Config : TConfig read FConfig ;
    property  LogDir : string read FLogDir write FLogDir;
    property  RootDir: string read FRootDir write FRootDir;
    property  ApiConfig : TApiConfigManager read FApiConfig;

    property  RestManager : TRestManager read FRestManasger;
    property  ErrorString : string read FErrorString write FErrorString;


  end;

var
  App : TApp;

implementation

uses
  GLibs
  , UApiTypes
  , UConsts
  , UEncrypts
  , System.StrUtils
  ;

{ TApp }

constructor TApp.Create;
var
  i: integer;
  ea : TExchangeApiType;
begin
  FEntropy:= TSecureString.Create;
  FPreFix := 'Rest';
  FApiConfig    := TApiConfigManager.Create;
  FLog    := TLogger.Create('',
                           65536,      // Capacity
                           INFINITE,   // PushTimeout (백프레셔 허용)
                           300,        // PopTimeout (종료 체크 주기)
                           300        // FlushEveryN
                           );

  FRestManasger:= TRestManager.Create;
end;

procedure TApp.CreateWinConfig;
begin

end;

procedure TApp.DebugLog(const fmt: string; const Args: array of const);
begin
  if IsLogLevel(llDebug) then
    FLog.Log(llDebug, FPreFix, Format( fmt, Args ) );
end;

procedure TApp.DebugLog(const fmt: string);
begin
  if IsLogLevel(llDebug) then
    FLog.Log(llDebug,FPreFix, Format( '%s', [fmt] ) );
end;

destructor TApp.Destroy;
var
  i: integer;
  ea : TExchangeApiType;
begin
  App.Log(llInfo, '', '--- Engine free ---');
  FLog.Free;
  FApiConfig.Free;
  FRestManasger.Free;
  FEntropy.Free;

  for i := 0  to High(FApiConfig.ExchangeInfo) do
    for ea := eaSpot to High(TExchangeApiType) do begin
      FreeAndNil(FApiConfig.ExchangeInfo[i].ApiInfo[ea].ApiKey[0].Sec);
      FreeAndNil(FApiConfig.ExchangeInfo[i].ApiInfo[ea].ApiKey[1].Sec);
    end;

  SetLength(FApiConfig.ExchangeInfo, 0);

  inherited;
end;

procedure TApp.SetEntropy(const Value: string);
begin
  FEntropy.Assign(Value);
end;

function TApp.IsLogLevel(lLevel: TLogLevel): boolean;
begin
  if Integer(lLevel) <= FConfig.LOG_LEVEL then
    result := true
  else
    result := false;
end;

function TApp.LoadConfig: boolean;
begin
  if not FConfig.LoadConfig then Exit(false);
  if not ApiConfig.LoadExchangeConfig then Exit(false);

  Result := SetDirInfo;

  FLog.LogDir := FLogDir;
end;

function TApp.LoadKeys: boolean;
var
  stEx, stDiv, stKey, stDir: string;
  KeyArr : TArray<string>;
  I, iCnt: Integer;
  ek : TExchangeKind;  ea: TExchangeApiType;
begin

  Result := false;
  stDir := FDataDir +'\'+APK_FILE;
  if not FileExists(stDir) then Exit;

  if not LoadEncryptedKeyFromFile(stDir, FEntropy, KeyArr) then
    Exit;

  for i := 0 to High(FApiConfig.ExchangeInfo) do
    for ea := eaSpot to High(TExchangeApiType) do begin
      FApiConfig.ExchangeInfo[i].ApiInfo[ea].ApiKey[0].Sec := TSecureString.Create;
      FApiConfig.ExchangeInfo[i].ApiInfo[ea].ApiKey[1].Sec := TSecureString.Create;
    end;

  //iCnt := integer(High(TExchangeKind));
  for I := 0 to High(KeyArr) do
  begin
    if KeyArr[i].IsEmpty then continue;

    stKey:= KeyArr[i];

    stEx := LeftStr(stKey, 3);
    stDiv:= MidStr(stKey, 4, 3);

    if stEx = 'BNS' then begin
      if stDiv = 'API' then
        FApiConfig.ExchangeInfo[0].ApiInfo[eaSpot].ApiKey[0].Key := Copy(stKey, 7, Length(stKey))
      else if stDiv = 'SEC' then
        FApiConfig.ExchangeInfo[0].ApiInfo[eaSpot].ApiKey[0].SetSec(Copy(stKey, 7, Length(stKey)));
    end
    else if stEx = 'BNF' then begin
      if stDiv = 'API' then begin
        FApiConfig.ExchangeInfo[0].ApiInfo[eaFutUsdt].ApiKey[0].Key := Copy(stKey, 7, Length(stKey));
        FApiConfig.ExchangeInfo[0].ApiInfo[eaFutCoin].ApiKey[0].Key := Copy(stKey, 7, Length(stKey));
      end
      else if stDiv = 'SEC' then begin
        FApiConfig.ExchangeInfo[0].ApiInfo[eaFutUsdt].ApiKey[0].SetSec(Copy(stKey, 7, Length(stKey)));
        FApiConfig.ExchangeInfo[0].ApiInfo[eaFutCoin].ApiKey[0].SetSec(Copy(stKey, 7, Length(stKey)));
      end;
    end
    else if stEx = 'UPS' then begin
      if stDiv = 'API' then
        FApiConfig.ExchangeInfo[1].ApiInfo[eaSpot].ApiKey[0].Key := Copy(stKey, 7, Length(stKey))
      else if stDiv = 'SEC' then
        FApiConfig.ExchangeInfo[1].ApiInfo[eaSpot].ApiKey[0].SetSec(Copy(stKey, 7, Length(stKey)));
    end
    else if stEx = 'BT1' then begin
      if stDiv = 'API' then
        FApiConfig.ExchangeInfo[2].ApiInfo[eaSpot].ApiKey[0].Key := Copy(stKey, 7, Length(stKey))
      else if stDiv = 'SEC' then
        FApiConfig.ExchangeInfo[2].ApiInfo[eaSpot].ApiKey[0].SetSec(Copy(stKey, 7, Length(stKey)));
    end
    else if stEx = 'BT2' then begin
      if stDiv = 'API' then
        FApiConfig.ExchangeInfo[2].ApiInfo[eaSpot].ApiKey[1].Key := Copy(stKey, 7, Length(stKey))
      else if stDiv = 'SEC' then
        FApiConfig.ExchangeInfo[2].ApiInfo[eaSpot].ApiKey[1].SetSec(Copy(stKey, 7, Length(stKey)));
    end;
  end;

  Result := true;
end;

procedure TApp.Log(lLevel : TLogLevel; stPrefix: string; const fmt: string;
  const Args: array of const);
begin

  if stPreFix = '' then
    stPreFix := FPreFix;

  if IsLogLevel(lLevel) then
    FLog.Log(lLevel, stPrefix, Format( fmt, Args ) );
end;


procedure TApp.Log(lLevel: TLogLevel; stData: string);
begin
  if IsLogLevel(lLevel) then
    FLog.Log(lLevel, FPreFix, stData);
end;

procedure TApp.Log(lLevel: TLogLevel; const fmt: string;
  const Args: array of const);
begin
  if IsLogLevel(lLevel) then
    FLog.Log(lLevel, FPreFix, Format( fmt, Args ) );
end;

procedure TApp.Log(lLevel : TLogLevel; stPrefix, stData: string);
begin

  if stPreFix = '' then
    stPreFix := FPreFix;

  if IsLogLevel(lLevel) then
    FLog.Log(lLevel, stPrefix, stData);
end;


function TApp.SetDirInfo: boolean;
begin
  Result := true;
  try
    FRootDir  := AppDir;
    FLogDir   := ComposeFilePath([FRootDir, FConfig.LOG_DIR]);
    FQuoteDir := ComposeFilePath([FRootDir, FConfig.QUOTE_DIR]);
    FDataDir  := ComposeFilePath([FRootDir, FConfig.DATA_DIR]);
  except
    Result := false;
  end;

end;

function TApp.GetEntropy: string;
begin
  Result := FEntropy.Reveal;
end;

end.
