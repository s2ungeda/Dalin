unit FApiKeyMngr;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
//  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,
  Vcl.ComCtrls, UEncrypts, USecureString
  ;

const
  DEFAULT_STR = 'sauri';
  APK_FILE = 'dalin.apk';
  APK_DIR  = 'Data';
  KEYPAIR_CNT = 5;
  KEYPAIR_NAME : array [0..KEYPAIR_CNT-1] of string =
  ('BNS', 'BNF', 'UPS', 'BT1', 'BT2');

  STR_DUMMY = 'abcdefghijklmnopqrstuvwxyz';

type

  TApiKeyPair = record
    Name: string;
    ApiKey : string;
    SecKey : string;

    function GetApiKey: string;
    function GetSecKey: string;
  end;

  TFrmApiKeyMngr = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Button2: TButton;
    Panel2: TPanel;
    Panel1: TPanel;
    bnApiKey: TLabeledEdit;
    bnSecKey: TLabeledEdit;
    Button1: TButton;
    Panel3: TPanel;
    Panel4: TPanel;
    bnFutApiKey: TLabeledEdit;
    bnFutSecKey: TLabeledEdit;
    Button6: TButton;
    Panel7: TPanel;
    Panel8: TPanel;
    upApiKey: TLabeledEdit;
    upSecKey: TLabeledEdit;
    Button3: TButton;
    Panel9: TPanel;
    btApiKey2: TLabeledEdit;
    btSecKey2: TLabeledEdit;
    Button4: TButton;
    Panel11: TPanel;
    Panel12: TPanel;
    btApiKey1: TLabeledEdit;
    btSecKey1: TLabeledEdit;
    Button5: TButton;
    Panel10: TPanel;
    Button7: TButton;
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FKeyPairs : array of TApiKeyPair;
    FSecKeys  : array of TSecureString;
    FSecStr: TSecureString;

    function LoadKey: boolean;
    function SaveApiKey: boolean;
    function CheckInput: boolean;

    procedure ClearInput;
    procedure SetSecStr;

  public
    { Public declarations }
    property SecStr: TSecureString read FSecStr;
  end;

var
  FrmApiKeyMngr: TFrmApiKeyMngr;

implementation

uses
  System.IniFiles
  , System.StrUtils
  , FInputEntropy

  ;

{$R *.dfm}

// 저장
procedure TFrmApiKeyMngr.Button2Click(Sender: TObject);
begin

  if not CheckInput then
  begin
    ShowMessage('Api/sec key 를 입력하세요');
    Exit;
  end;

  SetSecStr;

  if FSecStr.IsEmpty then
  begin
    ShowMessage('Entropy 를 입력하세요');
    Exit;
  end;

  if MessageDlg('각 거래소 API/Sec Key 를 저장하시겠습니까?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if not SaveApiKey then //SaveKey then
      ShowMessage('API KEY 저장에 실패했습니다.');
  end;
end;

procedure TFrmApiKeyMngr.Button5Click(Sender: TObject);
var
  aEdit : TLabeledEdit;
  i : Integer;
begin


  if FSecStr.IsEmpty then
  begin
    ShowMessage('Entropy 를 입력하세요');
    Exit;
  end;

  case (Sender as TComponent).Tag of
    0 : aEdit := bnSecKey;
    1 : aEdit := bnFutSecKey;
    2 : aEdit := upSecKey;
    3 : aEdit := btSecKey1;
    4 : aEdit := btSecKey2;
  end;

  if aEdit.PasswordChar = #0 then begin
    aEdit.PasswordChar := '*';
//    aEdit.Text  := STR_DUMMY;
  end
  else begin
    aEdit.PasswordChar := #0;
//    aEdit.Text := '';
//
//    var s := FSecKeys[(Sender as TComponent).Tag].Reveal;
//
//    for I := 1 to Length(s) do
//      if i > 10 then
//        aEdit.Text  := aEdit.Text + '*'
//      else
//        aEdit.Text  := aEdit.Text + s[i];
  end;

end;

// 로드
procedure TFrmApiKeyMngr.Button7Click(Sender: TObject);
begin
  SetSecStr;

  if FSecStr.IsEmpty then
  begin
    ShowMessage('Entropy 를 입력하세요');
    ClearInput;
    Exit;
  end;

  if not LoadKey then
    ShowMessage('API KEY 읽어오기 실패 !!');
end;

function TFrmApiKeyMngr.CheckInput: boolean;
begin
  Result := false;
  if bnApiKey.Text = '' then Exit;
  if bnSecKey.Text = '' then Exit;
  if bnFutApiKey.Text = '' then Exit;
  if bnFutSecKey.Text = '' then Exit;
  if upApiKey.Text  = '' then Exit;
  if upSecKey.Text  = '' then Exit;
  if btApiKey2.Text = '' then Exit;
  if btSecKey2.Text = '' then Exit;
  if btApiKey1.Text = '' then Exit;
  if btSecKey1.Text = '' then Exit;
  Result := true;
end;

procedure TFrmApiKeyMngr.ClearInput;
begin
  bnApiKey.Text  := '';
  bnSecKey.Text  := '';
  bnFutApiKey.Text := '';
  bnFutSecKey.Text := '';
  upApiKey.Text  := '';
  upSecKey.Text  := '';
  btApiKey2.Text := '';
  btSecKey2.Text := '';
  btApiKey1.Text := '';
  btSecKey1.Text := '';
end;


procedure TFrmApiKeyMngr.SetSecStr;
var
  aF : TFrmInputEntropy;
begin
  FSecStr.Clear;
  aF := TFrmInputEntropy.Create(Self);
  try
    if aF.Open(true) then
      FSecStr.Assign(aF.edtInput.Text);
  finally
    aF.Free;
  end;
end;

procedure TFrmApiKeyMngr.FormCreate(Sender: TObject);
var
  i : Integer;
  aF : TFrmInputEntropy;
begin
  FSecStr:= TSecureString.Create;
//  aF := TFrmInputEntropy.Create(Self);
//  try
//    if aF.Open(true) then
//      FSecStr.Assign(aF.edtInput.Text);
//  finally
//    aF.Free;
//  end;

  //  key load
  SetLength(FKeyPairs, KEYPAIR_CNT);
  SetLength(FSecKeys,  KEYPAIR_CNT);

  for I := 0 to High(FKeyPairs) do  begin
    FKeyPairs[i].Name :=  KEYPAIR_NAME[i];
    FSecKeys[i] := TSecureString.Create;
  end;

  //Button7Click(nil);

end;

procedure TFrmApiKeyMngr.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  FSecStr.Free;

  for I := 0 to High(FSecKeys) do
    FSecKeys[i].Free;

  SetLength(FKeyPairs, 0);
  SetLength(FSecKeys, 0);
end;

function TFrmApiKeyMngr.LoadKey: boolean;
var
  stEx, stDiv, stKey, stDir: string;
  KeyArr : TArray<string>;
  I: Integer;
  j: Integer;
begin
  stDir := ExtractFilePath( paramstr(0) )+APK_DIR+'\'+APK_FILE;
  if not FileExists(stDir) then Exit;

  if not LoadEncryptedKeyFromFile(stDir, FSecStr, KeyArr) then
  begin
    ShowMessage('로드실패');
    Exit;
  end;

  for I := 0 to High(KeyArr) do
  begin
    if KeyArr[i].IsEmpty then continue;

    stKey:= KeyArr[i];

    stEx := LeftStr(stKey, 3);
    stDiv:= MidStr(stKey, 4, 3);

    for j := 0 to High(FKeyPairs) do
    begin
      if FKeyPairs[j].Name = stEx then
      begin
        if stDiv = 'API' then
          FKeyPairs[j].ApiKey := Copy(stKey, 7, Length(stKey))
        else if stDiv = 'SEC' then
          FKeyPairs[j].SecKey := Copy(stKey, 7, Length(stKey));
        break;
      end;
    end;
  end;

  try
    /////////////////////////////////////////////////////////////
    ///
    bnApiKey.Text :=  FKeyPairs[0].ApiKey;
    bnSecKey.Text :=  FKeyPairs[0].SecKey;

    bnFutApiKey.Text :=  FKeyPairs[1].ApiKey;
    bnFutSecKey.Text :=  FKeyPairs[1].SecKey;

    upApiKey.Text :=  FKeyPairs[2].ApiKey;
    upSecKey.Text :=  FKeyPairs[2].SecKey;

    btApiKey1.Text :=  FKeyPairs[3].ApiKey;
    btSecKey1.Text :=  FKeyPairs[3].SecKey;

    btApiKey2.Text :=  FKeyPairs[4].ApiKey;
    btSecKey2.Text :=  FKeyPairs[4].SecKey;

    for I := 0 to High(FKeyPairs) do
      FSecKeys[i].Assign(FKeyPairs[i].SecKey);

    Result  := true;

  except
  end;

end;

function TFrmApiKeyMngr.SaveApiKey: boolean;
var StrArr: TArray<string>;
  FileName: string;
  I, J: Integer;
begin
  SetLength(StrArr, 10);

  FKeyPairs[0].Name   := 'BNS';
  FKeyPairs[0].ApiKey := bnApiKey.Text;
  FKeyPairs[0].SecKey := bnSecKey.Text;

  FKeyPairs[1].Name   := 'BNF';
  FKeyPairs[1].ApiKey := bnFutApiKey.Text;
  FKeyPairs[1].SecKey := bnFutSecKey.Text;

  FKeyPairs[2].Name   := 'UPS';
  FKeyPairs[2].ApiKey := upApiKey.Text;
  FKeyPairs[2].SecKey := upSecKey.Text;

  FKeyPairs[3].Name   := 'BT1';
  FKeyPairs[3].ApiKey := btApiKey1.Text;
  FKeyPairs[3].SecKey := btSecKey1.Text;

  FKeyPairs[4].Name   := 'BT2';
  FKeyPairs[4].ApiKey := btApiKey2.Text;
  FKeyPairs[4].SecKey := btSecKey2.Text;

  j := 0;
  for I := 0 to High(FKeyPairs) do
  begin
    StrArr[j] := FKeyPairs[I].GetApiKey;   inc(j);
    StrArr[j] := FKeyPairs[i].GetSecKey;   inc(j);
  end;

  FileName := ExtractFilePath( paramstr(0) )+APK_DIR+'\'+APK_FILE;
  Result := SaveEncryptedKeyToFile(FileName, FSecStr, StrArr);
end;


{ TApiKeyPair }

function TApiKeyPair.GetApiKey: string;
begin
  Result := Name+'API'+ApiKey;
end;

function TApiKeyPair.GetSecKey: string;
begin
  Result := Name+'SEC'+SecKey;
end;

end.
