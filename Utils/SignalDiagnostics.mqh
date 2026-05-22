//+------------------------------------------------------------------+
//| SignalDiagnostics.mqh — Phase 0 leg counters (EDGE-0.1)          |
//+------------------------------------------------------------------+
#ifndef AEC_SIGNAL_DIAGNOSTICS_MQH
#define AEC_SIGNAL_DIAGNOSTICS_MQH
#include "../Config/Inputs.mqh"
#include "../Models/SignalModel.mqh"
#include "../Utils/Logger.mqh"

class CSignalDiagnostics
  {
   ulong m_bars;
   ulong m_bb;
   ulong m_vol;
   ulong m_buyStruct;
   ulong m_sellStruct;
   ulong m_buyEma;
   ulong m_sellEma;
   ulong m_buyDisp;
   ulong m_sellDisp;
   ulong m_sessBuy;
   ulong m_sessSell;
   ulong m_fullBuy;
   ulong m_fullSell;
   ulong m_execBuy;
   ulong m_execSell;
   ulong m_nearSell5;
   ulong m_nearBuy5;

public:
   CSignalDiagnostics(): m_bars(0), m_bb(0), m_vol(0),
      m_buyStruct(0), m_sellStruct(0), m_buyEma(0), m_sellEma(0),
      m_buyDisp(0), m_sellDisp(0), m_sessBuy(0), m_sessSell(0),
      m_fullBuy(0), m_fullSell(0), m_execBuy(0), m_execSell(0),
      m_nearSell5(0), m_nearBuy5(0) {}

   void Reset()
     {
      m_bars = m_bb = m_vol = 0;
      m_buyStruct = m_sellStruct = m_buyEma = m_sellEma = 0;
      m_buyDisp = m_sellDisp = m_sessBuy = m_sessSell = 0;
      m_fullBuy = m_fullSell = m_execBuy = m_execSell = 0;
      m_nearSell5 = m_nearBuy5 = 0;
     }

   void RecordBar(const SignalLegSnapshot &legs)
     {
      m_bars++;
      if(legs.bb) m_bb++;
      if(legs.vol) m_vol++;
      if(legs.buyStruct) m_buyStruct++;
      if(legs.sellStruct) m_sellStruct++;
      if(legs.buyEma) m_buyEma++;
      if(legs.sellEma) m_sellEma++;
      if(legs.buyDisp) m_buyDisp++;
      if(legs.sellDisp) m_sellDisp++;
      if(legs.sessBuy) m_sessBuy++;
      if(legs.sessSell) m_sessSell++;
      if(legs.BuyChain()) m_fullBuy++;
      if(legs.SellChain()) m_fullSell++;

      const int bc = legs.BuyLegCount();
      const int sc = legs.SellLegCount();
      if(bc >= 5 && !legs.BuyChain()) m_nearBuy5++;
      if(sc >= 5 && !legs.SellChain()) m_nearSell5++;

      if(InpLogLevel >= LOG_DEBUG)
        {
         if(sc >= 5 && !legs.SellChain())
            CLogger::Debug(StringFormat("DIAG near-SELL %d/6 bb=%s vol=%s st=%s ema=%s disp=%s sess=%s",
                                        sc,
                                        legs.bb ? "Y" : "N", legs.vol ? "Y" : "N",
                                        legs.sellStruct ? "Y" : "N", legs.sellEma ? "Y" : "N",
                                        legs.sellDisp ? "Y" : "N", legs.sessSell ? "Y" : "N"));
         if(bc >= 5 && !legs.BuyChain())
            CLogger::Debug(StringFormat("DIAG near-BUY %d/6 bb=%s vol=%s st=%s ema=%s disp=%s sess=%s",
                                        bc,
                                        legs.bb ? "Y" : "N", legs.vol ? "Y" : "N",
                                        legs.buyStruct ? "Y" : "N", legs.buyEma ? "Y" : "N",
                                        legs.buyDisp ? "Y" : "N", legs.sessBuy ? "Y" : "N"));
        }
     }

   void RecordExecution(const ENUM_TRADE_DIR dir)
     {
      if(dir == DIR_BUY) m_execBuy++;
      else if(dir == DIR_SELL) m_execSell++;
     }

   void LogSummary() const
     {
      if(m_bars == 0)
        {
         CLogger::Info("DIAG summary: no bars recorded");
         return;
        }
      CLogger::Info(StringFormat(
         "DIAG summary bars=%I64u | bb=%I64u vol=%I64u | buySt=%I64u sellSt=%I64u buyEma=%I64u sellEma=%I64u buyDisp=%I64u sellDisp=%I64u | FULL_BUY=%I64u FULL_SELL=%I64u nearBuy5=%I64u nearSell5=%I64u | execBuy=%I64u execSell=%I64u",
         m_bars, m_bb, m_vol,
         m_buyStruct, m_sellStruct, m_buyEma, m_sellEma, m_buyDisp, m_sellDisp,
         m_fullBuy, m_fullSell, m_nearBuy5, m_nearSell5,
         m_execBuy, m_execSell));
     }

   void WriteCsvSummary() const
     {
      if(!InpDiagWriteSummaryCsv || m_bars == 0)
         return;
      const int h = FileOpen(InpDiagSummaryFile, FILE_WRITE | FILE_CSV | FILE_ANSI, ';');
      if(h == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("DIAG CSV open failed err=%d", GetLastError()));
         return;
        }
      FileWrite(h, "metric", "count");
      FileWrite(h, "bars", IntegerToString((long)m_bars));
      FileWrite(h, "bb", IntegerToString((long)m_bb));
      FileWrite(h, "vol", IntegerToString((long)m_vol));
      FileWrite(h, "buy_struct", IntegerToString((long)m_buyStruct));
      FileWrite(h, "sell_struct", IntegerToString((long)m_sellStruct));
      FileWrite(h, "buy_ema", IntegerToString((long)m_buyEma));
      FileWrite(h, "sell_ema", IntegerToString((long)m_sellEma));
      FileWrite(h, "buy_disp", IntegerToString((long)m_buyDisp));
      FileWrite(h, "sell_disp", IntegerToString((long)m_sellDisp));
      FileWrite(h, "full_buy", IntegerToString((long)m_fullBuy));
      FileWrite(h, "full_sell", IntegerToString((long)m_fullSell));
      FileWrite(h, "near_buy_5of6", IntegerToString((long)m_nearBuy5));
      FileWrite(h, "near_sell_5of6", IntegerToString((long)m_nearSell5));
      FileWrite(h, "exec_buy", IntegerToString((long)m_execBuy));
      FileWrite(h, "exec_sell", IntegerToString((long)m_execSell));
      FileClose(h);
      CLogger::Info(StringFormat("DIAG summary CSV written: %s", InpDiagSummaryFile));
     }
  };

#endif // AEC_SIGNAL_DIAGNOSTICS_MQH
