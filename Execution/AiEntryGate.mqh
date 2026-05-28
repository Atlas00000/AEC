//+------------------------------------------------------------------+
//| AiEntryGate.mqh — logistic L3_take skip gate (EDGE-AI-4)          |
//| Coefficients from data/ai/model_sklearn.json (retrain → update)   |
//+------------------------------------------------------------------+
#ifndef AEC_AI_ENTRY_GATE_MQH
#define AEC_AI_ENTRY_GATE_MQH

#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"

// logistic_l3_take — features: entry_hour, entry_weekday, entry_month, is_buy
static const double AEC_AI_MEAN_HOUR     = 11.503614457831326;
static const double AEC_AI_SCALE_HOUR    = 2.45280492415022;
static const double AEC_AI_MEAN_WEEKDAY  = 3.025301204819277;
static const double AEC_AI_SCALE_WEEKDAY = 1.4161157952018772;
static const double AEC_AI_MEAN_MONTH    = 6.525301204819277;
static const double AEC_AI_SCALE_MONTH   = 3.388671537460328;
static const double AEC_AI_MEAN_IS_BUY   = 0.43132530120481927;
static const double AEC_AI_SCALE_IS_BUY  = 0.4952613307592193;
static const double AEC_AI_COEF_HOUR     = 0.07603523714643082;
static const double AEC_AI_COEF_WEEKDAY  = -0.05730359867516465;
static const double AEC_AI_COEF_MONTH    = -0.08816785665784599;
static const double AEC_AI_COEF_IS_BUY   = 0.13179106127847398;
static const double AEC_AI_INTERCEPT     = 0.011083876184307244;

inline double Aec_AiScaleFeature(const double raw, const double mean, const double scale)
  {
   if(scale <= 0.0)
      return 0.0;
   return (raw - mean) / scale;
  }

inline double Aec_AiProbTakeFromBarTime(const datetime bar_time, const ENUM_TRADE_DIR dir)
  {
   MqlDateTime dt;
   if(bar_time == 0 || !TimeToStruct(bar_time, dt))
      return 0.0;

   const double is_buy = (dir == DIR_BUY ? 1.0 : 0.0);
   const double xs_hour = Aec_AiScaleFeature((double)dt.hour, AEC_AI_MEAN_HOUR, AEC_AI_SCALE_HOUR);
   const double xs_wday = Aec_AiScaleFeature((double)dt.day_of_week, AEC_AI_MEAN_WEEKDAY, AEC_AI_SCALE_WEEKDAY);
   const double xs_mon = Aec_AiScaleFeature((double)dt.mon, AEC_AI_MEAN_MONTH, AEC_AI_SCALE_MONTH);
   const double xs_buy = Aec_AiScaleFeature(is_buy, AEC_AI_MEAN_IS_BUY, AEC_AI_SCALE_IS_BUY);

   const double logit = AEC_AI_INTERCEPT
                        + AEC_AI_COEF_HOUR * xs_hour
                        + AEC_AI_COEF_WEEKDAY * xs_wday
                        + AEC_AI_COEF_MONTH * xs_mon
                        + AEC_AI_COEF_IS_BUY * xs_buy;
   return 1.0 / (1.0 + MathExp(-logit));
  }

inline bool Aec_AiEntryAllows(const ENUM_TRADE_DIR dir,
                               const datetime bar_time,
                               string &detail)
  {
   detail = "";
   if(!InpUseAiEntryFilter)
     {
      detail = "AI gate off";
      return true;
     }
   if(bar_time == 0)
     {
      detail = "AI gate bad bar time";
      return false;
     }

   const double p_take = Aec_AiProbTakeFromBarTime(bar_time, dir);
   if(p_take >= InpAiMinProbTake)
     {
      MqlDateTime dt;
      TimeToStruct(bar_time, dt);
      detail = StringFormat("AI take p=%.3f >= %.2f hr=%d", p_take, InpAiMinProbTake, dt.hour);
      return true;
     }

   MqlDateTime dt;
   TimeToStruct(bar_time, dt);
   detail = StringFormat("AI skip p=%.3f < %.2f hr=%d wd=%d mon=%d %s",
                         p_take, InpAiMinProbTake, dt.hour, dt.day_of_week, dt.mon,
                         (dir == DIR_BUY ? "BUY" : "SELL"));
   return false;
  }

#endif // AEC_AI_ENTRY_GATE_MQH
