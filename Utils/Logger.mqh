//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//+------------------------------------------------------------------+
#ifndef AEC_LOGGER_MQH
#define AEC_LOGGER_MQH
#include "../Config/Inputs.mqh"
#include "../Enums/Types.mqh"

class CLogger
  {
public:
   static void Init()
     {
     }

   static bool LevelOk(const ENUM_LOG_LEVEL msg_level)
     {
      return (msg_level <= InpLogLevel);
     }

   static void Error(const string s)
     {
      PrintFormat("[AEC][ERROR] %s", s);
     }

   static void Info(const string s)
     {
      if(!LevelOk(LOG_INFO))
         return;
      PrintFormat("[AEC][INFO] %s", s);
     }

   static void Debug(const string s)
     {
      if(!LevelOk(LOG_DEBUG))
         return;
      PrintFormat("[AEC][DEBUG] %s", s);
     }

   static void Trace(const string s)
     {
      if(!LevelOk(LOG_TRACE))
         return;
      PrintFormat("[AEC][TRACE] %s", s);
     }

   static void State(const EA_STATE st, const string note)
     {
      if(!LevelOk(LOG_DEBUG))
         return;
      PrintFormat("[AEC][STATE] %d %s", (int)st, note);
     }
  };

#endif // AEC_LOGGER_MQH
