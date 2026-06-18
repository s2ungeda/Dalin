unit UDecimalHelper;

interface

uses
  System.SysUtils, System.Math;  // [CHANGED] System.Math 추가

type
  // 단순 변환용도
  // decimal 계산을 여기서 하면 안된다.

  TDecimalHelper = record
    OrgVal : string;
    Jungsu : string;
    Sosu   : string;
    Precision : integer;
    Multiple  : int64;
    ConVal    : int64;
    constructor Create(sval : string );
    function print : string;
    procedure init;
    procedure convert(sval:string);overload;
    procedure convert(dVal:double);overload;
    function StrToDouble( const sVal : string) : double;
    function DoubleToStr( const dVal : double) : string;
    function AddComma(const sVal: string): string;
    function ToDouble : double;
    function ToInt64  : int64;
    function ToString : string;
  end;

  TBigInt = TDecimalHelper;

const
  // [ADDED] 미리 계산된 배수 테이블 (반복문 제거)
  MULTIPLIERS: array[0..8] of Int64 = (
    1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000
  );

implementation

{ TDecimalHelper }

procedure TDecimalHelper.init;
begin
  Sosu := '';
  Multiple := 1;
  Precision := 0;
end;

{------------------------------------------------------------------------------
  [OPTIMIZED] convert(dVal: double)

  *** BEFORE ***
  procedure TDecimalHelper.convert(dVal: double);
  begin
    convert( Format('%.8f', [dVal]));  // double → string → 다시 파싱
  end;

  *** AFTER ***
  - Format 호출 제거
  - 문자열 파싱 없이 직접 수학 연산으로 계산
  - 메모리 할당 최소화
------------------------------------------------------------------------------}
procedure TDecimalHelper.convert(dVal: double);
var
  FracPart: Double;
  FracInt: Int64;
  IntPart: Int64;
begin
  init;

  if IsZero(dVal) then
  begin
    ConVal := 0;
    Multiple := 1;
    OrgVal := '0';
    Jungsu := '0';
    Exit;
  end;

  // 정수부와 소수부 분리 (문자열 변환 없이)
  IntPart := Trunc(dVal);
  FracPart := Frac(Abs(dVal));

  if IsZero(FracPart) then
  begin
    // 정수만 있는 경우
    Precision := 0;
    Multiple := 1;
    ConVal := IntPart;
    Jungsu := IntToStr(IntPart);
    OrgVal := Jungsu;
  end
  else
  begin
    // 소수점 정밀도 계산 (최대 8자리)
    FracInt := Round(FracPart * 100000000);

    // trailing zero 제거
    Precision := 8;
    while (Precision > 0) and (FracInt mod 10 = 0) do
    begin
      Dec(Precision);
      FracInt := FracInt div 10;
    end;

    Multiple := MULTIPLIERS[Precision];  // [CHANGED] 룩업 테이블 사용
    ConVal := Abs(IntPart) * Multiple + FracInt;
    if dVal < 0 then
      ConVal := -ConVal;

    Jungsu := IntToStr(IntPart);
    if Precision > 0 then
      Sosu := IntToStr(FracInt)
    else
      Sosu := '';
    OrgVal := Format('%.*f', [Precision, dVal]);
  end;
end;

{------------------------------------------------------------------------------
  [OPTIMIZED] convert(sval: string)

  *** BEFORE ***
  procedure TDecimalHelper.convert(sval:string);
  var
    sts : TArray<string>;
    iCnt, iLen, j: integer;
    sTmp : string;
  begin
    if sval = '' then begin ... end;

    sTmp := sval.Replace(',','');           // 항상 Replace 호출
    sval := sTmp;
    OrgVal := sval;
    init;

    sts  := OrgVal.Split(['.']);            // 동적 배열 생성
    iLen := High(sts);

    if iLen >= 1 then begin
      Jungsu  := sts[0];
      Sosu    := sts[1];
      ...
      for j := 0 to Precision-1 do          // 반복문으로 배수 계산
        Multiple := Multiple*10;
    end else
      Jungsu := OrgVal;

    ConVal := StrToInt64(Jungsu + Sosu);
  end;

  *** AFTER ***
  - Split 제거 → 직접 '.' 위치 탐색
  - Replace는 콤마 있을 때만 호출
  - 반복문 대신 MULTIPLIERS 룩업 테이블 사용
------------------------------------------------------------------------------}
procedure TDecimalHelper.convert(sval: string);
var
  DotPos, Len, i, TrailingZeros: Integer;
  HasComma: Boolean;
  FracStr: string;
begin
  if sval = '' then
  begin
    ConVal := 0;
    Multiple := 0;
    OrgVal := '';
    Jungsu := '';
    Sosu := '';
    Precision := 0;
    Exit;
  end;

  init;

  // [CHANGED] 콤마 체크 (있을 때만 제거) - 불필요한 Replace 방지
  HasComma := False;
  for i := 1 to Length(sval) do
    if sval[i] = ',' then
    begin
      HasComma := True;
      Break;
    end;

  if HasComma then
    sval := StringReplace(sval, ',', '', [rfReplaceAll]);

  OrgVal := sval;
  Len := Length(sval);

  // [CHANGED] Split 대신 직접 '.' 위치 탐색
  DotPos := 0;
  for i := 1 to Len do
    if sval[i] = '.' then
    begin
      DotPos := i;
      Break;
    end;

  if DotPos = 0 then
  begin
    // 정수만 있는 경우
    Jungsu := sval;
    Sosu := '';
    Precision := 0;
    Multiple := 1;
    ConVal := StrToInt64(sval);
  end
  else
  begin
    // 정수부와 소수부 분리
    Jungsu := Copy(sval, 1, DotPos - 1);
    FracStr := Copy(sval, DotPos + 1, Len - DotPos);

    // trailing zero 카운트
    TrailingZeros := 0;
    for i := Length(FracStr) downto 1 do
    begin
      if FracStr[i] <> '0' then
        Break;
      Inc(TrailingZeros);
    end;

    Precision := Length(FracStr) - TrailingZeros;

    if Precision > 0 then
      Sosu := Copy(FracStr, 1, Precision)
    else
      Sosu := '';

    // [CHANGED] 배수 계산 - 룩업 테이블 사용
    if Precision <= 8 then
      Multiple := MULTIPLIERS[Precision]
    else
    begin
      Multiple := MULTIPLIERS[8];
      for i := 9 to Precision do
        Multiple := Multiple * 10;
    end;

    // ConVal 계산
    if Jungsu = '' then
      Jungsu := '0';
    if Sosu = '' then
      ConVal := StrToInt64(Jungsu)
    else
      ConVal := StrToInt64(Jungsu + Sosu);
  end;
end;

function TDecimalHelper.AddComma(const sVal: string): string;
begin
  convert(sVal);
  Result := Format('%.*n', [Precision, ToDouble]);
end;

constructor TDecimalHelper.Create(sval: string);
begin
  OrgVal := sval;
  init;
end;

{------------------------------------------------------------------------------
  [OPTIMIZED] DoubleToStr

  *** BEFORE ***
  function TDecimalHelper.DoubleToStr(const dVal: double): string;
  begin
    convert( Format('%.8f', [dVal]));           // Format 1회
    Result  := Format('%.*n', [ Precision, dVal]); // Format 2회
  end;

  *** AFTER ***
  - convert 호출 제거
  - Format 1회만 호출
  - 정밀도 직접 계산
------------------------------------------------------------------------------}
function TDecimalHelper.DoubleToStr(const dVal: double): string;
var
  FracPart: Double;
  FracInt: Int64;
  CalcPrecision: Integer;
begin
  if IsZero(dVal) then
    Exit('0');

  FracPart := Frac(Abs(dVal));

  if IsZero(FracPart) then
    CalcPrecision := 0
  else
  begin
    FracInt := Round(FracPart * 100000000);
    CalcPrecision := 8;
    while (CalcPrecision > 0) and (FracInt mod 10 = 0) do
    begin
      Dec(CalcPrecision);
      FracInt := FracInt div 10;
    end;
  end;

  Result := Format('%.*n', [CalcPrecision, dVal]);  // [CHANGED] Format 1회만
end;

function TDecimalHelper.print: string;
begin
  Result := Format('O:%s Cnv:%d %d , %.*f', [OrgVal, ConVal, Precision, Precision, ConVal / Multiple]);
end;

function TDecimalHelper.StrToDouble(const sVal: string): double;
begin
  convert(sVal);
  Result := ToDouble;
end;

function TDecimalHelper.ToDouble: double;
begin
  if Multiple = 0 then
    Result := ConVal
  else
    Result := ConVal / Multiple;
end;

function TDecimalHelper.ToInt64: int64;
begin
  Result := ConVal;
end;

function TDecimalHelper.ToString: string;
begin
  Result := Format('%.*f', [Precision, ToDouble]);
end;

end.
