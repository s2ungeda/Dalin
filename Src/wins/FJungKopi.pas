unit FJungKopi;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs
  , UStorage, Vcl.Grids, Vcl.ExtCtrls
  , UTypes
  , UApiTypes
  ;
const
  TimeRow = 7;
  SecondRow = 4;
  IncRow = 2;

type
  TFrmJungKopi = class(TForm)
    sgVal: TStringGrid;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure sgValDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
  private
    { Private declarations }
    FPrecision : integer;
    FCol, FRow : integer;
    FLastIdx   : integer;
    FData     : array [ TExchangeKind ] of double;
    FData2    : double ;    // 환율
    FCount    : integer;
    procedure initData;
  public
    { Public declarations }
    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );
  end;
var
  FrmJungKopi: TFrmJungKopi;
implementation
uses
  GApp  , GLibs , UConsts
  , Math
  , UOtherData
  , UTableConsts
  ;
{$R *.dfm}
{ TFrmJungKopi }
procedure TFrmJungKopi.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := false;
  Action := caFree;
end;
procedure TFrmJungKopi.FormCreate(Sender: TObject);
var
  I, iMod: Integer;
  s : string;
begin
  with sgVal do
    for I := 0 to ColCount-1 do
    begin
      if i = 0 then
        ColWidths[i] := 60
      else
        ColWidths[i] := RPSNT_COL_WID;
      if i > 0  then  begin
        iMod := i Mod 2;
        if iMod = 0 then
          s := '30'
        else
          s := '00';
        Cells[i, 0 ]  := Format('%d:%s', [ (i-1) div 2, s] );
        Cells[i, TimeRow ] := Format('%d:%s', [ (i-1) div 2 + 12, s ]);
//        cells[i,1]    := intToStr( i-1 );
//        cells[i,3]    := intToStr( (i-1)+24 );
      end;
    end;
  with sgVal do
  begin
    Cells[0,0]  := '거래소';
    Cells[0,1]  := 'Upbit';
    Cells[0,3]  := '환율';
    Cells[0,2]  := 'Bithumb';
    Cells[0,TimeRow]  := 'RealTime';
  end;
  FCol  := -1;
  FRow  := -1;
  FLastIdx  := -1;
  sgVal.Canvas.Font.Name := 'Arial';
  sgVal.Canvas.Font.Size := 9;
  FPrecision:= App.GetPrecision;

  FCount := 590;
  initData;
end;
procedure TFrmJungKopi.FormDestroy(Sender: TObject);
begin
  //
end;
procedure TFrmJungKopi.LoadEnv(aStorage: TStorage);
begin
end;
procedure TFrmJungKopi.SaveEnv(aStorage: TStorage);
begin
end;
procedure TFrmJungKopi.initData;
var
  aWcd : TWCDData;
  I, j, iCol, iRow: Integer;
  dPrev : array [TExchangeKind] of double;
  dVal : double;
begin

  Exit;

  with sgVal, App.Engine.SymbolCore do
    for i := 0 to JKIdx[ekUpbit] do
    begin
      iRow := 1;
      iCol := i + 1;
      if i > 23 then begin
        iRow := SecondRow;
        iCol := i - 24 + 1;
      end;
      Cells[iCol,iRow]  := FmtString(FPrecision, JungKopi[ekUpbit][i] );
      Cells[iCol,iRow+1]:= FmtString(FPrecision, JungKopi[ekBithumb][i] ) ;
      Cells[iCol,iRow+2]:= FmtString(1, App.Engine.ApiManager.ExRate.Value ) ;
      if i = 0  then
      begin
        SetColor( 0, sgVal, iCol, iRow );
        SetColor( 0, sgVal, iCol, iRow + 1 );
      end else
      begin
        SetColor( JungKopi[ekUpbit][i] - dPrev[ekUpbit], sgVal, iCol, iRow );
        SetColor( JungKopi[ekBithumb][i] - dPrev[ekBithumb], sgVal, iCol, iRow+1 );
      end;
      dPrev[ekUpbit]  := JungKopi[ekUpbit][i];
      dPrev[ekBithumb]:= JungKopi[ekBithumb][i];
    end;

end;
procedure TFrmJungKopi.sgValDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    stTxt : string;
    aBack , aFont : TColor;
    aRect : TRect;
    dFormat : word;
    dTmp : double;
begin
  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;
  with sgVal do
  begin
    stTxt := Cells[ ACol, ARow];
    if (ARow = 0 ) or  ( ARow = RowCount-1 ) then
    begin
      aBack := clBtnFace;
      if (ACol = FCol) and ((( FRow-1 ) = ARow) or ((FRow+3)=ARow)) then
      begin
        aBack := clBlack;
        aFont := clWhite;
      end;
    end else
    begin
//      if (ACol = 0 ) and ( ARow in [3..4] ) then
//        aFont := GetColor( StrToFloatDef( stTxt, 0 ) )  ;
      if Objects[ACol, ARow] <> nil  then
      begin
        aBack := GetColor( 0, Integer( Objects[ACol, ARow] ));
        aFont := GetColor( 1, Integer( Objects[ACol, ARow] )); //clWhite;
        if (ACol = 1) and (( ARow = 1) or (ARow = 2))  then
          aFont := clBlack;
        // 현재가 표시 부분..
        if (( ACol = FCol ) and ( ARow in [ FRow..FRow+1])) or
         ((ACol = 0 ) and ( ARow in [4..5] ) ) then
        begin
//          aFont := GetColor( 2, Integer( Objects[ACol, ARow] ));
//          aBack := clWhite;
          aBack := GetColor( 0, Integer( Objects[ACol, ARow] ));
          aFont := GetColor( 1, Integer( Objects[ACol, ARow] )); //clWhite;
        end;
      end ;
    end;
    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;
    aRect.Top := Rect.Top + 4;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );
    if ( ARow = 0 ) or  ( ARow = RowCount-1 ) then begin
      Canvas.Pen.Color := clBlack;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Right, Rect.Bottom),
                       Point(Rect.Right, Rect.Top)]);
      Canvas.Pen.Color := clWhite;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Left,  Rect.Top),
                       Point(Rect.Right, Rect.Top)]);
    end;
  end;
end;

procedure TFrmJungKopi.Timer1Timer(Sender: TObject);
var
  iCol, idx  : integer;
begin

  if App.Stop then Exit;


  FData[ ekUpbit ]   := App.Engine.SymbolCore.MainKimp[ekUpbit];
  FData[ ekBithumb ] := App.Engine.SymbolCore.MainKimp[ekBithumb];
  FData2             := App.Engine.ApiManager.ExRate.Value;

  inc( FCount );

  if FCount mod 600 = 0 then
  begin
    App.Log(llInfo, 'Index_Kip', ' %s , %.2f, %.2f, %.1f ', [
      FormatDatetime('yyyy-mm-dd hh:nn', now),  FData[ ekUpbit ],  FData[ ekBithumb ]  , FData2
    ]  );
    FCount :=0;
  end;

  if IsZero(  FData[ ekUpbit ] )       or IsZero( FData[ ekBithumb ] ) then Exit;

  with sgVal do
  begin
    Cells[0, 4] := FmtString( FPrecision, FData[ekUpbit]);
    Cells[0, 5] := FmtString( FPrecision, FData[ekBithumb]);
    Cells[0, 6] := FmtString( 1, FData2);


    with App.Engine.SymbolCore do
      iCol := JKIdx[ekUpbit];
    FRow := 1;
    FCol := iCol + 1;
    if iCol > 23 then begin
      FRow := SecondRow;
      FCol := iCol - 24 + 1;
    end;

    Cells[FCol, FRow]   := FmtString( FPrecision, FData[ekUpbit]);
    Cells[FCol, FRow+1] := FmtString( FPrecision, FData[ekBithumb]);
    Cells[FCol, FRow+2] := FmtString( 1, FData2);


    if ( FCol = 1 ) and ( FRow = 1 ) then
    begin
      SetColor( 0, sgVal, iCol, FRow );
      SetColor( 0, sgVal, iCol, FRow + 1 );
    end   ;

    idx := Max( 0, iCol -1 );
    SetColor( FData[ ekUpbit ]    - App.Engine.SymbolCore.JungKopi[ekUpbit][idx],  sgVal, FCol, FRow );
    SetColor( FData[ ekBithumb ]  - App.Engine.SymbolCore.JungKopi[ekBithumb][idx],  sgVal, FCol, FRow+1 );

    Objects[0,4] := Objects[ FCol, FRow];
    Objects[0,5] := Objects[ FCol, FRow+1];
    if FLastIdx <> FCol then
    begin
      FLastIdx := FCol;
      Invalidate;
    end;
  end;
end;
end.
