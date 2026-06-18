unit UEncrypts;

interface

uses
  System.SysUtils,  System.Classes,
  IdSSLOpenSSL, IdHashSHA,
  IdGlobal, IdHMAC, IdHMACSHA1,

  Winapi.Windows
  ;

type
  DATA_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDATA_BLOB = ^DATA_BLOB;

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: LPCWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';

function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: PLPWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';

function CalculateHMACSHA256(const value, salt: String): String;
function CalculateHMACSHA512(const value, salt: String): String;
function HashHMACSHA512(const fileName: String): String;
function GetUUID : string;

///
///

procedure SaveEncryptedKeyToFile(const FileName, ApiKey, ApiSecret: string); overload;
procedure LoadEncryptedKeyFromFile(const FileName: string; out EncKey, EncSecret: TBytes); overload;

function SaveEncryptedKeyToFile(const FileName: string; aObj: TObject; KeyArr: TArray<string>): boolean; overload;
function LoadEncryptedKeyFromFile(const FileName: string; aObj: TObject; out KeyArr: TArray<string>): boolean; overload;

function EncryptData(const PlainText, Entropy: string): TBytes;
function DecryptData(const Encrypted: TBytes; Entropy:string): string;
function BytesToString(const Value: TBytes): string;


implementation

uses
  USecureString,
  System.IOUtils
  ;

function CalculateHMACSHA256(const value, salt: String): String;
var
  hmac: TIdHMACSHA256;
  hash: TIdBytes;
begin
  LoadOpenSSLLibrary;
  if not TIdHashSHA256.IsAvailable then
    raise Exception.Create('SHA256 hashing is not available!');
  hmac := TIdHMACSHA256.Create;
  try
    hmac.Key := IndyTextEncoding_UTF8.GetBytes(salt);
    hash := hmac.HashValue(IndyTextEncoding_UTF8.GetBytes(value));
    Result := ToHex(hash);
  finally
    hmac.Free;
  end;
end;

 function CalculateHMACSHA512(const value, salt: String): String;
var
  hmac: TIdHMACSHA512;
  hash: TIdBytes;
begin
  LoadOpenSSLLibrary;
  if not TIdHashSHA512.IsAvailable then
    raise Exception.Create('SHA512 hashing is not available!');
  hmac := TIdHMACSHA512.Create;
  try
    hmac.Key := IndyTextEncoding_UTF8.GetBytes(salt);
    hash := hmac.HashValue(IndyTextEncoding_UTF8.GetBytes(value));
    Result := LowerCase(ToHex(hash));
  finally
    hmac.Free;
  end;

 end;

function HashHMACSHA512(const fileName: String): String;
var
  hmac: TIdHMACSHA256;
  hash: TIdBytes;

  SHA: TIdHashSHA256;
  Stream: TFileStream;
begin
  LoadOpenSSLLibrary;
  if not TIdHashSHA256.IsAvailable then
    raise Exception.Create('SHA256 hashing is not available!');

  Stream := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
  try
    SHA := TIdHashSHA256.Create;
    try
      Result := SHA.HashStreamAsHex(Stream);
    finally
      SHA.Free;
    end;
  finally
    Stream.Free;
  end;
end;


function GetUUID : string;
var
  guid : TGUID;
  sData: string;
begin
  CreateGUID(guid);
  sData  := GUIDToString(guid);
  Result := Copy( sData, 2, Length( sData) - 2);
end;


////
///
///


function EncryptData(const PlainText, Entropy: string): TBytes;
var
  DataIn, DataOut, DataEnt: DATA_BLOB;
begin

  DataIn.pbData := Pointer(PlainText);
  DataIn.cbData := Length(PlainText) * SizeOf(Char);

  DataEnt.pbData := Pointer(Entropy);
  DataEnt.cbData := Length(Entropy) * SizeOf(Char);

  if CryptProtectData(@DataIn, nil, @DataEnt, nil, nil, 0, @DataOut) then
  begin
    SetLength(Result, DataOut.cbData);
    Move(DataOut.pbData^, Result[0], DataOut.cbData);
    LocalFree(HLOCAL(DataOut.pbData));
  end
  else
    raise Exception.Create('암호화 실패');
end;

function DecryptData(const Encrypted: TBytes; Entropy:string): string;
var
  DataIn, DataOut, DataEnt: DATA_BLOB;
begin
  DataIn.pbData := @Encrypted[0];
  DataIn.cbData := Length(Encrypted);

  DataEnt.pbData := Pointer(Entropy);
  DataEnt.cbData := Length(Entropy) * SizeOf(Char);

  if CryptUnprotectData(@DataIn, nil, @DataEnt, nil, nil, 0, @DataOut) then
  begin
    SetString(Result, PChar(DataOut.pbData), DataOut.cbData div SizeOf(Char));
    LocalFree(HLOCAL(DataOut.pbData));
  end
  else
    raise Exception.Create('복호화 실패');
end;


procedure SaveEncryptedKeyToFile(const FileName, ApiKey, ApiSecret: string);
var
  EncKey, EncSecret: TBytes;
  F: TFileStream;
  Size: Integer;
begin
  EncKey := EncryptData(ApiKey, '');
  EncSecret := EncryptData(ApiSecret, '');

  F := TFileStream.Create(FileName, fmCreate);
  try
    Size := Length(EncKey);
    F.WriteBuffer(Size, SizeOf(Size));
    F.WriteBuffer(EncKey[0], Size);

    Size := Length(EncSecret);
    F.WriteBuffer(Size, SizeOf(Size));
    F.WriteBuffer(EncSecret[0], Size);
  finally
    F.Free;
  end;
end;

function SaveEncryptedKeyToFile(const FileName: string; aObj: TObject; KeyArr: TArray<string>): boolean;
var
  EncKey, EncSecret: TBytes;
  F: TFileStream;
  Size: Integer;
  I: Integer;
  SecStr : string;
begin
  Result := false;
  F := TFileStream.Create(FileName, fmCreate);

  SecStr  := (aObj as TSecureString).Reveal;
  try
    try

      for I := 0 to High(KeyArr) do
      begin
        EncSecret :=  EncryptData(KeyArr[i], SecStr);
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

procedure LoadEncryptedKeyFromFile(const FileName: string; out EncKey, EncSecret: TBytes);
var
  F: TFileStream;
  Size: Integer;
begin
  F := TFileStream.Create(FileName, fmOpenRead);
  try
    F.ReadBuffer(Size, SizeOf(Size));
    SetLength(EncKey, Size);
    F.ReadBuffer(EncKey[0], Size);

    F.ReadBuffer(Size, SizeOf(Size));
    SetLength(EncSecret, Size);
    F.ReadBuffer(EncSecret[0], Size);
  finally
    F.Free;
  end;
end;


function LoadEncryptedKeyFromFile(const FileName: string; aObj: TObject; out KeyArr: TArray<string>): boolean; overload;
var
  F: TFileStream;
  Count, Size: Integer;
  EncKey: TBytes;
  SecStr: TSecureString;
begin
  Result := False;
  Count := 0;
  SetLength(KeyArr, 0);

  if not FileExists(FileName) then
    Exit;

  SecStr  := aObj as TSecureString;

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
      KeyArr[Count - 1] := DecryptData(EncKey, SecStr.Reveal); // 필요시 인자 수정
    end;

    Result := Count > 0;
  finally
    F.Free;
  end;
end;


function BytesToString(const Value: TBytes): string;
begin
  SetLength(Result, Length(Value) div SizeOf(Char));
  if Length(Result) > 0 then
    Move(Value[0], Result[1], Length(Value));
end;



end.
