unit UExchangeThread;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs,

  Windows,

  UOrders, URestItems,

  UApiTypes, UApiConsts

  ;

const
  BALANCE = 'balance';
  ORD_DETAIL  = 'detail';
  ORD_LIST = 'orderList';

type

  TResData = record
    OutJson : string;
    Order   : TOrder;
    Name    : string;
    procedure Clear;
  end;

  TExchangeThread = class(TThread)
  private
    FEvent  : TEvent;
    FExKind: TExchangeKind;
    FCount, FIndex: integer;
    FData : TResData;
    FRest : TReqeustItem;
    { Private declarations }
    function GetOrderOBO : TOrder;    // one by one
    function GetOrderUpbit : string;
  protected
    procedure Execute; override;
    procedure SyncProc;
  public
    constructor Create(eKind : TExchangeKind);
    destructor Destroy; override;

    property ExKind : TExchangeKind read FExKind write FExKind;
  end;

implementation

uses
  GApp, GLibs, UTypes
  , Rest.Types
  , UEncrypts
  , IdCoderMIME, IdGlobal
  , UBithManager , UUpbitManager
  , UUpbitSpot

  ;

{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TExchangeThread.UpdateCaption;
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

{ TExchangeThread }

constructor TExchangeThread.Create(eKind : TExchangeKind);
begin
  inherited Create(false);
  FreeOnTerminate := false;
  Priority  := tpNormal;

  FEvent  := TEvent.Create( nil, False, False, PChar( ExKindToStr(eKind)+'_Ex_Event') );
  FExKind := eKind;

  FRest   := TReqeustItem.Create;
  FRest.ExKind  :=  eKind;

  FIndex  := 0;
  FCount  := 0;
end;

destructor TExchangeThread.Destroy;
begin
  FEvent.Free;
  FRest.Free;
  inherited;
end;

procedure TExchangeThread.Execute;
var
  idx : integer;
  aOrder : TOrder;
  sTime, sVal, sSig, sBody : string;
  I: Integer;
begin
  { Place thread code here }


  while not terminated do
  begin

    if not( FEvent.WaitFor( TExThreadTimeout[FExKind] ) in [wrSignaled] ) then
    begin

      try
        if App = nil then continue;

//-------------------------------------------------------------------------------------------------
        if FExKind = ekBithumb then
        begin

          if FCount > 3000 then
          begin
            FCount := 0;
            FData.Name    := BALANCE;
            FRest.Req.init(App.Engine.ApiConfig.GetBaseUrl( FExKind, mtSpot ) );
            sTime 	:= GetTimestamp;
            FRest.AResource :=  '/info/balance';
            sVal	:= EncodePath( FRest.AResource, Format('endPoint=%s&currency=%s', [ FRest.AResource, 'ALL'] ), sTime );

            FRest.SetBithumbSig( sVal, sTime );

            with FRest.Req do
            begin
              SetParam('endPoint', '/info/balance', TRESTRequestParameterKind.pkREQUESTBODY);
              SetParam('currency', 'ALL',           TRESTRequestParameterKind.pkREQUESTBODY);

              if not Request( rmPOST, '/info/balance', '', FRest.JsonData, FRest.OutData) then
                 App.Log( llError, '', 'Failed %s ParseBalance-Thread (%s, %s)',
                    [ TExchangeKindDesc[FExKind], FRest.JsonData, FRest.OutData] );
            end;

            FData.OutJson := FRest.JsonData;
            Synchronize( SyncProc );

          end else
          begin

              aOrder := GetOrderOBO;
              if aOrder <> nil then begin
                FData.Order   := aOrder;
                FData.Name    := ORD_DETAIL;

                FRest.Req.init(App.Engine.ApiConfig.GetBaseUrl( FExKind, mtSpot ) );
                FRest.AResource := '/info/order_detail';

                sTime 	:= GetTimestamp;
                sVal		:= EncodePath( FRest.AResource, Format('endPoint=%s&order_id=%s&order_currency=%s',
                  [ FRest.AResource, aOrder.OrderNo, aOrder.Symbol.Code ] ), sTime )  ;

                FRest.SetBithumbSig( sVal, sTime );

                with FRest.Req do
                begin
                  SetParam('endPoint',      FRest.AResource, TRESTRequestParameterKind.pkREQUESTBODY);
                  SetParam('order_id', 			aOrder.OrderNo , TRESTRequestParameterKind.pkREQUESTBODY);
                  SetParam('order_currency',aOrder.Symbol.Code, TRESTRequestParameterKind.pkREQUESTBODY);

                  if not Request( rmPOST, FRest.AResource, '', FRest.JsonData, FRest.OutData) then
                     App.Log( llError, '', 'Failed %s RequestBitOrderDetail-Thread (%s, %s)',
                        [ TExchangeKindDesc[FExKind], FRest.JsonData, FRest.OutData] );
                end;

                FData.OutJson := FRest.JsonData;
                Synchronize( SyncProc );
              end;
          end;

          FData.Clear;

        end else
//-------------------------------------------------------------------------------------------------\
        if FExKind = ekUpbit then
        begin
          {if App.AppStatus < asLoad then }
          continue;
          // 1. 주기적으로 미체결 주문 조회
          if FCount > 4 then
          begin
            FCount := 0;
            continue;
            FData.Name  := ORD_LIST;
            FRest.Req.init(App.Engine.ApiConfig.GetBaseUrl( FExKind, mtSpot ) );

            sBody :=  'state=wait&order_by=desc';
            FRest.SetUpbitSig(sBody);

            if not FRest.Req.Request(rmGET, 'v1/orders?'+sBody, '',  FRest.JsonData, FRest.OutData) then
               App.Log( llError, '', 'Failed %s RequestOrderList 1 -Thread (%s, %s)',
                  [ TExchangeKindDesc[FExKind], FRest.JsonData, FRest.OutData] );

            FData.OutJson := FRest.JsonData;
            Synchronize( SyncProc );
          end
          // 2. 주문 상태 상세 조회
          else begin



              aOrder  := GetOrderOBO;
              if aOrder <> nil then
              begin
                FData.Order   := aOrder;
                FData.Name  := ORD_DETAIL;
                FRest.Req.init(App.Engine.ApiConfig.GetBaseUrl( FExKind, mtSpot ) );
                sBody := 'uuid='+aOrder.OrderNo;
                FRest.SetUpbitSig(sBody);
                if not FRest.Req.Request(rmGET, 'v1/order?'+sBody, '',  FRest.JsonData, FRest.OutData) then
                   App.Log( llError, '', 'Failed %s RequestOrderList 2 - Thread (%s, %s)',
                      [ TExchangeKindDesc[FExKind], FRest.JsonData, FRest.OutData] );

  //              sBody :=  'states[]=done&states[]=cancel';
  //              sVal  :=  GetOrderUpbit;
  //              if sVal = '' then Continue;
  //              sBody := sBody + sVal;
  //              FRest.SetUpbitSig(sBody);
  //              if not FRest.Req.Request(rmGET, 'v1/orders?'+sBody, '',  FRest.JsonData, FRest.OutData) then
  //                 App.Log( llError, '', 'Failed %s RequestOrderList 2 - Thread (%s, %s)',
  //                    [ TExchangeKindDesc[FExKind], FRest.JsonData, FRest.OutData] );

                FData.OutJson := FRest.JsonData;
                Synchronize( SyncProc );
              end;
            end;


          FData.Clear;
        end;

      finally
        inc(FCount);
      end;
    end;

  end;
end;

function TExchangeThread.GetOrderUpbit: string;
begin
  Result := '';
  if App = nil  then Exit;
  if App.Engine = nil then Exit;

  if App.Engine.TradeCore.AOMutex[FExKind] <= 0 then Exit;
  if App.AppStatus >= asClose then Exit;

  WaitForSingleObject(App.Engine.TradeCore.AOMutex[FExKind], INFINITE);
  try
    Result := TUpbitSpot(App.Engine.ApiManager.ExManagers[FExKind]).GetActiveOrderIDForQuery;
  finally
    ReleaseMutex(App.Engine.TradeCore.AOMutex[FExKind]);
  end;

end;

function TExchangeThread.GetOrderOBO: TOrder;
begin
  if App = nil  then Exit;
  if App.Engine = nil then Exit;

  if App.Engine.TradeCore.AOMutex[FExKind] <= 0 then Exit (nil);
  if App.AppStatus >= asClose then Exit (nil);

  WaitForSingleObject(App.Engine.TradeCore.AOMutex[FExKind], INFINITE);

  try
    if FIndex >= App.Engine.TradeCore.Orders[FExKind].ActiveOrders.Count then
      FIndex := 0;
    Result := App.Engine.TradeCore.Orders[FExKind].ActiveOrders.Orders[FIndex];

    FIndex := FIndex +1;
  finally
    ReleaseMutex(App.Engine.TradeCore.AOMutex[FExKind]);
  end;

end;

procedure TExchangeThread.SyncProc;
begin
//  if FData.Order <> nil then
  case FExKind of
    ekBinance: ;
    ekUpbit:
      if FData.Name = ORD_LIST then
        TUpbitManager(App.Engine.ApiManager.ExManagers[FExKind]).Parse.ParseSpotOrderList(FData.OutJson, '')
      else if (FData.Name = ORD_DETAIL) and (FData.Order <> nil) then
        TUpbitManager(App.Engine.ApiManager.ExManagers[FExKind]).Parse.ParseSpotOrderDetail(FData.OutJson, FData.Order.OrderNo) ;
    ekBithumb:
      if (FData.Order <> nil ) and (FData.Name = ORD_DETAIL) then
        TBithManager(App.Engine.ApiManager.ExManagers[FExKind]).Parse.ParseSpotOrderDetail(FData.OutJson, FData.Order.OrderNo)
      else if FData.Name = BALANCE then
        TBithManager(App.Engine.ApiManager.ExManagers[FExKind]).Parse.ParseBalance(FData.OutJson);
  end;
end;

{ TResData }

procedure TResData.Clear;
begin
  OutJson := '';
  Order   := nil;
end;

end.
