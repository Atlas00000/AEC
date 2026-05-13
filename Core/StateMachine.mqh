//+------------------------------------------------------------------+
//| StateMachine.mqh — minimal state holder + transitions            |
//+------------------------------------------------------------------+
#ifndef AEC_STATE_MACHINE_MQH
#define AEC_STATE_MACHINE_MQH
#include "../Enums/Types.mqh"
#include "../Utils/Logger.mqh"

class CStateMachine
  {
   EA_STATE m_state;
public:
   CStateMachine(): m_state(STATE_IDLE) {}

   EA_STATE State() const { return m_state; }

   void Set(const EA_STATE s, const string note)
     {
      if(m_state == s)
         return;
      m_state = s;
      CLogger::State(s, note);
     }

   void Force(const EA_STATE s, const string note)
     {
      m_state = s;
      CLogger::State(s, note);
     }
  };

#endif // AEC_STATE_MACHINE_MQH
