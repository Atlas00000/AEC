//+------------------------------------------------------------------+
//| SignalFeatureCalc.mqh — numeric features at bar 1 (EDGE-AI-3.1)    |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_FEATURE_CALC_MQH
#define AEC_SIGNAL_FEATURE_CALC_MQH

#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"
#include "../Models/SignalFeatureMetrics.mqh"
#include "BBSqueeze.mqh"

inline bool AecSigFeat_BbMetrics(const int hBands,
                                  const int squeezeLookback,
                                  const double widthRatioTh,
                                  double &bb_expand_ratio,
                                  double &bb_width_vs_avg,
                                  int &squeeze_bars)
  {
   bb_expand_ratio = 0.0;
   bb_width_vs_avg = 0.0;
   squeeze_bars = 0;
   if(hBands == INVALID_HANDLE || squeezeLookback < 2)
      return false;

   const int need = squeezeLookback + 8;
   double base[], up[], lo[];
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(lo, true);
   if(CopyBuffer(hBands, 0, 0, need, base) <= 0
      || CopyBuffer(hBands, 1, 0, need, up) <= 0
      || CopyBuffer(hBands, 2, 0, need, lo) <= 0)
      return false;

   const int widthMax = squeezeLookback + 4;
   double widths[];
   ArrayResize(widths, widthMax + 1);
   for(int i = 1; i <= widthMax; ++i)
     {
      const double b = base[i];
      if(b == 0.0)
         return false;
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
   if(w2 > 0.0)
      bb_expand_ratio = w1 / w2;
   if(avg > 0.0)
      bb_width_vs_avg = w1 / avg;

   const int maxShift = widthMax - squeezeLookback + 1;
   for(int s = 2; s <= maxShift; ++s)
     {
      if(!SigBb_ShiftCompressed(widths, s, squeezeLookback, widthRatioTh))
         break;
      squeeze_bars++;
     }
   return true;
  }

inline double AecSigFeat_StructBreakAtr(const string sym,
                                         const ENUM_TIMEFRAMES tf,
                                         const ENUM_TRADE_DIR dir,
                                         const int swingLookback,
                                         const int hAtr)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0 || atr[1] <= 0.0)
      return 0.0;

   const int span = MathMax(2, swingLookback);
   const double c1 = iClose(sym, tf, 1);
   if(c1 <= 0.0)
      return 0.0;

   if(dir == DIR_BUY)
     {
      const int sh = iHighest(sym, tf, MODE_HIGH, span, 2);
      if(sh < 0)
         return 0.0;
      const double swingHigh = iHigh(sym, tf, sh);
      return (c1 - swingHigh) / atr[1];
     }
   if(dir == DIR_SELL)
     {
      const int sh = iLowest(sym, tf, MODE_LOW, span, 2);
      if(sh < 0)
         return 0.0;
      const double swingLow = iLow(sym, tf, sh);
      return (swingLow - c1) / atr[1];
     }
   return 0.0;
  }

inline double AecSigFeat_DisplacementAtr(const string sym,
                                          const ENUM_TIMEFRAMES tf,
                                          const ENUM_TRADE_DIR dir,
                                          const int hAtr)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0 || atr[1] <= 0.0)
      return 0.0;
   const double o1 = iOpen(sym, tf, 1);
   const double c1 = iClose(sym, tf, 1);
   const double body = MathAbs(c1 - o1);
   if(dir == DIR_BUY && c1 <= o1)
      return 0.0;
   if(dir == DIR_SELL && c1 >= o1)
      return 0.0;
   return body / atr[1];
  }

inline double AecSigFeat_PriorBarRangeAtr(const string sym,
                                           const ENUM_TIMEFRAMES tf,
                                           const int hAtr)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0 || atr[1] <= 0.0)
      return 0.0;
   const double h1 = iHigh(sym, tf, 1);
   const double l1 = iLow(sym, tf, 1);
   if(h1 <= l1)
      return 0.0;
   return (h1 - l1) / atr[1];
  }

inline double AecSigFeat_AtrPercentile(const int hAtr, const int lookback)
  {
   if(hAtr == INVALID_HANDLE || lookback < 10)
      return 0.0;
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 1, lookback, atr) <= 0)
      return 0.0;
   const double current = atr[0];
   int below = 0;
   for(int i = 0; i < lookback; ++i)
     {
      if(atr[i] < current)
         below++;
     }
   return 100.0 * (double)below / (double)lookback;
  }

inline double AecSigFeat_AdxValue(const int hAdx)
  {
   double adx[];
   ArraySetAsSeries(adx, true);
   if(hAdx == INVALID_HANDLE || CopyBuffer(hAdx, 0, 0, 3, adx) <= 0)
      return 0.0;
   return adx[1];
  }

inline bool AecSignalFeature_Collect(const string sym,
                                      const ENUM_TIMEFRAMES tf,
                                      const ENUM_TRADE_DIR dir,
                                      const int hBands,
                                      const int hAtr,
                                      const int hAdx,
                                      AecSignalFeatureMetrics &out)
  {
   AecSignalFeatureMetricsClear(out);
   if(dir != DIR_BUY && dir != DIR_SELL)
      return false;

   if(!AecSigFeat_BbMetrics(hBands, InpBbSqueezeLookback, InpBbSqueezeWidthRatio,
                            out.bb_expand_ratio, out.bb_width_vs_avg, out.squeeze_bars))
      return false;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
      return false;
   out.atr_value = atr[1];

   out.struct_break_atr = AecSigFeat_StructBreakAtr(sym, tf, dir, InpSwingLookback, hAtr);
   out.displacement_atr = AecSigFeat_DisplacementAtr(sym, tf, dir, hAtr);
   out.prior_bar_range_atr = AecSigFeat_PriorBarRangeAtr(sym, tf, hAtr);
   if(InpUseAtrPercentileBand && InpAtrPercentileLookback >= 10)
      out.atr_percentile = AecSigFeat_AtrPercentile(hAtr, InpAtrPercentileLookback);
   if(InpUseAdxMinFilter && hAdx != INVALID_HANDLE)
      out.adx_value = AecSigFeat_AdxValue(hAdx);

   out.metrics_ok = true;
   return true;
  }

#endif // AEC_SIGNAL_FEATURE_CALC_MQH
