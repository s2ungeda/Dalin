unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Outline,
  Vcl.Samples.DirOutln, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.FileCtrl;

type
  TForm1 = class(TForm)
    lv: TListView;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Edit2: TEdit;
    ReLoad: TButton;
    Edit3: TEdit;
    lvig: TListView;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ReLoadClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FIgList : TStringList;
    procedure UpDateList;
    function LoadConfig: boolean;
  public
    { Public declarations }
  end;

  function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;

var
  Form1: TForm1;

implementation

uses
  System.IOUtils
  , System.Types
  , DateUtils
  , ShellApi
  , System.IniFiles
  ;

{$R *.dfm}

function FileTimeToDateTime(const FileTime: TFileTime): TDateTime;
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  if FileTimeToLocalFileTime(FileTime, LocalFileTime) then
    if FileTimeToSystemTime(LocalFileTime, SystemTime) then
      Result := SystemTimeToDateTime(SystemTime);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  UpDateList;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  sFileName, sData : string;
  f : TextFile;
  i : integer;             ListItem  : TListItem;
begin

  sFileName := edit2.Text +'\files.lsg';
  try
    AssignFile(f, sFileName);
    ReWrite(f);
    try
      for I := 0 to lv.Items.Count -1  do
      begin
        sData := Format('%s:%s:%s', [lv.Items[i].Caption,
          lv.Items[i].SubItems[0], lv.Items[i].SubItems[1] ]);
        Writeln(f, sData);
      end;
    finally
      CloseFile(f);
    end;

  finally
    if FileExists(sFileName) then
      ShellExecute(Application.Handle, 'open', 'notepad', PChar(sFileName), nil, SW_SHOW);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FIgList := TStringList.Create;;
  LoadConfig;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FIgList.Free;
end;

function TForm1.LoadConfig: boolean;
var
  pIniFile : TIniFile;
  stDir, sSec : string;
  iCnt : Integer;
  I: Integer;
  ListItem  : TListItem;
begin
  result := true;

  try
    try
      stDir := ExtractFilePath( paramstr(0) )+'Config\';
      pIniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+'muf_config.ini' );

      edit1.Text := pIniFile.ReadString('Directory', 'Load', 'Sauri');
      edit2.Text := pIniFile.ReadString('Directory', 'Write', 'Sauri');
      edit3.Text := pIniFile.ReadString('Directory', 'Depth', '2');

      FIgList.Clear;  lvig.Clear;

      iCnt := pIniFile.ReadInteger('Ignore', 'Count', 0);
      for I := 1 to iCnt do
      begin
        sSec  := 'Ignore_'+i.ToString;
        FIgList.Add(pIniFile.ReadString('Ignore', sSec, 'Sauri'));

        ListItem := lvig.Items.Add;
        ListItem.Caption := i.ToString;
        ListItem.SubItems.Add(FIgList[FIgList.Count-1]);
      end;

    except
      result := false;
    end;
  finally
    pIniFile.Free;
  end;

end;

procedure TForm1.ReLoadClick(Sender: TObject);
begin
  LoadConfig;
end;

procedure TForm1.UpDateList;
var
  sArr : TStringDynArray;
  sFile: string;
  FileInfo: TSearchRec;
  ListItem  : TListItem;
  sDir : string;
  dirArr : TArray<string>;

  i,iStart : integer;
begin
  lv.Clear;

  sArr := TDirectory.GetFiles( edit1.Text, '*', TSearchOption.soAllDirectories);
  iStart  := StrToIntDef(edit3.Text, 2);

  for sFile in sArr do
  begin
    if FindFirst(sFile, faAnyFile, FileInfo) = 0 then
    try

      if FIgList.IndexOf(FileInfo.Name) >= 0 then Continue;

      ListItem := lv.Items.Add;
      ListItem.Caption := FileInfo.Name; // 파일 이름
      ListItem.SubItems.Add(FormatDateTime('yymmddhhmm', FileInfo.TimeStamp) );
      sDir := ExtractFileDir( sFile);
      dirArr  := sDir.Split(['\']);

      sDir := '';
      for I := iStart to High(dirArr) do
        sDir := sDir + '/' + dirArr[i];
      sDir := sDir + '/';
      ListItem.SubItems.Add(sDir);
      ListItem.SubItems.Add(IntToStr(FileInfo.Size)); // 파일 크기

    finally
      FindClose(FileInfo);
    end;
  end;
end;

end.
