unit UExchangeRate;

interface

uses
  System.Classes, System.SysUtils, System.DateUtils,

  System.JSON,  Rest.Json , Rest.Types ,

  UExchange,  UTerms,

  UApiTypes

  ;

type

  TExchangeRate = class//( TExchange )
  private
    FExRate : double;
    FLastTime: TDateTime;
    FExchangeRateItems: TTerms;
    FUpdateTime: TDateTime;

    function GetValue: double;
    procedure SetValue(const val: double);
  public

    Constructor Create( aObj : TObject);//; eaType : TExchangeApiType);
    Destructor  Destroy; override;

    function GetExRate : double;
    function GetAvgExRate( iRange : integer ) : double;
    function LastUpdateBetween : integer;

    property Value : double read GetValue write SetValue;
    property LastTime : TDateTime read FLastTime write FLastTime;
    property UpdateTime: TDateTime read FUpdateTime;
    property ExchangeRateItems: TTerms read FExchangeRateItems;
  end;


implementation

uses
  GApp, GLibs
  ,UConsts
  ,Math
  , UTypes
  ;

{ TExchangeRate }

constructor TExchangeRate.Create(aObj: TObject);//; eaType : TExchangeApiType);
begin
//  inherited Create( aObj, eaType );
  FExRate := 0;
  FLastTime := 0;
//  FQueryExRate := nil;
  FExchangeRateItems:= TTerms.Create;
end;

destructor TExchangeRate.Destroy;
begin

  FExchangeRateItems.Free;
  inherited;
end;



function TExchangeRate.GetAvgExRate(iRange: integer): double;
var
  i, j, iCount : integer;
  dSum : double;
  aItem : TTermItem;
begin

  if (FExchangeRateItems.Count <= 0 ) or ( iRange <= 0 ) then
    Exit (FExRate);

  if iRange > FExchangeRateItems.Count then
    iCount  := FExchangeRateItems.Count
  else
    iCount  := iRange;

  j := 0;  dSum := 0;
  for I := FExchangeRateItems.Count-1 downto 0 do
  begin

    aItem := FExchangeRateItems.Term[i];
    if aItem <> nil then
    begin
      dSum := dSum + aItem.C;
      inc( j );
    end;

    if j >= iCount then break;
  end;

  Result :=  dSum / iCount;

//  var sRate : string;
//
//  if Result > 0  then
//    sRate  := Format('%.2f', [ abs(FExRate - Result) / Result * 100 ] )
//  else
//    sRate  := Format('%.2f', [ FExRate ] );
//
//  App.Log(llInfo, 'ExRate','환 이격 %s  =  avg(%.2n), last(%.2n) (분모)%d, %d, %d)', [ sRate, Result, FExRate, iCount, j, iRange ]  );

end;

function TExchangeRate.GetExRate: double;
begin
//  if QueryExRate.LastValue <> '0' then
//    FExRate := StrToFloatDef( QueryExRate.LastValue, 0.0 );
  Result  := FExRate;
end;

function TExchangeRate.GetValue: double;
begin
  if FExRate <= PRICE_EPSILON then
    Result := 1
  else
    Result := FExRate;
end;

function TExchangeRate.LastUpdateBetween: integer;
begin
  Result := SecondsBetween(Now, FUpdateTime);
end;

procedure TExchangeRate.SetValue(const val : double);
var
  iRes : Integer;
begin

  if CmpVal(FExRate, Val) <> 0 then
    FUpdateTime := now;

  FExRate := val;
  FExchangeRateItems.Update(val);
end;


end.
