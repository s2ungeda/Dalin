unit UTypes;
interface

uses
  messages
  ;

const

  RES_WT = 100;
  RES_WT_LIST = 101;

  Mk = 0;
  TK = 1;

type

  TDistributorID = 0..255;
  TDistributorIDs = set of TDistributorID;

  TDistributorEvent = procedure(Sender, Receiver: TObject; DataID: Integer;
    DataObj: TObject; EventID: TDistributorID) of object;

  TAppStatus = ( asNone, asInit, asSetValue, asRecovery, asLoad, asShow, asClose );

  TAppStatusEvent  = procedure( asType : TAppStatus ) of object;
  TQuoteType = (qtNone, qtMarketDepth, qtTimeNSale, qtCustom, qtUnknown);
  TPositionType = (ptLong, ptShort);
  TPositionTypes = set of TPositionType;
  TSideType = ( stLong, stShort );

  TSPType = ( spMajor, spSub );
  TSymbolCountryType = ( scDomes, scInter );  // domestic , international
  TAutoOrderType = ( aoEntry, aoExit );

  TLogLevel = (llError, llWarning, llInfo, llDebug);
  TLogFileType = (lfLog, lfCsv);

  TWinParam = record
    FontName : string;
    FontSize : integer;
    FTerm    : integer;
  end;

  TResultMesage = record
    Code : integer;
    Reason : string;
    ResType: integer;
//    procedure SetMessage(iCode: integer; sReason:string);
  end;

  TObjectNotifyEvent = procedure(Sender: TObject) of object;
  TTextNotifyEvent = procedure(Sender: TObject; Value: String) of object;
  TIntNotifyEVent  = procedure(Sender: TObject; Value: Integer) of object;
  TResultNotifyEvent = procedure(Sender: TObject; Result : TResultMesage) of object;


const
	WM_EXRATE_MESSAGE = WM_USER + $0001;
  WM_LOGARRIVED     = WM_USER + $0002;
  WM_DETECTEDDEBUGER= WM_USER + $0003;


implementation


{ TResultMesage }

//procedure TResultMesage.SetMessage(iCode: integer; sReason: string);
//begin
//  Code := iCode;
//  Reason := sReason;
//end;

end.
