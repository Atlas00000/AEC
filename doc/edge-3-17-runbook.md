# EDGE-3.17 — Stricter BB entry on P5-F (Phase 9)

**Hypothesis (EDGE-7.2):** BB is the scarcest signal leg — tighten release quality to cut weak / never-green entries.

**No new code** — existing `BBSqueeze.mqh` inputs.

Two **one-knob** presets on **P5-F** (run separately):

---

## 3.17a — Release expand **1.12** (run first · **T65**)

| Input | P5-F | P9-E |
|-------|------|------|
| `InpMinBbReleaseExpandRatio` | 1.10 | **1.12** |
| `InpUseBbSqueezeDuration` | false | false |

**Preset:** `AEC.P9-E_bb-release-112_EDGE-3-17.set`

**Prior art:** EDGE-3.3 **T12** on P3-C — marginal reject (+100 net, DD ~57%). Re-check on **locked P5-F**.

---

## 3.17b — Squeeze duration **4** bars (optional · **T66**)

| Input | P5-F | P9-F |
|-------|------|------|
| `InpUseBbSqueezeDuration` | false | **true** |
| `InpBbMinSqueezeBars` | 4 | **4** |
| `InpMinBbReleaseExpandRatio` | 1.10 | 1.10 |

**Preset:** `AEC.P9-F_squeeze-duration-4_EDGE-3-17b.set`

**Prior art:** EDGE-3.15 **T35** on P3-F — **reject** (net −28.90). Only run if **3.17a** fails and you still want duration on P5-F.

**Do not** enable both 1.12 **and** duration in one test without a single-var pass.

---

## Result (2026-05-21) — **reject**

| Metric | T48 | T65 P9-E |
|--------|-----|----------|
| Net | +271.30 | **−16.47** |
| PF | 1.17 | 0.99 |
| Trades | 1244 | 1574 |
| Equity DD | ~24% | ~37% |

**T66 (duration)** skipped — 3.15 already failed. **P5-F** unchanged.

---

## Run (T65)

1. **F7** compile `AEC.mq5`.
2. Load **`AEC.P9-E_bb-release-112_EDGE-3-17.set`**.
3. **EURUSD M5** · **2020.01.01 – 2026.05.19** · deposit **200** · lot **0.01**.
4. Compare to **T48**.

**Outputs:** `AEC_P9-E_deals.csv` · `AEC_P9-E_segments.csv`

---

## Success bar vs T48

| Metric | Target |
|--------|--------|
| Net | **Higher** than +271.30 |
| PF | **≥ 1.17** |
| Trades | Fewer OK if net up |
| WR | Up or flat |
| Equity DD | **Not worse** than ~24% |

**Reject** if net down · PF &lt; 1.17 · DD materially worse.

---

## If keep

Holdout **2024–2026** with same preset (**T67** vs T51).

---

## Phase 9 context

All **exit** tweaks (5.7, 6.9–6.11) **rejected**. 3.17 is **entry-only** — should not add trade churn like 6.9.
