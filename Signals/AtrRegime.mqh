//+------------------------------------------------------------------+
//| AtrRegime.mqh — ATR percentile band on signal TF (EDGE-4.3)       |
//+------------------------------------------------------------------+
#ifndef AEC_ATR_REGIME_MQH
#define AEC_ATR_REGIME_MQH

inline bool SigAtr_PercentileBandOk(const int hAtr,
                                    const int lookback,
                                    const double pctMin,
                                    const double pctMax,
                                    string &detail)
  {
   detail = "";
   if(hAtr == INVALID_HANDLE || lookback < 10)
     {
      detail = "ATR pct bad params";
      return false;
     }
   if(pctMin < 0.0 || pctMax > 100.0 || pctMin >= pctMax)
     {
      detail = "ATR pct bad range";
      return false;
     }

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 1, lookback, atr) <= 0)
     {
      detail = "ATR pct copy failed";
      return false;
     }

   const double current = atr[0];
   double sorted[];
   ArrayResize(sorted, lookback);
   ArrayCopy(sorted, atr);
   ArraySort(sorted);

   const int idxMin = (int)MathFloor((lookback - 1) * pctMin / 100.0);
   int idxMax = (int)MathFloor((lookback - 1) * pctMax / 100.0);
   idxMax = MathMin(idxMax, lookback - 1);
   idxMax = MathMax(idxMax, idxMin);

   const double thrMin = sorted[idxMin];
   const double thrMax = sorted[idxMax];
   const bool ok = (current >= thrMin && current <= thrMax);
   detail = StringFormat("ATR pct cur=%.5f thr=[%.5f,%.5f] p=%d-%d ok=%s",
                         current, thrMin, thrMax, idxMin, idxMax, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_ATR_REGIME_MQH
