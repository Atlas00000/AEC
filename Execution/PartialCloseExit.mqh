//+------------------------------------------------------------------+
//| PartialCloseExit.mqh — scale out at +R, leave runner (EDGE-6.7)  |
//+------------------------------------------------------------------+
#ifndef AEC_PARTIAL_CLOSE_EXIT_MQH
#define AEC_PARTIAL_CLOSE_EXIT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "PositionHelpers.mqh"
#include "TradeExecutor.mqh"

inline bool Aec_NormalizeCloseVolume(const string sym,
                                     const double requested,
                                     const double position_vol,
                                     double &close_vol,
                                     string &reason)
  {
   close_vol = 0.0;
   const double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   const double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   const double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(vstep <= 0.0)
     {
      reason = "Invalid SYMBOL_VOLUME_STEP";
      return false;
     }

   close_vol = MathFloor(requested / vstep) * vstep;
   if(close_vol < vmin - 1e-12)
     {
      reason = StringFormat("Partial vol %.5f below min %.5f", close_vol, vmin);
      return false;
     }

   const double remain = position_vol - close_vol;
   if(remain < vmin - 1e-12)
     {
      close_vol = MathFloor((position_vol - vmin) / vstep) * vstep;
      if(close_vol < vmin - 1e-12)
        {
         reason = StringFormat("Cannot partial: pos %.5f min %.5f", position_vol, vmin);
         return false;
        }
     }

   if(close_vol > vmax + 1e-12)
     {
      reason = "Partial vol above max";
      return false;
     }
   return true;
  }

inline void Aec_PartialCloseClearState(CGlobalsPersist &gv)
  {
   gv.DeleteKey("PART_TICKET");
   gv.DeleteKey("PART_DONE");
  }

inline void Aec_PartialCloseSyncTicket(CGlobalsPersist &gv, const ulong ticket)
  {
   const long tracked = gv.GetInt("PART_TICKET", 0);
   if((ulong)tracked != ticket)
     {
      gv.SetInt("PART_TICKET", (long)ticket);
      gv.SetInt("PART_DONE", 0);
     }
  }

inline void Aec_PartialCloseManageTick(const string sym,
                                       const long magic,
                                       const double bid,
                                       const double ask,
                                       CGlobalsPersist &gv,
                                       CTradeExecutor &exec)
  {
   if(!InpUsePartialCloseAtR || !InpAllowTrading)
      return;
   if(InpPartialClosePercent <= 0.0 || InpPartialCloseTriggerR <= 0.0)
      return;

   ulong ticket = 0;
   long pos_type = -1;
   double entry = 0.0, sl = 0.0;
   if(!Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
     {
      Aec_PartialCloseClearState(gv);
      return;
     }

   Aec_PartialCloseSyncTicket(gv, ticket);

   if(gv.GetInt("PART_DONE", 0) != 0)
      return;

   if(!PositionSelectByTicket(ticket))
      return;

   const double vol = PositionGetDouble(POSITION_VOLUME);
   const double risk = Aec_PositionRiskDistance(pos_type, entry, sl);
   if(!Aec_PositionReachedR(pos_type, entry, risk, InpPartialCloseTriggerR, bid, ask))
      return;

   const double pct = MathMin(100.0, MathMax(1.0, InpPartialClosePercent)) / 100.0;
   const double requested = vol * pct;
   string nrej = "";
   double close_vol = 0.0;
   if(!Aec_NormalizeCloseVolume(sym, requested, vol, close_vol, nrej))
     {
      CLogger::Trace(StringFormat("Partial skip ticket=%I64u: %s", ticket, nrej));
      gv.SetInt("PART_DONE", 1);
      return;
     }

   string er = "";
   if(!exec.PartialCloseVolume(ticket, close_vol, er))
     {
      CLogger::Trace(StringFormat("Partial at %.2fR failed: %s", InpPartialCloseTriggerR, er));
      return;
     }

   CLogger::Info(StringFormat("Partial %.0f%% at %.2fR ticket=%I64u closed=%.5f remain~%.5f",
                              InpPartialClosePercent, InpPartialCloseTriggerR, ticket,
                              close_vol, vol - close_vol));
   gv.SetInt("PART_DONE", 1);
  }

#endif // AEC_PARTIAL_CLOSE_EXIT_MQH
