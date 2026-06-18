unit UCommonParse;

interface

uses
  System.Classes, System.SysUtils,

  UApiTypes, UApiConsts,

  UOrders
  ;

type

  TCommonParse = class
  public
    procedure ProcEmptyResponse(aExType : TExchangeKind; const sLocalNo : string);
  end;

implementation

uses
  GApp,
  UTypes
  ;

{ TCommonParse }

procedure TCommonParse.ProcEmptyResponse(aExType: TExchangeKind; const sLocalNo: string);
var
  aOrder : TOrder;
begin
  aOrder:= App.Engine.TradeCore.FindOrder(aExType, sLocalNo);
  if aOrder = nil then begin
    App.Log(llError, '%s not found order : %s ', [TExShortDesc[aExType], sLocalNo]);
    Exit;
  end else
  begin
    aOrder.RejectReason := 'data is empty';
    App.Engine.TradeBroker.Accept(aOrder, now, false, '9999') ;
  end;
end;

end.
