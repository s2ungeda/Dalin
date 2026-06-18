unit UApiDTOs;

interface

uses
  System.Generics.Collections, System.SysUtils;

type
  TBalanceDTO = class
  public
    Asset: string;
    Balance: Double;
    Available: Double;
  end;

  TPositionDTO = class
  public
    Symbol: string;
    Volume: Double;
    AvgPrice: Double;
    LiqPrice: Double;
    MaxNotional: Double;
    Leverage: Integer;
    IsIsolated: Boolean;
  end;

  TOrderDTO = class
  public
    Symbol: string;
    OrderId: string;
    ClientOrderId: string;
    Side: Integer; // 1 for Buy, -1 for Sell
    OrderType: string; // 'LIMIT', 'MARKET', etc.
    Price: Double;
    Quantity: Double;
    ReduceOnly: Boolean;
    OrderTime: TDateTime;
  end;

implementation

end.
