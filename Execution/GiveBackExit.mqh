//+------------------------------------------------------------------+
//| GiveBackExit.mqh — cap give-back after +MFE (EDGE-6.9)           |
//+------------------------------------------------------------------+
#ifndef AEC_GIVE_BACK_EXIT_MQH
#define AEC_GIVE_BACK_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline void Aec_GiveBackSyncTicketState(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("GB_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("GB_TICKET", (long)ticket);
      gv.SetInt("GB_HIT_MFE", 0);
      gv.DeleteKey("GB_MFE_TIME");
     }
  }

inline void Aec_GiveBackClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("GB_TICKET");
   gv.DeleteKey("GB_HIT_MFE");
   gv.DeleteKey("GB_MFE_TIME");
  }

inline void Aec_GiveBackUpdateMfeHit(CGlobalsPersist &gv,
                                     const long pos_type,
                                     const double entry,
                                     const double sl,
                                     const double bid,
                                     const double ask)
  {
   if(gv.GetInt("GB_HIT_MFE", 0) != 0)
      return;
   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(!Aec_PositionReachedR(pos_type, entry, risk, InpGiveBackMinR, bid, ask))
      return;
   gv.SetInt("GB_HIT_MFE", 1);
   gv.SetTime("GB_MFE_TIME", TimeCurrent());
  }

inline bool Aec_GiveBackTryCloseOnBar(const string sym,
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
      Aec_GiveBackClearState(gv);
      return false;
     }

   Aec_GiveBackSyncTicketState(gv, ticket);

   if(gv.GetInt("GB_HIT_MFE", 0) == 0)
      return false;

   datetime mfe_time = 0;
   if(!gv.GetTime("GB_MFE_TIME", mfe_time) || mfe_time == 0)
      return false;

   const int bars_since = iBarShift(sym, period, mfe_time, true);
   if(bars_since < 0 || bars_since < InpGiveBackMaxBarsAfterMfe)
      return false;

   string er = "";
   if(!exec.ClosePosition(ticket, er))
     {
      CLogger::Info(StringFormat("Give-back close failed: %s", er));
      return false;
     }

   CLogger::Info(StringFormat("Give-back exit ticket=%I64u bars_since_mfe=%d minR=%.2f",
                              ticket, bars_since, InpGiveBackMinR));
   Aec_GiveBackClearState(gv);
   return true;
  }

inline void Aec_GiveBackManageTick(const string sym,
                                   const ENUM_TIMEFRAMES period,
                                   const long magic,
                                   const double bid,
                                   const double ask,
                                   const bool is_new_bar,
                                   CGlobalsPersist &gv,
                                   CTradeExecutor &exec)
  {
   if(!InpUseGiveBackCap || !InpAllowTrading)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_GiveBackClearState(gv);
      return;
     }

   Aec_GiveBackSyncTicketState(gv, ticket);
   Aec_GiveBackUpdateMfeHit(gv, pos_type, entry, sl, bid, ask);

   if(is_new_bar)
      Aec_GiveBackTryCloseOnBar(sym, period, magic, gv, exec);
  }

#endif // AEC_GIVE_BACK_EXIT_MQH
