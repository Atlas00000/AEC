//+------------------------------------------------------------------+
//| PositionHelpers.mqh — shared open-position utilities             |
//+------------------------------------------------------------------+
#ifndef AEC_POSITION_HELPERS_MQH
#define AEC_POSITION_HELPERS_MQH

inline bool Aec_FindOurPosition(const string sym,
                                const long magic,
                                ulong &ticket,
                                long &pos_type,
                                double &entry,
                                double &sl)
  {
   ticket = 0;
   pos_type = -1;
   entry = 0.0;
   sl = 0.0;
   const int total = PositionsTotal();
   for(int i = total - 1; i >= 0; --i)
     {
      const ulong t = PositionGetTicket(i);
      if(t == 0 || !PositionSelectByTicket(t))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != sym)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      ticket = t;
      pos_type = PositionGetInteger(POSITION_TYPE);
      entry = PositionGetDouble(POSITION_PRICE_OPEN);
      sl = PositionGetDouble(POSITION_SL);
      return true;
     }
   return false;
  }

inline double Aec_PositionRiskDistance(const long pos_type,
                                       const double entry,
                                       const double sl)
  {
   if(sl <= 0.0)
      return 0.0;
   if(pos_type == POSITION_TYPE_BUY)
      return entry - sl;
   if(pos_type == POSITION_TYPE_SELL)
      return sl - entry;
   return 0.0;
  }

inline bool Aec_PositionReachedR(const long pos_type,
                                 const double entry,
                                 const double risk_dist,
                                 const double r_mult,
                                 const double bid,
                                 const double ask)
  {
   if(risk_dist <= 0.0 || r_mult <= 0.0)
      return false;
   const double target = risk_dist * r_mult;
   if(pos_type == POSITION_TYPE_BUY)
      return (bid >= entry + target);
   if(pos_type == POSITION_TYPE_SELL)
      return (ask <= entry - target);
   return false;
  }

#endif // AEC_POSITION_HELPERS_MQH
