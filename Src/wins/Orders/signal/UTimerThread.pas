unit UTimerThread;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs, System.DateUtils,
  System.Generics.Collections,

  Windows

  ;

type

  TTimerThread = class(TThread)
  private
    { Private declarations }
    FEvent  : TEvent;
    FEndEvent : TEvent;
    FCount, FIndex: integer;
    FInterval: integer;
    FOnLog: TGetStrProc;
    FOnTimer: TProc;
    FEnable: boolean;
    procedure SetInterval(const Value: integer);
    procedure DoLog(s:string);
    procedure SetEnable(const Value: boolean);
    procedure Stop;

  protected
    procedure Execute; override;
    procedure TerminatedSet;
  public
    constructor Create;
    destructor Destroy; override;

    property Interval : integer read FInterval write SetInterval;
    property OnLog : TGetStrProc read FOnLog write FOnLog;
    property OnTimer: TProc read FOnTimer write FOnTimer;
    property Enable: boolean read FEnable write SetEnable;
  end;

implementation



{ TTimerThread }

constructor TTimerThread.Create;
begin

  FInterval := 1000;
  FOnTimer  := nil;
  FEnable   := true;//false;

  inherited Create(false);
  FreeOnTerminate := false;
  Priority  := tpNormal;

  FEvent    := TEvent.Create(nil, False, False, '');

  FIndex  := 0;
  FCount  := 0;

//  Resume;
end;

destructor TTimerThread.Destroy;
begin
  FEvent.Free;
  inherited;
end;

procedure TTimerThread.DoLog(s: string);
begin
  if Assigned(FOnLog) then
    FOnLog(s);
end;

procedure TTimerThread.Execute;
var Res : TWaitResult;
begin
  { Place thread code here }
  while not Terminated do
  begin
    // FInterval 동안 대기, 하지만 Stop 호출 시 즉시 탈출
    case FEvent.WaitFor(FInterval) of
      wrTimeout:
        begin

          if not FEnable then Continue;

          if Assigned(FOnTimer) then
            FOnTimer;
            {
            TThread.Queue(nil, // UI 접근시 안전, Synchronize로 바꿔도 됨
              procedure
              begin

              end);
              }
        end;
      wrSignaled: // Stop 호출됨
        Break;
    end;
  end;

end;


procedure TTimerThread.SetEnable(const Value: boolean);
begin
  FEnable := Value;
end;

procedure TTimerThread.SetInterval(const Value: integer);
begin
  FInterval := Value;
end;

procedure TTimerThread.Stop;
begin
  Terminate;
end;


procedure TTimerThread.TerminatedSet;
begin
  FEvent.SetEvent;
end;

end.
