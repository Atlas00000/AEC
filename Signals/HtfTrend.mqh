//+------------------------------------------------------------------+
//| HtfTrend.mqh — higher-TF EMA trend (EDGE-4.1)                    |
//+------------------------------------------------------------------+
#ifndef AEC_HTF_TREND_MQH
#define AEC_HTF_TREND_MQH

inline bool SigHtf_TrendBuy(const int hHtfEma,
                            const string sym,
                            const ENUM_TIMEFRAMES htf,
                            string &detail)
  {
   detail = "";
   double ema[];
   ArraySetAsSeries(ema, true);
   if(hHtfEma == INVALID_HANDLE || CopyBuffer(hHtfEma, 0, 0, 3, ema) <= 0)
     {
      detail = "HTF EMA copy failed";
      return false;
     }
   const double c1 = iClose(sym, htf, 1);
   if(c1 <= 0.0)
     {
      detail = "HTF bad close";
      return false;
     }
   const bool ok = (c1 > ema[1]);
   detail = StringFormat("HTF buy close=%.5f ema=%.5f ok=%s", c1, ema[1], ok ? "Y" : "N");
   return ok;
  }

inline bool SigHtf_TrendSell(const int hHtfEma,
                             const string sym,
                             const ENUM_TIMEFRAMES htf,
                             string &detail)
  {
   detail = "";
   double ema[];
   ArraySetAsSeries(ema, true);
   if(hHtfEma == INVALID_HANDLE || CopyBuffer(hHtfEma, 0, 0, 3, ema) <= 0)
     {
      detail = "HTF EMA copy failed";
      return false;
     }
   const double c1 = iClose(sym, htf, 1);
   if(c1 <= 0.0)
     {
      detail = "HTF bad close";
      return false;
     }
   const bool ok = (c1 < ema[1]);
   detail = StringFormat("HTF sell close=%.5f ema=%.5f ok=%s", c1, ema[1], ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_HTF_TREND_MQH
