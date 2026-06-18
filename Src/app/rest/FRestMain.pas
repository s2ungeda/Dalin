unit FRestMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  REST.Types, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope,

  USharedData, USharedThread, UApiTypes, Vcl.ExtCtrls
  ;


type
  TFrmRestMain = class(TForm)
    m: TMemo;
    RESTClient1: TRESTClient;
    BinReq: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTClient2: TRESTClient;
    UpbReq: TRESTRequest;
    RESTResponse2: TRESTResponse;
    RESTClient3: TRESTClient;
    BitReq: TRESTRequest;
    RESTResponse3: TRESTResponse;
    RESTClient4: TRESTClient;
    BinSpotReq: TRESTRequest;
    RESTResponse4: TRESTResponse;
    RESTClient5: TRESTClient;
    RESTResponse5: TRESTResponse;
    BinFutCmReq: TRESTRequest;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Timer1: TTimer;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

    procedure initControls;
    function GetEntropy(var sData: string): boolean;
    { Private declarations }
  public
    { Public declarations }
    mt : array [TSharedThreadType] of TSharedThread;
    procedure OnNotify(const S: string);
  end;

var
  FrmRestMain: TFrmRestMain;

implementation

uses
  system.IniFiles
  , GApp
  , GLibs
  , URestBase
  , USimpleShareMemory
  ;

{$R *.dfm}

procedure TFrmRestMain.Button1Click(Sender: TObject);
begin
  //
  mt[stBtSThread].DoSetEvent(true);
end;

procedure TFrmRestMain.Button2Click(Sender: TObject);
begin
  mt[stBtSThread].DoSetEvent(false);
end;

procedure TFrmRestMain.Button3Click(Sender: TObject);
var
  i : integer;
begin
//  mt[stBtSThread].PushData2( 'T', 'S', 'B', 'XRP', 'XRP' )  ;
//  exit;
  for I := 0 to 9 do
    mt[stBtSThread].PushData2( 'T', 'S', 'O', 'XRP', 'XRP' )  ;
end;

procedure TFrmRestMain.Button4Click(Sender: TObject);
begin
//
  mt[stBtSThread].PushData2( 'T', 'S', 'O', 'XRP', 'XRP' )  ;
//  mt[stBtSThread].PushData2( 'T', 'S', 'B', 'XRP', 'XRP' )  ;
end;

procedure TFrmRestMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := false;
  Action := caFree;
end;

procedure TFrmRestMain.FormCreate(Sender: TObject);
var
  i : TSharedThreadType;
  sData: string;
begin

{$IFDEF RELEASE}
  if not GetEntropy(sData) then
  begin
    ShowMessage('잘못된 인자로 실행할수 없음');
    Application.Terminate;
  end;
{$ENDIF}

{$IFDEF DEBUG}
  sData := ParamStr(1);
{$ENDIF}
  App := TApp.Create;

  if not App.LoadConfig then
  begin
    ShowMessage('환경설정 파일을 읽을수 없음');
    PostMessage(Handle, WM_CLOSE, 0, 0);
    Exit;
  end;

  try
    App.Entropy := sData;
  except
    PostMessage(Handle, WM_CLOSE, 0, 0);
    Exit;
  end;

  if not App.LoadKeys then
  begin
    ShowMessage('Key 정보를 로드 할수 없음.');
    PostMessage(Handle, WM_CLOSE, 0, 0);
    Exit;
  end;

  initControls;

  // 거래소마다 TReqclient 를 따로 사용...
  for i := stBnSThread to High(TSharedThreadType) do begin
    mt[i] := TSharedThread.Create(App.RestManager.OnSharedDataNotify, false, i);
    App.RestManager.init(i, mt[i].PushData);
    mt[i].Resume;
  end;

  App.DebugLog('main thread id = %d', [TThread.CurrentThread.ThreadID]);
  Caption  := Format('%s ver.%s', [Caption, FileVersionToStr(Application.ExeName)]);

  Timer1.Enabled := true;

end;

procedure TFrmRestMain.FormDestroy(Sender: TObject);
var
  i : TSharedThreadType;
begin
  for i := stBnSThread to High(TSharedThreadType) do
    if mt[i] <> nil then begin
      mt[i].Terminate;
      mt[i].WaitFor;
      mt[i].Free;
    end;
  App.Free;
end;

function TFrmRestMain.GetEntropy(var sData: string): boolean;
begin
  Result := false;
  sData := '';
  try
    sData:= TSimpleShareMemory.Read(ParamStr(1));
    if sData.IsEmpty then Exit;
    Result := true;
  except
  end;
end;

procedure TFrmRestMain.initControls;
var
  sData: string;
begin





//  BinReq.Client.BaseURL := App.ApiConfig.GetBaseUrl( ekBinance, eaFutUsdt);
//  UpbReq.Client.BaseURL := App.ApiConfig.GetBaseUrl( ekUpbit, eaSpot);
//  BitReq.Client.BaseURL := App.ApiConfig.GetBaseUrl( ekBithumb, eaSpot );
//  BinSpotReq.Client.BaseURL := App.ApiConfig.GetBaseUrl( ekBinance, eaSpot);
//  BinFutCmReq.Client.BaseURL:= App.ApiConfig.GetBaseUrl( ekBinance, eaFutCoin);
end;

procedure TFrmRestMain.OnNotify(const S: string);
begin
  m.Lines.Add( Copy(s, 1, 100 ) );
end;




procedure TFrmRestMain.Timer1Timer(Sender: TObject);
var
  i : TSharedThreadType;
  aRb : TRestBase;
  x, y, j, k: integer;
begin
  //
  x := 10; y := 10;  j := 0; k:= 70;
  for I := stBnSThread to High(TSharedThreadType) do
  begin

    aRb := App.RestManager.Rest[i];
    Canvas.TextOut(x+(j*k)+10, y, Copy(STTypeToStr(i), 1, 3) );
    Canvas.TextOut(x+(j*k), y+20, Format('(%02d, %02d)',
      [aRb.AsyncRESTs.Ready.Count, aRb.AsyncRESTs.Wroks.Count] ));
    inc(j);
  end;

end;

end.
