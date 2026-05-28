//+------------------------------------------------------------------+
//| SignalEngine.mqh — Phase 1 AND-chain                             |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_ENGINE_MQH
#define AEC_SIGNAL_ENGINE_MQH
#include "../Config/Inputs.mqh"
#include "../Models/SignalModel.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/Helpers.mqh"
#include "BBSqueeze.mqh"
#include "StructureBreak.mqh"
#include "EMAMomentum.mqh"
#include "VolumeExpansion.mqh"
#include "Displacement.mqh"
#include "SessionBreakout.mqh"
#include "HtfTrend.mqh"
#include "AdxRegime.mqh"
#include "AtrRegime.mqh"
#include "SignalFeatureCalc.mqh"

class CSignalEngine
  {
   int m_hBands;
   int m_hEmaFast;
   int m_hEmaSlow;
   int m_hAtr;
   int m_hHtfEma;
   int m_hAdx;

   bool CollectLegs(const string sym,
                   const ENUM_TIMEFRAMES tf,
                   SignalLegSnapshot &legs,
                   string &detail) const
     {
      ZeroMemory(legs);
      detail = "";

      string d_bb, d_stBuy, d_stSell, d_emaBuy, d_emaSell, d_vol, d_dispBuy, d_dispSell, d_sessBuy, d_sessSell, d_htfBuy, d_htfSell, d_adx, d_atrPct, d_priorBar;

      double bbExpand = InpMinBbReleaseExpandRatio;
      double structMult = InpMinStructBreakAtrMult;
      double dispMult = InpDisplacementBodyAtrMult;
      bool overlapStrict = false;
      if(InpUseAdaptiveOverlap)
        {
         const datetime bar1 = iTime(sym, tf, 1);
         if(bar1 != 0 && Aec_BrokerHourInWindow(bar1, InpOverlapHourStart, InpOverlapHourEnd))
           {
            overlapStrict = true;
            bbExpand = InpOverlapBbExpandRatio;
            structMult = InpOverlapStructBreakAtrMult;
            dispMult = InpOverlapDisplacementAtrMult;
           }
        }

      legs.bb = SigBb_Release(m_hBands, InpBbSqueezeLookback, InpBbSqueezeWidthRatio,
                              InpUseMinBbReleaseQuality, bbExpand,
                              InpUseBbExpansionPersistence,
                              InpUseBbSqueezeDuration, InpBbMinSqueezeBars, d_bb);
      if(InpUseBbChopSkip && legs.bb)
        {
         string d_chop = "";
         if(!SigBb_WidthVsAvgOk(m_hBands, InpBbSqueezeLookback, InpMinBbWidthVsAvgRatio, d_chop))
            legs.bb = false;
         d_bb = d_bb + " | " + d_chop;
        }
      if(overlapStrict)
         d_bb = d_bb + " | overlap BB>=" + DoubleToString(bbExpand, 2);
      legs.vol = SigVol_Expanded(sym, tf, InpVolumeMaLookback, InpVolumeMultiplier, d_vol);
      legs.buyDisp = SigDisp_Bull(sym, tf, m_hAtr, dispMult, d_dispBuy);
      legs.sellDisp = SigDisp_Bear(sym, tf, m_hAtr, dispMult, d_dispSell);
      if(overlapStrict)
        {
         d_dispBuy = d_dispBuy + " | overlap disp>=" + DoubleToString(dispMult, 2);
         d_dispSell = d_dispSell + " | overlap disp>=" + DoubleToString(dispMult, 2);
        }
        if(InpUseMinSignalBarRange && InpMinSignalBarRangeAtrMult > 0.0)
        {
         string d_rng = "";
         if(legs.buyDisp)
           {
            if(!SigBar_MinRangeOk(sym, tf, m_hAtr, InpMinSignalBarRangeAtrMult, d_rng))
               legs.buyDisp = false;
            d_dispBuy = d_dispBuy + " | " + d_rng;
           }
         if(legs.sellDisp)
           {
            if(!SigBar_MinRangeOk(sym, tf, m_hAtr, InpMinSignalBarRangeAtrMult, d_rng))
               legs.sellDisp = false;
            d_dispSell = d_dispSell + " | " + d_rng;
           }
        }
      if(InpUseCloseStrength && InpCloseStrengthMinPosition > 0.0 && InpCloseStrengthMinPosition < 1.0)
        {
         string d_cs = "";
         if(legs.buyDisp)
           {
            if(!SigClose_BuyStrength(sym, tf, InpCloseStrengthMinPosition, d_cs))
               legs.buyDisp = false;
            d_dispBuy = d_dispBuy + " | " + d_cs;
           }
         if(legs.sellDisp)
           {
            if(!SigClose_SellStrength(sym, tf, InpCloseStrengthMinPosition, d_cs))
               legs.sellDisp = false;
            d_dispSell = d_dispSell + " | " + d_cs;
           }
        }
      legs.buyStruct = SigStruct_BuyBreak(sym, tf, InpSwingLookback, m_hAtr,
                                          InpUseMinStructBreakDist, structMult,
                                          InpUseRoomToRun, InpRoomToRunAtrMult, InpRoomToRunLookback, d_stBuy);
      legs.sellStruct = SigStruct_SellBreak(sym, tf, InpSwingLookback, m_hAtr,
                                            InpUseMinStructBreakDist, structMult,
                                            InpUseRoomToRun, InpRoomToRunAtrMult, InpRoomToRunLookback, d_stSell);
      if(overlapStrict)
        {
         d_stBuy = d_stBuy + " | overlap struct>=" + DoubleToString(structMult, 2);
         d_stSell = d_stSell + " | overlap struct>=" + DoubleToString(structMult, 2);
        }
      legs.buyEma = SigEma_AlignedBuy(m_hEmaFast, m_hEmaSlow, d_emaBuy);
      legs.sellEma = SigEma_AlignedSell(m_hEmaFast, m_hEmaSlow, d_emaSell);
      if(InpUseEmaOverextensionCap && InpEmaMaxDistAtrMult > 0.0)
        {
         string d_ed = "";
         if(legs.buyEma)
           {
            if(!SigEma_WithinFastEma(sym, tf, m_hEmaFast, m_hAtr, InpEmaMaxDistAtrMult, d_ed))
               legs.buyEma = false;
            d_emaBuy = d_emaBuy + " | " + d_ed;
           }
         if(legs.sellEma)
           {
            if(!SigEma_WithinFastEma(sym, tf, m_hEmaFast, m_hAtr, InpEmaMaxDistAtrMult, d_ed))
               legs.sellEma = false;
            d_emaSell = d_emaSell + " | " + d_ed;
           }
        }
      if(InpUseEmaDirectionFilter)
        {
         string d_dir = "";
         if(legs.buyEma)
           {
            if(!SigEma_SlowTrendBuy(m_hEmaSlow, d_dir))
               legs.buyEma = false;
            d_emaBuy = d_emaBuy + " | " + d_dir;
           }
         if(legs.sellEma)
           {
            if(!SigEma_SlowTrendSell(m_hEmaSlow, d_dir))
               legs.sellEma = false;
            d_emaSell = d_emaSell + " | " + d_dir;
           }
        }
      legs.sessBuy = SigSession_PassesBuy(sym, tf, d_sessBuy);
      legs.sessSell = SigSession_PassesSell(sym, tf, d_sessSell);

      legs.buyHtf = true;
      legs.sellHtf = true;
      if(InpUseHtfTrendFilter)
        {
         legs.buyHtf = SigHtf_TrendBuy(m_hHtfEma, sym, InpHtfTrendTimeframe, d_htfBuy);
         legs.sellHtf = SigHtf_TrendSell(m_hHtfEma, sym, InpHtfTrendTimeframe, d_htfSell);
        }

      legs.adxOk = true;
      if(InpUseAdxMinFilter)
         legs.adxOk = SigAdx_MinOk(m_hAdx, InpAdxMinLevel, d_adx);

      legs.atrRegimeOk = true;
      if(InpUseAtrPercentileBand)
         legs.atrRegimeOk = SigAtr_PercentileBandOk(m_hAtr, InpAtrPercentileLookback,
                                                    InpAtrPercentileMin, InpAtrPercentileMax, d_atrPct);

      legs.priorBarOk = true;
      if(InpUsePriorBarRangeCap)
         legs.priorBarOk = SigBar_MaxRangeOk(sym, tf, m_hAtr, InpMaxPriorBarRangeAtrMult, d_priorBar);

      detail = d_bb + " | BUY " + d_stBuy + " SELL " + d_stSell + " | BUY " + d_emaBuy + " SELL " + d_emaSell + " | " + d_vol
               + " | BUY " + d_dispBuy + " SELL " + d_dispSell + " | BUY " + d_sessBuy + " SELL " + d_sessSell
               + " | BUY " + d_htfBuy + " SELL " + d_htfSell + " | " + d_adx + " | " + d_atrPct + " | " + d_priorBar;
      return true;
     }

public:
   CSignalEngine(): m_hBands(INVALID_HANDLE), m_hEmaFast(INVALID_HANDLE), m_hEmaSlow(INVALID_HANDLE),
      m_hAtr(INVALID_HANDLE), m_hHtfEma(INVALID_HANDLE), m_hAdx(INVALID_HANDLE) {}

   bool Init(const string sym, const ENUM_TIMEFRAMES tf)
     {
      Deinit();
      m_hBands = iBands(sym, tf, InpBbPeriod, 0, InpBbDeviation, PRICE_CLOSE);
      m_hEmaFast = iMA(sym, tf, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
      m_hEmaSlow = iMA(sym, tf, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
      m_hAtr = iATR(sym, tf, InpAtrPeriod);
      m_hHtfEma = INVALID_HANDLE;
      m_hAdx = INVALID_HANDLE;
      if(InpUseHtfTrendFilter && InpHtfTrendEmaPeriod > 0)
         m_hHtfEma = iMA(sym, InpHtfTrendTimeframe, InpHtfTrendEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(InpUseAdxMinFilter && InpAdxPeriod > 0)
         m_hAdx = iADX(sym, tf, InpAdxPeriod);
      if(m_hBands == INVALID_HANDLE || m_hEmaFast == INVALID_HANDLE || m_hEmaSlow == INVALID_HANDLE || m_hAtr == INVALID_HANDLE)
        {
         CLogger::Error("SignalEngine indicator init failed");
         return false;
        }
      if(InpUseHtfTrendFilter && m_hHtfEma == INVALID_HANDLE)
        {
         CLogger::Error("SignalEngine HTF EMA init failed");
         return false;
        }
      if(InpUseAdxMinFilter && m_hAdx == INVALID_HANDLE)
        {
         CLogger::Error("SignalEngine ADX init failed");
         return false;
        }
      return true;
     }

   void Deinit()
     {
      if(m_hBands != INVALID_HANDLE)
         IndicatorRelease(m_hBands);
      if(m_hEmaFast != INVALID_HANDLE)
         IndicatorRelease(m_hEmaFast);
      if(m_hEmaSlow != INVALID_HANDLE)
         IndicatorRelease(m_hEmaSlow);
      if(m_hAtr != INVALID_HANDLE)
         IndicatorRelease(m_hAtr);
      if(m_hHtfEma != INVALID_HANDLE)
         IndicatorRelease(m_hHtfEma);
      if(m_hAdx != INVALID_HANDLE)
         IndicatorRelease(m_hAdx);
      m_hBands = m_hEmaFast = m_hEmaSlow = m_hAtr = m_hHtfEma = m_hAdx = INVALID_HANDLE;
     }

   int AtrHandle() const { return m_hAtr; }
   int BandsHandle() const { return m_hBands; }
   int AdxHandle() const { return m_hAdx; }

   bool FeatureMetrics(const string sym,
                       const ENUM_TIMEFRAMES tf,
                       const ENUM_TRADE_DIR dir,
                       AecSignalFeatureMetrics &metrics) const
     {
      return AecSignalFeature_Collect(sym, tf, dir, m_hBands, m_hAtr, m_hAdx, metrics);
     }

   int MinBarsRequired() const
     {
      const int ema = (int)MathMax(InpEmaFast, InpEmaSlow) + 5;
      int bbExtra = 0;
      if(InpUseBbSqueezeDuration && InpBbMinSqueezeBars > 1)
         bbExtra = InpBbMinSqueezeBars;
      const int bb = InpBbPeriod + InpBbSqueezeLookback + bbExtra + 5;
      const int atr = InpAtrPeriod + 5;
      const int vol = InpVolumeMaLookback + 5;
      const int st = MathMax(2, InpSwingLookback) * 2 + 5;
      const int room = InpUseRoomToRun ? (InpRoomToRunLookback + 5) : 0;
      const int adx = InpUseAdxMinFilter ? (InpAdxPeriod + 5) : 0;
      const int atrPct = InpUseAtrPercentileBand ? (InpAtrPercentileLookback + InpAtrPeriod + 5) : 0;
      int m = ema;
      m = MathMax(m, bb);
      m = MathMax(m, atr);
      m = MathMax(m, vol);
      m = MathMax(m, st);
      m = MathMax(m, room);
      m = MathMax(m, adx);
      m = MathMax(m, atrPct);
      m = MathMax(m, InpMinBarsBeforeTrade);
      return m;
     }

   bool SnapshotLegs(const string sym, const ENUM_TIMEFRAMES tf, SignalLegSnapshot &legs, string &detail)
     {
      const int need = MinBarsRequired();
      if(need > Bars(sym, tf))
         return false;
      return CollectLegs(sym, tf, legs, detail);
     }

   bool Evaluate(const string sym, const ENUM_TIMEFRAMES tf, SignalResult &out)
     {
      out.direction = DIR_NONE;
      out.valid = false;
      out.reason = "";
      out.detail = "";

      if(InpForceTestSignal)
        {
         if(!MQLInfoInteger(MQL_TESTER))
           {
            out.reason = "ForceTestSignal only allowed in Strategy Tester";
            CLogger::Error(out.reason);
            return false;
           }
         out.valid = true;
         out.direction = (InpForceTestDirection >= 0 ? DIR_BUY : DIR_SELL);
         out.reason = "FORCED_TEST_SIGNAL";
         out.detail = "Bypass chain";
         return true;
        }

      const int need = MinBarsRequired();
      const int have = Bars(sym, tf);
      if(need > have)
        {
         out.reason = StringFormat("Not enough bars: have=%d need=%d", have, need);
         return false;
        }
      if(InpUseHtfTrendFilter && InpHtfTrendEmaPeriod > 0)
        {
         const int htfNeed = InpHtfTrendEmaPeriod + 5;
         const int htfHave = Bars(sym, InpHtfTrendTimeframe);
         if(htfNeed > htfHave)
           {
            out.reason = StringFormat("Not enough HTF bars: have=%d need=%d", htfHave, htfNeed);
            return false;
           }
        }

      SignalLegSnapshot legs;
      if(!CollectLegs(sym, tf, legs, out.detail))
         return false;

      const bool buy = legs.BuyChain();
      const bool sell = legs.SellChain();

      if(buy && sell)
        {
         out.reason = "Ambiguous BUY and SELL";
         out.valid = false;
         return true;
        }

      if(InpUseSignalSpreadCap && InpMaxSignalSpreadPoints > 0 && (buy || sell))
        {
         const int spread_pts = Aec_SpreadPoints(sym);
         if(spread_pts > InpMaxSignalSpreadPoints)
           {
            out.reason = StringFormat("Spread cap %d > %d", spread_pts, InpMaxSignalSpreadPoints);
            out.valid = false;
            out.detail = out.detail + " | " + out.reason;
            return true;
           }
        }

      if(buy)
        {
         out.valid = true;
         out.direction = DIR_BUY;
         out.reason = "AND_CHAIN_BUY";
         return true;
        }
      if(sell)
        {
         out.valid = true;
         out.direction = DIR_SELL;
         out.reason = "AND_CHAIN_SELL";
         return true;
        }

      out.reason = "No signal";
      out.valid = false;
      return true;
     }
  };

#endif // AEC_SIGNAL_ENGINE_MQH
