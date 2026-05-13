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

#endif // AEC_DISPLACEMENT_MQH
