//+------------------------------------------------------------------+
//| CsvLog.mqh — optional decision rows                              |
//+------------------------------------------------------------------+
#ifndef AEC_CSV_LOG_MQH
#define AEC_CSV_LOG_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

class CCsvLog
  {
   static int s_handle;
   static bool s_header_done;
public:
   static void Shutdown()
     {
      if(s_handle != INVALID_HANDLE)
        {
         FileClose(s_handle);
         s_handle = INVALID_HANDLE;
        }
      s_header_done = false;
     }

   static bool Init()
     {
      Shutdown();
      if(!InpLogCsv)
         return true;
      if(!InpLogCsv)
         return true;
      const int flags = FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI | FILE_SHARE_READ;
      s_handle = FileOpen(InpCsvFileName, flags, ';');
      if(s_handle == INVALID_HANDLE)
        {
         CLogger::Error(StringFormat("CSV open failed err=%d", GetLastError()));
         return false;
        }
      FileSeek(s_handle, 0, SEEK_END);
      if(FileSize(s_handle) == 0)
         s_header_done = false;
      else
         s_header_done = true;
      return true;
     }

   static void Row(const string sym,
                  const string direction,
                  const double entry,
                  const double sl,
                  const double tp,
                  const double lot,
                  const int spread_pts,
                  const string signal_reason,
                  const string exec_result)
     {
      if(!InpLogCsv || s_handle == INVALID_HANDLE)
         return;
      if(!s_header_done)
        {
         FileWrite(s_handle, "timestamp", "symbol", "direction", "entry", "sl", "tp", "lot", "spread_pts", "signal", "exec");
         s_header_done = true;
        }
      FileWrite(s_handle,
                TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                sym,
                direction,
                DoubleToString(entry, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)),
                DoubleToString(sl, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)),
                DoubleToString(tp, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)),
                DoubleToString(lot, 2),
                IntegerToString(spread_pts),
                signal_reason,
                exec_result);
      FileFlush(s_handle);
     }
  };

int CCsvLog::s_handle = INVALID_HANDLE;
bool CCsvLog::s_header_done = false;

#endif // AEC_CSV_LOG_MQH
