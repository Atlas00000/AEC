//+------------------------------------------------------------------+
//| Inputs.mqh — Phase 1 inputs (single chart / symbol / timeframe)  |
//+------------------------------------------------------------------+
#ifndef AEC_INPUTS_MQH
#define AEC_INPUTS_MQH
#include "../Enums/Types.mqh"

//----- General / safety
input string InpSectionGeneral = "=== General ===";
input bool   InpAllowTrading = false;              // Allow live/tester trading (OFF default)
input bool   InpForceTestSignal = false;           // Tester only: bypass signal chain (use with care)
input int    InpForceTestDirection = 1;            // If force: 1=BUY, -1=SELL
input ENUM_LOG_LEVEL InpLogLevel = LOG_INFO;       // Log verbosity (see Enums/Types.mqh)
input bool   InpLogCsv = false;                    // Optional CSV decision log
input string InpCsvFileName = "AEC_decisions.csv";

//----- State / symbol
input string InpSectionSymbol = "=== Symbol / session ===";
input long   InpMagic = 260513001;                 // Magic number
input int    InpMaxSpreadPoints = 50;              // Max spread (points)
input int    InpMinBarsBeforeTrade = 120;          // Min bars before trading (LTF-friendly; raise on HTF)

//----- Risk / sizing
input string InpSectionRisk = "=== Risk & sizing ===";
input bool   InpUseRiskPercent = false;            // Use risk % instead of fixed lot
input double InpFixedLot = 0.01;                  // Fixed lot (if risk % off)
input double InpRiskPercent = 1.0;                // Risk per trade % of equity
input double InpMaxDailyDrawdownPercent = 5.0;    // Block new trades if exceeded (broker day)
input double InpMinEquityPercentOfBalance = 80.0; // Block if equity < balance * pct/100
input double InpHardEquityDrawdownPercent = 20.0; // Optional close-all threshold (0=disable)
input bool   InpCloseAllOnHardEquity = false;     // If hard DD hit, close all positions

//----- Stops / targets (points unless mode says otherwise)
input string InpSectionStops = "=== Stops & targets ===";
input ENUM_SLTP_MODE InpSltpMode = SLTP_MODE_POINTS;
input int    InpStopLossPoints = 200;
input int    InpTakeProfitPoints = 400;
input int    InpAtrPeriod = 14;
input double InpAtrSlMultiplier = 1.5;
input double InpRiskReward = 2.0;                 // TP distance = SL distance * RR (if TP mode RR)
input bool   InpUseRrForTp = true;                  // Derive TP from SL * RR
input bool   InpUseExperimentalAtrTrail = false;  // Disabled ATR trail stub (no logic in Phase 1)

//----- Execution
input string InpSectionExec = "=== Execution ===";
input int    InpMaxSlippagePoints = 30;
input int    InpMaxOrderRetries = 2;              // Requote / busy only
input int    InpMaxOpenTrades = 1;
input bool   InpSeparateMaxTradesPerDirection = false;
input int    InpMaxOpenTradesPerDirection = 1;
input int    InpCooldownSecondsAfterTrade = 20;   // Shorter for more samples (tighten for live)
input bool   InpCooldownAfterLossOnly = false;
input int    InpTradeDirection = 0;                // 0=both, 1=buy only, -1=sell only

//----- Indicators — Bollinger squeeze (defaults tuned for M1/M5: more sensitive = more signals)
input string InpSectionBB = "=== Bollinger squeeze ===";
input int    InpBbPeriod = 14;                   // Shorter period = faster bands on LTF
input double InpBbDeviation = 2.0;
input int    InpBbSqueezeLookback = 12;          // Shorter memory = compression vs avg reacts faster
input double InpBbSqueezeWidthRatio = 1.08;      // Higher = easier squeeze plate (w2 < avg*ratio)

//----- Indicators — EMA
input string InpSectionEma = "=== EMA momentum ===";
input int    InpEmaFast = 8;                     // Slightly faster for LTF alignment
input int    InpEmaSlow = 17;

//----- Indicators — ATR / displacement
input string InpSectionDisp = "=== Displacement ===";
input double InpDisplacementBodyAtrMult = 0.55; // Lower = smaller impulse still counts (was 1.0)

//----- Indicators — Volume
input string InpSectionVol = "=== Volume expansion ===";
input int    InpVolumeMaLookback = 14;          // Shorter MA on tick volume for LTF
input double InpVolumeMultiplier = 1.05;      // Closer to MA = more passes (was 1.2)

//----- Structure break
input string InpSectionStruct = "=== Structure break ===";
input int    InpSwingLookback = 3;              // Tighter swing window = breaks trigger more often (was 5)

//----- Session breakout (optional)
input string InpSectionSession = "=== Session breakout (optional) ===";
input bool   InpUseSessionBreakout = false;
input int    InpSessionStartHour = 0;             // Broker hour session reference start
input int    InpSessionEndHour = 8;              // Build range from bars inside [start,end)

#endif // AEC_INPUTS_MQH
