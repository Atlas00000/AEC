//+------------------------------------------------------------------+
//| SignalModel.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_MODEL_MQH
#define AEC_SIGNAL_MODEL_MQH
#include "../Enums/Types.mqh"

struct SignalResult
  {
   ENUM_TRADE_DIR    direction;
   bool              valid;
   string            reason;
   string            detail; // breakdown for logs
  };

#endif // AEC_SIGNAL_MODEL_MQH
