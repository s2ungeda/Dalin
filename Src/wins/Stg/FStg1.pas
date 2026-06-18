unit FStg1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TFrmStg1 = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmStg1: TFrmStg1;

implementation

{$R *.dfm}


procedure TFrmStg1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
