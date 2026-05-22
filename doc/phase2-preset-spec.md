# Phase 2 preset — EDGE-2.1 hours gate (8–17)

**Status:** Implemented in code. Preset ready for T05 backtest.

| Input | Value |
|-------|--------|
| `InpUseTradingHours` | true |
| `InpTradingHourStart` | 8 |
| `InpTradingHourEnd` | 17 |
| All other | Same as `AEC.RAW_baseline_LTF.set` |

**Behavior:** On each new bar, entries are blocked unless the **closed signal bar** (shift 1) broker hour is in `[8, 17)`. Open positions are not force-closed at hour end.

**Compare to baseline:** [phase1-analysis.md](./phase1-analysis.md) full-range PF 0.93 · 3418 trades.

**Preset file:** `presets/tester/AEC.P2-A_hours-8-17_EDGE-2-1.set`

**Test ID:** T05 · archive to `doc/data/T05/`

**Success criteria vs baseline:** PF > 0.98 · fewer trades · max DD not worse.

## T05 result (2026-05-20)

| Metric | T04 baseline | T05 (hours 8–17) | Δ |
|--------|--------------|------------------|---|
| Net profit | -322.19 | -121.70 | +200.49 |
| Profit factor | 0.93 | 0.96 | +0.03 |
| Trades | 3418 | 2395 | -1023 (-30%) |
| Max DD % | 16.9 | 9.7 | -7.2 pp |
| Win rate | ~32% | 32.7% | ~flat |
| Avg win / loss | 4.02 / 2.03 | 4.01 / 2.02 | ~flat |

**Verdict:** Meaningful improvement; PF target 0.98 missed by 0.02. **Keep** hours gate as Phase 2 base layer. Hours chart confirms no entries 0–7.

---

## EDGE-2.2 — min structure break distance

**Status:** Implemented. Preset ready for T06.

| Input | Value |
|-------|--------|
| `InpUseTradingHours` | true (8–17, same as P2-A) |
| `InpUseMinStructBreakDist` | true |
| `InpMinStructBreakAtrMult` | **0.15** |
| All other | Same as `AEC.P2-A_hours-8-17_EDGE-2-1.set` |

**Behavior:** After a swing high/low break on bar 1, close must penetrate the swing level by at least **0.15 × ATR(14)** on that bar. Filters tick-over / weak breaks.

**Compare to:** T05 stack (PF 0.96 · 2395 trades · DD 9.7%).

**Preset file:** `presets/tester/AEC.P2-B_struct-break-atr015_EDGE-2-2.set`

**Test ID:** T06 · archive to `doc/data/T06/`

**Success criteria vs T05:** PF ≥ 0.98 · win rate up or trades down · max DD not worse.

## T06 result (2026-05-20)

**Deposit:** **200** (user’s realistic account; T04/T05 used 2000 — PF/trades/WR still comparable).

| Metric | T05 (dep 2000) | T06 (dep 200) | Δ |
|--------|----------------|---------------|---|
| Net profit | -121.70 | -45.05 | — (deposit differs) |
| Profit factor | 0.96 | **0.99** | +0.03 |
| Trades | 2395 | 2323 | -72 (-3%) |
| Max DD % | 9.7 | 74.7 | *not comparable* |
| Win rate | 32.7% | **33.2%** | +0.5 pp |
| Avg win / loss | 4.01 / 2.02 | 4.01 / 2.02 | ~flat |
| Long / short | — | 1157 / 1166 | balanced |

**Verdict:** PF **0.99** crosses 0.98 target; win rate nudges toward breakeven (~33.5%). **Keep** struct break filter. Stack baseline moves to **T06** (hours + 0.15 ATR).

---

## EDGE-2.3 — min BB release quality

**Status:** Implemented. Preset ready for T07.

| Input | Value |
|-------|--------|
| Stack | Same as P2-B (hours 8–17 + struct break 0.15 ATR) |
| `InpUseMinBbReleaseQuality` | true |
| `InpMinBbReleaseExpandRatio` | **1.08** (release bar width ≥ 8% above squeeze bar) |
| Deposit | **200** |

**Behavior:** After squeeze plate + `w1 > w2`, require `w1 >= w2 × 1.08`. Filters feeble band pops that barely expand.

**Compare to:** T06 stack (PF 0.99 · 2323 trades · WR 33.2% · deposit 200).

**Preset file:** `presets/tester/AEC.P2-C_bb-release-expand108_EDGE-2-3.set`

**Test ID:** T07 · archive to `doc/data/T07/`

**Success criteria vs T06:** PF ≥ 1.0 · win rate up · trades down acceptable · net profit improved.

## T07 result (2026-05-20)

| Metric | T06 stack | T07 (+ BB quality) | Δ |
|--------|-----------|---------------------|---|
| Net profit | -45.05 | **+43.49** | +88.54 |
| Profit factor | 0.99 | **1.01** | +0.02 — **profitable** |
| Trades | 2323 | 2180 | -143 (-6%) |
| Max DD % | 74.7 | 69.8 | -4.9 pp |
| Win rate | 33.2% | **33.9%** | +0.7 pp |
| Avg win / loss | 4.01 / 2.02 | 4.01 / 2.03 | ~flat |
| Long / short | 1157 / 1166 | 1071 / 1109 | balanced |

**Verdict:** First filter stack to flip **net positive** on full range at deposit 200. **Keep** BB release quality. Phase 2 stack baseline = **T07** (P2-C).

---

## EDGE-2.4 — volume tier 1.15+

**Status:** Preset ready for T08. **No code change** — existing volume leg uses `InpVolumeMultiplier`.

| Input | Value |
|-------|--------|
| Stack | Same as P2-C (T07 filters) |
| `InpVolumeMultiplier` | **1.15** (was 1.05 in P2-C / data-collection default) |
| Deposit | **200** |

**Behavior:** Tick volume on bar 1 must be ≥ **1.15 ×** volume MA(14). Filters low-participation releases.

**Compare to:** T07 stack (PF 1.01 · 2180 trades · net +43.49 · WR 33.9%).

**Preset file:** `presets/tester/AEC.P2-D_volume-tier115_EDGE-2-4.set`

**Test ID:** T08 · archive to `doc/data/T08/`

**Success criteria vs T07:** PF ≥ 1.01 · win rate up · net profit up · trade count toward 500–1.5k target acceptable.

## T08 result (2026-05-20)

| Metric | T07 stack | T08 (+ vol 1.15) | Δ |
|--------|-----------|-------------------|---|
| Net profit | +43.49 | **-5.30** | -48.79 |
| Profit factor | 1.01 | **1.00** | -0.01 |
| Trades | 2180 | 1953 | -227 (-10%) |
| Max DD % | 69.8 | 73.9 | +4.1 pp |
| Win rate | 33.9% | 33.5% | ~flat |
| Avg win / loss | 4.01 / 2.03 | 4.01 / 2.03 | ~flat |
| Long / short | 1071 / 1109 | 953 / 1000 | balanced |

**Verdict:** Tighter volume **rejects good trades** more than bad ones — net flipped negative. **Do not add** to stack. Keep **`InpVolumeMultiplier=1.05`** (P2-C).

---

## EDGE-2.5 — session overlap defaults

**Status:** Preset ready for T09. **No code change** — optional session leg already in AND-chain.

| Input | Value |
|-------|--------|
| Stack | Same as P2-C (T07 production filters) |
| `InpUseSessionBreakout` | **true** |
| `InpSessionStartHour` | **0** (default) |
| `InpSessionEndHour` | **8** (default — Asian box) |
| Deposit | **200** |

**Behavior:** Build intraday high/low from broker hours **0–7** on the signal day. BUY requires close **above** session high; SELL **below** session low. Active during hours gate 8–17 → London/NY trades must break the Asian range.

**Compare to:** T07 / P2-C (PF 1.01 · net +43.49 · 2180 trades).

**Preset file:** `presets/tester/AEC.P2-E_session-overlap_EDGE-2-5.set`

**Test ID:** T09 · archive to `doc/data/T09/`

**Success criteria vs T07:** PF > 1.01 · net profit up · win rate up · trade count reduction OK if quality improves.

## T09 result (2026-05-20)

| Metric | T07 (P2-C) | T09 (+ session) | Δ |
|--------|------------|-----------------|---|
| Net profit | +43.49 | **-106.48** | -149.97 |
| Profit factor | 1.01 | **0.94** | -0.07 |
| Trades | 2180 | 1402 | -778 (-36%) |
| Max DD % | 69.8 | 71.5 | +1.7 pp |
| Win rate | 33.9% | 32.4% | -1.5 pp |
| Avg win / loss | 4.01 / 2.03 | 4.00 / 2.03 | ~flat |

**Verdict:** Asian range breakout leg **over-filters** — PF and net collapse. **Reject.** Session stays **off** (`InpUseSessionBreakout=false`). **Phase 2 complete** — production = **P2-C only**.

---

## EDGE-3.11 — room-to-run

**Status:** **done (T31)** — reject.

| Input | Value |
|-------|--------|
| Stack | Same as P2-C |
| `InpUseRoomToRun` | true |
| `InpRoomToRunAtrMult` | **0.5** |
| `InpRoomToRunLookback` | **24** bars |
| Deposit | **200** |

**Behavior:** After structure break passes, BUY needs nearest swing **high** above close ≥ **0.5× ATR** away; SELL needs nearest **low** below ≥ **0.5× ATR**. No ceiling/floor in lookback → pass.

**Compare to:** P2-C (PF 1.01 · net +43.49 · 2180 trades).

**Preset:** `presets/tester/AEC.P3-A_room-to-run_EDGE-3-11.set` · **T31** · `doc/data/T31/`

**Success vs P2-C:** PF ≥ 1.01 · WR up · net up · fewer trades OK.

### T31 result (2026-05-20)

| Metric | T31 (P3-A) | T07 (P2-C) |
|--------|------------|------------|
| PF | **0.97** | 1.01 |
| Net | **-75.13** | +43.49 |
| Trades | 1884 | 2180 |
| WR | 32.91% | ~33.9% |
| Max equity DD % | ~66.7% | ~69.8% |

**Verdict:** **Reject.** Room filter cuts ~14% of trades but flips stack to net loss (Δ net ≈ **-118** vs P2-C). Same pattern as volume 1.15 / session — removes winners with losers. Keep **`InpUseRoomToRun=false`** on production preset.

---

## EDGE-3.1 — exclude hours 13–15

**Status:** **done (T10)** — reject.

| Metric | T10 (P3-B) | T07 (P2-C) |
|--------|------------|------------|
| PF | **1.00** | 1.01 |
| Net | **-7.70** | +43.49 |
| Trades | 1844 | 2180 |
| WR | 33.46% | ~33.9% |

**Verdict:** **Reject.** Blind overlap cut ≈ T08 pattern (PF 1.00, net slightly negative vs P2-C +43). Keep **`InpUseHourExclusion=false`**. Consider **EDGE-3.16** (tighter entry only in 13–15) instead of hour block.

---

## EDGE-3.2 — BB release expand 1.10

**Status:** **done (T11)** — **keep** → production.

| Input | Value |
|-------|--------|
| Stack | Same as P2-C |
| `InpUseMinBbReleaseQuality` | true |
| `InpMinBbReleaseExpandRatio` | **1.10** (was **1.08** in P2-C) |
| Deposit | **200** |

**Hypothesis:** Weak 8–10% band expansions still slip through at 1.08; 1.10 drops feeble releases.

**Compare to:** P2-C (PF 1.01 · net +43.49 · 2180 trades).

**Preset:** `presets/tester/AEC.P3-C_bb-release-expand110_EDGE-3-2.set` · **T11** · `doc/data/T11/`

**Success vs P2-C:** PF ≥ 1.01 · WR up · net up · fewer trades OK. If **keep**, production preset becomes P3-C; if marginal, try **EDGE-3.3** (1.12) before committing.

### T11 result (2026-05-20)

| Metric | T11 (P3-C) | T07 (P2-C) |
|--------|------------|------------|
| PF | **1.03** | 1.01 |
| Net | **+97.80** | +43.49 |
| Trades | 2133 | 2180 |
| WR | 34.32% | ~33.9% |
| Max equity DD % | ~50.9% | ~69.8% |

**Verdict:** **Keep** — new **production** preset `AEC.P3-C_bb-release-expand110_EDGE-3-2.set`. Tighter BB release improves net (+54), PF, WR, and materially lowers DD%. **EDGE-3.3** (1.12) optional sweep — T12 vs P3-C.

---

## EDGE-3.3 — BB release expand 1.12

**Status:** **done (T12)** — **reject (marginal)** — production stays **P3-C**.

| Metric | T12 (P3-D) | T11 (P3-C) |
|--------|------------|------------|
| PF | 1.04 | 1.03 |
| Net | +100.23 | +97.80 |
| Trades | 2069 | 2133 |
| WR | 34.36% | 34.32% |
| Max equity DD % | ~56.8% | ~50.9% |

**Verdict:** **Reject.** Net +2.43 and PF +0.01 do not justify ~6pp higher max DD. **Production:** `AEC.P3-C_bb-release-expand110_EDGE-3-2.set` · do not use 1.12.

---

## EDGE-3.12 — BB expansion persistence

**Status:** **done (T32)** — **reject**.

| Metric | T32 (P3-E) | T11 (P3-C) |
|--------|------------|------------|
| PF | 1.02 | 1.03 |
| Net | +37.07 | +97.80 |
| Trades | 1598 | 2133 |
| WR | 33.98% | 34.32% |
| Max equity DD % | ~34.1% | ~50.9% |

**Verdict:** **Reject.** Lower DD but net −60.73 and PF/WR down — removes good expansions with fakes. **`InpUseBbExpansionPersistence=false`** on production.

---

## EDGE-3.4 — struct break 0.20 ATR

**Status:** **done (T13)** — **keep** → production.

| Metric | T13 (P3-F) | T11 (P3-C) |
|--------|------------|------------|
| PF | **1.04** | 1.03 |
| Net | **+103.71** | +97.80 |
| Trades | 2115 | 2133 |
| WR | 34.37% | 34.32% |
| Max equity DD % | ~52.6% | ~50.9% |

**Verdict:** **Keep** — modest net/PF/WR lift with similar trade count; DD +1.7pp acceptable. **Production:** `AEC.P3-F_struct-break-atr020_EDGE-3-4.set`.

---

## EDGE-3.6 — displacement 0.65 ATR

**Status:** Preset ready for T15.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpDisplacementBodyAtrMult` | **0.65** (was **0.55**) |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-G_displacement-atr065_EDGE-3-6.set` · **T15** · `doc/data/T15/`

### T15 result (2026-05-20)

| Metric | T15 (P3-G) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.00 | 1.04 |
| Net | -2.24 | +103.71 |
| Trades | 2079 | 2115 |
| WR | 33.53% | 34.37% |
| Max equity DD % | ~74.3% | ~52.6% |

**Verdict:** **Reject.** Displacement 0.65 wipes net edge and spikes DD — keep **`InpDisplacementBodyAtrMult=0.55`** on production.

---

## EDGE-3.5 — struct break 0.25 ATR

**Status:** Preset ready for T14.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpMinStructBreakAtrMult` | **0.25** (was **0.20** in P3-F) |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-H_struct-break-atr025_EDGE-3-5.set` · **T14** · `doc/data/T14/`

### T14 result (2026-05-20)

| Metric | T14 (P3-H) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.03 | **1.04** |
| Net | +93.03 | **+103.71** |
| Trades | 2100 | 2115 |
| WR | 34.29% | 34.37% |
| Max equity DD % | ~56.9% | ~52.6% |

**Verdict:** **Reject.** Tighter struct does not beat 0.20 — keep **`InpMinStructBreakAtrMult=0.20`** on P3-F.

---

## EDGE-3.13 — EMA overextension cap

**Status:** Implemented. Preset ready for T33.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseEmaOverextensionCap` | true |
| `InpEmaMaxDistAtrMult` | **1.2** |
| Rule | After EMA align: bar-1 \|close − fast EMA\| ≤ **1.2 × ATR** |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-I_ema-overext-cap_EDGE-3-13.set` · **T33** · `doc/data/T33/`

### T33 result (2026-05-20)

| Metric | T33 (P3-I) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.05 | 1.04 |
| Net | +60.62 | **+103.71** |
| Trades | 892 | 2115 |
| WR | 34.64% | 34.37% |
| Max equity DD % | ~27.1% | ~52.6% |

**Verdict:** **Reject.** PF nudges up and DD halves, but net −43 and trade count −58% — over-filter. **`InpUseEmaOverextensionCap=false`** on production.

---

## EDGE-3.7 — min signal-bar range 0.30× ATR

**Status:** Implemented. Preset ready for T16.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseMinSignalBarRange` | true |
| `InpMinSignalBarRangeAtrMult` | **0.30** |
| Rule | Bar 1 (high − low) ≥ **0.30 × ATR** (after displacement body OK) |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-J_min-bar-range-atr030_EDGE-3-7.set` · **T16** · `doc/data/T16/`

### T16 result (2026-05-20)

| Metric | T16 (P3-J) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.04 | 1.04 |
| Net | +103.01 | +103.71 |
| Trades | 2116 | 2115 |
| WR | 34.36% | 34.37% |
| Max equity DD % | ~52.6% | ~52.6% |

**Verdict:** **Reject (no lift).** Filter is effectively redundant at 0.30×ATR — displacement 0.55 already limits narrow bars. **`InpUseMinSignalBarRange=false`** on production.

---

## EDGE-3.14 — close strength (top/bottom 70% of bar 1)

**Status:** Implemented. Preset ready for **T34**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseCloseStrength` | true |
| `InpCloseStrengthMinPosition` | **0.70** (buy ≥ 0.70; sell ≤ 0.30) |
| Rule | On bar 1, after displacement OK: position = `(close−low)/(high−low)` |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-K_close-strength-70pct_EDGE-3-14.set` · **T34** · `doc/data/T34/`

**Code:** `SigClose_BuyStrength` / `SigClose_SellStrength` in `Signals/Displacement.mqh`; gated in `SignalEngine.mqh` after min bar range.

### T34 result (2026-05-20)

| Metric | T34 (P3-K) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.01 | 1.04 |
| Net | +20.48 | +103.71 |
| Trades | 1939 | 2115 |
| WR | 33.73% | 34.37% |
| Max equity DD % | ~61.9% | ~52.6% |

**Verdict:** **Reject.** Net −83 vs baseline; PF down; DD worse. **`InpUseCloseStrength=false`** on production.

---

## EDGE-3.15 — squeeze duration (≥4 compressed bars)

**Status:** Implemented. Preset ready for **T35**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseBbSqueezeDuration` | true |
| `InpBbMinSqueezeBars` | **4** |
| Rule | After standard release (w1>w2, squeeze plate, expand ≥1.10): bars **2–5** must each satisfy `width < avg(shift..shift+lookback−1) × InpBbSqueezeWidthRatio` |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-L_squeeze-duration-4_EDGE-3-15.set` · **T35** · `doc/data/T35/`

**Code:** `SigBb_ShiftCompressed` + duration gate in `Signals/BBSqueeze.mqh`.

### T35 result (2026-05-20)

| Metric | T35 (P3-L) | T13 (P3-F) |
|--------|------------|------------|
| PF | 0.99 | 1.04 |
| Net | −28.90 | +103.71 |
| Trades | 1942 | 2115 |
| WR | 33.32% | 34.37% |
| Max equity DD % | ~59.3% | ~52.6% |

**Verdict:** **Reject.** Net negative; PF below 1; DD worse. **`InpUseBbSqueezeDuration=false`** on production.

---

## EDGE-3.8 — EMA direction (slow EMA slope)

**Status:** Implemented. Preset ready for **T17**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseEmaDirectionFilter` | true |
| Rule | After fast/slow cross OK: buy requires **slow[1] > slow[2]**; sell **slow[1] < slow[2]** |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-M_ema-direction_EDGE-3-8.set` · **T17** · `doc/data/T17/`

**Code:** `SigEma_SlowTrendBuy` / `SigEma_SlowTrendSell` in `Signals/EMAMomentum.mqh`.

### T17 result (2026-05-20)

| Metric | T17 (P3-M) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.04 | 1.04 |
| Net | +103.01 | +103.71 |
| Trades | 2116 | 2115 |
| WR | 34.36% | 34.37% |
| Max equity DD % | ~52.6% | ~52.6% |

**Verdict:** **Reject (no lift).** Filter is redundant when fast already above/below slow on bar 1. **`InpUseEmaDirectionFilter=false`** on production.

---

## EDGE-3.9 — signal spread cap (25 pts)

**Status:** Implemented. Preset ready for **T18**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseSignalSpreadCap` | true |
| `InpMaxSignalSpreadPoints` | **25** |
| `InpMaxSpreadPoints` | **50** (unchanged hard tick gate) |
| Rule | After full AND chain: veto if bid/ask spread > 25 pts at new-bar entry tick |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P3-N_signal-spread-25_EDGE-3-9.set` · **T18** · `doc/data/T18/`

**Code:** `Aec_SpreadPoints` in `Utils/Helpers.mqh`; gate in `SignalEngine::Evaluate`.

### T18 result (2026-05-20)

| Metric | T18 (P3-N) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.04 | 1.04 |
| Net | +105.01 | +103.71 |
| Trades | 2115 | 2115 |
| WR | 34.37% | 34.37% |
| Max equity DD % | ~51.7% | ~52.6% |

**Verdict:** **Reject (no lift).** Identical trade count; +1.3 net within noise. **`InpUseSignalSpreadCap=false`** on production.

---

## EDGE-3.10 — trading hours 8–12 only

**Status:** Preset ready for **T37**. No code change (uses `InpUseTradingHours` + `InpTradingHourEnd`).

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseTradingHours` | true |
| `InpTradingHourStart` | **8** |
| `InpTradingHourEnd` | **12** (exclusive — drops afternoon 12–17 vs production 17) |
| Deposit | **200** |

**Compare to:** P3-F / T13 · optional T10 (3.1 exclude 13–15 only).

**Preset:** `AEC.P3-O_hours-8-12_EDGE-3-10.set` · **T37** · `doc/data/T37/`

**Hypothesis:** Morning session only may beat blunt 8–17 or 3.1 exclusion.

### T37 result (2026-05-20)

| Metric | T37 (P3-O) | T13 (P3-F) | T10 (3.1 excl 13–15) |
|--------|------------|------------|----------------------|
| PF | 1.05 | 1.04 | 1.00 |
| Net | +84.48 | +103.71 | −7.70 |
| Trades | 1185 | 2115 | 1844 |
| WR | 34.68% | 34.37% | 33.5% |
| Max equity DD % | ~34.6% | ~52.6% | ~66.9% |

**Verdict:** **Reject.** PF nudges up and DD halves, but net **−19** vs P3-F — do not shrink window to 8–12. Production stays **8–17**.

---

## EDGE-3.16 — adaptive overlap (stricter 13–15 only)

**Status:** Implemented. Preset ready for **T38**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F (hours **8–17**, no hour exclusion) |
| `InpUseAdaptiveOverlap` | true |
| `InpOverlapHourStart` / `InpOverlapHourEnd` | **13** / **15** (exclusive end, signal bar time) |
| Overlap BB expand | **1.12** (base 1.10) |
| Overlap struct ATR | **0.25** (base 0.20) |
| Overlap displacement | **0.65** (base 0.55) |

**Compare to:** P3-F / T13 · T10 (EDGE-3.1 blind cut).

**Preset:** `AEC.P3-P_adaptive-overlap_EDGE-3-16.set` · **T38** · `doc/data/T38/`

**Code:** `SignalEngine::CollectLegs` swaps thresholds when bar 1 hour ∈ overlap window.

### T38 result (2026-05-20)

| Metric | T38 (P3-P) | T13 (P3-F) | T10 (3.1 excl 13–15) |
|--------|------------|------------|----------------------|
| PF | 1.02 | 1.04 | 1.00 |
| Net | +47.24 | +103.71 | −7.70 |
| Trades | 2093 | 2115 | 1844 |
| WR | 33.92% | 34.37% | 33.5% |
| Max equity DD % | ~60.2% | ~52.6% | ~66.9% |

**Verdict:** **Reject.** Adaptive strictness does not beat blind exclusion or baseline — overlap still contributes net; do not tighten in-window. **`InpUseAdaptiveOverlap=false`** on production.

---

## EDGE-4.1 — HTF H1 EMA(50) trend

**Status:** Implemented. Preset ready for **T39**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseHtfTrendFilter` | true |
| `InpHtfTrendTimeframe` | **PERIOD_H1** (16385 in .set) |
| `InpHtfTrendEmaPeriod` | **50** |
| Rule | Buy: H1 closed bar close **>** EMA50 · Sell: close **<** EMA50 |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P4-A_htf-h1-ema50_EDGE-4-1.set` · **T39** · `doc/data/T39/`

**Code:** `Signals/HtfTrend.mqh` · `buyHtf`/`sellHtf` in AND chain.

### T39 result (2026-05-20)

| Metric | T39 (P4-A) | T13 (P3-F) |
|--------|------------|------------|
| PF | 0.97 | 1.04 |
| Net | −59.18 | +103.71 |
| Trades | 1507 | 2115 |
| WR | 32.91% | 34.37% |
| Max equity DD % | ~81.0% | ~52.6% |

**Verdict:** **Reject.** Strategy goes negative; HTF alignment over-filters. **`InpUseHtfTrendFilter=false`** on production.

---

## EDGE-4.2 — ADX(14) minimum 18

**Status:** Implemented. Preset ready for **T40**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseAdxMinFilter` | true |
| `InpAdxPeriod` | **14** |
| `InpAdxMinLevel` | **18.0** |
| Rule | ADX main line on signal TF bar 1 ≥ 18 (skip flat chop) |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P4-B_adx-min18_EDGE-4-2.set` · **T40** · `doc/data/T40/`

**Code:** `Signals/AdxRegime.mqh` · `adxOk` in AND chain.

### T40 result (2026-05-20)

| Metric | T40 (P4-B) | T13 (P3-F) |
|--------|------------|------------|
| PF | 1.04 | 1.04 |
| Net | +101.68 | +103.71 |
| Trades | 1977 | 2115 |
| WR | 34.40% | 34.37% |
| Max equity DD % | ~42.6% | ~52.6% |

**Verdict:** **Reject (no lift).** Lower DD not enough to trade −2 net and −138 trades. **`InpUseAdxMinFilter=false`** on production.

---

## EDGE-4.3 — ATR percentile band (20–85)

**Status:** Implemented. Preset ready for **T41**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUseAtrPercentileBand` | true |
| `InpAtrPercentileLookback` | **100** |
| `InpAtrPercentileMin` | **20** (skip bottom 20% dead vol) |
| `InpAtrPercentileMax` | **85** (skip top ~15% spike vol) |
| Rule | Bar-1 ATR must lie between 20th and 85th percentile of ATR on shifts 1..100 |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P4-C_atr-pct-20-85_EDGE-4-3.set` · **T41** · `doc/data/T41/`

**Code:** `Signals/AtrRegime.mqh` · `atrRegimeOk` in AND chain (reuses `m_hAtr`).

### T41 result (2026-05-20)

| Metric | T41 (P4-C) | T13 (P3-F) |
|--------|------------|------------|
| PF | 0.99 | 1.04 |
| Net | −15.74 | +103.71 |
| Trades | 1453 | 2115 |
| WR | 33.45% | 34.37% |
| Max equity DD % | ~50.4% | ~52.6% |

**Verdict:** **Reject.** Net negative; −31% trades. **`InpUseAtrPercentileBand=false`** on production.

---

## EDGE-4.4 — prior bar range cap (2× ATR)

**Status:** Implemented. Preset ready for **T42**.

| Input | Value |
|-------|--------|
| Stack | Same as P3-F |
| `InpUsePriorBarRangeCap` | true |
| `InpMaxPriorBarRangeAtrMult` | **2.0** |
| Rule | Bar-1 high-low range must be ≤ **2.0 × ATR** (skip post-shock bars) |
| Deposit | **200** |

**Compare to:** P3-F / T13 (PF 1.04 · net +103.71 · 2115 trades).

**Preset:** `AEC.P4-D_prior-bar-range-cap-2atr_EDGE-4-4.set` · **T42** · `doc/data/T42/`

**Code:** `SigBar_MaxRangeOk` in `Signals/Displacement.mqh` · `priorBarOk` in AND chain.

### T42 result (2026-05-20)

| Metric | T42 (P4-D) | T13 (P3-F) |
|--------|------------|------------|
| PF | **1.07** | 1.04 |
| Net | **+161.20** | +103.71 |
| Trades | 1706 | 2115 |
| WR | 35.17% | 34.37% |
| Max equity DD % | ~40.0% | ~52.6% |

**Verdict:** **Keep** — new **production** preset `AEC.P4-D_prior-bar-range-cap-2atr_EDGE-4-4.set`. P3-F remains comparison baseline (T13).

---

## EDGE-4.5 — BB width vs average (chop skip)

**Status:** Implemented. Preset ready for **T43**.

| Input | Value |
|-------|--------|
| Stack | Same as **P4-D** (T42 baseline) |
| `InpUseBbChopSkip` | true |
| `InpMinBbWidthVsAvgRatio` | **1.0** |
| Rule | After BB release: bar-1 normalized width **≥** 12-bar average × 1.0 (skip marginal range releases) |
| Deposit | **200** |

**Compare to:** P4-D / T42 (PF 1.07 · net +161.20 · 1706 trades · DD ~40%).

**Preset:** `AEC.P4-E_bb-chop-skip_EDGE-4-5.set` · **T43** · `doc/data/T43/`

**Code:** `SigBb_WidthVsAvgOk` in `Signals/BBSqueeze.mqh` · gated on `legs.bb` in `SignalEngine.mqh`.

### T43 result (2026-05-20)

| Metric | T43 (P4-E) | T42 (P4-D) |
|--------|------------|------------|
| PF | **1.14** | 1.07 |
| Net | **+241.63** | +161.20 |
| Trades | 1305 | 1706 |
| WR | 36.70% | 35.17% |
| Max equity DD % | ~25.0% | ~40.0% |

**Verdict:** **Keep** — new **production** preset `AEC.P4-E_bb-chop-skip_EDGE-4-5.set`. P4-D remains comparison baseline (T42).

---

## EDGE-5.1 — cooldown after loss (90 min)

**Status:** Preset ready for **T21** (logic already in `Engine.mqh`).

| Input | Value |
|-------|--------|
| Stack | Same as **P4-E** (T43 production) |
| `InpCooldownAfterLossOnly` | **true** |
| `InpCooldownSecondsAfterTrade` | **5400** (90 minutes) |
| Rule | On losing position close (deal profit+swap+commission < 0), block new entries for 90 min; wins have no cooldown |
| Deposit | **200** |

**Compare to:** P4-E / T43 (PF 1.14 · net +241.63 · 1305 trades · DD ~25%).

**Preset:** `AEC.P5-A_cooldown-loss-90min_EDGE-5-1.set` · **T21** · `doc/data/T21/`

### T21 result (2026-05-20)

| Metric | T21 (P5-A) | T43 (P4-E) |
|--------|------------|------------|
| PF | 1.09 | **1.14** |
| Net | +151.62 | **+241.63** |
| Trades | 1251 | 1305 |
| WR | 35.65% | 36.70% |
| Max equity DD % | ~33.0% | **~25.0%** |

**Verdict:** **Reject.** Net −90 · PF down · DD worse — loss cooldown blocks good follow-up entries. Production stays **P4-E** (20s cooldown all trades, loss-only off).

---

## EDGE-5.2 — max trades per day (5)

**Status:** Implemented. Preset ready for **T22**.

| Input | Value |
|-------|--------|
| Stack | Same as **P4-E** (T43) |
| `InpUseMaxTradesPerDay` | true |
| `InpMaxTradesPerDay` | **5** |
| Rule | Count successful market opens per broker calendar day; block new entries when count ≥ 5 |
| Deposit | **200** |

**Compare to:** P4-E / T43 (PF 1.14 · net +241.63 · 1305 trades · DD ~25%).

**Preset:** `AEC.P5-B_max-trades-per-day-5_EDGE-5-2.set` · **T22** · `doc/data/T22/`

**Code:** `Risk/RiskManager.mqh` · `Engine.mqh` after `HasRoomForNew`.

### T22 result (2026-05-20)

| Metric | T22 (P5-B) | T43 (P4-E) |
|--------|------------|------------|
| PF | 1.14 | 1.14 |
| Net | +241.63 | +241.63 |
| Trades | **1305** | **1305** |
| WR | 36.70% | 36.70% |
| Max equity DD % | ~25.0% | ~25.0% |

**Verdict:** **Reject (no lift).** Identical report — 5/day cap inactive at current trade frequency. **`InpUseMaxTradesPerDay=false`** on production.

---

## EDGE-5.3 — daily drawdown block 3%

**Status:** Preset ready for **T23** (logic already in `RiskManager.mqh`).

| Input | Value |
|-------|--------|
| Stack | Same as **P4-E** (T43) |
| `InpMaxDailyDrawdownPercent` | **3.0** (was **5.0**) |
| Rule | If intraday equity falls ≥3% from day-start equity, block new entries until next broker day |
| Deposit | **200** |

**Compare to:** P4-E / T43 (PF 1.14 · net +241.63 · 1305 trades · DD ~25%).

**Preset:** `AEC.P5-C_daily-dd-3pct_EDGE-5-3.set` · **T23** · `doc/data/T23/`

**Success vs P4-E:** PF ≥ 1.14 · net up or equal · WR up; fewer trades OK only if net improves · DD not worse.

### T23 result (2026-05-20)

| Metric | T23 (P5-C) | T43 (P4-E) |
|--------|------------|------------|
| PF | 1.14 | 1.14 |
| Net | +241.63 | +241.63 |
| Trades | **1305** | **1305** |
| WR | 36.70% | 36.70% |
| Max equity DD % | ~25.0% | ~25.0% |

**Verdict:** **Reject (no lift).** 3% daily block never changes curve vs 5% at this deposit/lot. **`InpMaxDailyDrawdownPercent=5.0`** on production.

---

## EDGE-5.4 — direction throttle by hour

**Status:** Implemented. Preset ready for **T44**.

| Input | Value |
|-------|--------|
| Stack | Same as **P4-E** (T43) |
| `InpUseHourDirectionFilter` | true |
| `InpBlockBuyHourStart` / `InpBlockBuyHourEnd` | **13** / **15** (block BUY in window) |
| `InpBlockSellHourStart` / `InpBlockSellHourEnd` | **-1** (SELL throttle off) |
| Rule | On signal bar broker hour: skip BUY entries in [13,15); SELL unchanged |
| Deposit | **200** |

**Compare to:** P4-E / T43 · optional T10 (3.1 excluded all hours 13–15).

**Preset:** `AEC.P5-D_block-buy-hours-1315_EDGE-5-4.set` · **T44** · `doc/data/T44/`

**Code:** `Signals/HourDirection.mqh` · `Engine.mqh` after global `InpTradeDirection`.

**T44 result (2026-05-20):** **Reject.** PF **1.15** vs T43 **1.14**; net **+222.85** vs **+241.63** (−18.78); trades **1175** (−130); WR **36.68%**; max equity DD **~26.4%** vs **~25%**. Filter active but cuts profitable overlap BUYs. **`InpUseHourDirectionFilter=false`** on production.

---

## EDGE-5.5 — post-streak gate

**Status:** Implemented. Preset ready for **T36**.

| Input | Value |
|-------|--------|
| Stack | Same as **P4-E** (T43) |
| `InpUsePostStreakGate` | true |
| `InpPostStreakLossCount` | **4** |
| `InpPostStreakPauseSeconds` | **2700** (45 min) |
| `InpCooldownAfterLossOnly` | false (unchanged) |
| `InpCooldownSecondsAfterTrade` | **20** (unchanged) |
| Rule | On each **losing** position exit: increment streak; at **4** → pause **45 min** (overrides `CD_UNTIL`) and reset streak; win/BE resets streak |
| Deposit | **200** |

**Compare to:** P4-E / T43 · contrast T21 (90 min after **every** loss).

**Preset:** `AEC.P5-E_post-streak-4loss-45min_EDGE-5-5.set` · **T36** · `doc/data/T36/`

**Code:** `Core/Engine.mqh` · `OnExitDealProfit` · GV key `LOSS_STREAK`.

**T36 result (2026-05-20):** **Keep → production.** PF **1.15** vs T43 **1.14**; net **+247.68** vs **+241.63** (+6.05); trades **1302** (−3); WR **36.79%**; max equity DD **~23%** vs **~25%**. **`InpUsePostStreakGate=true`** on production.

---

## EDGE-6.1 — risk-reward 1.5

**Status:** Preset ready for **T24** (no code change — existing `InpRiskReward` + `InpUseRrForTp`).

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpRiskReward` | **1.5** (was **2.0**) |
| `InpUseRrForTp` | true |
| `InpStopLossPoints` | **200** (unchanged) |
| Effective TP | **300** pts (200 × 1.5) |
| Deposit | **200** |

**Compare to:** P5-E / T36 (RR 2.0 · TP 400 pts).

**Preset:** `AEC.P6-A_rr-1_5_EDGE-6-1.set` · **T24** · `doc/data/T24/`

**T24 result (2026-05-20):** **Reject.** PF **1.06** vs T36 **1.15**; net **+99.51** vs **+247.68** (−148.17); trades **1414** (+112); WR **41.65%** (+4.9 pp); max equity DD **~32%** vs **~23%**. Closer TP not worth it. **`InpRiskReward=2.0`** on production.

---

## EDGE-6.2 — risk-reward 2.5

**Status:** Preset ready for **T25** (no code change).

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpRiskReward` | **2.5** (was **2.0**) |
| `InpUseRrForTp` | true |
| `InpStopLossPoints` | **200** (unchanged) |
| Effective TP | **500** pts |
| Deposit | **200** |

**Preset:** `AEC.P6-F_rr-2_5_EDGE-6-2.set` · **T25** · `doc/data/T25/`

**T25 result (2026-05-20):** **Reject.** PF **1.04** vs T36 **1.15**; net **+60.12** vs **+247.68** (−187.56); trades **1178**; WR **29.63%**; max equity DD **~36%**. Wider TP hurts completion rate. **`InpRiskReward=2.0`** on production.

---

## EDGE-6.5 — stop loss 150 pts

**Status:** Preset ready for **T28** (no code change).

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpStopLossPoints` | **150** (was **200**) |
| `InpRiskReward` | **2.0** (unchanged) |
| Effective TP | **300** pts (150 × 2) |
| Deposit | **200** |

**Preset:** `AEC.P6-G_sl-150pts_EDGE-6-5.set` · **T28** · `doc/data/T28/`

**T28 result (2026-05-20):** **Reject.** PF **1.01** vs T36 **1.15**; net **+12.31** vs **+247.68** (−235.37); trades **1537** (+235); WR **33.83%**; max equity DD **~45%**. **`InpStopLossPoints=200`** on production.

---

## EDGE-6.4 — dead-trade exit

**Status:** Implemented. Preset ready for **T27**.

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpUseDeadTradeExit` | true |
| `InpDeadTradeMinR` | **0.3** |
| `InpDeadTradeMaxBars` | **5** |
| Rule | Each tick: track if price reached **+0.3R** (R = \|entry − SL\|). On new bar: if **≥ 5** bars since open and min R never hit → close position |
| Deposit | **200** |

**Compare to:** P5-E / T36.

**Preset:** `AEC.P6-B_dead-trade-exit_EDGE-6-4.set` · **T27** · `doc/data/T27/`

**Code:** `Execution/DeadTradeExit.mqh` · `TradeExecutor::ClosePosition` · `Engine.mqh` (runs before cooldown / entries).

**T27 result (2026-05-20):** **Reject.** PF **1.09** vs T36 **1.15**; net **+105.57** vs **+247.68** (−142.11); trades **1677** (+375); WR **33.27%**; max equity DD **~24.2%**; avg hold **~4h** vs **~9.5h**. Early exit churn. **`InpUseDeadTradeExit=false`** on production.

---

## EDGE-6.8 — breakeven at +0.8R

**Status:** Implemented. Preset ready for **T45**.

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpUseBreakevenAtR` | true |
| `InpBreakevenTriggerR` | **0.8** |
| Rule | When price reaches **+0.8R**, modify SL to entry (respects `SYMBOL_TRADE_STOPS_LEVEL`) · once per position |
| Deposit | **200** |

**Compare to:** P5-E / T36.

**Preset:** `AEC.P6-C_be-at-0_8r_EDGE-6-8.set` · **T45** · `doc/data/T45/`

**Code:** `Execution/BreakevenExit.mqh` · `TradeExecutor::ModifySlToBreakeven` · `PositionHelpers.mqh`.

**T45 result (2026-05-20):** **Reject.** PF **1.03** vs T36 **1.15**; net **+42.58** vs **+247.68** (−205.10); trades **1481** (+179); WR **42.61%**; max equity DD **~43%** vs **~23%**. BE caps 2R runners. **`InpUseBreakevenAtR=false`** on production.

---

## EDGE-6.3 — breakeven at +1.0R

**Status:** Preset ready for **T26** (reuses **6.8** code).

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpUseBreakevenAtR` | true |
| `InpBreakevenTriggerR` | **1.0** (vs T45 **0.8**) |
| Rule | Move SL to entry when **+1R** reached |
| Deposit | **200** |

**Preset:** `AEC.P6-D_be-at-1r_EDGE-6-3.set` · **T26** · `doc/data/T26/`

**T26 result (2026-05-20):** **Reject.** PF **1.07** vs T36 **1.15**; net **+95.90** vs **+247.68** (−151.78); trades **1427** (+125); WR **41.49%**; max equity DD **~39%**. Better than T45 but not production-worthy.

---

## EDGE-6.7 — partial close at +1.2R

**Status:** Implemented. Preset ready for **T46**.

| Input | Value |
|-------|--------|
| Stack | Same as **P5-E** (T36) |
| `InpUsePartialCloseAtR` | true |
| `InpPartialCloseTriggerR` | **1.2** |
| `InpPartialClosePercent` | **40** |
| Rule | At **+1.2R**, close **40%** volume once; remainder runs to TP |
| Deposit | **200** · lot **0.01** |

**Compare to:** P5-E / T36.

**Preset:** `AEC.P6-E_partial-40pct-at-1_2r_EDGE-6-7.set` · **T46** · `doc/data/T46/`

**Code:** `Execution/PartialCloseExit.mqh` · `TradeExecutor::PartialCloseVolume`.

**Caveat:** Broker min lot step **0.01** → partial may not execute at **0.01** fixed lot; journal shows `Partial skip` if so.

**T46 result (2026-05-20):** **Reject (no lift).** Identical to T36 — partial never binds at 0.01 lot. **`InpUsePartialCloseAtR=false`** on production.
