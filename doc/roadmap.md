# Phase 1 roadmap — automated execution engine (single symbol)

This roadmap matches `concept.md` after inconsistency fixes. **Phase 1 = one chart, one symbol, one timeframe: a reliable automated execution path** (signals + risk + market orders + logging + state). It explicitly excludes AI, sessions-as-filters, portfolio logic, multi-symbol orchestration, adaptive optimisation, and rich trade management beyond SL/TP (and optional simple ATR trail as a **disabled** stub if present at all).

---

## Principles (avoid overengineering and scope creep)

- **Ship a vertical slice each week** that still **compiles with zero errors** in MetaEditor. No “week of headers only” that leaves the main EA broken.
- **One main EA file** (e.g. `AEC.mq5`) is the only compile target; everything else is `.mqh` included from there or from includes it pulls in.
- **Stubs are allowed** only when they implement a real interface (function signatures + return values) and do not break the build. Prefer “returns `false` / no-op” over empty files.
- **Do not add**: pending orders, partial closes, baskets, correlation, second timeframe, file-based state (except optional CSV logging), databases, UI panels beyond minimal comments, or “plugin” dynamic loading.
- **Testing is yours**: this roadmap ends at “ready for your compile-once tester pass”; it does not expand into test harness code inside the EA.

---

## Compile-once-before-testing rule

| Meaning | How we enforce it |
|--------|-------------------|
| **During development** | At the end of **every** week below, the full tree must **compile successfully** (F7). You should not merge a week’s work that leaves unresolved references or missing includes. |
| **Before you open Strategy Tester** | After the **final** week, perform **one** intentional full compile, attach to chart or tester once, then run your planned tests — avoid “change code between every tester run” as the default workflow. |

If a feature risks breaking the build mid-week, implement it behind a **compile-time-safe** path: complete the signature and minimal body first, then fill logic in the same week.

---

## Weekly implementation

### Week 1 — Repository scaffolding (compile-ready shell)

**Goal:** Folder layout, main EA, inputs, logger, empty tick path — **loads on chart, does not trade.**

- Create folder structure under `MQL5/Experts/AEC/` (aligned with `concept.md` folder map): `Config/`, `Core/`, `Signals/`, `Risk/`, `Execution/`, `Utils/`, `Models/`, `Enums/` as needed.
- Add main `AEC.mq5` (name may match your repo): `OnInit` / `OnDeinit` / `OnTick` calling a thin `Engine_OnTick()` in `Core/Engine.mqh`.
- `Config/Inputs.mqh`: declare **all** Phase 1 `input` variables (risk, magic, slippage, toggles, indicator periods). Defaults safe for live (e.g. trading disabled flag if you use one).
- `Utils/Logger.mqh`: journal logging + verbosity enum; no CSV until optional later week.
- `Enums/Types.mqh` + minimal `Models/` structs if needed for compile.
- **Out of scope:** Any signal math, any `OrderSend`, globals persistence.

**Exit:** F7 compile OK; EA attaches; journal shows init + heartbeat optional.

---

### Week 2 — State machine + engine orchestration (still no live orders)

**Goal:** Deterministic tick pipeline and states from `concept.md` — **no order placement.**

- `Core/StateMachine.mqh`: states `IDLE`, `SIGNAL_PENDING`, `VALIDATING`, `EXECUTING`, `COOLDOWN`, `BLOCKED` (subset may no-op until Week 3–4).
- `Core/Engine.mqh`: single entry `Engine_OnTick()` — new bar gate if using closed-bar confirmation, early exit if `BLOCKED` or not new bar when required.
- Wire **read-only** checks: spread vs max (log + stay `IDLE`), optional “trading enabled” input.
- **Out of scope:** Indicator handles, position sizing, order validation details.

**Exit:** F7 compile OK; states transition in journal on simulated paths (e.g. forced `BLOCKED` via input).

---

### Week 3 — Risk engine + order validation (compile-ready, no sends)

**Goal:** All **reject reasons** exist before any broker call — **still no `OrderSend`.**

- `Risk/RiskManager.mqh` + `Risk/PositionSizing.mqh`: fixed lot, optional % risk, equity/daily DD rules returning allow/deny + reason string for logger.
- `Execution/OrderValidator.mqh`: stops/freeze levels, volume min/step/max, filling mode probe (`SymbolInfoInteger` / trade fill modes), deviation mapping to `MaxSlippagePoints` as per spec.
- `Execution/TradeTracker.mqh`: count positions by `magic` + symbol; support max trades / per-direction if in inputs.
- **Out of scope:** Signal combination, FOK/IOC retry loop (stub return codes only if needed for compile).

**Exit:** F7 compile OK; from `OnTick`, a **test hook** (input-guarded) can call validator and log pass/fail without sending.

---

### Week 4 — Execution path + persistence hooks (controlled live send)

**Goal:** Market **buy/sell** with validation and logging — **gated by master switch + all signal inputs forcing “no signal” OR explicit tester-only flag.**

- `Execution/TradeExecutor.mqh`: build request struct, filling preference order (FOK → IOC → fallback), **max 1–2 retries** on requote/busy only; no dynamic slippage widening.
- Global variables: last trade time, cooldown end, daily lock — **write/read helpers only**; no file DB.
- `TradeTracker` integration after successful open for cooldown start.
- **Safety:** Default `input bool InpAllowLiveTrading = false` (or equivalent) so compile-first attach does not fire orders unintentionally.
- **Out of scope:** Full signal stack; pending orders; trailing.

**Exit:** F7 compile OK; on demo with explicit enable + manual or stub “signal true”, one market order places SL/TP per spec.

---

### Week 5 — Signal engine (Phase 1 set only)

**Goal:** Implement **only** indicators and rules from `concept.md` Gap section — **combine logic fixed:** BB squeeze release AND structure break AND EMA alignment AND displacement AND volume expansion AND optional session toggle.

- One `Signals/SignalEngine.mqh` orchestrator calling: `BBSqueeze`, `StructureBreak`, `EMAMomentum`, `VolumeExpansion`, `Displacement`, optional session breakout module (toggle off by default).
- Respect **minimum bars** / history from spec before setting “ready to trade.”
- `Models/SignalModel.mqh`: direction + reason string for logger.
- **Out of scope:** Weighted scoring, MTF, regime labels, parameter auto-tuning.

**Exit:** F7 compile OK; on tester, trades only when full AND chain true; journal prints signal breakdown.

---

### Week 6 — Integration, defaults, and handoff (completion)

**Goal:** Single **production compile** before your testing phase — **no new features.**

- Remove or guard any debug-only forced signals; confirm master switch semantics.
- End-to-end path: `IDLE` → new bar → signal → `VALIDATING` → risk → validator → `EXECUTING` → result log → `COOLDOWN` / `IDLE` / `BLOCKED`.
- Optional CSV logger toggle: if enabled, ensure header once + row per decision (per `concept.md`).
- Optional **disabled** ATR trail: either absent or compiled but default off and documented in inputs.
- README not required unless you want it; **no** extra markdown in repo unless you ask.

**Exit:** F7 compile OK; freeze code; **one** compile before you run your Strategy Tester / demo checklist from `concept.md`.

---

## Scope checklist (quick “are we gold-plating?”)

| Allowed Phase 1 | Defer |
|-----------------|-------|
| Market in/out via SL/TP (+ optional RR-derived TP) | Pending orders, partials, breakeven bots, time exits |
| Single-symbol, single TF, one EA instance | Multi-symbol, correlation, routing |
| Modular `.mqh` engines | Dynamic plugins, scripts generating code |
| Journal + optional CSV | Heavy analytics UI |
| Globals for cooldown / daily lock | SQL / file state machine |
| FOK/IOC + capped retries | Endless retry / widening slippage |

---

## Completion definition

Phase 1 is **done** when: (1) the EA compiles cleanly, (2) with your inputs it runs through the full pipeline without invalid orders, (3) risk and safety blocks are observable in logs, (4) signal logic matches the fixed AND-chain in `concept.md`, and (5) you take over with your own testing plan without further feature work.
