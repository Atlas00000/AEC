//+------------------------------------------------------------------+
//| PositionSizing.mqh                                               |
//+------------------------------------------------------------------+
#ifndef AEC_POSITION_SIZING_MQH
#define AEC_POSITION_SIZING_MQH
#include "../Config/Inputs.mqh"
#include "../Models/TradeModel.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/Logger.mqh"

class CPositionSizing
  {
public:
   static bool NormalizeVolume(const string sym, double &lots, string &reason)
     {
      const double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
      const double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
      const double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
      if(vstep <= 0.0)
        {
         reason = "Invalid SYMBOL_VOLUME_STEP";
         return false;
        }
      lots = MathFloor(lots / vstep) * vstep;
      if(lots < vmin - 1e-12)
        {
         reason = StringFormat("Lot below min (%.5f < %.5f)", lots, vmin);
         return false;
        }
      if(lots > vmax + 1e-12)
        {
         reason = StringFormat("Lot above max (%.5f > %.5f)", lots, vmax);
         return false;
        }
      return true;
     }

   static double LotsFromFixed(const string sym, string &reason)
     {
      double lot = InpFixedLot;
      if(!NormalizeVolume(sym, lot, reason))
         return 0.0;
      return lot;
     }

   static double LotsFromRiskPercent(const string sym,
                                     const int sl_points,
                                     string &reason)
     {
      if(sl_points <= 0)
        {
         reason = "SL points must be > 0 for risk sizing";
         return 0.0;
        }
      const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      const double risk_money = equity * (InpRiskPercent / 100.0);
      const double ticksize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
      const double tickvalue = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
      const double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(ticksize <= 0.0 || tickvalue <= 0.0 || point <= 0.0)
        {
         reason = "Invalid tick/point metadata";
         return 0.0;
        }
      const double sl_price_dist = (double)sl_points * point;
      const double ticks = sl_price_dist / ticksize;
      const double loss_per_lot = ticks * tickvalue;
      if(loss_per_lot <= 0.0)
        {
         reason = "loss_per_lot<=0";
         return 0.0;
        }
      double lots = risk_money / loss_per_lot;
      if(!NormalizeVolume(sym, lots, reason))
         return 0.0;
      CLogger::Debug(StringFormat("Sizing risk_money=%.2f sl_pts=%d lots=%.4f", risk_money, sl_points, lots));
      return lots;
     }

   static bool BuildSltpPlan(const string sym,
                            const ENUM_ORDER_TYPE type,
                            const double entry_price,
                            const int sl_points_in,
                            const int tp_points_in,
                            SltpPlan &plan,
                            string &reason)
     {
      plan.sl_price = 0.0;
      plan.tp_price = 0.0;
      plan.sl_points = sl_points_in;
      plan.tp_points = tp_points_in;
      plan.note = "";

      const double point = Aec_PointSize(sym);
      if(type == ORDER_TYPE_BUY)
        {
         plan.sl_price = entry_price - (double)plan.sl_points * point;
         plan.tp_price = entry_price + (double)plan.tp_points * point;
        }
      else if(type == ORDER_TYPE_SELL)
        {
         plan.sl_price = entry_price + (double)plan.sl_points * point;
         plan.tp_price = entry_price - (double)plan.tp_points * point;
        }
      else
        {
         reason = "Unsupported order type for SLTP plan";
         return false;
        }
      return true;
     }
  };

#endif // AEC_POSITION_SIZING_MQH
