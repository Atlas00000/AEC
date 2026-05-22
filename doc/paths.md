# AEC — standard paths (this machine)

Use these when sharing test output — no need to paste full paths each time.

**Terminal ID:** `D0E8209F77C8CF37AD8BF550E51FF075`  
**Strategy Tester agent:** `Agent-127.0.0.1-3000` (local agent; port may change if you restart tester)

---

## Strategy Tester outputs (primary)

| What | Path |
|------|------|
| **Tester log (daily)** | `%AppData%\MetaQuotes\Tester\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\logs\YYYYMMDD.log` |
| **EA CSV / diag files** | `%AppData%\MetaQuotes\Tester\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files\` |

### Expanded (copy-paste)

**Logs**
```
C:\Users\emili\AppData\Roaming\MetaQuotes\Tester\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\logs\
```

**Files** (decisions CSV, diag summary CSV)
```
C:\Users\emili\AppData\Roaming\MetaQuotes\Tester\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files\
```

---

## Project / source code

```
C:\Users\emili\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AEC\
```

| Item | Relative path |
|------|----------------|
| Main EA | `AEC.mq5` |
| Presets | `presets\tester\` |
| Docs | `doc\` |
| Archive test results | `doc\data\T01\`, `T02\`, … |

---

## Live terminal Files (not tester)

When EA runs on a **chart** (not tester), CSVs go here instead:

```
C:\Users\emili\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\
```

---

## Per-test filenames (after preset load)

| Test ID | Decisions CSV | Diag CSV |
|---------|---------------|----------|
| T01 | `AEC_P0-B_decisions.csv` | `AEC_P0-B_diag_summary.csv` |
| T02 | `AEC_P0-C_decisions.csv` | `AEC_P0-C_diag_summary.csv` |
| T03 | `AEC_P0-A_decisions.csv` | `AEC_P0-A_diag_summary.csv` |
| T47 | `AEC_P7-A_deals.csv` | `AEC_P7-A_segments.csv` (EDGE-7.1) |
| T49 | `AEC_P7-D_deals.csv` (+ mfe_r/mae_r) | `AEC_P7-D_mae_mfe_buckets.csv` (EDGE-7.3) |
| T50 | `AEC_P8-A_train_deals.csv` | `AEC_P8-A_train_segments.csv` (EDGE-8.1 train) |
| T51 | `AEC_P8-B_holdout_deals.csv` | `AEC_P8-B_holdout_segments.csv` (EDGE-8.1 holdout) |
| 7.4 | — | `AEC_edge_7_4_never_green_by_hour.csv` |
| T59 | `AEC_P9-A_deals.csv` | `AEC_P9-A_segments.csv` (EDGE-5.7 full range) |
| T60 | `AEC_P9-A_holdout_deals.csv` (or same prefix, holdout dates) | segments (EDGE-5.7 holdout) |
| T61 | `AEC_P9-B_deals.csv` | `AEC_P9-B_segments.csv` (EDGE-6.9 give-back) |
| T63 | `AEC_P9-C_deals.csv` | `AEC_P9-C_segments.csv` (EDGE-6.10 partial @ 1R) |
| T64 | `AEC_P9-D_deals.csv` | `AEC_P9-D_segments.csv` (EDGE-6.11 soft never-green) |
| T65 | `AEC_P9-E_deals.csv` | `AEC_P9-E_segments.csv` (EDGE-3.17a BB 1.12) |
| T66 | `AEC_P9-F_deals.csv` | `AEC_P9-F_segments.csv` (EDGE-3.17b squeeze 4) |

If you see generic `AEC_decisions.csv` / `AEC_diag_summary.csv`, the run used **older inputs** — still valid; reload preset before next test.

---

## Quick reference for chat

You can say: **“T01 files in Tester Agent Files”** or **“today’s log in Tester logs”** — paths above apply.
