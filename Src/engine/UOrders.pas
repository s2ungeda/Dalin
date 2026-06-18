unit UOrders;

interface

uses
	System.Classes, System.SysUtils,

  UAccounts, Usymbols,  UFills, 

  UApiTypes, UTypes

  ;

type

  //------------------------------ order
  TOrderType 		= (otNormal, otChange, otCancel);  
  TPriceControl = (pcLimit, pcMarket );  
  TTimeInForce 	= (tmGTC, tmFOK, tmIOC, tmPOST);  

  TOrderState = (osReady,
                   // with server
                 osSent, osSrvAcpt, osSrvRjt,
                   // with exchange
                 osActive, osRejected, osFilled, osCanceled,
                 osConfirmed, osFailed);

  TOrderStates  = set of TOrderState;

  TOrder = class(TCollectionItem)
  private
  public
    constructor Create(Coll: TCollection); override;
    destructor Destroy; override;

    property Account: TAccount read FAccount;
    property Symbol: TSymbol read FSymbol;    

    property TimeToMarket: TTimeInForce read FTimeToMarket;
    property PriceControl: TPriceControl read FPriceControl;

    property Side: Integer read FSide;
    property OrderQty: double read FOrderQty Write FOrderQty;
    property Price: Double read FPrice;
    property FilledPrice: Double read FFilledPrice;                 
    property AvgPrice : double read FAvgPrice write FAvgPrice;   

		property ActiveQty: double read FActiveQty write FActiveQty;
    property FilledQty: double read FFilledQty write FFilledQty;
    property CanceledQty: double read FCanceledQty  write FCanceledQty;     

    property OrderNo: string read FOrderNo write FOrderNo;
    property LocalNo: string read FLocalNo write FLocalNo;
    property GroupNo: string read FGroupNo write FGroupNo;             

    property State: TOrderState read FState write FState;          
    property RejectCode: string read FRejectCode write FRejectCode;     
    property Fills  : TFillList  read FFills;

    property SentTime	: TDateTime read FSentTime;
    property AcptTime	: TDateTime read FAcptTime write FAcptTime;    
    property TradeTime: TDateTime read FTradeTime write FTradeTime;
    property EventTime: TDateTime read FEventTime write EventTime;
    
  end;
implementation

end.
