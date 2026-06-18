unit UApiMaps;

interface

uses
  WinApi.Windows,
  System.Classes, System.SysUtils,  System.Variants
  , UApiTypes, UApiConsts
  ;

const
  DATA_SIZE = 1024 * 100;
  Q_SIZE = 100;


type

  TDataItem = packed record
    Data  : array [0..DATA_SIZE-1] of Ansichar;
    Size  : array [0..4] of AnsiChar;
  end;

  PSharedData = ^TSharedData;
  TSharedData = record
    SharedData : array [0..Q_SIZE-1] of TDataItem;
    WCnt, RCnt : integer;
  end;

implementation

end.
