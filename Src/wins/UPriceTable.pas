unit UPriceTable;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.Grids, Vcl.ValEdit, Vcl.CategoryButtons;
type
  TFrmPriceTable = class(TForm)
    plRight: TPanel;
    StatusBar1: TStatusBar;
    plLeft: TPanel;
    plLeftTop: TPanel;
    plLeftClient: TPanel;
    plRightTop: TPanel;
    plRightClient: TPanel;
    Splitter1: TSplitter;
    plLeftClientTop: TPanel;
    Splitter2: TSplitter;
    plLeftClientClient: TPanel;
    SpeedButtonRightPanel: TSpeedButton;
    sgKimp: TStringGrid;
    sgInOut: TStringGrid;
    sgQuote: TStringGrid;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    procedure initControls;
  public
    { Public declarations }
  end;
var
  FrmPriceTable: TFrmPriceTable;
implementation
{$R *.dfm}
uses
  UTableConsts
  ;
{ TFrmPriceTable }



procedure TFrmPriceTable.FormCreate(Sender: TObject);
begin
  initControls;
end;

procedure TFrmPriceTable.initControls;
var
  i : integer;
begin

  for I := 0 to prcTbl1_TitleCnt - 1 do
  begin
    sgKimp.Cells[i,0] := prcTbll1_Title[i];
    sgInOut.Cells[i,0]:= prcTbll1_Title[i];
  end;

  for I := 0 to prcTbl2_TitleCnt - 1 do
  begin
    sgQuote.Cells[i,0] := prcTbll2_Title[i];

  end;

end;

procedure TFrmPriceTable.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmPriceTable.FormDestroy(Sender: TObject);
begin
  //
end;

end.
