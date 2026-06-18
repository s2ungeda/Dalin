unit UConfig;

interface

uses
  system.IniFiles, system.SysUtils
  ;

type

  TProcessInfo = record
    AppName : string;
    ClassName : string;
    Active : boolean;
  end;

  TConfig = record
    LOG_DIR   : string;
    QUOTE_DIR : string;
    DATA_DIR  : string;
    LOG_LEVEL : integer;
    DATA_FILE : string;

//    DATA_FILE2: string;
    VERBOSE  : boolean;

    PrcsInfo : array [0..2] of TProcessInfo;

    VerifyMod : boolean;
    RunMod    : boolean;
    TradeMod  : boolean;
    ReConnInterval : integer;
//    FontName : string;
//    Fontsize : integer;

    function LoadConfig : boolean;
  end;

implementation

{ TConfig }

function TConfig.LoadConfig: boolean;
var
  pIniFile : TIniFile;
  stDir, sSec : string;
begin
  result := true;

  try
    try
      stDir := ExtractFilePath( paramstr(0) )+'Config\';
      pIniFile := TIniFile.Create(stDir + 'Config.txt' );

      /////////////////////////////////////////////////////////////

      LOG_LEVEL := pIniFile.ReadInteger('Log', 'Level', 3);
      VERBOSE   := pIniFile.ReadInteger('Log', 'Verbose', 1) = 1;

      LOG_DIR   := pIniFile.ReadString('Dir', 'LogDir', 'Sauri');
      QUOTE_DIR := pIniFile.ReadString('Dir', 'QuoteDir', 'Sauri');
      DATA_DIR  := pIniFile.ReadString('Dir', 'DataDir', 'Sauri');

      DATA_FILE := pIniFile.ReadString('File', 'DataFile', 'Sauri');
//      DATA_FILE2:= DATA_FILE + '_2';

      /////////////////////////////////////////////////////////////
      VerifyMod  := pIniFile.ReadInteger('ENV', 'VerifyMod', 1) = 1;
      RunMod     := pIniFile.ReadInteger('ENV', 'RunMode', 1) = 1;
      TradeMod   := pIniFile.ReadInteger('ENV', 'TradeMode', 1) = 1;
      ReConnInterval:= pIniFile.ReadInteger('ENV', 'ReConnInterval', 12);

      ////////////////////////////////////////////////////////////////
      sSec  := 'ExRate';
      PrcsInfo[0].AppName   := pIniFile.ReadString(sSec, 'ExFile', 'Sauri');
      PrcsInfo[0].ClassName := pIniFile.ReadString(sSec, 'ClassName', 'Sauri');
      PrcsInfo[0].Active    := pIniFile.ReadInteger(sSec,'Active', 0) = 1;

      sSec  := 'Rest';
      PrcsInfo[1].AppName   := pIniFile.ReadString(sSec , 'ExFile', 'Sauri');
      PrcsInfo[1].ClassName := pIniFile.ReadString(sSec, 'ClassName', 'Sauri');
      if TradeMod then
        PrcsInfo[1].Active  := pIniFile.ReadInteger(sSec,'Active', 0) = 1
      else
        PrcsInfo[1].Active  := false;

      sSec  := 'Key';
      PrcsInfo[2].AppName   := pIniFile.ReadString(sSec , 'ExFile', 'Sauri');
      PrcsInfo[2].ClassName := pIniFile.ReadString(sSec, 'ClassName', 'Sauri');
      PrcsInfo[2].Active    := false;

//      FontName  := pIniFile.ReadString('ENV', 'Font', 'Arial') ;
//      Fontsize  := pIniFile.ReadInteger('ENV', 'Size', 11) ;

    except
      result := false;
    end;
  finally
    pIniFile.Free;
  end;

end;

end.
