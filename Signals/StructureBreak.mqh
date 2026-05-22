//+------------------------------------------------------------------+
//| StructureBreak.mqh — swing range break on closed bar 1           |
//+------------------------------------------------------------------+
#ifndef AEC_STRUCTURE_BREAK_MQH
#define AEC_STRUCTURE_BREAK_MQH
#include "../Config/Inputs.mqh"

inline bool SigStruct_RoomOkBuy(const string sym,
                               const ENUM_TIMEFRAMES tf,
                               const int lookbackBars,
                               const int hAtr,
                               const double minAtrMult,
                               string &detail)
  {
   const double c1 = iClose(sym, tf, 1);
   if(c1 <= 0.0)
     {
      detail = "Room BUY bad close";
      return false;
     }

   const int span = MathMax(2, lookbackBars);
   double nearestAbove = DBL_MAX;
   for(int sh = 2; sh <= span; ++sh)
     {
      const double h = iHigh(sym, tf, sh);
      if(h > c1 && h < nearestAbove)
         nearestAbove = h;
     }

   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "Room BUY ATR copy failed";
      return false;
     }
   const double minRoom = atr[1] * minAtrMult;

   if(nearestAbove >= DBL_MAX / 2.0)
     {
      detail = StringFormat("Room BUY c1=%.5f no ceiling minRoom=%.5f ok=Y", c1, minRoom);
      return true;
     }

   const double room = nearestAbove - c1;
   const bool ok = (room >= minRoom);
   detail = StringFormat("Room BUY c1=%.5f ceiling=%.5f room=%.5f minRoom=%.5f ok=%s",
                         c1, nearestAbove, room, minRoom, ok ? "Y" : "N");
   return ok;
  }

inline bool SigStruct_RoomOkSell(const string sym,
                                const ENUM_TIMEFRAMES tf,
                                const int lookbackBars,
                                const int hAtr,
                                const double minAtrMult,
                                string &detail)
  {
   const double c1 = iClose(sym, tf, 1);
   if(c1 <= 0.0)
     {
      detail = "Room SELL bad close";
      return false;
     }

   const int span = MathMax(2, lookbackBars);
   double nearestBelow = -DBL_MAX;
   for(int sh = 2; sh <= span; ++sh)
     {
      const double l = iLow(sym, tf, sh);
      if(l < c1 && l > nearestBelow)
         nearestBelow = l;
     }

   double atr[];
   ArraySetAsSeries(atr, true);
   if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
     {
      detail = "Room SELL ATR copy failed";
      return false;
     }
   const double minRoom = atr[1] * minAtrMult;

   if(nearestBelow <= -DBL_MAX / 2.0)
     {
      detail = StringFormat("Room SELL c1=%.5f no floor minRoom=%.5f ok=Y", c1, minRoom);
      return true;
     }

   const double room = c1 - nearestBelow;
   const bool ok = (room >= minRoom);
   detail = StringFormat("Room SELL c1=%.5f floor=%.5f room=%.5f minRoom=%.5f ok=%s",
                         c1, nearestBelow, room, minRoom, ok ? "Y" : "N");
   return ok;
  }

inline bool SigStruct_BuyBreak(const string sym,
                              const ENUM_TIMEFRAMES tf,
                              const int swingLookback,
                              const int hAtr,
                              const bool useMinBreakDist,
                              const double minBreakAtrMult,
                              const bool useRoomToRun,
                              const double roomAtrMult,
                              const int roomLookback,
                              string &detail)
  {
   const int span = MathMax(2, swingLookback);
   const int highest_shift = iHighest(sym, tf, MODE_HIGH, span, 2);
   if(highest_shift < 0)
     {
      detail = "iHighest failed";
      return false;
     }
   const double swingHigh = iHigh(sym, tf, highest_shift);
   const double c1 = iClose(sym, tf, 1);
   const double c2 = iClose(sym, tf, 2);
   bool brk = (c1 > swingHigh) && (c2 <= swingHigh);

   double minDist = 0.0;
   double dist = c1 - swingHigh;
   if(brk && useMinBreakDist && minBreakAtrMult > 0.0)
     {
      double atr[];
      ArraySetAsSeries(atr, true);
      if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
        {
         detail = "Struct BUY ATR copy failed";
         return false;
        }
      minDist = atr[1] * minBreakAtrMult;
      if(dist < minDist)
         brk = false;
     }

   string roomD = "";
   if(brk && useRoomToRun && roomAtrMult > 0.0)
     {
      if(!SigStruct_RoomOkBuy(sym, tf, roomLookback, hAtr, roomAtrMult, roomD))
         brk = false;
     }

   if(useRoomToRun && roomAtrMult > 0.0)
      detail = StringFormat("Struct BUY c1=%.5f swingHigh=%.5f dist=%.5f minDist=%.5f ok=%s | %s",
                            c1, swingHigh, dist, minDist, brk ? "Y" : "N", roomD);
   else if(useMinBreakDist && minBreakAtrMult > 0.0)
      detail = StringFormat("Struct BUY c1=%.5f swingHigh=%.5f dist=%.5f minDist=%.5f ok=%s",
                            c1, swingHigh, dist, minDist, brk ? "Y" : "N");
   else
      detail = StringFormat("Struct BUY c1=%.5f swingHigh=%.5f c2=%.5f ok=%s", c1, swingHigh, c2, brk ? "Y" : "N");
   return brk;
  }

inline bool SigStruct_SellBreak(const string sym,
                               const ENUM_TIMEFRAMES tf,
                               const int swingLookback,
                               const int hAtr,
                               const bool useMinBreakDist,
                               const double minBreakAtrMult,
                               const bool useRoomToRun,
                               const double roomAtrMult,
                               const int roomLookback,
                               string &detail)
  {
   const int span = MathMax(2, swingLookback);
   const int lowest_shift = iLowest(sym, tf, MODE_LOW, span, 2);
   if(lowest_shift < 0)
     {
      detail = "iLowest failed";
      return false;
     }
   const double swingLow = iLow(sym, tf, lowest_shift);
   const double c1 = iClose(sym, tf, 1);
   const double c2 = iClose(sym, tf, 2);
   bool brk = (c1 < swingLow) && (c2 >= swingLow);

   double minDist = 0.0;
   double dist = swingLow - c1;
   if(brk && useMinBreakDist && minBreakAtrMult > 0.0)
     {
      double atr[];
      ArraySetAsSeries(atr, true);
      if(hAtr == INVALID_HANDLE || CopyBuffer(hAtr, 0, 0, 3, atr) <= 0)
        {
         detail = "Struct SELL ATR copy failed";
         return false;
        }
      minDist = atr[1] * minBreakAtrMult;
      if(dist < minDist)
         brk = false;
     }

   string roomD = "";
   if(brk && useRoomToRun && roomAtrMult > 0.0)
     {
      if(!SigStruct_RoomOkSell(sym, tf, roomLookback, hAtr, roomAtrMult, roomD))
         brk = false;
     }

   if(useRoomToRun && roomAtrMult > 0.0)
      detail = StringFormat("Struct SELL c1=%.5f swingLow=%.5f dist=%.5f minDist=%.5f ok=%s | %s",
                            c1, swingLow, dist, minDist, brk ? "Y" : "N", roomD);
   else if(useMinBreakDist && minBreakAtrMult > 0.0)
      detail = StringFormat("Struct SELL c1=%.5f swingLow=%.5f dist=%.5f minDist=%.5f ok=%s",
                            c1, swingLow, dist, minDist, brk ? "Y" : "N");
   else
      detail = StringFormat("Struct SELL c1=%.5f swingLow=%.5f c2=%.5f ok=%s", c1, swingLow, c2, brk ? "Y" : "N");
   return brk;
  }

#endif // AEC_STRUCTURE_BREAK_MQH
