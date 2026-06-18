unit FRepresentWDC;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ExtCtrls
  , UStorage , UApiTypes
  ;
type
  TFrmRprsntWDC = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    sgWDC2: TStringGrid;
    sgWDC1: TStringGrid;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sgWDC1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FPrecision : integer;
    FCol, FRow : integer;
    FLastIdx   : integer;
    FWCD     : array [ TExchangeKind ] of double;
  public
    { Public declarations }
    procedure initData;
    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );
  end;
var
  FrmRprsntWDC: TFrmRprsntWDC;
implementation
uses
  GApp  , GLibs , Math
  , UConsts
  , UOtherData
  , UTableConsts
  ;
{$R *.dfm}
{ TFrmRprsntWDC }
procedure TFrmRprsntWDC.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := false;
  Action := caFree;
end;
procedure TFrmRprsntWDC.FormCreate(Sender: TObject);
var
  I, iMod: Integer;
  s : string;
begin
  with sgWDC2 do
    for I := 0 to ColCount-1 do
    begin
      if i = 0 then begin
        ColWidths[i] := 60;
        sgWDC1.ColWidths[i] := 60;
      end
      else begin
        ColWidths[i] := RPSNT_COL_WID;
        sgWDC1.ColWidths[i] := RPSNT_COL_WID;
      end;
      if i > 0  then  begin
        iMod := i Mod 2;
        if iMod = 0 then
          s := '30'
        else
          s := '00';
        sgWDC1.Cells[i,0] := Format('T-%d',[ 25-i]);
        Cells[i, 0 ]  := Format('%d:%s', [ (i-1) div 2, s] );
        Cells[i, 5 ] := Format('%d:%s', [ (i-1) div 2 + 12, s ]);
      end;
    end;
  with sgWDC1 do
  begin
    Cells[0,1]  := 'Upbit';
    Cells[0,2]  := 'Bithumb';
  end;
  with sgWDC2 do
  begin
    Cells[0,0]  := '거래소';
    Cells[0,1]  := 'Upbit';
    Cells[0,2]  := 'Bithumb';
    Cells[0,5]  := 'RealTime';
  end;
  FCol  := -1;
  FRow  := -1;
  FLastIdx  := -1;
  sgWDC2.Canvas.Font.Name := 'Arial';
  sgWDC2.Canvas.Font.Size := 9;
  sgWDC1.Canvas.Font.Name := 'Arial';
  sgWDC1.Canvas.Font.Size := 9;
  FPrecision:= App.GetPrecision;
  initData;
end;
procedure TFrmRprsntWDC.initData;
var
  aWcd : TWCDData;
  I, j, iCol, iRow: Integer;
  dPrev : array [TExchangeKind] of double;

begin
  with sgWDC1 do
  for I := 0 to App.Engine.SymbolCore.WCDays.Count-1 do
  begin
    aWcd  := App.Engine.SymbolCore.WCDays.WCDs[i];
    Cells[ ColCount-1-I , 1] := FmtString( 1,  aWcd.RpsntWCD[ekUpbit] );
    Cells[ ColCount-1-I , 2] := FmtString( 1,  aWcd.RpsntWCD[ekBithumb] );
  end;
  j := 1;
  for I := App.Engine.SymbolCore.WCDays.Count-1 downto 0 do
  begin
    aWcd  := App.Engine.SymbolCore.WCDays.WCDs[i];
    if i < App.Engine.SymbolCore.WCDays.Count-1 then begin
      SetColor( aWcd.RpsntWCD[ekUpbit] - dPrev[ekUpbit], sgWDC1, j, 1 );
      SetColor( aWcd.RpsntWCD[ekBithumb] - dPrev[ekBithumb], sgWDC1, j, 2 );
//      sgWDC1.Cells[j, 0] := FmtString( 1, aWcd.RpsntWCD[ekUpbit] - dPrev[ekUpbit] );
    end ;
    sgWDC1.Cells[j, 0] := Format('%2.2d.%2.2d', [ aWcd.m, aWcd.d]);
    dPrev[ekUpbit]  := aWcd.RpsntWCD[ekUpbit];
    dPrev[ekBithumb]:= aWcd.RpsntWCD[ekBithumb];
    inc(j);
  end;

  with sgWDC2, App.Engine.SymbolCore do
    for i := 0 to WDCIdx[ekUpbit] do
    begin
      iRow := 1;
      iCol := i + 1;
      if i > 23 then begin
        iRow := 3;
        iCol := i - 24 + 1;
      end;
      Cells[iCol,iRow]  := FmtString(1, RprsntWDC[ekUpbit][i] );
      Cells[iCol,iRow+1]:= FmtString(1, RprsntWDC[ekBithumb][i] ) ;
      if i = 0  then
      begin
        if aWcd <> nil then begin
          SetColor( RprsntWDC[ekUpbit][i] - aWcd.RpsntWCD[ekUpbit] , sgWDC2, iCol, iRow );
          SetColor( RprsntWDC[ekBithumb][i] - aWcd.RpsntWCD[ekBithumb] , sgWDC2, iCol, iRow +1 );
        end  else
        begin
          SetColor( 0, sgWDC2, iCol, iRow );
          SetColor( 0, sgWDC2, iCol, iRow );
        end;
      end else
      begin
        SetColor( RprsntWDC[ekUpbit][i] - dPrev[ekUpbit], sgWDC2, iCol, iRow );
        SetColor( RprsntWDC[ekBithumb][i] - dPrev[ekBithumb], sgWDC2, iCol, iRow+1 );
      end;
      dPrev[ekUpbit]  := RprsntWDC[ekUpbit][i];
      dPrev[ekBithumb]:= RprsntWDC[ekBithumb][i];
    end;

end;
procedure TFrmRprsntWDC.LoadEnv(aStorage: TStorage);
begin
end;
procedure TFrmRprsntWDC.SaveEnv(aStorage: TStorage);
begin
end;

procedure TFrmRprsntWDC.sgWDC1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
    stTxt : string;
    aBack , aFont : TColor;
    aRect : TRect;
    dFormat : word;

    bPoly : boolean;
begin
  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;
  with Sender as TStringGrid do
  begin
    stTxt := Cells[ ACol, ARow];
    if (ARow = 0 )  then begin
      aBack := clBtnFace;
      if (Tag = 1) and ( ACol = FCol ) and ( ARow = FRow-1) then begin
        aBack := clBlack;
        aFont := clWhite;
      end;
    end
    else if  ( ARow = RowCount-1 ) and ( Tag = 1) then begin
      aBack := clBtnFace;
      if (ACol = FCol) and ( FRow+2=ARow) then
      begin
        aBack := clBlack;
        aFont := clWhite;
      end;
    end
    else  begin
      if Tag = 1 then begin
        if Objects[ACol, ARow] <> nil  then
        begin
          aBack := GetColor( 0, Integer( Objects[ACol, ARow] ));
          aFont := GetColor( 1, Integer( Objects[ACol, ARow] ));
          // 현재가 표시 부분..
          if (( ACol = FCol ) and ( ARow in [ FRow..FRow+1]))  or
            (( ACol = 0 ) and ( ARow in [3..4] ))  then
          begin
//            aFont := GetColor( 2, Integer( Objects[ACol, ARow] ));
//            aBack := clWhite;
            aBack := GetColor( 0, Integer( Objects[ACol, ARow] ));
            aFont := GetColor( 1, Integer( Objects[ACol, ARow] ));
          end;
        end ;
      end else
      if Tag = 0 then
      begin
        if Objects[ACol, ARow] <> nil  then
        begin
          aBack := GetColor( 0, Integer( Objects[ACol, ARow] ));
          aFont := GetColor( 1, Integer( Objects[ACol, ARow] ));
//          aFont := clWhite;
        end;
      end;
    end;
    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;
    aRect.Top := Rect.Top + 2;
    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );

    bPoly := false;
    if (( ARow = 0 ) or ( ARow = RowCount-1 )) and (Tag=1) then begin
      bPoly := true;
    end else
    if ( ARow = 0 ) and ( Tag = 0 ) then
      bPoly := true;
    if bPoly then
    begin
      Canvas.Pen.Color := clBlack;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Right, Rect.Bottom),
                       Point(Rect.Right, Rect.Top)]);
      Canvas.Pen.Color := clWhite;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Left,  Rect.Top),
                       Point(Rect.Right, Rect.Top)]);
    end;
    if (ARow = 2) and  ( Tag = 1 ) then
    begin
      Canvas.Pen.Color := clGray;
      Canvas.Pen.Width := 1;
      Canvas.Pen.Style := psSolid;
      Canvas.MoveTo( rect.left-1, rect.bottom );
      Canvas.Lineto( rect.right, rect.bottom );
    end;
  end;
end;
procedure TFrmRprsntWDC.Timer1Timer(Sender: TObject);
var
  iCol,  idx : integer;
begin

  if App.Stop then Exit;

  FWCD[ ekUpbit ]   := App.Engine.SymbolCore.MainWDC[ekUpbit];
  FWCD[ ekBithumb ] := App.Engine.SymbolCore.MainWDC[ekBithumb];
  if IsZero(  FWCD[ ekUpbit ] )       or IsZero( FWCD[ ekBithumb ] ) then Exit;
  with sgWDC2 do
  begin
    with App.Engine.SymbolCore do
      iCol := WDCIdx[ekUpbit];
    FRow := 1;
    FCol := iCol + 1;
    if iCol > 23 then begin
      FRow := 3;
      FCol := iCol - 24 + 1;
    end;
    Cells[0, 3] := Format('%.*n', [ 1, FWCD[ekUpbit] ]);
    Cells[0, 4] := Format('%.*n', [ 1, FWCD[ekBithumb] ]);
    Cells[FCol, FRow] := Format('%.*n', [ 1, FWCD[ekUpbit] ]);
    Cells[FCol, FRow+1] := Format('%.*n', [ 1, FWCD[ekBithumb] ]);
    idx := Max( 0, iCol -1 );
    SetColor( FWCD[ ekUpbit ] - App.Engine.SymbolCore.RprsntWDC[ekUpbit][idx],  sgWDC2, FCol, FRow );
    SetColor( FWCD[ ekBithumb ] - App.Engine.SymbolCore.RprsntWDC[ekBithumb][idx],  sgWDC2, FCol, FRow+1 );
    Objects[0,3] := Objects[ FCol, FRow];
    Objects[0,4] := Objects[ FCol, FRow+1];
    if FLastIdx <> FCol then
    begin
      FLastIdx := FCol;
      Invalidate;
    end;
  end;
end;
end.
