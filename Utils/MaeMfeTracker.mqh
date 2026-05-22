//+------------------------------------------------------------------+
//| MaeMfeTracker.mqh — per-trade MAE/MFE in R + buckets (EDGE-7.3)  |
//+------------------------------------------------------------------+
#ifndef AEC_MAE_MFE_TRACKER_MQH
#define AEC_MAE_MFE_TRACKER_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Execution/PositionHelpers.mqh"

struct AecMaeMfeBucket
  {
   int    trades;
   int    wins;
   double gross_profit;
   double gross_loss;
  };

struct AecMaeMfeClosed
  {
   ulong    position_id;
   string   direction;
   double   net;
   double   mfe_r;
   double   mae_r;
  };

inline void AecMaeMfeBucketClear(AecMaeMfeBucket &b)
  {
   b.trades = 0;
   b.wins = 0;
   b.gross_profit = 0.0;
   b.gross_loss = 0.0;
  }

inline void AecMaeMfeBucketAdd(AecMaeMfeBucket &b, const double net)
  {
   b.trades++;
   if(net > 0.0)
     {
      b.wins++;
      b.gross_profit += net;
     }
   else if(net < 0.0)
      b.gross_loss += net;
  }

inline double AecMaeMfeBucketNet(const AecMaeMfeBucket &b)
  {
   return b.gross_profit + b.gross_loss;
  }

inline double AecMaeMfeBucketPf(const AecMaeMfeBucket &b)
  {
   if(b.gross_loss >= 0.0)
      return (b.gross_profit > 0.0 ? 999.0 : 0.0);
   if(b.gross_profit <= 0.0)
      return 0.0;
   return b.gross_profit / MathAbs(b.gross_loss);
  }

inline double AecMaeMfeBucketWinRate(const AecMaeMfeBucket &b)
  {
   if(b.trades <= 0)
      return 0.0;
   return 100.0 * (double)b.wins / (double)b.trades;
  }

inline void AecMaeMfeWriteBucketRow(const int handle,
                                    const string bucket_type,
                                    const string bucket_key,
                                    const string outcome,
                                    const AecMaeMfeBucket &b)
  {
   if(b.trades <= 0)
      return;
   FileWrite(handle,
             bucket_type,
             bucket_key,
             outcome,
             IntegerToString(b.trades),
             IntegerToString(b.wins),
             DoubleToString(b.gross_profit, 2),
             DoubleToString(b.gross_loss, 2),
             DoubleToString(AecMaeMfeBucketNet(b), 2),
             DoubleToString(AecMaeMfeBucketPf(b), 4),
             DoubleToString(AecMaeMfeBucketWinRate(b), 2));
  }

inline bool AecMaeMfeEntryMeta(const ulong position_id,
                               datetime &entry_time,
                               string &direction)
  {
   entry_time = 0;
   direction = "";
   if(position_id == 0 || !HistorySelectByPosition(position_id))
      return false;
   const int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      const ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0)
         continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;
      entry_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      const long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
      direction = (deal_type == DEAL_TYPE_BUY ? "BUY" : "SELL");
      return true;
     }
   return false;
  }

class CMaeMfeTracker
  {
   static ulong   s_pos_id;
   static double  s_entry;
   static double  s_sl;
   static double  s_risk;
   static long    s_dir;
   static double  s_mfe_r;
   static double  s_mae_r;
   static double  s_accum_net;
   static bool    s_active;
   static AecMaeMfeClosed s_closed[];
   static int     s_closed_n;

   static int FindClosedIndex(const ulong position_id)
     {
      for(int i = 0; i < s_closed_n; i++)
        {
         if(s_closed[i].position_id == position_id)
            return i;
        }
      return -1;
     }

   static double RiskDistance(const long pos_type, const double entry, const double sl)
     {
      if(pos_type == POSITION_TYPE_BUY)
         return (entry - sl);
      if(pos_type == POSITION_TYPE_SELL)
         return (sl - entry);
      return 0.0;
     }

   static double EffectiveRisk(const string sym,
                               const long pos_type,
                               const double entry,
                               const double sl)
     {
      double risk = RiskDistance(pos_type, entry, sl);
      if(risk > 0.0)
         return risk;
      const double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(pt <= 0.0 || InpStopLossPoints <= 0)
         return 0.0;
      return (double)InpStopLossPoints * pt;
     }

   static void ResetOpen()
     {
      s_active = false;
      s_pos_id = 0;
      s_entry = 0.0;
      s_sl = 0.0;
      s_risk = 0.0;
      s_dir = -1;
      s_mfe_r = 0.0;
      s_mae_r = 0.0;
      s_accum_net = 0.0;
     }

   static void BeginTrack(const string sym,
                          const ulong pos_id,
                          const long pos_type,
                          const double entry,
                          const double sl)
     {
      s_pos_id = pos_id;
      s_dir = pos_type;
      s_entry = entry;
      s_sl = sl;
      s_risk = EffectiveRisk(sym, pos_type, entry, sl);
      s_mfe_r = 0.0;
      s_mae_r = 0.0;
      s_accum_net = 0.0;
      s_active = (pos_id > 0 && s_risk > 0.0);
     }

   static void UpdateExcursion(const double bid, const double ask)
     {
      if(!s_active || s_risk <= 0.0)
         return;

      double fav = 0.0;
      double adv = 0.0;
      if(s_dir == POSITION_TYPE_BUY)
        {
         fav = (bid - s_entry) / s_risk;
         adv = (s_entry - bid) / s_risk;
        }
      else if(s_dir == POSITION_TYPE_SELL)
        {
         fav = (s_entry - ask) / s_risk;
         adv = (ask - s_entry) / s_risk;
        }
      else
         return;

      if(fav > s_mfe_r)
         s_mfe_r = fav;
      if(adv > s_mae_r)
         s_mae_r = adv;
     }

   static void StoreClosed(const ulong pos_id,
                           const string direction,
                           const double net,
                           const double mfe_r,
                           const double mae_r)
     {
      const int idx = FindClosedIndex(pos_id);
      if(idx >= 0)
        {
         s_closed[idx].net = net;
         s_closed[idx].mfe_r = mfe_r;
         s_closed[idx].mae_r = mae_r;
         return;
        }
      const int n = ArraySize(s_closed);
      ArrayResize(s_closed, n + 1);
      s_closed[n].position_id = pos_id;
      s_closed[n].direction = direction;
      s_closed[n].net = net;
      s_closed[n].mfe_r = mfe_r;
      s_closed[n].mae_r = mae_r;
      s_closed_n = n + 1;
     }

   static void FinalizeOpen(const string direction)
     {
      if(!s_active)
         return;
      StoreClosed(s_pos_id, direction, s_accum_net, s_mfe_r, s_mae_r);
      ResetOpen();
     }

   static bool PositionStillOpen(const ulong pos_id)
     {
      if(pos_id == 0)
         return false;
      if(!PositionSelectByTicket(pos_id))
         return false;
      return (PositionGetDouble(POSITION_VOLUME) > 0.0);
     }

   static int MfeBinIndex(const double mfe_r)
     {
      if(mfe_r < 0.3) return 0;
      if(mfe_r < 0.6) return 1;
      if(mfe_r < 1.0) return 2;
      if(mfe_r < 1.5) return 3;
      return 4;
     }

   static int MaeBinIndex(const double mae_r)
     {
      if(mae_r < 0.5) return 0;
      if(mae_r < 1.0) return 1;
      return 2;
     }

   static void WriteBucketRows(const int handle)
     {
      AecMaeMfeBucket tax_dead, tax_fought, tax_other_loss, tax_win;
      AecMaeMfeBucket mfe_bins[5];
      AecMaeMfeBucket mae_loss_bins[3];
      AecMaeMfeBucket mfe_win[5];
      AecMaeMfeBucket mfe_loss[5];

      AecMaeMfeBucketClear(tax_dead);
      AecMaeMfeBucketClear(tax_fought);
      AecMaeMfeBucketClear(tax_other_loss);
      AecMaeMfeBucketClear(tax_win);
      for(int i = 0; i < 5; i++)
        {
         AecMaeMfeBucketClear(mfe_bins[i]);
         AecMaeMfeBucketClear(mfe_win[i]);
         AecMaeMfeBucketClear(mfe_loss[i]);
        }
      for(int i = 0; i < 3; i++)
         AecMaeMfeBucketClear(mae_loss_bins[i]);

      for(int i = 0; i < s_closed_n; i++)
        {
         const AecMaeMfeClosed c = s_closed[i];
         const double net = c.net;
         const int fb = MfeBinIndex(c.mfe_r);
         AecMaeMfeBucketAdd(mfe_bins[fb], net);

         if(net > 0.0)
           {
            AecMaeMfeBucketAdd(tax_win, net);
            AecMaeMfeBucketAdd(mfe_win[fb], net);
           }
         else if(net < 0.0)
           {
            const int mb = MaeBinIndex(c.mae_r);
            AecMaeMfeBucketAdd(mae_loss_bins[mb], net);
            AecMaeMfeBucketAdd(mfe_loss[fb], net);
            if(c.mfe_r < 0.2)
               AecMaeMfeBucketAdd(tax_dead, net);
            else if(c.mfe_r >= 0.5)
               AecMaeMfeBucketAdd(tax_fought, net);
            else
               AecMaeMfeBucketAdd(tax_other_loss, net);
           }
        }

      const string mfe_labels[5] = {"0-0.3", "0.3-0.6", "0.6-1.0", "1.0-1.5", "1.5+"};
      const string mae_labels[3] = {"0-0.5", "0.5-1.0", "1.0+"};

      FileWrite(handle,
                "bucket_type", "bucket_key", "outcome",
                "trades", "wins", "gross_profit", "gross_loss", "net", "profit_factor", "win_rate_pct");

      AecMaeMfeWriteBucketRow(handle, "taxonomy", "loser_never_green", "loss", tax_dead);
      AecMaeMfeWriteBucketRow(handle, "taxonomy", "loser_fought_mfe05", "loss", tax_fought);
      AecMaeMfeWriteBucketRow(handle, "taxonomy", "loser_other", "loss", tax_other_loss);
      AecMaeMfeWriteBucketRow(handle, "taxonomy", "winner", "win", tax_win);

      for(int b = 0; b < 5; b++)
         AecMaeMfeWriteBucketRow(handle, "mfe_bin", mfe_labels[b], "ALL", mfe_bins[b]);
      for(int b = 0; b < 5; b++)
         AecMaeMfeWriteBucketRow(handle, "mfe_bin", mfe_labels[b], "win", mfe_win[b]);
      for(int b = 0; b < 5; b++)
         AecMaeMfeWriteBucketRow(handle, "mfe_bin", mfe_labels[b], "loss", mfe_loss[b]);
      for(int b = 0; b < 3; b++)
         AecMaeMfeWriteBucketRow(handle, "mae_bin_loss", mae_labels[b], "loss", mae_loss_bins[b]);
     }

public:
   static void Reset()
     {
      ResetOpen();
      ArrayResize(s_closed, 0);
      s_closed_n = 0;
     }

   static void OnTick(const string sym, const long magic, const double bid, const double ask)
     {
      if(!AecExportMaeMfeActive())
         return;

      ulong ticket = 0;
      long pos_type = -1;
      double entry = 0.0, sl = 0.0;
      if(Aec_FindOurPosition(sym, magic, ticket, pos_type, entry, sl))
        {
         if(!s_active || s_pos_id != ticket)
            BeginTrack(sym, ticket, pos_type, entry, sl);
         else if(s_risk <= 0.0)
           {
            s_sl = sl;
            s_risk = EffectiveRisk(sym, pos_type, entry, sl);
            s_active = (s_risk > 0.0);
           }
         UpdateExcursion(bid, ask);
         return;
        }

      if(s_active && !PositionStillOpen(s_pos_id))
        {
         const string direction = (s_dir == POSITION_TYPE_BUY ? "BUY" : "SELL");
         FinalizeOpen(direction);
        }
     }

   static void OnDeal(const ulong deal, const string sym, const long magic)
     {
      if(!AecExportMaeMfeActive() || deal == 0 || !HistoryDealSelect(deal))
         return;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != sym)
         return;
      if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
         return;

      const long entry_type = HistoryDealGetInteger(deal, DEAL_ENTRY);
      const ulong pos_id = HistoryDealGetInteger(deal, DEAL_POSITION_ID);

      if(entry_type == DEAL_ENTRY_IN)
        {
         const long deal_type = HistoryDealGetInteger(deal, DEAL_TYPE);
         const long pos_type = (deal_type == DEAL_TYPE_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
         const double price = HistoryDealGetDouble(deal, DEAL_PRICE);
         double sl = 0.0;
         if(PositionSelectByTicket(pos_id))
            sl = PositionGetDouble(POSITION_SL);
         BeginTrack(sym, pos_id, pos_type, price, sl);
         return;
        }

      if(entry_type != DEAL_ENTRY_OUT)
         return;

      const double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      const double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      if(s_active && s_pos_id == pos_id)
         UpdateExcursion(bid, ask);

      const double slice_net = HistoryDealGetDouble(deal, DEAL_PROFIT)
                               + HistoryDealGetDouble(deal, DEAL_SWAP)
                               + HistoryDealGetDouble(deal, DEAL_COMMISSION);

      string direction = "";
      datetime entry_time = 0;
      if(!AecMaeMfeEntryMeta(pos_id, entry_time, direction))
        {
         const long out_type = HistoryDealGetInteger(deal, DEAL_TYPE);
         direction = (out_type == DEAL_TYPE_BUY ? "SELL" : "BUY");
        }

      if(s_active && s_pos_id == pos_id)
         s_accum_net += slice_net;

      if(PositionStillOpen(pos_id))
         return;

      if(s_active && s_pos_id == pos_id)
         FinalizeOpen(direction);
     }

   static bool Lookup(const ulong position_id, double &mfe_r, double &mae_r)
     {
      mfe_r = 0.0;
      mae_r = 0.0;
      if(s_active && s_pos_id == position_id)
        {
         mfe_r = s_mfe_r;
         mae_r = s_mae_r;
         return true;
        }
      const int idx = FindClosedIndex(position_id);
      if(idx < 0)
         return false;
      mfe_r = s_closed[idx].mfe_r;
      mae_r = s_closed[idx].mae_r;
      return true;
     }

   static int ClosedCount() { return s_closed_n; }

   static bool PositionCloseMeta(const ulong position_id,
                                 const string sym,
                                 const long magic,
                                 datetime &close_time,
                                 double &net)
     {
      close_time = 0;
      net = 0.0;
      if(position_id == 0 || !HistorySelectByPosition(position_id))
         return false;
      const int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || !HistoryDealSelect(ticket))
            continue;
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) != sym)
            continue;
         if((long)HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic)
            continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
            continue;
         const datetime t = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         if(t >= close_time)
            close_time = t;
         net += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                + HistoryDealGetDouble(ticket, DEAL_SWAP)
                + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
      return (close_time > 0);
     }

   static void ExcursionFromBar(const long pos_type,
                                const double entry,
                                const double risk,
                                const double hi,
                                const double lo,
                                double &mfe_r,
                                double &mae_r)
     {
      if(risk <= 0.0)
         return;
      double fav = 0.0;
      double adv = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
        {
         fav = (hi - entry) / risk;
         adv = (entry - lo) / risk;
        }
      else if(pos_type == POSITION_TYPE_SELL)
        {
         fav = (entry - lo) / risk;
         adv = (hi - entry) / risk;
        }
      if(fav > mfe_r)
         mfe_r = fav;
      if(adv > mae_r)
         mae_r = adv;
     }

   static void RebuildFromHistory(const string sym, const long magic)
     {
      if(!AecExportMaeMfeActive())
         return;
      if(!HistorySelect(0, 0))
         HistorySelect(D'2020.01.01', D'2038.01.01');

      const ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
      const int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0 || !HistoryDealSelect(deal))
            continue;
         if(HistoryDealGetString(deal, DEAL_SYMBOL) != sym)
            continue;
         if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
            continue;
         if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT)
            continue;

         const ulong pos_id = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
         if(pos_id == 0 || FindClosedIndex(pos_id) >= 0)
            continue;

         string direction = "";
         datetime entry_time = 0;
         if(!AecMaeMfeEntryMeta(pos_id, entry_time, direction))
            continue;

         double entry_price = 0.0;
         double sl = 0.0;
         long pos_type = -1;
         if(!HistorySelectByPosition(pos_id))
            continue;
         const int n = HistoryDealsTotal();
         for(int j = 0; j < n; j++)
           {
            const ulong in_deal = HistoryDealGetTicket(j);
            if(in_deal == 0 || !HistoryDealSelect(in_deal))
               continue;
            if(HistoryDealGetInteger(in_deal, DEAL_ENTRY) != DEAL_ENTRY_IN)
               continue;
            entry_price = HistoryDealGetDouble(in_deal, DEAL_PRICE);
            const long deal_type = HistoryDealGetInteger(in_deal, DEAL_TYPE);
            pos_type = (deal_type == DEAL_TYPE_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
            break;
           }
         if(entry_price <= 0.0 || pos_type < 0)
            continue;

         datetime close_time = 0;
         double net = 0.0;
         if(!PositionCloseMeta(pos_id, sym, magic, close_time, net))
            continue;

         const double risk = EffectiveRisk(sym, pos_type, entry_price, sl);
         if(risk <= 0.0)
            continue;

         double mfe_r = 0.0;
         double mae_r = 0.0;
         const int shift_end = iBarShift(sym, tf, close_time, true);
         const int shift_start = iBarShift(sym, tf, entry_time, true);
         if(shift_end < 0 || shift_start < 0)
           {
            StoreClosed(pos_id, direction, net, mfe_r, mae_r);
            continue;
           }
         const int lo_shift = MathMin(shift_start, shift_end);
         const int hi_shift = MathMax(shift_start, shift_end);
         for(int s = hi_shift; s >= lo_shift; --s)
           {
            const double hi = iHigh(sym, tf, s);
            const double lo = iLow(sym, tf, s);
            ExcursionFromBar(pos_type, entry_price, risk, hi, lo, mfe_r, mae_r);
           }
         StoreClosed(pos_id, direction, net, mfe_r, mae_r);
        }
     }

   static void WriteBuckets(const string sym, const long magic)
     {
      if(!AecExportMaeMfeActive())
         return;
      RebuildFromHistory(sym, magic);
      if(s_closed_n == 0)
        {
         CLogger::Error("MAE/MFE buckets: no positions after history rebuild");
         return;
        }

      const int h = FileOpen(InpMaeMfeBucketFile, FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
      if(h == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("MAE/MFE bucket CSV failed err=%d", GetLastError()));
         return;
        }
      WriteBucketRows(h);
      FileClose(h);
      CLogger::Info(StringFormat("MAE/MFE buckets: %d positions -> %s", s_closed_n, InpMaeMfeBucketFile));
     }
  };

ulong   CMaeMfeTracker::s_pos_id = 0;
double  CMaeMfeTracker::s_entry = 0.0;
double  CMaeMfeTracker::s_sl = 0.0;
double  CMaeMfeTracker::s_risk = 0.0;
long    CMaeMfeTracker::s_dir = -1;
double  CMaeMfeTracker::s_mfe_r = 0.0;
double  CMaeMfeTracker::s_mae_r = 0.0;
double  CMaeMfeTracker::s_accum_net = 0.0;
bool    CMaeMfeTracker::s_active = false;
AecMaeMfeClosed CMaeMfeTracker::s_closed[];
int     CMaeMfeTracker::s_closed_n = 0;

#endif // AEC_MAE_MFE_TRACKER_MQH
