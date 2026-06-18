unit FOrderList;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls
  , UApiTypes, UApiConsts
  , UOrders, USymbols
  , UStorage, Vcl.Menus
  , UDistributor
  ;
const
  ORD_COL = 0;
  NEXT_ROW_CNT = 100;

type
  TFrmOrderList = class(TForm)
    Panel1: TPanel;
    sgOrder: TStringGrid;
    ComboBox1: TComboBox;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    N2: TMenuItem;
    edtCode: TEdit;
    cbCode: TCheckBox;
    btnNext: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure sgOrderDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure sgOrderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure edtCodeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbCodeClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
  private
    { Private declarations }
    FExIndex : integer;
    FIndex, FCount  : integer;
    FState   : array [0..4] of boolean;
    FRow     : integer;
    FOrder	 : TOrder;

    //FStIndex : integer;
    procedure initControls;
    procedure DoOrder(aOrder: TOrder; EventID: TDistributorID);
    function Fillter(aOrder: TOrder): boolean;
    procedure AddOrder(aOrder: TOrder); overload;
    procedure AddOrder(aOrder: TOrder; iRow : integer); overload;
    procedure DelOrder(aOrder: TOrder);
    procedure UpdateOrder(aOrder: TOrder);
    procedure PutData(aOrder: TOrder; iRow: integer); overload;
    procedure PutData( var iCol, iRow : integer; sData : string); overload;
    procedure UpdateData;
    procedure UpdateDataNext;
    { Public declarations }
  public
    procedure SaveEnv( aStorage : TStorage );
    procedure LoadEnv( aStorage : TStorage );
    procedure TradeProc(Sender, Receiver: TObject; DataID: Integer;
      DataObj: TObject; EventID: TDistributorID) ;
    
  end;
var
  FrmOrderList: TFrmOrderList;
implementation
uses
	GApp, GLibs
  , USymbolCore
  , UTableConsts
  , UConsts
  , Math
  ;
{$R *.dfm}
procedure TFrmOrderList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caFree;
end;
procedure TFrmOrderList.FormCreate(Sender: TObject);
begin
	initControls;
  FExIndex  := 0;
  FState[0] := true;
  FState[1] := true;
  Fstate[2] := false;    Fstate[3] := false;     Fstate[4] := false;

  UpdateData;

  App.Engine.TradeBroker.Subscribe( Self, TradeProc);

end;
procedure TFrmOrderList.FormDestroy(Sender: TObject);
begin
	//
  App.Engine.TradeBroker.Unsubscribe( Self );
end;
procedure TFrmOrderList.initControls;
var
  I: integer;
begin
	with sgOrder do
  begin
		ColCount	:= orderList_TitleCnt;
  	RowCount	:= 1;
    for I := 0 to orderList_TitleCnt-1 do
		begin
    	Cells[i,0]	:= orderList_Title[i];
      ColWidths[i]:= orderList_Width[i];
    end;
  end;

  FRow := -1;
end;



procedure TFrmOrderList.LoadEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
    //
    ComboBox1.ItemIndex := FieldByName('ExKin').AsIntegerDef(0);
    CheckBox1.Checked := FieldByName('CheckBox1').AsBooleanDef(True);
    CheckBox2.Checked := FieldByName('CheckBox2').AsBooleanDef(True);
    CheckBox3.Checked := FieldByName('CheckBox3').AsBooleanDef(False);
    CheckBox4.Checked := FieldByName('CheckBox4').AsBooleanDef(False);

    cbCode.Checked  := FieldByName('cbCode').AsBoolean;
    edtCode.Text    := FieldByName('Code').AsString ;
  end;
end;


procedure TFrmOrderList.SaveEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
    //
    FieldByName('ExKin').AsInteger   := ComboBox1.ItemIndex;
    FieldByName('CheckBox1').AsBoolean  := CheckBox1.Checked;
    FieldByName('CheckBox2').AsBoolean  := CheckBox2.Checked;
    FieldByName('CheckBox3').AsBoolean  := CheckBox3.Checked;
    FieldByName('CheckBox4').AsBoolean  := CheckBox4.Checked;

    FieldByName('cbCode').AsBoolean   := cbCode.Checked;
    FieldByName('Code').AsString    := edtCode.Text;
  end;
end;

procedure TFrmOrderList.N1Click(Sender: TObject);
begin
	//  
  if FOrder = nil then Exit;

  App.Engine.TradeCore.Orders[ FOrder.Account.ExchangeKind].NewCancelOrder( FOrder, FOrder.ActiveQty);
  App.Engine.TradeBroker.Send( FOrder );

end;

procedure TFrmOrderList.N2Click(Sender: TObject);
begin
  if FOrder = nil then Exit;

  App.Engine.ApiManager.ExManagers[ FOrder.Account.ExchangeKind].RequestOrdeDetail( FOrder );

end;

procedure TFrmOrderList.sgOrderDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
  var
  	aRect : TRect;
    aFont, aBack : TColor;    
    dFormat	: WORD;
    stTxt	: string;
    aOrder: TOrder;
begin
  aFont   := clBlack;
  dFormat := DT_CENTER ;
  aRect   := Rect;
  aBack   := clWhite;
  aOrder  := nil;

	with sgOrder do
  begin
  	stTxt := Cells[ ACol, ARow];
  	if ARow = 0 then
    begin
			aBack := clBtnFace;
    end else
    begin
    	if ACol in [4..7] then
				dFormat := DT_RIGHT;

      if ACol = 3 then
      begin
        aOrder  := TOrder( Objects[ORD_COL, ARow] );
        if aOrder <> nil then begin
          if aOrder.Side > 0 then
            aFont := clRed
          else if aOrder.Side < 0 then
            aFont := clBlue;
        end
      end;


      if ARow = FRow then
      begin
        aBack := $00F2BEB9;
      end;
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
procedure TFrmOrderList.sgOrderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    ACol : integer;
    aOrder : TOrder;
begin
  sgOrder.PopupMenu := nil;
  sgOrder.MouseToCell(X,Y, ACol, FRow);
  if FRow < 0 then Exit;

  if Button = mbRight then
  begin

    aOrder  := TOrder( sgOrder.Objects[ORD_COL, FRow] );
    FOrder  := nil;
    if ( aOrder <> nil ) and ( aOrder.State = osActive ) and ( not aORder.Modify ) then
    begin
      sgOrder.PopupMenu := PopupMenu1;
      FOrder	:= aOrder;
    end;
  end;

  sgOrder.Invalidate;

end;

procedure TFrmOrderList.TradeProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin
  if (Receiver <> Self) or (DataID <> TRD_DATA) then Exit;

  case Integer(EventID) of
    ORDER_ACCEPTED,
    ORDER_REJECTED,
    ORDER_CANCELED,
    ORDER_FILLED: DoOrder(DataObj as TOrder, EventID);
  end;
end;

procedure TFrmOrderList.DoOrder(aOrder : TOrder;EventID: TDistributorID);
var
  bRes : boolean;
begin
  bRes := Fillter( aOrder );

  if not bRes then
    DelOrder( aOrder )
  else begin
    if ((aOrder.State = osActive) and ( integer(EventID) = ORDER_ACCEPTED ))
      or ( aOrder.State = osRejected )  then
      AddOrder( aOrder )
    else
      UpdateOrder( aOrder );
  end;
end;


procedure TFrmOrderList.edtCodeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    sText : string;
begin

  if Key = VK_RETURN then
  begin
    if not cbCode.Checked then Exit;
    if edtCode.text = '' then Exit;
    UpdateData;
  end;
end;

procedure TFrmOrderList.AddOrder(aOrder : TOrder );
begin
  InsertLine( sgOrder, 1 );
  PutData( aOrder, 1 );

  if ( sgOrder.RowCount > 1) and ( sgOrder.FixedRows <= 0 ) then
    sgOrder.FixedRows := 1;
end;

procedure TFrmOrderList.AddOrder(aOrder: TOrder; iRow : integer);
begin

  InsertLine( sgOrder, iRow );
  PutData( aOrder, iRow );

end;

procedure TFrmOrderList.UpdateOrder(aOrder : TOrder );
var
  iRow : integer;
begin
  iRow := sgOrder.Cols[ORD_COL].IndexOfObject(aOrder);
  if iRow >= 0 then
    PutData(aOrder, iRow )
  else
    AddOrder(aOrder);
end;

procedure TFrmOrderList.DelOrder(aOrder : TOrder );
var
  iRow : integer;
begin
  iRow := sgOrder.Cols[ORD_COL].IndexOfObject(aOrder);
  if iRow >= 0 then
    DeleteLine(sgOrder, iRow );
end;

procedure TFrmOrderList.PutData( aOrder : TOrder; iRow : integer);
var
  iCol, iPre : integer;
begin
  iCol := 0;
  with sgOrder do
  begin
    Objects[ORD_COL, iRow]  := aOrder;
    if aOrder.StgType in [stPutKipOrder, stSPOrder] then
      PutData( iCol, iRow, aOrder.GroupNo )
    else
      PutData( iCol, iRow, aOrder.StgToStr );
    PutData( iCol, iRow, ExKindToStr( aOrder.Account.ExchangeKind ) );
    PutData( iCol, iRow, aOrder.Symbol.Spec.BaseCode );
    PutData( iCol, iRow, aOrder.SideToStr );
    PutData( iCol, iRow, aOrder.Symbol.PriceToStr( aOrder.Price) );

    if aOrder.Symbol.Spec.ExchangeType = ekBinance then
      PutData( iCol, iRow, aOrder.Symbol.QtyToStr( aOrder.OrderQty) )
    else
      PutData( iCol, iRow, aOrder.OrderQtyBI.ToString  );

    PutData( iCol, iRow, aOrder.Symbol.PriceToStr( aOrder.AvgPrice ) );
    PutData( iCol, iRow, Format('%.8n', [aOrder.FilledQty]));// aOrder.Symbol.QtyToStr( aOrder.FilledQty) );
    PutData( iCol, iRow, aOrder.StateToStr );

    if aOrder.State = osRejected then
      PutData( iCol, iRow, FormatDateTime('hh:nn:ss', aOrder.RejectTime) )
    else
      PutData( iCol, iRow, FormatDateTime('hh:nn:ss', aOrder.AcptTime) );

    if aOrder.Fills.Count > 0 then
      PutData( iCol, iRow, FormatDateTime('hh:nn:ss', aOrder.Fills.Fills[0].FillTime ) )
    else
      PutData( iCol, iRow, '' );

    if aOrder.State = osRejected then
      PutData( iCol, iRow, aOrder.RejectReason )
    else
      PutData( iCol, iRow, aOrder.OrderNo );
  end;
end;

procedure TFrmOrderList.PutData( var iCol, iRow : integer; sData : string);
begin
  with sgOrder do
  begin
    Cells[ iCol, iRow] := sData;
  end;
  inc( iCol );
end;



procedure TFrmOrderList.btnNextClick(Sender: TObject);
begin
  //
  UpdateDataNext;
end;

procedure TFrmOrderList.cbCodeClick(Sender: TObject);
begin
  UpdateData;
end;

procedure TFrmOrderList.CheckBox1Click(Sender: TObject);
var
  iTag : integer;
begin
  iTag := TCheckBox(Sender).Tag ;
  FState[iTag]  := TCheckBox(Sender).Checked;

  UpdateData;
end;

procedure TFrmOrderList.ComboBox1Change(Sender: TObject);
begin
  FExIndex := ComboBox1.ItemIndex;
  UpdateData;
end;

procedure TFrmOrderList.ComboBox2Change(Sender: TObject);
begin
  //
//  FStIndex  := ComboBox2.ItemIndex ;
end;

function TFrmOrderList.Fillter( aOrder : TOrder ) : boolean;
begin
  case FExIndex of
    0 : Result := true;
    else  Result := aOrder.Account.ExchangeKind = TExchangeKind( FExIndex - 1 );
  end;
  if not Result then Exit;

  if cbCode.Checked then
    if UpperCase( aOrder.Symbol.Spec.BaseCode) <> UpperCase(edtcode.Text) then Exit (false);

  case aOrder.State of
    osReady,  osSent,   osSrvAcpt : Result := FState[4] ;
    osSrvRjt, osFailed, osRejected: Result := FState[3] ;
    osActive: Result  := FState[0] ;
    osFilled: Result  := FState[1];
    osCanceled:Result := FState[2] ;
  end;
end;


procedure TFrmOrderList.UpdateData;
var
  aOrder : TOrder;
  iCnt, iStart, i : integer;
  aList : TList;
begin

  InitGrid( sgOrder, true, 1 );
//  sgOrder.BeginUpdate;
  FCount := 1;

//  if App.Engine.TradeCore.TotalOrders.Count > (NEXT_ROW_CNT*FCount) then begin
//    FIndex  := App.Engine.TradeCore.TotalOrders.Count - (NEXT_ROW_CNT*FCount);
//    btnNext.Enabled := true;
//  end
//  else begin
//    FIndex  := 0;
//    btnNext.Enabled := false;
//  end;
  FIndex  := 0;

  aList := TList.Create;
  try

    for I := App.Engine.TradeCore.TotalOrders.Count-1 downto 0 do
    begin
      FIndex := i;
      aOrder  := App.Engine.TradeCore.TotalOrders.Orders[i];
      if aOrder = nil then Continue;
      if not Fillter( aOrder ) then Continue;
      aList.Add(aOrder);
      if aList.Count >= NEXT_ROW_CNT then
      begin

        break;
      end;
    end;

    for I := aList.Count-1 downto 0 do
    begin
      aOrder  := TOrder( aList.Items[i] );
      AddOrder( aOrder );
    end;

//    for I := FIndex to App.Engine.TradeCore.TotalOrders.Count-1 do
//    begin
//      aOrder  := App.Engine.TradeCore.TotalOrders.Orders[i];
//      if aOrder = nil then Continue;
//      if not Fillter( aOrder ) then Continue;
//      AddOrder( aOrder );
//      inc( iCnt);
//      if iCnt >  NEXT_ROW_CNT  then
//      begin
//
//      end;
//    end;

    if FIndex > 0 then
      btnNext.Enabled := true
    else
      btnNext.Enabled := false;

  finally
    aList.Free;
  end;

//  sgOrder.EndUpdate;
end;

procedure TFrmOrderList.UpdateDataNext;
var
  aOrder : TOrder;
  i, iEnd, iRow : integer;

  aList : TList;
begin

  aList := TList.Create;
  try

    for I := FIndex-1 downto 0 do
    begin
      FIndex := i;
      aOrder  := App.Engine.TradeCore.TotalOrders.Orders[i];
      if aOrder = nil then Continue;
      if not Fillter( aOrder ) then Continue;
      aList.Add(aOrder);
      if aList.Count >= NEXT_ROW_CNT then
        break;
    end;

    iRow := sgOrder.RowCount;

    for I := aList.Count-1 downto 0 do
    begin
      aOrder  := TOrder( aList.Items[i] );
      AddOrder( aOrder, iRow );
    end;

    if FIndex > 0 then
      btnNext.Enabled := true
    else
      btnNext.Enabled := false;

  finally
    aList.Free;
  end;


  Exit;


  inc(FCount);

//  if FIndex > 10 then
//  begin
//    FIndex := FIndex - 10;
//    btnNext.Enabled := true;
//  end else
//  begin
//    FIndex := 0;
//    btnNext.Enabled := false;
//  end;
  iEnd := FIndex;

  if App.Engine.TradeCore.TotalOrders.Count > (NEXT_ROW_CNT*FCount) then begin
    FIndex  := App.Engine.TradeCore.TotalOrders.Count - (NEXT_ROW_CNT*FCount);
    btnNext.Enabled := true;
  end
  else begin
    FIndex  := 0;
    btnNext.Enabled := false;
  end;

//  FIndex := Min(0, FIndex - 10);
//
//  if App.Engine.TradeCore.TotalOrders.Count - FIndex > 10 then begin
//    FIndex  := App.Engine.TradeCore.TotalOrders.Count - (FIndex + 10 );
//    btnNext.Enabled := true;
//  end
//  else begin
//    FIndex  := 0;
//    btnNext.Enabled := false;
//  end;
  iRow := sgOrder.RowCount;

  for I := FIndex to iEnd-1 do //App.Engine.TradeCore.TotalOrders.Count-1 do
  begin
    aOrder  := App.Engine.TradeCore.TotalOrders.Orders[i];
    if aOrder = nil then Continue;
    if not Fillter( aOrder ) then Continue;
    AddOrder( aOrder, iRow );
  end;

end;

end.

