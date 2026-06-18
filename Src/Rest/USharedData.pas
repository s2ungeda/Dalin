unit USharedData;

interface

uses
  System.Classes  ,

  USharedConsts
  ;

type

  PDataItem = ^TDataItem;
  TDataItem = packed record
    exKind : char;      // B(binance), U(upbit), T(bithumb)
    exApiType : char;   // S(Spot), F(futUsdt), P(futCoin)
    trDiv  : char;      // N(new order), C ( cancel order), L( 주문조회) P ( 포지션조회 ) B ( 잔고조회 )
    data   : array [0..DATA_SIZE-1] of ansichar;
    size   : integer;//string[5];//array [0..4] of ansichar;
    ref    : string[50];
  end;

  PSharedData = ^TSharedData;
  TSharedData = record
    SharedData : array [0..Q_SIZE-1] of TDataItem;
    Front, Rear : integer;
    function Count : integer;
    function IsEmpty : boolean;
    procedure init;
    function IsFull: boolean;
  end;

  TSharedDataNotify = procedure ( aData : TDataItem ) of Object;
  TSharedPushData =   function ( c1, c2, c3 : char; s1, s2 : string ):boolean of Object;

  TSharedThreadType = (stBnSThread, stBnFThread, stBnCThread, stUpSThread, stBtSThread);

  function STTypeToStr(stType : TSharedThreadType) : string;

implementation

{ TSharedData }

const
 TSharedThreadTypeDesc : array [TSharedThreadType] of string =
  ('BnSThread', 'BnFThread', 'BnCThread', 'UpSThread', 'BtSThread');

function STTypeToStr(stType : TSharedThreadType) : string;
begin
  Result := TSharedThreadTypeDesc[stType];
end;

function TSharedData.Count: integer;
begin
  Result :=((Rear - Front + 1) + Q_Size) mod Q_Size;
end;

procedure TSharedData.init;
begin
  Front := 0;
  Rear  := 0;
end;

function TSharedData.IsEmpty: boolean;
begin
  Result := Front = Rear;
end;

function TSharedData.IsFull: boolean;
begin
  Result := ( Rear + 1 ) mod Q_SIZE = Front;
end;


end.
