unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, Vcl.ComCtrls
  , system.JSON, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, Vcl.ExtCtrls
  ;

const
  WM_DOWNCOMPLETED = WM_USER + $0001;

type

  TUpdateFile = class(TCollectionItem)
  public
    name : string;
    version : string;
    path : string;
  end;

  TFrmMKPUpdater = class(TForm)
    pb: TProgressBar;
    http: TNetHTTPClient;
    Label1: TLabel;
    upTimer: TTimer;
    ListBox1: TListBox;
    Button1: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure httpReceiveData(const Sender: TObject; AContentLength,
      AReadCount: Int64; var AAbort: Boolean);
    procedure httpRequestCompleted(const Sender: TObject;
      const AResponse: IHTTPResponse);
    procedure FormCreate(Sender: TObject);
    procedure upTimerTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    FUrl : string;
    FAppDir : string;
    RemoteFiles, LocalFiles : TCollection;
    DownList  : TStringList;

    procedure AddFile(aFile: TUpdateFile);
    procedure CompareVersion;
    procedure DownLoadFiles;
    procedure ExecuteDalin;

    function DownloadUpdateFile(FileURL, SavePath: string): boolean;

    procedure MoveFiles;

    procedure ReadMyVersion;
    procedure ReadFiles(sFileName: string; aColl: TCollection);
    procedure ReadRemoteVersion;

    procedure SaveUpdateFileVersion;
    procedure UpdateLocalFileVersion(aFile: TUpdateFile);

    { Private declarations }
  public
    { Public declarations }
    procedure WMDowncompleted(var msg: TMessage); message WM_DOWNCOMPLETED;
  end;

var
  FrmMKPUpdater: TFrmMKPUpdater;

implementation

uses
  System.IOUtils, ShellApi
  ;

{$R *.dfm}

procedure TFrmMKPUpdater.AddFile(aFile: TUpdateFile);
begin
  DownList.AddObject(aFile.name, aFile);
//    Format('%s/updates/files/%s/%s', [aFile.path, aFile.name]), aFile

end;

procedure TFrmMKPUpdater.DownLoadFiles;
var
  I: Integer;
  aFile, bFile: TUpdateFile;
  bOK : boolean;
  s: string;
begin

  bOK:= false;
  if not DirectoryExists('C:\DownTemp') then CreateDir('C:\DownTemp');

  try
    try
      for I := 0 to DownList.Count-1 do
      begin
        aFile := TUpdateFile(DownList.Objects[i]);
        if DownloadUpdateFile(
          FUrl+Format('/updates/files%s%s',[aFile.path, aFile.name]),
          Format('C:\DownTemp\%s',[aFile.name])) then
        // 다운받은 파일 버전 업데이트.
          UpdateLocalFileVersion(aFile);
      end;
      bOK := true;
    except
      if aFile <> nil then
        s := aFile.name;
      Exit;
    end;


  finally
    if bOK then
      PostMessage(Handle, WM_DOWNCOMPLETED, 0, 0)
    else
      ShowMessage('업데이트 도중 에러 발생 : ' + s);
  end;

end;

function TFrmMKPUpdater.DownloadUpdateFile(FileURL, SavePath: string): boolean;
var
  IdHTTP: TIdHTTP;
  FileStream: TFileStream;
begin

  Result := false;
  FileStream := TFileStream.Create(SavePath, fmCreate);
  try
    try
      http.Get(FileURL, FileStream);
      Result := true;
    except
      on E: Exception do
        ShowMessage('업데이트 파일 다운로드 중 오류 발생: ' + E.Message);
    end;
  finally
    FileStream.Free;
  end;
end;

procedure TFrmMKPUpdater.ExecuteDalin;
begin
  ShellExecute(Application.Handle, nil, PChar(ExtractFilePath(Application.ExeName)+'\Dalin.exe'),
    nil, nil, SW_SHOW);
end;

procedure TFrmMKPUpdater.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmMKPUpdater.FormCreate(Sender: TObject);
begin
  FUrl    := 'https://www.moonkomp.com';
  FAppDir := ExtractFilePath(paramStr(0)) ;
  LocalFiles := TCollection.Create(TUpdateFile);
  RemoteFiles:= TCollection.Create(TUpdateFile);
  DownList   := TStringList.Create;
  // 1. 내가 가지고 있는 파일 버전을 읽는다.
  ReadMyVersion;

  ReadRemoteVersion;

  CompareVersion;

  if DownList.Count <= 0 then
    ExecuteDalin
  else
    if MessageDlg('새로운 버전의 파일을 업데이트 하시겠습니까?', mtInformation, [mbYes, mbNo], 0) = mrYes then
      upTimer.Enabled := true
    else
      ExecuteDalin;
end;

procedure TFrmMKPUpdater.FormDestroy(Sender: TObject);
begin
  DownList.Free;
  LocalFiles.Free;
  RemoteFiles.Free;
end;


procedure TFrmMKPUpdater.Button1Click(Sender: TObject);
begin
  close;
end;

procedure TFrmMKPUpdater.CompareVersion;
var
  I, j: Integer;
  rf, lf: TUpdateFile;
  bFind: boolean;
begin
  if RemoteFiles.Count <= 0 then Exit;

  for I := 0 to RemoteFiles.Count -1 do
  begin
    rf := TUpdateFile(RemoteFiles.Items[i]);
    bFind := false;
    for j := 0 to LocalFiles.Count-1 do
    begin
      lf := TUpdateFile(LocalFiles.Items[j]);
      if rf.name = lf.name then
      begin
        bFind := true;
        if rf.version <> lf.version then begin
          AddFile(rf);
        end;
        break;
      end;
    end;

    if not bFind then
      AddFile(rf);
  end;


end;

procedure TFrmMKPUpdater.ReadRemoteVersion;
begin
  DownloadUpdateFile(FUrl+'/updates/files.lsg', 'c:\files.lsg');
  ReadFiles('c:\files.lsg', RemoteFiles);
end;

procedure TFrmMKPUpdater.SaveUpdateFileVersion;
var
  aFile: TUpdateFile;
  i : integer;
  sFileName, sData: string;
  f: TextFile;
begin

  sFileName := FAppDir + 'update.lsg';

  try
    AssignFile(f, sFileName);
    Rewrite(f);
    try
      for I := 0 to LocalFiles.Count-1 do
      begin
        aFile := LocalFiles.Items[i] as TUpdateFile;
        sData := Format('%s:%s:%s', [aFile.name, aFile.version, aFile.path]);
        Writeln(f, sData);
      end;

    finally
      CloseFile(f);
    end;

  except
  end;

end;

procedure TFrmMKPUpdater.UpdateLocalFileVersion(aFile: TUpdateFile);
var
  i: integer;
  lFile: TUpdateFile;
  bFind : boolean;
begin
  //
  bFind := false;
  for I := 0 to LocalFiles.Count-1 do
  begin
    lFile := LocalFiles.Items[i] as TUpdateFile;
    if lFile.name = aFile.name then
    begin
      bFind:= true;
      lFile.version := aFile.version;
      lFile.path    := aFile.path;
      break;
    end;
  end;

  if not bFind then
  begin
    lFile := LocalFiles.Add as TUpdateFile;
    lFile.name  := aFile.name;
    lFile.version := aFile.version;
    lFile.path  := aFile.path;
  end;

end;

procedure TFrmMKPUpdater.upTimerTimer(Sender: TObject);
begin
  //
  upTimer.Enabled := false;
  DownLoadFiles;
end;

procedure TFrmMKPUpdater.WMDowncompleted(var msg: TMessage);
var
  f: TextFile;
begin
  // 다운완료
  // 파일 이동 , 메인창 띄우기
  MoveFiles;

  SaveUpdateFileVersion;
end;

procedure TFrmMKPUpdater.httpReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  pb.Max  := AContentLength;
  pb.Position := AReadCount;
  Caption := '다운로드 시작...';
end;

procedure TFrmMKPUpdater.httpRequestCompleted(const Sender: TObject;
  const AResponse: IHTTPResponse);
begin
  Caption := '다운로드 완료';
end;

procedure TFrmMKPUpdater.MoveFiles;
var
  I: Integer;
  aFile: TUpdateFile;
  srcFile, destFile: string;
begin
  if DownList.Count <= 0 then Exit;

  Caption := '파일카피';

  pb.Max  := DownList.Count;
  pb.Position := 0;

  for I := 0 to DownList.Count-1 do
  begin
    aFile:= TUpdateFile(DownList.Objects[i]);
    srcFile   := 'C:\DownTemp\'+aFile.name;
    destFile  := 'C:\testDalin'+aFile.path+afile.name;

    TFile.Copy(srcFile, destFile, true);
    sleep(1);

    pb.Position := i+1;
  end;

  Caption := '파일카피 완료';
end;

procedure TFrmMKPUpdater.ReadFiles(sFileName: string; aColl: TCollection);
var
  i: integer;
  aList:TStringList;
  sArr: TArray<string>;
begin

  if not FileExists(sFileName) then Exit;

  aList:= TStringList.Create;
  try
    aList.LoadFromFile(sFileName);
    for I := 0 to aList.Count-1 do
    begin
      sArr  := aList[i].Split([':']);
      if Length(sArr) < 3 then continue;

      with aColl.Add as TUpdateFile do
      begin
        name  := sArr[0];
        version := sArr[1];
        path  := sArr[2];
      end;
    end;
  finally
    aList.Free;
  end;

end;

procedure TFrmMKPUpdater.ReadMyVersion;
begin
  ReadFiles(FAppDir + 'update.lsg', LocalFiles);
end;

end.
