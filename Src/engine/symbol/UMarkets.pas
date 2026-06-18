unit UMarkets;

interface

uses
  Classes, SysUtils, Math,

  USymbols, UMarketSpecs;

type
    //------------------------------------------< Market >

  TMarket = class(TCollectionItem)
  protected
    FFQN: String; // fully qualified name
    FSymbols: TSymbolList;
    FSpec: TMarketSpec;
  public
    constructor Create(aColl: TCollection); override;
    destructor Destroy; override;

    procedure AddSymbol(aSymbol: TSymbol); virtual;

    property FQN: String read FFQN;
    property Spec: TMarketSpec read FSpec write FSpec;
    property Symbols: TSymbolList read FSymbols;
  end;

  TMarkets = class(TCollection)
  protected
    function GetMarket(i: Integer): TMarket;
  public
    function Find(stFQN: String): TMarket;

    procedure GetList(aList: TStrings);
    procedure GetList2(aList: TStrings);  // 주식선물 빼고
    procedure GetList3(aList: TStrings);  // 주식선물만

    property Markets[i:Integer]: TMarket read GetMarket;
  end;

  TMarketList = class(TStringList)
  private
    function GetMarket(i: Integer): TMarket;
  public
    procedure AddMarket(aMarket: TMarket);
    function FindMarket(stFQN: String): TMarket;
    property Markets[i:Integer]: TMarket read GetMarket; default;
  end;


    //------------------------------------------< Stock Market >

  TSpotMarket = class(TMarket)
  private
    function GetSpot(i: Integer): TSpot;
  public
    property Spots[i:Integer]: TSpot read GetSpot; default;
  end;

  TSpotMarkets = class(TMarkets)
  private
    function GetSpotMarket(i: Integer): TSpotMarket;
  public
    constructor Create;
    function New(stFQN: String): TSpotMarket;
    property SpotMarkets[i:Integer]: TSpotMarket read GetSpotMarket; default;
  end;

    //------------------------------------------< Margin Market >

  TMarginMarket = class(TMarket)
  private
    function GetMargin(i: Integer): TMargin;
  public
    property Margins[i:Integer]: TMargin read GetMargin; default;
  end;

  TMarginMarkets = class(TMarkets)
  private
    function GetMarginMarket(i: Integer): TMarginMarket;
  public
    constructor Create;
    function New(stFQN: String): TMarginMarket;
    property MarginMarkets[i:Integer]: TMarginMarket read GetMarginMarket; default;
  end;

    //------------------------------------------< Future Market >

  TFutureMarket = class(TMarket)
  private
    FFrontMonth: TFuture;
    function GetFuture(i: Integer): TFuture;
  public
    procedure AddSymbol(aSymbol: TSymbol); override;
    function  FindNearSymbol( stCode : string ) : TSymbol;
    property FrontMonth: TFuture read FFrontMonth write FFrontMonth;
    property Futures[i:Integer]: TFuture read GetFuture; default;
  end;

  TFutureMarkets = class(TMarkets)
  private
    function GetFutureMarket(i: Integer): TFutureMarket;
  public
    constructor Create;
    function New(stFQN: String): TFutureMarket;
    property FutureMarkets[i:Integer]: TFutureMarket read GetFutureMarket; default;
  end;



    //------------------------------------------< Market Groups >

  TMarketGroup = class(TCollectionItem)
  protected
    FFQN: String;
    FTitle: String;
    FRef: TSymbol;
    FIdx : integer;
    FMarkets: TMarketList;
  public
    constructor Create(aColl: TCollection); override;
    destructor Destroy; override;

    property FQN : string read FFQN;
    property Ref: TSymbol read FRef;
    property Title : string read FTitle;
    property Idx : integer read FIdx;
    property Markets: TMarketList read FMarkets;
  end;

  TMarketGroups = class(TCollection)
  private
    function GetGroup(i: Integer): TMarketGroup;
  public
    constructor Create;
    procedure AddMarket(aMarket: TMarket; stFQN, stTitle: String; aRef: TSymbol = nil);

    function Find(stFQN: String): TMarketGroup;
    procedure GetList(aList: TStrings);
    function FindTitle(stTitle: String): TMarketGroup;
    property Groups[i:Integer]: TMarketGroup read GetGroup; default;
  end;

implementation

//------------------------------------------------------------------< market >
{ TMarket }

constructor TMarket.Create(aColl: TCollection);
begin
  inherited Create(aColl);

  FSymbols := TSymbolList.Create;
end;

destructor TMarket.Destroy;
begin
  FSymbols.Free;

  inherited;
end;

procedure TMarket.AddSymbol(aSymbol: TSymbol);
begin
  FSymbols.AddObject(aSymbol.Code, aSymbol);
end;

{ TMarkets }

function TMarkets.Find(stFQN: String): TMarket;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Count - 1 do
    if CompareStr(stFQN, (Items[i] as TMarket).FFQN) = 0 then
    begin
      Result := Items[i] as TMarket;
      Break;
    end;
end;

procedure TMarkets.GetList(aList: TStrings);
var
  i: Integer;
  aMarket: TMarket;
begin
  for i := 0 to Count - 1 do
  begin
    aMarket := GetMarket(i);
    if aMarket.Spec <> nil then
      aList.AddObject(aMarket.Spec.Description, aMarket)
    else
      aList.AddObject(aMarket.FQN, aMarket);
  end;
end;

procedure TMarkets.GetList2(aList: TStrings);
var
  i: Integer;
  aMarket: TMarket;
begin
  for i := 0 to Count - 1 do
  begin
    aMarket := GetMarket(i);
    if aMarket.Spec <> nil then begin
      aList.AddObject(aMarket.Spec.Description, aMarket);
    end
    else
      aList.AddObject(aMarket.FQN, aMarket);
  end;

end;

// 주식선물만
procedure TMarkets.GetList3(aList: TStrings);
var
  i: Integer;
  aMarket: TMarket;
begin
  for i := 0 to Count - 1 do
  begin
    aMarket := GetMarket(i);
    if aMarket.Spec <> nil then begin
      aList.AddObject(aMarket.Spec.Description, aMarket)
    end
    else
      aList.AddObject(aMarket.FQN, aMarket);
  end;

end;

function TMarkets.GetMarket(i: Integer): TMarket;
begin
  if (i >= 0) and (i <= Count-1) then
    Result := Items[i] as TMarket
  else
    Result := nil;
end;

{ TMarketList }

procedure TMarketList.AddMarket(aMarket: TMarket);
begin
  AddObject(aMarket.FQN, aMarket);
end;

function TMarketList.FindMarket(stFQN: String): TMarket;
var
  iIndex: Integer;
begin
  iIndex := IndexOf(stFQN);
  if iIndex >= 0 then
    Result := TMarket(Objects[iIndex])
  else
    Result := nil;
end;

function TMarketList.GetMarket(i: Integer): TMarket;
begin
  if (i >= 0) and (i <= Count-1) then
    Result := TMarket(Objects[i])
  else
    Result := nil;
end;


//-------------------------------------------------------------< stock market >

{ TStockMarket }

function TSpotMarket.GetSpot(i: Integer): TSpot;
begin
  Result := FSymbols[i] as TSpot;
end;

{ TStockMarkets }

constructor TSpotMarkets.Create;
begin
  inherited Create(TSpotMarket);
end;

function TSpotMarkets.GetSpotMarket(i: Integer): TSpotMarket;
begin
  Result := GetMarket(i) as TSpotMarket;
end;

function TSpotMarkets.New(stFQN: String): TSpotMarket;
begin
  Result := Add as TSpotMarket;
  Result.FFQN := stFQN;
end;


//-----------------------------------------------------------< future market >

{ TFutureMarket }

procedure TFutureMarket.AddSymbol(aSymbol: TSymbol);
var
  aFuture: TFuture;
begin
  if not (aSymbol is TFuture) then Exit;

  inherited AddSymbol(aSymbol);

  aFuture := aSymbol as TFuture;

  if FFrontMonth = nil then
    FFrontMonth := aFuture
  else
    if Floor(aFuture.ExpDate) < Floor(FFrontMonth.ExpDate) then
      FFrontMonth := aFuture;
end;

function TFutureMarket.FindNearSymbol(stCode: string): TSymbol;
var
  iY, iM, I: Integer;
  dGap, dMin : double;
  aSymbol : TFuture;
  stDate : string;
  dtDate : TDateTime;
  function _getCodeMonth( c : char ): integer;
  begin
    case c of
      'F': Result := 1;
      'G': Result := 2;
      'H': Result := 3;
      'J': Result := 4;
      'K': Result := 5;
      'M': Result := 6;
      'N': Result := 7;
      'Q': Result := 8;
      'U': Result := 9;
      'V': Result := 10;
      'X': Result := 11;
      'Z': Result := 12;
      else
        Result := 0;
    end;
  end;

begin
  try
    Result := nil;

    stDate := Copy( stCode, Length(stCode)-2, 3 );
    iY := 2000 + StrToInt( Copy(stDate, 2, 2 ));
    iM := _getCodeMonth( stDate[1] );

    dtDate  := EncodeDate( iY, iM, 1 );

    dMin := 10000;
    for I := 0 to Symbols.Count - 1 do
    begin
      aSymbol := Symbols.Symbols[i] as TFuture;
      dGap := aSymbol.ExpDate - dtDate;
      if ( dGap > 0 ) and ( dGap < dMin ) then
      begin
        Result := aSymbol;
        dMin   := dGap;
      end;
    end;
  except
    Result := nil;
  end;
end;

function TFutureMarket.GetFuture(i: Integer): TFuture;
begin
  Result := FSymbols[i] as TFuture;
end;

{ TFutureMarkets }

constructor TFutureMarkets.Create;
begin
  inherited Create(TFutureMarket);
end;


function TFutureMarkets.GetFutureMarket(i: Integer): TFutureMarket;
begin
  Result := GetMarket(i) as TFutureMarket;
end;

function TFutureMarkets.New(stFQN: String): TFutureMarket;
begin
  Result := Add as TFutureMarket;
  Result.FFQN := stFQN;
end;


//-------------------------------------------------------------< market group >

{ TMarketGroup }

constructor TMarketGroup.Create(aColl: TCollection);
begin
  inherited Create(aColl);

  FMarkets := TMarketList.Create;
  FIdx := -1;
  FRef := nil;
  FFQN := '';
  FTitle := '';
end;

destructor TMarketGroup.Destroy;
begin
  FMarkets.Free;

  inherited;
end;

{ TMarketGroups }



constructor TMarketGroups.Create;
begin
  inherited Create(TMarketGroup);
end;

function TMarketGroups.GetGroup(i: Integer): TMarketGroup;
begin
  if (i >= 0) and (i <= Count-1) then
    Result := Items[i] as TMarketGroup
  else
    Result := nil;
end;

procedure TMarketGroups.GetList(aList: TStrings);
var
  i: Integer;
begin
  if aList = nil then Exit;

  for i := 0 to Count - 1 do
    aList.AddObject((Items[i] as TMarketGroup).FTitle, Items[i]);
end;

function TMarketGroups.Find(stFQN: String): TMarketGroup;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Count - 1 do
    if CompareStr(stFQN, (Items[i] as TMarketGroup).FFQN) = 0 then
    begin
      Result := Items[i] as TMarketGroup;
      Break;
    end;
end;

function TMarketGroups.FindTitle(stTitle: String): TMarketGroup;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Count - 1 do
    if CompareStr(stTitle, (Items[i] as TMarketGroup).FTitle) = 0 then
    begin
      Result := Items[i] as TMarketGroup;
      Break;
    end;
end;

procedure TMarketGroups.AddMarket(aMarket: TMarket; stFQN, stTitle: String;
  aRef: TSymbol);
var
  aGroup: TMarketGroup;
begin
  aGroup := Find(stFQN);

  if aGroup = nil then
  begin
    aGroup := Add as TMarketGroup;
    aGroup.FFQN := stFQN;
    aGroup.FTitle := stTitle;
    aGroup.FRef := aRef;
  end;

  aGroup.Markets.AddMarket(aMarket);
end;


{ TMarginMarket }

function TMarginMarket.GetMargin(i: Integer): TMargin;
begin
  Result := FSymbols[i] as TMargin;
end;

{ TMarginMarkets }

constructor TMarginMarkets.Create;
begin
  inherited Create(TMarginMarket);
end;

function TMarginMarkets.GetMarginMarket(i: Integer): TMarginMarket;
begin
  Result := GetMarket(i) as TMarginMarket;
end;

function TMarginMarkets.New(stFQN: String): TMarginMarket;
begin
  Result := Add as TMarginMarket;
  Result.FFQN := stFQN;
end;

end.


