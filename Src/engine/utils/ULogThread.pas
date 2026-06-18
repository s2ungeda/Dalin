unit ULogThread;
interface
uses
  System.Classes, System.SysUtils  , Windows, Forms
  , UTypes
  ;
type

  {
  1. LogLevel
  2. PreFix
  3. Data
  }

  TAppLogItem = class( TCollectionItem )
  public
    LogTime   : TDateTime;
    LogSource : string;
    LogTitle  : string;
    LogDesc   : string;
    LogData   : TObject;
  end;

  TAppLogItems = class( TCollection )
  private
    function GetLogItem(i: integer): TAppLogItem;
  public
    LogKind : TLogLevel;
    BLog    : Boolean;
    Critcal : TRtlCriticalSection;

    Constructor Create;
    Destructor  Destroy; override;

    function New( lkValue : TLogLevel ) : TAppLogItem;
    property LogItem[ i : integer] : TAppLogItem read GetLogItem; default;
  end;


implementation
{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,
      Synchronize(UpdateCaption);
  and UpdateCaption could look like,
    procedure TLogThread.UpdateCaption;
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



{ TAppLogItems }

constructor TAppLogItems.Create;
begin
  inherited Create( TAppLogItem );
  BLog  := True;
  InitializeCriticalSection( Critcal );
end;

destructor TAppLogItems.Destroy;
begin
  DeleteCriticalSection( Critcal );
  inherited;
end;

function TAppLogItems.GetLogItem(i: integer): TAppLogItem;
begin
  if ( i<0 ) and ( i>=Count) then
    Result := nil
  else
    Result  := Items[i] as TAppLogItem;
end;

function TAppLogItems.New(lkValue: TLogLevel): TAppLogItem;
begin
  EnterCriticalSection(Critcal);
  LogKind := lkValue;
  Result  := Insert(0) as TAppLogItem;
  Result.LogTime  :=  now;

  if Count > 300 then
    Delete(Count-1);

  LeaveCriticalSection(Critcal)
end;

end.
