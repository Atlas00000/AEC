//+------------------------------------------------------------------+
//| TradeExecutor.mqh — market orders, filling preference, retries   |
//+------------------------------------------------------------------+
#ifndef AEC_TRADE_EXECUTOR_MQH
#define AEC_TRADE_EXECUTOR_MQH
#include <Trade/Trade.mqh>
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

class CTradeExecutor
  {
   CTrade m_trade;
public:
   void Configure()
     {
      m_trade.SetExpertMagicNumber((int)InpMagic);
      m_trade.SetDeviationInPoints((uint)MathMax(0, InpMaxSlippagePoints));
      m_trade.SetTypeFilling(PickFilling(_Symbol));
      m_trade.SetAsyncMode(false);
     }

   static ENUM_ORDER_TYPE_FILLING PickFilling(const string sym)
     {
      const uint fm = (uint)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);
      if((fm & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
         return ORDER_FILLING_FOK;
      if((fm & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

   bool OpenMarket(const string sym,
                  const ENUM_ORDER_TYPE type,
                  const double lots,
                  const double sl_price,
                  const double tp_price,
                  string &reason)
     {
      Configure();

      const int maxr = (int)MathMax(0, InpMaxOrderRetries);
      for(int attempt = 0; attempt <= maxr; ++attempt)
        {
         m_trade.SetTypeFilling(ORDER_FILLING_FOK);
         if(TryOnce(sym, type, lots, sl_price, tp_price, reason))
            return true;

         const uint rc = m_trade.ResultRetcode();
         if(attempt < maxr && (rc == TRADE_RETCODE_REQUOTE || rc == TRADE_RETCODE_PRICE_OFF || rc == TRADE_RETCODE_TOO_MANY_REQUESTS || rc == TRADE_RETCODE_LOCKED))
           {
            CLogger::Debug(StringFormat("Retry open after retcode=%u attempt=%d", rc, attempt + 1));
            Sleep(50);
            continue;
           }

         const uint fm = (uint)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);
         if((fm & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
           {
            m_trade.SetTypeFilling(ORDER_FILLING_IOC);
            if(TryOnce(sym, type, lots, sl_price, tp_price, reason))
               return true;
           }

         reason = StringFormat("Open failed retcode=%u comment=%s", m_trade.ResultRetcode(), m_trade.ResultComment());
         return false;
        }

      reason = "Open failed: retries exhausted";
      return false;
     }

private:
   bool TryOnce(const string sym,
               const ENUM_ORDER_TYPE type,
               const double lots,
               const double sl_price,
               const double tp_price,
               string &reason)
     {
      const bool ok = (type == ORDER_TYPE_BUY)
                      ? m_trade.Buy(lots, sym, 0.0, sl_price, tp_price, "AEC")
                      : m_trade.Sell(lots, sym, 0.0, sl_price, tp_price, "AEC");
      if(!ok)
        {
         reason = StringFormat("Trade request failed retcode=%u %s", m_trade.ResultRetcode(), m_trade.ResultComment());
         return false;
        }
      CLogger::Info(StringFormat("Opened ticket=%I64u", m_trade.ResultOrder()));
      return true;
     }

public:
   bool ClosePosition(const ulong ticket, string &reason)
     {
      Configure();
      if(ticket == 0 || !PositionSelectByTicket(ticket))
        {
         reason = "position not found";
         return false;
        }
      if(!m_trade.PositionClose(ticket))
        {
         reason = StringFormat("Close failed retcode=%u %s",
                               m_trade.ResultRetcode(), m_trade.ResultComment());
         return false;
        }
      CLogger::Info(StringFormat("Closed ticket=%I64u", ticket));
      return true;
     }

   bool ModifyPositionSl(const ulong ticket, const double new_sl, string &reason)
     {
      Configure();
      if(ticket == 0 || !PositionSelectByTicket(ticket))
        {
         reason = "position not found";
         return false;
        }

      const string sym = PositionGetString(POSITION_SYMBOL);
      const double tp = PositionGetDouble(POSITION_TP);
      const int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      const double sl_norm = NormalizeDouble(new_sl, dg);

      if(!m_trade.PositionModify(ticket, sl_norm, tp))
        {
         reason = StringFormat("Modify SL failed retcode=%u %s",
                               m_trade.ResultRetcode(), m_trade.ResultComment());
         return false;
        }
      return true;
     }

   bool ModifySlToBreakeven(const ulong ticket, string &reason)
     {
      if(ticket == 0 || !PositionSelectByTicket(ticket))
        {
         reason = "position not found";
         return false;
        }

      const string sym = PositionGetString(POSITION_SYMBOL);
      const long pos_type = PositionGetInteger(POSITION_TYPE);
      const double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      const double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      const double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      const double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      const int stops_lvl = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
      const double min_dist = (double)MathMax(stops_lvl, 1) * pt;

      double new_sl = entry;
      if(pos_type == POSITION_TYPE_BUY)
        {
         const double cap = bid - min_dist;
         if(new_sl > cap)
            new_sl = cap;
        }
      else if(pos_type == POSITION_TYPE_SELL)
        {
         const double cap = ask + min_dist;
         if(new_sl < cap)
            new_sl = cap;
        }
      else
        {
         reason = "unknown position type";
         return false;
        }

      if(!ModifyPositionSl(ticket, new_sl, reason))
         return false;

      CLogger::Info(StringFormat("SL -> BE ticket=%I64u sl=%.5f", ticket, new_sl));
      return true;
     }

   bool PartialCloseVolume(const ulong ticket, const double close_volume, string &reason)
     {
      Configure();
      if(ticket == 0 || !PositionSelectByTicket(ticket))
        {
         reason = "position not found";
         return false;
        }
      if(close_volume <= 0.0)
        {
         reason = "close volume <= 0";
         return false;
        }
      if(!m_trade.PositionClosePartial(ticket, close_volume))
        {
         reason = StringFormat("Partial close failed retcode=%u %s",
                               m_trade.ResultRetcode(), m_trade.ResultComment());
         return false;
        }
      CLogger::Info(StringFormat("Partial close ticket=%I64u vol=%.5f", ticket, close_volume));
      return true;
     }
  };

#endif // AEC_TRADE_EXECUTOR_MQH
