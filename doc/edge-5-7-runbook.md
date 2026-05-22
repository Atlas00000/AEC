# EDGE-5.7 — Block broker hour 16 (all directions)

**Hypothesis (EDGE-7.4):** Hour **16** is the only 8–17 window with **net &lt; 0** and highest never-green % among active hours.

**Implementation:** Existing **EDGE-3.1** hour exclusion — no new code.

| Input | Value |
|-------|--------|
| `InpUseHourExclusion` | **true** |
| `InpExcludeHourStart` | **16** |
| `InpExcludeHourEnd` | **17** (exclusive → blocks hour **16** only) |

**Unchanged from P5-F:** BUY block **[14,15)** · post-streak · full signal stack.

---

## Run (T59)

1. **F7** compile `AEC.mq5`.
2. Load **`AEC.P9-A_block-hour-16_EDGE-5-7.set`**.
3. **EURUSD M5** · **2020.01.01 – 2026.05.19** · deposit **200**.
4. Compare to **T48** (P5-F).

**Outputs:** `AEC_P9-A_deals.csv` · `AEC_P9-A_segments.csv`

---

## Result (2026-05-21) — **keep (marginal)**

| Metric | T48 | T59 P9-A |
|--------|-----|----------|
| Net | +271.30 | **+272.12** |
| PF | 1.17 | 1.17 |
| Trades | 1244 | 1226 |
| WR | 37.14% | 37.19% |

## Holdout (T60) — **reject**

| Metric | T51 P5-F | T60 P9-A |
|--------|----------|----------|
| Net | +93.57 | **+87.56** (−6.01) |
| PF | 1.18 | 1.17 |
| Trades | 419 | 410 |

**Production:** stay on **P5-F** · EDGE-5.7 **closed**.

---

## Success bar vs T48 (P5-F)

| Metric | Target |
|--------|--------|
| Net profit | **Higher** than +271.30 |
| Profit factor | **≥ 1.17** |
| Trades | ~**1199** (−45 vs 1244 if h16 fully removed) |
| WR | **Up** or flat |
| Equity DD | **Not worse** than ~24% |

**Reject** if net down or PF &lt; 1.17.

---

## After full-range pass

1. **EDGE-8.1 holdout** again on P9-A — **T60 done: reject** (net −6 vs T51).
2. Production lock **unchanged** ([edge-8-3-production-lock.md](./edge-8-3-production-lock.md)).

---

## vs EDGE-3.1

| | EDGE-3.1 (reject) | EDGE-5.7 |
|--|-------------------|------------|
| Window | **[13,15)** all dirs | **[16,17)** only |
| On top of | P2-C | **P5-F** |
| Result | Net −7.70 | **T59 keep** (+0.82 vs T48) |

Do **not** combine [13,15) exclude with 5.7 — 3.1 already rejected.
