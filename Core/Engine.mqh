//+------------------------------------------------------------------+
//| Engine.mqh — orchestration (single symbol / chart TF)            |
//+------------------------------------------------------------------+
#ifndef AEC_ENGINE_MQH
#define AEC_ENGINE_MQH

#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"
#include "../Models/SignalModel.mqh"
#include "../Models/TradeModel.mqh"
#include "../Utils/Helpers.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"
#include "../Utils/CsvLog.mqh"
#include "../Utils/SignalDiagnostics.mqh"
#include "../Utils/MaeMfeTracker.mqh"
#include "../Utils/DealExport.mqh"
#include "StateMachine.mqh"
#include "../Risk/RiskManager.mqh"
#include "../Risk/PositionSizing.mqh"
#include "../Execution/TradeTracker.mqh"
#include "../Execution/OrderValidator.mqh"
#include "../Execution/TradeExecutor.mqh"
#include "../Execution/DeadTradeExit.mqh"
#include "../Execution/GiveBackExit.mqh"
#include "../Execution/NeverGreenSoftExit.mqh"
#include "../Execution/BreakevenExit.mqh"
#include "../Execution/PartialCloseExit.mqh"
#include "../Execution/AtrTrailExit.mqh"
#include "../Signals/SignalEngine.mqh"
#include "../Signals/HourDirection.mqh"

class CEngine
  {
   CStateMachine    m_sm;
   CGlobalsPersist  m_gv;
   CRiskManager     m_risk;
   CSignalEngine    m_sig;
   CTradeExecutor   m_exec;
   CSignalDiagnostics m_diag;
   datetime         m_lastBarOpen;
   int              m_blockReason; // 0 none, 1 daily DD, 2 hard equity, 3 min equity
   int              m_blockedDayId;
   bool             m_loggedAtrTrailStub;

   void SetCooldownFromNow(const int seconds_override = -1)
     {
      const int secs = (seconds_override > 0 ? seconds_override : InpCooldownSecondsAfterTrade);
      const datetime until = TimeCurrent() + (datetime)secs;
      m_gv.SetTime("CD_UNTIL", until);
      CLogger::Debug(StringFormat("Cooldown %ds until %s", secs,
                                  TimeToString(until, TIME_DATE | TIME_SECONDS)));
     }

   int ConsecutiveLossStreak() const
     {
      return (int)m_gv.GetInt("LOSS_STREAK", 0);
     }

   void SetConsecutiveLossStreak(const int n) const
     {
      m_gv.SetInt("LOSS_STREAK", (long)MathMax(0, n));
     }

   void OnExitDealProfit(const double profit)
     {
      if(InpCooldownAfterLossOnly && profit < 0.0)
         SetCooldownFromNow();

      if(!InpUsePostStreakGate)
         return;

      if(profit >= 0.0)
        {
         if(ConsecutiveLossStreak() > 0)
            SetConsecutiveLossStreak(0);
         return;
        }

      const int next = ConsecutiveLossStreak() + 1;
      SetConsecutiveLossStreak(next);
      if(next < InpPostStreakLossCount)
         return;

      SetCooldownFromNow(InpPostStreakPauseSeconds);
      SetConsecutiveLossStreak(0);
      CLogger::Info(StringFormat("Post-streak gate: %d consecutive losses — pause %ds",
                                 InpPostStreakLossCount, InpPostStreakPauseSeconds));
     }

   bool InCooldown() const
     {
      datetime cd = 0;
      if(!m_gv.GetTime("CD_UNTIL", cd))
         return false;
      return (cd > TimeCurrent());
     }

   void TryResetDailyBlock()
     {
      if(m_blockReason == 0)
         return;
      if(m_blockReason == 2)
         return;
      const int did = m_risk.CurrentDayId();
      if(did != m_blockedDayId)
        {
         m_blockReason = 0;
         m_sm.Set(STATE_IDLE, "new calendar day unblock");
        }
     }

   void CloseAllOurPositions(const string sym, const long magic)
     {
      CTrade tr;
      tr.SetExpertMagicNumber((int)magic);
      const int total = PositionsTotal();
      for(int i = total - 1; i >= 0; --i)
        {
         const ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != sym)
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != magic)
            continue;
         tr.PositionClose(ticket);
        }
     }

   bool ComputeSlTpPoints(const string sym,
                         const int atr_handle,
                         int &sl_pts,
                         int &tp_pts,
                         string &reason)
     {
      sl_pts = 0;
      tp_pts = 0;
      const double pt = Aec_PointSize(sym);
      if(pt <= 0.0)
        {
         reason = "bad point";
         return false;
        }

      if(InpSltpMode == SLTP_MODE_ATR)
        {
         double a[];
         ArraySetAsSeries(a, true);
         if(CopyBuffer(atr_handle, 0, 1, 1, a) != 1)
           {
            reason = "ATR copy failed";
            return false;
           }
         sl_pts = (int)MathRound((a[0] * InpAtrSlMultiplier) / pt);
        }
      else
        {
         sl_pts = Aec_UserDistanceToPoints(sym, InpSltpMode, InpStopLossPoints);
        }

      if(sl_pts <= 0)
        {
         reason = "SL points computed <= 0";
         return false;
        }

      if(InpUseRrForTp)
         tp_pts = (int)MathRound((double)sl_pts * InpRiskReward);
      else
        {
         if(InpSltpMode == SLTP_MODE_ATR)
            tp_pts = Aec_UserDistanceToPoints(sym, SLTP_MODE_POINTS, InpTakeProfitPoints);
         else
            tp_pts = Aec_UserDistanceToPoints(sym, InpSltpMode, InpTakeProfitPoints);
        }

      if(tp_pts <= 0)
        {
         reason = "TP points computed <= 0";
         return false;
        }
      return true;
     }

public:
   CEngine(): m_lastBarOpen(0), m_blockReason(0), m_blockedDayId(0), m_loggedAtrTrailStub(false) {}

   bool Init()
     {
      m_blockReason = 0;
      m_blockedDayId = 0;
      m_sm.Force(STATE_IDLE, "init");
      m_lastBarOpen = iTime(_Symbol, _Period, 0);
      m_gv.Init(InpMagic);
      m_risk.AttachGlobals(&m_gv);
      m_risk.OnInitDayAnchor();
      if(!m_sig.Init(_Symbol, _Period))
         return false;
      m_diag.Reset();
      if(InpDiagSignalLegs)
         CLogger::Info("Phase 0 diagnostics ON — leg summary at deinit (see journal + AEC_diag_summary.csv)");
      if(!CCsvLog::Init())
         CLogger::Error("CSV log init failed — continuing without CSV");
      if(InpExportDeals || AecExportMaeMfeActive())
         CDealExport::Reset();
      if(InpUseExperimentalAtrTrail && !InpUseAtrTrailAfterR && !m_loggedAtrTrailStub)
        {
         CLogger::Info("InpUseExperimentalAtrTrail is legacy — use InpUseAtrTrailAfterR (EDGE-6.6).");
         m_loggedAtrTrailStub = true;
        }
      CLogger::Info(StringFormat("AEC v1.01 P5-F production (T48) symbol=%s tf=%d allow=%s buyBlock=[%d,%d) diag=%s export=%s",
                                 _Symbol, (int)_Period,
                                 InpAllowTrading ? "true" : "false",
                                 InpBlockBuyHourStart, InpBlockBuyHourEnd,
                                 InpDiagSignalLegs ? "on" : "off",
                                 InpExportDeals ? "on" : "off"));
      return true;
     }

   void Deinit(const int reason)
     {
      if(InpDiagSignalLegs)
        {
         m_diag.LogSummary();
         m_diag.WriteCsvSummary();
        }
      CDealExport::ExportOnDeinit(_Symbol, InpMagic);
      m_sig.Deinit();
      CCsvLog::Shutdown();
      CLogger::Info(StringFormat("AEC deinit reason=%d", reason));
     }

   void OnTradeTransaction(const MqlTradeTransaction &trans)
     {
      if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
         return;
      if(trans.symbol != _Symbol)
         return;
      const ulong deal = trans.deal;
      if(deal == 0)
         return;
      if(!HistoryDealSelect(deal))
         return;
      if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagic)
         return;
      const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      CMaeMfeTracker::OnDeal(deal, _Symbol, InpMagic);
      if(entry != DEAL_ENTRY_OUT)
         return;
      const double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                            + HistoryDealGetDouble(deal, DEAL_SWAP)
                            + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      OnExitDealProfit(profit);
      CDealExport::RecordCloseDeal(deal, _Symbol, InpMagic);
     }

   void OnTesterEnd()
     {
      CDealExport::ExportOnTester(_Symbol, InpMagic);
      CDealExport::FlushMaeMfeOnly(_Symbol, InpMagic);
     }

   void OnTick()
     {
      m_risk.UpdateDayRollover();
      TryResetDailyBlock();

      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      CMaeMfeTracker::OnTick(_Symbol, InpMagic, bid, ask);
      const bool is_new_bar = Aec_IsNewBar(_Symbol, _Period, m_lastBarOpen);

      if(m_sm.State() != STATE_BLOCKED)
        {
         Aec_DeadTradeManageTick(_Symbol, _Period, InpMagic, bid, ask, is_new_bar, m_gv, m_exec);
         Aec_GiveBackManageTick(_Symbol, _Period, InpMagic, bid, ask, is_new_bar, m_gv, m_exec);
         Aec_NeverGreenSoftManageTick(_Symbol, _Period, InpMagic, bid, ask, is_new_bar, m_gv, m_exec);
         Aec_BreakevenManageTick(_Symbol, InpMagic, bid, ask, m_gv, m_exec);
         Aec_PartialCloseManageTick(_Symbol, InpMagic, bid, ask, m_gv, m_exec);
         Aec_AtrTrailManageTick(_Symbol, InpMagic, m_sig.AtrHandle(), bid, ask, m_gv, m_exec);
        }

      if(m_sm.State() == STATE_BLOCKED)
        {
         // remain blocked until rules clear daily case
         return;
        }

      if(InCooldown())
         return;

      const int spread_pts = Aec_SpreadPoints(_Symbol);
      if(spread_pts > InpMaxSpreadPoints)
        {
         CLogger::Trace(StringFormat("Skip tick: spread_pts=%d max=%d", spread_pts, InpMaxSpreadPoints));
         return;
        }

      if(!InpAllowTrading)
         return;

      if(!is_new_bar)
         return;

      if(InpUseTradingHours || InpUseHourExclusion)
        {
         const datetime signal_bar_time = iTime(_Symbol, _Period, 1);
         if(signal_bar_time == 0)
            return;
         if(InpUseTradingHours)
           {
            if(!Aec_BrokerHourInWindow(signal_bar_time, InpTradingHourStart, InpTradingHourEnd))
              {
               MqlDateTime dt;
               TimeToStruct(signal_bar_time, dt);
               CLogger::Trace(StringFormat("Skip bar: broker hour %d outside [%d,%d)",
                                           dt.hour, InpTradingHourStart, InpTradingHourEnd));
               return;
              }
           }
         if(InpUseHourExclusion)
           {
            if(Aec_BrokerHourInWindow(signal_bar_time, InpExcludeHourStart, InpExcludeHourEnd))
              {
               MqlDateTime dt;
               TimeToStruct(signal_bar_time, dt);
               CLogger::Trace(StringFormat("Skip bar: broker hour %d in excluded [%d,%d)",
                                           dt.hour, InpExcludeHourStart, InpExcludeHourEnd));
               return;
              }
           }
        }

      if(InpDiagSignalLegs)
        {
         SignalLegSnapshot legs;
         string ld = "";
         if(m_sig.SnapshotLegs(_Symbol, _Period, legs, ld))
            m_diag.RecordBar(legs);
        }

      string rsk = "";
      if(!m_risk.DailyDrawdownOk(rsk))
        {
         CLogger::Info(rsk);
         m_blockReason = 1;
         m_blockedDayId = m_risk.CurrentDayId();
         m_sm.Set(STATE_BLOCKED, "daily DD");
         return;
        }
      if(!m_risk.MinEquityOk(rsk))
        {
         CLogger::Info(rsk);
         m_blockReason = 3;
         m_blockedDayId = m_risk.CurrentDayId();
         m_sm.Set(STATE_BLOCKED, "min equity");
         return;
        }
      if(!m_risk.HardEquityOk(rsk))
        {
         CLogger::Info(rsk);
         if(InpCloseAllOnHardEquity)
            CloseAllOurPositions(_Symbol, InpMagic);
         m_blockReason = 2;
         m_blockedDayId = m_risk.CurrentDayId();
         m_sm.Set(STATE_BLOCKED, "hard equity");
         return;
        }

      SignalResult sig;
      if(!m_sig.Evaluate(_Symbol, _Period, sig))
        {
         CLogger::Debug(StringFormat("Signal eval failed: %s", sig.reason));
         return;
        }
      if(!sig.valid)
        {
         CLogger::Trace(StringFormat("No trade: %s", sig.reason));
         return;
        }

      CLogger::Debug(StringFormat("Signal %s | %s", sig.reason, sig.detail));

      if(InpTradeDirection > 0 && sig.direction != DIR_BUY)
         return;
      if(InpTradeDirection < 0 && sig.direction != DIR_SELL)
         return;

      if(InpUseHourDirectionFilter)
        {
         const datetime signal_bar_time = iTime(_Symbol, _Period, 1);
         string hdir = "";
         if(!Aec_HourDirectionAllows(sig.direction, signal_bar_time, hdir))
           {
            CLogger::Trace(hdir);
            return;
           }
        }

      if(!CTradeTracker::HasRoomForNew(_Symbol, InpMagic, (int)sig.direction, rsk))
        {
         CLogger::Info(rsk);
         return;
        }

      if(!m_risk.MaxTradesPerDayOk(rsk))
        {
         CLogger::Trace(rsk);
         return;
        }

      int sl_pts = 0, tp_pts = 0;
      if(!ComputeSlTpPoints(_Symbol, m_sig.AtrHandle(), sl_pts, tp_pts, rsk))
        {
         CLogger::Info(rsk);
         return;
        }

      const ENUM_ORDER_TYPE otype = (sig.direction == DIR_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      const double entry = (otype == ORDER_TYPE_BUY ? ask : bid);

      SltpPlan plan;
      if(!CPositionSizing::BuildSltpPlan(_Symbol, otype, entry, sl_pts, tp_pts, plan, rsk))
        {
         CLogger::Info(rsk);
         return;
        }

      string rsz = "";
      double lots = 0.0;
      if(InpUseRiskPercent)
         lots = CPositionSizing::LotsFromRiskPercent(_Symbol, sl_pts, rsz);
      else
         lots = CPositionSizing::LotsFromFixed(_Symbol, rsz);
      if(lots <= 0.0)
        {
         CLogger::Info(StringFormat("Lot sizing failed: %s", rsz));
         return;
        }

      m_sm.Set(STATE_VALIDATING, sig.reason);
      string vrej = "";
      if(!COrderValidator::ValidateMarket(_Symbol, otype, lots, plan.sl_price, plan.tp_price, vrej))
        {
         CLogger::Info(StringFormat("Order validation rejected: %s", vrej));
         CCsvLog::Row(_Symbol, (sig.direction == DIR_BUY ? "BUY" : "SELL"), entry, plan.sl_price, plan.tp_price, lots, spread_pts, sig.reason, StringFormat("REJ:%s", vrej));
         m_sm.Set(STATE_IDLE, "validation fail");
         return;
        }

      m_sm.Set(STATE_EXECUTING, "send");
      string er = "";
      const bool opened = m_exec.OpenMarket(_Symbol, otype, lots, plan.sl_price, plan.tp_price, er);
      if(!opened)
        {
         CLogger::Info(StringFormat("Open failed: %s", er));
         CCsvLog::Row(_Symbol, (sig.direction == DIR_BUY ? "BUY" : "SELL"), entry, plan.sl_price, plan.tp_price, lots, spread_pts, sig.reason, StringFormat("FAIL:%s", er));
         m_sm.Set(STATE_IDLE, "open fail");
         return;
        }

      CCsvLog::Row(_Symbol, (sig.direction == DIR_BUY ? "BUY" : "SELL"), entry, plan.sl_price, plan.tp_price, lots, spread_pts, sig.reason, "OK");
      m_risk.RecordTradeOpened();
      if(InpDiagSignalLegs)
         m_diag.RecordExecution(sig.direction);
      if(!InpCooldownAfterLossOnly)
         SetCooldownFromNow();
      m_sm.Set(STATE_IDLE, "done");
     }
  };

CEngine g_engine;

inline bool Engine_Init()
  {
   return g_engine.Init();
  }

inline void Engine_Deinit(const int reason)
  {
   g_engine.Deinit(reason);
  }

inline void Engine_OnTick()
  {
   g_engine.OnTick();
  }

inline void Engine_OnTradeTransaction(const MqlTradeTransaction &trans)
  {
   g_engine.OnTradeTransaction(trans);
  }

inline void Engine_OnTesterEnd()
  {
   g_engine.OnTesterEnd();
  }

#endif // AEC_ENGINE_MQH
