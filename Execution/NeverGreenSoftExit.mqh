//+------------------------------------------------------------------+
//| NeverGreenSoftExit.mqh — soft time stop (EDGE-6.11)              |
//+------------------------------------------------------------------+
#ifndef AEC_NEVER_GREEN_SOFT_EXIT_MQH
#define AEC_NEVER_GREEN_SOFT_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline void Aec_NeverGreenSoftSyncTicket(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("NG_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("NG_TICKET", (long)ticket);
      gv.SetInt("NG_HIT_MINR", 0);
     }
  }

inline void Aec_NeverGreenSoftClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("NG_TICKET");
   gv.DeleteKey("NG_HIT_MINR");
  }

inline void Aec_NeverGreenSoftUpdateMinRHit(CGlobalsPersist &gv,
                                            const long pos_type,
                                            const double entry,
                                            const double sl,
                                            const double bid,
                                            const double ask)
  {
   if(gv.GetInt("NG_HIT_MINR", 0) != 0)
      return;
   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(Aec_PositionReachedR(pos_type, entry, risk, InpSoftNeverGreenMinR, bid, ask))
      gv.SetInt("NG_HIT_MINR", 1);
  }

inline bool Aec_NeverGreenSoftTryCloseOnBar(const string sym,
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
      Aec_NeverGreenSoftClearState(gv);
      return false;
     }

   Aec_NeverGreenSoftSyncTicket(gv, ticket);

   if(gv.GetInt("NG_HIT_MINR", 0) != 0)
      return false;

   const datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
   if(open_time == 0)
      return false;

   const int bars_since = iBarShift(sym, period, open_time, true);
   if(bars_since < 0 || bars_since < InpSoftNeverGreenMaxBars)
      return false;

   string er = "";
   if(!exec.ClosePosition(ticket, er))
     {
      CLogger::Info(StringFormat("Soft never-green close failed: %s", er));
      return false;
     }

   CLogger::Info(StringFormat("Soft never-green exit ticket=%I64u bars=%d minR=%.2f not hit",
                              ticket, bars_since, InpSoftNeverGreenMinR));
   Aec_NeverGreenSoftClearState(gv);
   return true;
  }

inline void Aec_NeverGreenSoftManageTick(const string sym,
                                         const ENUM_TIMEFRAMES period,
                                         const long magic,
                                         const double bid,
                                         const double ask,
                                         const bool is_new_bar,
                                         CGlobalsPersist &gv,
                                         CTradeExecutor &exec)
  {
   if(!InpUseSoftNeverGreenExit || !InpAllowTrading)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_NeverGreenSoftClearState(gv);
      return;
     }

   Aec_NeverGreenSoftSyncTicket(gv, ticket);
   Aec_NeverGreenSoftUpdateMinRHit(gv, pos_type, entry, sl, bid, ask);

   if(is_new_bar)
      Aec_NeverGreenSoftTryCloseOnBar(sym, period, magic, gv, exec);
  }

#endif // AEC_NEVER_GREEN_SOFT_EXIT_MQH
