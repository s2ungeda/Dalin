unit USharedThread;

interface

uses
  System.Classes, System.SysUtils,
  windows,
  USharedData
  ;


type

  TMmfThread = class(TThread)
  private
    hTerminate: THandle;
    hMapLock: THandle;
    hMapEvent: THandle;
    hMapping: THandle;
    PMapData: Pointer;
    FOnNotify: TGetStrProc;
    FData : string;
    { Private declarations }
  protected
    procedure Execute; override;
    procedure DoTerminate; override;
    procedure TerminatedSet; override;

    procedure SyncProc;

  public
    constructor Create( aCallBack : TGetStrProc );
    destructor Destroy; override;

    property OnNotify : TGetStrProc read FOnNotify write FOnNotify;
  end;

implementation

{ 
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);  

  and UpdateCaption could look like,

    procedure Mmf.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end;
    
    or 
    
    Synchronize( 
      procedure 
      begin
        Form1.Caption := 'Updated in thread via an anonymous method' 
      end
      )
    );
    
  where an anonymous method is passed.
  
  Similarly, the developer can call the Queue method with similar parameters as 
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.
    
}

{ Mmf }

constructor TMmfThread.Create( aCallBack : TGetStrProc );
begin
  FOnNotify := aCallBack;
  inherited Create(False);
  hTerminate := CreateEvent(nil, True, False, nil);
  if hTerminate = 0 then RaiseLastOSError;
end;

destructor TMmfThread.Destroy;
begin
  if hTerminate <> 0 then CloseHandle(hTerminate)

end;

procedure TMmfThread.DoTerminate;
begin
  if PMapData <> nil then UnmapViewOfFile(PMapData);
  if hMapping <> 0 then CloseHandle(hMapping);
  if hMapEvent <> 0 then CloseHandle(hMapEvent);
  if hMapLock <> 0 then CloseHandle(hMapLock);
  inherited;
end;

procedure TMmfThread.Execute;
var
  llInit: Boolean;
  llRet, llValue: DWORD;
  llHandles: array[0..1] of THandle;
  iSize, i : integer;
  vData : PSharedData;
  tmp : string;
  item : TDataItem;
  aaa : ansiString;
begin
  iSize  := SizeOf(TSharedData);
  hMapEvent := CreateEvent(nil, False, False, PChar('wowsniffDataReady'));
  if hMapEvent = 0 then RaiseLastOSError;

  hMapLock := CreateMutex(nil, False, PChar('wowsniffDataLock'));
  if hMapLock = 0 then RaiseLastOSError;

  hMapping := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, iSize, PChar('wowsniff'));
  if hMapping = 0 then RaiseLastOSError;
  // Check if already exists
  llInit := (GetLastError() <> ERROR_ALREADY_EXISTS);

  PMapData := MapViewOfFile(hMapping, FILE_MAP_WRITE, 0, 0, iSize);
  if PMapData = nil then RaiseLastOSError;
  if llInit then
  begin
    // Init block to #0 if newly created
    FillChar(PMapData^, iSize, 0);
  end;

  llHandles[0] := hMapEvent;
  llHandles[1] := hTerminate;

  while not Terminated do
  begin
    llRet := WaitForMultipleObjects(2, PWOHandleArray(@llHandles), False, INFINITE);
    case llRet of
      WAIT_OBJECT_0+0:
      begin
        llRet := WaitForSingleObject(hMapLock, 5000);
        if llRet = WAIT_OBJECT_0 then
        begin
          try

            vData   := PSharedData( PMapData );

            var iWorkCnt : integer;  iWorkCnt := 0;

            while ( not vData.IsEmpty ) and ( iWorkCnt < 10 ) do
            begin
              vData.Front := ( vData.Front + 1) mod Q_SIZE;
              inc(iWorkCnt);
              CopyMemory(@item, @(vData.SharedData[vData.Front])  , sizeof( TDataItem) )        ;
              var ii : integer;
              ii  := StrToInt(ansiString(item.size));
              aaa := ansiString( item.data );
              FData   :=  Format('%d, %03d :  %s', [ vData.Front, vData.Count, aaa ]);
              Synchronize(SyncProc );
            end;


//            if vData.IsEmpty then continue;
//
//            if vData.Count < 4 then continue;
//
//            for I := 0 to vData.Count-1 do
//            begin
//              if vData.IsEmpty then continue;
//              vData.Front := ( vData.Front + 1) mod Q_SIZE;
//              CopyMemory(@item, @(vData.SharedData[vData.Front])  , sizeof( TDataItem) )        ;
//              var ii : integer;
//              ii  := StrToInt(ansiString(item.size));
//              aaa := ansiString( item.data );
//              //setstring( aaa, PAnsiChar( item.data[0] ), ii );
//             // setstring(tmp, PChar(vData.SharedData[i].data ), 100);
//
//              FData   :=  Format('%d, %03d :  %s', [ vData.Front, vData.Count, aaa ]);
//  //            llValue := PDword(PMapData)^;
//  //            FData   := IntTostr(  llValue );
//              Synchronize(SyncProc );
//            end;
//            ResetEvent(hMapEvent);
          finally
            ReleaseMutex(hMapLock);
          end;
          // use llValue as needed...
          Continue;
        end;
      end;
      WAIT_OBJECT_0+1:
      begin
        Exit;
      end;
    end;
    if llRet <> WAIT_FAILED then SetLastError(llRet);
    RaiseLastOSError;
  end;
end;

procedure TMmfThread.SyncProc;
begin
  FOnNotify( FData );
end;

procedure TMmfThread.TerminatedSet;
begin
  SetEvent(hTerminate);
end;

end.
