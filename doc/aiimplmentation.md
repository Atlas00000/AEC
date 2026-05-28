# AI implementation roadmap — AEC entry filter layer

**Status:** **AI-4/5/6 promoted** · production **P10-B (T70/T71)** · **AI-3 / AI-8 next** (regime + signal-bar scoring) · see [edge-8-3-production-lock.md](./edge-8-3-production-lock.md).

**Goal:** Add an **AI scoring / skip gate** on top of the existing signal chain and execution engine. The engine still opens, manages risk, and closes trades; AI answers: *is the regime OK?* and *take this entry or skip it?*

**Validated scope:** **2020–2026** (T50/T51/T70/T71). **Extended history (T73, 2010–2026):** PF **0.98** · net **−79.93** — **regime caution**, not EA breakage. Pre-2020 did not show the same squeeze→expansion economics.

**Not in scope:** LLM per-tick trade decisions · AI-managed exits · replacing BB/struct/EMA legs · multi-symbol models.

---

## Backlog — new tasks (quick nav)

Single index for **post–AI-4/6** work (regime fade, signal-bar scoring, operations). Completed AI-0–2 / AI-4–6 → see phase sections below.

| Order | ID | Task | Output / test | Status |
|------:|-----|------|---------------|--------|
| 1 | **EDGE-AI-3.1** | Export signal-bar features on chain pass (+ optional shadow rows) | `P10-E` → `AEC_P10-E_signal_features.csv` + deals | **done** |
| 2 | **EDGE-AI-3.2** | Merge features into dataset build | `data/ai/aec_trades_ml.csv` (v2) + `aec_signals_ml.csv` | **done** |
| 3 | **EDGE-AI-3.3** | Train **LightGBM** (L3; report L1/L2) on train ≤ 2023 | `data/ai/model_lgbm.*` | **done** |
| 4 | **EDGE-AI-3.4** | tau sweep vs T70/T71; compare to v1 logistic | `threshold_sweep_v2.csv` | **done** (offline **reject** — see summary) |
| 5 | **EDGE-AI-8.4** | Era split / calendar PF from deal CSVs | [edge-ai-8-4-regime-readout.md](./edge-ai-8-4-regime-readout.md) | **done** (2020+ data) |
| 6 | **T74** | Backtest **P5-F** 2010–2026 (no AI) | `P10-F` preset · vs T73 | **ready** |
| 7 | **EDGE-AI-8.1 / T75** | P10-B + **ATR pct** + **ADX min** | `P11-A` preset · 2010+ and 2020+ runs | **ready** |
| 8 | **EDGE-AI-3.5** | SHAP top-15 → readout; optional manual EDGE rule | [edge-ai-3-5-shap-readout.md](./edge-ai-3-5-shap-readout.md) | **done** |
| 9 | **EDGE-AI-3.6** | Labels **L2** / **L4** comparison | [edge-ai-3-6-label-comparison.md](./edge-ai-3-6-label-comparison.md) | **done** |
| 10 | **EDGE-AI-3.7** | MQL5 gate v2 — only if 3.4 beats T70/T71 | `AiEntryGate.mqh` v2 | `gated` |
| 11 | **EDGE-AI-8.2** | Rolling PF/net health → block or dynamic τ | `RegimeHealth.mqh` | `open` |
| 12 | **EDGE-AI-8.3** | Regime classifier `P(regime)` — stand down vs entry skip | Python + optional MQL5 | `open` |
| 13 | **EDGE-AI-8.5** | Update production lock with supported deployment era | [edge-8-3-production-lock.md](./edge-8-3-production-lock.md) | `open` |
| 14 | **EDGE-AI-7.1** | Quarterly retrain (rolling 3y train, 6–12m OOS) | refresh model / gate constants | `deferred` |
| 15 | **EDGE-AI-7.2** | Drift monitor — monthly PF vs T70 | alert if PF &lt; 1 over 30d | `deferred` |
| 16 | **EDGE-AI-7.3** | Demo forward P10-B (2020+ conditions) | live validation | `deferred` |
| — | **EDGE-AI-7.4** | Policy: never tune τ on reported holdout | — | `policy` |
| — | **EDGE-AI-7.5** | Policy: `InpUseAiEntryFilter=false` fallback = P5-F | — | `policy` |
| — | **T73** | Robustness P10-B **2010–2026** | PF 0.98 · **caution** · logged | `done` |

**v2 feature groups (for 3.1–3.2):** `bb_expand_ratio`, `bb_width_vs_avg`, `squeeze_bars`, `struct_break_atr`, `displacement_body_atr`, `prior_bar_range_atr`, `atr_percentile`, `adx_bar1`, `spread_pts`, leg pass flags, `loss_streak`, `hour_x_buy`.

---

## Why AI here (and not more rules)

| Observation (P5-F / Phase 7–9) | Implication |
|----------------------------------|-------------|
| PF **~1.17** stable · holdout **PASS** | Core edge is real — do not rewrite signals |
| WR **~37%** · avg win **~2×** avg loss | Optimize **entry quality**, not win rate alone |
| **45.8%** losers `never_green` · **16.8%** `fought_mfe05` | Labels and features already defined (T49) |
| Phase 9 **exit/filters rejected** (6.9–6.11, 5.7, 3.17) | Pre-trade **skip model** > another hand-tuned gate |
| **T73** 2010–2026 PF **0.98** | Edge is **regime-specific**; v1 AI (clock-only) cannot fix pre-2020 |
| T30 funnel ~**1 / 180 bars** · BB leg tightest | Rare **vol-release breakout** events, not always-on edge |

---

## Edge in price / candle behavior (research readout)

The stack is **not** generic trend-following. It targets **compression → expansion** on **closed bar 1 (shift 1)**:

| Behavior | Stack rule | Loser pathology (T49, P5-F) |
|----------|------------|-----------------------------|
| **Squeeze → release** | BB plate + release **w1/w2 ≥ 1.10** | **~45.8%** losers **never green** (`mfe_r < 0.2`) — false release / chop pop |
| **Real breakout** | Struct break **≥ 0.20× ATR** past swing | Cosmetic breaks in slow ranges |
| **Impulse bar** | Displacement body **≥ 0.55× ATR** | 0.65 ATR filter **rejected** (T15) — needs impulse, not max |
| **No exhaustion entry** | Prior bar range **≤ 2× ATR** | Entries after huge bars underperform |
| **No dead chop** | BB width **≥ avg × 1.0** | Thin width = range without follow-through |
| **Session** | **08–17**, peak **12–15** | **BUY hour 14** net **−33.82** → BUY block **[14,15)**; hour **13 BUY** strong |
| **Payoff** | SL 200 / TP 400 (**~2R**) | WR **~37%**, avg win **~2×** avg loss; wins cluster ~**+4**, losses ~**−2** |
| **Path (labels only)** | L3 skip never-green | **~16.8%** losers **fought** (MFE **≥ 0.5R** then full loss) — skip candidates, bad exits (T61 reject) |

**Implication for AI:** v1 (hour, weekday, month, `is_buy`) trims **clock** marginals only (holdout AUC ~0.51). v2 must score **this bar’s** release/break quality and **vol regime** — not calendar alone.

---

## Architecture

### Shipped (AI-4) — entry skip only

```text
[Bar 1 closed]
     ↓
[P5-F / P10-B signal chain]  →  full_buy / full_sell
     ↓
[Entry AI gate]  P(L3_take) ≥ τ  (logistic v1, embedded)
     ↓
[Risk + TradeExecutor]  —  UNCHANGED
```

### Target (AI-3 + AI-8) — regime + bar context

```text
[Bar 1 closed]
     ↓
[P5-F signal chain]  →  full_buy / full_sell
     ↓
[Regime gate]        →  vol/ADX/rolling health — "playbook era OK?"
     ↓
[Entry score AI]       →  BB/struct/displacement/spread on bar 1 — "this release OK?"
     ↓
[Risk + TradeExecutor]
```

| Layer | Responsibility | Status |
|-------|----------------|--------|
| **P5-F / P10-B stack** | Hours 8–17 · BB 1.10 · struct 0.20 · chop · prior cap · post-streak · BUY block [14,15) | **prod** |
| **Entry AI gate (v1)** | `P(L3_take) ≥ 0.45` — hour/weekday/month/direction | **prod** |
| **Regime gate (v2)** | ATR percentile band · ADX · rolling PF block / dynamic τ | **planned AI-8** |
| **Entry AI (v2)** | LightGBM on signal-bar features | **planned AI-3** |
| **Execution** | SL 200 / TP 400 · no Phase 6/9 exit overlays | **locked** |

**Research path:** train and sweep in **Python**. **Live path:** embedded logistic/tree constants or ONNX only after offline + T70/T71 bar met.

### Combating edge fade (regime shift)

Same **rules** do not imply same **economics** across decades (T73). Mitigation stack:

| Approach | Mechanism | EDGE |
|----------|-----------|------|
| **Regime gate (rules)** | `InpUseAtrPercentileBand` · `InpUseAdxMinFilter` — trade only when vol/trend state matches playbook | **AI-8.1** |
| **Rolling health** | Last N trades or 30d: if rolling PF &lt; 1 or net &lt; 0 → block new entries or raise τ | **AI-8.2** |
| **Entry score v2** | Skip bad *bars* (chop release, weak struct penetration) not just bad *hours* | **AI-3** |
| **Regime classifier** | Separate **P(good_regime)** from **P(good_trade)** on slow features (ATR pct, ADX, rolling stats) | **AI-8.3** |
| **Retrain / drift** | Rolling **3y train**, **6–12m** test; quarterly refresh; monthly PF vs T70 | **AI-7** |
| **Scope honesty** | Deploy as **2020+ validated** until long-history re-proven | **T73** doc |

Do **not** rely on v1 hour-only AI to detect 2010 vs 2020 regime change.

---

## Production baseline (do not degrade)

| Item | Value |
|------|--------|
| Preset | `AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set` |
| Reference test | **T70** full range · **T71** holdout (vs **T48** / **T51**) |
| T70 net / PF / trades | **+273.61** / **1.19** / **1144** · DD ~**14%** |
| T48 baseline (no AI) | **+271.30** / **1.17** / **1244** · DD ~**24%** |

See [edge-8-3-production-lock.md](./edge-8-3-production-lock.md).

---

## Success bar (any AI phase that touches production)

Same discipline as Phase 8–9:

| Metric | Target vs T48 |
|--------|----------------|
| Profit factor | **≥ 1.17** |
| Net profit | **Higher** |
| Win rate | Up or flat (not the primary goal) |
| Trades | Fewer OK if net improves |
| Equity DD % | **Not worse** than ~24% |
| Holdout (2024–2026) | **Not worse** than T51 (PF ≥ 1.05, net > 0 minimum; prefer match or beat T51) |

**Reject** if WR jumps but PF &lt; 1.17 (exit-churn pattern seen in T61–T64).

---

## Label strategy (pick one primary per model version)

| ID | Label | Use when |
|----|--------|----------|
| **L1** | `net_r > 0` at close | Simple profitability |
| **L2** | `mfe_r >= 1.0` | Would trade have reached meaningful MFE |
| **L3** | Skip `never_green` — loser with `mfe_r < 0.2` | Aligns with T49 taxonomy |
| **L4** | `net_r >= 0.5` | Middle ground for 2R profile |

**Default for EDGE-AI-1:** **L3** + report **L1** secondary.

**Leakage rules:** Features from **signal bar (shift 1) and earlier only** — never bar 0, never post-entry MFE/MAE in training rows.

---

## Feature set

### v1 — shipped in `AiEntryGate.mqh`

| Feature | Source | Notes |
|---------|--------|--------|
| `entry_hour` | deal / bar time | Top logistic coef magnitude |
| `entry_weekday` | MT5 `day_of_week` | |
| `entry_month` | MT5 `mon` | Weak seasonality |
| `is_buy` | direction | Hour×direction partly redundant |

Trained on **2020–2026** deals only — **out-of-distribution** on 2010–2019.

### v2 — EDGE-AI-3 (signal bar, no leakage)

Export at **`SignalEngine::Evaluate`** when chain passes (and optional shadow rows for skipped signals). **Never** use `mfe_r`, `mae_r`, `net_profit` as features.

| Group | Feature | Captures |
|-------|---------|----------|
| **BB** | `bb_expand_ratio` (w1/w2 bar 1) | Release quality |
| **BB** | `bb_width_vs_avg` | Chop vs expansion |
| **BB** | `squeeze_bars` / plate tightness | Compression depth |
| **Struct** | `struct_break_atr` (actual penetration) | Strong vs cosmetic break |
| **Displacement** | `displacement_body_atr` | Impulse on signal bar |
| **Exhaustion** | `prior_bar_range_atr` | Post-spike entries |
| **Regime** | `atr_level`, `atr_percentile` | Vol state |
| **Regime** | `adx_bar1` | Trend vs flat |
| **Micro** | `spread_pts` | Cost at signal |
| **Legs** | `pass_bb`, `pass_vol`, `pass_struct`, `pass_disp`, … | Which conditions fired |
| **Time** | `entry_hour`, `is_buy`, `hour_x_buy` | Keep v1 signal |
| **Context** | `loss_streak`, `trades_today` | Behavioral |

Optional **v3:** last N bar returns · session vol percentile · H1 ATR trend.

---

## Model stack (recommended order)

| Order | Model | Role |
|-------|--------|------|
| 1 | **LightGBM / XGBoost / CatBoost** | Primary skip classifier |
| 2 | **Logistic + calibration** | Baseline / explainability |
| 3 | **SHAP / feature importance** | Turn model → one human rule (optional EDGE) |
| — | **LLM** | Docs, hypotheses, log analysis only — **not** production gate |

---

## Phases and IDs

### Phase AI-0 — Data contract

| ID | Task | Output | Status |
|----|------|--------|--------|
| **EDGE-AI-0.1** | Define **one row per signal** schema (taken trades + optional shadow “would signal”) | [ai-data-schema.md](./ai-data-schema.md) | **done** |
| **EDGE-AI-0.2** | Export script: merge `AEC_P8-A/B` or `P7-D` deals + segment fields + leg flags | `scripts/ai_build_dataset.py` | **done** |
| **EDGE-AI-0.3** | Train/holdout split columns (`train` ≤ 2023, `holdout` ≥ 2024) | CSV in `data/ai/` | **done** |

**Exit:** Reproducible dataset build from existing tester CSVs in &lt; 1 min.

---

### Phase AI-1 — Offline baseline model

| ID | Task | Output | Status |
|----|------|--------|--------|
| **EDGE-AI-1.1** | Train classifier (label **L3** default) on **train** only | `scripts/ai_train_skip_model.py` | **done** |
| **EDGE-AI-1.2** | Evaluate on **holdout** + full — confusion, precision on `never_green` | `data/ai/train_metrics.json` | **done** |
| **EDGE-AI-1.3** | SHAP top-15 features → short readout | use `coefficients` in train_metrics (v1) | **deferred** |

**Exit:** Holdout AUC / precision documented; no MT5 change yet.

---

### Phase AI-2 — Threshold sweep (no backtest rerun)

| ID | Task | Output | Status |
|----|------|--------|--------|
| **EDGE-AI-2.1** | Simulate skip if `P(take) < τ` on historical deal rows | `scripts/ai_simulate_thresholds.py` | **done** |
| **EDGE-AI-2.2** | Sweep τ ∈ [0.35, 0.65] — report PF, net, trades, DD vs T48 | `data/ai/threshold_sweep.csv` | **done** |
| **EDGE-AI-2.3** | Pick **τ*** with net↑ and PF ≥ 1.17 on full; verify holdout not worse than T51 | `threshold_sweep_summary.json` | **done** (τ*=0.45) |

**Exit:** One τ* recommended or **stop** (no EA work).

---

### Phase AI-3 — Signal-bar features + stronger models (next)

Tasks → **[Backlog](#backlog--new-tasks-quick-nav)** (EDGE-AI-3.1–3.7).

**Exit:** Holdout beats **T71** and full-range beats **T70** (or clear never-green skip rate ↑ with net↑).

---

### Phase AI-8 — Regime gate & fade defense

Tasks → **[Backlog](#backlog--new-tasks-quick-nav)** (EDGE-AI-8.1–8.5, T74–T75).

**Exit:** Improved T73-era behavior **or** explicit “stand down” in bad regimes without killing 2020+ T70 metrics.

---

### Phase AI-4 — MQL5 integration (minimal)

| ID | Task | Output | Status |
|----|------|--------|--------|
| **EDGE-AI-4.1** | Inputs: `InpUseAiEntryFilter`, `InpAiMinProbTake` | `Config/Inputs.mqh` | **done** |
| **EDGE-AI-4.2** | `AiEntryGate.mqh` — embedded logistic (from `model_sklearn.json`) | `Execution/AiEntryGate.mqh` | **done** |
| **EDGE-AI-4.3** | Wire gate after hour filter, before risk/execute | `Core/Engine.mqh` | **done** |
| **EDGE-AI-4.4** | Presets `P10-B` / `P10-C` on P5-F stack | `presets/tester/` | **done** |
| **EDGE-AI-4.5** | Full-range backtest **T70** vs T48 | Report | **PASS** |

**Exit:** T70 meets success bar on full range.

**Prefer simplest deploy:** top-N rules from SHAP before full ONNX in MT5.

---

### Phase AI-5 — Validation (mirror Phase 8)

| ID | Task | Status |
|----|------|--------|
| **EDGE-AI-5.1** | Holdout backtest 2024–2026 **T71** with P10-C | **PASS** |
| **EDGE-AI-5.2** | Calendar-year sweep from deals (reuse `wf_8_2_summarize.py` pattern) | `open` |
| **EDGE-AI-5.3** | Compare T71 vs **T51** — promote only if pass | **PASS** |

**Exit:** Holdout PASS → candidate for production lock update.

---

### Phase AI-6 — Production lock (conditional)

| ID | Task | Status |
|----|------|--------|
| **EDGE-AI-6.1** | Update [edge-8-3-production-lock.md](./edge-8-3-production-lock.md) | **done** |
| **EDGE-AI-6.2** | `Inputs.mqh` defaults (`InpUseAiEntryFilter=true`) | **done** |
| **EDGE-AI-6.3** | Runbook [edge-ai-4-runbook.md](./edge-ai-4-runbook.md) | **done** |

---

### Phase AI-7 — Operations & retrain (live process)

Tasks → **[Backlog](#backlog--new-tasks-quick-nav)** (EDGE-AI-7.1–7.5).

---

## Recommended execution order

**Done:** AI-0 → AI-2 · AI-4 → AI-6 (incl. T70/T71).  
**Next:** follow **Order** in [Backlog — new tasks](#backlog--new-tasks-quick-nav).

---

## Do not repeat

| Anti-pattern | Why |
|--------------|-----|
| AI changes SL/TP or partial close | Phase 6/9 exit churn |
| Train on full 2020–2026 | Overfit; use T50/T51 split |
| Optimize for WR alone | Hides PF collapse |
| Block hours from one script only | 5.7 failed holdout |
| LLM in `OnTick` | Latency, audit, tester |
| Skip &gt; ~35% of trades without net proof | Starves 2R runners |
| Expect **period-invariant PF** from fixed rules | T73: pre-2020 losing era · regime-specific edge |
| v1 hour-only model for **regime** detection | Use **AI-8** slow features + **AI-3** bar features |
| More **exit** rules for never-green / fought | T61–T64 churn — **pre-trade skip** only |
| Train τ or model on **2010–2026** aggregate | Hides era failure; use split or rolling windows |
| Promote without **P5-F** long-history check | AI may be OOD pre-2020 even if stack is weak too |

---

## Dependencies

| Need | Source |
|------|--------|
| Deal CSVs with outcomes | `InpExportDeals` presets P7-D / P8-A/B |
| `mfe_r` / `mae_r` | v1.01 export or `p7d_mae_mfe_postprocess.py` |
| Leg diagnostics | P7-B or **AI-3.1** signal-bar export |
| Regime inputs | `InpUseAtrPercentileBand`, `InpUseAdxMinFilter` (off in prod until AI-8) |
| Python env | `pandas`, `scikit-learn`, `lightgbm` (or xgboost) — add `requirements-ai.txt` in AI-0 |

---

## Links

| Doc | Purpose |
|-----|---------|
| [edge-discovery.md](./edge-discovery.md) | Rule-based EDGE history |
| [edge-8-3-production-lock.md](./edge-8-3-production-lock.md) | Production lock (P10-B) · T73 scope |
| [edge-ai-4-runbook.md](./edge-ai-4-runbook.md) | T70/T71 validation |
| [edge-ai-0-runbook.md](./edge-ai-0-runbook.md) | Dataset + train pipeline |
| [edge-ai-3-1-runbook.md](./edge-ai-3-1-runbook.md) | Signal feature export (P10-E) |
| [edge-7-3-runbook.md](./edge-7-3-runbook.md) | MAE/MFE taxonomy |
| [test-results-log.md](./test-results-log.md) | Log T70+ when run |
| [paths.md](./paths.md) | Tester file paths |

---

## Current status

| Phase | Status |
|-------|--------|
| **AI-0–2** · **AI-4–6** | **done** — production **P10-B** |
| **AI-3.1** | **done** — [edge-ai-3-1-runbook.md](./edge-ai-3-1-runbook.md) |
| **AI-3.2+** · **AI-8** · **AI-7** | **open / deferred** — [Backlog](#backlog--new-tasks-quick-nav) |

**Robustness:** **T73** = **caution** — edge **2020+ validated** until backlog 8.x / 3.x improve long history.

Update this file when each **EDGE-AI-*** ID moves to `done` / `reject` / `deferred`.
