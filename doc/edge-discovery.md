# Edge discovery — phased task list



**Status:** **Phase 8 complete** · production **`AEC.P5-F`** (T48) locked · **Phase 9** = bucket-driven improvements (next).

**Problem (post–Phase 2):** Thin edge (PF ~1.01, WR ~34% vs breakeven ~33.5%). Enough winners; **~66% losers** at ~2:1 R:R erode gains. Focus: **entry quality**, **regime**, **failure containment**, then **exits** — one ID → one backtest vs **P2-C**.



**Related docs:** [concept.md](./concept.md) · [phase1-analysis.md](./phase1-analysis.md) · [phase3-optimization.md](./phase3-optimization.md) · [addtions.md](./addtions.md) · [paths.md](./paths.md)



**How to use IDs:** Pick the **lowest-ID open** task. One filter change → one backtest → filter log.

**Backtest deposit:** **200** (fixed lot 0.01). T04/T05 used 2000 for exploratory runs only — compare **PF, trades, win rate** going forward.



---



## Target metrics (edge “found” — working definition)



| Metric | Full-range baseline | Isolated-edge target |

|--------|---------------------|----------------------|

| Profit factor | **0.93** | **> 1.15** OOS |

| Win rate | **~32%** | **> 38%** *or* avg win **> 2.2×** loss |

| Trade count | **3,418** | **500–1.5k** after filters |

| Direction | **Balanced** L/S | Both unless deliberate |

| Max equity DD | **~16.9%** | **< 10%** before scaling risk |



---



## Phase 0 — Diagnostics



| ID | Status | Notes |

|----|--------|-------|

| EDGE-0.1 | **done** | T01–T03 exec + natural chain |

| EDGE-0.2 | **done** | Full-range report provided (2020–2026) |

| EDGE-0.3 | **partial** | Charts in phase1-analysis; numeric buckets → **EDGE-7.1** |

| EDGE-0.4 | **done** | Full baseline documented below |



---



## Phase 1 — Analysis (no EA changes)



| ID | Status | Outcome |

|----|--------|---------|

| EDGE-1.1 | **done** | Drop **0–7** first; **not** 12–17-only |

| EDGE-1.2 | **done** | Keep Mon–Fri; weekday filter deferred |

| EDGE-1.3 | **done** | **Tighten entries** before widening TP |

| EDGE-1.4 | **done** | Entry quality > exit tuning; see phase1-analysis |

| EDGE-1.5 | **done** | Primary segment **8–17 broker** → EDGE-2.1 |



---



## Phase 2 — Research filters



| ID | Task | Depends on | Status |

|----|------|------------|--------|

| **EDGE-2.1** | Trading hours gate **8–17** | EDGE-1.5 | **done (T05)** — keep filter |

| EDGE-2.2 | Min structure break distance | EDGE-2.1 measured | **done (T06)** — keep filter |

| **EDGE-2.3** | Min BB release quality | EDGE-2.2 measured | **done (T07)** — keep filter |

| **EDGE-2.4** | Volume tier 1.15+ | EDGE-2.3 measured | **done (T08)** — **reject** (net/PF worse) |

| **EDGE-2.5** | Session overlap defaults | EDGE-2.3 measured | **done (T09)** — **reject** |



---



## Phase 3 — Entry & time refinement (vs P2-C)



**Goal:** Raise WR / PF by removing **marginal entries**. **Do not** re-test EDGE-2.4 or EDGE-2.5.

**Thesis (P2-C):** *Volatility expansion continuation after compression* — filters must test **movement quality**, not more movement. See [addtions.md](./addtions.md).



| ID | Task | Depends on | Status | Test |
|----|------|------------|--------|------|
| **EDGE-3.1** | Exclude broker hours **13–15** | Phase 2 | **done (T10)** — **reject** |
| EDGE-3.2 | BB release expand **1.10** (single bar) | P2-C | **done (T11)** — **keep** → production |
| EDGE-3.3 | BB release expand **1.12** | P3-C | **done (T12)** — **reject** (marginal) |
| EDGE-3.4 | Struct break **0.20 ATR** | P3-C | **done (T13)** — **keep** → production |
| EDGE-3.5 | Struct break **0.25 ATR** | P3-F | **done (T14)** — **reject** |
| EDGE-3.6 | Displacement mult **0.65** | P3-F | **done (T15)** — **reject** |
| EDGE-3.7 | Min signal-bar range ≥ **0.30× ATR** | P3-F | **done (T16)** — **reject** (no lift) |
| EDGE-3.8 | EMA **direction** — slow EMA slopes with trade (bar 1 vs 2) | P3-F | **done (T17)** — **reject** (no lift) |
| EDGE-3.9 | Tighter spread at signal — max **25** pts (tick cap **50**) | P3-F | **done (T18)** — **reject** (no lift) |
| EDGE-3.10 | Hours **8–12** only (vs 8–17 / 3.1) | P3-F | **done (T37)** — **reject** |
| **EDGE-3.11** | **Room-to-run** — opposing swing ≥ **0.5× ATR** away | P3-C | **done (T31)** — **reject** |
| **EDGE-3.12** | **BB expansion persistence** — width up **2** closed bars | P3-C | **done (T32)** — **reject** |
| **EDGE-3.13** | **EMA overextension cap** — close within **1.2× ATR** of fast EMA | P3-F | **done (T33)** — **reject** |
| **EDGE-3.14** | **Close strength** — bull close in upper **70%** of bar range | P3-F | **done (T34)** — **reject** |
| **EDGE-3.15** | **Squeeze duration** — BB compressed ≥ **4** bars before release | P3-F | **done (T35)** — **reject** |
| **EDGE-3.16** | **Adaptive overlap** — stricter BB/struct/disp in **13–15** only | P3-F | **done (T38)** — **reject** |



---



## Phase 4 — Regime detection



| ID | Task | Depends on | Status | Test |
|----|------|------------|--------|------|
| **EDGE-4.1** | **HTF H1 EMA(50)** trend alignment | P3-F | **done (T39)** — **reject** |
| **EDGE-4.2** | **ADX(14) ≥ 18** on signal TF | P3-F | **done (T40)** — **reject** (no lift) |
| **EDGE-4.3** | **ATR percentile** band **20–85** (100-bar dist) | P3-F | **done (T41)** — **reject** |
| **EDGE-4.4** | Block prior bar **> 2× ATR** (bar-1 H-L cap) | P3-F | **done (T42)** — **keep** → **production** |
| **EDGE-4.5** | BB width vs average (chop skip) — bar-1 width **≥ avg × 1.0** | P4-D | **done (T43)** — **keep** → **production** |



---



## Phase 5 — Failure containment



| ID | Task | Depends on | Status | Test |
|----|------|------------|--------|------|
| **EDGE-5.1** | **Cooldown after loss** — **90 min** (5400 s), loss exits only | P4-E | **done (T21)** — **reject** |
| **EDGE-5.2** | **Max trades per day** — **5** opens / broker day | P4-E | **done (T22)** — **reject** (no lift) |
| **EDGE-5.3** | Daily DD block **3%** (was **5%**) | P4-E | **done (T23)** — **reject** (no lift) |
| **EDGE-5.4** | Direction throttle — **block BUY [13,15)** on signal bar | P4-E | **done (T44)** — **reject** |
| **EDGE-5.5** | **Post-streak gate** — after **4** losses: **45 min** pause | P4-E | **done (T36)** — **keep** → **production** |
| **EDGE-5.6** | Block BUY **[14,15)** only (T47 refine of 5.4) | P5-E | **done (T48)** — **keep** |



---



## Phase 6 — Exit & trade management (TP/SL / trail)



*After entry stack stable. Prefer **6.4 / 6.7 / 6.8** before **6.6** trail ([addtions.md](./addtions.md)).*



| ID | Task | Depends on | Status | Test |
|----|------|------------|--------|------|
| **EDGE-6.1** | **RR 1.5** (TP = 1.5× SL) | P5-E | **done (T24)** — **reject** |
| **EDGE-6.2** | **RR 2.5** (TP = 2.5× SL) | P5-E | **done (T25)** — **reject** |
| **EDGE-6.3** | **Breakeven at 1R** (SL to entry) | P5-E | **done (T26)** — **reject** |
| **EDGE-6.4** | **Dead-trade exit** — no **+0.3R** within **5** bars → close | P5-E | **done (T27)** — **reject** |
| **EDGE-6.5** | **SL 150 pts** (was 200) · RR 2.0 | P5-E | **done (T28)** — **reject** |
| **EDGE-6.6** | **ATR trail** after 1R (`InpUseAtrTrailAfterR` · 1.0R · ATR×1.5) | P5-E | **done (T29)** — **reject** |
| **EDGE-6.7** | **Partial close** **40%** at **1.2R** | P5-E | **done (T46)** — **reject** (no lift) |
| **EDGE-6.8** | **BE at 0.8R** (SL to entry) | P5-E | **done (T45)** — **reject** |



---



## Phase 7 — Diagnostics & segmentation (**complete**)



| ID | Task | Depends on | Status | Test / output |
|----|------|------------|--------|----------------|
| **EDGE-7.1** | Deal export → PF by hour/weekday/month | P5-E | **done (T47)** | `P7-A` · h14 drag · h13 BUY strong |
| **EDGE-7.2** | Leg **diag** full range (pass vs exec) | P5-F | **done (T30)** | `P7-B` · BB bottleneck |
| **EDGE-7.3** | MAE/MFE bucket taxonomy + bins | EDGE-7.1 | **done (T49)** | `P7-D` · `scripts/p7d_mae_mfe_postprocess.py` |

**T49 bucket baseline (P5-F, 1244 trades):** 45.8% `loser_never_green` · 16.8% `loser_fought_mfe05` · +226 net in peak MFE **1.5+** bin. Archive → `doc/data/T49/`.



---



## Phase 8 — Validation (backtest OOS) (**complete**)



*Validated **P5-F** before Phase 9. Re-run **8.1 holdout** on any Phase 9 winner.*



| ID | Task | Status | Notes |
|----|------|--------|-------|
| **EDGE-8.1** | Train/holdout split | **done (PASS)** | [edge-8-1-runbook.md](./edge-8-1-runbook.md) · **T50** · **T51** |
| **EDGE-8.2** | Calendar-year walk-forward | **done (PASS)** | [edge-8-2-runbook.md](./edge-8-2-runbook.md) · `wf_8_2_summarize.py` · **6/7** years net > 0 |
| **EDGE-8.3** | Production lock | **done** | [edge-8-3-production-lock.md](./edge-8-3-production-lock.md) · preset **P5-F** |

**8.1:** Holdout PF **1.18** · net **+93.57** · 419 trades. **8.2:** 2020 flat (−0.17); 2021–2026 all positive.



---



## Phase 9 — Bucket-driven improvements (**next**)



*Informed by **EDGE-7.3** — one ID → one backtest vs **P5-F** · then **EDGE-8.1** again on winner. Use `python scripts/p7d_mae_mfe_postprocess.py` after each run (no full diagnostic rerun).*



| Order | ID | Task | Bucket / segment signal | Status |
|-------|-----|------|-------------------------|--------|
| 0 | **EDGE-7.4** | Script: never-green **% by entry hour** → pick one hour gate | 7.3 taxonomy | **done** · → **EDGE-5.7** h16 |
| 1 | **EDGE-5.7** | Block hour **[16,17)** all dirs (`InpUseHourExclusion`) | 7.4 + 7.1 h16 weak | **reject** · T59 +0.82 · T60 holdout −6 vs T51 |
| 2 | **EDGE-6.9** | **Give-back cap** — reached **≥0.5R** MFE, not TP after **N** bars → close | 16.8% `loser_fought_mfe05` | **reject (T61)** · PF 1.02 · net +33 |
| 3 | **EDGE-6.10** | Partial **25%** at **1.0R**, runner to 2R TP | MFE bins **0.6–1.5** net negative | **reject (T63)** · PF 1.02 · DD ~50% |
| 4 | **EDGE-6.11** | Soft time stop if MFE **&lt; 0.2R** after **M** bars (softer than 6.4) | `loser_never_green` | **reject (T64)** · net −12.53 · PF 0.99 |
| 5 | **EDGE-3.17** | BB **1.12** (P9-E) or squeeze **4** bars (P9-F) on **P5-F** | 7.2 BB bottleneck | **reject (T65)** · net −16.47 · T66 skip |



**Success bar vs T48:** PF **≥ 1.17** · net **up** · WR **up**; fewer trades OK if net improves · worse DD → **reject**.



**Do not repeat here:** Phase 6.3/6.8 BE · 6.4 dead-trade · 6.7 partial 1.2R · 3.1 exclude 13–15 · broad Phase 3/4 rejects (see table below).



---



## Phase 10 — Forward / live (deferred)



| ID | Task | Depends on | Status |
|----|------|------------|--------|
| EDGE-9.1 | Forward test demo | Phase 8 complete + Phase 9 locked | **deferred** |
| EDGE-9.2 | Live micro-lot | EDGE-9.1 | **deferred** |



---



## Recommended priority (current roadmap)



| Order | Phase | ID | Why |
|-------|-------|-----|-----|
| — | 9 | ~~EDGE-3.17~~ | **reject T65** — Phase 9 closed |
| — | 9 | ~~6.11~~ | **reject T64** (net −12.53) |
| — | 9 | ~~EDGE-6.10~~ | **reject T63** (PF 1.02 · DD ~50%) |
| — | 9 | ~~EDGE-6.9~~ | **reject T61** (−238 net vs T48) |
| — | 9 | ~~EDGE-5.7~~ | **reject** (T60 holdout −6 net vs T51) |
| **4** | 10 | EDGE-9.1 | Demo forward (deferred) |



*Phases 0–8 **closed**. Phase 9 only improvement lane.*



**Targets vs P5-F (T48):** holdout PF **≥ 1.05** · full-sample PF **≥ 1.17** · WR **≥ 37%** · trades **~1.0k–1.4k**.



---



## Do not repeat



| ID / idea | Reason |
|-----------|--------|
| EDGE-2.4 | Volume 1.15+ |
| EDGE-2.5 | Asian session AND leg |
| 12–17-only hours | Loses 8–12, keeps overlap churn |
| Exits before entry stack | MFE/MAE → entries first |
| Trailing-first / RR 2.5 first | Low priority per additions + T07 MFE |
| More indicators (RSI/MACD) | Clutter; no hypothesis |



---



## Active segment (EDGE-1.5)



```

Symbol:     EURUSD

Timeframe:  M5

Date range: 2020.01.01 – 2026.05.19

Hours:      8 – 17 broker (exclude 0–7)

Direction:  Both

Notes:      Hours 8–17 base (T05). One filter at a time for EDGE-2.2+.

```



---



## Phase 2 stack baseline (T07 / hours + struct + BB release)



```

Symbol: EURUSD

Timeframe: M5

Date range: 2020.01.01 – 2026.05.19

Deposit: 200

Trades: 2180 (1071 long / 1109 short)

Net profit: +43.49

Profit factor: 1.01

Max DD %: ~69.8% equity (deposit 200 · fixed 0.01 lot)

Win rate: ~33.9%

Avg win / avg loss: 4.01 / 2.03

Preset: P2-C (hours + struct 0.15 ATR + BB expand ≥1.08)

Verdict: first profitable stack · keep all three filters · compare EDGE-2.4+ vs this row

```



*(T04/T05 at deposit 2000: exploratory only — PF/trades still valid but DD% differs.)*



---



## Full-range baseline (T04 / RAW natural)



```

Symbol: EURUSD

Timeframe: M5

Date range: 2020.01.01 – 2026.05.19

Deposit: 2000

Trades: 3418 (1739 long / 1679 short)

Net profit: -322.19

Profit factor: 0.93

Max DD %: ~16.91% equity

Win rate: ~31.98%

Avg win / avg loss: 4.02 / 2.03

Avg hold: ~9h 11m

Preset: natural chain, LTF defaults (RAW / no force)

Breakeven WR: ~33.5% at current payoff

```



---



## Filter log



| Date | Task ID | Change | PF | Trades | Max DD % | Notes |

|------|---------|--------|-----|--------|----------|-------|

| 2026-05-20 | baseline | none | 0.93 | 3418 | 16.9 | Full range natural |
| 2026-05-20 | EDGE-2.1 | hours 8–17 | 0.96 | 2395 | 9.7 | Deposit 2000 · net -121.70 · WR 32.7% · **keep** |
| 2026-05-20 | EDGE-2.2 | + struct break ≥0.15 ATR | 0.99 | 2323 | 74.7 | dep 200 · WR 33.2% · **keep** |
| 2026-05-20 | EDGE-2.3 | + BB release w1/w2≥1.08 | **1.01** | 2180 | 69.8 | dep 200 · net **+43.49** · WR 33.9% · **keep** |
| 2026-05-20 | EDGE-2.4 | + volume mult 1.15 | 1.00 | 1953 | 73.9 | dep 200 · net -5.30 · **reject** |
| 2026-05-20 | EDGE-2.5 | + session Asian break [0,8) | 0.94 | 1402 | 71.5 | dep 200 · net -106.48 · **reject** |
| 2026-05-20 | EDGE-3.11 | + room-to-run ≥0.5×ATR (24 bars) | 0.97 | 1884 | 66.7 | dep 200 · net -75.13 · WR 32.9% · **reject** |
| 2026-05-20 | EDGE-3.1 | + exclude broker hours [13,15) | 1.00 | 1844 | 66.9 | dep 200 · net -7.70 · WR 33.5% · **reject** |
| 2026-05-20 | EDGE-3.2 | BB release w1/w2≥**1.10** (replaces 1.08) | **1.03** | 2133 | 50.9 | dep 200 · net **+97.80** · WR 34.3% · **keep** → **production** |
| 2026-05-20 | EDGE-3.3 | BB release w1/w2≥**1.12** | 1.04 | 2069 | 56.8 | dep 200 · net +100.23 · WR 34.4% · **reject** · stay P3-C |
| 2026-05-20 | EDGE-3.12 | + BB width persist w1>w2>w3 | 1.02 | 1598 | 34.1 | dep 200 · net +37.07 · WR 34.0% · **reject** |
| 2026-05-20 | EDGE-3.4 | struct break ≥**0.20** ATR (was 0.15) | **1.04** | 2115 | 52.6 | dep 200 · net **+103.71** · WR 34.4% · **keep** → **production** |
| 2026-05-20 | EDGE-3.6 | displacement body ≥**0.65** ATR (was 0.55) | 1.00 | 2079 | 74.3 | dep 200 · net -2.24 · WR 33.5% · **reject** |
| 2026-05-20 | EDGE-3.5 | struct break ≥**0.25** ATR (was 0.20) | 1.03 | 2100 | 56.9 | dep 200 · net +93.03 · WR 34.3% · **reject** |
| 2026-05-20 | EDGE-3.13 | + EMA \|close-fast\| ≤ **1.2× ATR** | 1.05 | 892 | 27.1 | dep 200 · net +60.62 · WR 34.6% · **reject** |
| 2026-05-20 | EDGE-3.7 | + bar-1 range ≥ **0.30× ATR** | 1.04 | 2116 | 52.6 | dep 200 · net +103.01 · WR 34.4% · **reject** (≈P3-F) |
| 2026-05-20 | EDGE-3.14 | + close in top/bottom **70%** of bar 1 | 1.01 | 1939 | 61.9 | dep 200 · net **+20.48** · WR 33.7% · **reject** |
| 2026-05-20 | EDGE-3.15 | + BB compressed ≥ **4** bars before release | 0.99 | 1942 | 59.3 | dep 200 · net **−28.90** · WR 33.3% · **reject** |
| 2026-05-20 | EDGE-3.8 | + slow EMA slope with trade | 1.04 | 2116 | 52.6 | dep 200 · net +103.01 · WR 34.4% · **reject** (≈P3-F) |
| 2026-05-20 | EDGE-3.9 | + signal spread cap **25** pts | 1.04 | 2115 | 51.7 | dep 200 · net **+105.01** · WR 34.4% · **reject** (≈P3-F) |
| 2026-05-20 | EDGE-3.10 | hours **8–12** only (was 8–17) | 1.05 | 1185 | 34.6 | dep 200 · net **+84.48** · WR 34.7% · **reject** |
| 2026-05-20 | EDGE-3.16 | adaptive strict BB/struct/disp in **[13,15)** | 1.02 | 2093 | 60.2 | dep 200 · net **+47.24** · WR 33.9% · **reject** |
| 2026-05-20 | EDGE-4.1 | + H1 EMA(50) trend (close vs EMA) | 0.97 | 1507 | 81.0 | dep 200 · net **−59.18** · WR 32.9% · **reject** |
| 2026-05-20 | EDGE-4.2 | + ADX(14) **≥ 18** on M5 | 1.04 | 1977 | 42.6 | dep 200 · net **+101.68** · WR 34.4% · **reject** (≈P3-F) |
| 2026-05-20 | EDGE-4.3 | + ATR pct band **20–85** (100 bars) | 0.99 | 1453 | 50.4 | dep 200 · net **−15.74** · WR 33.5% · **reject** |
| 2026-05-20 | EDGE-4.4 | + bar-1 range cap **≤ 2× ATR** | **1.07** | 1706 | 40.0 | dep 200 · net **+161.20** · WR 35.2% · **keep** → production (superseded by 4.5) |
| 2026-05-20 | EDGE-4.5 | + BB width **≥ avg × 1.0** (chop skip) | **1.14** | 1305 | 25.0 | dep 200 · net **+241.63** · WR 36.7% · **keep** → **production** |
| 2026-05-20 | EDGE-5.1 | + cooldown after loss **90 min** | 1.09 | 1251 | 33.0 | dep 200 · net **+151.62** · WR 35.7% · **reject** |
| 2026-05-20 | EDGE-5.2 | + max **5** trades / broker day | 1.14 | 1305 | 25.0 | dep 200 · net **+241.63** · WR 36.7% · **reject** (≈P4-E) |
| 2026-05-20 | EDGE-5.3 | + daily DD block **3%** (was 5%) | 1.14 | 1305 | 25.0 | dep 200 · net **+241.63** · WR 36.7% · **reject** (≈P4-E) |
| 2026-05-20 | EDGE-5.5 | + post-streak **4** losses → **45 min** pause | **1.15** | 1302 | 23.0 | dep 200 · net **+247.68** · WR 36.8% · **keep** → **production** |
| 2026-05-20 | EDGE-6.1 | RR **1.5** (TP 300 pts) | 1.06 | 1414 | 32.2 | dep 200 · net **+99.51** · WR 41.7% · **reject** |
| 2026-05-20 | EDGE-6.4 | Dead-trade (+0.3R in 5 bars) | 1.09 | 1677 | 24.2 | dep 200 · net **+105.57** · WR 33.3% · **reject** |
| 2026-05-20 | EDGE-6.8 | BE at **+0.8R** | 1.03 | 1481 | 42.9 | dep 200 · net **+42.58** · WR 42.6% · **reject** |
| 2026-05-20 | EDGE-6.3 | BE at **+1.0R** | 1.07 | 1427 | 39.4 | dep 200 · net **+95.90** · WR 41.5% · **reject** |
| 2026-05-20 | EDGE-6.7 | Partial **40%** at **+1.2R** | 1.15 | 1302 | 23.0 | dep 200 · net **+247.68** · WR 36.8% · **reject** (≈P5-E) |
| 2026-05-20 | EDGE-6.2 | RR **2.5** (TP 500 pts) | 1.04 | 1178 | 36.0 | dep 200 · net **+60.12** · WR 29.6% · **reject** |
| 2026-05-20 | EDGE-6.5 | SL **150** pts (TP 300) | 1.01 | 1537 | 45.4 | dep 200 · net **+12.31** · WR 33.8% · **reject** |



---



## Phase 2 summary (2026-05-20)



| Filter | Verdict | Preset layer |

|--------|---------|--------------|

| Hours 8–17 | **keep** | P2-A |

| Struct break ≥0.15 ATR | **keep** (superseded by 3.4) | P2-B / P3-C |

| Struct break ≥**0.20** ATR | **keep** | P3-F layer (in P4-D) |
| Prior bar range ≤**2× ATR** | **keep** | P4-D layer (in P4-E) |
| BB width ≥**avg × 1.0** (chop skip) | **keep** | P4-E layer (in P5-E) |
| Post-streak **4** losses → **45 min** pause | **keep** | P5-E ← **production** |

| BB release w1/w2≥**1.10** | **keep** | P3-C layer (in P3-F) |

| Volume mult 1.15 | reject | P2-D |

| Session Asian breakout | reject | P2-E |



**Production:** `AEC.P4-E_bb-chop-skip_EDGE-4-5.set` · deposit **200** · PF **1.14** · net **+241.63** · 1305 trades · DD ~25%.

*(P4-D / T42: PF 1.07 · net +161 · DD ~40%.)*

*(Baseline P3-F / T13: PF 1.04 · net +103.71 · 2115 trades · DD ~52.6%.)*



---



## Phase 3 stack baseline (T13 / P3-F)



```

Symbol: EURUSD

Timeframe: M5

Date range: 2020.01.01 – 2026.05.19

Deposit: 200

Trades: 2115 (1041 long / 1074 short)

Net profit: +103.71

Profit factor: 1.04

Max DD %: ~52.6% equity

Win rate: ~34.4%

Avg win / avg loss: 4.01 / 2.03

Preset: P3-F (hours + struct **0.20** ATR + BB expand ≥1.10)

Verdict: EDGE-3.4 **keep** — replaces 0.15 struct layer in P3-C

```



*(T11 / P3-C: PF 1.03 · net +97.80 · DD ~50.9% — prior production.)*



---



## Current focus

**Production:** **P5-F** (T48) — P5-E + **block BUY [14,15)** · preset **`AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set`** · PF **1.17** · net **+271.30** · 1244 trades · DD **~24%**.

**Phase 7:** **complete** (7.1–7.3 · T49 buckets via script).

**Phase 8:** **complete**. **Phase 9:** **closed** — no promote · **P5-F** locked · forward **EDGE-9.x** deferred.

**Diagnostics:** `python scripts/p7d_mae_mfe_postprocess.py` after any test that writes `AEC_P7-D_deals.csv` (or per-preset deal file).


