//+------------------------------------------------------------------+
//| HourDirection.mqh — per-hour buy/sell throttle (EDGE-5.4)         |
//+------------------------------------------------------------------+
#ifndef AEC_HOUR_DIRECTION_MQH
#define AEC_HOUR_DIRECTION_MQH
#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"
#include "../Utils/Helpers.mqh"

inline bool Aec_HourBlockWindowActive(const int start_h, const int end_h)
  {
   return (start_h >= 0 && end_h >= 0 && start_h != end_h);
  }

inline bool Aec_HourDirectionAllows(const ENUM_TRADE_DIR dir,
                                     const datetime bar_time,
                                     string &detail)
  {
   detail = "";
   if(!InpUseHourDirectionFilter)
     {
      detail = "Hour dir filter off";
      return true;
     }
   if(bar_time == 0)
     {
      detail = "Hour dir bad bar time";
      return false;
     }

   const bool blockBuy = Aec_HourBlockWindowActive(InpBlockBuyHourStart, InpBlockBuyHourEnd)
                         && Aec_BrokerHourInWindow(bar_time, InpBlockBuyHourStart, InpBlockBuyHourEnd);
   const bool blockSell = Aec_HourBlockWindowActive(InpBlockSellHourStart, InpBlockSellHourEnd)
                          && Aec_BrokerHourInWindow(bar_time, InpBlockSellHourStart, InpBlockSellHourEnd);

   if(dir == DIR_BUY && blockBuy)
     {
      MqlDateTime dt;
      TimeToStruct(bar_time, dt);
      detail = StringFormat("Hour dir block BUY hr=%d in [%d,%d)", dt.hour,
                            InpBlockBuyHourStart, InpBlockBuyHourEnd);
      return false;
     }
   if(dir == DIR_SELL && blockSell)
     {
      MqlDateTime dt;
      TimeToStruct(bar_time, dt);
      detail = StringFormat("Hour dir block SELL hr=%d in [%d,%d)", dt.hour,
                            InpBlockSellHourStart, InpBlockSellHourEnd);
      return false;
     }

   detail = "Hour dir ok";
   return true;
  }

#endif // AEC_HOUR_DIRECTION_MQH
