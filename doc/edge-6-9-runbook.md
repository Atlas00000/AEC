# EDGE-6.9 — Give-back cap (Phase 9)

**Hypothesis (EDGE-7.3):** ~**16.8%** of losers are `loser_fought_mfe05` (went **≥0.5R** then gave back to SL). Cut those stalls without touching never-green losers.

**Logic:** After price first reaches **+0.5R**, if position is still open **24 M5 bars** later (no TP at 2R), **close at market**.

| Input | Value |
|-------|--------|
| `InpUseGiveBackCap` | **true** |
| `InpGiveBackMinR` | **0.5** |
| `InpGiveBackMaxBarsAfterMfe` | **24** (~2h on M5) |

**Unchanged:** full **P5-F** entry stack (BUY block **[14,15)**, post-streak, SL 200 / TP 400).

**Code:** `Execution/GiveBackExit.mqh` · timer starts on **first** +minR touch (not from entry).

**vs EDGE-6.4:** 6.4 closes trades that **never** reach +0.3R in 5 bars; 6.9 targets trades that **did** go green.

---

## Result (2026-05-21) — **reject**

| Metric | T48 | T61 P9-B |
|--------|-----|----------|
| Net | +271.30 | **+33.49** |
| PF | 1.17 | 1.02 |
| Trades | 1244 | 1532 |
| WR | 37.14% | 48.43% |
| Equity DD | ~24% | ~28% |

Early market exits after +0.5R **cut 2R winners** — same churn pattern as **EDGE-6.4**. **No holdout.** Stay **P5-F**.

---

## Run (T61)

1. **F7** compile `AEC.mq5`.
2. Load **`AEC.P9-B_give-back-cap_EDGE-6-9.set`**.
3. **EURUSD M5** · **2020.01.01 – 2026.05.19** · deposit **200** · lot **0.01**.
4. Compare to **T48** (P5-F).

**Outputs:** `AEC_P9-B_deals.csv` · `AEC_P9-B_segments.csv`

Optional post-run: `python scripts/p7d_mae_mfe_postprocess.py` on deals CSV (no rerun).

---

## Success bar vs T48 (P5-F)

| Metric | Target |
|--------|--------|
| Net profit | **Higher** than +271.30 |
| Profit factor | **≥ 1.17** |
| WR | **Up** or flat |
| Trades | Fewer OK if net improves |
| Equity DD | **Not worse** than ~24% |

**Reject** if net down, PF &lt; 1.17, or DD materially worse (same bar as Phase 6 exits).

---

## If full-range **keep**

1. Rerun **holdout** **2024.01.01 – 2026.05.19** with same preset (**T62** vs **T51**).
2. Update [edge-8-3-production-lock.md](./edge-8-3-production-lock.md) only if **both** pass.

---

## Tuning (later, one at a time)

| Param | Try |
|-------|-----|
| `InpGiveBackMaxBarsAfterMfe` | **12** / **36** if 24 is too tight or loose |
| `InpGiveBackMinR` | **0.6** if too many early scratches |

Do not combine with 6.4 dead-trade or 6.8 BE in one test.
