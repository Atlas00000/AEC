# Phase 1 analysis — full-range baseline

**Test:** EURUSD M5 · **2020.01.01 → 2026.05.19** · natural chain (`InpForceTestSignal=false`) · LTF defaults · deposit **2000** · fixed lot **0.01**.

**Source:** Strategy Tester report (T04 / full-range RAW run). Visual segmentation from report charts; precise PF-by-bucket needs exported deal history (optional refinement).

---

## Baseline snapshot

| Metric | Value |
|--------|--------|
| Total trades | **3,418** |
| Long / short | **1,739 / 1,679** (balanced — no pipeline bias) |
| Net profit | **-322.19** |
| Profit factor | **0.93** |
| Win rate | **~32%** |
| Avg win / avg loss | **4.02 / 2.03** (~**1.98R** realized) |
| Max equity DD | **~16.9%** |
| Expected payoff | **-0.09** / trade |
| Avg hold | **~9h 11m** |
| Corr (profit, MFE) | **0.82** |
| Corr (profit, MAE) | **0.83** |

**Breakeven win rate** at this payoff ratio:  
`2.03 / (4.02 + 2.03) ≈ 33.5%` → actual **~32%** → slightly underwater. Confirms PF 0.93.

---

## EDGE-1.1 — Hour filter hypothesis

**Report pattern (entries by hour):**

- **Low activity:** hours **0–7** (Asia / overnight).
- **Rising:** **8–12** (European).
- **Peak entries:** **13–15** (London/NY overlap).
- **Profits vs losses by hour:** red (loss) bars remain large in **13–15**, not only green.

**Conclusion:** **Do not** start by *keeping only* 12–17. Peak hours = most trades **and** heavy loss participation → likely **churn**, not edge.

**Recommendation:**

| Action | Rationale |
|--------|-----------|
| **Drop 0–7** (first test) | Low vol / spread noise; few entries but poor signal quality typical on M5 |
| **Keep 8–17** as first Phase 2 window | Cuts Asia; retains European + US |
| **Optional follow-up:** test **excluding 13–15** if 8–17 backtest still weak | Report suggests overlap is loss-heavy |

**Decision:** `keep_overlap` = **No** for 12–17 only · **Yes** to **exclude Asia (0–7)** via **8–17** gate first.

---

## EDGE-1.2 — Weekday hypothesis

**Report pattern:**

- Activity spread **Mon–Fri**; **Tue–Thu** highest; **Sun** minimal.
- Cannot rank PF by weekday from report graphics alone.

**Recommendation:**

- **Keep Mon–Fri** for Phase 2 (no weekday filter yet).
- After **EDGE-2.1** retest, export deals and check if **Friday** underperforms (gap risk) before excluding.

**Decision:** **Inconclusive on PF** · defer weekday filter until post–hours-gate backtest.

---

## EDGE-1.3 — Payoff vs hit rate

| Path | Assessment |
|------|------------|
| **Raise win rate** (tighter entries) | **Primary.** ~32% vs ~33.5% breakeven — small gap; quality filters may flip PF |
| **Widen TP / RR** | Secondary. Avg win already ~2× loss; MFE corr **0.82** suggests some extension possible but not the main lever |
| **Tighten SL** | Risky at 32% WR — would need even higher WR |

**Decision:** **Tighten entries first** (hours gate → volume tier → structure/BB quality), not RR overhaul.

---

## EDGE-1.4 — MFE / MAE review

1. **MFE 0.82** — When price moves favorably, exits often capture meaningful portion → **TP/SL plumbing OK**.
2. **MAE 0.83** — Adverse excursion correlates with outcomes → many losers go wrong quickly; **entry selectivity** matters more than exit tuning.
3. **Max loss streak 19** (~-$38) — Loose chain + high frequency → **filters should cut count** toward 500–1.5k target range.

---

## EDGE-1.5 — Primary segment (encode first in Phase 2)

```
Symbol:     EURUSD
Timeframe:  M5
Date range: 2020.01.01 – 2026.05.19 (same for all EDGE-2 retests)
Hours:      8 – 17 broker time (exclude 0–7 Asia)
Direction:  Both
Notes:      First filter only; do not combine with volume/structure until EDGE-2.1 measured alone
```

**Next implementation ID:** **EDGE-2.1** (trading hours gate).

**Success criteria for EDGE-2.1 vs this baseline:**

| Metric | Baseline | Target after 2.1 |
|--------|----------|------------------|
| PF | 0.93 | **> 0.98** (step toward 1.0+; not full edge yet) |
| Trades | 3,418 | **Lower** (Asia removed) |
| Max DD % | ~16.9% | **Not worse** |

---

## Phase 1 task status

| ID | Status | Summary |
|----|--------|---------|
| EDGE-1.1 | **done** | Exclude Asia first; do not use 12–17-only |
| EDGE-1.2 | **done** | Defer weekday filter |
| EDGE-1.3 | **done** | Tighten entries > widen TP |
| EDGE-1.4 | **done** | MFE/MAE → entry quality focus |
| EDGE-1.5 | **done** | Segment = **8–17 broker** |

---

## Optional (sharpens Phase 1 later)

Export tester **Report HTML** or deal list → `doc/data/T04/` → rebuild PF by hour/weekday in Excel for numeric buckets (EDGE-0.3 spreadsheet).

Not blocking Phase 2.

---

## T05 result (EDGE-2.1, 2026-05-20)

Hours gate **8–17** vs T04 full-range baseline:

| Metric | T04 | T05 | Verdict |
|--------|-----|-----|---------|
| PF | 0.93 | 0.96 | Improved; target 0.98 missed by 0.02 |
| Trades | 3418 | 2395 | -30% |
| Max DD | 16.9% | 9.7% | Much lower |
| Net | -322.19 | -121.70 | +200.49 |

**Decision:** Keep hours filter as Phase 2 stack base. Struct break 0.15 ATR (T06) also **keep** — PF 0.99 at deposit 200.

---

## T06 result (EDGE-2.2, 2026-05-20)

Stack: hours 8–17 + min struct break 0.15 ATR · **deposit 200**.

| Metric | T05 (hours only) | T06 (+ struct) | Verdict |
|--------|------------------|----------------|---------|
| PF | 0.96 | **0.99** | **≥0.98 target met** |
| Trades | 2395 | 2323 | -3% |
| Win rate | 32.7% | **33.2%** | Toward breakeven |
| Net | -121.70 @ 2k | -45.05 @ 200 | Different deposits |

**Decision:** Keep both filters. Phase 2 stack baseline = **T06**.

---

## T07 result (EDGE-2.3, 2026-05-20)

Stack: hours + struct 0.15 ATR + BB release w1/w2≥1.08 · deposit 200.

| Metric | T06 | T07 | Verdict |
|--------|-----|-----|---------|
| PF | 0.99 | **1.01** | **Profitable** |
| Net | -45.05 | **+43.49** | Flipped positive |
| Trades | 2323 | 2180 | -6% |
| Win rate | 33.2% | **33.9%** | Improved |

**Decision:** Keep all three filters. Stack baseline = **T07 (P2-C)**.

---

## T08 result (EDGE-2.4, 2026-05-20)

Volume mult 1.15 on T07 stack · deposit 200.

| Metric | T07 | T08 | Verdict |
|--------|-----|-----|---------|
| PF | 1.01 | 1.00 | Worse |
| Net | +43.49 | -5.30 | **Reject filter** |
| Trades | 2180 | 1953 | -10% |

**Decision:** Do **not** raise volume tier. Production stack stays **P2-C** (`InpVolumeMultiplier=1.05`).

---

## T09 result (EDGE-2.5, 2026-05-20)

Session Asian breakout [0,8) on T07 stack · deposit 200.

| Metric | T07 | T09 | Verdict |
|--------|-----|-----|---------|
| PF | 1.01 | 0.94 | **Reject** |
| Net | +43.49 | -106.48 | **Reject** |
| Trades | 2180 | 1402 | -36% |

**Decision:** Session leg **off** in production. **Phase 2 complete** — use **P2-C** only.
