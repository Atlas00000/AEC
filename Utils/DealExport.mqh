//+------------------------------------------------------------------+
//| DealExport.mqh — closed-deal CSV + PF/net segments (EDGE-7.1)    |
//+------------------------------------------------------------------+
#ifndef AEC_DEAL_EXPORT_MQH
#define AEC_DEAL_EXPORT_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/MaeMfeTracker.mqh"

struct AecDealBucket
  {
   int    trades;
   int    wins;
   double gross_profit;
   double gross_loss;
  };

struct AecDealRow
  {
   ulong    deal_id;
   ulong    position_id;
   datetime close_time;
   datetime entry_time;
   int      entry_hour;
   int      entry_weekday;
   int      entry_month;
   string   direction;
   double   net;
   double   profit;
   double   swap;
   double   commission;
   double   volume;
   string   symbol;
   double   mfe_r;
   double   mae_r;
  };

inline void AecDealBucketClear(AecDealBucket &b)
  {
   b.trades = 0;
   b.wins = 0;
   b.gross_profit = 0.0;
   b.gross_loss = 0.0;
  }

inline void AecDealBucketAdd(AecDealBucket &b, const double net)
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

inline double AecDealBucketNet(const AecDealBucket &b)
  {
   return b.gross_profit + b.gross_loss;
  }

inline double AecDealBucketPf(const AecDealBucket &b)
  {
   if(b.gross_loss >= 0.0)
      return (b.gross_profit > 0.0 ? 999.0 : 0.0);
   if(b.gross_profit <= 0.0)
      return 0.0;
   return b.gross_profit / MathAbs(b.gross_loss);
  }

inline double AecDealBucketWinRate(const AecDealBucket &b)
  {
   if(b.trades <= 0)
      return 0.0;
   return 100.0 * (double)b.wins / (double)b.trades;
  }

inline bool AecDealPositionEntryMeta(const ulong position_id,
                                     datetime &entry_time,
                                     string &direction)
  {
   entry_time = 0;
   direction = "";
   if(position_id == 0)
      return false;
   if(!HistorySelectByPosition(position_id))
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

inline void AecDealWriteSegmentRow(const int handle,
                                   const string segment_type,
                                   const string segment_key,
                                   const string direction,
                                   const AecDealBucket &b)
  {
   if(b.trades <= 0)
      return;
   FileWrite(handle,
             segment_type,
             segment_key,
             direction,
             IntegerToString(b.trades),
             IntegerToString(b.wins),
             DoubleToString(b.gross_profit, 2),
             DoubleToString(b.gross_loss, 2),
             DoubleToString(AecDealBucketNet(b), 2),
             DoubleToString(AecDealBucketPf(b), 4),
             DoubleToString(AecDealBucketWinRate(b), 2));
  }

class CDealExport
  {
   static AecDealRow s_rows[];
   static int        s_count;
   static bool       s_flushed;

   static bool HistorySelectAll()
     {
      if(HistorySelect(0, 0))
         return true;
      return HistorySelect(D'2020.01.01', D'2038.01.01');
     }

   static bool BuildRowFromDeal(const ulong deal, const string sym, const long magic, AecDealRow &row)
     {
      if(deal == 0 || !HistoryDealSelect(deal))
         return false;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != sym)
         return false;
      if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
         return false;
      if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         return false;

      row.deal_id = deal;
      row.position_id = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
      row.close_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      row.profit = HistoryDealGetDouble(deal, DEAL_PROFIT);
      row.swap = HistoryDealGetDouble(deal, DEAL_SWAP);
      row.commission = HistoryDealGetDouble(deal, DEAL_COMMISSION);
      row.net = row.profit + row.swap + row.commission;
      row.volume = HistoryDealGetDouble(deal, DEAL_VOLUME);
      row.symbol = sym;

      if(row.volume <= 0.0 && MathAbs(row.net) < 0.00001)
         return false;

      row.entry_time = 0;
      row.direction = "";
      if(!AecDealPositionEntryMeta(row.position_id, row.entry_time, row.direction))
        {
         row.entry_time = row.close_time;
         const long out_type = HistoryDealGetInteger(deal, DEAL_TYPE);
         row.direction = (out_type == DEAL_TYPE_BUY ? "SELL" : "BUY");
        }

      MqlDateTime dt;
      TimeToStruct(row.entry_time, dt);
      row.entry_hour = dt.hour;
      row.entry_weekday = dt.day_of_week;
      row.entry_month = dt.mon;
      return true;
     }

   static bool DealAlreadyRecorded(const ulong deal_id)
     {
      for(int i = 0; i < s_count; i++)
        {
         if(s_rows[i].deal_id == deal_id)
            return true;
        }
      return false;
     }

   static void AppendRow(const AecDealRow &row)
     {
      const int n = ArraySize(s_rows);
      ArrayResize(s_rows, n + 1);
      s_rows[n] = row;
      s_count = n + 1;
     }

   static void LoadFromHistory(const string sym, const long magic)
     {
      if(!HistorySelectAll())
        {
         CLogger::Error("Deal export: HistorySelect failed");
         return;
        }

      const int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(DealAlreadyRecorded(deal))
            continue;
         AecDealRow row;
         if(!BuildRowFromDeal(deal, sym, magic, row))
            continue;
         row.mfe_r = 0.0;
         row.mae_r = 0.0;
         CMaeMfeTracker::Lookup(row.position_id, row.mfe_r, row.mae_r);
         AppendRow(row);
        }
     }

   static void WriteFiles(const string sym, const long magic)
     {
      if(s_flushed)
         return;

      if(AecExportMaeMfeActive())
         CMaeMfeTracker::RebuildFromHistory(sym, magic);

      const int flags = FILE_WRITE | FILE_CSV | FILE_ANSI;
      const int deals_h = FileOpen(InpDealExportFile, flags, ';');
      if(deals_h == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("Deal export open failed err=%d file=%s",
                                     GetLastError(), InpDealExportFile));
         return;
        }

      if(AecExportMaeMfeActive())
         FileWrite(deals_h,
                   "close_time", "entry_time", "entry_hour", "entry_weekday", "entry_month",
                   "direction", "net_profit", "profit", "swap", "commission",
                   "volume", "mfe_r", "mae_r", "deal_id", "position_id", "symbol");
      else
         FileWrite(deals_h,
                   "close_time", "entry_time", "entry_hour", "entry_weekday", "entry_month",
                   "direction", "net_profit", "profit", "swap", "commission",
                   "volume", "deal_id", "position_id", "symbol");

      AecDealBucket hour_all[24];
      AecDealBucket hour_buy[24];
      AecDealBucket hour_sell[24];
      AecDealBucket wd_all[7];
      AecDealBucket wd_buy[7];
      AecDealBucket wd_sell[7];
      AecDealBucket mon_all[12];
      AecDealBucket mon_buy[12];
      AecDealBucket mon_sell[12];
      AecDealBucket total_all;
      AecDealBucket total_buy;
      AecDealBucket total_sell;

      for(int i = 0; i < 24; i++)
        {
         AecDealBucketClear(hour_all[i]);
         AecDealBucketClear(hour_buy[i]);
         AecDealBucketClear(hour_sell[i]);
        }
      for(int i = 0; i < 7; i++)
        {
         AecDealBucketClear(wd_all[i]);
         AecDealBucketClear(wd_buy[i]);
         AecDealBucketClear(wd_sell[i]);
        }
      for(int i = 0; i < 12; i++)
        {
         AecDealBucketClear(mon_all[i]);
         AecDealBucketClear(mon_buy[i]);
         AecDealBucketClear(mon_sell[i]);
        }
      AecDealBucketClear(total_all);
      AecDealBucketClear(total_buy);
      AecDealBucketClear(total_sell);

      for(int i = 0; i < s_count; i++)
        {
         AecDealRow row = s_rows[i];
         if(AecExportMaeMfeActive())
           {
            row.mfe_r = 0.0;
            row.mae_r = 0.0;
            CMaeMfeTracker::Lookup(row.position_id, row.mfe_r, row.mae_r);
           }
         if(AecExportMaeMfeActive())
            FileWrite(deals_h,
                      TimeToString(row.close_time, TIME_DATE | TIME_SECONDS),
                      TimeToString(row.entry_time, TIME_DATE | TIME_SECONDS),
                      IntegerToString(row.entry_hour),
                      IntegerToString(row.entry_weekday),
                      IntegerToString(row.entry_month),
                      row.direction,
                      DoubleToString(row.net, 2),
                      DoubleToString(row.profit, 2),
                      DoubleToString(row.swap, 2),
                      DoubleToString(row.commission, 2),
                      DoubleToString(row.volume, 2),
                      DoubleToString(row.mfe_r, 3),
                      DoubleToString(row.mae_r, 3),
                      IntegerToString((long)row.deal_id),
                      IntegerToString((long)row.position_id),
                      row.symbol);
         else
            FileWrite(deals_h,
                      TimeToString(row.close_time, TIME_DATE | TIME_SECONDS),
                      TimeToString(row.entry_time, TIME_DATE | TIME_SECONDS),
                      IntegerToString(row.entry_hour),
                      IntegerToString(row.entry_weekday),
                      IntegerToString(row.entry_month),
                      row.direction,
                      DoubleToString(row.net, 2),
                      DoubleToString(row.profit, 2),
                      DoubleToString(row.swap, 2),
                      DoubleToString(row.commission, 2),
                      DoubleToString(row.volume, 2),
                      IntegerToString((long)row.deal_id),
                      IntegerToString((long)row.position_id),
                      row.symbol);

         const int hour = row.entry_hour;
         const int weekday = row.entry_weekday;
         const int month = row.entry_month;
         const double net = row.net;

         if(hour >= 0 && hour < 24)
           {
            AecDealBucketAdd(hour_all[hour], net);
            if(row.direction == "BUY")
               AecDealBucketAdd(hour_buy[hour], net);
            else if(row.direction == "SELL")
               AecDealBucketAdd(hour_sell[hour], net);
           }
         if(weekday >= 0 && weekday < 7)
           {
            AecDealBucketAdd(wd_all[weekday], net);
            if(row.direction == "BUY")
               AecDealBucketAdd(wd_buy[weekday], net);
            else if(row.direction == "SELL")
               AecDealBucketAdd(wd_sell[weekday], net);
           }
         if(month >= 1 && month <= 12)
           {
            const int mi = month - 1;
            AecDealBucketAdd(mon_all[mi], net);
            if(row.direction == "BUY")
               AecDealBucketAdd(mon_buy[mi], net);
            else if(row.direction == "SELL")
               AecDealBucketAdd(mon_sell[mi], net);
           }

         AecDealBucketAdd(total_all, net);
         if(row.direction == "BUY")
            AecDealBucketAdd(total_buy, net);
         else if(row.direction == "SELL")
            AecDealBucketAdd(total_sell, net);
        }

      FileClose(deals_h);

      const int seg_h = FileOpen(InpDealSegmentFile, flags, ';');
      if(seg_h == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("Segment export open failed err=%d file=%s",
                                     GetLastError(), InpDealSegmentFile));
         return;
        }

      FileWrite(seg_h,
                "segment_type", "segment_key", "direction",
                "trades", "wins", "gross_profit", "gross_loss", "net", "profit_factor", "win_rate_pct");

      for(int h = 0; h < 24; h++)
        {
         AecDealWriteSegmentRow(seg_h, "hour", IntegerToString(h), "ALL", hour_all[h]);
         AecDealWriteSegmentRow(seg_h, "hour", IntegerToString(h), "BUY", hour_buy[h]);
         AecDealWriteSegmentRow(seg_h, "hour", IntegerToString(h), "SELL", hour_sell[h]);
        }
      for(int w = 0; w < 7; w++)
        {
         AecDealWriteSegmentRow(seg_h, "weekday", IntegerToString(w), "ALL", wd_all[w]);
         AecDealWriteSegmentRow(seg_h, "weekday", IntegerToString(w), "BUY", wd_buy[w]);
         AecDealWriteSegmentRow(seg_h, "weekday", IntegerToString(w), "SELL", wd_sell[w]);
        }
      for(int m = 1; m <= 12; m++)
        {
         const int mi = m - 1;
         AecDealWriteSegmentRow(seg_h, "month", IntegerToString(m), "ALL", mon_all[mi]);
         AecDealWriteSegmentRow(seg_h, "month", IntegerToString(m), "BUY", mon_buy[mi]);
         AecDealWriteSegmentRow(seg_h, "month", IntegerToString(m), "SELL", mon_sell[mi]);
        }
      AecDealWriteSegmentRow(seg_h, "total", "ALL", "ALL", total_all);
      AecDealWriteSegmentRow(seg_h, "total", "ALL", "BUY", total_buy);
      AecDealWriteSegmentRow(seg_h, "total", "ALL", "SELL", total_sell);

      FileClose(seg_h);
      s_flushed = true;

      if(AecExportMaeMfeActive())
         CMaeMfeTracker::WriteBuckets(sym, magic);

      CLogger::Info(StringFormat("Deal export: %d closes maeMfe=%s -> %s + %s",
                                 s_count,
                                 AecExportMaeMfeActive() ? "on" : "off",
                                 InpDealExportFile, InpDealSegmentFile));
     }

public:
   static void Reset()
     {
      ArrayResize(s_rows, 0);
      s_count = 0;
      s_flushed = false;
      if(AecExportMaeMfeActive())
         CMaeMfeTracker::Reset();
     }

   static void RecordCloseDeal(const ulong deal, const string sym, const long magic)
     {
      if(!InpExportDeals || deal == 0)
         return;
      if(DealAlreadyRecorded(deal))
         return;
      AecDealRow row;
      if(!BuildRowFromDeal(deal, sym, magic, row))
         return;
      row.mfe_r = 0.0;
      row.mae_r = 0.0;
      CMaeMfeTracker::Lookup(row.position_id, row.mfe_r, row.mae_r);
      AppendRow(row);
     }

   static void Flush(const string sym, const long magic)
     {
      if(!InpExportDeals || s_flushed)
         return;
      if(s_count == 0)
         LoadFromHistory(sym, magic);
      WriteFiles(sym, magic);
     }

   static void ExportOnDeinit(const string sym, const long magic)
     {
      Flush(sym, magic);
     }

   static void ExportOnTester(const string sym, const long magic)
     {
      Flush(sym, magic);
     }

   static void FlushMaeMfeOnly(const string sym, const long magic)
     {
      if(AecExportMaeMfeActive())
         CMaeMfeTracker::WriteBuckets(sym, magic);
     }
  };

AecDealRow CDealExport::s_rows[];
int        CDealExport::s_count = 0;
bool       CDealExport::s_flushed = false;

#endif // AEC_DEAL_EXPORT_MQH
