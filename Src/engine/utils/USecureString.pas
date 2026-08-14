unit USecureString;

interface

uses
  SysUtils, Windows, Classes, SyncObjs
  ;
type

  TSecureString = class
  private
    FLock: TCriticalSection;
    FEncryptedData: TBytes;
    procedure SecureClear(var S: string);
    procedure InternalClear;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(const S: string); overload;
    procedure Assign(const Sec, Es: TBytes); overload;

    function Reveal: string;
    procedure Clear;

    function IsEmpty: Boolean;
  end;

//  function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: LPCWSTR;
//    pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
//    pPromptStruct: Pointer; dwFlags: DWORD;
//    pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';
//
//  function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: PLPWSTR;
//    pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
//    pPromptStruct: Pointer; dwFlags: DWORD;
//    pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';
//
//
//  function EncryptData(const PlainText: string; Entropy: TBytes): TBytes;
//  function DecryptData(const Encrypted, Entropy:TBytes): string;
//
//  function SaveEncryptedKeyToFile(const Entropy: TSecureString; const FileName: string;
//    KeyArr: TArray<string>): boolean;
//  function LoadEncryptedKeyFromFile(const Entropy: TSecureString; const FileName: string;
//    out KeyArr: TArray<TSecureString>): boolean;

implementation

uses
  UEncrypts
  ;


{ TSecureString }
    {
function EncryptData(const PlainText: string; Entropy: TBytes): TBytes;
var
  DataIn, DataOut, DataEnt: DATA_BLOB;
begin

  DataIn.pbData := Pointer(PlainText);
  DataIn.cbData := Length(PlainText) * SizeOf(Char);

  DataEnt.pbData := @Entropy[0];
  DataEnt.cbData := Length(Entropy);

  if CryptProtectData(@DataIn, nil, @DataEnt, nil, nil, 0, @DataOut) then
  begin
    SetLength(Result, DataOut.cbData);
    Move(DataOut.pbData^, Result[0], DataOut.cbData);
    LocalFree(HLOCAL(DataOut.pbData));
  end
  else
    raise Exception.Create('암호화 실패');
end;

function DecryptData(const Encrypted, Entropy : TBytes): string;
var
  DataIn, DataOut, DataEnt: DATA_BLOB;
begin
  DataIn.pbData := @Encrypted[0];
  DataIn.cbData := Length(Encrypted);

  DataEnt.pbData := @Entropy[0];
  DataEnt.cbData := Length(Entropy);

  if CryptUnprotectData(@DataIn, nil, @DataEnt, nil, nil, 0, @DataOut) then
  begin
    SetString(Result, PChar(DataOut.pbData), DataOut.cbData div SizeOf(Char));
    LocalFree(HLOCAL(DataOut.pbData));
  end
  else
    raise Exception.Create('복호화 실패');
end;


function SaveEncryptedKeyToFile(const Entropy: TSecureString; const FileName: string;
  KeyArr: TArray<string>): boolean;
var
  EncKey, EncSecret: TBytes;
  F: TFileStream;
  Size: Integer;
  I: Integer;
begin
  Result := false;
  F := TFileStream.Create(FileName, fmCreate);
  try
    try
      for I := 0 to High(KeyArr) do
      begin
        EncSecret :=  EncryptData(KeyArr[i], Entropy.FEntropyData);
        Size := Length(EncSecret);
        F.WriteBuffer(Size, SizeOf(Size));
        F.WriteBuffer(EncSecret[0], Size);
      end;

      Result := true;
    except;
    end;
  finally
    F.Free;
  end;
end;

function LoadEncryptedKeyFromFile(const Entropy: TSecureString; const FileName: string;
  out KeyArr: TArray<TSecureString>): boolean; overload;
var
  F: TFileStream;
  Count, Size: Integer;
  EncKey: TBytes;
begin
  Result := False;
  Count := 0;
  SetLength(KeyArr, 0);

  if not FileExists(FileName) then
    Exit;

  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    while F.Position < F.Size do
    begin
      // 파일 끝까지 남은 데이터 확인 후 Size 읽기
      if F.Size - F.Position < SizeOf(Size) then
        Break;

      F.ReadBuffer(Size, SizeOf(Size));

      // Size가 0이거나 음수면 데이터 끝 (이상치 방지)
      if (Size <= 0) or (F.Size - F.Position < Size) then
        Break;

      SetLength(EncKey, Size);
      F.ReadBuffer(EncKey[0], Size);

      Inc(Count);
      SetLength(KeyArr, Count);
      KeyArr[Count - 1].Assign(DecryptData(EncKey, Entropy.FEntropyData)); // 필요시 인자 수정
    end;

    Result := Count > 0;
  finally
    F.Free;
  end;
end;
 }

constructor TSecureString.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  SetLength(FEncryptedData, 0);
end;

destructor TSecureString.Destroy;
begin
  InternalClear;
  FLock.Free;
  inherited;
end;

procedure TSecureString.Assign(const S: string);
var
  InBlob, OutBlob: DATA_BLOB;
  InBytes: TBytes;
begin
  FLock.Enter;
  try
    InternalClear;

//  FEncryptedData := EncryptData(S);

    if S = '' then Exit; // 빈 문자열이면 @InBytes[0] 접근 없이 종료

    InBytes := TEncoding.Unicode.GetBytes(S);
    try
      InBlob.pbData := @InBytes[0];
      InBlob.cbData := Length(InBytes);

      if CryptProtectData(@InBlob, nil, nil, nil, nil, 0, @OutBlob) then
      begin
        SetLength(FEncryptedData, OutBlob.cbData);
        Move(OutBlob.pbData^, FEncryptedData[0], OutBlob.cbData);
        LocalFree(HLOCAL(OutBlob.pbData));
      end
      else
        raise Exception.Create('SecureString 암호화 실패');
    finally
      // 메모리에 남은 평문 복사본 소거
      FillChar(InBytes[0], Length(InBytes), 0);
    end;
  finally
    FLock.Leave;
  end;
end;

function TSecureString.Reveal: string;
var
  InBlob, OutBlob: DATA_BLOB;
begin
  Result := '';
  FLock.Enter;
  try
    if Length(FEncryptedData) = 0 then Exit;

    InBlob.pbData := @FEncryptedData[0];
    InBlob.cbData := Length(FEncryptedData);

    if CryptUnprotectData(@InBlob, nil, nil, nil, nil, 0, @OutBlob) then
    begin
      SetString(Result, PChar(OutBlob.pbData), OutBlob.cbData div SizeOf(Char));
      // API가 할당한 평문 버퍼 소거 후 해제
      FillChar(OutBlob.pbData^, OutBlob.cbData, 0);
      LocalFree(HLOCAL(OutBlob.pbData));
    end
    else
      raise Exception.Create('SecureString 복호화 실패');
  finally
    FLock.Leave;
  end;
end;

procedure TSecureString.SecureClear(var S: string);
begin
  if Length(S) > 0 then
  begin
    UniqueString(S); // 참조 공유 방지
    FillChar(PChar(S)^, Length(S) * SizeOf(Char), 0);
    S := '';
  end;
end;

procedure TSecureString.Assign(const Sec, Es: TBytes);
begin
  FLock.Enter;
  try
    InternalClear;
    FEncryptedData := Copy(Sec); // 깊은 복사 - 호출자 배열과 참조 공유 방지
  finally
    FLock.Leave;
  end;
end;

// 락 없이 버퍼만 소거 (락을 잡은 상태에서 호출)
procedure TSecureString.InternalClear;
begin
  if Length(FEncryptedData) > 0 then
    FillChar(FEncryptedData[0], Length(FEncryptedData), 0);
  SetLength(FEncryptedData, 0);
end;

procedure TSecureString.Clear;
begin
  FLock.Enter;
  try
    InternalClear;
  finally
    FLock.Leave;
  end;
end;

function TSecureString.IsEmpty: Boolean;
begin
  FLock.Enter;
  try
    Result := Length(FEncryptedData) = 0;
  finally
    FLock.Leave;
  end;
end;

end.
