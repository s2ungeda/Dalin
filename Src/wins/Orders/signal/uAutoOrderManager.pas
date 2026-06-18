unit uAutoOrderManager;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows;

type
  TResumeMode = (rmAuto, rmManual);

  TOrderState = (
    osIdle,           // 대기 중
    osOrdering,       // 주문 발주 중
    osWaitRetry,      // 재시도 대기 중
    osPaused          // 일시 중지 (연속 거부)
  );

  TOrderSettings = record
    RetryInterval: Integer;      // 재시도 간격 (초)
    MaxRejectCount: Integer;     // 최대 연속 거부 횟수
    ResumeMode: TResumeMode;     // 재개 방식
    AutoResumeDelay: Integer;    // 자동 재개 시간 (초)
  end;

  TOrderEvent = procedure of object;
  TStateChangeEvent = procedure(OldState, NewState: TOrderState) of object;
  TRejectEvent = procedure(RejectCount: Integer) of object;

  TAutoOrderManager = class
  private
    FSettings: TOrderSettings;
    FState: TOrderState;
    FRejectCount: Integer;
    FWaitStartTick: UInt64;

    FOnSendOrder: TOrderEvent;
    FOnStateChange: TStateChangeEvent;
    FOnReject: TRejectEvent;
    FOnPaused: TOrderEvent;
    FOnResumed: TOrderEvent;

    procedure SetState(Value: TOrderState);
    procedure DoSendOrder;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ApplySettings(const ASettings: TOrderSettings);
    function GetSettings: TOrderSettings;

    procedure StartOrder;
    procedure OnOrderAccepted;
    procedure OnOrderRejected;
    procedure ManualResume;
    procedure Stop;

    procedure CheckTimer;

    property State: TOrderState read FState;
    property RejectCount: Integer read FRejectCount;

    property OnSendOrder: TOrderEvent read FOnSendOrder write FOnSendOrder;
    property OnStateChange: TStateChangeEvent read FOnStateChange write FOnStateChange;
    property OnReject: TRejectEvent read FOnReject write FOnReject;
    property OnPaused: TOrderEvent read FOnPaused write FOnPaused;
    property OnResumed: TOrderEvent read FOnResumed write FOnResumed;
  end;

function OrderStateToStr(AState: TOrderState): string;

implementation

function OrderStateToStr(AState: TOrderState): string;
begin
  case AState of
    osIdle:      Result := '대기';
    osOrdering:  Result := '주문 중';
    osWaitRetry: Result := '재시도 대기';
    osPaused:    Result := '일시 중지';
  else
    Result := '알 수 없음';
  end;
end;

{ TAutoOrderManager }

constructor TAutoOrderManager.Create;
begin
  inherited Create;
  FState := osIdle;
  FRejectCount := 0;
  FWaitStartTick := 0;

  FSettings.RetryInterval := 3;
  FSettings.MaxRejectCount := 5;
  FSettings.ResumeMode := rmAuto;
  FSettings.AutoResumeDelay := 30;
end;

destructor TAutoOrderManager.Destroy;
begin
  inherited;
end;

procedure TAutoOrderManager.SetState(Value: TOrderState);
var
  OldState: TOrderState;
begin
  if FState <> Value then
  begin
    OldState := FState;
    FState := Value;
    if Assigned(FOnStateChange) then
      FOnStateChange(OldState, Value);
  end;
end;

procedure TAutoOrderManager.ApplySettings(const ASettings: TOrderSettings);
begin
  FSettings := ASettings;
end;

function TAutoOrderManager.GetSettings: TOrderSettings;
begin
  Result := FSettings;
end;

procedure TAutoOrderManager.DoSendOrder;
begin
  SetState(osOrdering);
  if Assigned(FOnSendOrder) then
    FOnSendOrder;
end;

procedure TAutoOrderManager.StartOrder;
begin
  FRejectCount := 0;
  FWaitStartTick := 0;
  DoSendOrder;
end;

procedure TAutoOrderManager.OnOrderAccepted;
begin
  FRejectCount := 0;
  FWaitStartTick := 0;
  SetState(osIdle);
end;

procedure TAutoOrderManager.OnOrderRejected;
begin
  Inc(FRejectCount);

  if Assigned(FOnReject) then
    FOnReject(FRejectCount);

  if FRejectCount >= FSettings.MaxRejectCount then
  begin
    SetState(osPaused);
    FWaitStartTick := GetTickCount64;

    if Assigned(FOnPaused) then
      FOnPaused;
  end
  else
  begin
    SetState(osWaitRetry);
    FWaitStartTick := GetTickCount64;
  end;
end;

procedure TAutoOrderManager.CheckTimer;
var
  ElapsedMs: UInt64;
begin
  if FWaitStartTick = 0 then
    Exit;

  ElapsedMs := GetTickCount64 - FWaitStartTick;

  case FState of
    osWaitRetry:
      begin
        if ElapsedMs >= UInt64(FSettings.RetryInterval) * 1000 then
        begin
          FWaitStartTick := 0;
          DoSendOrder;
        end;
      end;

    osPaused:
      begin
        if (FSettings.ResumeMode = rmAuto) and
           (ElapsedMs >= UInt64(FSettings.AutoResumeDelay) * 1000) then
        begin
          FWaitStartTick := 0;
          FRejectCount := 0;

          if Assigned(FOnResumed) then
            FOnResumed;

          DoSendOrder;
        end;
      end;
  end;
end;

procedure TAutoOrderManager.ManualResume;
begin
  if FState = osPaused then
  begin
    FWaitStartTick := 0;
    FRejectCount := 0;

    if Assigned(FOnResumed) then
      FOnResumed;

    DoSendOrder;
  end;
end;

procedure TAutoOrderManager.Stop;
begin
  FRejectCount := 0;
  FWaitStartTick := 0;
  SetState(osIdle);
end;

end.
