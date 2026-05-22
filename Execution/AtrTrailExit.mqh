//+------------------------------------------------------------------+
//| AtrTrailExit.mqh — trail SL by ATR after +R (EDGE-6.6)           |
//+------------------------------------------------------------------+
#ifndef AEC_ATR_TRAIL_EXIT_MQH
#define AEC_ATR_TRAIL_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "../Utils/Helpers.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline void Aec_AtrTrailClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("TRAIL_TICKET");
   gv.DeleteKey("TRAIL_ARMED");
  }

inline void Aec_AtrTrailSyncTicket(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("TRAIL_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("TRAIL_TICKET", (long)ticket);
      gv.SetInt("TRAIL_ARMED", 0);
     }
  }

inline bool Aec_AtrTrailComputeTargetSl(const string sym,
                                        const long pos_type,
                                        const double trail_dist,
                                        const double bid,
                                        const double ask,
                                        double &new_sl)
  {
   const int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   const double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   const int stops_lvl = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   const double min_dist = (double)MathMax(stops_lvl, 1) * pt;

   if(pos_type == POSITION_TYPE_BUY)
     {
      new_sl = NormalizeDouble(bid - trail_dist, dg);
      const double cap = bid - min_dist;
      if(new_sl > cap)
         new_sl = cap;
      return (new_sl > 0.0 && new_sl < bid);
     }
   if(pos_type == POSITION_TYPE_SELL)
     {
      new_sl = NormalizeDouble(ask + trail_dist, dg);
      const double cap = ask + min_dist;
      if(new_sl < cap)
         new_sl = cap;
      return (new_sl > ask);
     }
   return false;
  }

inline bool Aec_AtrTrailShouldTighten(const long pos_type,
                                      const double current_sl,
                                      const double new_sl)
  {
   if(current_sl <= 0.0)
      return true;
   if(pos_type == POSITION_TYPE_BUY)
      return (new_sl > current_sl);
   if(pos_type == POSITION_TYPE_SELL)
      return (new_sl < current_sl);
   return false;
  }

inline void Aec_AtrTrailManageTick(const string sym,
                                   const long magic,
                                   const int atr_handle,
                                   const double bid,
                                   const double ask,
                                   CGlobalsPersist &gv,
                                   CTradeExecutor &exec)
  {
   if(!InpUseAtrTrailAfterR || !InpAllowTrading)
      return;
   if(atr_handle == INVALID_HANDLE || InpAtrTrailAtrMult <= 0.0 || InpAtrTrailActivateR <= 0.0)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_AtrTrailClearState(gv);
      return;
     }

   Aec_AtrTrailSyncTicket(gv, ticket);

   if(!PositionSelectByTicket(ticket))
      return;

   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(risk <= 0.0)
      return;

   if(gv.GetInt("TRAIL_ARMED", 0) == 0)
     {
      if(!Aec_PositionReachedR(pos_type, entry, risk, InpAtrTrailActivateR, bid, ask))
         return;
      gv.SetInt("TRAIL_ARMED", 1);
      CLogger::Info(StringFormat("ATR trail armed ticket=%I64u at %.2fR", ticket, InpAtrTrailActivateR));
     }

   double atr_buf[];
   ArraySetAsSeries(atr_buf, true);
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buf) != 1)
      return;

   const double trail_dist = atr_buf[0] * InpAtrTrailAtrMult;
   if(trail_dist <= 0.0)
      return;

   double new_sl = 0.0;
   if(!Aec_AtrTrailComputeTargetSl(sym, pos_type, trail_dist, bid, ask, new_sl))
      return;

   const double current_sl = PositionGetDouble(POSITION_SL);
   if(!Aec_AtrTrailShouldTighten(pos_type, current_sl, new_sl))
      return;

   string er = "";
   if(!exec.ModifyPositionSl(ticket, new_sl, er))
     {
      CLogger::Trace(StringFormat("ATR trail modify failed: %s", er));
      return;
     }

   CLogger::Debug(StringFormat("ATR trail ticket=%I64u sl=%.5f dist=%.5f", ticket, new_sl, trail_dist));
  }

#endif // AEC_ATR_TRAIL_EXIT_MQH
