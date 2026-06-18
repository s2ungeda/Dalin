unit UCyclicItems;

interface

uses
  System.Classes  ,  REST.Types, 

  Windows
  ;

type

  TCyclicItem = class( TCollectionItem )
  public
    Interval : DWORD ;
    Name     : string;
    LastTime : DWORD;
    PrevTime : DWORD;
    Count    : integer;
    index    : integer;
    Resource : string;    
    Method	 : TRESTRequestMethod;
  end;

  TCyclicItems = class( TCollection )
  private
    function GetCyclicItem(i: integer): TCyclicItem;
  public
    Constructor Create;
    Destructor  Destroy; override;

    function New( AName : string ) : TCyclicItem;
    property Cyclic[ i : integer] : TCyclicItem read GetCyclicItem;
  end;

implementation

{ TCyclicItems }

constructor TCyclicItems.Create;
begin
  inherited Create(  TCyclicItem );
end;

destructor TCyclicItems.Destroy;
begin

  inherited;
end;

function TCyclicItems.GetCyclicItem(i: integer): TCyclicItem;
begin
  if ( i < 0 ) or ( i >= Count ) then
    Result := nil
  else
    REsult := Items[i] as TCyclicItem;
end;

function TCyclicItems.New(AName: string): TCyclicItem;
begin
  Result := Add as TCyclicItem;
  Result.Name     := AName;
  Result.LastTime := 0;
  Result.Count    := 0;
end;

end.
