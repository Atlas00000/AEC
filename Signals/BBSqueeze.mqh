//+------------------------------------------------------------------+
//| BBSqueeze.mqh — compression + release (closed bar shift 1)       |
//+------------------------------------------------------------------+
#ifndef AEC_BB_SQUEEZE_MQH
#define AEC_BB_SQUEEZE_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

// MT5 iBands buffers: BASE_LINE=0, UPPER_BAND=1, LOWER_BAND=2
inline bool SigBb_Release(const int hBands,
                         const int squeezeLookback,
                         const double widthRatioTh,
                         string &detail)
  {
   detail = "";
   if(hBands == INVALID_HANDLE)
     {
      detail = "BB handle invalid";
      return false;
     }
   const int need = squeezeLookback + 5;
   double base[], up[], lo[];
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(lo, true);
   if(CopyBuffer(hBands, 0, 0, need, base) <= 0)
     {
      detail = "CopyBuffer BB base failed";
      return false;
     }
   if(CopyBuffer(hBands, 1, 0, need, up) <= 0)
     {
      detail = "CopyBuffer BB upper failed";
      return false;
     }
   if(CopyBuffer(hBands, 2, 0, need, lo) <= 0)
     {
      detail = "CopyBuffer BB lower failed";
      return false;
     }

   // Width ratio series (shift index: 1 = last closed bar)
   double widths[];
   ArrayResize(widths, squeezeLookback + 3);
   for(int i = 1; i <= squeezeLookback + 2; ++i)
     {
      const double b = base[i];
      if(b == 0.0)
        {
         detail = "BB base zero";
         return false;
        }
      widths[i] = (up[i] - lo[i]) / MathAbs(b);
     }

   double avg = 0.0;
   const int from = 2;
   const int to = 1 + squeezeLookback;
   for(int k = from; k <= to; ++k)
      avg += widths[k];
   avg /= (double)(to - from + 1);

   const double w1 = widths[1];
   const double w2 = widths[2];

   const bool squeezePlate = (w2 < avg * widthRatioTh);
   const bool release = (w1 > w2) && squeezePlate;

   detail = StringFormat("BB width1=%.5f width2=%.5f avg=%.5f squeeze=%s release=%s", w1, w2, avg, squeezePlate ? "Y" : "N", release ? "Y" : "N");
   return release;
  }

#endif // AEC_BB_SQUEEZE_MQH
