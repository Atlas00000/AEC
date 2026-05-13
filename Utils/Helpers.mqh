//+------------------------------------------------------------------+
//| Helpers.mqh — points/pips/symbol helpers                         |
//+------------------------------------------------------------------+
#ifndef AEC_HELPERS_MQH
#define AEC_HELPERS_MQH

inline double Aec_PointSize(const string sym)
  {
   return SymbolInfoDouble(sym, SYMBOL_POINT);
  }

inline int Aec_DigitsCount(const string sym)
  {
   return (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
  }

// FX-style: 1 pip = 10 points for 5-digit / 3-digit JPY style; else 1 point = 1 pip
inline int Aec_PointsPerPip(const string sym)
  {
   const int dg = Aec_DigitsCount(sym);
   if(dg == 3 || dg == 5)
      return 10;
   return 1;
  }

inline int Aec_UserDistanceToPoints(const string sym, const ENUM_SLTP_MODE mode, const int value)
  {
   if(value < 0)
      return 0;
   if(mode == SLTP_MODE_POINTS)
      return value;
   if(mode == SLTP_MODE_PIPS)
      return value * Aec_PointsPerPip(sym);
   return value;
  }

// Caller keeps last seen bar open time; returns true once per new bar (shift 0 time change).
inline bool Aec_IsNewBar(const string sym, const ENUM_TIMEFRAMES tf, datetime &last_bar_open)
  {
   const datetime t0 = iTime(sym, tf, 0);
   if(t0 == 0)
      return false;
   if(t0 == last_bar_open)
      return false;
   last_bar_open = t0;
   return true;
  }

inline int Aec_BarsAvailable(const string sym, const ENUM_TIMEFRAMES tf)
  {
   return Bars(sym, tf);
  }

#endif // AEC_HELPERS_MQH
