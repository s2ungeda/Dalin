unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,

  UQueryExRate
  ;

type
  TFrmExRate = class(TForm)
    lblStatus: TLabel;
    lblRate: TLabel;
    TrayIcon1: TTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    FThread: TExRateThread;
  public
    { Public declarations }
    procedure OnThreadLog(const ALog: string);
    procedure WmSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;

var
  FrmExRate: TFrmExRate;

implementation

{$R *.dfm}

function FileVersionToStr(FileName: String): String;
var
  Size, Size2: DWord;
  pT, pT2: Pointer;
begin
  Result := '';
  Size := GetFileVersionInfoSize(PChar(FileName), Size2);
  if Size > 0 then
  begin
    GetMem(Pt, Size);
    try
      GetFileVersionInfo(PChar(FileName), 0, Size, Pt);
      VerQueryValue(Pt, '\', Pt2, Size2);
      with TVSFixedFileInfo(Pt2^) do
      begin
        Result := IntToStr(HiWord(dwFileVersionMS)) + '.' +//major version
                  IntToStr(LoWord(dwFileVersionMS)) + '.' +//minor version
                  IntToStr(HiWord(dwFileVersionLS)) + '.' +//release
                  IntToStr(LoWord(dwFileVersionLS));       //build
      end;
    finally
      FreeMem(Pt);
    end;//try
  end;//if

end;

procedure TFrmExRate.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Ensure we actually close instead of creating ghost processes if needed
  CanClose := True;
end;

procedure TFrmExRate.FormCreate(Sender: TObject);
begin
  lblStatus.Caption := 'Waiting for data...';
  lblRate.Caption := '---';

  FThread := TExRateThread.Create;
  FThread.OnLog :=
    procedure(ALog: string)
    begin
      OnThreadLog(ALog);
    end;

  // Setup TrayIcon
  TrayIcon1.Visible := True;
  TrayIcon1.BalloonTitle := 'Exchange Rate Monitor';
  TrayIcon1.BalloonHint := 'Running in background...';

  Caption := Format('%s ver.%s', [Caption, FileVersionToStr(Application.ExeName)]);
end;

procedure TFrmExRate.FormDestroy(Sender: TObject);
begin
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FThread.Free;
  end;
end;

procedure TFrmExRate.FormResize(Sender: TObject);
begin
  if WindowState = wsMinimized then
  begin
    Hide; // Hide from taskbar
    TrayIcon1.Visible := True;
    // Optional: Show balloon hint
    // TrayIcon1.ShowBalloonHint;
  end;
end;

procedure TFrmExRate.OnThreadLog(const ALog: string);
var
  LParts: TArray<string>;
begin
  // ALog format: "DateTime,Price"
  LParts := ALog.Split([',']);
  if Length(LParts) >= 2 then
  begin
    lblStatus.Caption := 'Last Update: ' + LParts[0];
    lblRate.Caption := 'Current : ' + LParts[1];
    TrayIcon1.Hint := 'Rate: ' + LParts[1] + ' (' + LParts[0] + ')';
  end;

end;

procedure TFrmExRate.TrayIcon1DblClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  Application.BringToFront;
end;

procedure TFrmExRate.WmSysCommand(var Msg: TWMSysCommand);
begin
  if (Msg.CmdType = SC_MINIMIZE) then
  begin
    Hide;
    TrayIcon1.Visible := True;
  end
  else
    inherited;
end;

end.
