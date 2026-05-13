//+------------------------------------------------------------------+
//| VolumeExpansion.mqh — tick volume vs SMA (shift 1)               |
//+------------------------------------------------------------------+
#ifndef AEC_VOLUME_EXPANSION_MQH
#define AEC_VOLUME_EXPANSION_MQH
#include "../Config/Inputs.mqh"

inline bool SigVol_Expanded(const string sym,
                           const ENUM_TIMEFRAMES tf,
                           const int lookback,
                           const double mult,
                           string &detail)
  {
   if(lookback <= 1)
     {
      detail = "volume lookback invalid";
      return false;
     }
   long vol[];
   ArraySetAsSeries(vol, true);
   const int need = lookback + 2;
   if(CopyTickVolume(sym, tf, 0, need, vol) <= 0)
     {
      detail = "CopyTickVolume failed";
      return false;
     }
   double sum = 0.0;
   for(int i = 2; i <= lookback + 1; ++i)
      sum += (double)vol[i];
   const double ma = sum / (double)lookback;
   const double v1 = (double)vol[1];
   const bool ok = (ma > 0.0) && (v1 >= ma * mult);
   detail = StringFormat("Vol v1=%.0f ma=%.1f mult=%.2f ok=%s", v1, ma, mult, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_VOLUME_EXPANSION_MQH
