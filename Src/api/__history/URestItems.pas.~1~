unit URestItems;

interface

uses
	System.Classes, 

  REST.Types ,

  URestRequests

  ;

type

	TReqeustItem = class
  public
	  Req : TRequest;
    AMethod : TRESTRequestMethod;  
    AResource : string;
    Name : string;
    JsonData, OutData	: string;
  	constructor Create;
    Destructor  Destroy; override;	  
  end;  

implementation

{ TReqeustItem }

constructor TReqeustItem.Create;
begin
	Req := TRequest.Create;
end;

destructor TReqeustItem.Destroy;
begin
  Req.Free;
  inherited;
end;

end.
