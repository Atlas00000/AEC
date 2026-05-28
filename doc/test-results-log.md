# Test results log (one test at a time)

Run **one preset → one backtest → archive → log → next**. Do not chain presets without saving outputs first.

**Standard backtest:** EURUSD M5 · 2020.01.01–2026.05.19 · **deposit 200** · fixed lot 0.01. (T04/T05 used deposit 2000 for exploratory behaviour only.)

---

## Rules

1. **One active test** — finish and archive before loading the next preset.
2. **Unique outputs** — each preset writes its own CSV names (no overwrites between tests).
3. **Archive immediately** after each run into `doc/data/<test-id>/` before starting the next.
4. **Log the row** below before you move on.
5. **Upload/share one folder** at a time when sending results for review.

---

## Phase 0 sequence (in order)

| Order | Test ID | Preset | When done, archive |
|-------|---------|--------|-------------------|
| 1 | `T01` | `AEC.P0-B_force-sell_EDGE-0-1.set` | `doc/data/T01/` |
| 2 | `T02` | `AEC.P0-C_force-buy_EDGE-0-1.set` | `doc/data/T02/` |
| 3 | `T03` | `AEC.P0-A_baseline-diag_EDGE-0-1.set` | `doc/data/T03/` |
| 4 | `T04` | `AEC.RAW_baseline_LTF.set` | `doc/data/T04/` |
| 5 | `T05` | `AEC.P2-A_hours-8-17_EDGE-2-1.set` | `doc/data/T05/` |
| 6 | `T06` | `AEC.P2-B_struct-break-atr015_EDGE-2-2.set` | `doc/data/T06/` |
| 7 | `T07` | `AEC.P2-C_bb-release-expand108_EDGE-2-3.set` | `doc/data/T07/` |
| 8 | `T08` | `AEC.P2-D_volume-tier115_EDGE-2-4.set` | `doc/data/T08/` |
| 9 | `T09` | `AEC.P2-E_session-overlap_EDGE-2-5.set` | `doc/data/T09/` |
| 10 | `T31` | `AEC.P3-A_room-to-run_EDGE-3-11.set` | `doc/data/T31/` |
| 11 | `T10` | `AEC.P3-B_exclude-hours-1315_EDGE-3-1.set` | `doc/data/T10/` |
| 12 | `T11` | `AEC.P3-C_bb-release-expand110_EDGE-3-2.set` | `doc/data/T11/` |
| 13 | `T12` | `AEC.P3-D_bb-release-expand112_EDGE-3-3.set` | `doc/data/T12/` |
| 14 | `T32` | `AEC.P3-E_bb-expansion-persist_EDGE-3-12.set` | `doc/data/T32/` |
| 15 | `T13` | `AEC.P3-F_struct-break-atr020_EDGE-3-4.set` | `doc/data/T13/` |
| 16 | `T15` | `AEC.P3-G_displacement-atr065_EDGE-3-6.set` | `doc/data/T15/` |
| 17 | `T14` | `AEC.P3-H_struct-break-atr025_EDGE-3-5.set` | `doc/data/T14/` |
| 18 | `T33` | `AEC.P3-I_ema-overext-cap_EDGE-3-13.set` | `doc/data/T33/` |
| 19 | `T16` | `AEC.P3-J_min-bar-range-atr030_EDGE-3-7.set` | `doc/data/T16/` |

**Phase 3+ sequence** (vs P2-C · deposit 200): see [edge-discovery.md](./edge-discovery.md). T10 = EDGE-3.1; high-value extensions T31–T36 = EDGE-3.11–3.13, 3.14, 3.15, 5.5, etc.

Skip `T01`/`T02` if you already proved force exec; still run `T03` before `T04`.

---

## Per-test checklist

After each backtest completes:

- [ ] Copy **tester Report** (HTML) → `doc/data/<test-id>/report.html`
- [ ] Copy from `MQL5/Files/` (or tester agent `Files/`):
  - [ ] `AEC_<preset>_decisions.csv` (if preset enables CSV)
  - [ ] `AEC_<preset>_diag_summary.csv` (if diag preset)
- [ ] Screenshot or copy **journal** `DIAG summary` line → `doc/data/<test-id>/journal.txt`
- [ ] Fill row in **Run log** below
- [ ] Only then load the **next** preset

---

## Run log

| Test ID | Date run | Preset | Symbol TF | Date range | Pass? | Notes |
|---------|----------|--------|-----------|------------|-------|-------|
| T01 | 2026-05-20 | P0-B force-sell (hybrid: force + diag) | EURUSD M5 | 2026.05.01–19 | **PASS** | exec_sell=21, all FORCED SELL OK; see T01 notes below |
| T02 | 2026-05-20 | P0-C force-buy | EURUSD M5 | 2026.05.01–19 | **PASS** | exec_buy=23, all FORCED BUY OK; preset `AEC_P0-C_*` files used |
| T03 | 2026-05-20 | P0-A natural chain | EURUSD M5 | 2026.05.01–19 | **PASS** | exec_buy=10 exec_sell=11; AND_CHAIN_* only; PF 0.83 (not scored) |
| T04 | 2026-05-20 | RAW natural full range | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | 3418 trades · PF 0.93 · baseline for Phase 1/2 |
| T05 | 2026-05-20 | P2-A hours 8–17 | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | dep 2000 · 2395 trades · PF 0.96 · keep hours |
| T06 | 2026-05-20 | P2-B struct break 0.15 ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | dep 200 · PF 0.99 · keep stack |
| T07 | 2026-05-20 | P2-C BB release ≥1.08 | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | dep 200 · PF **1.01** · net **+43.49** · **production stack** |
| T08 | 2026-05-20 | P2-D volume 1.15 | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.00 · net -5.30 |
| T09 | 2026-05-20 | P2-E session overlap | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 0.94 · net -106.48 · Phase 2 done |
| T31 | 2026-05-20 | P3-A room-to-run 0.5×ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 0.97 · net -75.13 · 1884 trades · vs T07 |
| T10 | 2026-05-20 | P3-B exclude hours 13–15 | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.00 · net -7.70 · 1844 trades · vs T07 |
| T11 | 2026-05-20 | P3-C BB release ≥1.10 | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF **1.03** · net **+97.80** · 2133 trades · **production** |
| T12 | 2026-05-20 | P3-D BB release ≥1.12 | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.04 · net +100.23 · DD ~57% · stay P3-C |
| T32 | 2026-05-20 | P3-E BB expansion persist | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.02 · net +37.07 · 1598 trades · vs T11 |
| T13 | 2026-05-20 | P3-F struct break 0.20 ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF **1.04** · net **+103.71** · 2115 trades · **production** |
| T14 | 2026-05-20 | P3-H struct break 0.25 ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.03 · net +93.03 · 2100 trades · vs T13 |
| T33 | 2026-05-20 | P3-I EMA overext cap 1.2×ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.05 · net +60.62 · 892 trades · vs T13 |
| T16 | 2026-05-20 | P3-J min bar range 0.30×ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.04 · net +103.01 · 2116 trades · ≈T13 |
| T15 | 2026-05-20 | P3-G displacement 0.65 ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.00 · net -2.24 · 2079 trades · vs T13 |
| T42 | 2026-05-20 | P4-D prior bar range ≤2×ATR | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF **1.07** · net **+161.20** · 1706 trades · superseded by T43 |
| T43 | 2026-05-20 | P4-E BB chop skip ≥avg×1.0 | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF **1.14** · net **+241.63** · 1305 trades · **production** |
| T21 | 2026-05-20 | P5-A cooldown loss 90min | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.09 · net +151.62 · 1251 trades · vs T43 |
| T22 | 2026-05-20 | P5-B max 5 trades/day | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.14 · net +241.63 · 1305 trades · ≈T43 (no lift) |
| T23 | 2026-05-20 | P5-C daily DD 3% | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.14 · net +241.63 · 1305 trades · ≈T43 (no lift) |
| T44 | 2026-05-20 | P5-D block BUY [13,15) | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.15 · net +222.85 · 1175 trades · vs T43 |
| T36 | 2026-05-20 | P5-E post-streak 4 loss / 45min | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF **1.15** · net **+247.68** · 1302 trades · **production** |
| T24 | 2026-05-20 | P6-A RR 1.5 | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.06 · net +99.51 · 1414 trades · vs T36 |
| T27 | 2026-05-20 | P6-B dead-trade exit | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.09 · net +105.57 · 1677 trades · vs T36 |
| T45 | 2026-05-20 | P6-C BE at 0.8R | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.03 · net +42.58 · 1481 trades · vs T36 |
| T26 | 2026-05-20 | P6-D BE at 1.0R | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.07 · net +95.90 · 1427 trades · vs T36 |
| T46 | 2026-05-20 | P6-E partial 40% at 1.2R | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.15 · net +247.68 · 1302 trades · ≈T36 (no lift) |
| T25 | 2026-05-20 | P6-F RR 2.5 | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.04 · net +60.12 · 1178 trades · vs T36 |
| T28 | 2026-05-20 | P6-G SL 150 pts | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.01 · net +12.31 · 1537 trades · vs T36 |
| T29 | 2026-05-20 | P6-H ATR trail after 1R | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.01 · net +12.31 · 1537 trades · vs T36 |
| T47 | 2026-05-20 | P7-A deal export (P5-E stack) | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | T36 metrics · 1302 deal rows · segments OK |
| T48 | 2026-05-20 | P5-F block BUY [14,15) | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF 1.17 · net +271.30 · 1244 trades · vs T36 |
| T30 | 2026-05-20 | P7-B diag P5-F stack | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | exec 1244 = T48 · funnel in notes |
| T49 | 2026-05-20 | P7-D MAE/MFE export | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | T48 metrics · buckets via script |
| T50 | 2026-05-21 | P8-A OOS train | EURUSD M5 | 2020.01.01–2023.12.31 | **done** | PF 1.17 · net +179.77 · 830 trades · WR 37.11% · DD ~23% |
| T51 | 2026-05-21 | P8-B OOS holdout | EURUSD M5 | 2024.01.01–2026.05.19 | **PASS** | PF 1.18 · net +93.57 · 419 trades · WR 37.23% · DD ~16% |
| T59 | 2026-05-21 | P9-A block hour 16 (EDGE-5.7) | EURUSD M5 | 2020.01.01–2026.05.19 | **keep** | PF 1.17 · net +272.12 · 1226 trades · vs T48 +0.82 net |
| T60 | 2026-05-21 | P9-A holdout (EDGE-5.7 OOS) | EURUSD M5 | 2024.01.01–2026.05.19 | **reject** | PF 1.17 · net +87.56 · 410 trades · vs T51 −6.01 net |
| T61 | 2026-05-21 | P9-B give-back cap (EDGE-6.9) | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.02 · net +33.49 · 1532 trades · vs T48 −237.81 net |
| T63 | 2026-05-21 | P9-C partial 25% @ 1R (EDGE-6.10) | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 1.02 · net +154.09 · 2048 trades · lot 0.05 · DD ~50% |
| T64 | 2026-05-21 | P9-D soft never-green (EDGE-6.11) | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 0.99 · net −12.53 · 1632 trades · vs T48 −283.83 net |
| T65 | 2026-05-21 | P9-E BB release 1.12 (EDGE-3.17a) | EURUSD M5 | 2020.01.01–2026.05.19 | **reject** | PF 0.99 · net −16.47 · 1574 trades · vs T48 −287.77 net |
| T72 | 2026-05-20 | P10-A AI dataset export (EDGE-AI-0) | EURUSD M5 | 2020.01.01–2026.05.19 | **done** | PF 1.17 · net +273.34 · 1249 trades · ≈T48 · `AEC_P10-A_deals.csv` |
| T70 | 2026-05-20 | P10-B AI skip τ=0.45 (EDGE-AI-4) | EURUSD M5 | 2020.01.01–2026.05.19 | **PASS** | PF 1.19 · net +273.61 · 1144 trades · vs T48 +2.31 net |
| T71 | 2026-05-20 | P10-C AI skip holdout (EDGE-AI-5) | EURUSD M5 | 2024.01.01–2026.05.19 | **PASS** | PF 1.22 · net +105.61 · 386 trades · vs T51 +12.04 net |
| T73 | 2026-05-20 | P10-B robustness (extended history) | EURUSD M5 | **2010.01.01**–2026.05.19 | **caution** | PF 0.98 · net −79.93 · 3163 trades · DD ~38% · dep 1000 |
| T74a | 2026-05-20 | P10-F long range dep 200 (EDGE-AI-8) | EURUSD M5 | 2010–2026 (stopped) | **incomplete** | PF 0.85 · net −199 · 905 trades · wiped ~2014 |
| T74b | 2026-05-20 | P10-F long range dep 1000 (EDGE-AI-8) | EURUSD M5 | 2010.01.01–2026.05.19 | **done** | PF **0.98** · net **−95.91** · **3180** trades · DD **~39.5%** · no AI · vs T73 |
| T75 | — | P11-A regime gate (EDGE-AI-8) | EURUSD M5 | 2010+ and 2020+ | **pending** | P10-B + ATR 20–85 + ADX≥18 · preset ready |

---

## T74 result notes (2026-05-20) — P5-F long range, no AI

### T74b — **done** (full 2010–2026, dep 1000)

**Verdict: answers the era question — pre-2020 stack drag; AI is not the main T73 story.**

| Metric | T74b P5-F (no AI) | T73 P10-B (+ AI) | T70 / T48 (2020+ only) |
|--------|-------------------|------------------|-------------------------|
| Net (full) | **−95.91** | **−79.93** | +273 / +271 |
| PF (full) | **0.98** | **0.98** | **1.19** / 1.17 |
| Trades | **3180** | 3163 | 1144 / 1244 |
| Max DD | **~39.5%** | ~38% | ~14% / ~24% |

**Era buckets (T74b deals replay):**

| Era | Trades | Net | PF |
|-----|-------:|----:|---:|
| **pre2020** | 2034 | **−371.63** | **0.87** |
| **2020+** | 1146 | **+275.72** | **1.19** |
| holdout 2024+ | 389 | +105.64 | 1.22 |

**Worst years:** **2010** (−67), **2015** (−55), **2016** (−104, PF 0.67). **2022–2025** profitable (PF 1.30–1.35).

**Conclusions:**

1. **P5-F alone** on 2010–2026 ≈ **T73** (same PF 0.98, similar trade count) — extended-history loss is **regime / era**, not the AI skip gate.
2. **2020+ window** on stack-only matches **T70** (PF **1.19**, net **+276**, 1146 trades) — validates **2020+ production lock**.
3. **T74a** (dep 200) remains **invalid** for full-range; account depleted ~2014.

Archive: `data/ai/AEC_P10-F_T74b_deals.csv` · [edge-ai-8-4-regime-readout.md](./edge-ai-8-4-regime-readout.md)

**Next:** **T75** (P11-A regime gate) — long 2010–2026 + short 2020–2026.

---

## T74 / T75 — EDGE-AI-8 regime

Presets: **`AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set`** · **`AEC.P11-A_regime-gate_EDGE-AI-8-T75.set`**  
Runbook: [edge-ai-8-runbook.md](./edge-ai-8-runbook.md) · Checklist: [edge-ai-8-t74-t75-checklist.md](./edge-ai-8-t74-t75-checklist.md)

---

## T70 / T71 result notes (2026-05-20) — EDGE-AI-4 / AI-5

**Verdict: PASS (candidate promote)** — full-range and holdout **beat** P5-F references; equity DD **lower** than T48/T51.

| Metric | T48 P5-F | T70 P10-B AI | Δ |
|--------|----------|--------------|---|
| Net | +271.30 | **+273.61** | **+2.31** |
| PF | 1.17 | **1.19** | +0.02 |
| Trades | 1244 | 1144 | −100 (~8% skip) |
| WR% | 37.14 | 37.50 | +0.36pp |
| Equity DD | ~24% | **~14%** | much lower |

| Metric | T51 P5-F | T71 P10-C AI | Δ |
|--------|----------|--------------|---|
| Net | +93.57 | **+105.61** | **+12.04** |
| PF | 1.18 | **1.22** | +0.04 |
| Trades | 419 | 386 | −33 |
| WR% | 37.23 | 38.08 | +0.85pp |
| Equity DD | ~16% | **~16%** | ~flat |

**Gate check (aiimplmentation.md):** PF ≥ 1.17 · net > T48 · holdout PF ≥ 1.05 · net > 0 · **not worse than T51** — all **PASS**.

**Offline vs tester:** T70 trades **1144** vs replay **1117** (+2.4%); T71 **386** vs **378** (+2.1%) — aligned.

**Production:** **P10-B** promoted (EDGE-AI-6) · `Inputs.mqh` + [edge-8-3-production-lock.md](./edge-8-3-production-lock.md).

**Phase AI-4/5/6:** **complete** · **Next:** demo forward (AI-7 deferred) or AI-3 features if retrain.

---

## T73 result notes (2026-05-20) — extended-history robustness

**Purpose:** Check overfitting / regime dependence outside the **2020–2026** validation window.

**Setup (from report):** Presumed **P10-B** (production) · EURUSD M5 · deposit **1000** · **2010.01.01 – 2026.05.19** · 100% history quality.

| Metric | T73 (2010–2026) | T70 (2020–2026) | Note |
|--------|-----------------|-----------------|------|
| Net | **−79.93** | +273.61 | Edge concentrated in recent years |
| PF | **0.98** | 1.19 | Below 1.0 over full sample |
| Trades | 3163 | 1144 | ~2× history length, ~2.8× trades |
| WR% | 33.10 | 37.50 | Lower in older regimes |
| Equity DD | ~38% | ~14% | Much harsher on long sample |

**Verdict: caution (not a production revert by itself)**

- **Does not invalidate** T70/T71 within the **locked research window** (2020–2026 train/holdout still passed).
- **Does warn** the stack (and especially the **AI gate**, trained only on 2020–2026 deals) may be **regime-specific**; 2010–2019 likely drags aggregate PF below 1.
- **Not apples-to-apples** vs T70: deposit **1000** vs **200**; confirm preset was **P10-B** and lot **0.01**.

**Recommended follow-ups (optional):**

1. Same window **2010–2026** with **P5-F** (no AI) — separates “signal stack” vs “AI + recent training”.
2. Split reports: **2010–2019** vs **2020–2026** on one preset — locates where PF breaks.
3. Keep **live/demo scope** aligned with validation: treat **2020+** as the supported deployment era unless a future EDGE re-validates 2010+.

---

## T50 / T51 result notes (2026-05-21) — EDGE-8.1

**Verdict: PASS** — holdout PF **1.18** · net **+93.57** (gate: PF ≥ 1.05, net > 0).

| Window | Trades | Net | PF | WR% | Equity DD (report) |
|--------|-------:|----:|---:|----:|-------------------:|
| Train T50 | 830 | +179.77 | 1.17 | 37.11 | ~23% |
| Holdout T51 | 419 | +93.57 | 1.18 | 37.23 | ~16% |
| Full T48 (ref) | 1244 | +271.30 | 1.17 | 37.14 | ~24% |

**Readout:** WR and PF **stable** train → holdout; holdout DD **lower** than train; ~**$39/net per year** holdout vs ~**$45** train (similar pace). P5-F not curve-fit to 2020–2023 only.

**Exports:** `AEC_P8-A_train_*` · `AEC_P8-B_holdout_*` (+ mae_mfe_buckets if v1.01 export on).

**Phase 8.2:** **PASS** — calendar years from T50+T51 deals · **6/7** years net > 0 · 2020 flat (−0.17). See [edge-8-2-runbook.md](./edge-8-2-runbook.md).

**Phase 8.3:** **done** — [edge-8-3-production-lock.md](./edge-8-3-production-lock.md).

**Phase 8:** **complete**. **Next:** Phase 9.

---

## T49 result notes (2026-05-20) — EDGE-7.3

**Backtest:** Matches **T48** — PF **1.17** · net **+271.30** · **1244** trades · WR **37.14%** · equity DD **~24%**.

**7.1 export:** `AEC_P7-D_deals.csv` **1244** rows · `AEC_P7-D_segments.csv` totals OK.

**7.3 export (T49):** **Done (script)** — `python scripts/p7d_mae_mfe_postprocess.py` on existing `AEC_P7-D_deals.csv` (~2s, no tester rerun). Losers: **45.8%** `loser_never_green`, **16.8%** `loser_fought_mfe05`. EA in-test export optional (v1.01); post-process preferred when deals CSV already exists.

**Segment highlight (P5-F filter confirmed):** hour **14 BUY** only **6** trades (net **−0.07**) vs T47 **66** trades (net **−33.82**) before filter.

**Phase 7:** **complete** (7.1–7.3 · T49 script buckets).

**Phase 8:** **complete** (8.1 PASS · 8.2 PASS · 8.3 lock).

## T59 result notes (2026-05-21) — EDGE-5.7

**Verdict: keep (marginal)** vs **T48** — full-range only; **production reject** after **T60** holdout.

| Metric | T48 P5-F | T59 P9-A | Δ |
|--------|----------|----------|---|
| Net | +271.30 | **+272.12** | **+0.82** |
| PF | 1.17 | **1.17** | = |
| Trades | 1244 | 1226 | −18 |
| WR% | 37.14 | 37.19 | +0.05pp |
| Equity DD | ~24% | ~23% | slightly lower |

**Filter:** `InpUseHourExclusion` **[16,17)** on signal bar · BUY block **[14,15)** unchanged.

**Note:** Segment `entry_hour=16` may still show ~16 trades (entries opened after signals on hour **15** bars). Exclusion blocks **signal** hour 16, not entry clock hour.

## T60 result notes (2026-05-21) — EDGE-5.7 holdout

**Verdict: reject (production)** — holdout **worse than T51**; **P5-F stays locked**.

| Metric | T51 P5-F | T60 P9-A | Δ |
|--------|----------|----------|---|
| Net | +93.57 | **+87.56** | **−6.01** |
| PF | 1.18 | **1.17** | −0.01 |
| Trades | 419 | 410 | −9 |
| WR% | 37.23 | 37.07 | −0.16pp |
| Equity DD | ~16% | ~17% | slightly worse |

**Loose OOS gate** (PF ≥ 1.05, net > 0): still **PASS** — but promotion requires **not degrading** vs T51; failed.

**EDGE-5.7 overall:** T59 full-range marginal **keep** · T60 holdout **reject** → **do not promote**. **Next:** **EDGE-6.9**.

---

**Phase 9 — EDGE-5.7:** **closed (reject)** · production **P5-F (T48)**.

## T61 result notes (2026-05-21) — EDGE-6.9

**Verdict: reject** — exit churn like **6.4**; **no holdout**.

| Metric | T48 P5-F | T61 P9-B | Δ |
|--------|----------|----------|---|
| Net | +271.30 | **+33.49** | **−237.81** |
| PF | 1.17 | **1.02** | −0.15 |
| Trades | 1244 | 1532 | +288 |
| WR% | 37.14 | 48.43 | +11.3pp |
| Equity DD | ~24% | **~28%** | worse |
| Avg win | ~4.01 | **~1.89** | capped |
| Avg loss | ~−2.02 | ~−1.73 | smaller scratches |

**Readout:** Give-back closes many trades at ~small profit after +0.5R, cutting runners before 2R TP. WR up but net/PF collapse. **`InpUseGiveBackCap=false`** on production.

**Next Phase 9:** **EDGE-6.10** (partial at 1R) or **6.11** (soft never-green stop) — one at a time vs T48.

---

**Phase 9 — EDGE-6.9:** **closed (reject)** · **P5-F** locked.

## T63 result notes (2026-05-21) — EDGE-6.10

**Verdict: reject** — partial **bound** at 0.05 lot but **hurts** edge; **no holdout**.

| Metric | T48 P5-F (0.01) | T63 P9-C (0.05) | Note |
|--------|-----------------|-----------------|------|
| Net | +271.30 | +154.09 | ~×5 lot but net **≪** 5× baseline |
| PF | 1.17 | **1.02** | fail |
| Trades | 1244 | **2048** | +804 churn |
| WR% | 37.14 | **61.82** | partial banks 1R |
| Equity DD | ~24% | **~50%** | fail |

**Readout:** 25% @ 1R raises WR but **splits exits** / adds deal churn; runners weakened vs full 2R profile. Same failure mode as **6.9** (PF 1.02, high WR). **`InpUsePartialCloseAtR=false`**.

**Next:** **EDGE-6.11** (soft never-green) or **3.17** (entry BB) — not more partial/give-back exits.

---

**Phase 9 — EDGE-6.10:** **closed (reject)** · **P5-F** locked.

## T64 result notes (2026-05-21) — EDGE-6.11

**Verdict: reject** — net **negative** · **no holdout**.

| Metric | T48 P5-F | T64 P9-D | Δ |
|--------|----------|----------|---|
| Net | +271.30 | **−12.53** | **−283.83** |
| PF | 1.17 | **0.99** | fail |
| Trades | 1244 | 1632 | +388 |
| WR% | 37.14 | 42.46 | +5.3pp |
| Equity DD | ~24% | **~38%** | worse |

**Readout:** Softer than 6.4 (0.2R / 12 bars) still **churns** — early exits on slow winners, more deals, edge gone. **`InpUseSoftNeverGreenExit=false`**.

**Phase 9 exits/filters tried:** 5.7 · 6.9 · 6.10 · 6.11 **all reject** → **3.17** (entry) last in lane.

---

**Phase 9 — EDGE-6.11:** **closed (reject)** · **P5-F** locked.

## T65 result notes (2026-05-21) — EDGE-3.17a

**Verdict: reject** — **no holdout** · optional **T66** (duration) low priority (3.15 failed on P3-F).

| Metric | T48 P5-F | T65 P9-E | Δ |
|--------|----------|----------|---|
| Net | +271.30 | **−16.47** | **−287.77** |
| PF | 1.17 | **0.99** | fail |
| Trades | 1244 | **1574** | +330 |
| WR% | 37.14 | 42.19 | +5pp |
| Equity DD | ~24% | **~37%** | worse |

**Readout:** Stricter BB **1.12** did not improve P5-F — net negative, DD up. **+330 trades** vs T48 is unexpected for a tighter release gate; confirm **P9-E** was loaded (not an exit preset). If P9-E confirmed, treat as **reject** anyway.

**3.17b (squeeze 4):** skip unless you want confirmation — **T35** already net −28.90 on older stack.

**Phase 9:** **complete (no promote)** · **P5-F** locked.

---

**Phase 9 — EDGE-3.17:** **closed (reject)** · production **P5-F (T48)**.

---

## T30 result notes (2026-05-20) — EDGE-7.2

**Verdict:** Diagnostics **complete** (no production change). `exec_buy`+`exec_sell` = **1244** matches **T48**.

| Metric | Count | % of bars (177999) |
|--------|------:|-------------------:|
| `bb` | 7752 | **4.4%** (scarcest leg) |
| `vol` | 67597 | 38.0% |
| `buy_disp` | 33936 | 19.1% |
| `buy_struct` | 19206 | 10.8% |
| `buy_ema` | 88341 | 49.6% |
| `full_buy` | 973 | 0.55% |
| `full_sell` | 1090 | 0.61% |
| `exec_buy` | 550 | — |
| `exec_sell` | 694 | — |

**Funnel:** `exec_buy` / `full_buy` = **56.5%** · `exec_sell` / `full_sell` = **63.7%** — remainder blocked by max 1 position, post-streak, hour BUY block [14,15), risk/spread gates.

**Takeaway:** AND-chain is very selective (~1 in 180 bars); **BB squeeze/release** is the tightest single leg. Loosening BB without new EDGE tests is high risk.

**P7-A re-export:** 1244 deals · total net **+271.30** PF **1.17** — aligns with T48 segments.

---

## T48 result notes (2026-05-20)

**Verdict:** EDGE-5.6 block BUY **[14,15)** **keep** — supersedes **P5-E (T36)** for production.

| Check | T48 (P5-F) | T36 (P5-E) | Δ |
|-------|------------|------------|---|
| Preset | `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set` | P5-E | — |
| PF | **1.17** | 1.15 | +0.02 |
| Net | **+271.30** | +247.68 | **+23.62** |
| Trades | **1244** | 1302 | −58 |
| WR | **37.14%** | 36.79% | +0.35 pp |
| Max equity DD % | **~24.1%** | ~23.0% | +~1.0 pp |
| Sharpe | **1.67** | 1.43 | +0.24 |
| Avg win / loss | 4.01 / 2.02 | 4.01 / 2.03 | ≈ |

**Note:** T47 predicted h14 BUY drag (−33.82 net); removing **~58** h14 BUYs lifted net with small DD tick-up. **`Inputs.mqh`** defaults updated to P5-F (`InpUseHourDirectionFilter=true`, BUY block **[14,15)**).

---

## T47 result notes (2026-05-20)

**Backtest:** Matches **T36** — PF **1.15** · net **+247.68** · **1302** trades · WR **36.79%** · equity DD **~23%**.

**Export:** `AEC_P7-A_deals.csv` **1302** rows · `AEC_P7-A_segments.csv` hour/weekday/month buckets. Archive → `doc/data/T47/`.

### Hour (entry broker time, net / PF)

| Hour | Trades | Net | PF | Notes |
|------|--------|-----|-----|-------|
| 10 | 111 | +41.94 | 1.31 | Strong |
| 11 | 141 | +47.10 | 1.27 | Strong |
| **13** | 205 | **+46.39** | 1.18 | Overlap — **profitable** |
| **14** | 136 | **−18.43** | 0.91 | Overlap — **drag** |
| 15 | 145 | +33.52 | 1.18 | OK |
| 16 | 44 | −10.10 | 0.84 | Weak (few trades) |
| 8–9 | 333 | +59.89 | ~1.15 | OK |

**BUY hour 13:** net **+52.41** PF **1.47** · **BUY hour 14:** net **−33.82** PF **0.68** · **SELL hour 14:** net **+15.39**.

→ **EDGE-5.4** (block BUY [13,15)) was too coarse — cuts strong **h13** BUYs (matches T44 reject). Finer test: block BUY **[14,15)** only.

### Weekday (`1`=Mon … `5`=Fri)

| Day | Net | PF |
|-----|-----|-----|
| Thu | **+116.79** | 1.41 |
| Fri | +67.54 | 1.20 |
| Wed | +47.05 | 1.14 |
| Mon | +13.49 | 1.04 |
| Tue | +2.81 | 1.01 |

Mon **SELL** net **−21.64** PF 0.90 — optional future filter, not tested.

### Month

| Best | Net | Worst | Net |
|------|-----|-------|-----|
| Mar | +71.62 | Dec | **−43.69** |
| Jul | +62.71 | Jun | −14.40 |

**Direction total:** SELL net **+140.37** · BUY **+107.31** — both positive; no global BUY block justified.

**Verdict:** **EDGE-7.1 done** — data supports **no** full [13,15) BUY block; consider **h14-only** BUY throttle as new EDGE if tested.

---

## T29 result notes (2026-05-20)

**Verdict:** EDGE-6.6 ATR trail after **1R** **reject** — stay **P5-E** (`InpUseAtrTrailAfterR=false`).

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-H_atr-trail-after-1r_EDGE-6-6.set` |
| Deposit | 200 |
| PF | **1.01** (vs T36 **1.15**, Δ −0.14) |
| Net | **+12.31** (vs T36 **+247.68**, Δ **−235.37**) |
| Trades | **1537** (+235 vs T36) |
| WR | 33.83% (vs 36.79%) |
| Max equity DD % | ~45.4% (vs ~23.0%) |
| Sharpe | 0.11 |
| Avg win / avg loss | 3.01 / 1.53 |

**Note:** Report matches **T28** (P6-G SL 150) on every headline metric — confirm **Inputs** tab shows `InpUseAtrTrailAfterR=true`, `InpStopLossPoints=200`, and **Journal** has `ATR trail armed` lines. If not, re-run T29 after F7 compile + P6-H load.

**Phase 6:** complete — all exit layers **reject** vs T36 · **production = P5-E**.

---

## T28 result notes (2026-05-20)

**Verdict:** EDGE-6.5 SL **150** pts **reject** — stay **P5-E** (SL **200**).

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-G_sl-150pts_EDGE-6-5.set` |
| Deposit | 200 |
| PF | **1.01** (vs T36 **1.15**, Δ −0.14) |
| Net | **+12.31** (vs T36 **+247.68**, Δ **−235.37**) |
| Trades | **1537** (+235 vs T36) |
| WR | 33.83% (vs 36.79%) |
| Max equity DD % | ~45.4% (vs ~23.0%) |
| Sharpe | 0.11 |

**Note:** Tighter SL → more stop-outs and churn; net nearly flat, DD **2×** T36. **`InpStopLossPoints=200`** on production.

**Phase 6:** all tested exits rejected · **production = P5-E**.

*(Superseded by T29 section — Phase 6 closed.)*

---

## T25 result notes (2026-05-20)

**Verdict:** EDGE-6.2 RR **2.5** **reject** — stay **P5-E** (RR **2.0**).

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-F_rr-2_5_EDGE-6-2.set` |
| Deposit | 200 |
| PF | **1.04** (vs T36 **1.15**, Δ −0.11) |
| Net | **+60.12** (vs T36 **+247.68**, Δ **−187.56**) |
| Trades | **1178** (−124 vs T36) |
| WR | **29.63%** (vs 36.79%, −7.2 pp) |
| Max equity DD % | ~36.0% (vs ~23.0%) |
| Avg win / loss | ~5.01 / ~−2.04 (vs ~4.01 / ~−2.03) |
| Sharpe | 0.30 |

**Note:** Wider TP (500 pts) — fewer full TP hits, WR collapses; avg win up but not enough to offset lost 2R completions. Mirror of T24 (RR 1.5). **`InpRiskReward=2.0`** on production.

---

## Output files by preset

| Preset | Decisions CSV | Diag summary CSV |
|--------|---------------|------------------|
| P0-A | `AEC_P0-A_decisions.csv` | `AEC_P0-A_diag_summary.csv` |
| P0-B | `AEC_P0-B_decisions.csv` | `AEC_P0-B_diag_summary.csv` |
| P0-C | `AEC_P0-C_decisions.csv` | `AEC_P0-C_diag_summary.csv` |
| RAW | (off) | (off) |
| P2-A | (off) | (off) |
| P2-B | (off) | (off) |
| P2-C | (off) | (off) |
| P2-D | (off) | (off) |
| P2-E | (off) | (off) |
| P3-A | (off) | (off) |
| P3-B | (off) | (off) |
| P3-C | (off) | (off) |
| P3-D | (off) | (off) |
| P3-E | (off) | (off) |
| P3-F | (off) | (off) |
| P3-G | (off) | (off) |
| P3-H | (off) | (off) |
| P3-I | (off) | (off) |
| P3-J | (off) | (off) |

---

## Folder layout example

```
doc/data/
  T01/
    report.html
    AEC_P0-B_decisions.csv
    AEC_P0-B_diag_summary.csv
    journal.txt
  T03/
    report.html
    AEC_P0-A_decisions.csv
    AEC_P0-A_diag_summary.csv
    journal.txt
```

When sharing for review: zip **one** `Txx` folder or paste that test’s journal + diag CSV only.

---

## T01 result notes (2026-05-20)

**Verdict:** EDGE-0.1 SELL execution **PASS**.

| Check | Result |
|-------|--------|
| `InpForceTestSignal=true`, direction `-1` | Confirmed in log |
| CSV | 21 rows, all `FORCED_TEST_SIGNAL` · `SELL` · `OK` |
| Report | 21 short trades, PF 1.31 |
| `exec_sell` | 21 |
| `exec_buy` | 0 (expected — force sell only) |

**Signal legs (same run, diag on):** `FULL_SELL=69` but only **21** executed → `InpMaxOpenTrades=1` + positions held ~13h avg → most bars blocked by open position, not sell failure.

**Next:** T03 natural chain (`AEC.P0-A_baseline-diag_EDGE-0-1.set`) — **no** force signal.

---

## T02 result notes (2026-05-20)

**Verdict:** EDGE-0.1 BUY execution **PASS**.

| Check | Result |
|-------|--------|
| Preset | `AEC_P0-C_*` CSVs (correct naming) |
| CSV | 23 rows, all `FORCED_TEST_SIGNAL` · `BUY` · `OK` |
| Report | 23 long trades (PF 0.64 irrelevant for exec proof) |
| `exec_buy` | 23 · `exec_sell` | 0 (expected) |

**T01 + T02 together:** Both directions execute on broker path. **T03** confirms natural `AND_CHAIN_BUY` / `AND_CHAIN_SELL`. **EDGE-0.1 complete.**

---

## T03 result notes (2026-05-20)

**Verdict:** EDGE-0.1 natural signal chain **PASS** · Phase 0 execution diagnostics **complete**.

| Check | Result |
|-------|--------|
| `InpForceTestSignal` | **false** (log confirmed) |
| CSV signals | `AND_CHAIN_BUY` (10) · `AND_CHAIN_SELL` (11) — all `OK` |
| Report | 21 trades · 10 long · 11 short |
| Diag | `full_buy=53` → `exec_buy=10` · `full_sell=69` → `exec_sell=11` |
| PnL | Net -4.90 · PF 0.83 — **not scored** in Phase 0 |

**Why fewer execs than full_* counts:** `InpMaxOpenTrades=1` + ~12h avg hold blocks most new signals (same as T01/T02).

**Old “5354 long / 0 short” mystery:** Not a sell bug. On this May window shorts fire naturally. Full-year skew likely **regime + throttling**, not broken pipeline.

---

## T31 result notes (2026-05-20)

**Verdict:** EDGE-3.11 room-to-run **reject** — stay on **P2-C**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-A_room-to-run_EDGE-3-11.set` |
| Deposit | 200 |
| PF | **0.97** (vs T07 **1.01**) |
| Net | **-75.13** (vs T07 **+43.49**) |
| Trades | 1884 (-296 vs T07) |
| WR | 32.91% (vs ~33.9%) |
| MFE/MAE corr | 0.81 / 0.82 (unchanged — exits not the problem) |

**Read:** Filter removes ~14% of entries but destroys edge; likely blocks continuation breaks that still had room in practice. Do not enable on production.

---

## T10 result notes (2026-05-20)

**Verdict:** EDGE-3.1 exclude hours 13–15 **reject** — stay on **P2-C**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-B_exclude-hours-1315_EDGE-3-1.set` |
| Deposit | 200 |
| PF | **1.00** (vs T07 **1.01**) |
| Net | **-7.70** (vs T07 **+43.49**) |
| Trades | 1844 (-336 vs T07) |
| WR | 33.46% (vs ~33.9%) |

**Next:** Done — see T11.

---

## T11 result notes (2026-05-20)

**Verdict:** EDGE-3.2 BB release ≥1.10 **keep** — production layer (superseded by **P3-F** / T13 for struct; BB 1.10 still in P3-F).

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-C_bb-release-expand110_EDGE-3-2.set` |
| Deposit | 200 |
| PF | **1.03** (vs T07 **1.01**) |
| Net | **+97.80** (vs T07 **+43.49**) |
| Trades | 2133 (-47 vs T07) |
| WR | 34.32% (vs ~33.9%) |
| Max equity DD % | ~50.9% (vs ~69.8%) |

**Next:** T12 done — see below.

---

## T12 result notes (2026-05-20)

**Verdict:** EDGE-3.3 BB release ≥1.12 **reject (marginal)** — **production stays P3-C**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-D_bb-release-expand112_EDGE-3-3.set` |
| Deposit | 200 |
| PF | **1.04** (vs T11 **1.03**) |
| Net | **+100.23** (vs T11 **+97.80**, Δ +2.43) |
| Trades | 2069 (-64 vs T11) |
| WR | 34.36% (vs 34.32%) |
| Max equity DD % | **~56.8%** (vs T11 **~50.9%**) |

**Next:** T32 done — see below.

---

## T32 result notes (2026-05-20)

**Verdict:** EDGE-3.12 BB expansion persistence **reject** — stay **P3-C**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-E_bb-expansion-persist_EDGE-3-12.set` |
| Deposit | 200 |
| PF | **1.02** (vs T11 **1.03**) |
| Net | **+37.07** (vs T11 **+97.80**, Δ −60.73) |
| Trades | 1598 (−535 vs T11) |
| WR | 33.98% (vs 34.32%) |
| Max equity DD % | ~34.1% (vs ~50.9%) |

**Next:** T13 done — production P3-F.

---

## T13 result notes (2026-05-20)

**Verdict:** EDGE-3.4 struct break ≥0.20 ATR **keep** — **production = P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-F_struct-break-atr020_EDGE-3-4.set` |
| Deposit | 200 |
| PF | **1.04** (vs T11 **1.03**) |
| Net | **+103.71** (vs T11 **+97.80**, Δ +5.91) |
| Trades | 2115 (-18 vs T11) |
| WR | 34.37% (vs 34.32%) |
| Max equity DD % | ~52.6% (vs ~50.9%) |

**Next:** T14 done — stay P3-F.

---

## T15 result notes (2026-05-20)

**Verdict:** EDGE-3.6 displacement ≥0.65 ATR **reject** — stay **P3-F** (0.55).

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-G_displacement-atr065_EDGE-3-6.set` |
| Deposit | 200 |
| PF | **1.00** (vs T13 **1.04**) |
| Net | **-2.24** (vs T13 **+103.71**, Δ −105.95) |
| Trades | 2079 (-36 vs T13) |
| WR | 33.53% (vs 34.37%) |
| Max equity DD % | **~74.3%** (vs ~52.6%) |

**Read:** Stronger impulse filter removes winners with losers; net flips negative and DD jumps ~22pp. Do not raise displacement above 0.55.

**Next:** T14 done — struct sweep stops at **0.20** (P3-F).

---

## T14 result notes (2026-05-20)

**Verdict:** EDGE-3.5 struct break ≥0.25 ATR **reject** — stay **P3-F** (0.20).

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-H_struct-break-atr025_EDGE-3-5.set` |
| Deposit | 200 |
| PF | **1.03** (vs T13 **1.04**) |
| Net | **+93.03** (vs T13 **+103.71**, Δ −10.68) |
| Trades | 2100 (-15 vs T13) |
| WR | 34.29% (vs 34.37%) |
| Max equity DD % | ~56.9% (vs ~52.6%) |

**Next:** T16 done — see below.

---

## T16 result notes (2026-05-20)

**Verdict:** EDGE-3.7 min bar range ≥0.30×ATR **reject (no lift)** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-J_min-bar-range-atr030_EDGE-3-7.set` |
| Deposit | 200 |
| PF | **1.04** (vs T13 **1.04**) |
| Net | **+103.01** (vs T13 **+103.71**, Δ −0.70) |
| Trades | 2116 (+1 vs T13) |
| WR | 34.36% (vs 34.37%) |

**Next:** **T42** EDGE-4.4 after T41.

---

## T17 result notes (2026-05-20)

**Verdict:** EDGE-3.8 slow EMA direction **reject (no lift)** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-M_ema-direction_EDGE-3-8.set` |
| Deposit | 200 |
| PF | **1.04** (vs T13 **1.04**) |
| Net | **+103.01** (vs T13 **+103.71**, Δ −0.70) |
| Trades | 2116 (+1 vs T13) |
| WR | 34.36% (vs 34.37%) |
| Max equity DD % | ~52.6% (vs ~52.6%) |

**Note:** Redundant with fast/slow cross on M5 — almost no trades filtered. **`InpUseEmaDirectionFilter=false`** on production.

---

## T37 result notes (2026-05-20)

**Verdict:** EDGE-3.10 hours **8–12** only **reject** — stay **P3-F** (**8–17**).

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-O_hours-8-12_EDGE-3-10.set` |
| Deposit | 200 |
| PF | **1.05** (vs T13 **1.04**) |
| Net | **+84.48** (vs T13 **+103.71**, Δ **−19.23**) |
| Trades | 1185 (−44% vs T13) |
| WR | 34.68% (vs 34.37%) |
| Max equity DD % | ~34.6% (vs ~52.6%) |

**Note:** Lower DD and slightly higher PF, but **net −19** — afternoon volume still carries edge. Morning-only is not a substitute for 3.1 (T10 also rejected). Keep **`InpTradingHourEnd=17`**.

---

## T39 result notes (2026-05-20)

**Verdict:** EDGE-4.1 HTF H1 EMA(50) trend **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P4-A_htf-h1-ema50_EDGE-4-1.set` |
| Deposit | 200 |
| PF | **0.97** (vs T13 **1.04**) |
| Net | **−59.18** (vs T13 **+103.71**, Δ **−162.89**) |
| Trades | 1507 (−29% vs T13) |
| WR | 32.91% (vs 34.37%) |
| Max equity DD % | ~81.0% (vs ~52.6%) |

**Note:** HTF gate removed ~29% of trades and flipped curve negative — counter-trend M5 breaks are part of the edge. **`InpUseHtfTrendFilter=false`** on production.

---

## T41 result notes (2026-05-20)

**Verdict:** EDGE-4.3 ATR percentile band 20–85 **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P4-C_atr-pct-20-85_EDGE-4-3.set` |
| Deposit | 200 |
| PF | **0.99** (vs T13 **1.04**) |
| Net | **−15.74** (vs T13 **+103.71**, Δ **−119.45**) |
| Trades | 1453 (−31% vs T13) |
| WR | 33.45% (vs 34.37%) |
| Max equity DD % | ~50.4% (vs ~52.6%) |

**Note:** Band cut a third of trades and flipped positive baseline negative — rejects good vol regimes. **`InpUseAtrPercentileBand=false`** on production.

**Next:** **T42** EDGE-4.4 prior bar range cap.

---

## T42 result notes (2026-05-20)

**Verdict:** EDGE-4.4 prior bar range cap ≤2×ATR **keep** — **production = P4-D**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P4-D_prior-bar-range-cap-2atr_EDGE-4-4.set` |
| Deposit | 200 |
| PF | **1.07** (vs T13 **1.04**) |
| Net | **+161.20** (vs T13 **+103.71**, Δ **+57.49**) |
| Trades | 1706 (−19% vs T13) |
| WR | 35.17% (vs 34.37%) |
| Max equity DD % | ~40.0% (vs ~52.6%) |

**Note:** First Phase 4 **keep** — filters post-shock bars without killing edge. Net, PF, WR, and DD all improve vs P3-F. **`InpUsePriorBarRangeCap=true`** on production · compile defaults updated.

**Next:** **T43** EDGE-4.5 BB chop skip.

---

## T43 result notes (2026-05-20)

**Verdict:** EDGE-4.5 BB chop skip **keep** — **production = P4-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P4-E_bb-chop-skip_EDGE-4-5.set` |
| Deposit | 200 |
| PF | **1.14** (vs T42 **1.07**) |
| Net | **+241.63** (vs T42 **+161.20**, Δ **+80.43**) |
| Trades | 1305 (−23% vs T42) |
| WR | 36.70% (vs 35.17%) |
| Max equity DD % | ~25.0% (vs ~40.0%) |

**Note:** Second Phase 4 **keep** — filters marginal BB releases in range chop; net, PF, WR, and DD all improve vs P4-D. **`InpUseBbChopSkip=true`** on production · compile defaults updated.

**Next:** **T21** EDGE-5.1 cooldown after loss.

---

## T21 result notes (2026-05-20)

**Verdict:** EDGE-5.1 cooldown after loss 90 min **reject** — stay **P4-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P5-A_cooldown-loss-90min_EDGE-5-1.set` |
| Deposit | 200 |
| PF | **1.09** (vs T43 **1.14**) |
| Net | **+151.62** (vs T43 **+241.63**, Δ **−90.01**) |
| Trades | 1251 (−4% vs T43) |
| WR | 35.65% (vs 36.70%) |
| Max equity DD % | ~33.0% (vs ~25.0%) |

**Note:** 90m pause after losses skips re-entries that were still profitable — same pattern as regime over-filters. **`InpCooldownAfterLossOnly=false`** · **`InpCooldownSecondsAfterTrade=20`** on production.

**Next:** **T22** EDGE-5.2 max trades per day.

---

## T22 result notes (2026-05-20)

**Verdict:** EDGE-5.2 max 5 trades/day **reject (no lift)** — stay **P4-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P5-B_max-trades-per-day-5_EDGE-5-2.set` |
| Deposit | 200 |
| PF | **1.14** (vs T43 **1.14**) |
| Net | **+241.63** (vs T43 **+241.63**, Δ **0**) |
| Trades | **1305** (identical to T43) |
| WR | 36.70% (vs 36.70%) |
| Max equity DD % | ~25.0% (vs ~25.0%) |

**Note:** Cap never binds — P4-E averages **~0.9 opens/day** in the 8–17 window; limit of 5 is far above typical daily volume. **`InpUseMaxTradesPerDay=false`** on production. Re-test only if stack trade rate rises (e.g. shorter cooldown / wider hours).

**Next:** **T23** EDGE-5.3 daily DD 3%.

---

## T23 result notes (2026-05-20)

**Verdict:** EDGE-5.3 daily DD block **3%** **reject (no lift)** — stay **P4-E** (**5%** daily DD).

| Check | Result |
|-------|--------|
| Preset | `AEC.P5-C_daily-dd-3pct_EDGE-5-3.set` |
| Deposit | 200 |
| PF | **1.14** (vs T43 **1.14**) |
| Net | **+241.63** (vs T43 **+241.63**, Δ **0**) |
| Trades | **1305** (identical) |
| WR | 36.70% (vs 36.70%) |
| Max equity DD % | ~25.0% (vs ~25.0%) |

**Note:** Identical to T43 — at deposit 200 with 0.01 lot, intraday equity rarely hits **3%** day DD (same as 5% cap inactive in practice). **`InpMaxDailyDrawdownPercent=5.0`** on production.

**Next:** **T44** EDGE-5.4 hour direction throttle.

---

## T44 result notes (2026-05-20)

**Verdict:** EDGE-5.4 block BUY **[13,15)** **reject** — stay **P4-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P5-D_block-buy-hours-1315_EDGE-5-4.set` |
| Deposit | 200 |
| PF | **1.15** (vs T43 **1.14**, Δ +0.01) |
| Net | **+222.85** (vs T43 **+241.63**, Δ **−18.78**) |
| Trades | **1175** (−130 vs T43, −10%) |
| WR | 36.68% (vs 36.70%) |
| Max equity DD % | ~26.4% (vs ~25.0%) |
| Sharpe | 1.42 |

**Note:** Filter **binds** (130 fewer trades; longs 467 vs ~597 implied). PF ticks up but **net and DD worsen** — blocked overlap BUYs were still net-positive. Not finer than EDGE-3.1 (full hour exclude); wrong direction for production. **`InpUseHourDirectionFilter=false`** on production. Revisit windows after **EDGE-7.1** deal export if data shows a different buy/sell split.

---

## T36 result notes (2026-05-20)

**Verdict:** EDGE-5.5 post-streak gate **keep** — **production = P5-E** (supersedes P4-E / T43).

| Check | Result |
|-------|--------|
| Preset | `AEC.P5-E_post-streak-4loss-45min_EDGE-5-5.set` |
| Deposit | 200 |
| PF | **1.15** (vs T43 **1.14**, Δ +0.01) |
| Net | **+247.68** (vs T43 **+241.63**, Δ **+6.05**) |
| Trades | **1302** (−3 vs T43) |
| WR | 36.79% (vs 36.70%) |
| Max equity DD % | ~23.0% (vs ~25.0%) |
| Sharpe | 1.43 |

**Note:** First Phase 5 **keep** — rare 45 min pauses after 4-loss streaks trim bad clusters without mass trade loss (contrast T21/T44). **`InpUsePostStreakGate=true`** on production · compile defaults updated.

**Next:** **T24** EDGE-6.1 RR 1.5.

---

## T24 result notes (2026-05-20)

**Verdict:** EDGE-6.1 RR **1.5** **reject** — stay **P5-E** (RR **2.0**).

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-A_rr-1_5_EDGE-6-1.set` |
| Deposit | 200 |
| PF | **1.06** (vs T36 **1.15**, Δ −0.09) |
| Net | **+99.51** (vs T36 **+247.68**, Δ **−148.17**) |
| Trades | **1414** (+112 vs T36) |
| WR | **41.65%** (vs 36.79%) |
| Max equity DD % | ~32.2% (vs ~23.0%) |
| Sharpe | 0.78 |

**Note:** Closer TP lifts WR (+5 pp) but cuts avg win (~3.01 vs ~4.01) and lets more marginal entries churn — net **−60%**, DD **+9 pp**. **`InpRiskReward=2.0`** on production.

---

## T27 result notes (2026-05-20)

**Verdict:** EDGE-6.4 dead-trade exit **reject** — stay **P5-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-B_dead-trade-exit_EDGE-6-4.set` |
| Deposit | 200 |
| PF | **1.09** (vs T36 **1.15**, Δ −0.06) |
| Net | **+105.57** (vs T36 **+247.68**, Δ **−142.11**) |
| Trades | **1677** (+375 vs T36) |
| WR | 33.27% (vs 36.79%) |
| Max equity DD % | ~24.2% (vs ~23.0%) |
| Avg hold | ~4:04 (vs ~9:31) |
| Sharpe | 1.13 |

**Note:** Filter **binds** — early exits cut stagnant trades but also scratch many that would have reached TP at 2R; churn +375 trades, avg win ~2.33 vs ~4.01. **`InpUseDeadTradeExit=false`** on production.

---

## T45 result notes (2026-05-20)

**Verdict:** EDGE-6.8 BE at **+0.8R** **reject** — stay **P5-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-C_be-at-0_8r_EDGE-6-8.set` |
| Deposit | 200 |
| PF | **1.03** (vs T36 **1.15**, Δ −0.12) |
| Net | **+42.58** (vs T36 **+247.68**, Δ **−205.10**) |
| Trades | **1481** (+179 vs T36) |
| WR | **42.61%** (vs 36.79%, +5.8 pp) |
| Max equity DD % | ~42.9% (vs ~23.0%) |
| Avg win / loss | ~2.13 / ~−1.53 (vs ~4.01 / ~−2.03) |
| Sharpe | 0.35 |

**Note:** BE at 0.8R lifts WR but caps winners before 2R TP — net **−83%** vs T36, DD nearly **2×**. Same exit-side churn pattern as 6.1/6.4. **`InpUseBreakevenAtR=false`** on production.

---

## T26 result notes (2026-05-20)

**Verdict:** EDGE-6.3 BE at **+1.0R** **reject** — stay **P5-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-D_be-at-1r_EDGE-6-3.set` |
| Deposit | 200 |
| PF | **1.07** (vs T36 **1.15**, Δ −0.08) |
| Net | **+95.90** (vs T36 **+247.68**, Δ **−151.78**) |
| Trades | **1427** (+125 vs T36) |
| WR | **41.49%** (vs 36.79%) |
| Max equity DD % | ~39.4% (vs ~23.0%) |
| Sharpe | 0.73 |

**Note:** Better than T45 (0.8R: net +42.58, PF 1.03, DD ~43%) but still far below T36 — BE at 1R still caps 2R runners and adds BE-stop churn. **`InpUseBreakevenAtR=false`** on production.

---

## T46 result notes (2026-05-20)

**Verdict:** EDGE-6.7 partial **40%** at **+1.2R** **reject (no lift)** — stay **P5-E**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P6-E_partial-40pct-at-1_2r_EDGE-6-7.set` |
| Deposit | 200 |
| PF | **1.15** (vs T36 **1.15**, Δ **0**) |
| Net | **+247.68** (vs T36 **+247.68**, Δ **0**) |
| Trades | **1302** (identical) |
| WR | 36.79% (vs 36.79%) |
| Max equity DD % | ~23.0% (vs ~23.0%) |
| Sharpe | 1.43 |

**Note:** Curve **identical** to T36 — at **0.01** lot, **40%** partial = **0.004** below min step **0.01**; rule never executes (`Partial skip` in journal). **`InpUsePartialCloseAtR=false`** on production. Re-test only with splittable lot (e.g. **0.05+**) if revisiting 6.7.

**Phase 6 exits:** 6.1 / 6.3 / 6.4 / 6.8 **reject** · 6.7 **no lift** → **hold P5-E**.

---

## T40 result notes (2026-05-20)

**Verdict:** EDGE-4.2 ADX(14) ≥ 18 **reject (no lift)** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P4-B_adx-min18_EDGE-4-2.set` |
| Deposit | 200 |
| PF | **1.04** (vs T13 **1.04**) |
| Net | **+101.68** (vs T13 **+103.71**, Δ −2.03) |
| Trades | 1977 (−138 vs T13) |
| WR | 34.40% (vs 34.37%) |
| Max equity DD % | ~42.6% (vs ~52.6%) |

**Note:** DD improves ~10 pp but net flat — not worth a layer. **`InpUseAdxMinFilter=false`** on production.

---

## T38 result notes (2026-05-20)

**Verdict:** EDGE-3.16 adaptive overlap **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-P_adaptive-overlap_EDGE-3-16.set` |
| Deposit | 200 |
| PF | **1.02** (vs T13 **1.04**) |
| Net | **+47.24** (vs T13 **+103.71**, Δ **−56.47**) |
| Trades | 2093 (−22 vs T13) |
| WR | 33.92% (vs 34.37%) |
| Max equity DD % | ~60.2% (vs ~52.6%) |

**Note:** Barely fewer trades but net **−56** — stricter overlap mults cut winners, not just churn (same pattern as 3.1 / global 3.3–3.6). **`InpUseAdaptiveOverlap=false`** on production.

**Next:** **Phase 4** (regime).

---

## T18 result notes (2026-05-20)

**Verdict:** EDGE-3.9 signal spread cap (25 pts) **reject (no lift)** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-N_signal-spread-25_EDGE-3-9.set` |
| Deposit | 200 |
| PF | **1.04** (vs T13 **1.04**) |
| Net | **+105.01** (vs T13 **+103.71**, Δ +1.30) |
| Trades | 2115 (= T13) |
| WR | 34.37% (vs 34.37%) |
| Max equity DD % | ~51.7% (vs ~52.6%) |

**Note:** Same trade count — spread rarely > 25 pts in tester at entry ticks. Marginal net +1.3 not worth a layer. **`InpUseSignalSpreadCap=false`** on production.

---

## T35 result notes (2026-05-20)

**Verdict:** EDGE-3.15 squeeze duration (≥4 bars) **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-L_squeeze-duration-4_EDGE-3-15.set` |
| Deposit | 200 |
| PF | **0.99** (vs T13 **1.04**) |
| Net | **−28.90** (vs T13 **+103.71**, Δ **−132.61**) |
| Trades | 1942 (−173 vs T13) |
| WR | 33.32% (vs 34.37%) |
| Max equity DD % | ~59.3% (vs ~52.6%) |

**Note:** Filter went negative vs baseline; same failure mode as 3.14 / 3.12. **`InpUseBbSqueezeDuration=false`** on production.

---

## T34 result notes (2026-05-20)

**Verdict:** EDGE-3.14 close strength (70% zone) **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-K_close-strength-70pct_EDGE-3-14.set` |
| Deposit | 200 |
| PF | **1.01** (vs T13 **1.04**) |
| Net | **+20.48** (vs T13 **+103.71**, Δ **−83.23**) |
| Trades | 1939 (−176 vs T13) |
| WR | 33.73% (vs 34.37%) |
| Max equity DD % | ~61.9% (vs ~52.6%) |

**Note:** Filter removed ~8% of trades but destroyed most edge — same pattern as 3.11 / 3.13 (quality filter cuts winners with losers). **`InpUseCloseStrength=false`** on production.

---


## T33 result notes (2026-05-20)

**Verdict:** EDGE-3.13 EMA overextension cap **reject** — stay **P3-F**.

| Check | Result |
|-------|--------|
| Preset | `AEC.P3-I_ema-overext-cap_EDGE-3-13.set` |
| Deposit | 200 |
| PF | **1.05** (vs T13 **1.04**) |
| Net | **+60.62** (vs T13 **+103.71**, Δ −43.09) |
| Trades | 892 (−58% vs T13) |
| WR | 34.64% (vs 34.37%) |
| Max equity DD % | ~27.1% (vs ~52.6%) |

**Read:** Lower DD is attractive but net edge is the goal at deposit 200 — cap removes too many valid continuation entries. Do not enable on production.

---

## T09 result notes (2026-05-20)

**Verdict:** EDGE-2.5 session overlap **reject** — **Phase 2 filter sweep complete.**

| Check | Result |
|-------|--------|
| Deposit | 200 |
| PF | 0.94 (vs T07 1.01) |
| Net | -106.48 (vs T07 +43.49) |
| Trades | 1402 (-36% vs T07) |

**Production preset:** `AEC.P5-E_post-streak-4loss-45min_EDGE-5-5.set` (see T36; baselines P4-E / T43 · P4-D / T42 · P3-F / T13).

---

## T08 result notes (2026-05-20)

**Verdict:** EDGE-2.4 volume tier 1.15+ **reject** — stay on **P2-C** (mult 1.05).

| Check | Result |
|-------|--------|
| Deposit | 200 |
| PF | 1.00 (vs T07 1.01) |
| Net | -5.30 (vs T07 +43.49) |
| Trades | 1953 (vs 2180, -10%) |
| Win rate | 33.54% — flat vs T07 |

Cutting low-volume bars removed net edge. Production stack unchanged: **T07 / P2-C**.

---

## T07 result notes (2026-05-20)

**Verdict:** EDGE-2.3 BB release quality **keep** · Phase 2 stack = **P2-C** · first profitable full-range run.

| Check | Result |
|-------|--------|
| Deposit | 200 |
| PF | **1.01** (vs T06 0.99) |
| Net | **+43.49** (vs T06 -45.05) |
| Trades | 2180 (vs 2323, -6%) |
| Win rate | 33.90% (739 / 2180) |
| Max DD | 69.76% equity |
| Direction | 1071 long / 1109 short |

BB expand filter removed weak squeezes without crushing frequency. Stack: hours 8–17 + struct 0.15 ATR + BB w1/w2≥1.08.

---

## T06 result notes (2026-05-20)

**Verdict:** EDGE-2.2 min structure break distance **keep** · Phase 2 stack = P2-B.

| Check | Result |
|-------|--------|
| Deposit | **200** (realistic; not comparable to T05 DD%) |
| PF | **0.99** (vs T05 0.96 — **0.98 target met**) |
| Trades | 2323 (vs 2395, -3%) |
| Win rate | 33.23% (772 / 2323) — near breakeven ~33.5% |
| Direction | 1157 long / 1166 short — balanced |
| Avg win / loss | 4.01 / 2.02 — unchanged R:R |

Weak tick-over breaks filtered without killing frequency. Next filter: BB release quality (EDGE-2.3).

**Verdict:** EDGE-2.1 hours gate **keep** as Phase 2 base layer.

| Metric | T04 baseline | T05 (hours 8–17) |
|--------|--------------|------------------|
| Net profit | -322.19 | -121.70 |
| Profit factor | 0.93 | 0.96 |
| Trades | 3418 | 2395 |
| Max DD % | 16.9 | 9.7 |
| Win rate | ~32% | 32.7% |

PF target 0.98 missed by 0.02; loss reduction and DD improvement justify keeping the filter. Entry quality (EDGE-2.2+) is the next lever.

