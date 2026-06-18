unit IDistributorItems;

interface

uses
  Winapi.Windows, System.Classes, System.Generics.Collections, System.SyncObjs, System.SysUtils
  , UTypes
  , UConsts
  ;

type

  // Topic = DataID
  TTopic = integer;

  // 주문데이타, 시세, Data(LPItem, IHItem 등)
  PTopicMode = ^TTopicMode;
  TTopicMode = (tmSequence, tmSnapshot);

  TSnapshotItem = record
    Key: string;
    Data: TObject;
    UpdateSeq: Int64;
  end;
  // 시세는 TQuote 를 Topic 으로  사용
  // 시세 토픽을 하나 만들면 됨 QUOTE_DATA
  // LP, IH Item 은 DataID 를 Topic 으로 사용..

  TSnapshotBuffer = class
  private
    FItems: TArray<TSnapshotItem>;
    FCount: Integer;
    FLastUpdateSeq: Int64;
    FLock: TSpinLock;
    function FindIndex(const Key: string; out Index: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Overwrite(const Item: TObject);
    function FetchUpdated(var LastSeq: Int64): TArray<TSnapshotItem>;
  end;

  ISubscriberInfo = interface
    ['{4D65B3DF-3345-476D-9B63-8B65F587F8A6}']
    function GetSubscriber : TObject;
    function GetDataID: integer;
    function GetDataObj: TObject;
    function GetEventIDs : TDistributorIDs;
//    function GetHanlder :  TDistributorEvent;
    function GetHandle : NativeUInt;

    function GetLastSendTime: TDateTime;
    function GetBusy: boolean;
    procedure SetBusy(Value: boolean);

    property Handle: NativeUInt read GetHandle;
    property Subscriber: TObject read GetSubscriber;
    property DataID: Integer read GetDataID;
    property DataObj: TObject read GetDataObj;
    property EventIDs: TDistributorIDs read GetEventIDs;
//    property Handler: TDistributorEvent read GetHanlder;
    property LastSendTime : TDateTime read GetLastSendTime;
    property Busy: boolean read GetBusy write SetBusy;
  end;

  TSubscriberInfo = class(TInterfacedObject, ISubscriberInfo)
  private
    FHandle: NativeUInt;
    FSubscriber: TObject;
    FDataID: Integer;
    FDataObj: TObject;
    FEventIDs: TDistributorIDs;
    FHandler: TDistributorEvent;
    FLastSendTime : TDateTime;
    FBusy: boolean;
  public
    constructor Create(ASubscriber: TObject; ADataID: integer; AHandler: TDistributorEvent );
    function GetHandle: NativeUInt;
    function GetBusy: Boolean;
    procedure SetBusy(Value: Boolean);

    function GetSubscriber : TObject;
    function GetDataID: integer;
    function GetDataObj: TObject;
    function GetEventIDs : TDistributorIDs;
    function GetHanlder :  TDistributorEvent;

    function GetLastSendTime: TDateTime;
  end;

  TDispatcher = class;

  TDispatchThread = class(TThread)
  private
    FOwner: TDispatcher;
    FQueue: TThreadedQueue<TObject>;
    FMode : TTopicMode;
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TDispatcher; Queue: TThreadedQueue<TObject>; Mode: TTopicMode);
  end;


  TDispatcher = class
  private
    FSanpThread: TDispatchThread;
    // 소켓 스레드가 그냥 FSanpQueue 에 push;
    FSnapQueue: TThreadedQueue<TObject>;

    // 총 3개..
    FTopicModes: TArray<PTopicMode>;
    FSnapshotBuffers : TArray<TSnapshotBuffer>;

    FSubscriptions: TObjectDictionary<integer, TList<ISubscriberInfo>>;
    FSubscribersToWake: TDictionary<ISubscriberInfo, Boolean>;

    FLock: TCriticalSection;
    procedure NotifySubscribers(const Topics: TEnumerable<integer>);

    procedure EnsureArraysCapacity(MaxTopic: TTopic);

  public
    constructor Create;
    destructor Destroy; override;

    function GetSnapshotBuffer(Mode: TTopicMode): TSnapshotBuffer;

    procedure EnqueueData(Topic: TTopic; const Data: TObject);
    procedure RegisterTopic(Topic: TTopic; Mode: TTopicMode);

    procedure Subscribe(aSubscriber: TObject; iDataID: Integer; aDataObj: TObject;
      EventIDs: TDistributorIDs; aHandler: TDistributorEvent);

//    procedure Cancel(aSubscriber: TObject; iDataID: Integer; aDataObj: TObject); overload;
//    procedure Cancel(aSubscriber: TObject; iDataID: Integer); overload;
    procedure Cancel(Topic: TTopic; aSubscriber: TObject); overload;
  end;



implementation


{ TDispatcher }

procedure TDispatcher.Cancel(Topic: TTopic; aSubscriber: TObject);
var
  aList: TList<ISubscriberInfo>;
  I: Integer;
begin
  FLock.Enter;
  try
    if FSubscriptions.TryGetValue(Topic, aList) then
      for i := aList.Count-1 downto 0 do
      begin
        if aList[i].Subscriber = aSubscriber then
        begin
          aList.Delete(i);
          break;
        end;
      end;
  finally
    FLock.Leave;
  end;
end;

constructor TDispatcher.Create;
begin
  FLock := TCriticalSection.Create;

  FSnapQueue  := TThreadedQueue<TObject>.Create(10000, 100, 100);

  SetLength(FSnapshotBuffers, 0);

  FSubscribersToWake := TDictionary<ISubscriberInfo, Boolean>.Create;

  FSanpThread:= TDispatchThread.Create(Self, FSnapQueue, tmSnapshot);
end;

destructor TDispatcher.Destroy;
begin
  if FSanpThread <> nil then
  begin
    FSanpThread.Terminate;
    FSanpThread.WaitFor;
    FSanpThread.Free
  end;

  FSnapQueue.Free;

  for var I := 0 to High(FSnapshotBuffers) do
  begin
    if Assigned(FSnapshotBuffers[I]) then
      FSnapshotBuffers[I].Free;
  end;
  SetLength(FSnapshotBuffers, 0);

  for var I := 0 to High(FTopicModes) do
  begin
    if FTopicModes[I] <> nil then
      Dispose(FTopicModes[I]);
  end;
  SetLength(FTopicModes, 0);


  FSubscriptions.Free;
  FSubscribersToWake.Free;

  FLock.Free;
  inherited;
end;

function TDispatcher.GetSnapshotBuffer(Mode: TTopicMode): TSnapshotBuffer;
begin

//  case Mode of
//    tmSequence: ;
//    tmSnapQuote: Result := FSnapshotBuffers;
//
//  end;

end;

procedure TDispatcher.EnqueueData(Topic: TTopic; const Data: TObject);
begin
  if Data = nil then Exit;
  // 토픽(DataID) 유효성 체크
  if (Topic < 0) or (Topic >= Length(FTopicModes)) then Exit;

  FSnapQueue.PushItem(Data);
end;

procedure TDispatcher.Subscribe(aSubscriber: TObject; iDataID: Integer;
  aDataObj: TObject; EventIDs: TDistributorIDs; aHandler: TDistributorEvent);
var
  aList: TList<ISubscriberInfo>;
  Info: ISubscriberInfo;
  bFound: Boolean;
begin

  FLock.Enter;
  try
    if not FSubscriptions.TryGetValue(iDataID, aList) then
    begin
      aList  := TList<ISubscriberInfo>.Create;
      FSubscriptions.Add(iDataID, aList);
    end;

    bFound := false;
    for Info in aList do
      if Info.Subscriber = aSubscriber then
      begin
        bFound := true;
        break;
      end;

    if not bFound then
      aList.Add(TSubscriberInfo.Create(aSubscriber, iDataID, aHandler));

  finally
    FLock.Leave;
  end;
end;

procedure TDispatcher.NotifySubscribers(const Topics: TEnumerable<integer>);
var
  Topic: integer;
  List: TList<ISubscriberInfo>;
  Info: ISubscriberInfo;
begin
  FLock.Enter;
  try
    FSubscribersToWake.Clear;
    for Topic in Topics do
    begin
      if FSubscriptions.TryGetValue(Topic, List) then
      begin
        for Info in List do
        begin
          if IsWindow(Info.Handle) then
          begin
            // Collect unique subscriber objects
            if not FSubscribersToWake.ContainsKey(Info) then
              FSubscribersToWake.Add(Info, True);
          end;
        end;
      end;
    end;

    // Send ONE message per subscriber if NOT BUSY
    for Info in FSubscribersToWake.Keys do
    begin
      if IsWindow(Info.Handle) and (not Info.Busy) then
      begin
        Info.Busy := True;
   //     PostMessage(Info.Handle, WM_DATA_AVAILABLE, 0, 0);
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDispatcher.EnsureArraysCapacity(MaxTopic: TTopic);
var
  OldLen, NewLen, I: Integer;
begin
  if MaxTopic < Length(FTopicModes) then Exit;

  OldLen := Length(FTopicModes);
  NewLen := MaxTopic + 100; // Pad for future updates

  SetLength(FTopicModes, NewLen);
//  SetLength(FRingBuffers, NewLen);
  SetLength(FSnapshotBuffers, NewLen);

  for I := OldLen to NewLen - 1 do
  begin
    FTopicModes[I] := nil;
//    FRingBuffers[I] := nil;
    FSnapshotBuffers[I] := nil;
  end;
end;


// 사용하고 있는 토픽(DataID) 다 등록..   ex) (TRD_DATA , tmSequence)
procedure TDispatcher.RegisterTopic(Topic: TTopic; Mode: TTopicMode);
var
  PMode: PTopicMode;
begin
  if Topic < 0 then Exit;

  FLock.Enter;
  try
    EnsureArraysCapacity(Topic);

    if FTopicModes[Topic] = nil then
    begin
      New(PMode);
      PMode^ := Mode;
      FTopicModes[Topic] := PMode;
    end;

    if Mode = tmSequence then
    begin
//      if FRingBuffers[Topic] = nil then
//        FRingBuffers[Topic] := TRingBuffer.Create(1024);
    end
    else
    begin
      if FSnapshotBuffers[Topic] = nil then
        FSnapshotBuffers[Topic] := TSnapshotBuffer.Create;
    end;
  finally
    FLock.Leave;
  end;
end;

{ TDispatchThread }

constructor TDispatchThread.Create(Owner: TDispatcher;
  Queue: TThreadedQueue<TObject>; Mode: TTopicMode);
begin
  inherited Create(False); // Start immediately
  FOwner := Owner;
  FQueue := Queue;
  FMode  := Mode;
  FreeOnTerminate := False;
end;

procedure TDispatchThread.Execute;
var
  Data: TObject;
  DataID: Integer;

  Snap: TSnapshotBuffer;
  PendingNotifications: TDictionary<integer, Boolean>;
  BatchCount: integer;
begin
  PendingNotifications := TDictionary<integer, Boolean>.Create;
  BatchCount := 0;
  try
    while not Terminated do
    begin
      // Blocking pop with timeout to allow termination check
      if FQueue.PopItem(Data) = TWaitResult.wrSignaled then
      begin
        DataID := Data.InstanceSize;

        // Update Buffer
        if FMode = tmSequence then
        begin
//          Ring := FOwner.GetRingBuffer(DataID);
//          if Assigned(Ring) then
//            Ring.Push(Data);
        end
        else
        begin
          Snap := FOwner.GetSnapshotBuffer(FMode);
          if Assigned(Snap) then
            Snap.Overwrite(Data);
        end;

        // Coalescing: Mark for notification
        if not PendingNotifications.ContainsKey(DataID) then
          PendingNotifications.Add(DataID, True);

        Inc(BatchCount);

        // Flush condition: Queue is empty OR we processed a large batch (avoid starvation)
        if (FQueue.QueueSize = 0) or (BatchCount >= 100) then
        begin
          // NEW: Batch Notification logic
          if PendingNotifications.Count > 0 then
            FOwner.NotifySubscribers(PendingNotifications.Keys);

          PendingNotifications.Clear;
          BatchCount := 0;
        end;
      end;
    end;
  finally
    PendingNotifications.Free;
  end;
end;

{ TSubscriberInfo }

constructor TSubscriberInfo.Create(ASubscriber: TObject; ADataID: integer;
  AHandler: TDistributorEvent);
begin
  FSubscriber := ASubscriber;
  FDataID     := ADataID;
  FHandler    := AHandler;
end;

function TSubscriberInfo.GetBusy: Boolean;
begin
  Result := FBusy;
end;

function TSubscriberInfo.GetDataID: integer;
begin
  Result := FDataID;
end;

function TSubscriberInfo.GetDataObj: TObject;
begin
  Result := FDataObj;
end;

function TSubscriberInfo.GetEventIDs: TDistributorIDs;
begin
  Result := FEventIDs;
end;

function TSubscriberInfo.GetHandle: NativeUInt;
begin
  Result := FHandle;
end;

function TSubscriberInfo.GetHanlder: TDistributorEvent;
begin
  Result := FHandler;
end;

function TSubscriberInfo.GetLastSendTime: TDateTime;
begin
  Result := FLastSendTime;
end;

function TSubscriberInfo.GetSubscriber: TObject;
begin
  Result := FSubscriber;
end;

procedure TSubscriberInfo.SetBusy(Value: Boolean);
begin
  FBusy := Value;
end;

{ TSnapshotBuffer }

constructor TSnapshotBuffer.Create;
begin
  SetLength(FItems, 128); // Pre-allocate initial capacity
  FCount := 0;
  FLastUpdateSeq := 0;
  FLock := TSpinLock.Create(False);
end;

destructor TSnapshotBuffer.Destroy;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FItems[I].Data := nil;
  SetLength(FItems, 0);
  inherited;
end;

function TSnapshotBuffer.FindIndex(const Key: string;
  out Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FCount - 1;
  while L <= H do
  begin
    I := L + (H - L) shr 1;
    C := CompareStr(FItems[I].Key, Key);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
      end;
    end;
  end;
  Index := L;

end;

function TSnapshotBuffer.FetchUpdated(var LastSeq: Int64): TArray<TSnapshotItem>;
var
  I, Count: Integer;
  MaxSeq: Int64;
begin
  FLock.Enter;
  try
    Count := 0;
    MaxSeq := LastSeq;

    // 1st pass: count updated items
    for I := 0 to High(FItems) do
    begin
      if FItems[I].UpdateSeq > LastSeq then
        Inc(Count);
    end;

    SetLength(Result, Count);

    // 2nd pass: extract and find highest sequence seen
    Count := 0;
    for I := 0 to High(FItems) do
    begin
      if FItems[I].UpdateSeq > LastSeq then
      begin
        Result[Count].Data := FItems[I].Data;
        if FItems[I].UpdateSeq > MaxSeq then
          MaxSeq := FItems[I].UpdateSeq;
        Inc(Count);
      end;
    end;

    // Let subscriber know the highest seq seen
    LastSeq := MaxSeq;
  finally
    FLock.Exit;
  end;

end;

procedure TSnapshotBuffer.Overwrite(const Item: TObject);
var
  Index, J: Integer;
  Key: string;
begin
  if Item = nil then Exit;
  Key := '';//Item.GetKey;

  FLock.Enter;
  try
    Inc(FLastUpdateSeq); // Monotonically increase internal state sequence

    if FindIndex(Key, Index) then
    begin
      // Update existing
      FItems[Index].Data := Item;
      FItems[Index].UpdateSeq := FLastUpdateSeq;
    end
    else
    begin
      // Insert new element maintaining sorted order
      if FCount >= Length(FItems) then
        SetLength(FItems, Length(FItems) * 2); // Double capacity

      for J := FCount downto Index + 1 do
        FItems[J] := FItems[J - 1];

      FItems[Index].Key := Key;
      FItems[Index].Data := Item;
      FItems[Index].UpdateSeq := FLastUpdateSeq;
      Inc(FCount);
    end;
  finally
    FLock.Exit;
  end;

end;

end.
