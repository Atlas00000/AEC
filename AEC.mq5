//+------------------------------------------------------------------+
//|                                                          AEC.mq5 |
//|                        Price Action Account Flipping Engine (P1) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.01"

#include "Core/Engine.mqh"

//+------------------------------------------------------------------+
int OnInit()
  {
   if(!Engine_Init())
      return INIT_FAILED;
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Engine_Deinit(reason);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   Engine_OnTick();
  }

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   Engine_OnTradeTransaction(trans);
  }

//+------------------------------------------------------------------+
double OnTester()
  {
   Engine_OnTesterEnd();
   return 0.0;
  }

//+------------------------------------------------------------------+
