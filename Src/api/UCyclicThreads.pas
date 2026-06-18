unit UCyclicThreads;
interface
uses
  System.Classes, System.SyncObjs
  , Windows
  , URestRequests//UCyclicItems
  ;
const
  INTERVAL = 100;
type      

  TCyclicThread = class(TThread)
  private
    { Private declarations }
   FMutex  : HWND;
   FEvent  : TEvent;
   FITems  : TList;
   FOnNotify  : TNotifyEvent;
   FData : TRequest;
   procedure SyncProc;
  protected
    procedure Execute; override;
  public
    constructor Create( aList : TList; ANotify : TNotifyEvent ; AName : string);
    destructor Destroy; override;
    procedure doJob;
    procedure TurnOffNotify;
  end;
implementation
uses
  GApp
  , UTypes
	, Forms
  ;
{ IntervalThread }
constructor TCyclicThread.Create( aList : TList; ANotify : TNotifyEvent; AName : string );
begin
  FITems    := aList;
  FOnNotify := ANotify;
  inherited Create(true);
  FreeOnTerminate := true;
  Priority  := tpNormal;
  FMutex  := CreateMuTex( nil, false, PChar(AName) );
  FEvent  := TEvent.Create( nil, False, False, '');
end;
destructor TCyclicThread.Destroy;
begin
  CloseHandle( FMutex );
  FEvent.Free;
  inherited;
end;
procedure TCyclicThread.doJob;
begin
  FEvent.SetEvent;
end;
procedure TCyclicThread.Execute;
var
  I, iSnd, gap : Integer;
  aItem : TRequest;
  nTick : DWORD;
  bSend : boolean;
begin
  { Place thread code here }
  iSnd := 0;
  while not Terminated do
  begin
      WaitForSingleObject( Handle,  INTERVAL );

//      if Terminated then break;
 			if FITems.Count <= 0 then continue;
      if App.Stop then continue;

      if iSnd >= FItems.Count then
        iSnd := 0;
//    for I := 0 to FItems.Count-1 do
//    begin
      aItem := TRequest( FItems.Items[iSnd] );
      if aItem = nil then continue;
      bSend := false;
      nTick := GetTickCount;

      if aITem.LastTime <= 0 then
      begin
        gap := aItem.Count * INTERVAL;
        if gap >= aItem.Interval then
          bSend := true;
        inc( aItem.Count );

      end else
      begin
        gap   := nTick - aItem.LastTime ;
        if gap >= aItem.Interval then
          bSend := true;
      end;
//      if (i = 2) and ( bSend ) then
//        aItem.EnTime := 2;

//      if (aItem.Name = 'listenkey') and (bSend) then
//      begin
//        App.DebugLog( '%s, %d ', [ aItem.Name, integer(aItem.State)] );
//      end;

      if App.AppStatus = asClose then
      begin
        continue;
      end;

      if (bSend) and (aItem.State <> 1)  then begin
        aItem.PrevTime  := aItem.LastTime;
        aItem.LastTime  := nTick;
        FData := aItem;
        Synchronize( SyncProc );
//        FOnNotify( aItem );
      end else
      if (bSend) and ( aITem.State = 1 ) then
      begin
        if not aItem.CheckDelayTime(15000) then
        begin
          aItem.DoTimeout;
          App.Log(llInfo, 'Req TimeOut %s %s ', [ aItem.Name, aItem.Req.Client.BaseURL ]  );
        end;
      end;
      inc( iSnd );
			// 루프 한번에 한건만 조회 하기 위해..
//      if iSnd > 0 then break;
//      Application.ProcessMessages;
//    end;
  end;
end;
procedure TCyclicThread.SyncProc;
begin
  if Assigned( FOnNotify ) then
    FOnNotify( FData );
end;
procedure TCyclicThread.TurnOffNotify;
begin
	FOnNotify	:= nil;
end;

end.
