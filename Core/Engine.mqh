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
#include "StateMachine.mqh"
#include "../Risk/RiskManager.mqh"
#include "../Risk/PositionSizing.mqh"
#include "../Execution/TradeTracker.mqh"
#include "../Execution/OrderValidator.mqh"
#include "../Execution/TradeExecutor.mqh"
#include "../Signals/SignalEngine.mqh"

class CEngine
  {
   CStateMachine    m_sm;
   CGlobalsPersist  m_gv;
   CRiskManager     m_risk;
   CSignalEngine    m_sig;
   CTradeExecutor   m_exec;
   datetime         m_lastBarOpen;
   int              m_blockReason; // 0 none, 1 daily DD, 2 hard equity, 3 min equity
   int              m_blockedDayId;
   bool             m_loggedAtrTrailStub;

   void SetCooldownFromNow()
     {
      const datetime until = TimeCurrent() + (datetime)InpCooldownSecondsAfterTrade;
      m_gv.SetTime("CD_UNTIL", until);
      CLogger::Debug(StringFormat("Cooldown until %s", TimeToString(until, TIME_DATE | TIME_SECONDS)));
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
      if(!CCsvLog::Init())
         CLogger::Error("CSV log init failed — continuing without CSV");
      if(InpUseExperimentalAtrTrail && !m_loggedAtrTrailStub)
        {
         CLogger::Info("Experimental ATR trail input is ON — Phase 1 has no trail logic (stub only).");
         m_loggedAtrTrailStub = true;
        }
      CLogger::Info(StringFormat("AEC init symbol=%s tf=%d allow=%s", _Symbol, (int)_Period, InpAllowTrading ? "true" : "false"));
      return true;
     }

   void Deinit(const int reason)
     {
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
      if(entry != DEAL_ENTRY_OUT)
         return;
      const double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                            + HistoryDealGetDouble(deal, DEAL_SWAP)
                            + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(InpCooldownAfterLossOnly && profit < 0.0)
         SetCooldownFromNow();
     }

   void OnTick()
     {
      m_risk.UpdateDayRollover();
      TryResetDailyBlock();

      if(m_sm.State() == STATE_BLOCKED)
        {
         // remain blocked until rules clear daily case
         return;
        }

      if(InCooldown())
         return;

      const double point = Aec_PointSize(_Symbol);
      const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const int spread_pts = (point > 0.0) ? (int)MathRound((ask - bid) / point) : 0;
      if(spread_pts > InpMaxSpreadPoints)
        {
         CLogger::Trace(StringFormat("Skip tick: spread_pts=%d max=%d", spread_pts, InpMaxSpreadPoints));
         return;
        }

      if(!InpAllowTrading)
         return;

      if(!Aec_IsNewBar(_Symbol, _Period, m_lastBarOpen))
         return;

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

      if(InpTradeDirection > 0 && sig.direction != DIR_BUY)
         return;
      if(InpTradeDirection < 0 && sig.direction != DIR_SELL)
         return;

      if(!CTradeTracker::HasRoomForNew(_Symbol, InpMagic, (int)sig.direction, rsk))
        {
         CLogger::Info(rsk);
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

#endif // AEC_ENGINE_MQH
