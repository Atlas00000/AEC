# Phase 0 runbook — diagnostics



**One preset · one backtest · archive · next.**  

Full discipline: [test-results-log.md](./test-results-log.md)



**Presets:** `presets/tester/`



---



## Before each test



1. Confirm previous test outputs are saved under `doc/data/Txx/`

2. Load **only** the preset for this step

3. Do not reuse a old tester report tab without saving first



---



## Sequence (do not skip archiving between steps)



### T01 — SELL execution proof



| | |

|--|--|

| **Preset** | `AEC.P0-B_force-sell_EDGE-0-1.set` |

| **Symbol / TF** | EURUSD M5 |

| **Dates** | 1 week |

| **Archive to** | `doc/data/T01/` |

| **Pass** | CSV shows `SELL` + `OK` |



Files: `AEC_P0-B_decisions.csv`, `AEC_P0-B_diag_summary.csv`



---



### T02 — BUY execution proof



| | |

|--|--|

| **Preset** | `AEC.P0-C_force-buy_EDGE-0-1.set` |

| **Dates** | 1 week |

| **Archive to** | `doc/data/T02/` |

| **Pass** | CSV shows `BUY` + `OK` |



---



### T03 — Leg diagnostic (EDGE-0.1 main)



| | |

|--|--|

| **Preset** | `AEC.P0-A_baseline-diag_EDGE-0-1.set` |

| **Dates** | Full baseline window |

| **Archive to** | `doc/data/T03/` |

| **Pass** | Journal `DIAG summary` · check `exec_sell` in diag CSV |



Files: `AEC_P0-A_decisions.csv`, `AEC_P0-A_diag_summary.csv`



**Interpret diag CSV:**



| Pattern | Meaning |

|---------|---------|

| `exec_sell > 0` | Sell pipeline OK |

| `full_sell = 0`, low sell legs | Signal alignment issue |

| Force tests OK, `exec_sell = 0` | Natural chain never sells |



---



### T04 — Raw baseline (EDGE-0.2)



| | |

|--|--|

| **Preset** | `AEC.RAW_baseline_LTF.set` |

| **Dates** | Same as T03 |

| **Archive to** | `doc/data/T04/` |

| **Pass** | `report.html` saved for segmentation |



---



### T05 — Hours gate (EDGE-2.1)



| | |

|--|--|

| **Preset** | `AEC.P2-A_hours-8-17_EDGE-2-1.set` |

| **Dates** | 2020.01.01 – 2026.05.19 (same as T04) |

| **Archive to** | `doc/data/T05/` |

| **Pass** | Report saved · PF 0.96 · DD 9.7% · **keep** hours filter |



---



### T06 — Structure break distance (EDGE-2.2)



| | |

|--|--|

| **Preset** | `AEC.P2-B_struct-break-atr015_EDGE-2-2.set` |

| **Dates** | 2020.01.01 – 2026.05.19 |

| **Deposit** | **200** |

| **Archive to** | `doc/data/T06/` |

| **Pass** | PF 0.99 · WR 33.2% · **keep** struct break filter |



---



### T07 — BB release quality (EDGE-2.3)



| | |

|--|--|

| **Preset** | `AEC.P2-C_bb-release-expand108_EDGE-2-3.set` |

| **Dates** | 2020.01.01 – 2026.05.19 |

| **Deposit** | **200** |

| **Archive to** | `doc/data/T07/` |

| **Pass** | PF **1.01** · net **+43.49** · **keep** BB release filter |



---



### T08 — Volume tier 1.15+ (EDGE-2.4)



| | |

|--|--|

| **Preset** | `AEC.P2-D_volume-tier115_EDGE-2-4.set` |

| **Dates** | 2020.01.01 – 2026.05.19 |

| **Deposit** | **200** |

| **Archive to** | `doc/data/T08/` |

| **Pass** | **reject** — PF 1.00 · net -5.30 · keep P2-C volume 1.05 |

| **Note** | No recompile — preset only (`InpVolumeMultiplier=1.15`) |



---



### T09 — Session overlap defaults (EDGE-2.5)



| | |

|--|--|

| **Preset** | `AEC.P2-E_session-overlap_EDGE-2-5.set` |

| **Dates** | 2020.01.01 – 2026.05.19 |

| **Deposit** | **200** |

| **Archive to** | `doc/data/T09/` |

| **Pass** | **reject** — PF 0.94 · net -106.48 · session off in production |

| **Note** | Session leg on · Asian range [0,8) breakout required |



---



## EDGE-0.3 / 0.4



Use **T04 report** (+ T03 diag if needed). Log findings in [edge-discovery.md](./edge-discovery.md).



---



## Current focus

**Next test:** **EDGE-3.1** / T10 — see [edge-discovery.md](./edge-discovery.md).


