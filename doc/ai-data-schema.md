# EDGE-AI-0 — ML dataset schema

One row = **one closed trade** from `AEC_*_deals.csv` (P5-F stack). No bar-0 or post-entry features in the feature vector.

---

## Source files

| Priority | File | Split |
|----------|------|--------|
| 1 | `AEC_P8-A_train_deals.csv` | train |
| 2 | `AEC_P8-B_holdout_deals.csv` | holdout |
| 3 | `AEC_P7-D_deals.csv` | full (split by `entry_year`) |

Built by: `python scripts/ai_build_dataset.py`

---

## Raw columns (from EA export)

| Column | Type | Notes |
|--------|------|--------|
| `close_time` | datetime | `YYYY.MM.DD HH:MM:SS` |
| `entry_time` | datetime | |
| `entry_hour` | int | Broker hour 0–23 |
| `entry_weekday` | int | 0=Sun … 6=Sat (MT5) |
| `entry_month` | int | 1–12 |
| `direction` | str | `BUY` / `SELL` |
| `net_profit` | float | Includes swap + commission |
| `profit` | float | |
| `swap` | float | |
| `commission` | float | |
| `volume` | float | |
| `mfe_r` | float | Requires export or post-process |
| `mae_r` | float | |
| `deal_id` | int | |
| `position_id` | int | |
| `symbol` | str | |

---

## Derived columns (Python)

| Column | Definition |
|--------|------------|
| `entry_year` | Year from `entry_time` |
| `split` | `train` if year ≤ 2023 else `holdout` (override if source file is P8-A/B) |
| `is_buy` | 1 if `direction == BUY` |
| `net_r` | `net_profit / 2.0` (fixed R$ for 0.01 lot · 200pt SL) |
| `label_L1_take` | 1 if `net_profit > 0` |
| `label_L2_take` | 1 if `mfe_r >= 1.0` |
| `label_L3_take` | 1 if NOT (`net_profit < 0` and `mfe_r < 0.2`) — skip never-green losers |
| `label_L4_take` | 1 if `net_r >= 0.5` |
| `label_never_green` | 1 if loser and `mfe_r < 0.2` |
| `label_fought` | 1 if loser and `mfe_r >= 0.5` |
| `mfe_bin` | T49 bins: 0-0.3, … 1.5+ |

---

## Model features (v1 — no leg export yet)

| Feature | Source |
|---------|--------|
| `entry_hour` | raw |
| `entry_weekday` | raw |
| `entry_month` | raw |
| `is_buy` | derived |
| `hour_x_buy` | optional interaction |

**v2 (EDGE-AI-3.1 / 3.2):** from `AEC_*_signal_features.csv` — join to deals on `(entry_time, direction)` where `entry_time = signal_time + bar_minutes` (M5 → **5**).

| Column | Type | Notes |
|--------|------|--------|
| `signal_time` | datetime | Bar 1 open time (shift 1) |
| `symbol` | str | |
| `direction` | str | BUY / SELL |
| `outcome` | str | `executed`, `ai_skip`, `hour_blocked`, … |
| `spread_pts` | int | At signal |
| `ai_prob_take` | float | P(L3_take) when AI on |
| `loss_streak` | int | Consecutive losses |
| `entry_hour` / `entry_weekday` / `entry_month` | int | Broker time of signal bar |
| `is_buy` | 0/1 | |
| `pass_bb` … `pass_prior_bar` | 0/1 | Leg flags for signal direction |
| `bb_expand_ratio` | float | w1/w2 |
| `bb_width_vs_avg` | float | w1 / lookback avg |
| `squeeze_bars` | int | Consecutive compressed bars before release |
| `struct_break_atr` | float | Penetration past swing / ATR |
| `displacement_atr` | float | Body / ATR on signal bar |
| `prior_bar_range_atr` | float | H-L bar 1 / ATR |
| `atr_value` | float | ATR on bar 1 |
| `atr_percentile` | float | 0–100 when `InpUseAtrPercentileBand` |
| `adx_value` | float | When `InpUseAdxMinFilter` |

Preset: **`AEC.P10-E_ml-csv-export_EDGE-AI-3-1.set`** (or legacy `P10-D`). Shadow rows (`outcome` ≠ `executed`) when `InpExportSignalFeaturesShadow=true`.

---

## Labels for training (default)

| ID | Target column | Model predicts |
|----|---------------|--------------|
| **L3** (default) | `label_L3_take` | P(good entry) — veto when P &lt; τ |
| **L1** | `label_L1_take` | P(profitable) |
| **L2** | `label_L2_take` | P(reached 1R MFE) |
| **L4** | `label_L4_take` | P(net_r ≥ 0.5) |

Compare: `python scripts/ai_compare_labels.py` → `doc/edge-ai-3-6-label-comparison.md`

**Do not use** `mfe_r` / `mae_r` / `net_profit` as features — leakage for entry-time model.

---

## Output artifacts (EDGE-AI-3.2)

| File | Purpose |
|------|---------|
| `data/ai/aec_trades_ml.csv` | One row per closed trade + v2 signal features |
| `data/ai/aec_trades_train.csv` | Train split (year ≤ 2023) |
| `data/ai/aec_trades_holdout.csv` | Holdout split |
| `data/ai/aec_signals_ml.csv` | All chain-pass rows (executed + shadow) |
| `data/ai/dataset_summary.json` | Schema v1/v2, join counts, label rates |

Extra v2 columns on trades: `feature_join_ok`, `hour_x_buy`, plus `SIGNAL_FEATURE_MERGE_COLS` in `scripts/ai_common.py`.

Large files are gitignored; regenerate locally.
