unit ChatComm;

//==============================================================================
// 채팅 통신 유닛 — UI 와 분리된 네트워크 로직
//
// 사용법:
//   FComm := TChatComm.Create;
//   FComm.SystemName := '홍길동';
//   FComm.UDPPort    := 8888;
//   FComm.TCPPort    := 0;
//   FComm.BroadcastIP := '255.255.255.255';
//   FComm.OnLog              := HandleLog;
//   FComm.OnPeerJoined       := HandlePeerJoined;
//   FComm.OnPeerLeft         := HandlePeerLeft;
//   FComm.OnMessageReceived  := HandleMessage;
//   FComm.Start;
//   ...
//   FComm.SendMessage('안녕');
//   ...
//   FComm.Free;       // 자동으로 Stop
//
// 이벤트는 모두 메인 스레드에서 호출됩니다 (TThread.Queue 사용).
//==============================================================================
interface
uses
  Winapi.Windows, System.SysUtils, System.Classes,
  System.Generics.Collections, System.SyncObjs, System.DateUtils,
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer, IdUDPClient,
  IdCustomTCPServer, IdTCPServer, IdTCPClient, IdContext,
  IdSocketHandle, IdGlobal;
type

  TPeerInfo = record
    ID: string;
    Name: string;
    IP: string;
    TCPPort: Integer;
  end;

  TPeerEvent = procedure(Sender: TObject; const Peer: TPeerInfo) of object;
  TMessageEvent = procedure(Sender: TObject;
    const SenderName, Msg, PeerIP: string) of object;
  TLogEvent = procedure(Sender: TObject; const Line: string) of object;
  TGetSendValuesEvent = procedure(Sender: TObject;
    out FX: Double; out Domestic, Coin: Cardinal) of object;

  TChatComm = class;

  THeartbeatThread = class(TThread)
  private
    FOwner: TChatComm;
    FStopEvent: TEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TChatComm);
    destructor Destroy; override;
    procedure SignalStop;
  end;

  TPeer = class
    ID: string;
    Name: string;
    IP: string;
    TCPPort: Integer;
    LastSeen: TDateTime;
  end;

  TChatComm = class
  private
    FStarted: Boolean;
    FClosing: Boolean;
    FInstanceID: string;
    FSystemName: string;
    FBroadcastIP: string;
    FUDPPort: Integer;
    FTCPPort: Integer;
    FActualTCPPort: Integer;
    FHeartbeatMS: Integer;
    FPeerTimeoutSec: Integer;
    FSendSeq: Integer;
    FSendDate: string;
    FAutoSendSec: Integer;
    FAutoSendPaused: Boolean;
    FLogPath: string;
    FLogLock: TCriticalSection;
    FUDPServer: TIdUDPServer;
    FUDPClient: TIdUDPClient;
    FTCPServer: TIdTCPServer;
    FThread: THeartbeatThread;
    FPeers: TObjectDictionary<string, TPeer>;
    FLock: TCriticalSection;
    FOnPeerJoined: TPeerEvent;
    FOnPeerLeft: TPeerEvent;
    FOnMessageReceived: TMessageEvent;
    FOnLog: TLogEvent;
    FOnGetSendValues: TGetSendValuesEvent;
    procedure UDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes;
      ABinding: TIdSocketHandle);
    procedure TCPExecute(AContext: TIdContext);
    procedure BroadcastHello;
    procedure BroadcastBye;
    function MakePeerInfo(P: TPeer): TPeerInfo;
    function NextSendID: string;
    function CurrentLogPath: string;
    procedure WriteAuditLog(const Line: string);
    procedure DoAutoSend;
    procedure QueuePeerJoined(const Peer: TPeerInfo);
    procedure QueuePeerLeft(const Peer: TPeerInfo);
    procedure QueueMessage(const SenderName, Msg, PeerIP: string);
    procedure QueueLog(const Line: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure SendMessage(const Msg: string);
    function SendPayload(FX: Double; Domestic, Coin: Cardinal): string;
    procedure PauseAutoSend;
    procedure ResumeAutoSend;
    function PeerSnapshot: TArray<TPeerInfo>;
    procedure CleanupStalePeers;
    property InstanceID: string read FInstanceID;
    property SystemName: string read FSystemName write FSystemName;
    property BroadcastIP: string read FBroadcastIP write FBroadcastIP;
    property UDPPort: Integer read FUDPPort write FUDPPort;
    property TCPPort: Integer read FTCPPort write FTCPPort;
    property ActualTCPPort: Integer read FActualTCPPort;
    property HeartbeatMS: Integer read FHeartbeatMS write FHeartbeatMS;
    property PeerTimeoutSec: Integer read FPeerTimeoutSec write FPeerTimeoutSec;
    property AutoSendSec: Integer read FAutoSendSec write FAutoSendSec;
    property AutoSendPaused: Boolean read FAutoSendPaused;
    property LogPath: string read FLogPath write FLogPath;
    property Started: Boolean read FStarted;
    property OnPeerJoined: TPeerEvent read FOnPeerJoined write FOnPeerJoined;
    property OnPeerLeft: TPeerEvent read FOnPeerLeft write FOnPeerLeft;
    property OnMessageReceived: TMessageEvent read FOnMessageReceived write FOnMessageReceived;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnGetSendValues: TGetSendValuesEvent
      read FOnGetSendValues write FOnGetSendValues;
  end;

implementation

{ THeartbeatThread }

constructor THeartbeatThread.Create(AOwner: TChatComm);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FStopEvent := TEvent.Create(nil, True, False, '');
end;
destructor THeartbeatThread.Destroy;
begin
  FStopEvent.Free;
  inherited;
end;
procedure THeartbeatThread.SignalStop;
begin
  Terminate;
  FStopEvent.SetEvent;
end;
procedure THeartbeatThread.Execute;
const
  TICK_MS = 500;
var
  LastHeartbeat, LastAutoSend: TDateTime;
begin
  LastHeartbeat := Now;
  LastAutoSend := Now;
  while not Terminated do
  begin
    if FStopEvent.WaitFor(TICK_MS) = wrSignaled then Break;
    if MilliSecondsBetween(Now, LastHeartbeat) >= FOwner.HeartbeatMS then
    begin
      LastHeartbeat := Now;
      try FOwner.BroadcastHello; except end;
      FOwner.CleanupStalePeers;
    end;
    if (FOwner.AutoSendSec > 0) and (not FOwner.AutoSendPaused) and
       (SecondsBetween(Now, LastAutoSend) >= FOwner.AutoSendSec) then
    begin
      LastAutoSend := Now;
      try FOwner.DoAutoSend; except end;
    end;
  end;
end;
{ TChatComm }
constructor TChatComm.Create;
var
  G: TGUID;
begin
  inherited;
  CreateGUID(G);
  FInstanceID := Copy(GUIDToString(G), 2, 8);
  FSystemName := 'User_' + IntToStr(GetCurrentProcessId);
  FBroadcastIP := '255.255.255.255';
  FUDPPort := 8888;
  FTCPPort := 0;
  FHeartbeatMS := 5000;
  FPeerTimeoutSec := 15;
  FSendSeq := 0;
  FSendDate := '';
  FAutoSendSec := 0;
  FAutoSendPaused := False;
  FLogPath := '';
  FLogLock := TCriticalSection.Create;
  FPeers := TObjectDictionary<string, TPeer>.Create([doOwnsValues]);
  FLock := TCriticalSection.Create;
  FUDPServer := TIdUDPServer.Create(nil);
  FUDPServer.BroadcastEnabled := True;
  FUDPServer.OnUDPRead := UDPRead;
  FUDPClient := TIdUDPClient.Create(nil);
  FUDPClient.BroadcastEnabled := True;
  FTCPServer := TIdTCPServer.Create(nil);
  FTCPServer.OnExecute := TCPExecute;
end;
destructor TChatComm.Destroy;
begin
  Stop;
  FUDPServer.Free;
  FUDPClient.Free;
  FTCPServer.Free;
  FPeers.Free;
  FLock.Free;
  FLogLock.Free;
  inherited;
end;

procedure TChatComm.Start;
var
  Binding: TIdSocketHandle;
begin
  if FStarted then Exit;
  FClosing := False;
  FUDPServer.Bindings.Clear;
  Binding := FUDPServer.Bindings.Add;

  Binding.IP := '0.0.0.0';
  Binding.Port := FUDPPort;
  Binding.ReuseSocket := rsTrue;
  FUDPServer.DefaultPort := FUDPPort;
  FUDPServer.Active := True;
  FTCPServer.Bindings.Clear;
  FTCPServer.DefaultPort := FTCPPort;
  FTCPServer.Active := True;
  if FTCPServer.Bindings.Count > 0 then
    FActualTCPPort := FTCPServer.Bindings[0].Port
  else
    FActualTCPPort := FTCPPort;
  FStarted := True;
  try BroadcastHello; except end;
  FThread := THeartbeatThread.Create(Self);
  FThread.Start;
end;

procedure TChatComm.Stop;
var
  i: Integer;
  ContextList: TList;
begin
  if not FStarted then Exit;
  FClosing := True;
  if Assigned(FThread) then
  begin
    FThread.SignalStop;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  try BroadcastBye; except end;
  if FTCPServer.Active then
  begin
    ContextList := FTCPServer.Contexts.LockList;
    try
      for i := 0 to ContextList.Count - 1 do
        try TIdContext(ContextList[i]).Connection.Disconnect; except end;
    finally
      FTCPServer.Contexts.UnlockList;
    end;
    try FTCPServer.Active := False; except end;
  end;
  if FUDPServer.Active then
    try FUDPServer.Active := False; except end;
  CheckSynchronize;
  FLock.Enter;
  try FPeers.Clear; finally FLock.Leave; end;
  FStarted := False;
end;

procedure TChatComm.BroadcastHello;
var
  Packet: string;
begin
  Packet := 'HELLO' + #9 + FInstanceID + #9 + FSystemName + #9 + IntToStr(FActualTCPPort);
  FUDPClient.BroadcastEnabled := True;
  FUDPClient.Broadcast(Packet, FUDPPort, FBroadcastIP, IndyTextEncoding_UTF8);
end;
procedure TChatComm.BroadcastBye;
var
  Packet: string;
begin
  Packet := 'BYE' + #9 + FInstanceID;
  FUDPClient.BroadcastEnabled := True;
  FUDPClient.Broadcast(Packet, FUDPPort, FBroadcastIP, IndyTextEncoding_UTF8);
end;
function TChatComm.CurrentLogPath: string;
begin
  if FLogPath = '' then
    Result := ''
  else
    Result := FLogPath + '_' + FormatDateTime('yyyy-mm-dd', Now) + '.log';
end;
procedure TChatComm.WriteAuditLog(const Line: string);
var
  Writer: TStreamWriter;
  Path: string;
begin
  Path := CurrentLogPath;
  if Path = '' then Exit;
  FLogLock.Enter;
  try
    try
      Writer := TStreamWriter.Create(Path, True, TEncoding.UTF8);
      try
        Writer.WriteLine(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz ', Now) + Line);
      finally
        Writer.Free;
      end;
    except
    end;
  finally
    FLogLock.Leave;
  end;
end;
procedure TChatComm.PauseAutoSend;
begin
  FAutoSendPaused := True;
  WriteAuditLog('[pause]');
end;
procedure TChatComm.ResumeAutoSend;
begin
  FAutoSendPaused := False;
  WriteAuditLog('[resume]');
end;
procedure TChatComm.DoAutoSend;
var
  FX: Double;
  Domestic, Coin: Cardinal;
  Sent: string;
begin
  if not Assigned(FOnGetSendValues) then Exit;
  FX := 0;
  Domestic := 0;
  Coin := 0;
  try
    FOnGetSendValues(Self, FX, Domestic, Coin);
  except
    on E: Exception do
    begin
      WriteAuditLog('[err OnGetSendValues] ' + E.Message);
      Exit;
    end;
  end;
  Sent := SendPayload(FX, Domestic, Coin);
  if Sent <> '' then
  begin
    WriteAuditLog('[sent-auto] ' + Sent);
    QueueLog('>> 나(자동): ' + Sent);
  end;
end;
function TChatComm.NextSendID: string;
var
  TodayStr: string;
begin
  TodayStr := FormatDateTime('yyyymmdd', Now);
  if TodayStr <> FSendDate then
  begin
    FSendDate := TodayStr;
    FSendSeq := 0;
  end;
  Inc(FSendSeq);
  Result := Format('sig-%s-%.3d', [TodayStr, FSendSeq]);
end;

function TChatComm.SendPayload(FX: Double; Domestic, Coin: Cardinal): string;
var
  fs: TFormatSettings;
begin
  if not FStarted then Exit('');
  fs := TFormatSettings.Create;
  fs.DecimalSeparator := '.';
  Result := Format(
    '{"id":"%s","fx":%s,"total_domestic":%u,"total_coin":%u,' +
    '"token":"Dalin","datetime":"%s"}',
    [NextSendID, FloatToStr(FX, fs), Domestic, Coin,
     FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)]);
  SendMessage(Result);
end;

function TChatComm.MakePeerInfo(P: TPeer): TPeerInfo;
begin
  Result.ID := P.ID;
  Result.Name := P.Name;
  Result.IP := P.IP;
  Result.TCPPort := P.TCPPort;
end;

procedure TChatComm.UDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  Raw, Typ, SenderID, SenderName, PeerIP: string;
  Parts: TArray<string>;
  TCPPort: Integer;
  Peer: TPeer;
  IsNew: Boolean;
  Info: TPeerInfo;
  FoundForBye: Boolean;
begin
  Raw := IndyTextEncoding_UTF8.GetString(AData);
  PeerIP := ABinding.PeerIP;
  Parts := Raw.Split([#9]);
  if Length(Parts) < 2 then Exit;
  Typ := Parts[0];
  SenderID := Parts[1];
  if SenderID = FInstanceID then Exit;
  if (Typ = 'HELLO') and (Length(Parts) >= 4) then
  begin
    SenderName := Parts[2];
    TCPPort := StrToIntDef(Parts[3], 0);
    if TCPPort = 0 then Exit;
    IsNew := False;
    FLock.Enter;
    try
      if not FPeers.TryGetValue(SenderID, Peer) then
      begin
        Peer := TPeer.Create;
        Peer.ID := SenderID;
        FPeers.Add(SenderID, Peer);
        IsNew := True;
      end;
      Peer.Name := SenderName;
      Peer.IP := PeerIP;
      Peer.TCPPort := TCPPort;
      Peer.LastSeen := Now;
      Info := MakePeerInfo(Peer);
    finally
      FLock.Leave;
    end;
    if IsNew then
      QueuePeerJoined(Info);
  end
  else if Typ = 'BYE' then
  begin
    FoundForBye := False;
    FLock.Enter;
    try
      if FPeers.TryGetValue(SenderID, Peer) then
      begin
        Info := MakePeerInfo(Peer);
        FPeers.Remove(SenderID);
        FoundForBye := True;
      end;
    finally
      FLock.Leave;
    end;
    if FoundForBye then
      QueuePeerLeft(Info);
  end;
end;

procedure TChatComm.TCPExecute(AContext: TIdContext);
var
  Line, SenderName, Msg, PeerIP: string;
  Parts: TArray<string>;
begin
  try
    Line := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
  except
    AContext.Connection.Disconnect;
    Exit;
  end;
  PeerIP := AContext.Binding.PeerIP;
  Parts := Line.Split([#9], 3);
  if Length(Parts) < 3 then
  begin
    AContext.Connection.Disconnect;
    Exit;
  end;
  SenderName := Parts[1];
  Msg := Parts[2];
  QueueMessage(SenderName, Msg, PeerIP);
  AContext.Connection.Disconnect;
end;

procedure TChatComm.CleanupStalePeers;
var
  ToRemove: TArray<TPeerInfo>;
  Pair: TPair<string, TPeer>;
  NowTime: TDateTime;
  i: Integer;
begin
  SetLength(ToRemove, 0);
  NowTime := Now;
  FLock.Enter;
  try
    for Pair in FPeers do
      if SecondsBetween(NowTime, Pair.Value.LastSeen) > FPeerTimeoutSec then
      begin
        SetLength(ToRemove, Length(ToRemove) + 1);
        ToRemove[High(ToRemove)] := MakePeerInfo(Pair.Value);
      end;
    for i := 0 to High(ToRemove) do
      FPeers.Remove(ToRemove[i].ID);
  finally
    FLock.Leave;
  end;
  for i := 0 to High(ToRemove) do
    QueuePeerLeft(ToRemove[i]);
end;

procedure TChatComm.SendMessage(const Msg: string);
type
  TPeerSnap = record
    IP: string;
    Port: Integer;
  end;
var
  Snapshot: TArray<TPeerSnap>;
  Peer: TPeer;
  i: Integer;
  Packet: string;
begin
  if not FStarted then Exit;
  Packet := FInstanceID + #9 + FSystemName + #9 + Msg;
  FLock.Enter;
  try
    SetLength(Snapshot, FPeers.Count);
    i := 0;
    for Peer in FPeers.Values do
    begin
      Snapshot[i].IP := Peer.IP;
      Snapshot[i].Port := Peer.TCPPort;
      Inc(i);
    end;
  finally
    FLock.Leave;
  end;
  if Length(Snapshot) = 0 then Exit;
  TThread.CreateAnonymousThread(
    procedure
    var
      S: TPeerSnap;
      Client: TIdTCPClient;
    begin
      for S in Snapshot do
      begin
        Client := TIdTCPClient.Create(nil);
        try
          Client.Host := S.IP;
          Client.Port := S.Port;
          Client.ConnectTimeout := 2000;
          try
            Client.Connect;
            try
              Client.IOHandler.WriteLn(Packet, IndyTextEncoding_UTF8);
            finally
              Client.Disconnect;
            end;
          except
            on E: Exception do
              WriteAuditLog(Format('[err send to %s:%d] %s',
                [S.IP, S.Port, E.Message]));
          end;
        finally
          Client.Free;
        end;
      end;
    end).Start;
end;
function TChatComm.PeerSnapshot: TArray<TPeerInfo>;
var
  Peer: TPeer;
  i: Integer;
begin
  FLock.Enter;
  try
    SetLength(Result, FPeers.Count);
    i := 0;
    for Peer in FPeers.Values do
    begin
      Result[i] := MakePeerInfo(Peer);
      Inc(i);
    end;
  finally
    FLock.Leave;
  end;
end;
procedure TChatComm.QueuePeerJoined(const Peer: TPeerInfo);
var
  LocalPeer: TPeerInfo;
  P: TThreadProcedure;
begin
  if FClosing then Exit;
  LocalPeer := Peer;
  P := procedure
       begin
         if FClosing then Exit;
         if Assigned(FOnPeerJoined) then FOnPeerJoined(Self, LocalPeer);
       end;
  TThread.Queue(nil, P);
end;
procedure TChatComm.QueuePeerLeft(const Peer: TPeerInfo);
var
  LocalPeer: TPeerInfo;
  P: TThreadProcedure;
begin
  if FClosing then Exit;
  LocalPeer := Peer;
  P := procedure
       begin
         if FClosing then Exit;
         if Assigned(FOnPeerLeft) then FOnPeerLeft(Self, LocalPeer);
       end;
  TThread.Queue(nil, P);
end;
procedure TChatComm.QueueMessage(const SenderName, Msg, PeerIP: string);
var
  LocalName, LocalMsg, LocalIP: string;
  P: TThreadProcedure;
begin
  if FClosing then Exit;
  LocalName := SenderName;
  LocalMsg := Msg;
  LocalIP := PeerIP;
  P := procedure
       begin
         if FClosing then Exit;
         if Assigned(FOnMessageReceived) then
           FOnMessageReceived(Self, LocalName, LocalMsg, LocalIP);
       end;
  TThread.Queue(nil, P);
end;
procedure TChatComm.QueueLog(const Line: string);
var
  LocalLine: string;
  P: TThreadProcedure;
begin
  if FClosing then Exit;
  LocalLine := Line;
  P := procedure
       begin
         if FClosing then Exit;
         if Assigned(FOnLog) then FOnLog(Self, LocalLine);
       end;
  TThread.Queue(nil, P);
end;
end.
