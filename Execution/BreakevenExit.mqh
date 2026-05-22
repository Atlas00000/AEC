//+------------------------------------------------------------------+
//| BreakevenExit.mqh — move SL to entry at +R (EDGE-6.8)            |
//+------------------------------------------------------------------+
#ifndef AEC_BREAKEVEN_EXIT_MQH
#define AEC_BREAKEVEN_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "../Utils/Helpers.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline bool Aec_PositionSlAtBreakeven(const string sym,
                                      const long pos_type,
                                      const double entry,
                                      const double sl)
  {
   const double pt = Aec_PointSize(sym);
   if(pt <= 0.0)
      return false;
   const double tol = pt * 2.0;
   if(pos_type == POSITION_TYPE_BUY)
      return (sl >= entry - tol);
   if(pos_type == POSITION_TYPE_SELL)
      return (sl <= entry + tol);
   return false;
  }

inline void Aec_BreakevenClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("BE_TICKET");
   gv.DeleteKey("BE_DONE");
  }

inline void Aec_BreakevenSyncTicket(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("BE_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("BE_TICKET", (long)ticket);
      gv.SetInt("BE_DONE", 0);
     }
  }

inline void Aec_BreakevenManageTick(const string sym,
                                    const long magic,
                                    const double bid,
                                    const double ask,
                                    CGlobalsPersist &gv,
                                    CTradeExecutor &exec)
  {
   if(!InpUseBreakevenAtR || !InpAllowTrading)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_BreakevenClearState(gv);
      return;
     }

   Aec_BreakevenSyncTicket(gv, ticket);

   if(gv.GetInt("BE_DONE", 0) != 0)
      return;

   if(Aec_PositionSlAtBreakeven(sym, pos_type, entry, sl))
     {
      gv.SetInt("BE_DONE", 1);
      return;
     }

   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(!Aec_PositionReachedR(pos_type, entry, risk, InpBreakevenTriggerR, bid, ask))
      return;

   string er = "";
   if(!exec.ModifySlToBreakeven(ticket, er))
     {
      CLogger::Trace(StringFormat("BE at %.2fR failed: %s", InpBreakevenTriggerR, er));
      return;
     }

   CLogger::Info(StringFormat("BE at %.2fR ticket=%I64u entry=%.5f", InpBreakevenTriggerR, ticket, entry));
   gv.SetInt("BE_DONE", 1);
  }

#endif // AEC_BREAKEVEN_EXIT_MQH
