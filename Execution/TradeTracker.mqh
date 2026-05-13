//+------------------------------------------------------------------+
//| TradeTracker.mqh — open positions by magic + symbol              |
//+------------------------------------------------------------------+
#ifndef AEC_TRADE_TRACKER_MQH
#define AEC_TRADE_TRACKER_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

class CTradeTracker
  {
public:
   static int CountOpen(const string sym, const long magic)
     {
      int n = 0;
      const int total = PositionsTotal();
      for(int i = total - 1; i >= 0; --i)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != sym)
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != magic)
            continue;
         n++;
        }
      return n;
     }

   static int CountOpenDir(const string sym, const long magic, const int dirSign)
     {
      int n = 0;
      const int total = PositionsTotal();
      for(int i = total - 1; i >= 0; --i)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != sym)
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != magic)
            continue;
         const long ptype = PositionGetInteger(POSITION_TYPE);
         if(dirSign > 0 && ptype != POSITION_TYPE_BUY)
            continue;
         if(dirSign < 0 && ptype != POSITION_TYPE_SELL)
            continue;
         n++;
        }
      return n;
     }

   static bool HasRoomForNew(const string sym,
                            const long magic,
                            const int dirSign,
                            string &reason)
     {
      const int all = CountOpen(sym, magic);
      if(all >= InpMaxOpenTrades)
        {
         reason = StringFormat("Max open trades reached: %d >= %d", all, InpMaxOpenTrades);
         return false;
        }
      if(InpSeparateMaxTradesPerDirection)
        {
         const int d = CountOpenDir(sym, magic, dirSign);
         if(d >= InpMaxOpenTradesPerDirection)
           {
            reason = StringFormat("Max per-direction trades: dir=%d count=%d >= %d", dirSign, d, InpMaxOpenTradesPerDirection);
            return false;
           }
        }
      return true;
     }
  };

#endif // AEC_TRADE_TRACKER_MQH
