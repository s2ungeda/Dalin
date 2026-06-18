unit FAccountDnwConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls,

  UApiTypes
  ;

type

  TFrmAccountDnwConfig = class(TForm)
    sg: TStringGrid;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure sgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
    Limits  : TAccountDnwLimit;
    function Open: boolean;
  end;

var
  FrmAccountDnwConfig: TFrmAccountDnwConfig;

implementation

uses
  GApp, Glibs
  ;

{$R *.dfm}

procedure TFrmAccountDnwConfig.Button1Click(Sender: TObject);
var
  I,  j: Integer;
  k : TExchangeKind;
begin
  //
  with sg do
    for I := 1 to 2 do
      for j := 1 to 2 do
        if Cells[j, i] = '' then
        begin
          ShowMessage('입력값이 잘못됨');
          Exit;
        end;

  with App.Engine.ApiConfig.DnwLimit do
  begin
    DepositLimit[ekUpbit] := StrToInt(sg.Cells[1, 1]);
    WidthDrawLimit[ekUpbit] := StrToInt(sg.Cells[2, 1]);

    DepositLimit[ekBithumb] := StrToINt(sg.Cells[1, 2]);
    WidthDrawLimit[ekBithumb] := StrToInt(sg.Cells[2, 2]);
  end;

  ModalResult := mrOK;
end;

procedure TFrmAccountDnwConfig.Button2Click(Sender: TObject);
begin
  //
  ModalResult := mrCancel;
end;

procedure TFrmAccountDnwConfig.FormCreate(Sender: TObject);
begin
  with sg do
  begin
    Cells[0, 0] := '1일';
    Cells[0, 1] := '업비트';
    Cells[0, 2] := '빗썸';

    Cells[1, 0] := '원화입금한도';
    Cells[2, 0] := '원화출금한도';
  end;
end;

function TFrmAccountDnwConfig.Open: boolean;
begin

  with sg do
  begin
    Cells[1, 1] := App.Engine.ApiConfig.DnwLimit.DepositLimit[ekUpbit].ToString;
    Cells[2, 1] := App.Engine.ApiConfig.DnwLimit.WidthDrawLimit[ekUpbit].ToString;

    Cells[1, 2] := App.Engine.ApiConfig.DnwLimit.DepositLimit[ekBithumb].ToString;
    Cells[2, 2] := App.Engine.ApiConfig.DnwLimit.WidthDrawLimit[ekBithumb].ToString;
  end;

  Result := ShowModal = mrOK;
end;

procedure TFrmAccountDnwConfig.sgKeyPress(Sender: TObject; var Key: Char);
begin
  if not (CharInSet(Key , ['0'..'9','.',#8])) then
    Key := #0;
end;

procedure TFrmAccountDnwConfig.sgMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
    aCol, aRow : integer;
begin
  TStringGrid(Sender).MouseToCell( X, Y, aCol, aRow);

  with TStringGrid(Sender) do
    if  ( aRow > 0 ) and ( aCol > 0 ) then
    begin
      Options     := Options + [ goEditing ];
      EditorMode  := true;
    end else begin
      EditorMode  := true;
      Options     := Options - [ goEditing ];
    end;
end;

end.
