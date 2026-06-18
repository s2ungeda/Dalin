unit AntiDebugUtils;

interface

uses
  Windows, PsAPI, TlHelp32, SysUtils;

type
  ULONG_PTR = NativeUInt;
  NTSTATUS  = LongInt;

  function IsDebuggerAttached: Boolean;
  function IsFridaModuleLoaded: Boolean;
  function HasDebugPort: Boolean;
  function HasDebugObjectHandle: Boolean;
  function CheckNtGlobalFlag: Boolean;
  function CheckHardwareBreakpoints: Boolean;
  function CheckTimingAnomaly: Boolean;
  function IsKnownDebuggerProcess: Boolean;


  function IsBeingDebugged(var s : string) : boolean;

implementation

// NtQueryInformationProcess 선언 (ntdll.dll에서 import)
function NtQueryInformationProcess(
  ProcessHandle: THandle;
  ProcessInformationClass: ULONG;
  ProcessInformation: Pointer;
  ProcessInformationLength: ULONG;
  ReturnLength: PULONG
): NTSTATUS; stdcall; external 'ntdll.dll';

// NtCurrentPeb: PEB 주소 반환 (x86/x64 모두 지원)
function NtCurrentPeb: Pointer; assembler;
asm
  {$IFDEF CPUX64}
    MOV   RAX, GS:[$60]
  {$ELSE}
    MOV   EAX, FS:[$30]
  {$ENDIF}
end;

{* 1. Win32 API + PEB BeingDebugged 검사 *}
function IsDebuggerAttached: Boolean;
var
  remote: BOOL;
begin
  // IsDebuggerPresent
  if IsDebuggerPresent then
    Exit(True);

  // CheckRemoteDebuggerPresent
  if CheckRemoteDebuggerPresent(GetCurrentProcess, remote) and remote then
    Exit(True);

  // PEB->BeingDebugged 플래그 (offset 2)
  Result := (PByte(NtCurrentPeb)^ and $02) <> 0;
end;

{* 2. 모듈 스캔: frida 키워드 검사 *}
function IsFridaModuleLoaded: Boolean;
var
  hMods: array[0..255] of HMODULE;
  cbNeeded, i: DWORD;
  modName: array[0..MAX_PATH - 1] of Char;
begin
  Result := False;
  if EnumProcessModules(GetCurrentProcess, @hMods, SizeOf(hMods), cbNeeded) then
  begin
    for i := 0 to (cbNeeded div SizeOf(HMODULE)) - 1 do
    begin
      if GetModuleFileNameEx(GetCurrentProcess, hMods[i], modName, MAX_PATH) > 0 then
      begin
        if Pos('frida', LowerCase(modName)) > 0 then
          Exit(True);
      end;
    end;
  end;
end;

{* 3. NtQueryInformationProcess 기반: DebugPort 검사 *}
function HasDebugPort: Boolean;
var
  debugPort: ULONG_PTR;
begin
  Result := False;
  // ProcessDebugPort = 7
  if NtQueryInformationProcess(GetCurrentProcess, 7, @debugPort, SizeOf(debugPort), nil) = 0 then
    Result := debugPort <> 0;
end;

{* 4. NtQueryInformationProcess 기반: DebugObjectHandle 검사 *}
function HasDebugObjectHandle: Boolean;
var
  debugObjHandle: ULONG_PTR;
begin
  Result := False;
  // ProcessDebugObjectHandle = 30
  if NtQueryInformationProcess(GetCurrentProcess, 30, @debugObjHandle, SizeOf(debugObjHandle), nil) = 0 then
    Result := debugObjHandle <> 0;
end;

{* 5. PEB->NtGlobalFlag 검사 *}
function CheckNtGlobalFlag: Boolean;
var
  PebBase: PByte;
  NtGlobalFlag: ULONG;
begin
  PebBase := PByte(NtCurrentPeb);
  {$IFDEF CPUX64}
    // 64-bit PEB에서 NtGlobalFlag 오프셋 = 0xBC
    NtGlobalFlag := PCardinal(PebBase + $BC)^;
  {$ELSE}
    // 32-bit PEB에서 NtGlobalFlag 오프셋 = 0x68
    NtGlobalFlag := PCardinal(PebBase + $68)^;
  {$ENDIF}
  // HEAP_ENABLE_TAIL_CHECK(0x10) | HEAP_ENABLE_FREE_CHECK(0x20) | HEAP_VALIDATE_PARAMETERS_ENABLED(0x40)
  Result := (NtGlobalFlag and $70) <> 0;
end;

{* 6. 하드웨어 브레이크포인트 검사 (Debug Registers) *}
function CheckHardwareBreakpoints: Boolean;
var
  ctx: TContext;
begin
  ZeroMemory(@ctx, SizeOf(ctx));
  ctx.ContextFlags := CONTEXT_DEBUG_REGISTERS;
  if GetThreadContext(GetCurrentThread, ctx) then
  begin
    Result := (ctx.Dr0 <> 0) or (ctx.Dr1 <> 0) or (ctx.Dr2 <> 0) or (ctx.Dr3 <> 0);
  end
  else
    Result := False;
end;

{* 7. 타이밍 이상 검사 (Anti-Anti-Debug) *}
function CheckTimingAnomaly: Boolean;
var
  freq, t1, t2: Int64;
  j: Integer;
  delta: Int64;
begin
  Result := False;
  if QueryPerformanceFrequency(freq) then
  begin
    QueryPerformanceCounter(t1);
    j := 0;
    while j < 1000 do
      Inc(j);
    QueryPerformanceCounter(t2);
    delta := t2 - t1;
    // 여기서 100,000 ticks 이상 차이가 나면 디버깅 의심 (환경에 따라 조정 가능)
    Result := delta > 100000;
  end;
end;

{* 8. 알려진 디버거 프로세스 이름 검사 *}
function IsKnownDebuggerProcess: Boolean;
var
  Snap: THandle;
  pe: PROCESSENTRY32;
  exeName: string;
begin
  Result := False;
  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snap = INVALID_HANDLE_VALUE then
    Exit(False);

  pe.dwSize := SizeOf(pe);
  if Process32First(Snap, pe) then
  begin
    repeat
      exeName := LowerCase(pe.szExeFile);
      if (exeName = 'ollydbg.exe') or
         (exeName = 'x64dbg.exe') or
         (exeName = 'windbg.exe') or
         (exeName = 'ida.exe') or
         (exeName = 'ida64.exe') or
         (exeName = 'dbgview.exe') or
         (exeName = 'scylla.exe') then
      begin
        Result := True;
        Break;
      end;
    until not Process32Next(Snap, pe);
  end;
  CloseHandle(Snap);
end;

{* 차단 처리 *}
function IsBeingDebugged(var s : string) : boolean;
begin
  Result := true;
  if IsDebuggerAttached then begin
    s :='Debugger Attached'; Exit;
  end;

  // 2) NtGlobalFlag 검사
  if CheckNtGlobalFlag then  begin
    s := 'NtGlobalFlag Indicates Debugging';  Exit;
  end;

  // 3) DebugPort 검사
  if HasDebugPort then begin
    s := 'Debug Port Open';  Exit;
  end;

  // 4) DebugObjectHandle 검사
  if HasDebugObjectHandle then  begin
    s := 'Debug Object Handle Present';  Exit;
  end;

  // 5) 하드웨어 브레이크포인트 검사
  if CheckHardwareBreakpoints then begin
    s := 'Hardware Breakpoint Detected'; Exit;
  end;

  // 6) 타이밍 이상 검사  이건 패스..
//  if CheckTimingAnomaly then
//    BlockAndExit('Timing Anomaly Detected');

  // 7) 프로세스 목록에서 알려진 디버거 검색
  if IsKnownDebuggerProcess then  begin
    s := 'Known Debugger Process Running'; Exit;
  end;

  // 8) frida 모듈 검사
  if IsFridaModuleLoaded then  begin
    s := 'Frida Module Loaded'; Exit;
  end;

  Result := false;
end;


end.

