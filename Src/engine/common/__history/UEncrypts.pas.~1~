unit UEncrypts;

interface

uses
  System.SysUtils,
  IdSSLOpenSSL, IdHashSHA,
  IdGlobal, IdHMAC, IdHMACSHA1
  ;


function CalculateHMACSHA256(const value, salt: String): String;
function CalculateHMACSHA512(const value, salt: String): String;
function GetUUID : string;


implementation

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

function GetUUID : string;
var
  guid : TGUID;
  sData: string;
begin
  CreateGUID(guid);
  sData  := GUIDToString(guid);
  Result := Copy( sData, 2, Length( sData) - 2);
end;




end.
