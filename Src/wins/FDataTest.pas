unit FDataTest;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls
  , UApiTypes
  , USymbols
  ;
type
  TFrmTest = class(TForm)
    edtCode: TEdit;
    cbDpst: TCheckBox;
    cbWd: TCheckBox;
    Button1: TButton;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Panel1: TPanel;
    Label3: TLabel;
    ComboBox3: TComboBox;
    Edit2: TEdit;
    CheckBox4: TCheckBox;
    mKip: TMemo;
    kipTimer: TTimer;
    Panel2: TPanel;
    Label2: TLabel;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    CheckBox3: TCheckBox;
    mWcd: TMemo;
    wcdTimer: TTimer;
    지우기: TButton;
    Button2: TButton;
    cbBT: TCheckBox;
    plBT: TPanel;
    lbBT: TLabel;
    btnBTDiscon: TButton;
    btnBTCon: TButton;
    btnBTSub: TButton;
    btnBTunsub: TButton;
    cbUP: TCheckBox;
    plUP: TPanel;
    lbUp: TLabel;
    btnUpDiscon: TButton;
    btnUpcon: TButton;
    btnUpsub: TButton;
    btnUpunsub: TButton;
    wsTimer: TTimer;
    cbBN: TCheckBox;
    Panel3: TPanel;
    lbBN: TLabel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Panel4: TPanel;
    Label4: TLabel;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure kipTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure wcdTimerTimer(Sender: TObject);
    procedure cbBTClick(Sender: TObject);
    procedure wsTimerTimer(Sender: TObject);
    procedure btnBTDisconClick(Sender: TObject);
    procedure btnBTConClick(Sender: TObject);
    procedure btnBTSubClick(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure btnBTunsubClick(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
  private
    procedure kipLog;
    procedure wcdLog;
    { Private declarations }
  public
    { Public declarations }
    Symbol1 : TSymbol;
    Symbol2 : TSymbol;
    LastCnt1 : int64;
    LastCnt2 : int64;
  end;
var
  FrmTest: TFrmTest;
implementation
uses
  GApp , GLibs
  , UConsts
  , UDataLogs
  , UBinanceWebSockets
  ;
{$R *.dfm}
procedure TFrmTest.btnBTConClick(Sender: TObject);
var
  aKind : TExchangeKind;
  i : integer;
begin
  aKind := TExchangeKind((  Sender as TButton).Tag );
  i := 0;
  if aKind = ekBinance then i := 1;
  if App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i] <> nil  then
    App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i].DoConnect;
end;
procedure TFrmTest.btnBTDisconClick(Sender: TObject);
var
  aKind : TExchangeKind;
  i : integer;
begin
  aKind := TExchangeKind((  Sender as TButton).Tag );
  i := 0;
  if aKind = ekBinance then i := 1;
  if App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i] <> nil  then
    if App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i].GetSockState = 'Open' then
      App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i].DoDisConnect;
end;
procedure TFrmTest.btnBTSubClick(Sender: TObject);
var
  aKind : TExchangeKind;
  i : integer;
begin
  aKind := TExchangeKind((  Sender as TButton).Tag );
  i := 0;
  if aKind = ekBinance then i := 1;
  if App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i] <> nil  then
    App.Engine.ApiManager.ExManagers[aKind].QuoteSock[i].SubscribeAll;
end;
procedure TFrmTest.btnBTunsubClick(Sender: TObject);
begin
  if App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0] <> nil  then
  begin
//    App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0].reCreate;
//    App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0].DoConnect;
  end;
end;
procedure TFrmTest.Button6Click(Sender: TObject);
begin
  if App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[1] <> nil  then
    TBinanceWebSocket(App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[1]).UnSubScribeAll;
end;
procedure TFrmTest.Button7Click(Sender: TObject);
begin
  if App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[1] <> nil  then
    if App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[1].GetSockState = 'Open' then
      App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[1].DoDisConnect;
end;

procedure TFrmTest.Button8Click(Sender: TObject);
begin
  if App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[1] <> nil  then
//    if App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[mtFutures].GetSockState = 'Open' then
      App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[1].DoConnect;
end;

procedure TFrmTest.Button1Click(Sender: TObject);
var
  aKind : TExchangeKind;
  aSymbol : TSymbol;
  iRes : integer;
begin
  aKind := TExchangeKind( ComboBox1.ItemIndex );
  aSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( edtCode.Text, aKind );
  if aSymbol = nil then
  begin
    ShowMessage('종목없음');
    Exit;
  end;
//  aSymbol.DepositState    := not cbDpst.Checked;
//  aSymbol.WithDrawlState  := not cbWD.Checked;
//  iRes := 0;
//  if (cbDpst.Checked) and ( cbWD.Checked ) then
//    iRes := DNW_BOTH_FALE
//  else if cbDpst.Checked then
//    iRes := DWN_WITHDRAW_FALSE
//  else if cbWD.Checked then
//    iRes := DWN_DEPOSIT_FALSE;
//  if iRes > 0 then begin
//    if App.Engine.SymbolCore.SymbolDnwStates[ aKind ].FindCode( aSymbol.Code ) = nil then
//      App.Engine.SymbolCore.SymbolDnwStates[ aKind ].AddSymbol( aSymbol )
//    else
//      iRes := 0;
//  end
//  else if iRes = 0 then
//    App.Engine.SymbolCore.SymbolDnwStates[ aKind ].DeleteSymbol( aSymbol );
  iRes := aSymbol.CheckDnwState( not cbDpst.Checked, not cbWD.Checked  )  ;
  if iRes > 0  then
    App.Engine.SymbolBroker.DnwEvent( aSymbol, iRes);
end;
procedure TFrmTest.Button2Click(Sender: TObject);
begin
  case ( Sender as TComponent).Tag of
    0 : mKip.Clear;
    1 : mWcd.Clear;
  end;
end;

procedure TFrmTest.cbBTClick(Sender: TObject);
begin
  case (Sender as TCheckBox).Tag of
    2 : plBT.Visible  := cbBT.Checked;
    1 : plUp.Visible  := cbUp.Checked;
    0 : panel3.Visible:= cbBn.Checked;
    3 : panel4.Visible:= CheckBox1.Checked;
  end;
end;
procedure TFrmTest.CheckBox4Click(Sender: TObject);
var
  aKind : TExchangeKind;
  aSymbol : TSymbol;
  iTag : integer;
  bCheck : boolean;
begin
  bCheck  := ( Sender as TCheckBox).Checked;
  iTag    := ( Sender as TCheckBox).Tag;
  if not bCheck then
  begin
    case iTag of
     0 :   kiptimer.Enabled := false;
     1 :   wcdTimer.Enabled := false;
    end;
    Exit;
  end;
  case iTag of
   0 :
    begin
       aKind := TExchangeKind( ComboBox3.ItemIndex + 1 );
       aSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( Edit2.Text, aKind );
    end;
   1 :
    begin
       aKind := TExchangeKind( ComboBox2.ItemIndex + 1 );
       aSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( Edit1.Text, aKind );
    end;
  end;
  if aSymbol = nil then
  begin
    ShowMessage('종목없음');
    Exit;
  end;
  case iTag of
   0 :
    begin
      Symbol1  := aSymbol;
      LastCnt1 := aSymbol.DataTrace.Kip.Cnt;
      kipLog;
      kipTimer.Enabled := bCheck;
    end;
   1 :
    begin
      Symbol2  := aSymbol;
      LastCnt2 := aSymbol.DataTrace.Wcd.Cnt;
      wcdLog;
      wcdTimer.Enabled := bCheck;
    end;
  end;

end;
procedure TFrmTest.kipLog;
var
  sTmp : string;
  data : TKipTrace;
begin
  if Symbol1 <> nil then
  begin
    data := Symbol1.DataTrace.Kip;
    sTmp := Format('%s : %s %% = %s, %s, %s', [ FormatDateTime('hh:nn:ss',  data.LastTime)
      , FmtString( 2, data.Kip ),  Symbol1.PriceToStr( data.CurPrice ), FmtString( 6, data.OsPrice )
      , FmtString( 1, data.ExRate ) ]);
    mKip.Lines.Insert(0, sTmp );
    LastCnt1 := Symbol1.DataTrace.Kip.Cnt;
  end;
end;
procedure TFrmTest.wcdLog;
var
  sTmp : string;
  data : TWCDTrace;
begin
  if Symbol2 <> nil then
  begin
    data := Symbol2.DataTrace.Wcd;
    sTmp := Format('%s : %s = %s, %s', [ FormatDateTime('hh:nn:ss',  data.LastTime)
      , FmtString( 1, data.Wcd ),  Symbol2.PriceToStr( data.CurPrice ), FmtString( 6, data.OsPrice )  ]);
    mWcd.Lines.Insert(0, sTmp );
    LastCnt2 := Symbol2.DataTrace.Wcd.Cnt;
  end;
end;
procedure TFrmTest.wcdTimerTimer(Sender: TObject);
begin
  if Symbol2 = nil then Exit;
  if Symbol2.DataTrace.Wcd.Cnt = LastCnt2 then Exit;
  wcdLog;
end;
procedure TFrmTest.wsTimerTimer(Sender: TObject);
begin
  if ( App.Engine.ApiManager.ExManagers[ekUpbit] = nil ) then Exit;
  if ( App.Engine.ApiManager.ExManagers[ekUpbit].QuoteSock = nil ) then Exit;

  if App.Engine.ApiManager.ExManagers[ekUpbit].QuoteSock[0] <> nil  then
    lbUp.Caption  := Format('%s : %d (%s)', [ App.Engine.ApiManager.ExManagers[ekUpbit].QuoteSock[0].GetSockState,
       App.Engine.ApiManager.ExManagers[ekUpbit].QuoteSock[0].RcvCnt,
       App.Engine.ApiManager.ExManagers[ekUpbit].SndRcvCnt  ] );

  if App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0] <> nil  then
    lbBT.Caption  := Format('%s : %d (%s)', [ App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0].GetSockState,
       App.Engine.ApiManager.ExManagers[ekBithumb].QuoteSock[0].RcvCnt,
       App.Engine.ApiManager.ExManagers[ekBithumb].SndRcvCnt  ] );

  if App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[0] <> nil  then
    lbBN.Caption  := Format('%s : %d (%s)', [ App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[0].GetSockState,
       App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[0].RcvCnt,
       App.Engine.ApiManager.ExManagers[ekBinance].SndRcvCnt  ] );

  if App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[1] <> nil  then
    Label4.Caption  := Format('%s : %d (%s)', [ App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[1].GetSockState,
       App.Engine.ApiManager.ExManagers[ekBinance].QuoteSock[1].RcvCnt,
       App.Engine.ApiManager.ExManagers[ekBinance].SndRcvCnt  ] );

//  if App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[mtFutures] <> nil  then
//    Label4.Caption  := Format('%s : %d', [ App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[mtFutures].GetSockState,
//       App.Engine.ApiManager.ExManagers[ekBinance].TradeSock[mtFutures].RcvCnt ] );
end;

procedure TFrmTest.FormCreate(Sender: TObject);
begin
  Symbol1 := nil;
  Symbol2 := nil;
//  cbBT.Checked := true;
//  cbUp.Checked := true;
//  cbBn.Checked := true;
end;
procedure TFrmTest.kipTimerTimer(Sender: TObject);
begin
  if Symbol1 = nil then Exit;
  if Symbol1.DataTrace.Kip.Cnt = LastCnt1 then Exit;
  kipLog;
end;
end.
