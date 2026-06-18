unit UCircularQueue;

interface

uses
  Classes, SysUtils, DateUtils, Math
  ;

type

  TCircularQueue = class
  private
    FArray: array of Double;
    FCapacity: Integer;
    FHead: Integer;
    FTail: Integer;
    FCount: Integer;
    FSum: Double; // 데이터의 합계를 추적하기 위한 변수
    FLastVar: double;
    FLastAvg: double;
    FFirstVal: double;
    FLastVal: double;

    procedure Init; overload;
    procedure SetAverage(bMove : boolean);
    procedure SetVariance(bMove : boolean);

  public
    constructor Create(ACapacity: Integer);
    destructor Destroy; override;

    procedure Clear;
    procedure Init(ACapacity: Integer); overload;
    procedure Push(Value: Double);

    function Pop: Double;
    function Count: Integer;
    function NewDataCount: Integer;
    function Average: Double; // 평균을 계산하는 메서드
    function Variance : double;
    function StDev : double;

    property LastVal : double read FLastVal;
    property LastAvg : double read FLastAvg;
    property LastVar : double read FLastVar;
    property FirstVal: double read FFirstVal;
    property Capacity: integer read FCapacity;
  end;


implementation

{ TCircularQueue }

constructor TCircularQueue.Create(ACapacity: Integer);
begin
  FCapacity := ACapacity;
  init;
end;

destructor TCircularQueue.Destroy;
begin
  SetLength(FArray, 0);
  inherited;
end;

procedure TCircularQueue.Init;
begin
  SetLength(FArray, FCapacity);
  FHead := 0;
  FTail := 0;
  FCount:= 0;
  FSum := 0.0; // 합계 초기화

  FLastVal  := 0;
  FFirstVal := 0;
  FLastAvg  := 0;
  FLastVar  := 0;
end;

procedure TCircularQueue.Init(ACapacity: Integer);
var
  newArray: array of Double;
  I: Integer;
begin
  if ACapacity = FCapacity then Exit;

//  SetLength( newArray, ACapacity);
//
//  if ACapacity > FCapacity then
//  begin
//
//    for I := 0 to FCount-1 do
//      newArray[i] := FArray[ (FHead+i) mod FCapacity ];
//
//  end else
//  begin
//
//    for i := 0 to Min(ACapacity, FCount) - 1 do
//      NewArray[i] := FArray[(FHead + i) mod FCapacity];
//  end;

  SetLength(FArray, 0);
  FCapacity := ACapacity;
  init;
end;


procedure TCircularQueue.Push(Value: Double);
var
  bMove : boolean;
begin
  if FCapacity <= 0 then Exit;

  if FCount < FCapacity then
  begin
    FArray[FTail] := Value;
    FTail := (FTail + 1) mod FCapacity;
    Inc(FCount);
    FFirstVal := FArray[FHead];
    bMove := false;
  end else
  begin
    FFirstVal := FArray[FHead];
    FSum := FSum - FArray[FHead]; // 가장 오래된 데이터 제거
    FArray[FTail] := Value;

    FTail := (FTail + 1) mod FCapacity;
    FHead := (FHead + 1) mod FCapacity;
    bMove := true;
  end;

  FLastVal  := Value;
  FSum := FSum + Value; // 새로운 데이터 추가 후 합계 업데이트

  SetVariance(bMove);
  SetAverage(bMove);
end;


function TCircularQueue.Pop: Double;
begin
  if FCount > 0 then
  begin
    Result := FArray[FHead];
    FSum := FSum - Result; // 가장 오래된 데이터 제거 후 합계 업데이트
    FHead := (FHead + 1) mod FCapacity;
    Dec(FCount);
  end else
    Result := 0.0;
end;

procedure TCircularQueue.Clear;
var
  I: Integer;
begin
  init;

  for I := 0 to High(FArray) do
    FArray[i] := 0;
end;

function TCircularQueue.Count: Integer;
begin
  Result := FCount;
end;

function TCircularQueue.NewDataCount: Integer;
begin
  Result := (FTail - FHead + FCapacity) mod FCapacity;
end;

function TCircularQueue.Average: Double;
begin
  Result := FLastAvg;
end;

function TCircularQueue.Variance: double;
begin
  Result := FLastVar;
end;


procedure TCircularQueue.SetAverage(bMove : boolean);
begin
  if bMove then
    FLastAvg := FLastAvg + ( FLastVal - FFirstVal ) / FCount
  else
    FLastAvg := FSum / FCount;
end;

procedure TCircularQueue.SetVariance(bMove : boolean);
begin
  if bMove then
    FLastVar := FLastVar -
              Power( FFirstVal - FLastAvg, 2) / FCount +
              Power( FLastVal - FLastAvg, 2) / FCount -
              Power( FLastVal - FFirstVal, 2) / Power(FCount,2)
  else begin
    if FCount <= 1 then
      FLastVar := 0
    else if FCount = 2 then begin
      // 최초 한번은 정석대로
      var dAvg : double;
      dAvg := FSum / FCount;
      FLastVar := (Power(FFirstVal - dAvg, 2) + Power(FLastVAl - dAvg, 2)) / FCount;
    end else
      FLastVar :=  FLastVar*((FCount-1)/FCount)+
              Power(FLastVal-FLastAvg,2) * ((FCount-1) / Power(FCount,2))
              ;
  end;

  if FLastVar < 0 then
  begin
    FLastVar := 0;
  end;
end;

function TCircularQueue.StDev: double;
begin
  Result := Sqrt( FLastVar );
end;

end.

