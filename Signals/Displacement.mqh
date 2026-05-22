//+------------------------------------------------------------------+
//| Displacement.mqh — body vs ATR on closed bar 1                   |
//+------------------------------------------------------------------+
#ifndef AEC_DISPLACEMENT_MQH
#define AEC_DISPLACEMENT_MQH

inline bool SigDisp_Bull(const string sym,
                        const ENUM_TIMEFRAMES tf,
                        const int hAtr,
                        const double bodyAtrMult,
                        string &detail)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "ATR copy failed";
      return false;
     }
   const double o1 = iOpen(sym, tf, 1);
   const double c1 = iClose(sym, tf, 1);
   const double body = MathAbs(c1 - o1);
   const bool bull = (c1 > o1);
   const bool ok = bull && (body >= atr[1] * bodyAtrMult);
   detail = StringFormat("Disp bull body=%.5f atr=%.5f mult=%.2f ok=%s", body, atr[1], bodyAtrMult, ok ? "Y" : "N");
   return ok;
  }

inline bool SigDisp_Bear(const string sym,
                        const ENUM_TIMEFRAMES tf,
                        const int hAtr,
                        const double bodyAtrMult,
                        string &detail)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "ATR copy failed";
      return false;
     }
   const double o1 = iOpen(sym, tf, 1);
   const double c1 = iClose(sym, tf, 1);
   const double body = MathAbs(c1 - o1);
   const bool bear = (c1 < o1);
   const bool ok = bear && (body >= atr[1] * bodyAtrMult);
   detail = StringFormat("Disp bear body=%.5f atr=%.5f mult=%.2f ok=%s", body, atr[1], bodyAtrMult, ok ? "Y" : "N");
   return ok;
  }

inline bool SigBar_MinRangeOk(const string sym,
                             const ENUM_TIMEFRAMES tf,
                             const int hAtr,
                             const double rangeAtrMult,
                             string &detail)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "Bar range ATR copy failed";
      return false;
     }
   const double h1 = iHigh(sym, tf, 1);
   const double l1 = iLow(sym, tf, 1);
   if(h1 <= 0.0 || l1 <= 0.0 || h1 < l1)
     {
      detail = "Bar range bad OHLC";
      return false;
     }
   const double rng = h1 - l1;
   const double minRng = atr[1] * rangeAtrMult;
   const bool ok = (rangeAtrMult <= 0.0 || rng >= minRng);
   detail = StringFormat("Bar range rng=%.5f min=%.5f atr=%.5f mult=%.2f ok=%s",
                         rng, minRng, atr[1], rangeAtrMult, ok ? "Y" : "N");
   return ok;
  }

// EDGE-4.4 — block signal bar when high-low range exceeds cap (volatility shock)
inline bool SigBar_MaxRangeOk(const string sym,
                              const ENUM_TIMEFRAMES tf,
                              const int hAtr,
                              const double maxRangeAtrMult,
                              string &detail)
  {
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "Bar max range ATR copy failed";
      return false;
     }
   const double h1 = iHigh(sym, tf, 1);
   const double l1 = iLow(sym, tf, 1);
   if(h1 <= 0.0 || l1 <= 0.0 || h1 < l1)
     {
      detail = "Bar max range bad OHLC";
      return false;
     }
   const double rng = h1 - l1;
   const double maxRng = atr[1] * maxRangeAtrMult;
   const bool ok = (maxRangeAtrMult <= 0.0 || rng <= maxRng);
   detail = StringFormat("Bar max rng=%.5f max=%.5f atr=%.5f mult=%.2f ok=%s",
                         rng, maxRng, atr[1], maxRangeAtrMult, ok ? "Y" : "N");
   return ok;
  }

inline bool SigClose_BuyStrength(const string sym,
                                 const ENUM_TIMEFRAMES tf,
                                 const double minPosition,
                                 string &detail)
  {
   const double h1 = iHigh(sym, tf, 1);
   const double l1 = iLow(sym, tf, 1);
   const double c1 = iClose(sym, tf, 1);
   if(h1 <= l1 || c1 <= 0.0)
     {
      detail = "Close str buy flat bar";
      return false;
     }
   const double pos = (c1 - l1) / (h1 - l1);
   const bool ok = (pos >= minPosition);
   detail = StringFormat("Close str buy pos=%.3f min=%.2f ok=%s", pos, minPosition, ok ? "Y" : "N");
   return ok;
  }

inline bool SigClose_SellStrength(const string sym,
                                  const ENUM_TIMEFRAMES tf,
                                  const double minPosition,
                                  string &detail)
  {
   const double h1 = iHigh(sym, tf, 1);
   const double l1 = iLow(sym, tf, 1);
   const double c1 = iClose(sym, tf, 1);
   if(h1 <= l1 || c1 <= 0.0)
     {
      detail = "Close str sell flat bar";
      return false;
     }
   const double pos = (c1 - l1) / (h1 - l1);
   const double maxPos = 1.0 - minPosition;
   const bool ok = (pos <= maxPos);
   detail = StringFormat("Close str sell pos=%.3f max=%.2f ok=%s", pos, maxPos, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_DISPLACEMENT_MQH
