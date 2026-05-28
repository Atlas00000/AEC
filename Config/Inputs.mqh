//+------------------------------------------------------------------+
//| Inputs.mqh — compile defaults = production P10-B (T70 / EDGE-AI-4) |
//| Preset: presets/tester/AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set      |
//| Stack: P5-F + AI skip gate τ=0.45 (logistic L3_take)               |
//|        hours 8–17 · BB 1.10 · struct 0.20 · BUY block [14,15)      |
//| InpAllowTrading=false on attach (safety); preset sets true in tester|
//+------------------------------------------------------------------+
#ifndef AEC_INPUTS_MQH
#define AEC_INPUTS_MQH
#include "../Enums/Types.mqh"

input group "General & safety"
input bool   InpAllowTrading = false;              // Allow live/tester trading (OFF default)
input bool   InpForceTestSignal = false;           // Tester only: bypass signal chain (use with care)
input int    InpForceTestDirection = 1;            // If force: 1=BUY, -1=SELL
input ENUM_LOG_LEVEL InpLogLevel = LOG_INFO;       // Log verbosity
input bool   InpLogCsv = false;                    // Optional CSV decision log
input string InpCsvFileName = "AEC_P10-B_decisions.csv";

input group "Symbol & history"
input long   InpMagic = 260513001;                 // Magic number
input int    InpMaxSpreadPoints = 50;              // Max spread (points) — hard tick gate
input bool   InpUseSignalSpreadCap = false;        // Tighter spread at signal/entry (EDGE-3.9)
input int    InpMaxSignalSpreadPoints = 25;        // Max spread when signal fires (points)
input int    InpMinBarsBeforeTrade = 120;          // Min bars before trading (LTF-friendly; raise on HTF)

input group "Risk & sizing"
input bool   InpUseRiskPercent = false;            // Use risk % instead of fixed lot
input double InpFixedLot = 0.01;                   // Fixed lot (if risk % off)
input double InpRiskPercent = 1.0;                 // Risk per trade % of equity
input double InpMaxDailyDrawdownPercent = 5.0;     // Block new trades if day equity DD % (P4-E 5%; EDGE-5.3 test 3%)
input double InpMinEquityPercentOfBalance = 80.0;  // Block if equity below balance * pct/100
input double InpHardEquityDrawdownPercent = 20.0;  // Optional close-all threshold (0=disable)
input bool   InpCloseAllOnHardEquity = false;      // If hard DD hit, close all positions

input group "Stops & targets"
input ENUM_SLTP_MODE InpSltpMode = SLTP_MODE_POINTS;
input int    InpStopLossPoints = 200;
input int    InpTakeProfitPoints = 400;
input int    InpAtrPeriod = 14;
input double InpAtrSlMultiplier = 1.5;
input double InpRiskReward = 2.0;                  // TP distance = SL distance * RR (if TP mode RR)
input bool   InpUseRrForTp = true;                 // Derive TP from SL * RR
input bool   InpUseExperimentalAtrTrail = false;   // Disabled ATR trail stub (no logic in Phase 1)

input group "Exit management (Phase 6)"
input bool   InpUseDeadTradeExit = false;        // Close if min R not reached within N bars (EDGE-6.4)
input double InpDeadTradeMinR = 0.3;             // Min favorable move in R to keep trade
input int    InpDeadTradeMaxBars = 5;            // Bars after open before dead-trade check
input bool   InpUseBreakevenAtR = false;         // Move SL to entry when +R reached (EDGE-6.3/6.8)
input double InpBreakevenTriggerR = 0.8;         // R to trigger BE; 1.0 = EDGE-6.3, 0.8 = EDGE-6.8
input bool   InpUsePartialCloseAtR = false;      // Partial close at +R, leave runner to TP (EDGE-6.7/6.10)
input double InpPartialCloseTriggerR = 1.2;      // R multiple to trigger partial (6.10 uses 1.0)
input double InpPartialClosePercent = 40.0;      // % to close (6.10 uses 25; needs lot >= 0.05 to bind)
input bool   InpUseAtrTrailAfterR = false;       // Trail SL by ATR after +R reached (EDGE-6.6)
input double InpAtrTrailActivateR = 1.0;       // Arm trail when price reaches this R
input double InpAtrTrailAtrMult = 1.5;          // Trail distance = ATR * mult (chart TF bar 0)
input bool   InpUseGiveBackCap = false;          // Close if +minR MFE then no TP within N bars (EDGE-6.9)
input double InpGiveBackMinR = 0.5;            // Min peak R before timer starts (aligns with fought_mfe05)
input int    InpGiveBackMaxBarsAfterMfe = 24;  // Bars after first +minR before give-back close
input bool   InpUseSoftNeverGreenExit = false; // Close if +minR not hit within N bars (EDGE-6.11)
input double InpSoftNeverGreenMinR = 0.2;      // Aligns with loser_never_green (mfe_r < 0.2)
input int    InpSoftNeverGreenMaxBars = 12;    // Bars from entry (6.4 uses 5 @ 0.3R)

input group "Execution & limits"
input int    InpMaxSlippagePoints = 30;
input int    InpMaxOrderRetries = 2;               // Requote / busy only
input int    InpMaxOpenTrades = 1;
input bool   InpSeparateMaxTradesPerDirection = false;
input int    InpMaxOpenTradesPerDirection = 1;
input int    InpCooldownSecondsAfterTrade = 20;    // Cooldown duration (sec); use 5400 for 90m loss pause (EDGE-5.1)
input bool   InpCooldownAfterLossOnly = false;   // true = pause only after losing exit (EDGE-5.1)
input int    InpTradeDirection = 0;                // 0=both, 1=buy only, -1=sell only

input group "Failure containment (Phase 5)"
input bool   InpUseMaxTradesPerDay = false;      // Cap new entries per broker calendar day (EDGE-5.2)
input int    InpMaxTradesPerDay = 5;             // Max position opens per day
input bool   InpUseHourDirectionFilter = true;   // Block BUY or SELL in broker-hour windows (EDGE-5.6 prod)
input int    InpBlockBuyHourStart = 14;          // Block BUY window start (inclusive); <0 = off
input int    InpBlockBuyHourEnd = 15;            // Block BUY window end (exclusive)
input int    InpBlockSellHourStart = -1;         // Block SELL window start; <0 = off
input int    InpBlockSellHourEnd = -1;           // Block SELL window end (exclusive)
input bool   InpUsePostStreakGate = true;        // Pause after N consecutive losing exits (EDGE-5.5)
input int    InpPostStreakLossCount = 4;         // Consecutive losses to trigger pause
input int    InpPostStreakPauseSeconds = 2700;   // Pause duration (sec); 2700 = 45 min

input group "Bollinger squeeze"
input int    InpBbPeriod = 14;                     // Shorter period = faster bands on LTF
input double InpBbDeviation = 2.0;
input int    InpBbSqueezeLookback = 12;            // Shorter memory = compression vs avg reacts faster
input double InpBbSqueezeWidthRatio = 1.08;        // Higher = easier squeeze plate (w2 below avg*ratio)
input bool   InpUseMinBbReleaseQuality = true;     // Require min band expansion on release bar (EDGE-3.2)
input double InpMinBbReleaseExpandRatio = 1.10;    // Min w1/w2 on release (production 1.10)
input bool   InpUseBbExpansionPersistence = false; // Require BB width up 2 closed bars (EDGE-3.12)
input bool   InpUseBbSqueezeDuration = false;    // Min consecutive compressed bars before release (EDGE-3.15)
input int    InpBbMinSqueezeBars = 4;            // Compressed bars on shifts 2..N before release bar 1
input bool   InpUseBbChopSkip = true;            // Bar-1 BB width >= avg × ratio (EDGE-4.5 prod)
input double InpMinBbWidthVsAvgRatio = 1.0;      // Min width1 / lookback avg (skip range chop)

input group "EMA momentum"
input int    InpEmaFast = 8;                       // Slightly faster for LTF alignment
input int    InpEmaSlow = 17;
input bool   InpUseEmaOverextensionCap = false;   // Max |close - fast EMA| on bar 1 (EDGE-3.13)
input double InpEmaMaxDistAtrMult = 1.2;         // Cap distance from fast EMA (× ATR bar 1)
input bool   InpUseEmaDirectionFilter = false;   // Slow EMA must slope with trade (EDGE-3.8)

input group "Displacement"
input double InpDisplacementBodyAtrMult = 0.55;    // Lower = smaller impulse still counts
input bool   InpUseMinSignalBarRange = false;    // Min high-low range on signal bar (EDGE-3.7)
input double InpMinSignalBarRangeAtrMult = 0.30; // Min bar range bar 1 (× ATR)
input bool   InpUseCloseStrength = false;        // Close in top/bottom zone of bar range (EDGE-3.14)
input double InpCloseStrengthMinPosition = 0.70; // Buy: close pos >= this; sell: pos <= 1-this

input group "Volume expansion"
input int    InpVolumeMaLookback = 14;             // Shorter MA on tick volume for LTF
input double InpVolumeMultiplier = 1.05;          // Closer to MA = more passes

input group "Structure break"
input int    InpSwingLookback = 3;                  // Tighter swing window = breaks trigger more often
input bool   InpUseMinStructBreakDist = true;      // Require close beyond swing by ATR×mult (EDGE-3.4)
input double InpMinStructBreakAtrMult = 0.20;    // Min penetration past swing level (production 0.20)
input bool   InpUseRoomToRun = false;            // Min free space to opposing swing (EDGE-3.11)
input double InpRoomToRunAtrMult = 0.5;          // Min distance to nearest obstacle (× ATR bar 1)
input int    InpRoomToRunLookback = 24;          // Bars to scan for swing highs/lows above/below close

input group "Session breakout (optional)"
input bool   InpUseSessionBreakout = false;
input int    InpSessionStartHour = 0;              // Broker hour session reference start
input int    InpSessionEndHour = 8;                // Build range from bars inside [start,end)

input group "Edge research (Phase 2 / P4-E production hours)"
input bool   InpUseTradingHours = true;            // Block entries outside broker hour window (P3-F 8–17)
input int    InpTradingHourStart = 8;              // Inclusive start (broker hour)
input int    InpTradingHourEnd = 17;               // Exclusive end (broker hour)
input bool   InpUseHourExclusion = false;          // Block entries inside exclusion window (EDGE-3.1)
input int    InpExcludeHourStart = 13;             // Exclusion start (inclusive broker hour)
input int    InpExcludeHourEnd = 15;               // Exclusion end (exclusive broker hour)
input bool   InpUseAdaptiveOverlap = false;        // Stricter BB/struct/disp in overlap hours (EDGE-3.16)
input int    InpOverlapHourStart = 13;             // Adaptive window start (inclusive broker hour)
input int    InpOverlapHourEnd = 15;               // Adaptive window end (exclusive broker hour)
input double InpOverlapBbExpandRatio = 1.12;       // BB w1/w2 min during overlap (vs 1.10 base)
input double InpOverlapStructBreakAtrMult = 0.25;  // Struct min ATR during overlap (vs 0.20 base)
input double InpOverlapDisplacementAtrMult = 0.65; // Displacement body min during overlap (vs 0.55)

input group "Regime (Phase 4)"
input bool   InpUseHtfTrendFilter = false;         // HTF close vs EMA trend gate (EDGE-4.1)
input ENUM_TIMEFRAMES InpHtfTrendTimeframe = PERIOD_H1; // HTF for trend
input int    InpHtfTrendEmaPeriod = 50;            // HTF EMA period (e.g. 50 on H1)
input bool   InpUseAdxMinFilter = false;           // Require min ADX on signal TF (EDGE-4.2)
input int    InpAdxPeriod = 14;                    // ADX period
input double InpAdxMinLevel = 18.0;               // Min ADX on bar 1 (skip flat chop)
input bool   InpUseAtrPercentileBand = false;      // ATR in percentile band on signal TF (EDGE-4.3)
input int    InpAtrPercentileLookback = 100;       // Bars for ATR distribution (shift 1..N)
input double InpAtrPercentileMin = 20.0;          // Min percentile (skip dead vol below)
input double InpAtrPercentileMax = 85.0;          // Max percentile (skip top ~15% spikes)
input bool   InpUsePriorBarRangeCap = true;        // Block bar 1 if H-L > cap × ATR (EDGE-4.4 prod)
input double InpMaxPriorBarRangeAtrMult = 2.0;     // Max signal-bar range (× ATR bar 1)

input group "Phase 0 diagnostics"
input bool   InpDiagSignalLegs = false;            // Count per-leg pass rates (EDGE-0.1; on for research)
input bool   InpDiagWriteSummaryCsv = false;       // Write leg summary CSV on deinit (tester/files)
input string InpDiagSummaryFile = "AEC_diag_summary.csv";

input group "Phase AI signal features (EDGE-AI-3.1)"
input bool   InpExportSignalFeatures = false;        // Export signal-bar features on chain pass
input string InpSignalFeatureFile = "AEC_signal_features.csv"; // Tester Files output
input bool   InpExportSignalFeaturesShadow = true;   // Log non-executed outcomes (ai_skip, etc.)

input group "Phase AI entry gate (EDGE-AI-4 production)"
input bool   InpUseAiEntryFilter = true;           // Skip entry if P(L3_take) < threshold (T70/T71)
input double InpAiMinProbTake = 0.45;            // Min P(take) to allow entry (offline + tester tau)

input group "Phase 7 deal export (EDGE-7.1)"
input bool   InpExportDeals = false;               // Export closed deals + PF segments on deinit
input string InpDealExportFile = "AEC_deals.csv";    // Per close (entry hour/weekday/month)
input string InpDealSegmentFile = "AEC_segments.csv"; // PF/net by hour, weekday, month
input bool   InpExportMaeMfe = false;              // Track MAE/MFE in R per position (EDGE-7.3)
input string InpMaeMfeBucketFile = "AEC_mae_mfe_buckets.csv"; // Taxonomy + MFE/MAE bins

inline bool AecExportMaeMfeActive()
  {
   return (InpExportMaeMfe || InpExportDeals);
  }

#endif // AEC_INPUTS_MQH
