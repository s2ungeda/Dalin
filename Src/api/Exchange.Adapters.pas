unit Exchange.Adapters;

interface

uses
  System.JSON, System.SysUtils, Exchange.Types;

type
  { ¾÷ºñÆ® ¾î´ðÅÍ }
  TUpbitAdapter = class(TInterfacedObject, IExchangeAdapter)
  public
    function GetExchangeName: string;
    function ParseAssetResponse(const AJsonResponse: string): TArray<TAssetInfo>;
  end;

  { ºø½ã ¾î´ðÅÍ (v2 ±âÁØ) }
  TBithumbAdapter = class(TInterfacedObject, IExchangeAdapter)
  public
    function GetExchangeName: string;
    function ParseAssetResponse(const AJsonResponse: string): TArray<TAssetInfo>;
  end;

implementation

{ TUpbitAdapter }

function TUpbitAdapter.GetExchangeName: string;
begin
  Result := 'UPBIT';
end;

function TUpbitAdapter.ParseAssetResponse(const AJsonResponse: string): TArray<TAssetInfo>;
var
  Val: TJSONValue;
  JSONArray: TJSONArray;
  I: Integer;
begin
  Result := nil;
  Val := TJSONObject.ParseJSONValue(AJsonResponse);
  if not Assigned(Val) then Exit;
  try
    if not (Val is TJSONArray) then Exit;
    JSONArray := Val as TJSONArray;
    SetLength(Result, JSONArray.Count);
    for I := 0 to JSONArray.Count - 1 do
    begin
      Result[I].Symbol := JSONArray.Items[I].GetValue<string>('currency');
      Result[I].Available := JSONArray.Items[I].GetValue<Currency>('balance');
      Result[I].Locked := JSONArray.Items[I].GetValue<Currency>('locked');
      Result[I].Total := Result[I].Available + Result[I].Locked;
      Result[I].AvgPrice := JSONArray.Items[I].GetValue<Double>('avg_buy_price');
    end;
  finally
    Val.Free;
  end;
end;

{ TBithumbAdapter }

function TBithumbAdapter.GetExchangeName: string;
begin
  Result := 'BITHUMB';
end;

function TBithumbAdapter.ParseAssetResponse(const AJsonResponse: string): TArray<TAssetInfo>;
var
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  I: Integer;
begin
  Result := nil;
  JSONObj := TJSONObject.ParseJSONValue(AJsonResponse) as TJSONObject;
  if not Assigned(JSONObj) then Exit;

  try
    // ºø½ãÀÇ ÀÀ´ä { "status": "...", "data": [...] } ÇüÅÂ
    if JSONObj.TryGetValue<TJSONArray>('data', JSONArray) then
    begin
      SetLength(Result, JSONArray.Count);
      for I := 0 to JSONArray.Count - 1 do
      begin
        Result[I].Symbol := JSONArray.Items[I].GetValue<string>('symbol');
        Result[I].Available := JSONArray.Items[I].GetValue<Currency>('available');
        Result[I].Locked := JSONArray.Items[I].GetValue<Currency>('frozen');
        Result[I].Total := Result[I].Available + Result[I].Locked;
        Result[I].AvgPrice := JSONArray.Items[I].GetValue<Double>('avg_price');
      end;
    end;
  finally
    JSONObj.Free;
  end;
end;

end.
