unit USymbolBroker;

interface

uses
  System.Classes, System.SysUtils,

  USymbols,  UDistributor,

  UApiTypes
  ;

type

  TSymbolBroker = class
  private

    FDistributor: TDistributor;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Subscribe(Sender: TObject; iDataID : integer; aHandler: TDistributorEvent);
    procedure Unsubscribe(Sender: TObject);

    procedure DnwEvent( aSymbol : TSymbol; aEventID : TDistributorID );

  end;


implementation

uses
  GApp , UTypes
  , UConsts
  ;

{ TSymbolBroker }

constructor TSymbolBroker.Create;
begin
  FDistributor:= TDistributor.Create;

end;

destructor TSymbolBroker.Destroy;
begin
  FDistributor.Free;
  inherited;
end;

procedure TSymbolBroker.DnwEvent(aSymbol: TSymbol; aEventID: TDistributorID);
begin
  if App.AppStatus > asLoad then
    FDistributor.Distribute(Self, DNW_EVENT, aSymbol, aEventID);
end;

//  Subscribe(Self, DNW_STATE, SymbolBrokerEventHandler);
procedure TSymbolBroker.Subscribe(Sender: TObject; iDataID: integer;
  aHandler: TDistributorEvent);
begin
  if Sender = nil then Exit;

  FDistributor.Subscribe(Sender, iDataID, ANY_OBJECT, ANY_EVENT, aHandler);
end;

procedure TSymbolBroker.Unsubscribe(Sender: TObject);
begin
  FDistributor.Cancel(Sender);
end;

end.
