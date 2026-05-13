//+------------------------------------------------------------------+
//| SignalEngine.mqh — Phase 1 AND-chain                             |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_ENGINE_MQH
#define AEC_SIGNAL_ENGINE_MQH
#include "../Config/Inputs.mqh"
#include "../Models/SignalModel.mqh"
#include "../Utils/Logger.mqh"
#include "BBSqueeze.mqh"
#include "StructureBreak.mqh"
#include "EMAMomentum.mqh"
#include "VolumeExpansion.mqh"
#include "Displacement.mqh"
#include "SessionBreakout.mqh"

class CSignalEngine
  {
   int m_hBands;
   int m_hEmaFast;
   int m_hEmaSlow;
   int m_hAtr;
public:
   CSignalEngine(): m_hBands(INVALID_HANDLE), m_hEmaFast(INVALID_HANDLE), m_hEmaSlow(INVALID_HANDLE), m_hAtr(INVALID_HANDLE) {}

   bool Init(const string sym, const ENUM_TIMEFRAMES tf)
     {
      Deinit();
      m_hBands = iBands(sym, tf, InpBbPeriod, 0, InpBbDeviation, PRICE_CLOSE);
      m_hEmaFast = iMA(sym, tf, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
      m_hEmaSlow = iMA(sym, tf, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
      m_hAtr = iATR(sym, tf, InpAtrPeriod);
      if(m_hBands == INVALID_HANDLE || m_hEmaFast == INVALID_HANDLE || m_hEmaSlow == INVALID_HANDLE || m_hAtr == INVALID_HANDLE)
        {
         CLogger::Error("SignalEngine indicator init failed");
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
      m_hBands = m_hEmaFast = m_hEmaSlow = m_hAtr = INVALID_HANDLE;
     }

   int AtrHandle() const { return m_hAtr; }

   int MinBarsRequired() const
     {
      const int ema = (int)MathMax(InpEmaFast, InpEmaSlow) + 5;
      const int bb = InpBbPeriod + InpBbSqueezeLookback + 5;
      const int atr = InpAtrPeriod + 5;
      const int vol = InpVolumeMaLookback + 5;
      const int st = MathMax(2, InpSwingLookback) * 2 + 5;
      int m = ema;
      m = MathMax(m, bb);
      m = MathMax(m, atr);
      m = MathMax(m, vol);
      m = MathMax(m, st);
      m = MathMax(m, InpMinBarsBeforeTrade);
      return m;
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

      string d_bb, d_stBuy, d_stSell, d_emaBuy, d_emaSell, d_vol, d_dispBuy, d_dispSell, d_sessBuy, d_sessSell;

      const bool bb = SigBb_Release(m_hBands, InpBbSqueezeLookback, InpBbSqueezeWidthRatio, d_bb);
      const bool vol = SigVol_Expanded(sym, tf, InpVolumeMaLookback, InpVolumeMultiplier, d_vol);
      const bool dispBuy = SigDisp_Bull(sym, tf, m_hAtr, InpDisplacementBodyAtrMult, d_dispBuy);
      const bool dispSell = SigDisp_Bear(sym, tf, m_hAtr, InpDisplacementBodyAtrMult, d_dispSell);

      const bool buyStruct = SigStruct_BuyBreak(sym, tf, InpSwingLookback, d_stBuy);
      const bool sellStruct = SigStruct_SellBreak(sym, tf, InpSwingLookback, d_stSell);

      const bool emaBuy = SigEma_AlignedBuy(m_hEmaFast, m_hEmaSlow, d_emaBuy);
      const bool emaSell = SigEma_AlignedSell(m_hEmaFast, m_hEmaSlow, d_emaSell);

      const bool sessBuy = SigSession_PassesBuy(sym, tf, d_sessBuy);
      const bool sessSell = SigSession_PassesSell(sym, tf, d_sessSell);

      const bool buy = bb && buyStruct && emaBuy && dispBuy && vol && sessBuy;
      const bool sell = bb && sellStruct && emaSell && dispSell && vol && sessSell;

      out.detail = d_bb + " | BUY " + d_stBuy + " SELL " + d_stSell + " | BUY " + d_emaBuy + " SELL " + d_emaSell + " | " + d_vol + " | BUY " + d_dispBuy + " SELL " + d_dispSell + " | BUY " + d_sessBuy + " SELL " + d_sessSell;

      if(buy && sell)
        {
         out.reason = "Ambiguous BUY and SELL";
         out.valid = false;
         return true;
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
