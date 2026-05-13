//+------------------------------------------------------------------+
//| TradeModel.mqh — lightweight validation / sizing context         |
//+------------------------------------------------------------------+
#ifndef AEC_TRADE_MODEL_MQH
#define AEC_TRADE_MODEL_MQH
#include "../Enums/Types.mqh"

struct SltpPlan
  {
   double   sl_price;
   double   tp_price;
   int      sl_points;     // normalized distance in points
   int      tp_points;
   string   note;
  };

#endif // AEC_TRADE_MODEL_MQH
