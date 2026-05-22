# AEC scripts

## EDGE-7.3 — MAE/MFE without rerunning Strategy Tester

After a P7-D backtest, you already have `AEC_P7-D_deals.csv` and segments. To add **`mfe_r` / `mae_r`** and **`AEC_P7-D_mae_mfe_buckets.csv`** in ~1–2 minutes:

1. Leave **MetaTrader 5** open (same terminal where you ran the tester — history must still be loaded).
2. Install once: `pip install MetaTrader5`
3. From the `AEC` folder:

```bash
python scripts/p7d_mae_mfe_postprocess.py
```

Outputs overwrite/enrich files in the tester `MQL5/Files/` folder (same paths as the EA export).

Custom paths:

```bash
python scripts/p7d_mae_mfe_postprocess.py --deals "C:\...\AEC_P7-D_deals.csv" --out-dir "C:\...\MQL5\Files"
```

**Logic:** M5 bar high/low between `entry_time` and `close_time`, R = `InpStopLossPoints` (200) × point — matches `MaeMfeTracker::RebuildFromHistory`.

**When to rerun the tester instead:** only if you changed strategy code/inputs and need new trades, or tester history was cleared.

## EDGE-8.1 — OOS summary

After **T50** (train) and **T51** (holdout) backtests:

```bash
python scripts/oos_8_1_summarize.py
```

See [doc/edge-8-1-runbook.md](../doc/edge-8-1-runbook.md).

## EDGE-8.2 — Walk-forward by year

After **T50** + **T51**:

```bash
python scripts/wf_8_2_summarize.py
```

See [doc/edge-8-2-runbook.md](../doc/edge-8-2-runbook.md). Production lock: [doc/edge-8-3-production-lock.md](../doc/edge-8-3-production-lock.md).

## EDGE-7.4 — Never-green by hour

```bash
python scripts/edge_7_4_never_green_by_hour.py
```

See [doc/edge-7-4-runbook.md](../doc/edge-7-4-runbook.md). Output: `AEC_edge_7_4_never_green_by_hour.csv`.
