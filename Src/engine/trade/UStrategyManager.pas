unit UStrategyManager;

interface

uses
  System.Classes,

  UApiTypes, UTypes ,

  UStrategyItem

  ;

type

  TStrategyManager = class
  public
    SPObject : TSPObjects;
    Constructor Create;
    Destructor  Destroy; override;
  end;

implementation

{ TStrategyManager }

constructor TStrategyManager.Create;
begin
  SPObject := TSPObjects.Create;
end;

destructor TStrategyManager.Destroy;
begin
  SPObject.Free;
  inherited;
end;

end.
