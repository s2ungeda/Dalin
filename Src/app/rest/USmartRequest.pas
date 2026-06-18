unit USmartRequest;

interface

uses
  System.Classes, System.SysUtils, System.DateUtils, System.Generics.Collections,

  System.SyncObjs, UTypes,

  URestRequests, REST.Types

  ;

type

  TAsyncRequestMngr = class
  private
    FReady: TList<TRequest>;
    FWorks: TList<TRequest>;
    FSends: TList<Int64>;
    FOwner: TObject;
    FCriticalSection: TCriticalSection;

    procedure OnResult(Sender: TObject);
    function New: TRequest;

  public
    Constructor Create(Owner: TObject; Capacity: integer);
    Destructor  Destroy; override;

    function IsAvailable : boolean;
//    function GetAvailable
    function GetItem :TRequest;
    function GetReqCount(iSec: integer = 1000): integer;

    function RequestAsync(aReq: TRequest): boolean;

    property Ready : TList<TRequest> read FReady;
    property Wroks : TList<TRequest> read FWorks;
    property Sends : TList<int64> read FSends;

    property Owner : TObject read FOwner;
  end;


implementation

uses
  GApp,
  UApiTypes, UApiConsts, USharedConsts,
  URestBase,
  Windows
  ;


{ TAsyncRequestMngr }

constructor TAsyncRequestMngr.Create(Owner: TObject; Capacity: integer);
var
  I: Integer;
  a: TRequest;
begin

  FOwner  := Owner;

  FReady  := TList<TRequest>.Create;
  FWorks  := TList<TRequest>.Create;
  FSends  := TList<Int64>.CReate;

  FCriticalSection:= TCriticalSection.Create;

  for I := 0 to Capacity-1 do
    FReady.Add(New);

end;

destructor TAsyncRequestMngr.Destroy;
var
  i : integer;
begin

  FCriticalSection.Enter;
  try
    for I := 0 to FReady.Count-1 do
      FReady[i].Free;

    for I := 0 to FWorks.Count-1 do
      FWorks[i].Free;

    FReady.Free;
    FWorks.Free;
    FSends.Free;
  finally
    FCriticalSection.Leave;
    FCriticalSection.Free;
  end;

  inherited;
end;

function TAsyncRequestMngr.New : TRequest;
begin
  Result := TRequest.Create;
  Result.Client.BaseURL := TRestBase(FOwner).BaseUrl;
//  Result.Req.SynchronizedEvents := false;
  Result.OnNotify  := OnResult;
end;

function TAsyncRequestMngr.GetItem: TRequest;
  var
    aReq : TRequest;
begin

//  FCriticalSection.Enter;
  try
    if FReady.Count < 1 then begin
      Result := New;
      //FReady.Add(Result);
    end
    else begin
      Result := FReady.Items[FReady.Count-1];
      FReady.Delete(FReady.Count-1);
  //    FWorks.Add(Result);
    end;

    if Result <> nil then
      FWorks.Add(Result);
  finally
//    FCriticalSection.Leave;
  end;
end;


function TAsyncRequestMngr.GetReqCount(iSec: integer): integer;
var
  I: Integer;
  nTick : int64;
begin
  Result := 0;
  nTick := GetTickCount64;
  for I := FSends.Count-1 downto 0 do
    if iSec >= (nTick - FSends[i]) then
      inc(Result)
    else
      break;

//  if FSends.Count > 5 then
//    App.DebugLog('limit : %d,  %d, %d', [Result, nTick, FSends.Count]);

end;

function TAsyncRequestMngr.IsAvailable: boolean;
begin
  Result := FReady.Count > 0;
end;

procedure TAsyncRequestMngr.OnResult(Sender: TObject);
var
  aReq : TRequest;
  OutJson, OutRes, sRemain : string;
  Res : boolean;
  i : integer;
begin

//  FCriticalSection.Enter;

  try
    aReq := Sender as TRequest;
    try
      try

        with aReq.Req do
        begin

          OutJson:= Response.Content;
          Res  := true;
          if not (Response.StatusCode in [200..201]) then
          begin
            OutRes := Format( 'status : %d, %s', [ Response.StatusCode, Response.StatusText ] );
            Res := false;

            // bithumb
            if (TRestBase(FOwner).ExKind = ekBithumb) and (OutJson.IsEmpty)  then
//            if (OutJson.IsEmpty) or (Response.StatusCode = 403 ) then
              OutJson := Format('{"error":{"name":"%d","message":"%s"}}', [Response.StatusCode, Response.StatusText])
            else if (TRestBase(FOwner).ExKind = ekUpbit) and (Response.StatusCode = 429) then
            begin
              sRemain := aReq.Req.Response.Headers.Values['Remaining-Req'];
              TRestBase(FOwner).MarkExhausted(sRemain);

              OutJson := Format('{"error":{"name":"%d","message":"%s"}}', [Response.StatusCode, Response.StatusText])
            end;
            //
          end;

          if Res and (TRestBase(FOwner).ExKind = ekUpbit) then
          begin
            sRemain := aReq.Req.Response.Headers.Values['Remaining-Req'];
            TRestBase(FOwner).UpdateLRemainValue(sRemain);
          end;

        end;

      except
        on E: Exception do
        begin
          OutRes := E.Message;
          Res := false;
        end
      end;
    finally
      aReq.Req.Params.Clear;
      aReq.Req.Body.ClearBody;

      FWorks.Remove(aReq);
      FReady.Add(aReq);

      with FOwner as TRestBase do
        App.DebugLog('Resp(%d) : %s %s, %s (R:%d, W:%d)', [TThread.Current.ThreadID, TExchangeKindDesc[ExKind],
          aReq.Name, aReq.Field1, FReady.Count, FWorks.Count] );
    end;

    with FOwner as TRestBase do
    begin
      if not Res then
      begin
        var sTmp : string;   sTmp := '---';

        case aReq.Name[1] of
          TR_NEW_ORD : sTmp := 'RequestNewOrder';     // 신규 주문
          TR_CNL_ORD : sTmp := 'RequestCnlOrder';     // 취소 주문
          TR_REQ_ORD : sTmp := 'RequestOrderList';     // 주문 조회..
          TR_REQ_POS : sTmp := 'RequestPosition';     // 포지션 조회..
          TR_REQ_BAL : sTmp := 'RequestBalance';     // 잔고 조회...
          TR_ORD_DETAIL : sTmp := 'RequestOrdDetail';	// 주문상세조회.
        end;

        App.Log( llError, '', 'Failed %s %s %s (%s, %s)',
          [ TExchangeKindDesc[ExKind], TExApiTypeDesc[ExApiType], sTmp, outRes, outJson] );
      end;

      OnResult(aReq.Name[1], OutJson, aReq.Field1);

      aReq.Field1 := '';
    end;
  finally
//    FCriticalSection.Leave;
  end;
end;

function TAsyncRequestMngr.RequestAsync(aReq: TRequest): boolean;
var
  i, iGap: integer;
begin

//  FCriticalSection.Enter;
  try
    Result := aReq.RequestAsync;
    FSends.Add(aReq.StTime);

    with FOwner as TRestBase do
      App.DebugLog('Reqq : %s %s, %s (R:%d, W:%d) %d ', [
        TExchangeKindDesc[ExKind], aReq.Name, aReq.Field1, FReady.Count, FWorks.Count, FSends.Count] );

    iGap := FSends.Count - 500 ;

    while iGap > 0 do
    begin
      FSends.Delete(0);
      Dec(iGap);
    end;
  finally
//    FCriticalSection.Leave;
  end;

end;

//procedure TAsyncRequestMngr.Request(AMethod: TRESTRequestMethod;
//  AResource: string);
//  var
//    aReq : TRequest;
//begin
//  aReq  := FReady.Items[FReady.Count-1];
//  if aReq <> nil then
//  begin
//    FReady.Delete(FReady.Count-1);
//    FWorks.Add(aReq);
//
//    aReq.
//  end;
//
//end;

end.
