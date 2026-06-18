unit UDataLogs;

interface

uses
  System.Classes, System.SysUtils, System.DateUtils, Math

  , GLibs

  ;

type

  TKipTrace = record
    ExRate  : double;
    OsPrice : double;
    CurPrice: double;
    LastTime: TDateTime;
    Kip     : double;
    Cnt     : int64;
    procedure SetData(  ex, op, cp, k : double );
  end;

  TWCDTrace = record
    OsPrice : double;
    CurPrice: double;
    Wcd     : double;
    LastTime: TDateTime;
    Cnt     : int64;
    procedure SetData(  op, cp, wcd : double );
  end;

  TSPTrace = record
    BtPrice : double;
    UpPrice : double;
    SP      : double;
    LastTime: TDateTime;
    Cnt     : int64;
    procedure SetData(  bt, up, sp : double );
  end;

  TDataTrace = class
  public
    Kip : TKipTrace;
    WCD : TWCDTrace;
    SP  : TSPTrace;
  end;

implementation

{ TKipTrace }



{ TKipTrace }

procedure TKipTrace.SetData(ex, op, cp, k: double);
begin
  ExRate  := ex;
  OsPrice := op;
  CurPrice:= cp;
  LastTime:= now;
  Kip     := k;
  inc( Cnt );
  if Cnt > ( High(int64) - 100 ) then
    Cnt := 1;
end;

{ TWCDTrace }

procedure TWCDTrace.SetData(op, cp, wcd: double);
begin
  OsPrice := op;
  CurPrice:= cp;
  Wcd     := wcd;
  LastTime:= now;
  inc( Cnt );
  if Cnt > ( High(int64) - 100 ) then
    Cnt := 1;
end;

{ TSPTrace }

procedure TSPTrace.SetData(bt, up, sp: double);
begin
  BtPrice := bt;
  UpPrice := up;
  SP  := sp;
  LastTime:= now;
  inc( Cnt );
  if Cnt > ( High(int64) - 100 ) then
    Cnt := 1;
end;

end.
