unit FQuoteMonitors;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.ComCtrls

  , UStorage, USymbols
  , UApiTypes, UDistributor, Vcl.Samples.Spin, Vcl.Menus
  , UTypes, Vcl.Mask
  ;

const
  ABLE_COL = 14;

type

  TFrmQuoteMonitors = class(TForm)
    StatusBar1: TStatusBar;
    plLeft: TPanel;
    plLeftTop: TPanel;
    plLeftClient: TPanel;
    sgQuote: TStringGrid;
    cbOSEx: TComboBox;
    cbKREx1: TComboBox;
    cbKREx2: TComboBox;
    plExRate: TPanel;
    Panel2: TPanel;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    cbUB: TCheckBox;
    cbBT: TCheckBox;
    Label1: TLabel;
    Button1: TButton;
    edtAmt: TEdit;
    Label2: TLabel;
    Timer1: TTimer;
    SpinButton1: TSpinButton;
    SpinButton2: TSpinButton;
    SpinButton3: TSpinButton;
    SpinButton4: TSpinButton;
    SpinButton6: TSpinButton;
    SpinButton7: TSpinButton;
    SpinButton8: TSpinButton;
    SpinButton9: TSpinButton;
    SpinButton10: TSpinButton;
    SpinButton11: TSpinButton;
    edtSec: TLabeledEdit;
    cbAuto: TCheckBox;
    dlgFont: TFontDialog;
    SpinButton5: TSpinButton;
    cbTradeAble: TCheckBox;
    SpinButton12: TSpinButton;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure sgQuoteDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure Button1Click(Sender: TObject);
    procedure cbUBClick(Sender: TObject);
    procedure edtAmtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SpinButton1DownClick(Sender: TObject);
    procedure SpinButton1UpClick(Sender: TObject);
    procedure edtSecKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbAutoClick(Sender: TObject);

    procedure cbKREx1Change(Sender: TObject);
    procedure sgQuoteMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure sgQuoteMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure sgQuoteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
  private
    FSubList: TList;
    FDataList: TList;
    FPrecision : integer;
    FShowSubEx : array [0..1] of TExchangeKind;
    FRow  : integer;
    FWinParam: TWinParam;
    { Private declarations }
    procedure initControls;
    function CheckFilter(aSymbol: TSymbol): boolean;
    procedure UpdateData(aSymbol: TSymbol; iRow: integer);
    procedure PutData(var iCol, iRow: integer; sData: string);
    procedure QuoteProc(Sender, Receiver: TObject; DataID: Integer;  DataObj: TObject; EventID: TDistributorID);
    procedure SortGrid(Grid: TStringGrid; SortCol: Integer; bAsc : boolean = true);
    procedure DefaultParam;
    procedure UpdateParam( bRefresh : boolean = true);

    function GetExchangeKind( iTag : integer ) : TExchangeKind;
  public
    { Public declarations }
    procedure RefreshData ;
    procedure SimpleRefreshData ;
    procedure MoreSimpleRefreshData ;

    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );

    property  SubList : TList read FSubList;
    property  DataList: TList read FDataList;

    property WinParam : TWinParam read FWinParam;
  end;

var
  FrmQuoteMonitors: TFrmQuoteMonitors;

implementation

uses
  GApp   , UTableConsts
  , UQuoteBroker  , USymbolUtils
  , UConsts, UApiConsts
  , GLibs
  ;

{$R *.dfm}

{ TFrmQuoteMonitors }

procedure TFrmQuoteMonitors.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmQuoteMonitors.FormCreate(Sender: TObject);
begin
  initControls;
  DefaultParam;
  UpdateParam( false );
  RefreshData;
end;

procedure TFrmQuoteMonitors.FormDestroy(Sender: TObject);
begin
  //
  FDataList.Free;
  FSubList.Free;
//  App.Engine.QuoteBroker.Cancel( self );
end;

procedure TFrmQuoteMonitors.FormResize(Sender: TObject);
begin
//  sgQuote.VisibleRowCount := sgQuote.rowc
end;

function TFrmQuoteMonitors.GetExchangeKind( iTag : integer ): TExchangeKind;
begin
  if iTag = 0 then
    REsult := TExchangeKind( cbKREx1.ItemIndex + 1 )
  else
    REsult := TExchangeKind( cbKREx2.ItemIndex + 1 );
end;

procedure TFrmQuoteMonitors.initControls;
var
  i, iSum : integer;
  iLeft : array [0..11] of integer;


begin

  iSum := 0;
  for I := 0 to quoteMon_TitleCnt - 1 do
  begin
    sgQuote.Cells[i,0] := quoteMon_Title[i];
    if i = 0 then
      sgQuote.RowHeights[i] := 20;
    sgQuote.ColWidths[i] :=  quoteMon_Width[i];
//    sgInOut.Cells[i,0]:= prcTbll1_Title[i];
    iSum := iSum +  quoteMon_Width[i] + 1;//(i*2);
//    if i <= (high(iLeft)-1) then
//      iLeft[i] := iSum;

//    if i <= high(iLeft) then
    if i <= 6 then
    begin
      iLeft[i] := iSum;
//      if i=2 then continue;
//      if ( i <= 1 ) then
//        iLeft[i] := iSum
//      else
//        iLeft[i-1] := iSum;
    end;

    case i of
    8  : iLeft[7] := iSum;
    13 : iLeft[8] := iSum;
    14 : iLeft[9] := iSum;
    15 : iLeft[10] := iSum;
    16 : iLeft[11] := iSum;
    end;

//    if i=11 then
//      iLeft[6] := iSum
//    else if i=14 then
//      iLeft[7] := iSum;

//    if i=10 then
//      iLeft[6] := iSum
//    else if i=13 then
//      iLeft[7] := iSum;

  end;
  sgQuote.RowCount := 1;
  sgQuote.RowHeights[0] := 22;
  App.Engine.SymbolCore.CommSymbols.SortByDailyAmount;
  FSubList := TList.Create;
  FDataList:= TList.Create;
  FPrecision  := App.GetPrecision;

  FRow  := -1;

  for i := ComponentCount-1 downto 0 do
    if Components[i] is TSpinButton then
    begin
      case Components[i].Tag of
       0 : (Components[i] as TSpinButton).Left := iLeft[0] - SpinButton1.Width;
       1 : (Components[i] as TSpinButton).Left := iLeft[1] - SpinButton1.Width;
       2 : (Components[i] as TSpinButton).Left := iLeft[2] - SpinButton1.Width;
       3 : (Components[i] as TSpinButton).Left := iLeft[3] - SpinButton1.Width;
       4 : (Components[i] as TSpinButton).Left := iLeft[4] - SpinButton1.Width;
       5 : (Components[i] as TSpinButton).Left := iLeft[5] - SpinButton1.Width;    // 진입sp
       6 : (Components[i] as TSpinButton).Left := iLeft[6] - SpinButton1.Width;    // 청산sp

       7 : (Components[i] as TSpinButton).Left := iLeft[7] - SpinButton1.Width;    // 현재가

       8 : (Components[i] as TSpinButton).Left := iLeft[8] - SpinButton1.Width;
       9 : (Components[i] as TSpinButton).Left := iLeft[9] - SpinButton1.Width;
       10 : (Components[i] as TSpinButton).Left := iLeft[10] - SpinButton1.Width;
       11 : (Components[i] as TSpinButton).Left := iLeft[11] - SpinButton1.Width;
      end;

    end;

  if cbAuto.Checked then
    cbAutoClick( nil );
end;

procedure TFrmQuoteMonitors.DefaultParam;
begin
  FWinParam.FontName  := 'Arial';
  FWinParam.FontSize  := 10;

  FShowSubEx[0] := GetExchangeKind(0);
  FShowSubEx[1] := GetExchangeKind(1);
end;

procedure TFrmQuoteMonitors.UpdateParam( bRefresh : boolean );
begin
  with sgQuote do
  begin
    Canvas.Font.Name := FWinParam.FontName;
    Canvas.Font.Size := FwinParam.FontSize;
    if bRefresh then
      Invalidate;
  end;
end;

procedure TFrmQuoteMonitors.LoadEnv(aStorage: TStorage);
begin
  if aStorage = nil  then Exit;

  edtAmt.Text := aStorage.FieldByName('Amount').AsStringDef('50');
  cbUB.Checked:= aStorage.FieldByName('UB').AsBooleanDef(true);
  cbBT.Checked:= aStorage.FieldByName('BT').AsBooleanDef(true);
  cbTradeAble.Checked := aStorage.FieldByName('TA').AsBooleanDef(true);

  edtSec.Text     := aStorage.FieldByName('Second' ).AsStringDef('10');
  cbAuto.Checked  := aStorage.FieldByName('Auto' ).AsBooleanDef(true);
  cbAutoClick(nil);

  cbKREx1.ItemIndex := aStorage.FieldByName('cbKREx1').AsIntegerDef( 0 );
  cbKREx2.ItemIndex := aStorage.FieldByName('cbKREx2').AsIntegerDef( 1 );

  FWinParam.FontName := aStorage.FieldByName('FontName').AsStringDef( FWinParam.FontName );
  FWinParam.FontSize := aStorage.FieldByName('FontSize').AsIntegerDef( FWinParam.FontSize );

  cbKREx1Change( cbKREx1 );
  cbKREx1Change( cbKREx2 );

  UpdateParam( false );

  RefreshData;
end;

procedure TFrmQuoteMonitors.Button1Click(Sender: TObject);
begin
  RefreshData;
end;

procedure TFrmQuoteMonitors.cbAutoClick(Sender: TObject);
begin
  Timer1.Interval := StrToInt( edtSec.Text ) * 1000;
  Timer1.Enabled := cbAuto.Checked;
end;

procedure TFrmQuoteMonitors.cbKREx1Change(Sender: TObject);
var
  iTag, idx : integer;
  bTmp : array [0..1] of TExchangeKind;
begin
  iTag := (Sender as TComboBox).Tag;
  idx  := (Sender as TComboBox).ItemIndex;

  bTmp[iTag] :=  FShowSubEx[iTag];
  FShowSubEx[iTag] := GetExchangeKind(iTag);

  if FShowSubEx[iTag] <> bTmp[iTag] then
    RefreshData;
end;

procedure TFrmQuoteMonitors.cbUBClick(Sender: TObject);
begin
  RefreshData;
end;

function TFrmQuoteMonitors.CheckFilter(aSymbol : TSymbol): boolean;

  function compare( d : double ) : boolean ;
  begin
      if aSymbol.DayAmount + DOUBLE_EPSILON < d then
        Exit (false)
      else
        Exit ( true );
  end;
begin

  if ( FShowSubEx[0] <> aSymbol.Spec.ExchangeType ) and
    ( FShowSubEx[1] <> aSymbol.Spec.ExchangeType ) then
    Exit ( false );

  if cbTradeAble.Checked then
  begin
    var bSymbol : TSymbol;
    bSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol(aSymbol.Spec.BaseCode, ekBinance, eaSpot, scUSDT);

    if ( bSymbol <> nil ) and (bSymbol.RefSymbol <> nil ) and
      (not bSymbol.RefSymbol.TradeAble) then
      Exit (false);
  end;

  if ( not cbUB.Checked ) and ( not cbBT.Checked ) then
    Exit  ( true )
  else  begin
    var dAmt : double;
    dAmt  := StrToFloat( edtAmt.Text );

    if cbUB.Checked and cbBT.Checked then
      Exit ( compare( dAmt))
    else if cbBT.Checked  and ( not cbUB.Checked ) then begin
      if aSymbol.Spec.ExchangeType = ekBithumb then
        Exit ( compare( dAmt))
      else Exit (true);
    end
    else if cbUB.Checked  and ( not cbBT.Checked ) then begin
      if aSymbol.Spec.ExchangeType = ekUpbit then
        Exit ( compare( dAmt))
      else Exit (true);
    end;
  end;



  result := true;
end;

procedure TFrmQuoteMonitors.edtAmtKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    sText : string;
begin
  if Key = VK_RETURN then
  begin
    sText := edtAmt.Text;
    if ( sText = '' ) or ( StrToInt( sText) < 1 ) then Exit;

    refreshData;
  end;

end;

procedure TFrmQuoteMonitors.edtSecKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if cbAuto.Checked then
    cbAuto.Checked := false;
end;

procedure TFrmQuoteMonitors.RefreshData;
var
  I: Integer;
  aSymbol : TSymbol;
//  info: TScrollInfo;
begin
//  App.Engine.QuoteBroker.Cancel( Self );
  InitGrid( sgQuote, true, 1 );
  FDataList.Clear;

  for I := 0 to App.Engine.SymbolCore.CommSymbols.Count-1 do
  begin
    aSymbol := App.Engine.SymbolCore.CommSymbols.CommSymbols[i];
    if not CheckFilter( aSymbol ) then begin
//      sgQuote.RowCount := sgQuote.RowCount -1;
      continue;
    end;
    FDataList.Add( aSymbol );
  end;

  sgQuote.RowCount := FDataList.Count + 1;

  sgQuote.BeginUpdate;

  for I := 0 to FDataList.Count-1 do
  begin
    aSymbol := TSymbol( FDataList.items[i] );
    UpdateData( aSymbol, i+1);
  end;

  sgQuote.EndUpdate;

  // 자리 배치 후 구독
//  for I := 0 to FDataList.Count-1 do
//  begin
//    aSymbol := TSymbol( FDataList.items[i] );
//    App.Engine.QuoteBroker.Brokers[ aSymbol.Spec.ExchangeType ].Subscribe( Self, aSymbol, QuoteProc);
//  end;

  if sgQuote.RowCount > 1 then
    sgQuote.FixedRows := 1;

// FillChar(info, Sizeof(info), 0);
//  with info do
//  begin
//    cbsize := Sizeof(info);
//    fmask  := SIF_ALL;
//    GetScrollInfo(sgQuote.handle, SB_VERT, info);
//    fmask  := fmask or SIF_PAGE;
//    nPage  := 5 * (nmax-nmin) div sgQuote.RowCount;
//  end;
//  SetScrollInfo(sgQuote.handle, SB_VERT, info, True);
end;

procedure TFrmQuoteMonitors.SimpleRefreshData;
var
  I: Integer;
  aSymbol : TSymbol;
begin

  InitGrid( sgQuote, false, 1 );

  for I := 0 to FDataList.Count-1 do
  begin
    aSymbol := TSymbol( FDataList.items[i] );
    UpdateData( aSymbol, i+1);
  end;

end;

procedure TFrmQuoteMonitors.MoreSimpleRefreshData;
var
  I: Integer;
  aSymbol : TSymbol;
begin

  if App.Stop then Exit;

  sgQuote.BeginUpdate;

  for I := 1 to sgQuote.RowCount-1 do
  begin
    aSymbol := TSymbol( sgQuote.Objects[CoinCol, i] );
    if aSymbol <> nil then
      UpdateData( aSymbol, i);
  end;

  sgQuote.EndUpdate;

end;

procedure TFrmQuoteMonitors.PutData( var iCol, iRow : integer; sData : string );
begin
  sgQuote.Cells[iCol, iRow] := sData;
  inc( iCol );
end;

procedure TFrmQuoteMonitors.QuoteProc(Sender, Receiver: TObject;
  DataID: Integer; DataObj: TObject; EventID: TDistributorID);
  var
    aSymbol : TSymbol;
    iRow : integer;
begin
  if ( Receiver <> Self ) or ( DataObj = nil ) then Exit;

  aSymbol := (DataObj as TQuote).Symbol;
  iRow := sgQuote.Cols[CoinCol].IndexOfObject( aSymbol );

  if iRow <= 0 then Exit;

  UpdateData( asymbol,  iRow );

end;

procedure TFrmQuoteMonitors.UpdateData( aSymbol : TSymbol; iRow : integer );
var
  iCol : integer;
  dTmp, dBasis : double;
  bSymbol, pSymbol : TSymbol;
  sTmp : string;
begin
  iCol := 0;
  with sgQuote do
  begin
    Objects[CoinCol, iRow]  := aSymbol;
    PutData( iCol, iRow, aSymbol.Code );
    PutData( iCol, iRow, TExchangeKindShortDesc[ aSymbol.Spec.ExchangeType ]  );
    // binance basis

    pSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol(  aSymbol.Spec.BaseCode, ekBinance, eaFutUsdt );

    if pSymbol <> nil then
      dBasis := pSymbol.Basis
    else
      dBasis := 0.0;
        
    PutData( iCol, iRow, Format('%.*n', [ 2, dBasis] ) );
    PutData( iCol, iRow, Format('%.*n', [ FPrecision, aSymbol.KimpPrice] ) );

    PutData( iCol, iRow, format('%.*n', [ 2, aSymbol.WDCPrice] ) );

// 진입, 청산 SP
    sTmp := ifThenStr( aSymbol.Spec.ExchangeType = ekUpbit,  Format('%.*n', [ 2, aSymbol.SPValue[0]] ) , '' );
    PutData( iCol, iRow, sTmp);
    sTmp := ifThenStr( aSymbol.Spec.ExchangeType = ekUpbit,  Format('%.*n', [ 2, aSymbol.SPValue[1]] ) , '' );
    PutData( iCol, iRow, sTmp);

    PutData( iCol, iRow, Format('%.2f', [ aSymbol.SpreadRate]) );

    PutData( iCol, iRow, aSymbol.PriceToStr( aSymbol.Last ) );

// 추가된 컬럼 2022.11.09
    PutData( iCol, iRow, Format('%.0n ', [ (aSymbol.Asks[0].Price * aSymbol.Asks[0].Volume) / 1000 ]) );
    PutData( iCol, iRow, aSymbol.PriceToStr(aSymbol.Asks[0].Price ) );
    PutData( iCol, iRow, aSymbol.PriceToStr(aSymbol.Bids[0].Price ) );
    PutData( iCol, iRow, Format('%.0n ', [ (aSymbol.Bids[0].Price * aSymbol.Bids[0].Volume) / 1000 ]) );

    // 전일종가 대신 오픈...
    if aSymbol.PrevClose <= 0 then  dTmp := 1
    else dTmp := aSymbol.PrevClose;

    // 등락/ 고/ 저
    PutData( iCol, iRow, Format('%.1f', [ (aSymbol.Last    - aSymbol.PrevClose) / dTmp * 100 ] ) );
    PutData( iCol, iRow, Format('%.1f', [ (aSymbol.DayHigh - aSymbol.PrevClose) / dTmp * 100 ] ) );
    PutData( iCol, iRow, Format('%.1f', [ (aSymbol.DayLow  - aSymbol.PrevClose) / dTmp * 100 ] ) );

    PutData( iCol, iRow, Format('%.*n', [ 0, aSymbol.DayAmount ]) );

    bSymbol := App.Engine.SymbolCore.BaseSymbols.FindSymbol( aSymbol.Spec.BaseCode, ekBinance, eaSpot);

    if bSymbol = nil then begin
      PutData( iCol, iRow, 'X');
      Objects[ABLE_COL,iRow] := Pointer(100);
    end
    else begin
      PutData( iCol, iRow, ifThenStr( bSymbol.IsFuture, 'O', 'X') );
//      PutData( iCol, iRow, ifThenStr( bSymbol.IsMargin, '○', 'X') );

      if bSymbol.RefSymbol <> nil then
      begin
        if bSymbol.RefSymbol.TradeAble then
          Objects[ABLE_COL,iRow] := Pointer(100)
        else
          Objects[ABLE_COL,iRow] := Pointer(-100);
      end;
    end;

    // 현재가 같은 호가..하이라이트...
    if Cells[ Mon_CurCol , iRow] = Cells[ Mon_AskCol , iRow] then
      Objects[ Mon_AskCol, iRow] := Pointer( 100 )
    else
      Objects[ Mon_AskCol, iRow] := Pointer( -100 );

    if Cells[ Mon_CurCol , iRow] = Cells[ Mon_BidCol, iRow] then
      Objects[ Mon_BidCol, iRow] := Pointer( 100 )
    else
      Objects[ Mon_BidCol, iRow] := Pointer( -100 );

  end;
end;

procedure TFrmQuoteMonitors.SaveEnv(aStorage: TStorage);
begin
  if aStorage = nil  then Exit;

  aStorage.FieldByName('Amount').AsString := edtAmt.Text;
  aStorage.FieldByName('UB').AsBoolean := cbUB.Checked;
  aStorage.FieldByName('BT').AsBoolean := cbBT.Checked;
  aStorage.FieldByName('TA').AsBoolean := cbTradeAble.Checked;

  aStorage.FieldByName('Second' ).AsString := edtSec.Text;
  aStorage.FieldByName('Auto' ).AsBoolean  := cbAuto.Checked;

  aStorage.FieldByName('FontName').AsString := FWinParam.FontName;
  aStorage.FieldByName('FontSize').AsInteger:= FWinParam.FontSize;

  aStorage.FieldByName('cbKREx1').AsInteger := cbKREx1.ItemIndex;
  aStorage.FieldByName('cbKREx2').AsInteger := cbKREx2.ItemIndex;
end;

procedure TFrmQuoteMonitors.sgQuoteDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
  var
    stTxt : string;
    aRect : TRect;
    aFont, aBack : TColor;
    dFormat : Word;
    iMode : integer;
    iVal  : integer;
begin
  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;
  iVal    := 0;

  with sgQuote do
  begin

    Canvas.Font.Style   := [];
    Canvas.Font.Size    := 10;

    stTxt := Cells[ ACol, ARow];

    if ARow = 0 then
    begin
      aBack := clMoneyGreen;
    end else
    begin
      if ACol in [4..15] then
        dFormat := DT_RIGHT;

//      if ACol = ABLE_COL then
//      begin
        if Objects[ ABLE_COL, ARow] <> nil then
        begin
          iVal := integer( Objects[ABLE_COL, ARow] );
          if iVal < 0 then begin
            Canvas.Font.Style   := Canvas.Font.Style + [fsItalic];
            Canvas.Font.Size    := 8;
            aFont := clSilver;
          end;
        end;
//      end;

    // 매도/매수 하이라이트
      if ACol in [Mon_AskCol..Mon_BidCol] then
        if Objects[ ACol, ARow] <> nil then
        begin
          if ARow = 32 then
            iVal := integer( Objects[ACol, ARow] );
          iVal := integer( Objects[ACol, ARow] );
          if iVal > 0 then begin
            if ACol = Mon_AskCol then
              aBack := Short_COLOR
            else
              aBack := LONG_COLOR;
          end;
        end;
    end;

    aRect.Top := Rect.Top + 4;
    if ( ARow > 0 ) and ( dFormat = DT_RIGHT ) then
      aRect.Right := aRect.Right - 2;
    dFormat := dFormat or DT_VCENTER;

    if (ARow > 0) and (ARow = FRow) then
    begin
      aBack := $00F2BEB9;
    end;

    Canvas.Font.Color   := aFont;
    Canvas.Brush.Color  := aBack;

    Canvas.FillRect( Rect);
    DrawText( Canvas.Handle, PChar( stTxt ), Length( stTxt ), aRect, dFormat );

    if ARow = 0 then begin
      Canvas.Pen.Color := clBlack;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Right, Rect.Bottom),
                       Point(Rect.Right, Rect.Top)]);
      Canvas.Pen.Color := clWhite;
      Canvas.PolyLine([Point(Rect.Left,  Rect.Bottom),
                       Point(Rect.Left,  Rect.Top),
                       Point(Rect.Right, Rect.Top)]);
    end
    else if ARow > 1 then
    begin
     if (ARow mod 5 = 0) then begin

        Canvas.Pen.Color := clSilver;
        Canvas.Pen.Width := 1;
        Canvas.Pen.Style := psSolid;
        Canvas.MoveTo( rect.left-1, rect.bottom );
        Canvas.Lineto( rect.right, rect.bottom );

      end;
    end;
  end;

end;


procedure TFrmQuoteMonitors.sgQuoteMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var
    aCol, aRow : integer;
begin
  //
  aRow := FRow;

  sgQuote.MouseToCell( X, Y, aCol, FRow);

  sgQuote.Repaint;

//  if aRow > 0 then InvalidateRow( sgQuote, aRow );
//  if FRow > 0 then InvalidateRow( sgQuote, FRow );

end;

procedure TFrmQuoteMonitors.sgQuoteMouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
//  Handled:= True;
end;

procedure TFrmQuoteMonitors.sgQuoteMouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
//  Handled:= True;
end;

procedure TFrmQuoteMonitors.SortGrid(Grid: TStringGrid; SortCol: Integer; bAsc : boolean);
var

I, J: Integer;
temp: TStringList;
aSymbol, aSymbol2 : TSymbol ;
bComp : boolean;
iStr, jStr : string;
begin

  temp := TStringList.create;
  with Grid do

  for I := FixedRows to RowCount - 2 do
    for J := I + 1 to RowCount - 1 do
    begin

      if bAsc then
        bComp := CompareText(Cells[SortCol, I], Cells[SortCol, J]) > 0
      else
        bComp := CompareText(Cells[SortCol, I], Cells[SortCol, J]) < 0  ;

      if bComp then
      begin
        temp.assign(Rows[J]);

        Rows[J].assign(Rows[I]);
        Rows[I].assign(temp);
      end;
    end;
  temp.free;
end;

// 올림차순
procedure TFrmQuoteMonitors.SpinButton1DownClick(Sender: TObject);
var
  iTag : integer;
begin
  iTag := (Sender as TComponent).Tag ;

  //
  with sgQuote do
    case (Sender as TComponent).Tag of
      0 ,
      1 : SortGrid( sgQuote, iTag);     // 거래소
      2 : FDataList.Sort(CompareBasis2) ;     // basis
      3 : FDataList.Sort(CompareKimpPrice2) ;     // 김프
      4 : FDataList.Sort(CompareWDCPrice2);     //  wcd
      5 : FDataList.Sort(CompareSPrice2);     // 진입sp
      6 : FDataList.Sort(CompareExSPrice2);     // 청산sp

      7 : FDataList.Sort(CompareLast2);     // 현재가
      8 : FDataList.Sort(CompareDayUpDown2);     // 등락
      9 : FDataList.Sort(CompareDayHigh2); // 고
      10 : FDataList.Sort(CompareDayLow2); // 저
      11 : FDataList.Sort(CompareDailyAmount2);     // 일거래액
    end;

  if iTag in [2..11] then
    SimpleRefreshData;
end;

// 내림차순..
procedure TFrmQuoteMonitors.SpinButton1UpClick(Sender: TObject);
var
  iTag : integer;
begin
  iTag := (Sender as TComponent).Tag ;

  //
  with sgQuote do
    case (Sender as TComponent).Tag of
      0 ,
      1 : SortGrid( sgQuote, iTag, false);     // 거래소
      2 : FDataList.Sort(CompareBasis) ;     // basis
      3 : FDataList.Sort(CompareKimpPrice) ;     // 김프
      4 : FDataList.Sort(CompareWDCPrice);     // wcd
      5 : FDataList.Sort(CompareSPrice);     // 진입sp
      6 : FDataList.Sort(CompareExSPrice);     // 청산sp

      7 : FDataList.Sort(CompareLast);     // 현재가
      8 : FDataList.Sort(CompareDayUpDown);     // 등락
      9 : FDataList.Sort(CompareDayHigh);  // 고
      10 : FDataList.Sort(CompareDayLow);  // 저
      11 : FDataList.Sort(CompareDailyAmount);     // 일거래액
    end;

  if iTag in [2..11] then
    SimpleRefreshData;
end;

procedure TFrmQuoteMonitors.Timer1Timer(Sender: TObject);
begin
  plExRate.Caption  := Format('%.*n', [ 2, App.Engine.ApiManager.ExRate.Value ] );
  MoreSimpleRefreshData;
end;

end.
