# EDGE-AI-3.5 — SHAP readout (LightGBM v2)

Train rows (feature_join_ok=1): **759** · Model: `data/ai/model_lgbm.txt`

## Top 15 features (mean |SHAP|)

| Rank | Feature | mean \|SHAP\| | % of top-15 mass |
|-----:|---------|--------------:|-----------------:|
| 1 | `prior_bar_range_atr` | 0.0401 | 19.0% |
| 2 | `bb_width_vs_avg` | 0.0383 | 18.2% |
| 3 | `bb_expand_ratio` | 0.0376 | 17.9% |
| 4 | `struct_break_atr` | 0.0191 | 9.1% |
| 5 | `entry_hour` | 0.0174 | 8.2% |
| 6 | `displacement_atr` | 0.0165 | 7.8% |
| 7 | `entry_weekday` | 0.0107 | 5.1% |
| 8 | `entry_month` | 0.0098 | 4.6% |
| 9 | `is_buy` | 0.0082 | 3.9% |
| 10 | `atr_value` | 0.0077 | 3.7% |
| 11 | `spread_pts` | 0.0035 | 1.7% |
| 12 | `hour_x_buy` | 0.0017 | 0.8% |
| 13 | `loss_streak` | 0.0000 | 0.0% |
| 14 | `pass_bb` | 0.0000 | 0.0% |
| 15 | `pass_vol` | 0.0000 | 0.0% |

## Interpretation (actionable)

- **prior_bar_range_atr** — Very wide prior bar vs ATR may reduce take quality.
- **bb_width_vs_avg** — Favor releases where band width vs lookback avg is higher (not chop).
- **bb_expand_ratio** — Stronger bar-over-bar BB expansion on release improves L3 score.
- **struct_break_atr** — Deeper structure penetration (x ATR) associates with model confidence.
- **entry_hour** — Session hour still contributes after signal features.
- **displacement_atr** — Larger displacement body (x ATR) on signal bar matters.
- **entry_weekday** — Calendar weekday effect remains in v2 (secondary to BB/struct).
- **entry_month** — Seasonal/month bucket — weak alone, keep for regime work (AI-8).

## vs LightGBM gain (train)

| Feature | SHAP rank | Gain rank |
|---------|----------:|----------:|
| `prior_bar_range_atr` | 1 | 4 |
| `bb_width_vs_avg` | 2 | 1 |
| `bb_expand_ratio` | 3 | 2 |
| `struct_break_atr` | 4 | 3 |
| `entry_hour` | 5 | 8 |
| `displacement_atr` | 6 | 6 |
| `entry_weekday` | 7 | 5 |
| `entry_month` | 8 | 7 |
| `is_buy` | 9 | 10 |
| `atr_value` | 10 | 9 |

## Manual EDGE candidates (not auto-promoted)

1. **BB quality gate** — require `bb_width_vs_avg` and/or `bb_expand_ratio` above train median on L3=1 rows.
2. **Struct depth** — optional raise `InpMinStructBreakAtrMult` toward SHAP-favored penetration (test vs P3-F 0.20).
3. **Do not tune on holdout** — holdout AUC ~0.56; use SHAP for hypothesis only until 3.4 passes T71.

Regenerate: `python scripts/ai_shap_readout.py`
