# EDGE-AI-3.1 — Signal-bar feature export

**Recompile** `AEC.ex5` after pulling this change.

**Preset location:** MT5 only lists files under  
`Terminal\<hash>\MQL5\Profiles\Tester\`  
Copy from repo `Experts\AEC\presets\tester\` after adding a new `.set` (compile does not copy presets).

## Run backtest

| Item | Value |
|------|--------|
| Preset | **`AEC.P10-E_ml-csv-export_EDGE-AI-3-1.set`** (use this; not P10-B) |
| Symbol / TF | EURUSD M5 |
| Dates | 2020.01.01 – 2026.05.19 (or full range for T73-style) |
| Deposit / lot | 200 / 0.01 |

### After loading preset — verify Inputs

| Input | Must be |
|-------|---------|
| Export signal-bar features | **true** |
| Export signal features shadow | **true** |
| Export closed deals | **true** |
| Track MAE/MFE in R | **true** |
| Optional CSV decision log | **false** |

`P10-B` does **not** set export inputs → compile defaults stay **off** → you only get `*_decisions.csv` if you turned logging on manually.

## Outputs (tester `MQL5/Files/`)

| File | Content |
|------|---------|
| `AEC_P10-E_signal_features.csv` | One row per **chain pass** with `outcome` |
| `AEC_P10-E_deals.csv` | Closed trades (for join in AI-3.2) |
| `AEC_P10-E_segments.csv` | PF segments (optional) |
| `AEC_P10-E_mae_mfe_buckets.csv` | MAE/MFE buckets (optional) |

Legacy preset `P10-D` writes the same flags under `AEC_P10-D_*` filenames.

### `outcome` values

| Value | Meaning |
|-------|---------|
| `executed` | Order opened |
| `ai_skip` | AI gate blocked |
| `hour_blocked` | Hour direction filter |
| `no_room` / `max_trades_day` / `validation_fail` / `open_fail` / … | Later funnel blocks |

With **`InpExportSignalFeaturesShadow=true`** (default in P10-E), all outcomes are logged. Set **`false`** to log only `executed` rows.

## Journal check

On deinit you should see:

`Signal feature export: <N> rows -> AEC_P10-E_signal_features.csv`

**N** should be well above trade count (includes `ai_skip` and other shadow rows).

## Join key (AI-3.2)

On **M5**: `deals.entry_time` = `signal_time` + **5 minutes** (signal bar open → entry on next bar). Join also on `direction`.

```bash
python scripts/ai_build_dataset.py
# or explicit:
python scripts/ai_build_dataset.py --deals AEC_P10-E_deals.csv --features AEC_P10-E_signal_features.csv --bar-minutes 5
```

Outputs: `data/ai/aec_trades_ml.csv` (v2, 1148 rows) · `aec_signals_ml.csv` (all funnel rows) · `dataset_summary.json`.

## Next

**EDGE-AI-3.3** — train LightGBM on v2 features (train ≤ 2023).
