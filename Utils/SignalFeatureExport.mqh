//+------------------------------------------------------------------+
//| SignalFeatureExport.mqh — EDGE-AI-3.1 chain-pass CSV export        |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_FEATURE_EXPORT_MQH
#define AEC_SIGNAL_FEATURE_EXPORT_MQH

#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"
#include "../Models/SignalModel.mqh"
#include "../Models/SignalFeatureMetrics.mqh"
#include "../Utils/Logger.mqh"
#include "../Execution/AiEntryGate.mqh"

class CSignalFeatureExport
  {
   static ulong s_rows;
   static bool  s_header;

   static int OpenAppend()
     {
      int h = FileOpen(InpSignalFeatureFile, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
      if(h == INVALID_HANDLE)
        {
         h = FileOpen(InpSignalFeatureFile, FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
         if(h != INVALID_HANDLE)
            s_header = false;
        }
      else
         FileSeek(h, 0, SEEK_END);
      return h;
     }

   static void WriteHeader(const int h)
     {
      FileWrite(h,
                "signal_time", "symbol", "direction", "outcome",
                "spread_pts", "ai_prob_take", "loss_streak",
                "entry_hour", "entry_weekday", "entry_month", "is_buy",
                "pass_bb", "pass_vol", "pass_struct", "pass_ema", "pass_disp", "pass_sess",
                "pass_htf", "pass_adx", "pass_atr_pct", "pass_prior_bar",
                "bb_expand_ratio", "bb_width_vs_avg", "squeeze_bars",
                "struct_break_atr", "displacement_atr", "prior_bar_range_atr",
                "atr_value", "atr_percentile", "adx_value");
      s_header = true;
     }

   static int Leg01(const bool v) { return (v ? 1 : 0); }

public:
   static void Reset()
     {
      s_rows = 0;
      s_header = false;
     }

   static ulong RowCount() { return s_rows; }

   static void WriteChainPass(const string sym,
                               const ENUM_TIMEFRAMES tf,
                               const ENUM_TRADE_DIR dir,
                               const SignalLegSnapshot &legs,
                               const AecSignalFeatureMetrics &metrics,
                               const int spread_pts,
                               const int loss_streak,
                               const string outcome,
                               const double ai_prob_take)
     {
      if(!InpExportSignalFeatures)
         return;
      if(!InpExportSignalFeaturesShadow && outcome != "executed")
         return;
      if(dir != DIR_BUY && dir != DIR_SELL)
         return;

      const datetime signal_time = iTime(sym, tf, 1);
      if(signal_time == 0)
         return;

      MqlDateTime dt;
      TimeToStruct(signal_time, dt);

      const int h = OpenAppend();
      if(h == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("Signal feature CSV open failed err=%d file=%s",
                                     GetLastError(), InpSignalFeatureFile));
         return;
        }
      if(!s_header)
         WriteHeader(h);

      const bool is_buy = (dir == DIR_BUY);
      const bool pass_struct = is_buy ? legs.buyStruct : legs.sellStruct;
      const bool pass_ema = is_buy ? legs.buyEma : legs.sellEma;
      const bool pass_disp = is_buy ? legs.buyDisp : legs.sellDisp;
      const bool pass_sess = is_buy ? legs.sessBuy : legs.sessSell;
      const bool pass_htf = is_buy ? legs.buyHtf : legs.sellHtf;

      FileWrite(h,
                TimeToString(signal_time, TIME_DATE | TIME_SECONDS),
                sym,
                (is_buy ? "BUY" : "SELL"),
                outcome,
                IntegerToString(spread_pts),
                DoubleToString(ai_prob_take, 4),
                IntegerToString(loss_streak),
                IntegerToString(dt.hour),
                IntegerToString(dt.day_of_week),
                IntegerToString(dt.mon),
                IntegerToString(is_buy ? 1 : 0),
                IntegerToString(Leg01(legs.bb)),
                IntegerToString(Leg01(legs.vol)),
                IntegerToString(Leg01(pass_struct)),
                IntegerToString(Leg01(pass_ema)),
                IntegerToString(Leg01(pass_disp)),
                IntegerToString(Leg01(pass_sess)),
                IntegerToString(Leg01(pass_htf)),
                IntegerToString(Leg01(legs.adxOk)),
                IntegerToString(Leg01(legs.atrRegimeOk)),
                IntegerToString(Leg01(legs.priorBarOk)),
                DoubleToString(metrics.bb_expand_ratio, 5),
                DoubleToString(metrics.bb_width_vs_avg, 5),
                IntegerToString(metrics.squeeze_bars),
                DoubleToString(metrics.struct_break_atr, 4),
                DoubleToString(metrics.displacement_atr, 4),
                DoubleToString(metrics.prior_bar_range_atr, 4),
                DoubleToString(metrics.atr_value, 5),
                DoubleToString(metrics.atr_percentile, 2),
                DoubleToString(metrics.adx_value, 2));
      FileClose(h);
      s_rows++;
     }
  };

ulong CSignalFeatureExport::s_rows = 0;
bool  CSignalFeatureExport::s_header = false;

#endif // AEC_SIGNAL_FEATURE_EXPORT_MQH
