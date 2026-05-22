//+------------------------------------------------------------------+
//| AdxRegime.mqh — ADX minimum for trend strength (EDGE-4.2)         |
//+------------------------------------------------------------------+
#ifndef AEC_ADX_REGIME_MQH
#define AEC_ADX_REGIME_MQH

inline bool SigAdx_MinOk(const int hAdx, const double minLevel, string &detail)
  {
   detail = "";
   double adx[];
   ArraySetAsSeries(adx, true);
   if(hAdx == INVALID_HANDLE || CopyBuffer(hAdx, 0, 0, 3, adx) <= 0)
     {
      detail = "ADX copy failed";
      return false;
     }
   const bool ok = (minLevel <= 0.0 || adx[1] >= minLevel);
   detail = StringFormat("ADX val=%.2f min=%.2f ok=%s", adx[1], minLevel, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_ADX_REGIME_MQH
