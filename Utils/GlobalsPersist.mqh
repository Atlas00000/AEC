//+------------------------------------------------------------------+
//| GlobalsPersist.mqh — terminal global variables (no files)        |
//+------------------------------------------------------------------+
#ifndef AEC_GLOBALS_PERSIST_MQH
#define AEC_GLOBALS_PERSIST_MQH
#include "../Config/Inputs.mqh"
#include "../Utils/Logger.mqh"

class CGlobalsPersist
  {
   string m_prefix;
public:
   void Init(const long magic)
     {
      m_prefix = StringFormat("AEC_%I64d_", magic);
     }

   string Key(const string name) const { return m_prefix + name; }

   bool GetTime(const string name, datetime &out) const
     {
      const string k = Key(name);
      if(!GlobalVariableCheck(k))
         return false;
      out = (datetime)GlobalVariableGet(k);
      return true;
     }

   void SetTime(const string name, const datetime v) const
     {
      GlobalVariableSet(Key(name), (double)v);
     }

   void SetInt(const string name, const long v) const
     {
      GlobalVariableSet(Key(name), (double)v);
     }

   long GetInt(const string name, const long def) const
     {
      const string k = Key(name);
      if(!GlobalVariableCheck(k))
         return def;
      return (long)GlobalVariableGet(k);
     }

   void SetDouble(const string name, const double v) const
     {
      GlobalVariableSet(Key(name), v);
     }

   double GetDouble(const string name, const double def) const
     {
      const string k = Key(name);
      if(!GlobalVariableCheck(k))
         return def;
      return GlobalVariableGet(k);
     }

   void DeleteKey(const string name) const
     {
      const string k = Key(name);
      if(GlobalVariableCheck(k))
         GlobalVariableDel(k);
     }
  };

#endif // AEC_GLOBALS_PERSIST_MQH
