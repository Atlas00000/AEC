//+------------------------------------------------------------------+
//| DeadTradeExit.mqh — close stagnant trades (EDGE-6.4)             |
//+------------------------------------------------------------------+
#ifndef AEC_DEAD_TRADE_EXIT_MQH
#define AEC_DEAD_TRADE_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline void Aec_DeadTradeSyncTicketState(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("DEAD_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("DEAD_TICKET", (long)ticket);
      gv.SetInt("DEAD_HIT_MINR", 0);
     }
  }

inline void Aec_DeadTradeClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("DEAD_TICKET");
   gv.DeleteKey("DEAD_HIT_MINR");
  }

inline void Aec_DeadTradeUpdateMinRHit(CGlobalsPersist &gv,
                                       const long pos_type,
                                       const double entry,
                                       const double sl,
                                       const double bid,
                                       const double ask)
  {
   if(gv.GetInt("DEAD_HIT_MINR", 0) != 0)
      return;
   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(Aec_PositionReachedR(pos_type, entry, risk, InpDeadTradeMinR, bid, ask))
      gv.SetInt("DEAD_HIT_MINR", 1);
  }

inline bool Aec_DeadTradeTryCloseOnBar(const string sym,
                                       const ENUM_TIMEFRAMES period,
                                       const long magic,
                                       CGlobalsPersist &gv,
                                       CTradeExecutor &exec)
  {
   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_DeadTradeClearState(gv);
      return false;
     }

   Aec_DeadTradeSyncTicketState(gv, ticket);

   if(gv.GetInt("DEAD_HIT_MINR", 0) != 0)
      return false;

   const datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
   if(open_time == 0)
      return false;

   const int bars_since = iBarShift(sym, period, open_time, true);
   if(bars_since < 0 || bars_since < InpDeadTradeMaxBars)
      return false;

   string er = "";
   if(!exec.ClosePosition(ticket, er))
     {
      CLogger::Info(StringFormat("Dead-trade close failed: %s", er));
      return false;
     }

   CLogger::Info(StringFormat("Dead-trade exit ticket=%I64u bars=%d minR=%.2f not hit",
                              ticket, bars_since, InpDeadTradeMinR));
   Aec_DeadTradeClearState(gv);
   return true;
  }

inline void Aec_DeadTradeManageTick(const string sym,
                                    const ENUM_TIMEFRAMES period,
                                    const long magic,
                                    const double bid,
                                    const double ask,
                                    const bool is_new_bar,
                                    CGlobalsPersist &gv,
                                    CTradeExecutor &exec)
  {
   if(!InpUseDeadTradeExit || !InpAllowTrading)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_DeadTradeClearState(gv);
      return;
     }

   Aec_DeadTradeSyncTicketState(gv, ticket);
   Aec_DeadTradeUpdateMinRHit(gv, pos_type, entry, sl, bid, ask);

   if(is_new_bar)
      Aec_DeadTradeTryCloseOnBar(sym, period, magic, gv, exec);
  }

#endif // AEC_DEAD_TRADE_EXIT_MQH
