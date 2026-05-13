//+------------------------------------------------------------------+
//| Types.mqh — shared enums                                         |
//+------------------------------------------------------------------+
#ifndef AEC_TYPES_MQH
#define AEC_TYPES_MQH

enum ENUM_LOG_LEVEL
  {
   LOG_ERROR = 0,
   LOG_INFO  = 1,
   LOG_DEBUG = 2,
   LOG_TRACE = 3
  };

enum ENUM_SLTP_MODE
  {
   SLTP_MODE_POINTS = 0,
   SLTP_MODE_PIPS   = 1,
   SLTP_MODE_ATR    = 2
  };

enum EA_STATE
  {
   STATE_IDLE = 0,
   STATE_SIGNAL_PENDING,
   STATE_VALIDATING,
   STATE_EXECUTING,
   STATE_COOLDOWN,
   STATE_BLOCKED
  };

enum ENUM_TRADE_DIR
  {
   DIR_NONE = 0,
   DIR_BUY  = 1,
   DIR_SELL = -1
  };

#endif // AEC_TYPES_MQH
