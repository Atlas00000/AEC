We are building an MT5 Expert Advisor (EA) centred around the following trading concept and system architecture:
[Price Action Account Flipping Engine
(Aggressive Expansion Capture)
Core Edge
Explosive account growth comes from:
asymmetrical volatility expansion,
not random overleveraging.
This system focuses on:
rare explosive momentum phases.

Indicator / PA Blend
BB Squeeze
Market Structure Break
Volume Expansion
Session Breakout
EMA Momentum
Displacement Candles

Core Logic
Only trade:
high-volatility expansion setups.
Risk aggressively only when:
structure breaks,
momentum confirms,
volume expands,
volatility releases.
Compound rapidly during:
directional acceleration.
Reduce size aggressively after losses.

Key Identity
This is NOT:
High leverage gambling.

It is:
Selective volatility exploitation with aggressive compounding.

]
Current Development Scope (Phase 1):
The focus right now is strictly on building the automated execution engine based on the selected indicators and signal logic. We are intentionally keeping the system lightweight and modular at this stage.
Important:
Do NOT introduce advanced filtering, AI layers, session filters, portfolio management, adaptive optimisation, or overengineered logic yet.
Do NOT add unnecessary complexity outside the core execution workflow.
The goal is simply to automate trade execution reliably using the selected indicators and trading conditions.
Core Objective:
Build a configurable execution engine capable of:
Reading indicator values and market conditions in real time
Evaluating entry conditions
Executing buy/sell trades automatically
Managing basic trade risk
Providing clean parameter configuration for optimization and future scaling
Execution Engine Requirements:
Configurable indicator inputs
Configurable entry conditions
Buy/sell execution logic
Support for market orders initially
Clean order validation before execution
Low-latency and lightweight processing
Modular architecture for future expansion
Basic Risk Management & Position Sizing:
Include foundational risk and trade management features only, such as the following:
Fixed lot size input
Optional risk-based position sizing (% (risk per trade)
Stop Loss (fixed points/pips or ATR-based if applicable)
Take Profit configuration
Risk-to-reward ratio support
Maximum spread filter
Slippage control
Maximum simultaneous open trades
Basic cooldown between trades
Magic number management
Equity/balance safety checks
Configurable trading permissions (buy only / sell only / both)
One Symbol vs Multi-Symbol
Use:
Single symbol
Single timeframe
Based strictly on the current chart
This is the correct decision for Phase 1.
Benefits:
Simpler execution flow
Easier debugging
Lower CPU usage
Cleaner state management
More reliable order tracking
Avoids synchronization complexity
Architecture assumption:
One EA instance per chart
One symbol context
One timeframe context
Avoid for now:
multi-symbol scanning
centralized portfolio engine
cross-chart communication
symbol routing
correlation logic
Future extensibility:
Your modular structure should still isolate the following:
signal engine
execution engine
risk engine
This makes future multi-symbol expansion possible without rewriting the core.
The EA should:
Be modular and extensible
Use clean separation of concerns
Support future integration of:
filters
session logic
AI optimization
volatility layers
portfolio controls
advanced trade management
multi-strategy routing
Architecture Goals:
Clean and maintainable codebase
Production-style folder structure
Clear module responsibilities
Configurable engine design
Scalable architecture without premature complexity
High execution reliability
Easy debugging and testing
Suggested Focus Areas:
Signal evaluation pipeline
Indicator management system
Trade execution module
Risk management module
Position sizing engine
Configuration/input management
Logging and debugging utilities
State and trade tracking
What I need from you:
Design the execution engine architecture
Define module responsibilities and execution workflow
Recommend an MT5 production-grade folder structure
Suggest industry best practices for EA development
Keep implementation practical, scalable, and efficient
Avoid unnecessary abstraction or feature creep
Prioritize configurability, maintainability, and execution reliability
The current objective is NOT strategy perfection or advanced intelligence.
The objective is building a strong, configurable execution foundation first.


Gap Answered
* **Exact Phase 1 signal set**

  * **Indicators shipping in v1**

    * Bollinger Bands squeeze detection
    * EMA momentum alignment
    * Volume expansion confirmation
    * Market structure break (swing high/low break)
    * Displacement candle validation
    * Optional session breakout range reference
  * **Deferred to later phases**

    * AI confidence scoring
    * Regime classification
    * Adaptive volatility filters
    * Portfolio-level controls
    * Multi-timeframe confirmation
    * Multi-symbol orchestration
    * Correlation logic
    * Dynamic optimization
  * **Core signal combine logic**

    * Base entry:

      * BB squeeze release = required
      * Structure break = required
      * EMA momentum alignment = required
      * Displacement candle = required
    * Confirmation layer:

      * Volume expansion = required (same as final `AND`; no weighted scoring in Phase 1)
      * Session breakout = optional input toggle (off by default)
    * Final logic:

      * `(BB Squeeze Release AND Structure Break AND EMA Momentum AND Displacement Candle)`
      * `AND Volume Expansion`
      * `AND Optional Session Breakout`
  * **Buy example**

    * Squeeze compression detected
    * Candle closes above recent swing high
    * Fast EMA > Slow EMA
    * Bullish displacement candle exceeds ATR/body threshold
    * Tick volume above moving average multiplier
  * **Sell example**

    * Mirror inverse logic
  * **Minimum history requirements**

    * EMA: `max(fastEMA, slowEMA) + 5`
    * Bollinger: `BB period + squeeze lookback`
    * ATR: `ATR period + 5`
    * Volume MA: `volume lookback`
    * Structure break: `swing lookback * 2`
    * Recommended safe minimum:

      * `150–300 bars loaded before trading starts`

---

* **Entry/exit contract**

  * **Phase 1 entries**

    * Market orders only
    * One-shot execution after closed-bar confirmation
    * No pending orders yet
  * **Phase 1 exits**

    * Stop Loss
    * Take Profit
    * Optional fixed Risk:Reward TP generation
  * **Not included in Phase 1**

    * Partial closes
    * Scaling in/out
    * Advanced trailing stop
    * Breakeven automation
    * Time-based exits
    * Basket exits
    * Equity curve adaptive exits
  * **Optional lightweight trailing**

    * Can exist as disabled experimental toggle
    * Simple ATR trail only
    * No complex logic

---

* **ATR / pip semantics**

  * Internal engine should standardize everything into:

    * raw price distance
    * points
  * User inputs may support:

    * pips
    * points
    * ATR multipliers
  * Conversion rules:

    * 5-digit FX:

      * 1 pip = 10 points
    * 3-digit JPY:

      * 1 pip = 10 points
    * Metals/indices:

      * use broker point size directly
  * SL/TP flow:

    * Input → normalize to points → convert to price
  * ATR SL example:

    * `SL = ATR(14) × 1.5`
  * RR TP example:

    * `TP Distance = SL Distance × RR`
  * Broker constraint handling:

    * Respect:

      * `SYMBOL_TRADE_STOPS_LEVEL`
      * `SYMBOL_TRADE_FREEZE_LEVEL`
    * Validate:

      * minimum stop distance
      * price precision
      * volume step/min/max

---

* **Filling and deviation policy**

  * Preferred fill order:

    * `ORDER_FILLING_FOK`
    * fallback:

      * `ORDER_FILLING_IOC`
    * fallback:

      * broker-supported mode
  * Execution deviation:

    * Single configurable:

      * `MaxSlippagePoints`
  * Relationship:

    * deviation input directly maps to request deviation
  * Retry policy:

    * Retry only on:

      * requote
      * temporary trade context busy
    * Max retries:

      * `1–2`
  * Do NOT:

    * endlessly retry
    * widen slippage dynamically
  * Failed validation:

    * abort cleanly
    * log exact reason

---

* **State machine**

  * Core state:

    * `IDLE`
    * `SIGNAL_PENDING`
    * `VALIDATING`
    * `EXECUTING`
    * `COOLDOWN`
    * `BLOCKED`
  * Cooldown handling:

    * Per symbol
    * Per EA instance
    * Applies after:

      * successful trade open
      * optional loss event
  * Max trades:

    * Per magic number
    * Per symbol
    * Optional:

      * per direction
  * Restart persistence:

    * Use:

      * terminal Global Variables
    * Persist:

      * last trade timestamp
      * cooldown state
      * daily lock state
  * Avoid Phase 1 complexity:

    * no database
    * no file persistence unless logging

---

* **Equity/balance rules**

  * Suggested protections:

    * Max daily drawdown %
    * Minimum equity threshold
    * Maximum floating DD %
  * Recommended actions:

    * Daily DD breach:

      * block new trades
    * Severe equity breach:

      * optional close-all
      * disable trading
  * Scope separation:

    * Daily = resets at broker day
    * Session = deferred
    * All-time = optional hard-stop
  * Example:

    * Daily DD:

      * `5%`
    * Hard equity protection:

      * `20%`
  * State after trigger:

    * `BLOCKED`
    * Requires:

      * next day reset
      * or manual reset

---

* **Logging spec**

  * Log categories:

    * Initialization
    * Indicator values
    * Signal decision
    * Validation failure
    * Risk calculations
    * Trade request
    * Trade result
    * State transitions
    * Safety rule triggers
  * Verbosity levels:

    * `ERROR`
    * `INFO`
    * `DEBUG`
    * `TRACE`
  * Phase 1 recommendation:

    * Journal logging mandatory
    * Optional CSV logging toggle
  * CSV fields:

    * timestamp
    * symbol
    * direction
    * entry price
    * SL
    * TP
    * lot size
    * spread
    * signal reason
    * execution result
  * Important:

    * every rejected trade must explain why

---

* **Testing plan**

  * Strategy Tester setup:

    * Every tick based on real ticks
    * Fixed spread tests
    * Variable spread tests
    * Multiple market regimes
  * Required tests:

    * Trending market
    * Choppy market
    * High-volatility news periods
    * Low liquidity periods
  * Minimal validation checklist before live:

    * No invalid orders
    * No duplicate trades
    * Cooldown works
    * SL/TP placement correct
    * Risk sizing accurate
    * Spread filter works
    * Equity protection works
    * Restart recovery works
    * Logs readable
  * Forward testing:

    * Demo account minimum:

      * `2–4 weeks`
  * Optimization caution:

    * prioritize robustness over peak backtest equity

---

* **Folder/module map**

  * Recommended structure (project folder name may match your repo, e.g. `AEC`):

    * `MQL5/Experts/AEC/` (or `Experts/PAFlipEngine/` — keep paths consistent with `#include`)
  * Main files:

    * `AEC.mq5` (or `PAFlipEngine.mq5` — one main EA entry point only)
    * `Config/Inputs.mqh`
    * `Core/Engine.mqh`
    * `Core/StateMachine.mqh`
    * `Signals/SignalEngine.mqh`
    * `Signals/BBSqueeze.mqh`
    * `Signals/StructureBreak.mqh`
    * `Signals/EMAMomentum.mqh`
    * `Signals/VolumeExpansion.mqh`
    * `Signals/Displacement.mqh`
    * `Risk/RiskManager.mqh`
    * `Risk/PositionSizing.mqh`
    * `Execution/TradeExecutor.mqh`
    * `Execution/OrderValidator.mqh`
    * `Execution/TradeTracker.mqh`
    * `Utils/Logger.mqh`
    * `Utils/Helpers.mqh`
    * `Models/SignalModel.mqh`
    * `Models/TradeModel.mqh`
    * `Enums/Types.mqh`
  * Include graph:

    * Main EA (e.g. `AEC.mq5` or `PAFlipEngine.mq5`)

      * loads:

        * Inputs
        * Engine
    * Engine:

      * orchestrates:

        * Signals
        * Risk
        * Execution
        * State
    * Execution isolated from signal logic
    * Risk isolated from execution logic

---

* **Optimization story**

  * Safe to optimize in Phase 1:

    * Risk %
    * Fixed lot
    * ATR multiplier
    * RR ratio
    * Cooldown duration
    * Spread filter
    * EMA lengths
    * BB squeeze threshold
    * Volume multiplier
    * Structure lookback
  * Dangerous to aggressively optimize:

    * too many filters together
    * candle micro-pattern thresholds
    * highly specific session values
    * overfit volatility windows
  * Best practice:

    * Optimize:

      * execution stability
      * risk consistency
      * robustness
    * Avoid:

      * curve-fitting raw signal logic
  * Recommended philosophy:

    * Keep signal logic stable
    * Optimize risk/execution layer first
    * Add adaptive intelligence later in AI phase
