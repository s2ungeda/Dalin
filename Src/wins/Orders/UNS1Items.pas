unit UNS1Items;

interface

uses
  System.SysUtils, System.Classes,

  UDecimalHelper
  ;

const
  MIN_ORD_AMT = 5000;  //

type

  TNS1Param = record

    orderQty : double;
    orderQty_s : string;
    startHoga: integer;
    tick     : integer;
    count    : integer;

    // 정정
    modCnt   : integer;
    modForVol: double;

    // 취소 조건
    limitHoga: integer;
    useLimitHoga : boolean;

    procedure Init;
    procedure SetParm( const sQty : string; const iHoga, iTick, iCnt, iMod, iLimit : integer;
      dmfv : double; bUse :boolean);
    procedure Assign( const aParam : TNS1Param);

    function BaseCheck : boolean;
  end;

  tmpOrd = record
    price : double;
    qty   : double;
    fee   : double;

    function amt : double;
    procedure setdata( dPrice, dQty, dFee : double);
  end;


implementation

uses
  GLibs
  ;

{ TSPParam }

procedure TNS1Param.Assign(const aParam: TNS1Param);
begin
  orderQty := aParam.orderQty;
  startHoga:= aParam.startHoga;
  tick     := aParam.tick;
  count    := aParam.count;

  modCnt   := aParam.modCnt;
  limitHoga:= aParam.limitHoga;

  useLimitHoga  := aParam.useLimitHoga;
  modForVol := aParam.modForVol;

  orderQty_s := aParam.orderQty_s;
end;

function TNS1Param.BaseCheck: boolean;
begin
  Result := false;
  if orderQty_s = '' then Exit;
  if CheckZero(orderQty) then Exit;
  if count <= 0 then Exit;
  if tick <= 0 then Exit;
  if startHoga <= 0 then Exit;
  if modCnt <= 0 then Exit;
  if limitHoga <= 0 then Exit;

  Result := true;
end;

procedure TNS1Param.Init;
begin
  orderQty := 0;
  startHoga:= 3;
  tick     := 1;
  count    := 2;

  modCnt   := 3;
  modForVol:= 0;

  limitHoga:= 1;
  useLimitHoga := true;

  orderQty_s := '';
end;

procedure TNS1Param.SetParm(const sQty : string; const iHoga, iTick, iCnt, iMod, iLimit : integer;
  dmfv : double; bUse :boolean);
var
  bInt : TDecimalhelper;
begin
  orderQty_s  := sQty;
  orderQty    := bInt.StrToDouble(sQty);

  startHoga := iHoga;
  tick      := iTick;
  count     := iCnt;

  modCnt    := iMod;
  limitHoga := iLimit;

  modForVol := dmfv;

  useLimitHoga := bUse;
end;

{ tmpOrd }

function tmpOrd.amt: double;
begin

end;

procedure tmpOrd.setdata(dPrice, dQty, dFee: double);
begin
  price := dPrice;
  qty   := dQty;
end;

end.
