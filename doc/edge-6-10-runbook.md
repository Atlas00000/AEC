# EDGE-6.10 — Partial 25% at +1.0R (Phase 9)

**Hypothesis (EDGE-7.3):** MFE bins **0.6–1.5R** were net-negative — bank **25%** earlier at **1.0R**, let runner reach **2R TP**.

**vs EDGE-6.7 (reject):** 6.7 used **40%** at **1.2R** on P5-E; at **0.01** lot partial **never bound** (identical to baseline). 6.10 uses **1.0R** + **25%** on **P5-F** with **0.05** lot so the rule can execute.

| Input | Value |
|-------|--------|
| `InpUsePartialCloseAtR` | **true** |
| `InpPartialCloseTriggerR` | **1.0** |
| `InpPartialClosePercent` | **25** |
| `InpFixedLot` | **0.05** (required for partial) |

**Unchanged:** P5-F entry stack · SL 200 / TP 400 · BUY block **[14,15)**.

**Code:** existing `Execution/PartialCloseExit.mqh` · `TradeExecutor::PartialCloseVolume`.

---

## Result (2026-05-21) — **reject**

| Metric | T48 (0.01) | T63 (0.05) |
|--------|------------|------------|
| Net | +271.30 | +154.09 |
| PF | 1.17 | 1.02 |
| Trades | 1244 | 2048 |
| WR | 37% | 61.82% |
| Equity DD | ~24% | ~50% |

Partial **did** run at 0.05 lot but **destroyed** risk-adjusted edge. **No holdout.**

---

## Run (T63)

1. **F7** compile `AEC.mq5` (no code change if already built for 6.9).
2. Load **`AEC.P9-C_partial-25pct-at-1r_EDGE-6-10.set`**.
3. **EURUSD M5** · **2020.01.01 – 2026.05.19** · deposit **200**.
4. **Journal:** confirm lines like `Partial 25% at 1.00R` — if only `Partial skip`, lot is too small.

**Outputs:** `AEC_P9-C_deals.csv` · `AEC_P9-C_segments.csv`

---

## Success bar

**Primary (rule actually ran):** Journal shows partial closes on a meaningful % of winners.

| Metric | Target |
|--------|--------|
| PF | **≥ 1.17** (or clear lift vs same-lot P5-F if you rerun T48 @ 0.05) |
| Net $ | Higher than no-partial at **same lot** |
| WR | Up or flat |
| Equity DD % | Not worse than ~24% (scaled) |
| Trades | ~same order as T48 (not +300 churn like 6.9) |

**Reject** if: identical to P5-F at 0.01 (partial skipped) · PF &lt; 1.17 · net down · DD worse.

**Note:** Absolute **$ net** vs **T48 @ 0.01** is not apples-to-apples (5× size). Compare **PF**, **WR**, **DD%**, and optionally rerun **P5-F @ 0.05** as reference.

---

## If keep

Holdout **2024–2026** with same preset (**T64** vs T51 @ 0.05 or PF-only gate).

---

## Do not combine

Give-back (6.9) · dead-trade (6.4) · BE (6.8) in one test.
