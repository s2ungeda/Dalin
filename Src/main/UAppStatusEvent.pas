unit UAppStatusEvent;

interface

uses
  UTypes
  ;

procedure AppStatusEvent( asType : TAppStatus );

implementation

procedure AppStatusEvent( asType : TAppStatus );
begin
  case asType of
    asNone: ;
    asInit: ;
  end;
end;

end.
