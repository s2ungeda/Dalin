unit URestThread;
interface
uses
  system.Classes, system.SysUtils, system.DateUtils
  , Windows, SyncObjs  , REST.Types
  , URestRequests  
  , UApiTypes, UApiConsts , URestItems
  
  ;
type      
	TResponseNotify = procedure( aItem : TBalanceRequestItem ) of Object;
	
  TRestThread = class( TThread )
  private
    FEvent  : TEvent;
    FMutex  : HWND;
    FQueue  : TList;
    FData		: TBalanceRequestItem;
    FDivInfo: TDivInfo;
    FOnResNotify: TResponseNotify;
    function MakeuniqueName( sAddSt : string ) : string;
    
  protected
    procedure Execute; override;
    procedure SyncProc;
  public
    constructor Create( aInfo : TDivInfo );
    destructor Destroy; override;   
    procedure PushQueue( aReqItem : TBalanceRequestItem );
    function  PopQueue : TBalanceRequestItem;
    function  QCount : integer;
    property  DivInfo : TDivInfo read FDivInfo;
    property  OnResNotify : TResponseNotify read FOnResNotify write FOnResNotify;
  end;

implementation
uses
	GApp , UTypes
  , UBithSpot
  ;
{ TRestThread }
constructor TRestThread.Create( aInfo : TDivInfo  );
begin
  FDivInfo 			:= aInfo;
//  FOnResNotify	:=  aProc;
	
  inherited Create(false);
  FreeOnTerminate := false;
  Priority  := tpNormal;
  
  FEvent  := TEvent.Create( nil, False, False, MakeuniqueName('Event') );
  FMutex  := CreateMuTex( nil, false, PChar(MakeuniqueName('Mutex')) );
  FQueue  := TList.Create;
end;
destructor TRestThread.Destroy;
begin
  CloseHandle( FMutex );
  FEvent.Free;
  FQueue.Free;
  inherited;
end;
procedure TRestThread.Execute;
var
  bRes : boolean;
begin

  while not Terminated do
  begin
    if not( FEvent.WaitFor( FDivInfo.WaitTime ) in [wrSignaled] ) then
    begin

    	FData	:= PopQueue;
      if FData <> nil then
      begin
        FData.Result := App.Engine.ApiManager.ExManagers[FData.ExKind].RequestBalance;
        Synchronize( SyncProc );
        FData.Free;
        FData := nil;
      end;
    end; 
  end;

end;

function TRestThread.MakeuniqueName(sAddSt: string): string;
begin
	Result := Format('%s_%s_%s_%d', [ TExShortDesc[ FDivInfo.Kind] 
  	,   TMarketTypeDesc[ FDivInfo.Market ], sAddSt,  FDivInfo.Index ] );
end;
function TRestThread.PopQueue: TBalanceRequestItem;
begin
	if FQueue.Count < 1 then exit (nil);
	WaitForSingleObject(FMutex, INFINITE);
	Result := FQueue.Items[0];
	FQueue.Delete(0);
//  FQueue2.Add( Result);
  ReleaseMutex(FMutex);              
    
end;

procedure TRestThread.PushQueue(aReqItem: TBalanceRequestItem);
begin
	WaitForSingleObject(FMutex, INFINITE);
	FQueue.Add( aReqItem );
  ReleaseMutex(FMutex);              
end;
function TRestThread.QCount: integer;
begin
  Result := FQueue.Count;
end;

procedure TRestThread.SyncProc;
begin
	if Assigned( FOnResNotify ) then begin
  	FOnResNotify( FData );
  end;
    
end;

end.
