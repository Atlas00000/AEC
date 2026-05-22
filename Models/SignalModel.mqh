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
   string            detail;
  };

// Per-leg booleans for Phase 0 diagnostics (EDGE-0.1)
struct SignalLegSnapshot
  {
   bool bb;
   bool vol;
   bool buyStruct;
   bool sellStruct;
   bool buyEma;
   bool sellEma;
   bool buyDisp;
   bool sellDisp;
   bool sessBuy;
   bool sessSell;
   bool buyHtf;
   bool sellHtf;
   bool adxOk;
   bool atrRegimeOk;
   bool priorBarOk;

   int BuyLegCount() const
     {
      int n = 0;
      if(bb) n++;
      if(vol) n++;
      if(buyStruct) n++;
      if(buyEma) n++;
      if(buyDisp) n++;
      if(sessBuy) n++;
      if(buyHtf) n++;
      if(adxOk) n++;
      if(atrRegimeOk) n++;
      if(priorBarOk) n++;
      return n;
     }

   int SellLegCount() const
     {
      int n = 0;
      if(bb) n++;
      if(vol) n++;
      if(sellStruct) n++;
      if(sellEma) n++;
      if(sellDisp) n++;
      if(sessSell) n++;
      if(sellHtf) n++;
      if(adxOk) n++;
      if(atrRegimeOk) n++;
      if(priorBarOk) n++;
      return n;
     }

   bool BuyChain() const
     {
      return bb && vol && buyStruct && buyEma && buyDisp && sessBuy && buyHtf && adxOk && atrRegimeOk && priorBarOk;
     }

   bool SellChain() const
     {
      return bb && vol && sellStruct && sellEma && sellDisp && sessSell && sellHtf && adxOk && atrRegimeOk && priorBarOk;
     }
  };

#endif // AEC_SIGNAL_MODEL_MQH
