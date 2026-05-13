//+------------------------------------------------------------------+
//| StructureBreak.mqh — swing range break on closed bar 1           |
//+------------------------------------------------------------------+
#ifndef AEC_STRUCTURE_BREAK_MQH
#define AEC_STRUCTURE_BREAK_MQH
#include "../Config/Inputs.mqh"

inline bool SigStruct_BuyBreak(const string sym,
                              const ENUM_TIMEFRAMES tf,
                              const int swingLookback,
                              string &detail)
  {
   const int span = MathMax(2, swingLookback);
   const int highest_shift = iHighest(sym, tf, MODE_HIGH, span, 2);
   if(highest_shift < 0)
     {
      detail = "iHighest failed";
      return false;
     }
   const double swingHigh = iHigh(sym, tf, highest_shift);
   const double c1 = iClose(sym, tf, 1);
   const double c2 = iClose(sym, tf, 2);
   const bool brk = (c1 > swingHigh) && (c2 <= swingHigh);
   detail = StringFormat("Struct BUY c1=%.5f swingHigh=%.5f c2=%.5f ok=%s", c1, swingHigh, c2, brk ? "Y" : "N");
   return brk;
  }

inline bool SigStruct_SellBreak(const string sym,
                               const ENUM_TIMEFRAMES tf,
                               const int swingLookback,
                               string &detail)
  {
   const int span = MathMax(2, swingLookback);
   const int lowest_shift = iLowest(sym, tf, MODE_LOW, span, 2);
   if(lowest_shift < 0)
     {
      detail = "iLowest failed";
      return false;
     }
   const double swingLow = iLow(sym, tf, lowest_shift);
   const double c1 = iClose(sym, tf, 1);
   const double c2 = iClose(sym, tf, 2);
   const bool brk = (c1 < swingLow) && (c2 >= swingLow);
   detail = StringFormat("Struct SELL c1=%.5f swingLow=%.5f c2=%.5f ok=%s", c1, swingLow, c2, brk ? "Y" : "N");
   return brk;
  }

#endif // AEC_STRUCTURE_BREAK_MQH
