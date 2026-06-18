unit FAccountDnw;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.StdCtrls,

  UTypes, UApiTypes, UStorage, Vcl.WinXPickers
  ;

type

  TWonList = record
    time : TDateTime;
    amt  : double;
    row  : integer;
  end;

  TFrmAccountDnw = class(TForm)
    Panel1: TPanel;
    sg: TStringGrid;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure sgDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure sgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    FRow, FCount, FCount2: integer;
    FDnwConfig , FWonDnwList, FCoinDnwList : TForm;
    procedure InitControls;
  public
    { Public declarations }
    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );
    procedure OnRequestDone(Sender: TObject; Value: Integer);
  end;

var
  FrmAccountDnw: TFrmAccountDnw;

implementation

uses
  Gapp, GLibs, GAppForms,
  System.Generics.Collections, math,
  FAccountDnwList , FOrderLimit,  DalinMain
  ;

{$R *.dfm}

procedure TFrmAccountDnw.Button1Click(Sender: TObject);
begin

  FDnwConfig  := App.Engine.FormBroker.Open(ID_COMM_CONFIG, 0);
  if FDnwConfig = nil then Exit;

  TFrmOrderLimit(FDnwConfig).PageControl1.ActivePageIndex := 2;
  FDnwConfig.Left := Left + ClientWidth;
  FDnwConfig.Top  := Top + Button1.Top;
end;

procedure TFrmAccountDnw.Button2Click(Sender: TObject);
begin
  Button2.Enabled := false;
  Timer1.Enabled  := true;
  FCount := 0;

  if FWonDnwList = nil then begin
    FWonDnwList := TFrmAccountDnwList.Create(Self);
    TFrmAccountDnwList(FWonDnwList).Init(true, OnRequestDone);
  end;

  TFrmAccountDnwList(FWonDnwList).Button1Click(Button1);
  FWonDnwList.Show;
end;

procedure TFrmAccountDnw.Button3Click(Sender: TObject);
begin

  Button3.Enabled := false;
  Timer2.Enabled  := true;
  Fcount2 := 0;

  if FCoinDnwList = nil then begin
    FCoinDnwList  := TFrmAccountDnwList.Create(Self);
    TFrmAccountDnwList(FCoinDnwList).Init(false, nil);
  end;

  TFrmAccountDnwList(FCoinDnwList).Button1Click(Button1);
  FCoinDnwList.Show;
end;

procedure TFrmAccountDnw.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmAccountDnw.FormCreate(Sender: TObject);
begin
  InitControls;
end;

procedure TFrmAccountDnw.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TFrmAccountDnw.InitControls;
begin
  with sg do
  begin
    Cells[0,0] := '빗썸/업비트';
    Cells[1,0] := '입금';
    Cells[2,0] := '출금';
    Cells[3,0] := '입금';
    Cells[4,0] := '출금';

    Cells[0,1] := '원화입출가능';

    Cells[0,2] := '24시간출금가능';
    Cells[1,2] := '입금금액';
    Cells[2,2] := '누적출금가능';
    Cells[3,2] := '입금금액';
    Cells[4,2] := '누적출금가능';
  end;

  FDnwConfig  := nil;
  FWonDnwList := nil;
  FCoinDnwList:= nil;
end;

procedure TFrmAccountDnw.LoadEnv(aStorage: TStorage);
begin

end;

const ww = 100000000;
procedure TFrmAccountDnw.OnRequestDone(Sender: TObject; Value: Integer);
var
  prevTime, bkTime : TDateTime;
  iCol, i, j, iRow, iMax : Integer;
  dWon : double;
  aItem : TCoinDnwItem;
  won: array [0..4] of TList<TWonList>;
  dSums: array [0..4] of double;
  dAccs: array [0..3] of double;
  wl : TWonList;
begin

  bkTime   := incDay(now, -1);
  prevTime := Date + EncodeTime(0, 0, 0, 0);

  iMax := 0;  iRow := 3;
  sg.RowCount := 3;
  for I := 1 to High(dSums) do
  begin
    dSums[i]  := 0;
    if i<=3 then  dAccs[i]  := 0;
    won[i]    := TList<TWonList>.Create;
  end;

  try

    for I := 0 to High(TFrmAccountDnwList(FWonDnwList).DnwArray) do
    begin
      aItem := TFrmAccountDnwList(FWonDnwList).DnwArray[i];

      if aItem.time < bkTime then
        break;

      iCol := 0;
      case aItem.exKind of
        ekUpbit:
          if aITem.gubun = '입금' then
            iCol := 3
          else
            iCol := 4;
        ekBithumb:
          if aITem.gubun = '입금' then
            iCol := 1
          else
            iCol := 2;
      end;

      dWon  :=  StrToFloat(aItem.qty);
      if iCol in [1, 3] then begin
        sg.RowCount := sg.RowCount + 1;
        sg.Cells[0, iRow]     := FormatDateTime('mm-dd hh:nn:ss', aItem.time);
        sg.Cells[iCol, iRow]  := Format('%.0n', [dWon]);

  //      New(wl);
  //      wl^.time := aItem.time;
  //      wl^.amt  := dWon;
  //      wl^.row  := iRow;
  //      won[iCol].Add(wl);
  //      포인터 대신 제네릭을 사용하자

        wl.time := aItem.time;
        wl.amt  := dWon;
        wl.row  := iRow;
        won[iCol].Add(wl);

        inc(iRow);
      end;

      if aItem.time >= prevTime then
        dSums[iCol] := dSums[iCol] + dWon;
    end;

    for I := 1 to High(won) do
      for j := won[i].Count-1 downto 0 do
      begin
        wl := won[i].Items[j];
        dAccs[i] := dAccs[i] + wl.amt;
        if j < won[i].Count-1 then
          sg.Cells[i+1, wl.row] := Format('%.0n', [dAccs[i]]);
      end;

    with sg, App.Engine.ApiConfig.DnwLimit do
    begin
      if RowCount > 3 then
        FixedRows  := 3;

      Cells[1, 1] := Format('%.0n', [max(0, DepositLimit[ekBithumb] * ww - dSums[1])]);
      Cells[2, 1] := Format('%.0n', [max(0, WidthDrawLimit[ekBithumb] * ww - dSums[2])]);
      Cells[3, 1] := Format('%.0n', [max(0, DepositLimit[ekUpbit] * ww - dSums[3])]);
      Cells[4, 1] := Format('%.0n', [max(0, WidthDrawLimit[ekUpbit] * ww - dSums[4])]);
    end;

//  for I := 1 to High(won) do
//    for var idx in won[i] do
//      dispose(idx);

  finally
    for I := 1 to High(won) do
      won[i].Free;
  end;
end;

procedure TFrmAccountDnw.SaveEnv(aStorage: TStorage);
begin

end;

procedure TFrmAccountDnw.sgDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
  var
  	aRect : TRect;
    aFont, aBack : TColor;
    dFormat	: WORD;
    stTxt	: string;
begin

  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;

	with Sender as TStringGrid do
  begin
  	stTxt := Cells[ ACol, ARow];

    if (ARow in [0,2]) or (ACol = 0) then begin

      aBack := clBtnFace;
//      if Tag in [1..4] then begin
//        aBack := clGray;
//        aFont := clWhite;
//      end
//      else
//        aBack := clSilver;


    end
    else begin
      if ACol <> 0 then
        dFormat := DT_RIGHT;

      if ARow = FRow then
        aBAck := $00F2BEB9;
    end;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;
    aRect.Top := Rect.Top + 2;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );
  end;
end;

procedure TFrmAccountDnw.sgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var aCol : integer;
begin
  sg.MouseToCell(X, Y, ACol, FRow);
  sg.Repaint;
end;

procedure TFrmAccountDnw.Timer1Timer(Sender: TObject);
begin
  try
    if Button2.Enabled then
      Timer1.Enabled := false
    else begin
      if FCount >= 3 then
      begin
        Timer1.Enabled := false;
        Button2.Enabled:= true;
      end;
    end;

  finally
    inc(FCount);
  end;
end;

procedure TFrmAccountDnw.Timer2Timer(Sender: TObject);
begin
  try
    if Button3.Enabled then
      Timer2.Enabled := false
    else begin
      if FCount2 >= 3 then
      begin
        Timer2.Enabled := false;
        Button3.Enabled:= true;
      end;
    end;

  finally
    inc(FCount2);
  end;

end;

end.
