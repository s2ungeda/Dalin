unit FOrderList;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections
  , VirtualTrees, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL
  , UApiTypes, UApiConsts
  , UOrders, USymbols, UFills
  , UStorage, Vcl.Menus
  , UDistributor
  ;

const
  COL_EXPAND   = 0;
  COL_STRATEGY = 1;
  COL_EXCHANGE = 2;
  COL_SYMBOL   = 3;
  COL_SIDE     = 4;
  COL_PRICE    = 5;
  COL_QTY      = 6;
  COL_AVGPRICE = 7;
  COL_FILLEDQTY= 8;
  COL_STATE    = 9;
  COL_TIME     = 10;
  COL_FILLTIME = 11;
  COL_ORDERNO  = 12;

  ORD_COL = 1;
  EXP_COL = 0;
  FIL_COL = 2;
  NEXT_ROW_CNT = 500;

  EXP_ON = 100;
  EXP_OFF = -100;
  EXP_NO = 0;

type
  TRowType = (rtOrder, rtFill);

  TDisplayRow = record
    RowType: TRowType;
    Order: TOrder;
    Fill: TFill;
    IsExpanded: Boolean;
  end;
  PDisplayRow = ^TDisplayRow;

  TOrderFilterState = record
    ShowActive: Boolean;
    ShowFilled: Boolean;
    ShowCanceled: Boolean;
    ShowRejected: Boolean;
    ShowPending: Boolean;
    procedure Reset;
    procedure SetFromCheckBoxes(cb1, cb2, cb3, cb4: Boolean);
  end;

type
  TFrmOrderList = class(TForm)
    Panel1: TPanel;
    vstOrder: TVirtualStringTree;
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
    Panel2: TPanel;
    Label1: TLabel;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure edtCodeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbCodeClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N4Click(Sender: TObject);

    // VirtualStringTree event handlers
    procedure vstOrderGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vstOrderGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure vstOrderPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType);
    procedure vstOrderBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    procedure vstOrderFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstOrderNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure vstOrderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    FExIndex : integer;
    FIndex, FCount  : integer;
    FFilterState : TOrderFilterState;
    FOrder	 : TOrder;

    FExpandedOrders: TDictionary<string, boolean>;
    FDisplayList: TList<TDisplayRow>;

    procedure InitGrid;
    procedure AddColumn(const AText: string; AWidth: Integer;
      AAlignment: TAlignment = taLeftJustify);
    procedure DoOrder(aOrder: TOrder; EventID: TDistributorID);
    function Filter(aOrder: TOrder): boolean;

    procedure InsertOrderToTop(aOrder: TOrder);
    procedure HandleOrderRemoval(aOrder: TOrder);
    procedure RefreshOrderInList(aOrder: TOrder);
    function FindOrderRowIndex(aOrder: TOrder): Integer;
    procedure FillFromNextOrders;

    procedure UpdateData;
    procedure DoUpdateList(aStartIndex: Integer);
    procedure UpdateDataNext;

    function GetOrderCellText(aOrder: TOrder; ACol: Integer): string;
    function GetFillCellText(aOrder: TOrder; aFill: TFill; ACol: Integer): string;

    procedure CleanupExpandedOrders;

    function GetNodeDisplayRow(Node: PVirtualNode): PDisplayRow;

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
  , Clipbrd
  ;
{$R *.dfm}

{ TOrderFilterState }

procedure TOrderFilterState.Reset;
begin
  ShowActive := True;
  ShowFilled := True;
  ShowCanceled := False;
  ShowRejected := False;
  ShowPending := False;
end;

procedure TOrderFilterState.SetFromCheckBoxes(cb1, cb2, cb3, cb4: Boolean);
begin
  ShowActive := cb1;
  ShowFilled := cb2;
  ShowCanceled := cb3;
  ShowRejected := cb4;
end;

{ TFrmOrderList }

procedure TFrmOrderList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caFree;
end;

procedure TFrmOrderList.FormCreate(Sender: TObject);
begin
	InitGrid;
  FExIndex  := 0;

  FDisplayList   := TList<TDisplayRow>.Create;
  FExpandedOrders:= TDictionary<string, boolean>.Create;

  FFilterState.Reset;

  UpdateData;

  App.Engine.TradeBroker.Subscribe( Self, TradeProc);

end;

procedure TFrmOrderList.FormDestroy(Sender: TObject);
begin
  FDisplayList.Free;
  FExpandedOrders.Free;
  App.Engine.TradeBroker.Unsubscribe( Self );
end;

//==============================================================================
// VirtualStringTree Grid Initialization
//==============================================================================
procedure TFrmOrderList.InitGrid;
begin
  vstOrder.BeginUpdate;
  try
    vstOrder.NodeDataSize := SizeOf(TDisplayRow);

    // Grid mode options
    vstOrder.TreeOptions.MiscOptions :=
      vstOrder.TreeOptions.MiscOptions
      + [toGridExtensions, toFullRepaintOnResize]
      - [toToggleOnDblClick];

    vstOrder.TreeOptions.PaintOptions :=
      vstOrder.TreeOptions.PaintOptions
      + [toShowVertGridLines, toShowHorzGridLines, toHideFocusRect]
      - [toShowTreeLines, toShowRoot, toShowButtons];

    vstOrder.TreeOptions.SelectionOptions :=
      vstOrder.TreeOptions.SelectionOptions
      + [toExtendedFocus, toFullRowSelect];

    // Header
    vstOrder.Header.Options :=
      vstOrder.Header.Options
      + [hoVisible, hoColumnResize, hoAutoResize]
      - [hoDrag];

    vstOrder.Header.Style := hsFlatButtons;
    vstOrder.Header.Height := 24;
    vstOrder.DefaultNodeHeight := 22;

    // Columns
    vstOrder.Header.Columns.Clear;
    AddColumn('',           30,  taCenter);         // 0  COL_EXPAND
    AddColumn('Strategy',   80,  taLeftJustify);    // 1  COL_STRATEGY
    AddColumn('Exchange',   70,  taCenter);         // 2  COL_EXCHANGE
    AddColumn('Symbol',     80,  taLeftJustify);    // 3  COL_SYMBOL
    AddColumn('Side',       50,  taCenter);         // 4  COL_SIDE
    AddColumn('Price',     100,  taRightJustify);   // 5  COL_PRICE
    AddColumn('Qty',        80,  taRightJustify);   // 6  COL_QTY
    AddColumn('AvgPrice',  100,  taRightJustify);   // 7  COL_AVGPRICE
    AddColumn('FilledQty',  80,  taRightJustify);   // 8  COL_FILLEDQTY
    AddColumn('State',      80,  taCenter);         // 9  COL_STATE
    AddColumn('Time',       80,  taCenter);         // 10 COL_TIME
    AddColumn('FillTime',   80,  taCenter);         // 11 COL_FILLTIME
    AddColumn('OrderNo',   120,  taLeftJustify);    // 12 COL_ORDERNO

    // Appearance
    vstOrder.Color := clWhite;
    vstOrder.Font.Name := 'Tahoma';
    vstOrder.Font.Size := 9;
    vstOrder.Header.Font.Name := 'Tahoma';
    vstOrder.Header.Font.Size := 9;
    vstOrder.Header.Font.Style := [fsBold];

  finally
    vstOrder.EndUpdate;
  end;
end;

procedure TFrmOrderList.AddColumn(const AText: string; AWidth: Integer;
  AAlignment: TAlignment);
var
  Col: TVirtualTreeColumn;
begin
  Col := vstOrder.Header.Columns.Add;
  Col.Text := AText;
  Col.Width := AWidth;
  Col.Alignment := AAlignment;
  Col.CaptionAlignment := taCenter;
end;

//==============================================================================
// Node data helper
//==============================================================================
function TFrmOrderList.GetNodeDisplayRow(Node: PVirtualNode): PDisplayRow;
begin
  Result := vstOrder.GetNodeData(Node);
end;

//==============================================================================
// VirtualStringTree Event Handlers
//==============================================================================
procedure TFrmOrderList.vstOrderGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TDisplayRow);
end;

procedure TFrmOrderList.vstOrderGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  Data: PDisplayRow;
begin
  Data := GetNodeDisplayRow(Node);
  if Data = nil then Exit;

  CellText := '';

  if Data^.RowType = rtOrder then
  begin
    if Column = COL_EXPAND then
    begin
      // Expand indicator text
      if (Data^.Order <> nil) and (Data^.Order.Fills.Count > 0) then
      begin
        if Data^.IsExpanded then
          CellText := 'v'
        else
          CellText := '>';
      end;
    end
    else
      CellText := GetOrderCellText(Data^.Order, Column);
  end
  else if Data^.RowType = rtFill then
  begin
    CellText := GetFillCellText(Data^.Order, Data^.Fill, Column);
  end;
end;

procedure TFrmOrderList.vstOrderPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType);
var
  Data: PDisplayRow;
begin
  Data := GetNodeDisplayRow(Node);
  if Data = nil then Exit;

  if Data^.RowType = rtOrder then
  begin
    // Buy/Sell color
    if (Column = COL_SIDE) and (Data^.Order <> nil) then
    begin
      if Data^.Order.Side > 0 then
        TargetCanvas.Font.Color := clRed
      else if Data^.Order.Side < 0 then
        TargetCanvas.Font.Color := clBlue;
    end;
  end;
end;

procedure TFrmOrderList.vstOrderBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data: PDisplayRow;
begin
  if CellPaintMode <> cpmPaint then Exit;

  Data := GetNodeDisplayRow(Node);
  if Data = nil then Exit;

  if Data^.RowType = rtFill then
  begin
    // Fill rows: light gray background
    TargetCanvas.Brush.Color := $00E0E0E0;
    TargetCanvas.FillRect(CellRect);
  end
  else
  begin
    // Zebra striping for order rows
    if Odd(Node^.Index) then
      TargetCanvas.Brush.Color := $00FAFAFA
    else
      TargetCanvas.Brush.Color := clWhite;
    TargetCanvas.FillRect(CellRect);
  end;
end;

procedure TFrmOrderList.vstOrderFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Data: PDisplayRow;
begin
  Data := GetNodeDisplayRow(Node);
  if Data <> nil then
    Finalize(Data^);
end;

//==============================================================================
// Double-click: toggle expand/collapse
//==============================================================================
procedure TFrmOrderList.vstOrderNodeDblClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
var
  Data: PDisplayRow;
  bExpanded: boolean;
begin
  if HitInfo.HitNode = nil then Exit;

  Data := GetNodeDisplayRow(HitInfo.HitNode);
  if Data = nil then Exit;

  if Data^.RowType = rtOrder then
  begin
    if FExpandedOrders.TryGetValue(Data^.Order.OrderNo, bExpanded) then
      FExpandedOrders.AddOrSetValue(Data^.Order.OrderNo, not bExpanded)
    else
      FExpandedOrders.Add(Data^.Order.OrderNo, True);

    UpdateData;
  end;
end;

//==============================================================================
// Mouse down: right-click popup menu
//==============================================================================
procedure TFrmOrderList.vstOrderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  HitInfo: THitInfo;
  Data: PDisplayRow;
  aOrder: TOrder;
begin
  vstOrder.PopupMenu := nil;

  vstOrder.GetHitTestInfoAt(X, Y, True, HitInfo);
  if HitInfo.HitNode = nil then Exit;

  Data := GetNodeDisplayRow(HitInfo.HitNode);
  if Data = nil then Exit;

  if Button = mbRight then
  begin
    if Data^.RowType = rtOrder then
    begin
      aOrder := Data^.Order;
      FOrder := nil;
      if aOrder <> nil then
        if (aOrder.State = osActive) and (not aOrder.Modify) then
        begin
          FOrder := aOrder;
          N4.Visible := True;
          if not aOrder.Modify then
            N1.Visible := True;
          vstOrder.PopupMenu := PopupMenu1;
        end
        else
        begin
          N1.Visible := False;
          FOrder := aOrder;
          vstOrder.PopupMenu := PopupMenu1;
        end;
    end;
  end;
end;

procedure TFrmOrderList.LoadEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
    ComboBox1.ItemIndex := FieldByName('ExKin').AsIntegerDef(0);
    CheckBox1.Checked := FieldByName('CheckBox1').AsBooleanDef(True);
    CheckBox2.Checked := FieldByName('CheckBox2').AsBooleanDef(True);
    CheckBox3.Checked := FieldByName('CheckBox3').AsBooleanDef(False);
    CheckBox4.Checked := FieldByName('CheckBox4').AsBooleanDef(False);

    cbCode.Checked  := FieldByName('cbCode').AsBoolean;
    edtCode.Text    := FieldByName('Code').AsString ;

    FFilterState.SetFromCheckBoxes(
      CheckBox1.Checked, CheckBox2.Checked,
      CheckBox3.Checked, CheckBox4.Checked
    );
  end;
end;


procedure TFrmOrderList.SaveEnv(aStorage: TStorage);
begin
  if aStorage = nil then Exit;

  with aStorage do
  begin
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
  if FOrder = nil then Exit;

  App.Engine.TradeCore.Orders[ FOrder.Account.ExchangeKind].NewCancelOrder( FOrder, FOrder.ActiveQty);
  App.Engine.TradeBroker.Send( FOrder );

end;

procedure TFrmOrderList.N2Click(Sender: TObject);
begin
  if FOrder <> nil then
  begin
    Clipboard.AsText := FOrder.OrderNo;
  end;
end;

procedure TFrmOrderList.N4Click(Sender: TObject);
begin
  if FOrder = nil then Exit;

  App.Engine.ApiManager.ExManagers[FOrder.Symbol.Spec.ExchangeType].RequestOrdeDetail(FOrder);
end;


//==============================================================================
// Get order cell text
//==============================================================================
function TFrmOrderList.GetOrderCellText(aOrder: TOrder; ACol: Integer): string;
var
  sts: TArray<string>;
begin
  Result := '';
  if aOrder = nil then Exit;

  case ACol of
    COL_STRATEGY: begin
      if aOrder.StgType = stSPOrder then
        Result := aOrder.GroupNo
      else if aOrder.StgType in [stPutKipOrder, stPKIdxOrder] then
      begin
        sts := aOrder.GroupNo.Split(['_']);
        if Length(sts) >= 5 then
          Result := sts[3] + '_' + sts[4]
        else
          Result := aOrder.GroupNo;
      end
      else
        Result := aOrder.StgToStr;
    end;
    COL_EXCHANGE: Result := ExKindToStr(aOrder.Account.ExchangeKind);
    COL_SYMBOL: Result := aOrder.Symbol.Spec.BaseCode;
    COL_SIDE: Result := aOrder.SideToStr;
    COL_PRICE: Result := aOrder.Symbol.PriceToStr(aOrder.Price);
    COL_QTY: begin
      if aOrder.Symbol.Spec.ExchangeType = ekBinance then
        Result := aOrder.Symbol.QtyToStr(aOrder.OrderQty)
      else
        Result := aOrder.OrderQtyBI.ToString;
    end;
    COL_AVGPRICE: Result := aOrder.Symbol.PriceToStr(aOrder.AvgPrice);
    COL_FILLEDQTY: Result := Format('%.8n', [aOrder.FilledQty]);
    COL_STATE: Result := aOrder.StateToStr;
    COL_TIME: begin
      if aOrder.State = osRejected then
        Result := FormatDateTime('hh:nn:ss', aOrder.RejectTime)
      else
        Result := FormatDateTime('hh:nn:ss', aOrder.AcptTime);
    end;
    COL_FILLTIME: begin
      if aOrder.Fills.Count > 0 then
        Result := FormatDateTime('hh:nn:ss', aOrder.Fills.Fills[0].FillTime)
      else
        Result := '';
    end;
    COL_ORDERNO: begin
      if aOrder.State = osRejected then
        Result := aOrder.RejectReason
      else
        Result := aOrder.OrderNo;
    end;
  end;
end;

//==============================================================================
// Get fill cell text
//==============================================================================
function TFrmOrderList.GetFillCellText(aOrder: TOrder; aFill: TFill; ACol: Integer): string;
begin
  Result := '';
  if aFill = nil then Exit;

  case ACol of
    COL_AVGPRICE: Result := aFill.Symbol.PriceToStr(aFill.Price);
    COL_FILLEDQTY: Result := Format('%.8n', [aFill.Volume]);
    COL_FILLTIME: Result := FormatDateTime('hh:nn:ss', aFill.FillTime);
    COL_ORDERNO: Result := aFill.FillNo;
  end;
end;

procedure TFrmOrderList.TradeProc(Sender, Receiver: TObject; DataID: Integer;
  DataObj: TObject; EventID: TDistributorID);
begin
  if (Receiver <> Self) or (DataID <> TRD_DATA) then Exit;

  case Integer(EventID) of
    ORDER_ACCEPTED,
    ORDER_REJECTED,
    ORDER_CANCELED,
    ORDER_CHANGED,
    ORDER_FILLED: DoOrder(DataObj as TOrder, EventID);
  end;
end;

//==============================================================================
// Core: order event handler
//==============================================================================
procedure TFrmOrderList.DoOrder(aOrder: TOrder; EventID: TDistributorID);
var
  bExistsInList: Boolean;
  bPassesFilter: Boolean;
  idx: Integer;
  Node: PVirtualNode;

  function FindNodeByIndex(AIndex: Integer): PVirtualNode;
  var
    N: PVirtualNode;
    Cnt: Integer;
  begin
    Result := nil;
    N := vstOrder.GetFirst;
    Cnt := 0;
    while N <> nil do
    begin
      if Cnt = AIndex then
      begin
        Result := N;
        Exit;
      end;
      Inc(Cnt);
      N := vstOrder.GetNext(N);
    end;
  end;

begin
  bExistsInList := FindOrderRowIndex(aOrder) >= 0;
  bPassesFilter := Filter(aOrder);

  case Integer(EventID) of
    ORDER_ACCEPTED:
      if bPassesFilter then
        InsertOrderToTop(aOrder);

    ORDER_FILLED, ORDER_CHANGED:
      begin
        if bExistsInList then
        begin
          if bPassesFilter then
          begin
            idx := FindOrderRowIndex(aOrder);
            if idx >= 0 then
            begin
              Node := FindNodeByIndex(idx);
              if Node <> nil then
                vstOrder.InvalidateNode(Node)
              else
                vstOrder.Invalidate;
            end;
          end
          else
            HandleOrderRemoval(aOrder);
        end
        else if bPassesFilter then
          InsertOrderToTop(aOrder);
      end;

    ORDER_CANCELED, ORDER_REJECTED:
      begin
        if bExistsInList then
        begin
          if bPassesFilter then
          begin
            idx := FindOrderRowIndex(aOrder);
            if idx >= 0 then
            begin
              Node := FindNodeByIndex(idx);
              if Node <> nil then
                vstOrder.InvalidateNode(Node)
              else
                vstOrder.Invalidate;
            end;
          end
          else
            HandleOrderRemoval(aOrder);
        end
        else if bPassesFilter then
          InsertOrderToTop(aOrder);
      end;
  end;
end;

//==============================================================================
// Insert new order to top of list
//==============================================================================
procedure TFrmOrderList.InsertOrderToTop(aOrder: TOrder);
begin
  if FindOrderRowIndex(aOrder) >= 0 then
  begin
    vstOrder.Invalidate;
    Exit;
  end;

  // Full rebuild via UpdateData (keeps FDisplayList and VST nodes in sync)
  UpdateData;
end;

//==============================================================================
// Handle order removal from list
//==============================================================================
procedure TFrmOrderList.HandleOrderRemoval(aOrder: TOrder);
begin
  // Full rebuild via UpdateData (removes order and refills)
  UpdateData;
end;

//==============================================================================
// Fill empty slots from next orders
//==============================================================================
procedure TFrmOrderList.FillFromNextOrders;
var
  aOrder: TOrder;
  row: TDisplayRow;
  bExpanded: Boolean;
  j: Integer;
begin
  while (FDisplayList.Count < NEXT_ROW_CNT) and (FIndex >= 0) do
  begin
    while FIndex >= 0 do
    begin
      aOrder := App.Engine.TradeCore.TotalOrders.Orders[FIndex];
      Dec(FIndex);

      if (aOrder <> nil) and Filter(aOrder) then
      begin
        if FindOrderRowIndex(aOrder) < 0 then
        begin
          bExpanded := FExpandedOrders.TryGetValue(aOrder.OrderNo, bExpanded) and bExpanded;

          row.RowType := rtOrder;
          row.Order := aOrder;
          row.Fill := nil;
          row.IsExpanded := bExpanded;
          FDisplayList.Add(row);

          if bExpanded then
          begin
            for j := 0 to aOrder.Fills.Count - 1 do
            begin
              row.RowType := rtFill;
              row.Order := aOrder;
              row.Fill := aOrder.Fills.Fills[j];
              row.IsExpanded := False;
              FDisplayList.Add(row);
            end;
          end;

          Break;
        end;
      end;
    end;
  end;
end;

//==============================================================================
// Find order index in display list (-1 if not found)
//==============================================================================
function TFrmOrderList.FindOrderRowIndex(aOrder: TOrder): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FDisplayList.Count - 1 do
  begin
    if (FDisplayList[i].RowType = rtOrder) and
       (FDisplayList[i].Order = aOrder) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

//==============================================================================
// Refresh order in list
//==============================================================================
procedure TFrmOrderList.RefreshOrderInList(aOrder: TOrder);
begin
  // Simply invalidate the whole tree for a refresh
  vstOrder.Invalidate;
end;

procedure TFrmOrderList.edtCodeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if not cbCode.Checked then Exit;
    if edtCode.Text = '' then Exit;
    UpdateData;
  end;
end;

procedure TFrmOrderList.btnNextClick(Sender: TObject);
begin
  UpdateDataNext;
end;

procedure TFrmOrderList.cbCodeClick(Sender: TObject);
begin
  UpdateData;
end;

procedure TFrmOrderList.CheckBox1Click(Sender: TObject);
var
  iTag: integer;
begin
  iTag := TCheckBox(Sender).Tag;

  case iTag of
    0: FFilterState.ShowActive := TCheckBox(Sender).Checked;
    1: FFilterState.ShowFilled := TCheckBox(Sender).Checked;
    2: FFilterState.ShowCanceled := TCheckBox(Sender).Checked;
    3: FFilterState.ShowRejected := TCheckBox(Sender).Checked;
    4: FFilterState.ShowPending := TCheckBox(Sender).Checked;
  end;

  UpdateData;
end;

procedure TFrmOrderList.ComboBox1Change(Sender: TObject);
begin
  FExIndex := ComboBox1.ItemIndex;
  UpdateData;
end;

procedure TFrmOrderList.ComboBox2Change(Sender: TObject);
begin
  // Reserved
end;

//==============================================================================
// Filter
//==============================================================================
function TFrmOrderList.Filter(aOrder: TOrder): boolean;
begin
  case FExIndex of
    0: Result := True;
    else Result := aOrder.Account.ExchangeKind = TExchangeKind(FExIndex - 1);
  end;
  if not Result then Exit;

  if cbCode.Checked then
    if UpperCase(aOrder.Symbol.Spec.BaseCode) <> UpperCase(edtCode.Text) then
      Exit(False);

  case aOrder.State of
    osReady, osSent, osSrvAcpt: Result := FFilterState.ShowPending;
    osSrvRjt, osFailed, osRejected: Result := FFilterState.ShowRejected;
    osActive: Result := FFilterState.ShowActive;
    osFilled: Result := FFilterState.ShowFilled;
    osCanceled: Result := FFilterState.ShowCanceled;
  end;
end;


procedure TFrmOrderList.UpdateData;
begin
  CleanupExpandedOrders;

  if App.Engine.TradeCore.TotalOrders.Count > 0 then
    DoUpdateList(App.Engine.TradeCore.TotalOrders.Count - 1)
  else
    DoUpdateList(0);
end;

procedure TFrmOrderList.DoUpdateList(aStartIndex: Integer);
var
  aOrder: TOrder;
  i, j: integer;
  row: TDisplayRow;
  bExpanded: boolean;
  Node: PVirtualNode;
  Data: PDisplayRow;
begin
  vstOrder.BeginUpdate;
  try
    vstOrder.Clear;
    FDisplayList.Clear;

    FIndex := -1;

    if aStartIndex >= App.Engine.TradeCore.TotalOrders.Count then
      aStartIndex := App.Engine.TradeCore.TotalOrders.Count - 1;

    for i := aStartIndex downto 0 do
    begin
      aOrder := App.Engine.TradeCore.TotalOrders.Orders[i];
      if aOrder = nil then Continue;
      if not Filter(aOrder) then Continue;

      bExpanded := FExpandedOrders.TryGetValue(aOrder.OrderNo, bExpanded) and bExpanded;

      // Add Order Row
      row.RowType := rtOrder;
      row.Order := aOrder;
      row.Fill := nil;
      row.IsExpanded := bExpanded;
      FDisplayList.Add(row);

      Node := vstOrder.AddChild(nil);
      Data := GetNodeDisplayRow(Node);
      Data^ := row;

      // Add Fill Rows if expanded
      if bExpanded then
      begin
        for j := 0 to aOrder.Fills.Count - 1 do
        begin
          row.RowType := rtFill;
          row.Order := aOrder;
          row.Fill := aOrder.Fills.Fills[j];
          row.IsExpanded := False;
          FDisplayList.Add(row);

          Node := vstOrder.AddChild(nil);
          Data := GetNodeDisplayRow(Node);
          Data^ := row;
        end;
      end;

      // Pagination limit
      if FDisplayList.Count >= NEXT_ROW_CNT then
      begin
        FIndex := i - 1;
        Break;
      end;
    end;

  finally
    vstOrder.EndUpdate;
  end;

  btnNext.Enabled := (FIndex >= 0);
end;

procedure TFrmOrderList.UpdateDataNext;
begin
  if FIndex >= 0 then
    DoUpdateList(FIndex);
end;

//==============================================================================
// Memory cleanup: remove expanded state for non-existent orders
//==============================================================================
procedure TFrmOrderList.CleanupExpandedOrders;
var
  KeysToRemove: TList<string>;
  Key: string;
  Found: Boolean;
  i: Integer;
begin
  KeysToRemove := TList<string>.Create;
  try
    for Key in FExpandedOrders.Keys do
    begin
      Found := False;
      for i := 0 to App.Engine.TradeCore.TotalOrders.Count - 1 do
      begin
        if App.Engine.TradeCore.TotalOrders.Orders[i].OrderNo = Key then
        begin
          Found := True;
          Break;
        end;
      end;

      if not Found then
        KeysToRemove.Add(Key);
    end;

    for Key in KeysToRemove do
      FExpandedOrders.Remove(Key);
  finally
    KeysToRemove.Free;
  end;
end;

end.
