unit UQueryExRate;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Net.HttpClient, System.Net.HttpClientComponent, 
  System.DateUtils, System.IOUtils, System.Generics.Collections;

type
  TExRateThread = class(TThread)
  private
    FUrl: string;
    FLogFile: string;
    FLastId: string;
    FOnLog: TProc<string>;
    procedure LogResult(const APrice: string);
  protected
    procedure Execute; override;
  public
    constructor Create;
    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

implementation

{ TExRateThread }

constructor TExRateThread.Create;
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FUrl := 'https://www.moonkomp.com/exrate/api_latest.php?limit=3';
  FLastId := '';
  // Log file in the same directory as the executable
  FLogFile := ChangeFileExt(ParamStr(0), '') + '_exchangeRate.log';
  // Or strictly "exchangeRate.log" as requested, potentially in current dir? 
  // Requirement: "exchangeRate.log 파일에 업데이트 한다."
  // Safe bet: ExtractFilePath(ParamStr(0)) + 'exchangeRate.log'
  FLogFile := ExtractFilePath(ParamStr(0)) + 'Data/exchangeRate.log';
end;

procedure TExRateThread.Execute;
var
  LClient: TNetHTTPClient;
  LResponse: IHTTPResponse;
  LJsonObj, LItem: TJSONObject;
  LDataArray: TJSONArray;
  LPriceStr, LId: string;
  LFormatSettings: TFormatSettings;
begin
  LClient := TNetHTTPClient.Create(nil);
  try
    // Use invariant culture for consistent float parsing if needed, 
    // but we are treating price as string for logging mostly, or simple conversion.
    LFormatSettings := TFormatSettings.Invariant;

    while not Terminated do
    begin
      try
        LResponse := LClient.Get(FUrl);
        if LResponse.StatusCode = 200 then
        begin
          LJsonObj := TJSONObject.ParseJSONValue(LResponse.ContentAsString(TEncoding.UTF8)) as TJSONObject;
          try
            if Assigned(LJsonObj) then
            begin
              LDataArray := LJsonObj.GetValue<TJSONArray>('data');
              if Assigned(LDataArray) and (LDataArray.Count > 0) then
              begin
                LItem := LDataArray.Items[0] as TJSONObject;
                if Assigned(LItem) then
                begin
                   // Get ID to check for duplicates
                   LId := LItem.GetValue<string>('id');
                   
                   // Only process if ID has changed (is new)
                   if (LId <> '') and (LId <> FLastId) then
                   begin
                     // The API returns price as string, e.g. "1447.5800"
                     LPriceStr := LItem.GetValue<string>('price');
                     if LPriceStr <> '' then
                     begin
                       LogResult(LPriceStr);
                       FLastId := LId;
                     end;
                   end;
                end;
              end;
            end;
          finally
            LJsonObj.Free;
          end;
        end;
      except
        // Ignore errors
      end;
      
      // Wait 2 seconds
      Sleep(2000);
    end;
  finally
    LClient.Free;
  end;
end;

procedure TExRateThread.LogResult(const APrice: string);
var
  LLine: string;     i:integer;
begin
  // Format: UpdateDateTime,ExchangeRate
  // Example: 2026-02-02 17:30:21,1455.37
  LLine := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ',' + APrice;

  for I := 0 to 2 do
  begin
    try
      TFile.WriteAllText(FLogFile, LLine, TEncoding.UTF8);
      Break; // Success
    except
      // If we failed and it's not the last attempt, wait a bit
      if I < 2 then
        Sleep(100)
      else
      begin
        // On final failure, we might want to log purely to debug output if available,
        // or just accept the loss of this sample to avoid crashing.
        // Existing code swallowed errors, so we primarily aim to reduce them.
      end;
    end;
  end;
  
  try
    TFile.WriteAllText(FLogFile, LLine, TEncoding.UTF8);
    
    if Assigned(FOnLog) then
    begin
      Synchronize(procedure
        begin
          FOnLog(LLine);
        end);
    end;
  except
    // Handle file access errors
  end;
end;

end.
