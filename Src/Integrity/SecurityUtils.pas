unit SecurityUtils;

interface

uses
  Winapi.Windows, SysUtils, Classes, System.Hash;

function GetTextSectionHash: string;
function GetExpectedHashFromSelf: string;
function CheckFileIntegrity: Boolean;

implementation

uses
  Winapi.ImageHlp,

  Dialogs
  ;

const
  HASH_MARKER = '__HASH__';
  HASH_LENGTH = 64; // SHA-256 as hex
  HASH_PLACEHOLDER: PAnsiChar = '__HASH__0000000000000000000000000000000000000000000000000000000000000000';

// 더미 참조로 제거 방지
procedure TouchHashMarker;
begin
  if HASH_PLACEHOLDER[0] = #0 then Exit;
end;

function GetSHA256(const Buffer: TBytes): string;
var
  SHA: THashSHA2;
begin
  SHA := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  SHA.Update(Buffer);
  Result := SHA.HashAsString;
end;

function GetTextSectionHash: string;
var
  FS: TFileStream;
  Buffer: TBytes;
  DosHeader: PImageDosHeader;
  NtHeaders: PImageNtHeaders;
  Section: PImageSectionHeader;
  i: Integer;
  StartOffset, Size: Cardinal;
  SectionBytes, MarkerBytes, Cleaned: TBytes;
  j: Integer;
  Match: Boolean;
  MarkerPos, AfterPos, BeforeLen, AfterLen: Integer;
begin
  FS := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Buffer, FS.Size);
    FS.ReadBuffer(Buffer[0], FS.Size);

    DosHeader := PImageDosHeader(@Buffer[0]);
    if DosHeader^.e_magic <> IMAGE_DOS_SIGNATURE then
      raise Exception.Create('Invalid EXE format');

    NtHeaders := PImageNtHeaders(@Buffer[DosHeader^._lfanew]);
    if NtHeaders^.Signature <> IMAGE_NT_SIGNATURE then
      raise Exception.Create('Invalid PE signature');

    for i := 0 to NtHeaders^.FileHeader.NumberOfSections - 1 do
    begin
      Section := PImageSectionHeader(PByte(@NtHeaders^.OptionalHeader) +
        NtHeaders^.FileHeader.SizeOfOptionalHeader +
        i * SizeOf(TImageSectionHeader));

      if AnsiString(PAnsiChar(@Section^.Name[0])) = '.text' then
      begin
        StartOffset := Section^.PointerToRawData;
        Size := Section^.SizeOfRawData;

        if (StartOffset + Size) > Length(Buffer) then
          raise Exception.Create('.text section out of bounds');

        SectionBytes := Copy(Buffer, StartOffset, Size);

        // .text 섹션 내에서 HASH_MARKER 바이트 시퀀스를 찾아 제거
        MarkerBytes := TEncoding.ANSI.GetBytes(HASH_MARKER);
        MarkerPos := -1;

        for j := 0 to Length(SectionBytes) - Length(MarkerBytes) - HASH_LENGTH do
        begin
          Match := CompareMem(@SectionBytes[j], @MarkerBytes[0], Length(MarkerBytes));
          if Match then
          begin
            MarkerPos := j;
            Break;
          end;
        end;

        if MarkerPos >= 0 then
        begin
          BeforeLen := MarkerPos;
          AfterPos := MarkerPos + Length(HASH_MARKER) + HASH_LENGTH;
          AfterLen := Length(SectionBytes) - AfterPos;
          SetLength(Cleaned, BeforeLen + AfterLen);

          if BeforeLen > 0 then
            Move(SectionBytes[0], Cleaned[0], BeforeLen);

          if AfterLen > 0 then
            Move(SectionBytes[AfterPos], Cleaned[BeforeLen], AfterLen);

          SectionBytes := Cleaned;
        end;

        Exit(GetSHA256(SectionBytes));
      end;
    end;

    raise Exception.Create('.text section not found');
  finally
    FS.Free;
  end;
end;

function GetExpectedHashFromSelf: string;
var
  FS: TFileStream;
  Buffer: TBytes;
  PosMarker: Integer;
begin
  FS := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Buffer, FS.Size);
    FS.ReadBuffer(Buffer[0], FS.Size);

    var RawStr := TEncoding.ANSI.GetString(Buffer);
    PosMarker := Pos(HASH_MARKER, RawStr);
    if PosMarker > 0 then
      Result := Copy(RawStr, PosMarker + Length(HASH_MARKER), HASH_LENGTH)
    else
      Result := '';
  finally
    FS.Free;
  end;
end;

function CheckFileIntegrity: Boolean;
var
  actualHash, expectedHash: string;
begin
  TouchHashMarker;
  actualHash := GetTextSectionHash;
  expectedHash := GetExpectedHashFromSelf;
  Result := SameText(actualHash, expectedHash);

  ShowMessage('Expected: ' + expectedHash + sLineBreak + 'Actual: ' + actualHash);

end;

end.

