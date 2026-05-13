//+------------------------------------------------------------------+
//| SessionBreakout.mqh — optional intraday range by broker hour      |
//+------------------------------------------------------------------+
#ifndef AEC_SESSION_BREAKOUT_MQH
#define AEC_SESSION_BREAKOUT_MQH
#include "../Config/Inputs.mqh"

inline bool SigSession_PassesBuy(const string sym,
                                const ENUM_TIMEFRAMES tf,
                                string &detail)
  {
   if(!InpUseSessionBreakout)
     {
      detail = "Session filter off";
      return true;
     }

   const datetime t1 = iTime(sym, tf, 1);
   if(t1 == 0)
     {
      detail = "Bad bar time";
      return false;
     }

   MqlDateTime dt1;
   TimeToStruct(t1, dt1);

   double hi = -DBL_MAX;
   double lo = DBL_MAX;
   int counted = 0;
   const int max_scan = 500;

   for(int sh = 1; sh < max_scan; ++sh)
     {
      const datetime tt = iTime(sym, tf, sh);
      if(tt == 0)
         break;
      MqlDateTime dtx;
      TimeToStruct(tt, dtx);
      if(dtx.day != dt1.day || dtx.mon != dt1.mon || dtx.year != dt1.year)
         break;

      const int hr = dtx.hour;
      bool inSess = false;
      if(InpSessionStartHour <= InpSessionEndHour)
         inSess = (hr >= InpSessionStartHour && hr < InpSessionEndHour);
      else
         inSess = (hr >= InpSessionStartHour || hr < InpSessionEndHour);

      if(!inSess)
         continue;

      hi = MathMax(hi, iHigh(sym, tf, sh));
      lo = MathMin(lo, iLow(sym, tf, sh));
      counted++;
     }

   if(counted <= 0 || hi <= -DBL_MAX / 2 || lo >= DBL_MAX / 2)
     {
      detail = "Session range empty";
      return false;
     }

   const double c1 = iClose(sym, tf, 1);
   const bool ok = (c1 > hi);
   detail = StringFormat("Session BUY range lo=%.5f hi=%.5f c1=%.5f ok=%s", lo, hi, c1, ok ? "Y" : "N");
   return ok;
  }

inline bool SigSession_PassesSell(const string sym,
                                 const ENUM_TIMEFRAMES tf,
                                 string &detail)
  {
   if(!InpUseSessionBreakout)
     {
      detail = "Session filter off";
      return true;
     }

   const datetime t1 = iTime(sym, tf, 1);
   if(t1 == 0)
     {
      detail = "Bad bar time";
      return false;
     }

   MqlDateTime dt1;
   TimeToStruct(t1, dt1);

   double hi = -DBL_MAX;
   double lo = DBL_MAX;
   int counted = 0;
   const int max_scan = 500;

   for(int sh = 1; sh < max_scan; ++sh)
     {
      const datetime tt = iTime(sym, tf, sh);
      if(tt == 0)
         break;
      MqlDateTime dtx;
      TimeToStruct(tt, dtx);
      if(dtx.day != dt1.day || dtx.mon != dt1.mon || dtx.year != dt1.year)
         break;

      const int hr = dtx.hour;
      bool inSess = false;
      if(InpSessionStartHour <= InpSessionEndHour)
         inSess = (hr >= InpSessionStartHour && hr < InpSessionEndHour);
      else
         inSess = (hr >= InpSessionStartHour || hr < InpSessionEndHour);

      if(!inSess)
         continue;

      hi = MathMax(hi, iHigh(sym, tf, sh));
      lo = MathMin(lo, iLow(sym, tf, sh));
      counted++;
     }

   if(counted <= 0 || hi <= -DBL_MAX / 2 || lo >= DBL_MAX / 2)
     {
      detail = "Session range empty";
      return false;
     }

   const double c1 = iClose(sym, tf, 1);
   const bool ok = (c1 < lo);
   detail = StringFormat("Session SELL range lo=%.5f hi=%.5f c1=%.5f ok=%s", lo, hi, c1, ok ? "Y" : "N");
   return ok;
  }

#endif // AEC_SESSION_BREAKOUT_MQH
