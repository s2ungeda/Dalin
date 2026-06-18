unit UDBTypes;

interface

uses
  System.Classes
  ;

type

  TSignalResult = record
    Code : string;
    StgCode : string;

    E_F_Qty :double;
    E_S_Qty :double;
    X_F_Qty :double;
    X_S_Qty :double;

    E_B_S_Qty :double;
    E_B_L_Qty :double;
    E_U_S_Qty :double;
    E_U_L_Qty :double;
    E_T_S_Qty :double;
    E_T_L_Qty :double;

    X_B_S_Qty :double;
    X_B_L_Qty :double;
    X_U_S_Qty :double;
    X_U_L_Qty :double;
    X_T_S_Qty :double;
    X_T_L_Qty :double;
  end;


implementation

end.

