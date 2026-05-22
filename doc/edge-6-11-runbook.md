# EDGE-6.11 — Soft never-green time stop (Phase 9)

**Hypothesis (EDGE-7.3):** **45.8%** of losers are `loser_never_green` (**mfe_r &lt; 0.2**). Exit stagnant trades earlier than full SL bleed — **without** touching trades that went green (unlike 6.9).

**vs EDGE-6.4 (reject):** 6.4 used **+0.3R** in **5** bars → heavy churn. 6.11 is **softer**: **+0.2R** threshold (matches taxonomy) and **12** bars (~1h M5).

| Input | Value |
|-------|--------|
| `InpUseSoftNeverGreenExit` | **true** |
| `InpSoftNeverGreenMinR` | **0.2** |
| `InpSoftNeverGreenMaxBars` | **12** |

**Unchanged:** full **P5-F** · **0.01** lot · SL 200 / TP 400.

**Code:** `Execution/NeverGreenSoftExit.mqh`

---

## Result (2026-05-21) — **reject**

| Metric | T48 | T64 P9-D |
|--------|-----|----------|
| Net | +271.30 | **−12.53** |
| PF | 1.17 | 0.99 |
| Trades | 1244 | 1632 |
| Equity DD | ~24% | ~38% |

**No holdout.** Production **P5-F**.

---

## Run (T64)

1. **F7** compile `AEC.mq5`.
2. Load **`AEC.P9-D_soft-never-green_EDGE-6-11.set`**.
3. **EURUSD M5** · **2020.01.01 – 2026.05.19** · deposit **200**.
4. Compare to **T48** · journal: `Soft never-green exit`.

**Outputs:** `AEC_P9-D_deals.csv` · `AEC_P9-D_segments.csv`

---

## Success bar vs T48

| Metric | Target |
|--------|--------|
| Net | **Higher** than +271.30 |
| PF | **≥ 1.17** |
| Trades | Not **+300** churn (reject if ~1.5k+ like 6.9) |
| WR | Up or flat |
| Equity DD | **≤ ~24%** (not worse) |

**Reject** if PF &lt; 1.17 · net down · DD ~30%+ · trade count spike with PF 1.02.

---

## If keep

Holdout **2024–2026** (**T65** vs T51).

---

## Tuning (one at a time)

| Param | Try |
|-------|-----|
| `InpSoftNeverGreenMaxBars` | **18** / **24** if 12 too aggressive |
| `InpSoftNeverGreenMinR` | **0.15** only if 0.2 too strict |

Do not combine with 6.4 · 6.9 · 6.10.
