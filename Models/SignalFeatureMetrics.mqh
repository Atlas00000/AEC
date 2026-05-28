//+------------------------------------------------------------------+
//| SignalFeatureMetrics.mqh — EDGE-AI-3.1 signal-bar feature row    |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_FEATURE_METRICS_MQH
#define AEC_SIGNAL_FEATURE_METRICS_MQH

struct AecSignalFeatureMetrics
  {
   double bb_expand_ratio;
   double bb_width_vs_avg;
   int    squeeze_bars;
   double struct_break_atr;
   double displacement_atr;
   double prior_bar_range_atr;
   double atr_value;
   double atr_percentile;
   double adx_value;
   bool   metrics_ok;
  };

inline void AecSignalFeatureMetricsClear(AecSignalFeatureMetrics &m)
  {
   m.bb_expand_ratio = 0.0;
   m.bb_width_vs_avg = 0.0;
   m.squeeze_bars = 0;
   m.struct_break_atr = 0.0;
   m.displacement_atr = 0.0;
   m.prior_bar_range_atr = 0.0;
   m.atr_value = 0.0;
   m.atr_percentile = 0.0;
   m.adx_value = 0.0;
   m.metrics_ok = false;
  }

#endif // AEC_SIGNAL_FEATURE_METRICS_MQH
