unit FChatMonitor;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  ChatComm;
type
  TFrmChatComm = class(TForm)
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlRight: TPanel;
    lblPeers: TLabel;
    lstPeers: TListBox;
    memLog: TMemo;
    lblFX: TLabel;
    edtFX: TEdit;
    lblDomestic: TLabel;
    edtDomestic: TEdit;
    lblCoin: TLabel;
    edtCoin: TEdit;
    btnSend: TButton;
    lblName: TLabel;
    edtName: TEdit;
    lblUDPPort: TLabel;
    edtUDPPort: TEdit;
    lblTCPPort: TLabel;
    edtTCPPort: TEdit;
    lblBroadcast: TLabel;
    edtBroadcast: TEdit;
    btnStart: TButton;
    lblInterval: TLabel;
    edtInterval: TEdit;
    btnUpdateInterval: TButton;
    btnPauseResume: TButton;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnPauseResumeClick(Sender: TObject);
    procedure btnUpdateIntervalClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    FComm: TChatComm;
    procedure AppendLog(const Line: string);
    procedure RefreshPeerList;
    procedure HandleLog(Sender: TObject; const Line: string);
    procedure HandlePeerJoined(Sender: TObject; const Peer: TPeerInfo);
    procedure HandlePeerLeft(Sender: TObject; const Peer: TPeerInfo);
    procedure HandleMessageReceived(Sender: TObject;
      const SenderName, Msg, PeerIP: string);
    procedure HandleGetSendValues(Sender: TObject;
      out FX: Double; out Domestic, Coin: Cardinal);
    procedure SetControls;
  public
    procedure ShowMonitor;
  end;
var
  FrmChatComm: TFrmChatComm;
implementation
uses
  GApp
  , DalinMain
  ;
{$R *.dfm}

procedure TFrmChatComm.SetControls;
begin
  if FComm.AutoSendPaused  then
    btnPauseResume.Caption := 'Resume Auto'
  else
    btnPauseResume.Caption := 'Pause Auto';


  if FComm.Started then
  begin
    btnStart.Caption := 'Stop';
    edtName.Enabled := False;
    edtUDPPort.Enabled := False;
    edtTCPPort.Enabled := False;
  end else
  begin
    btnStart.Caption := 'Start';
    edtName.Enabled := True;
    edtUDPPort.Enabled := True;
    edtTCPPort.Enabled := True;
  end;

end;

procedure TFrmChatComm.ShowMonitor;
begin

  FComm.OnLog := HandleLog;
  FComm.OnPeerJoined := HandlePeerJoined;
  FComm.OnPeerLeft := HandlePeerLeft;
  FComm.OnMessageReceived := HandleMessageReceived;

  Show;
end;

procedure TFrmChatComm.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  FComm.OnLog := nil;;
  FComm.OnPeerJoined := nil;
  FComm.OnPeerLeft := nil;
  FComm.OnMessageReceived := nil;

  Action := caHide;
end;

procedure TFrmChatComm.FormCreate(Sender: TObject);
begin
  FComm := FrmDalinMain.ChatCom;//
  // 모니터링용
  FComm.OnLog := HandleLog;
  FComm.OnPeerJoined := HandlePeerJoined;
  FComm.OnPeerLeft := HandlePeerLeft;
  FComm.OnMessageReceived := HandleMessageReceived;
  //
  edtName.Text := FComm.SystemName;
  edtUDPPort.Text := IntToStr(FComm.UDPPort);
  edtTCPPort.Text := IntToStr(FComm.TCPPort);
  edtBroadcast.Text := FComm.BroadcastIP;
  edtInterval.Text := IntToStr(FComm.AutoSendSec);

  SetControls;

  memLog.Clear;
  lstPeers.Clear;
end;
procedure TFrmChatComm.FormDestroy(Sender: TObject);
begin
  FComm.OnLog := nil;;
  FComm.OnPeerJoined := nil;
  FComm.OnPeerLeft := nil;
  FComm.OnMessageReceived := nil;
end;

procedure TFrmChatComm.AppendLog(const Line: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss ', Now) + Line);

  if memLog.Lines.Count > 1000 then
    for var I := 900 to memLog.Lines.Count-1 do
      memlog.Lines.Delete(i);

end;
procedure TFrmChatComm.RefreshPeerList;
var
  Peers: TArray<TPeerInfo>;
  i: Integer;
begin
  Peers := FComm.PeerSnapshot;
  lstPeers.Items.BeginUpdate;
  try
    lstPeers.Items.Clear;
    for i := 0 to High(Peers) do
      lstPeers.Items.Add(Format('%s (%s:%d)',
        [Peers[i].Name, Peers[i].IP, Peers[i].TCPPort]));
  finally
    lstPeers.Items.EndUpdate;
  end;
end;
procedure TFrmChatComm.btnStartClick(Sender: TObject);
begin
  if FComm.Started then
  begin
    FComm.Stop;
    btnStart.Caption := 'Start';
    edtName.Enabled := True;
    edtUDPPort.Enabled := True;
    edtTCPPort.Enabled := True;
    AppendLog('[info] 중지됨.');
    RefreshPeerList;
    Exit;
  end;
  FComm.SystemName := edtName.Text;
  FComm.UDPPort := StrToIntDef(edtUDPPort.Text, 8888);
  FComm.TCPPort := StrToIntDef(edtTCPPort.Text, 0);
  FComm.BroadcastIP := edtBroadcast.Text;
  FComm.AutoSendSec := StrToIntDef(edtInterval.Text, 10);
  try
    FComm.Start;
    btnStart.Caption := 'Stop';
    edtName.Enabled := False;
    edtUDPPort.Enabled := False;
    edtTCPPort.Enabled := False;
    AppendLog(Format('[info] 시작됨. UDP=%d TCP=%d 이름=%s',
      [FComm.UDPPort, FComm.ActualTCPPort, FComm.SystemName]));
//    edtFX.SetFocus;
  except
    on E: Exception do
      AppendLog('[error] 시작 실패: ' + E.Message);
  end;
end;
procedure TFrmChatComm.btnSendClick(Sender: TObject);
var
  fs: TFormatSettings;
  FX: Double;
  Domestic, Coin: Cardinal;
  Sent: string;
begin
  if not FComm.Started then
  begin
    AppendLog('[error] 먼저 Start 를 눌러 주세요.');
    Exit;
  end;

  FX := 0; Domestic := 0; Coin := 0;

  if Assigned(FComm.OnGetSendValues) then
    FComm.OnGetSendValues(FComm, FX, Domestic, Coin);

  if (FX <= 0) or (Domestic <= 0) or (Coin <= 0) then Exit;

  edtFX.Text        := Format('%.2n', [FX]);
  edtCoin.Text      := Format('%.0n', [Coin + 0.001]);
  edtDomestic.Text  := Format('%.0n', [Domestic + 0.001]);

  Sent := FComm.SendPayload(FX, Domestic, Coin);

  AppendLog('>> 나: ' + Sent);
end;

procedure TFrmChatComm.HandleLog(Sender: TObject; const Line: string);
begin
  AppendLog(Line);
end;

procedure TFrmChatComm.HandlePeerJoined(Sender: TObject; const Peer: TPeerInfo);
begin
  AppendLog(Format('[info] 접속: %s (%s:%d)',
    [Peer.Name, Peer.IP, Peer.TCPPort]));
  RefreshPeerList;
end;

procedure TFrmChatComm.HandlePeerLeft(Sender: TObject; const Peer: TPeerInfo);
begin
  AppendLog(Format('[info] 퇴장: %s', [Peer.Name]));
  RefreshPeerList;
end;
procedure TFrmChatComm.HandleMessageReceived(Sender: TObject;
  const SenderName, Msg, PeerIP: string);
begin
  AppendLog(Format('(%s) %s: %s', [PeerIP, SenderName, Msg]));
end;
procedure TFrmChatComm.HandleGetSendValues(Sender: TObject;
  out FX: Double; out Domestic, Coin: Cardinal);
var
  LocalFX: Double;
  LocalDomestic, LocalCoin: Cardinal;
begin
  // 자동 송신 콜백은 워커 스레드에서 호출됨 → 에디트박스 접근은 메인 스레드로
  TThread.Synchronize(nil,
    procedure
    var
      fs: TFormatSettings;
    begin
      fs := TFormatSettings.Create;
      fs.DecimalSeparator := '.';
      LocalFX := StrToFloatDef(edtFX.Text, 0, fs);
      LocalDomestic := StrToUIntDef(edtDomestic.Text, 0);
      LocalCoin := StrToUIntDef(edtCoin.Text, 0);
    end);
  FX := LocalFX;
  Domestic := LocalDomestic;
  Coin := LocalCoin;
end;
procedure TFrmChatComm.btnPauseResumeClick(Sender: TObject);
begin
  if FComm.AutoSendPaused then
  begin
    FComm.ResumeAutoSend;
    btnPauseResume.Caption := 'Pause Auto';
    AppendLog('[info] 자동 송신 재개');
  end
  else
  begin
    FComm.PauseAutoSend;
    btnPauseResume.Caption := 'Resume Auto';
    AppendLog('[info] 자동 송신 일시정지');
  end;
end;
procedure TFrmChatComm.btnUpdateIntervalClick(Sender: TObject);
var
  NewSec: Integer;
begin
  NewSec := StrToIntDef(edtInterval.Text, 0);
  FComm.AutoSendSec := NewSec;
  AppendLog(Format('[info] 자동 송신 주기 변경: %d초', [NewSec]));
end;
procedure TFrmChatComm.Button1Click(Sender: TObject);
begin
  memLog.Clear;
end;

end.
