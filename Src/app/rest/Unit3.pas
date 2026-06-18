unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  REST.Types, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope,

  USharedThread, UApiTypes
  ;

type
  TForm2 = class(TForm)
    m: TMemo;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTClient2: TRESTClient;
    RESTRequest2: TRESTRequest;
    RESTResponse2: TRESTResponse;
    RESTClient3: TRESTClient;
    RESTRequest3: TRESTRequest;
    RESTResponse3: TRESTResponse;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private

    { Private declarations }
  public
    { Public declarations }
    mt : TSharedThread;
    procedure OnNotify(const S: string);
  end;

var
  Form2: TForm2;

implementation

uses
  system.IniFiles
  , GApp
  , GLibs


  ;

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
begin
  mt := TSharedThread.Create( OnNotify );
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  mt.Terminate;
end;

procedure TForm2.OnNotify(const S: string);
begin
  m.Lines.Add( Copy(s, 1, 100 ) );
end;




end.
