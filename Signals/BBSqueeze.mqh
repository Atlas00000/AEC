//+------------------------------------------------------------------+
//| BBSqueeze.mqh — compression + release (closed bar shift 1)       |
//+------------------------------------------------------------------+
#ifndef AEC_BB_SQUEEZE_MQH
#define AEC_BB_SQUEEZE_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

// MT5 iBands buffers: BASE_LINE=0, UPPER_BAND=1, LOWER_BAND=2
inline bool SigBb_ShiftCompressed(const double &widths[],
                                  const int shift,
                                  const int squeezeLookback,
                                  const double widthRatioTh)
  {
   const int from = shift;
   const int to = shift + squeezeLookback - 1;
   if(to >= ArraySize(widths) || from < 1)
      return false;
   double avg = 0.0;
   for(int k = from; k <= to; ++k)
      avg += widths[k];
   avg /= (double)squeezeLookback;
   return (widths[shift] < avg * widthRatioTh);
  }

inline bool SigBb_Release(const int hBands,
                         const int squeezeLookback,
                         const double widthRatioTh,
                         const bool useMinReleaseQuality,
                         const double minReleaseExpandRatio,
                         const bool useExpansionPersistence,
                         const bool useMinSqueezeDuration,
                         const int minSqueezeBars,
                         string &detail)
  {
   detail = "";
   if(hBands == INVALID_HANDLE)
     {
      detail = "BB handle invalid";
      return false;
     }
   int extra = 0;
   if(useMinSqueezeDuration && minSqueezeBars > 1)
      extra = minSqueezeBars;
   const int need = squeezeLookback + extra + 5;
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
   const int widthMax = squeezeLookback + extra + 2;
   double widths[];
   ArrayResize(widths, widthMax + 1);
   for(int i = 1; i <= widthMax; ++i)
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
   const double w3 = widths[3];

   const bool squeezePlate = (w2 < avg * widthRatioTh);
   bool release = (w1 > w2) && squeezePlate;

   double minW1 = 0.0;
   if(release && useMinReleaseQuality && minReleaseExpandRatio > 1.0)
     {
      minW1 = w2 * minReleaseExpandRatio;
      if(w1 < minW1)
         release = false;
     }

   if(release && useExpansionPersistence)
     {
      if(w2 <= w3)
         release = false;
     }

   int squeezeRun = 0;
   if(release && useMinSqueezeDuration && minSqueezeBars >= 2)
     {
      for(int s = 2; s < 2 + minSqueezeBars; ++s)
        {
         if(!SigBb_ShiftCompressed(widths, s, squeezeLookback, widthRatioTh))
           {
            release = false;
            break;
           }
         squeezeRun++;
        }
     }

   if(useMinReleaseQuality && minReleaseExpandRatio > 1.0)
      detail = StringFormat("BB width1=%.5f width2=%.5f width3=%.5f avg=%.5f minW1=%.5f squeeze=%s persist=%s dur=%d/%d release=%s",
                            w1, w2, w3, avg, minW1, squeezePlate ? "Y" : "N",
                            (w2 > w3) ? "Y" : "N", squeezeRun, minSqueezeBars, release ? "Y" : "N");
   else
      detail = StringFormat("BB width1=%.5f width2=%.5f width3=%.5f avg=%.5f squeeze=%s persist=%s dur=%d/%d release=%s",
                            w1, w2, w3, avg, squeezePlate ? "Y" : "N",
                            (w2 > w3) ? "Y" : "N", squeezeRun, minSqueezeBars, release ? "Y" : "N");
   return release;
  }

// EDGE-4.5 — skip range chop: release bar width must be >= lookback average × ratio
inline bool SigBb_WidthVsAvgOk(const int hBands,
                               const int squeezeLookback,
                               const double minWidthVsAvgRatio,
                               string &detail)
  {
   detail = "";
   if(hBands == INVALID_HANDLE || squeezeLookback < 2)
     {
      detail = "BB chop bad params";
      return false;
     }
   const int need = squeezeLookback + 5;
   double base[], up[], lo[];
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(lo, true);
   if(CopyBuffer(hBands, 0, 0, need, base) <= 0
      || CopyBuffer(hBands, 1, 0, need, up) <= 0
      || CopyBuffer(hBands, 2, 0, need, lo) <= 0)
     {
      detail = "BB chop copy failed";
      return false;
     }

   const int widthMax = squeezeLookback + 2;
   double widths[];
   ArrayResize(widths, widthMax + 1);
   for(int i = 1; i <= widthMax; ++i)
     {
      const double b = base[i];
      if(b == 0.0)
        {
         detail = "BB chop base zero";
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
   const double minW1 = avg * minWidthVsAvgRatio;
   const bool ok = (minWidthVsAvgRatio <= 0.0 || w1 >= minW1);
   detail = StringFormat("BB chop w1=%.5f avg=%.5f min=%.5f mult=%.2f ok=%s",
                         w1, avg, minW1, minWidthVsAvgRatio, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_BB_SQUEEZE_MQH
