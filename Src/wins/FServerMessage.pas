unit FServerMessage;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, CommCtrl,
  Dialogs, ComCtrls,

  UTypes, Vcl.StdCtrls, Vcl.ExtCtrls
  ;

type
  TFrmServerMessage = class(TForm)
    lvLog: TListView;
    Panel1: TPanel;
    Button1: TButton;
    cbAddLog: TCheckBox;
    procedure lvLogDrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FLogCount : array [ TLogLevel ] of integer;
    procedure UpdateLog(iKind: integer; bNew: boolean = false );
    { Private declarations }
  public
    { Public declarations }
    procedure WMALogArrived(var msg: TMessage); message WM_LOGARRIVED;
  end;

var
  FrmServerMessage: TFrmServerMessage;

implementation

uses
  GApp
  , UConsts
  , ULogThread
  ;


{$R *.dfm}

procedure TFrmServerMessage.Button1Click(Sender: TObject);
begin
  lvLog.Items.Clear;
  lvLog.Clear;
end;

procedure TFrmServerMessage.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TFrmServerMessage.FormCreate(Sender: TObject);
var
  I: TLogLevel;
begin
  for I := llError to High(TLogLevel) do
    FLogCount[i] := 0;
end;

procedure TFrmServerMessage.lvLogDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  i, iX, iY, iLeft : Integer;
  aSize : TSize;
  ListView : TListView;
begin

  if (Item.Data = nil) then Exit;
  //
  Rect.Bottom := Rect.Bottom-1;       ;
  ListView := Sender as TListView;
  //
  with ListView.Canvas do
  begin
    //-- color
    if (odSelected in State) {or (odFocused in State)} then
    begin
      Brush.Color := SELECTED_COLOR;
      Font.Color := clBlack;
    end else
    begin
      Font.Color := clBlack;
      if Item.Index mod 2 = 1 then
        Brush.Color := EVEN_COLOR
      else
        Brush.Color := ODD_COLOR;
    end;
    //-- background
    FillRect(Rect);
    //-- icon
    aSize := TextExtent('9');
    iY := Rect.Top + (Rect.Bottom - Rect.Top - aSize.cy) div 2;
    if (Item.ImageIndex >=0) and (ListView.SmallImages <> nil) then
    begin
      // aListView.SmallImages.BkColor := Brush.Color;
      ListView.SmallImages.Draw(ListView.Canvas, Rect.Left+1, Rect.Top,
                              Item.ImageIndex);
    end;
    //-- caption
    if Item.Caption <> '' then
        TextRect(
            Classes.Rect(0,
              Rect.Top, ListView_GetColumnWidth(ListView.Handle,0), Rect.Bottom),
            Rect.Left + 2, iY, Item.Caption);
    //-- subitems
    iLeft := Rect.Left;
    for i:=0 to Item.SubItems.Count-1 do
    begin
      if i+1 >= ListView.Columns.Count then Break;
      iLeft := iLeft + ListView_GetColumnWidth(ListView.Handle,i);

      if Item.SubItems[i] = '' then Continue;
      aSize := TextExtent(Item.SubItems[i]);

      case ListView.Columns[i+1].Alignment of
        taLeftJustify :  iX := iLeft + 2;
        taCenter :       iX := iLeft +
             (ListView_GetColumnWidth(ListView.Handle,i+1)-aSize.cx) div 2;
        taRightJustify : iX := iLeft +
              ListView_GetColumnWidth(ListView.Handle,i+1) - 2 - aSize.cx;
        else iX := iLeft + 2; // redundant coding
      end;
      TextRect(
          Classes.Rect(iLeft, Rect.Top,
             iLeft + ListView_GetColumnWidth(ListView.Handle,i+1), Rect.Bottom),
          iX, iY, Item.SubItems[i]);
    end;
  end;

end;

procedure TFrmServerMessage.WMALogArrived(var msg: TMessage);
begin
  if cbAddLog.Checked then
    UpdateLog( msg.WParam )
  else begin
    var aKind : TLogLevel;
    var iCnt : integer;
    aKind := TLogLevel( msg.WParam );
    iCnt := App.LogItems[ aKind ].Count - FLogCount[aKind];
  end;

end;

procedure TFrmServerMessage.UpdateLog( iKind : integer; bNew : boolean);
var
  i : integer;
  aItem : TAppLogItem;
  aList : TListItem;
  aKind : TLogLevel;
begin

  if App = nil then Exit;

  aKind := TLogLevel( iKind );

  if bNew then
  begin
    //lvLog.Items.Clear;
    lvLog.Items.Count := App.LogItems[ aKind ].Count;
    lvLog.Invalidate;
  end else
  begin

    var iCnt : integer;
    iCnt := App.LogItems[ aKind ].Count - FLogCount[aKind];

    if iCnt >= 0 then
      for I := iCnt-1 downto 0 do
      begin

        aItem := App.LogItems[ aKind ].LogItem[i];
        if aItem = nil then continue;// Exit;

        aList := lvLog.Items.Insert(0);

        aList.Data  := aItem;
        aList.Caption := FormatDateTime( 'mm-dd hh:nn:ss', aItem.LogTime );

        aList.SubItems.Add( aItem.LogTitle );
        aList.SubItems.Add( aItem.LogDesc );

        inc(FLogCount[aKind]);
      end;

    lvLog.Refresh;
  end;

  if lvLog.Items.Count > 0 then
  begin
    lvLog.Selected := lvLog.Items[0];
    lvLog.ItemFocused := lvLog.Items[0];
  end;

end;


end.
