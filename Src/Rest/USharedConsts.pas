unit USharedConsts;

interface

const
  DATA_SIZE = 1024 * 200;
  Q_SIZE = 200;

  // REST 입장에서..
  REST_PUSH = 1;
  REST_POP  = 0;
  // Dalin 입장에서..
  SHRD_PUSH = 0;
  SHRE_POP  = 1;
  // 바이낸 주문 배열 인덱스
  BO_CNT = 8;
  BO_CODE  = 0;
  BO_LS    = 1;
  BO_PRC   = 2;
  BO_QTY   = 3;
  BO_TYPE  = 4;
  BO_CID   = 5;
  BO_RDO   = 6;     // reduce only
  BO_TIF   = 7;     // timeinforce

  // 바이낸 취소 배열 인덱스
  BC_CNT = 2;
  BC_OID  = 0;
  BC_CODE = 1;

{$REGION '.........upbit.........' }

  // 업비트 주문
  UO_CNT = 5;
  UO_CODE  = 0;
  UO_LS    = 1;
  UO_PRC   = 2;
  UO_QTY   = 3;
  UO_TYPE  = 4;

  // 취소
  UC_CNT = 1;
  UC_UID   = 0;

  // 주문가능
  UA_CNT = 1;
  UA_CODE = 0;

  // 주문 리스트
  UL_CNT = 2;
  UL_STATE = 0;
  UL_ASC = 1;
  // order detail
  UD_CNT = 1;
  UD_UID	= 0;

  // tradeAmt
  UT_CNT = 2;
  UT_STATE = 0;
  UT_ASC = 1;

  U5_CNT = 1;
  U5_CODE = 0;
{$ENDREGION  }

  // 빗썸
  // new order
  TO_CNT= 5;
  TO_CODE  = 0;
  TO_LS    = 1;
  TO_PRC   = 2;
  TO_QTY   = 3;
  TO_TYPE  = 4;

  // cancel order
  TC_CNT = 1;
  TC_OID   = 0;
//  TC_CODE  = 1;
//  TC_LS    = 2;
//  TC_STT   = 3;

  // order list  & trade Amt
  TL_CNT = 1;
  TL_CODE = 0;

  // balance
  TB_CNT = 1;
  TB_CODE = 0; 

  // order detail
  TD_CNT = 2;
  TD_CODE = 0;
  TD_OID	= 1;

  TR_NEW_ORD = 'N';     // 신규 주문
  TR_CNL_ORD = 'C';     // 취소 주문
  TR_REQ_ORD = 'O';     // 주문 조회..
  TR_REQ_POS = 'P';     // 포지션 조회..
  TR_REQ_BAL = 'B';     // 잔고 조회...
  TR_ABLE_ORD= 'A';			// 주문가능금액..
  TR_ORD_DETAIL = 'D';	// 주문상세조회.
  TR_TRD_AMT  = 'T';    // 거래액
  TR_ORD_BOOK = 'H';    // 마켓뎁스..

  TR_DNW_STATE  = 'W';  // 입출금 조회

  EX_BN = 'B';
  EX_UP = 'U';
  EX_BI = 'T';



implementation

end.
