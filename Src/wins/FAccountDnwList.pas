unit FAccountDnwList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Generics.Collections,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls, REST.Client, REST.Types,

  UApiTypes, Utypes, URequestPools
  ;

const
  dnwListCnt = 6;
  sndListCnt = 7;
  dnwListTitle : array [0..dnwListCnt-1] of string = ('No','거래소', 'Time', '구분', '금액','수수료');
  dnwListWidths: array [0..dnwListCnt-1] of integer = (30, 60, 90, 40, 120, 100);

  sndListTitle : array [0..sndListCnt-1] of string = ('No','거래소', '코인', 'Time', '구분', '수량', '수수료');
  sndListWidths: array [0..sndListCnt-1] of integer = (30, 60, 50, 90, 40, 120, 100);

  UKD = 0;   // upbit krw deposit;
  UKW = 1;   // upbit krw withdraw;
  BKD = 2;
  BKW = 3;

  UCW = 0;   // upbit coin withdraw
  BCW = 1;   // bithumb coin withdraw;

  ViewCnt = 30;

type

  TRequestDnwList = class(TRequestTask)
  private
    FIsDnw: boolean;
    FExKind: TExchangeKind;
    FOnResNotify: TTextNotifyEvent;
    FIsDone: boolean;
    FDnwArray: TArray<TCoinDnwItem>;
    procedure MakeRequestBithumb;
    procedure MakeRequestUpbit;
  public
    constructor Create(ARequestID: Integer; bDnw: boolean; aExKind: TExchangeKind); overload;
    destructor  Destroy; override;
    procedure MakeRequest; override;
    procedure OnAysncCompleted(Sender: TCustomRESTRequest); override;

    property OnResNotify : TTextNotifyEvent read FOnResNotify write FOnResNotify;
    property IsDnw: boolean read FIsDnw;
    property ExKind: TExchangeKind read FExKind ;
    property IsDone: boolean read FIsDone write FIsDone;
    property DnwArray : TArray<TCoinDnwItem> read FDnwArray write FDnwArray;
  end;

  TFrmAccountDnwList = class(TForm)
    Panel1: TPanel;
    stBar: TStatusBar;
    sg: TStringGrid;
    Button1: TButton;
    Timer1: TTimer;
    btnNext: TButton;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure sgDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure sgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnNextClick(Sender: TObject);

  private
    { Private declarations }
    FIndex : integer;
    FPage  : integer;
    FIsDnw : boolean;
    FCount : integer;
    FRow   : integer;
    FTask : array of TRequestDnwList;
    FDnwArray: TArray<TCoinDnwItem>;
    FDoneEvent: TIntNotifyEVent;
    procedure RequestList;
    procedure MakeTask(iCnt: integer);
    procedure ResCompleted(aTask : TRequestTask);
    procedure ResNotify(Sender: TObject; Value: String);
    procedure DoLog(stLog : string);
    procedure MergeDnwList;
  public
    { Public declarations }
    //function Open(bDnw: boolean; var aList : TList) : boolean;
    property  DnwArray : TArray<TCoinDnwItem> read FDnwArray;
    procedure Init(bDnw: boolean; aProc: TIntNotifyEVent);
    procedure UpdateData;

    property OnDoneEvent: TIntNotifyEVent read FDoneEvent write FDoneEvent;
  end;

var
  FrmAccountDnwList: TFrmAccountDnwList;

implementation

uses
  GApp, GLibs
  , UUpbitSpot, UBithSpot, UUpbitManager, UBithManager
  , UDecimalHelper
  , System.Generics.Defaults, Math

  ;

{$R *.dfm}

procedure TFrmAccountDnwList.btnNextClick(Sender: TObject);
begin
  //(FPage + 1) * ViewCnt, Length(DnwArray) - (sgRowCount -1)
  inc(FPage);
  UpdateData;
end;

procedure TFrmAccountDnwList.Button1Click(Sender: TObject);
begin
  Button1.Enabled := false;
  Timer1.Enabled := true;
  FCount := 0;
  FIndex := 0;
  FPage  := 1;
  sg.RowCount := 1;
  btnNext.Enabled := true;

  RequestList;
end;

procedure TFrmAccountDnwList.DoLog(stLog: string);
begin
  stBar.Panels[0].Text := FormatDateTime('hh:nn:ss', now);
  stBar.Panels[1].Text := stLog;
end;

procedure TFrmAccountDnwList.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  //
  Action := caHide;
end;

procedure TFrmAccountDnwList.FormCreate(Sender: TObject);
begin
  sg.RowCount := 1;
  FCount := 0;
  FTask := nil;
  FRow  := -1;
end;

procedure TFrmAccountDnwList.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  //
  if FTask <> nil then
    for I := 0 to High(FTask) do
      FTask[i].Free;

  SetLength(FTask, 0);
  FTask := nil;
end;

procedure TFrmAccountDnwList.Init(bDnw: boolean; aProc: TIntNotifyEVent);
var
  I, iSum: integer;
begin
  FIsDnw  := bDnw;
  iSum    := 0;

  FDoneEvent  := aProc;

  with sg do
    if FIsDnw then
    begin
      Caption   := '국내 원화입출금리스트';
      Panel1.Caption := '100개씩 최대400개, 완료된것만';
      ColCount  := dnwListCnt;
      for I := 0 to dnwListCnt-1 do
      begin
        Cells[i, 0] :=  dnwListTitle[i];
        ColWidths[i]:=  dnwListWidths[i];
        iSum := iSum + dnwListWidths[i];
      end;
      MakeTask(4);

    end else
    begin
      Caption   := '국내 코인전송리스트';
      Panel1.Caption := '각 100개씩 최대 200개, 완료된것만';
      ColCount  := sndListCnt;
      for I := 0 to sndListCnt-1 do
      begin
        Cells[i, 0] :=  sndListTitle[i];
        ColWidths[i]:=  sndListWidths[i];
        iSum := iSum + sndListWidths[i];
      end;
      MakeTask(2);
    end;

  Width := iSum + (sg.ColCount * 2) + 32;
end;

procedure TFrmAccountDnwList.MakeTask(iCnt: integer);
var
  I: Integer;
  aExKind: TExchangeKind;
begin
  SetLength(FTask, iCnt);
  for I := 0 to iCnt-1 do
  begin

    if FIsDnw and (i <= 1) then
      aExKind := ekUpbit
    else if FIsDnw and (i > 1) then
      aExKind := ekBithumb
    else if (not FIsDnw) and (i = 0) then
      aExKind := ekUpbit
    else if (not FIsDnw) and (i = 1) then
      aExKind := ekBithumb;

    FTask[i]  := TRequestDnwList.Create(i, FIsDnw, aExKind);
    FTask[i].OnCompleted := ResCompleted;
    FTask[i].OnResNotify := ResNotify;
  end;
end;

procedure TFrmAccountDnwList.MergeDnwList;
var
  i, out, len: Integer;
begin


  len := 0;
  for i := 0 to High(FTask) do
    len := len + Length(FTask[i].DnwArray);
  SetLength(FDnwArray, len);
  out := 0;
  for i := 0 to High(FTask) do
  begin
    len := Length(FTask[i].DnwArray);
    if len > 0 then
    begin
      TArray.Copy<TCoinDnwItem>(FTask[i].DnwArray, FDnwArray, 0, out, len);
      Inc(out, len);
    end;
  end;

  TArray.Sort<TCoinDnwItem>(FDnwArray, TComparer<TCoinDnwItem>.Construct(
    function(const Item1, Item2 : TCoinDnwItem) : integer
    begin
      Result := CompareDoubleInc(Item1.time, Item2.time);
    end
  ));

//  for I := 0 to High(FDnwArray) do
//  begin
//    App.Log(llDebug, '%d:%s, %s, %s, %s', [i, FormatDateTime('mm-dd hh:nn:ss', FDnwArray[i].time),
//      FDnwArray[i].code, FDnwArray[i].gubun, FDnwArray[i].qty] );
//  end;

end;

procedure TFrmAccountDnwList.RequestList;
var
  I: Integer;
begin
  for I := 0 to High(FTask) do begin
    FTAsk[i].IsDone := false;
    FTask[i].Execute(true);
  end;
end;

procedure TFrmAccountDnwList.ResCompleted(aTask: TRequestTask);
var
  i : integer;
begin
  //
  if aTask = nil then Exit;

  TRequestDnwList(aTask).IsDone := true;

  for I := 0 to High(FTask) do
    if not FTAsk[i].IsDone then Exit;

  MergeDnwList;

  UpdateData;

  Timer1.Enabled := false;
  Button1.Enabled:= true;
  DoLog('조회 완료');

  if Assigned(FDoneEvent) then
    FDoneEvent(Self, 1);
end;

procedure TFrmAccountDnwList.ResNotify(Sender: TObject; Value: String);
begin
  DoLog(Value);
end;

procedure TFrmAccountDnwList.sgDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    sTxt: string;
    clFont, clBack: TColor;
    dFormat: DWORD;
    rRect: TRect;
begin
  clFont:= clBlack;
  clBack:= clWhite;
  dFormat:= DT_CENTER;
  rRect  := Rect;
  with (Sender as TStringGrid) do
  begin
    sTxt := Cells[ACol, ARow];
    if ARow = 0 then
    begin
      dFormat := dFormat or DT_CENTER;
      clBack  := clBtnFace;
    end else
    begin
//      if (ARow mod 2 = 0) then
//        clBack := clSilver;

      if (FIsDnw and (ACol in [1, 4, 5])) or
        ((not FIsDnw) and (ACol in [1, 5, 6])) then
        dFormat := DT_RIGHT;

      if FIsDnw and (ACol = 3) then
        if sTxt = '출금' then
          clFont := clBlue
        else
          clFont := clRed;        

      if ARow = FRow then       
        clBack := $00F2BEB9;
            
    end;

    Canvas.Font.Color   := clFont;
    Canvas.Brush.Color  := clBack;
    rRect.Top := Rect.Top + 2;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      rRect.Right := rRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( sTxt ), Length( sTxt ), rRect, dFormat );    
  end;
end;

procedure TFrmAccountDnwList.sgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    aCol : integer;
 
begin
  //
  sg.MouseToCell( X, Y, aCol, FRow);   
  sg.Repaint;    
end;

procedure TFrmAccountDnwList.Timer1Timer(Sender: TObject);
begin

  try
    if Button1.Enabled then
      Timer1.Enabled := false
    else begin
      if FCount >= 3 then
      begin
        Timer1.Enabled := false;
        Button1.Enabled:= true;
      end;
    end;

  finally
    inc(FCount);
  end;

end;

procedure TFrmAccountDnwList.UpdateData;
var
  iViewCnt, iRow, I, j: integer;
  bInt: TDecimalHelper;
begin

//  iNcRow := Min(FPage * ViewCnt

  with sg do
  begin
//
//    iViewCnt := Length(DnwArray) div (ViewCnt * FPage);
//    if iViewCnt <= 0 then
//      iViewCnt := Length(DnwArray) - (ViewCnt * (FPage -1))
//    else
//      iViewCnt := ViewCnt;
//
//    RowCount := RowCount + iViewCnt;// Length(FDnwArray) + 1;

    //for I := 0 to High(FDnwArray) do
    j := 0;
    for I := FIndex to High(FDnwArray) do
    begin
      FIndex := i;
      iRow := i+1;
      RowCount := RowCount + 1;
      Cells[0, iRow]  := iRow.ToString;
      Cells[0+1, iRow] := FDnwArray[i].exchange;

      if FIsDnw then
      begin
        Cells[1+1, iRow] := FormatDateTime('mm-dd hh:nn:ss', FDnwArray[i].time);
        Cells[2+1, iRow] := FDnwArray[i].gubun;
        Cells[3+1, iRow] := bInt.AddComma(FDnwArray[i].qty);
        Cells[4+1, iRow] := FDnwArray[i].fee;
      end else
      begin
        Cells[1+1, iRow] := FDnwArray[i].code;
        Cells[2+1, iRow] := FormatDateTime('mm-dd hh:nn:ss', FDnwArray[i].time);
        Cells[3+1, iRow] := FDnwArray[i].gubun;
        Cells[4+1, iRow] := bInt.AddComma(FDnwArray[i].qty);
        Cells[5+1, iRow] := FDnwArray[i].fee;
      end;

      inc(j);
      if j >=  ViewCnt then
        break;
    end;

    if FIndex >=  High(DnwArray) then
      btnNext.Enabled := false;

    if RowCount > 1 then
      FixedRows := 1;
  end;
end;

{ TRequestDnwList }

constructor TRequestDnwList.Create(ARequestID: Integer; bDnw: boolean; aExKind: TExchangeKind);
begin
  inherited Create(ARequestID, nil);
  FIsDnw := bDnw;
  FExKind:= aExKind;

  BaseUrl := App.Engine.ApiConfig.GetBaseUrl(FExKind, eaSpot);
end;

destructor TRequestDnwList.Destroy;
begin
  SetLength(FDnwArray, 0);
  FDnwArray  := nil;
  inherited;
end;

procedure TRequestDnwList.MakeRequest;
begin
  SetLength(FDnwArray, 0);
  case FExKind of
    ekUpbit : MakeRequestUpbit;
    ekBithumb: MakeRequestBithumb;
  end;
end;

procedure TRequestDnwList.MakeRequestUpbit;
var
  sVAl, sRrc: string;
begin
  if FIsDnw then
  begin
    sRrc := ifThenStr(RequestID = UKD, '/v1/deposits', '/v1/withdraws');
    sVal := format('currency=KRW&limit=100&state=%s',
      [ifThenStr(RequestID = UKD, 'ACCEPTED', 'DONE')]) ;
  end else
  begin
    sRrc := '/v1/withdraws';
    sVal := 'limit=100&state=DONE';
  end;

  RESTRequest.Resource := sRrc + '?' + sVal;
  RESTRequest.Method   := rmGET; //

  TUpbitSpot(App.Engine.ApiManager.ExManagers[ekUpbit].Exchanges[eaSpot]).GetSig(RESTRequest, sVal);

end;

procedure TRequestDnwList.MakeRequestBithumb;
var
  sTime, sVAl, sRrc: string;
begin
  if FIsDnw then
  begin
    sRrc := ifThenStr(RequestID = BKD, '/v1/deposits/krw', '/v1/withdraws/krw');
    sVal := format('limit=100&state=%s', [ifThenStr(RequestID = BKD, 'ACCEPTED', 'DONE')]) ;
  end else
  begin
    sRrc := '/v1/withdraws';
    sVal := 'limit=100&state=DONE';
  end;

  RESTRequest.Resource := sRrc+'?'+sVal;
  RESTRequest.Method   := rmGET; //

  TBithSpot(App.Engine.ApiManager.ExManagers[ekBithumb].Exchanges[eaSpot]).SetToken(RESTRequest, sVal);

end;

procedure TRequestDnwList.OnAysncCompleted(Sender: TCustomRESTRequest);
begin
  TThread.Queue(nil,
    procedure
    var
      OutJson, OutRes : string;
      bRes : boolean;
    begin

      try
        bRes := true;
        OutJson:= RESTRequest.Response.Content;
        if not (RESTRequest.Response.StatusCode in  [200..201]) then begin
          OutRes := Format( 'status : %d, %s', [ RESTRequest.Response.StatusCode, RESTRequest.Response.StatusText ] );
          bRes := false; 
          if Assigned(FOnResNotify) then
            FONResNotify(Self, Format('Request Failed : %s', [OutRes]));          
        end ;
      except
        on E: Exception do begin
          OutRes := E.Message;
          if Assigned(FOnResNotify) then
            FONResNotify(Self, Format('Request Exception : %s', [E.Message]));
        end;
      end;

      // 배열 초기화.
      SetLength(FDnwArray, 0);

      if FExKind = ekUpbit then
        TUpbitManager(App.Engine.ApiManager.ExManagers[ekUpbit]).Parse.ParseDnwList(OutJson, FDnwArray, FIsDnw)
      else
        TBithManager(App.Engine.ApiManager.ExManagers[ekBithumb]).Parse.ParseDnwList(OutJson, FDnwArray);

      App.DebugLog('req list: %s',[OutJson]);
      //TBithManager(App.Engine.ApiManager.ExManagers[ekBithumb]).Parse.ParseSpotOrderDetail(OutJson, FOrder.OrderNo);

      if Assigned(OnCompleted) then
        OnCompleted(Self);
    end);
end;

end.
