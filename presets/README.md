# AEC tester presets



Load **one preset per backtest**. Archive outputs before loading the next preset.



**Workflow:** [doc/test-results-log.md](../doc/test-results-log.md)  

**Source of truth:** `MQL5/Experts/AEC/presets/tester/`  
**Strategy Tester Load dropdown:** `MQL5/Profiles/Tester/` — run sync (below), do not copy by hand.



---



## Production (live / chart preset)

| Preset | Test | Notes |
|--------|------|-------|
| **`AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set`** | **T70** | **Production (EDGE-AI-4)** · P5-F + AI skip τ=0.45 · see `doc/edge-8-3-production-lock.md` |
| **`AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set`** | **T74** | P5-F · 2010–2026 · no AI · era baseline · [edge-ai-8-runbook.md](../doc/edge-ai-8-runbook.md) |
| **`AEC.P11-A_regime-gate_EDGE-AI-8-T75.set`** | **T75** | P10-B + ATR pct + ADX · regime gate test |
| `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set` | **T48** | Prior production (baseline, no AI) |

## OOS / research backtests

| Preset | Test | Notes |
|--------|------|-------|
| **`AEC.P8-A_oos-train_EDGE-8-1.set`** | **T50** | **OOS train** 2020–2023 (EDGE-8.1) |
| **`AEC.P8-B_oos-holdout_EDGE-8-1.set`** | **T51** | **OOS holdout** 2024–2026 (P5-F, no AI) |
| **`AEC.P10-C_ai-skip-holdout_EDGE-AI-4.set`** | **T71** | Holdout with AI gate (vs T51) |
| **`AEC.P9-A_block-hour-16_EDGE-5-7.set`** | **T59** | Phase 9 · P5-F + exclude hour **16** (reject) |
| `AEC.P8-WF-YYYY_EDGE-8-2.set` | optional | Per-year WF (strict); not required after 8.2 script PASS |
| `AEC.P5-E_post-streak-4loss-45min_EDGE-5-5.set` | **T36** | Prior production (superseded by T48) |
| `AEC.P7-D_mae-mfe-export_EDGE-7-3.set` | **T49** | Research: P5-F + deal/MAE/MFE export (EDGE-7.3) |
| **`AEC.P10-A_ai-dataset-full_EDGE-AI-0.set`** | **T72** | **AI-0 export** · P5-F + `AEC_P10-A_deals.csv` (EDGE-AI-0) |

Compare new layers vs **P5-E** (not P4-E). Baselines: **P4-E** (T43) · **P4-D** (T42) · **P3-F** (T13).

---

## Quick pick (run in order for Phase 0)



| Order | Preset | Test ID | Edge task |

|-------|--------|---------|-----------|

| 1 | `AEC.P0-B_force-sell_EDGE-0-1.set` | **T01** | SELL exec proof |

| 2 | `AEC.P0-C_force-buy_EDGE-0-1.set` | **T02** | BUY exec proof |

| 3 | `AEC.P0-A_baseline-diag_EDGE-0-1.set` | **T03** | EDGE-0.1 main |

| 4 | `AEC.RAW_baseline_LTF.set` | **T04** | Baseline / EDGE-0.2 |

| — | `AEC.SAFE_chart-no-trade.set` | — | Post-compile chart only |



---



## One test at a time



1. **F7** compile  

2. Load **one** preset  

3. Set dates → **Start**  

4. Save report + CSVs → `doc/data/Txx/` (see test-results-log)  

5. Log row in test-results-log  

6. **Then** load the next preset  



Each preset uses **dedicated output filenames** so runs never overwrite each other.



---



## Outputs by preset



| Preset | Decisions CSV | Diag CSV |

|--------|---------------|----------|

| P0-A | `AEC_P0-A_decisions.csv` | `AEC_P0-A_diag_summary.csv` |

| P0-B | `AEC_P0-B_decisions.csv` | `AEC_P0-B_diag_summary.csv` |

| P0-C | `AEC_P0-C_decisions.csv` | `AEC_P0-C_diag_summary.csv` |

| RAW | — | — |
| P4-D | `AEC_P4-D_decisions.csv` | `AEC_P4-D_diag_summary.csv` |
| P4-E | `AEC_P4-E_decisions.csv` | `AEC_P4-E_diag_summary.csv` |
| P5-A | `AEC_P5-A_decisions.csv` | `AEC_P5-A_diag_summary.csv` |
| P5-B | `AEC_P5-B_decisions.csv` | `AEC_P5-B_diag_summary.csv` |
| P5-C | `AEC_P5-C_decisions.csv` | `AEC_P5-C_diag_summary.csv` |
| P5-D | `AEC_P5-D_decisions.csv` | `AEC_P5-D_diag_summary.csv` |
| P5-E | `AEC_P5-E_decisions.csv` | `AEC_P5-E_diag_summary.csv` |
| P5-F | `AEC_P5-F_decisions.csv` | `AEC_P5-F_diag_summary.csv` |
| P6-A | `AEC_P6-A_decisions.csv` | `AEC_P6-A_diag_summary.csv` |
| P6-B | `AEC_P6-B_decisions.csv` | `AEC_P6-B_diag_summary.csv` |
| P6-C | `AEC_P6-C_decisions.csv` | `AEC_P6-C_diag_summary.csv` |
| P6-D | `AEC_P6-D_decisions.csv` | `AEC_P6-D_diag_summary.csv` |
| P6-E | `AEC_P6-E_decisions.csv` | `AEC_P6-E_diag_summary.csv` |
| P6-F | `AEC_P6-F_decisions.csv` | `AEC_P6-F_diag_summary.csv` |
| P6-G | `AEC_P6-G_decisions.csv` | `AEC_P6-G_diag_summary.csv` |
| P6-H | `AEC_P6-H_decisions.csv` | `AEC_P6-H_diag_summary.csv` |
| P7-A | `AEC_P7-A_decisions.csv` | `AEC_P7-A_diag_summary.csv` (+ `AEC_P7-A_deals.csv`, `AEC_P7-A_segments.csv`) |
| P7-B | `AEC_P7-B_decisions.csv` | **`AEC_P7-B_diag_summary.csv`** (EDGE-7.2 / T30) |
| P7-C | `AEC_P7-C_decisions.csv` | `AEC_P7-C_diag_summary.csv` (optional P2-C baseline) |
| P7-D | `AEC_P7-D_decisions.csv` | `AEC_P7-D_deals.csv` + `AEC_P7-D_segments.csv` + **`AEC_P7-D_mae_mfe_buckets.csv`** (T49) |
| P8-A | `AEC_P8-A_decisions.csv` | `AEC_P8-A_train_deals.csv` + `AEC_P8-A_train_segments.csv` (T50) |
| P8-B | `AEC_P8-B_decisions.csv` | `AEC_P8-B_holdout_deals.csv` + `AEC_P8-B_holdout_segments.csv` (T51) |
| P9-A | `AEC_P9-A_decisions.csv` | `AEC_P9-A_deals.csv` + `AEC_P9-A_segments.csv` (T59 / EDGE-5.7) |



Files appear under `MQL5/Files/` (live) or tester agent `Files/` folder.



---



## Naming convention



```

AEC.<context>_<detail>_<task-id>.set

```



When adding Phase 2+ presets, assign the next **Txx** ID in test-results-log.



---



## Sync presets into Strategy Tester (required once per session / after git pull)

```powershell
cd MQL5\Experts\AEC
.\scripts\sync_tester_presets.ps1
```

Copies all `AEC*.set` from `presets/tester/` → `MQL5/Profiles/Tester/` (only changed files).  
**T74 / T75 checklist:** [doc/edge-ai-8-t74-t75-checklist.md](../doc/edge-ai-8-t74-t75-checklist.md)


