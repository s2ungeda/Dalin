program Rest;

uses
  Vcl.Forms,
  Windows,
  FRestMain in 'FRestMain.pas' {FrmRestMain},
  GApp in 'GApp.pas',
  URestManager in 'URestManager.pas',
  UBinFutRequests in 'UBinFutRequests.pas',
  URestBase in 'URestBase.pas',
  UBinSpotRequests in 'UBinSpotRequests.pas',
  UBinFutCmRequests in 'UBinFutCmRequests.pas',
  UUpbitRequests in 'UUpbitRequests.pas',
  UBithumbRequests in 'UBithumbRequests.pas',
  UExchangeApi in 'UExchangeApi.pas',
  USmartRequest in 'USmartRequest.pas',
  UApiConfigManager in '..\..\api\UApiConfigManager.pas',
  UApiConsts in '..\..\api\UApiConsts.pas',
  UApiTypes in '..\..\api\UApiTypes.pas',
  URestRequests in '..\..\api\URestRequests.pas',
  GLibs in '..\..\engine\common\GLibs.pas',
  UConfig in '..\..\engine\common\UConfig.pas',
  UConsts in '..\..\engine\common\UConsts.pas',
  UEncrypts in '..\..\engine\common\UEncrypts.pas',
  UTypes in '..\..\engine\common\UTypes.pas',
  UDecimalHelper in '..\..\engine\utils\UDecimalHelper.pas',
  ULogWriter in '..\..\engine\utils\ULogWriter.pas',
  USecureString in '..\..\engine\utils\USecureString.pas',
  USimpleShareMemory in '..\..\engine\utils\USimpleShareMemory.pas',
  USharedConsts in '..\..\Rest\USharedConsts.pas',
  USharedData in '..\..\Rest\USharedData.pas',
  USharedThread in '..\..\Rest\USharedThread.pas';

var MutexHandle : longint;
{$R *.res}

begin

  MutexHandle := CreateMutex(nil, true, 'DaLCoMiN_Rest');
  if GetlastError() = ERROR_ALREADY_EXISTS then begin
    Application.MessageBox('Rest 프로그램이 이미 실행 중입니다.','경고',0 );
    Halt;
  end;

  if ParamCount = 0 then
  begin
    Application.MessageBox('잘못된 실행. 프로그램 종료','경고',0 );
    Halt;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmRestMain, FrmRestMain);
  Application.Run;
end.
