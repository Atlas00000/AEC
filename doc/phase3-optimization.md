# Phase 3–9 optimization — rationale

**Baseline for all tests:** `AEC.P3-F_struct-break-atr020_EDGE-3-4.set` (T13) unless noted. *(Legacy: P3-C / T11, P2-C / T07.)*

**Deposit:** 200 · EURUSD M5 · 2020.01.01–2026.05.19 · fixed lot 0.01.

**Task IDs:** Full table in [edge-discovery.md](./edge-discovery.md).

---

## Problem statement

- PF ~**1.01**, WR ~**34%**, breakeven WR ~**33.5%** at ~2:1 avg win/loss.
- Strategy has **enough good trades**; **volume of losers** (~66%) keeps edge thin.
- MFE correlation ~**0.82** → exits/TP generally work when trade is right.
- MAE correlation ~**0.83** → losers often go wrong early → **entries + regime** first.

---

## Phase 3 — Entry & time

| ID | Change | Hypothesis |
|----|--------|------------|
| EDGE-3.1 | Block entries broker hours **13–15** | Overlap noisy in T04 but T10 **reject** — net -7.70 vs P2-C +43.49 |
| EDGE-3.2 | BB expand **1.10** | **T11 keep** — PF 1.03 · net +97.80 · production P3-C |
| EDGE-3.3 | BB expand **1.12** | **T12 reject** — net +2 vs P3-C but DD ~57% vs ~51%; stop at 1.10 |
| EDGE-3.4–3.5 | Struct **0.20** / **0.25** ATR | **T13 keep** P3-F · **T14 reject** 0.25 — stop at 0.20 |
| EDGE-3.6 | Displacement **0.65** ATR body | **T15 reject** — net -2.24 vs P3-F +103.71 · DD ~74% |
| EDGE-3.7 | Min bar range ≥ **0.30× ATR** (bar 1 H-L) | **T16 reject** — net +103 vs +104 · 2116 trades · redundant with disp 0.55 |
| EDGE-3.8 | EMA gate | Block breaks against slow trend |
| EDGE-3.9 | Spread on signal bar | Skip poor execution conditions |
| EDGE-3.10 | 8–12 only | Compare to 3.1 if overlap split unclear |

### Extensions (from [addtions.md](./addtions.md))

| ID | Change | Hypothesis |
|----|--------|------------|
| **EDGE-3.11** | Room-to-run ≥ 0.5× ATR to opposing swing | Break into nearby S/R fails fast |
| **EDGE-3.12** | BB width rising 2 closed bars | **T32 reject** — net +37 vs P3-C +98; lower DD not worth edge loss |
| **EDGE-3.13** | Max **1.2× ATR** from fast EMA | **T33 reject** — PF 1.05 but net +61 vs P3-F +104 · −58% trades |
| **EDGE-3.14** | Close in top/bottom 70% of bar | Wick-heavy weak commitment |
| **EDGE-3.15** | Squeeze ≥ 4 bars before release | Random micro-compressions |
| **EDGE-3.16** | Stricter mults in 13–15 only | Alternative to blind 3.1 cut |

---

## Phase 4 — Regime

| ID | Change | Hypothesis |
|----|--------|------------|
| EDGE-4.1 | H1 EMA direction | M5 break with HTF trend |
| EDGE-4.2 | ADX minimum | Skip flat chop |
| EDGE-4.3 | ATR percentile band | Skip dead and news-spike bars |
| EDGE-4.4 | Prior bar range cap ≤ **2× ATR** | **T42 keep** — PF 1.07 · net +161 · **production P4-D** |
| EDGE-4.5 | BB width ≥ avg × **1.0** on bar 1 | **T43 keep** — PF 1.14 · net +242 · **production P4-E** |

---

## Phase 5 — Failure containment

| ID | Change | Hypothesis |
|----|--------|------------|
| EDGE-5.1 | Cooldown after loss **90 min** (loss-only) | **T21 reject** — net +152 vs P4-E +242 |
| EDGE-5.2 | Max **5** trades/day | **T22 reject** (no lift) — cap never binds · ≈T43 |
| EDGE-5.3 | Daily DD block **3%** (was 5%) | **T23 reject** (no lift) — ≈T43 |
| EDGE-5.4 | Block BUY **[13,15)** (first throttle) | **T44 ready** — refine after 7.1 |
| **EDGE-5.5** | Pause **45 min** after **4** consecutive losses | **T36 ready** |

---

## Phase 6 — Exits

| ID | Change | Hypothesis |
|----|--------|------------|
| EDGE-6.1 | RR 1.5 | **T24 reject** — stay RR 2.0 |
| EDGE-6.2 | RR 2.5 | **T25 reject** — stay RR 2.0 |
| EDGE-6.3 | BE at 1R | **T26 reject** — stay P5-E |
| **EDGE-6.4** | Dead-trade exit (+0.3R in 5 bars) | **T27 reject** — stay P5-E |
| EDGE-6.5 | SL 150 pts | **T28 reject** — stay SL 200 |
| EDGE-6.6 | ATR trail | Low priority |
| **EDGE-6.7** | Partial **40%** at **1.2R** | **T46 reject** (no lift @ 0.01 lot) |
| **EDGE-6.8** | BE at 0.8R | **T45 reject** — stay P5-E |

Test **one** EDGE-6.x at a time after entry stack stabilizes.

---

## Phase 7 — Data

| ID | Deliverable |
|----|-------------|
| EDGE-7.1 | Spreadsheet: PF/net by hour, weekday, month |
| EDGE-7.2 | Diag CSV: leg pass rates vs executions |
| EDGE-7.3 | MAE/MFE loser taxonomy |

---

## Phase 8–10 (see [edge-discovery.md](./edge-discovery.md))

- **8:** OOS / walk-forward on **P5-F** (next).
- **9:** Bucket-driven improvements (5.7, 6.9, …) **after 8.1**.
- **10:** Forward/live (deferred).

---

## Success criteria (vs P2-C)

| Metric | P2-C (T07) | Target |
|--------|------------|--------|
| PF | 1.01 | **> 1.05–1.10** |
| Win rate | 33.9% | **> 36%** |
| Trades | 2180 | **1,200–1,800** (quality over count) |
| Net @ dep 200 | +43.49 | Higher with stable PF |
