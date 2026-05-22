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

inline bool SigEma_SlowTrendBuy(const int hSlow, string &detail)
  {
   double s[];
   ArraySetAsSeries(s, true);
   if(CopyBuffer(hSlow, 0, 0, 4, s) <= 0)
     {
      detail = "EMA dir buy slow copy failed";
      return false;
     }
   const bool ok = (s[1] > s[2]);
   detail = StringFormat("EMA dir buy slow1=%.5f slow2=%.5f rising=%s", s[1], s[2], ok ? "Y" : "N");
   return ok;
  }

inline bool SigEma_SlowTrendSell(const int hSlow, string &detail)
  {
   double s[];
   ArraySetAsSeries(s, true);
   if(CopyBuffer(hSlow, 0, 0, 4, s) <= 0)
     {
      detail = "EMA dir sell slow copy failed";
      return false;
     }
   const bool ok = (s[1] < s[2]);
   detail = StringFormat("EMA dir sell slow1=%.5f slow2=%.5f falling=%s", s[1], s[2], ok ? "Y" : "N");
   return ok;
  }

inline bool SigEma_WithinFastEma(const string sym,
                                 const ENUM_TIMEFRAMES tf,
                                 const int hFast,
                                 const int hAtr,
                                 const double maxDistAtrMult,
                                 string &detail)
  {
   detail = "";
   const double c1 = iClose(sym, tf, 1);
   if(c1 <= 0.0)
     {
      detail = "EMA dist bad close";
      return false;
     }
   double f[], atr[];
   ArraySetAsSeries(f, true);
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hFast, 0, 0, 3, f) <= 0)
     {
      detail = "EMA dist fast copy failed";
      return false;
     }
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "EMA dist ATR copy failed";
      return false;
     }
   const double maxDist = atr[1] * maxDistAtrMult;
   const double dist = MathAbs(c1 - f[1]);
   const bool ok = (maxDistAtrMult <= 0.0 || dist <= maxDist);
   detail = StringFormat("EMA dist close=%.5f fast=%.5f dist=%.5f max=%.5f ok=%s",
                         c1, f[1], dist, maxDist, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_EMA_MOMENTUM_MQH
