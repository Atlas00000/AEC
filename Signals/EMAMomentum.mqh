//+------------------------------------------------------------------+
//| EMAMomentum.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef AEC_EMA_MOMENTUM_MQH
#define AEC_EMA_MOMENTUM_MQH
#include "../Utils/Logger.mqh"

inline bool SigEma_AlignedBuy(const int hFast, const int hSlow, string &detail)
  {
   double f[], s[];
   ArraySetAsSeries(f, true);
   ArraySetAsSeries(s, true);
   if(CopyBuffer(hFast, 0, 0, 3, f) <= 0 || CopyBuffer(hSlow, 0, 0, 3, s) <= 0)
     {
      detail = "EMA copy failed";
      return false;
     }
   const bool ok = (f[1] > s[1]);
   detail = StringFormat("EMA buy fast=%.5f slow=%.5f ok=%s", f[1], s[1], ok ? "Y" : "N");
   return ok;
  }

inline bool SigEma_AlignedSell(const int hFast, const int hSlow, string &detail)
  {
   double f[], s[];
   ArraySetAsSeries(f, true);
   ArraySetAsSeries(s, true);
   if(CopyBuffer(hFast, 0, 0, 3, f) <= 0 || CopyBuffer(hSlow, 0, 0, 3, s) <= 0)
     {
      detail = "EMA copy failed";
      return false;
     }
   const bool ok = (f[1] < s[1]);
   detail = StringFormat("EMA sell fast=%.5f slow=%.5f ok=%s", f[1], s[1], ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_EMA_MOMENTUM_MQH
