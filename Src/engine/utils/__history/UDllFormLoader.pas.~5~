unit UDllFormLoader;

interface

uses
  System.Classes, System.SysUtils, Windows, Forms,

  UStorage

  ;

type

  TDllFormItem = class(TCollectionItem)
  public
    FFormID: Integer;
    FDllHandle : THandle;
    FForm : TForm;
  end;

  TDllFormOpenEvent = procedure(iFormID: integer; var aHandle: THandle) of object;

  TDllFormLoader = class(TCollection)
  private
    FStorage: TStorage;
    FOnDllFormOpen: TDllFormOpenEvent;
    function New(iFormID: integer; hHandle: THandle): TDllFormItem;
    procedure OnFormClosed(Sender: TObject; var Action: TCloseAction);
    function Find(iFormID: integer): TDllFormItem;
  public
    constructor Create;
    destructor Destroy; override;

    procedure FreeDll;

    function Open(iFormID: integer; aMainForm: TForm): THandle;
    function Load(stFile: String; aMainForm: TForm): Boolean;
    function Save(stFile: String): Boolean;

    property Storage: TStorage read FStorage write FStorage;

    property OnDllFromOpen : TDllFormOpenEvent read FOnDllFormOpen write FOnDllFormOpen;
  end;

implementation

{ TDllFormLoader }

constructor TDllFormLoader.Create;
begin
 inherited Create(TDllFormItem);

  FStorage := TStorage.Create;
end;

destructor TDllFormLoader.Destroy;
begin
  FStorage.Free;
  inherited;
end;

procedure TDllFormLoader.FreeDll;
var
  i : integer;
  aItem : TDllFormItem;
begin
  for I := 0 to Count-1 do
  begin
    aItem := Items[i] as TDllFormItem;
//    if aItem.FForm <> nil then
//      aItem.FForm.Free;

    if aItem.FDllHandle <> 0 then
      FreeLibrary(aItem.FDllHandle);
  end;
end;

procedure TDllFormLoader.OnFormClosed(Sender: TObject; var Action: TCloseAction);
var
  aForm : TForm;
  aItem : TDllFormItem;
  iIndex: integer;
begin
//  aForm := TForm(Sender);
//  if aForm = nil then
//  begin
//    exit;
//  end;
//
////  if aForm = FrmMain then
////    gEnv.MainBoard := nil;
//
//  aItem := FindForm( aForm );
//  if aItem = nil then exit;
//  //aMenu := OrpMainForm.Menu.Items.Find('Window');
//  //aMenu.Remove(aItem.FSubMenu);
//  iIndex := FindIndex(aForm);
//  Action := cafree;
//  Delete(iIndex);
//
//  FFormTags.Del(aItem.FFormID, aForm.Tag);
end;

function TDllFormLoader.Find(iFormID: integer): TDllFormItem;
var
  I: Integer;
  aItem : TDllFormItem;
begin
  Result := nil;
  for I := 0 to Count-1 do
  begin
    aItem := Items[i] as TDllFormItem;
    if aItem.FFormID = iFormID then
    begin
      Result := aItem;
      break;
    end;
  end;
end;

function TDllFormLoader.New(iFormID: integer; hHandle: THandle): TDllFormItem;
begin
  Result := Add as  TDllFormItem;
  Result.FFormID := iFormID;
  Result.FDllHandle  := hHandle;
end;

function TDllFormLoader.Load(stFile: String; aMainForm: TForm): Boolean;
var
  iFormID: integer;
  hHandle: THandle;
  aItem : TDllFormItem;
  ShowFormProc: function (Sender: TComponent): TForm;
  LoadFormProc: procedure (aStorage: TStorage);
begin
  FStorage.Load(stFile);
  FStorage.First;
  Result := false;
  while not FStorage.EOF do
  begin
    Result := true;
    iFormID := FStorage.FieldByName('FormID').AsInteger;

    hHandle := LoadLibrary(PChar(Format('Win_%d.dll', [iFormID])));
    if hHandle <> 0 then
    begin
      aItem := New(iFormID, hHandle);

      @ShowFormProc := GetProcAddress(hHandle, 'Open');
      if Assigned(ShowFormProc) then
        aItem.FForm := ShowFormProc(aMainForm);

      @LoadFormProc := GetProcAddress(hHandle, 'Load');
      if Assigned(LoadFormProc) then
        LoadFormProc(FStorage);
    end;

    if aItem.FForm <> nil then
    begin
      aItem.FForm.Show;
        // set default
      aItem.FForm.Left := FStorage.FieldByName('Left').AsInteger;
      aItem.FForm.Top := FStorage.FieldByName('Top').AsInteger;
      aItem.FForm.Width := FStorage.FieldByName('width').AsInteger;
      aItem.FForm.Height := FStorage.FieldByName('Height').AsInteger;

      case FStorage.FieldByName('WindowState').AsInteger of
        0: aItem.FForm.WindowState := wsNormal;
        1: aItem.FForm.WindowState := wsMinimized;
        2: aItem.FForm.WindowState := wsMaximized;
      end;
    end;

    FStorage.Next;
  end;
end;

function TDllFormLoader.Open(iFormID: integer; aMainForm: TForm): THandle;
var
  aItem : TDllFormItem;
  ShowFormProc: function (Sender: TComponent): TForm;
begin

//  aItem := Find(iFormID);
//  if aItem <> nil then
  Result := LoadLibrary(PChar(Format('Win_%d.dll', [iFormID])));

  if Result <> 0 then
  begin
    aItem := New(iFormID, Result);

    @ShowFormProc := GetProcAddress(Result, 'Open');
    if Assigned(ShowFormProc) then begin
      aItem.FForm := ShowFormProc(aMainForm);
      aItem.FForm.OnClose := OnFormClosed;
    end;

    aItem.FForm.Show;
  end;
end;

function TDllFormLoader.Save(stFile: String): Boolean;
var
  I: Integer;
  aItem : TDllFormItem;
  SaveFormProc: procedure (aStorage: TStorage);
begin
  FStorage.Clear;

  for I := 0 to Count-1 do
  begin
    aItem := Items[i] as TDllFormItem;
    if aItem.FForm = nil then Continue;

    FStorage.New;
      // common
    FStorage.FieldByName('FormID').AsInteger := aItem.FFormID;
    FStorage.FieldByName('Left').AsInteger := aItem.FForm.Left;
    FStorage.FieldByName('Top').AsInteger := aItem.FForm.Top;
    FStorage.FieldByName('width').AsInteger := aItem.FForm.Width;
    FStorage.FieldByName('Height').AsInteger := aItem.FForm.Height;
    case aItem.FForm.WindowState of
      wsNormal: FStorage.FieldByName('WindowState').AsInteger := 0;
      wsMinimized: FStorage.FieldByName('WindowState').AsInteger := 1;
      wsMaximized: FStorage.FieldByName('WindowState').AsInteger := 2;
    end;


    @SaveFormProc := GetProcAddress(aItem.FDllHandle, 'Save');
    if Assigned(SaveFormProc) then
      SaveFormProc(FStorage);
  end;

  FStorage.Save(stFile);

end;

end.
