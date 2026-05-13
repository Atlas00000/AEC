//+------------------------------------------------------------------+
//| OrderValidator.mqh — pre-send checks                               |
//+------------------------------------------------------------------+
#ifndef AEC_ORDER_VALIDATOR_MQH
#define AEC_ORDER_VALIDATOR_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/Logger.mqh"

class COrderValidator
  {
public:
   static bool TerminalTradeOk(string &reason)
     {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         reason = "Terminal trading disabled";
         return false;
        }
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         reason = "EA trading disabled (button / permissions)";
         return false;
        }
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {
         reason = "Account auto-trading disabled for experts";
         return false;
        }
      return true;
     }

   static bool SymbolTradeOk(const string sym, string &reason)
     {
      const long mode = SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
      if(mode == SYMBOL_TRADE_MODE_DISABLED)
        {
         reason = "Symbol trade mode disabled";
         return false;
        }
      return true;
     }

   static bool VolumeOk(const string sym, const double lots, string &reason)
     {
      const double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
      if(lots < vmin - 1e-12 || lots > vmax + 1e-12)
        {
         reason = StringFormat("Volume out of range: %.5f not in [%.5f, %.5f]", lots, vmin, vmax);
         return false;
        }
      const double steps = (lots - vmin) / vstep;
      if(MathAbs(steps - MathRound(steps)) > 1e-6)
        {
         reason = StringFormat("Volume not aligned to step %.5f", vstep);
         return false;
        }
      return true;
     }

   static bool StopsFreezeOk(const string sym,
                            const ENUM_ORDER_TYPE type,
                            const double entry_price,
                            const double sl_price,
                            const double tp_price,
                            string &reason)
     {
      const int stops = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
      const int freeze = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL);
      const double point = Aec_PointSize(sym);
      if(point <= 0.0)
        {
         reason = "Invalid point size";
         return false;
        }

      const double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      const double ask = SymbolInfoDouble(sym, SYMBOL_ASK);

      if(stops > 0)
        {
         if(type == ORDER_TYPE_BUY)
           {
            if(sl_price > 0.0)
              {
               const double dist_pts = (bid - sl_price) / point;
               if(dist_pts < (double)stops - 1e-8)
                 {
                  reason = StringFormat("SL too close for stops level: dist=%.2f pts < %d", dist_pts, stops);
                  return false;
                 }
              }
            if(tp_price > 0.0)
              {
               const double dist_pts = (tp_price - ask) / point;
               if(dist_pts < (double)stops - 1e-8)
                 {
                  reason = StringFormat("TP too close for stops level: dist=%.2f pts < %d", dist_pts, stops);
                  return false;
                 }
              }
           }
         else if(type == ORDER_TYPE_SELL)
           {
            if(sl_price > 0.0)
              {
               const double dist_pts = (sl_price - ask) / point;
               if(dist_pts < (double)stops - 1e-8)
                 {
                  reason = StringFormat("SL too close for stops level: dist=%.2f pts < %d", dist_pts, stops);
                  return false;
                 }
              }
            if(tp_price > 0.0)
              {
               const double dist_pts = (bid - tp_price) / point;
               if(dist_pts < (double)stops - 1e-8)
                 {
                  reason = StringFormat("TP too close for stops level: dist=%.2f pts < %d", dist_pts, stops);
                  return false;
                 }
              }
           }
        }

      if(freeze > 0)
        {
         // Minimal freeze check vs bid/ask distance for pending-like rules; for market entries log-only soft check
         const double ref = (type == ORDER_TYPE_BUY ? ask : bid);
         if(sl_price > 0.0)
           {
            const double dist_pts = MathAbs(ref - sl_price) / point;
            if(dist_pts < (double)freeze - 1e-8)
              {
               reason = StringFormat("SL inside freeze level: dist=%.2f pts < %d", dist_pts, freeze);
               return false;
              }
           }
        }

      return true;
     }

   static bool ValidateMarket(const string sym,
                             const ENUM_ORDER_TYPE type,
                             const double lots,
                             const double sl_price,
                             const double tp_price,
                             string &reason)
     {
      if(!TerminalTradeOk(reason))
         return false;
      if(!SymbolTradeOk(sym, reason))
         return false;
      if(!VolumeOk(sym, lots, reason))
         return false;

      double entry = 0.0;
      if(type == ORDER_TYPE_BUY)
         entry = SymbolInfoDouble(sym, SYMBOL_ASK);
      else if(type == ORDER_TYPE_SELL)
         entry = SymbolInfoDouble(sym, SYMBOL_BID);
      else
        {
         reason = "Unsupported order type";
         return false;
        }

      if(!StopsFreezeOk(sym, type, entry, sl_price, tp_price, reason))
         return false;

      return true;
     }
  };

#endif // AEC_ORDER_VALIDATOR_MQH
