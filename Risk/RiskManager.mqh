//+------------------------------------------------------------------+
//| RiskManager.mqh — equity / daily DD / hard stop                  |
//+------------------------------------------------------------------+
#ifndef AEC_RISK_MANAGER_MQH
#define AEC_RISK_MANAGER_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"
#include "../Utils/GlobalsPersist.mqh"

class CRiskManager
  {
   int    m_day_id;
   double m_day_start_equity;
   int    m_day_trades_opened;
   CGlobalsPersist *m_gv;

   void PersistDayTradeCount() const
     {
      if(m_gv == NULL)
         return;
      m_gv.SetInt("DAY_ID", m_day_id);
      m_gv.SetInt("DAY_TRADES", m_day_trades_opened);
     }

public:
   CRiskManager(): m_day_id(0), m_day_start_equity(0.0), m_day_trades_opened(0), m_gv(NULL) {}

   void AttachGlobals(CGlobalsPersist *gv) { m_gv = gv; }

   int CurrentDayId() const
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      return dt.year * 10000 + dt.mon * 100 + dt.day;
     }

   void OnInitDayAnchor()
     {
      m_day_id = CurrentDayId();
      m_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      m_day_trades_opened = 0;
      if(m_gv != NULL)
        {
         int saved_day = 0;
         int saved_trades = 0;
         m_gv.GetInt("DAY_ID", saved_day);
         m_gv.GetInt("DAY_TRADES", saved_trades);
         if(saved_day == m_day_id && saved_trades > 0)
            m_day_trades_opened = saved_trades;
         m_gv.SetDouble("DAY_START_EQ", m_day_start_equity);
         PersistDayTradeCount();
        }
     }

   void UpdateDayRollover()
     {
      const int did = CurrentDayId();
      if(did != m_day_id)
        {
         m_day_id = did;
         m_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
         m_day_trades_opened = 0;
         PersistDayTradeCount();
         CLogger::Info(StringFormat("Daily risk anchor reset: day=%d start_equity=%.2f trades=0",
                                    m_day_id, m_day_start_equity));
        }
     }

   void RecordTradeOpened()
     {
      m_day_trades_opened++;
      PersistDayTradeCount();
     }

   int DayTradesOpened() const { return m_day_trades_opened; }

   bool MaxTradesPerDayOk(string &reason) const
     {
      if(!InpUseMaxTradesPerDay || InpMaxTradesPerDay <= 0)
         return true;
      if(m_day_trades_opened >= InpMaxTradesPerDay)
        {
         reason = StringFormat("Max trades per day: %d >= %d", m_day_trades_opened, InpMaxTradesPerDay);
         return false;
        }
      return true;
     }

   bool DailyDrawdownOk(string &reason) const
     {
      if(InpMaxDailyDrawdownPercent <= 0.0)
         return true;
      const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(m_day_start_equity <= 0.0)
         return true;
      const double dd = (m_day_start_equity - eq) / m_day_start_equity * 100.0;
      if(dd >= InpMaxDailyDrawdownPercent)
        {
         reason = StringFormat("Max daily drawdown breached: dd=%.2f%% >= %.2f%%", dd, InpMaxDailyDrawdownPercent);
         return false;
        }
      return true;
     }

   bool MinEquityOk(string &reason) const
     {
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(bal <= 0.0)
         return true;
      const double thr = bal * (InpMinEquityPercentOfBalance / 100.0);
      if(eq < thr)
        {
         reason = StringFormat("Equity below threshold: eq=%.2f < thr=%.2f (%.1f%% of balance)", eq, thr, InpMinEquityPercentOfBalance);
         return false;
        }
      return true;
     }

   bool HardEquityOk(string &reason) const
     {
      if(InpHardEquityDrawdownPercent <= 0.0)
         return true;
      const double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(bal <= 0.0)
         return true;
      const double dd = (bal - eq) / bal * 100.0;
      if(dd >= InpHardEquityDrawdownPercent)
        {
         reason = StringFormat("Hard equity drawdown: dd=%.2f%% >= %.2f%%", dd, InpHardEquityDrawdownPercent);
         return false;
        }
      return true;
     }
  };

#endif // AEC_RISK_MANAGER_MQH
