# EDGE-AI-3.3 / 3.4 — LightGBM train + threshold sweep

## Prerequisites

```bash
pip install -r requirements-ai.txt
python scripts/ai_build_dataset.py
```

## Train (3.3)

```bash
python scripts/ai_train_lgbm.py
```

Outputs:

| File | Purpose |
|------|---------|
| `data/ai/model_lgbm.txt` | LightGBM model |
| `data/ai/model_lgbm.json` | Feature list + metadata |
| `data/ai/train_metrics_lgbm.json` | AUC / importance |

**Features (26):** clock (`entry_hour`, `entry_weekday`, `entry_month`, `is_buy`) + signal-bar columns from P10-E export. **`ai_prob_take` excluded** (v1 gate score).

## Sweep (3.4)

```bash
python scripts/ai_simulate_thresholds_v2.py
```

Default tau grid **0.75–0.90** (v2 scores are compressed ~0.78–0.86 on this dataset).

Outputs: `threshold_sweep_v2.csv`, `threshold_sweep_v2_summary.json`.

## P10-E offline result (2026-05-23)

| Item | Value |
|------|--------|
| Train AUC | 0.86 (n=759) |
| Holdout AUC | 0.56 (n=389) — weak generalization |
| Top features | `bb_width_vs_avg`, `bb_expand_ratio`, `struct_break_atr` |
| Best tau vs **T70** only | **0.82** — full net ~390, PF ~1.36, 898 trades |
| **T70+T71 bar** | **No tau passed** (holdout net &lt; T71 at useful skip rates) |
| v1 logistic | tau **0.45** still production baseline |

**Verdict:** Do **not** promote to MQL5 gate v2 (3.7) without new features, labels, or holdout-valid tuning. Keep **P10-B** v1 gate.

## Next

- **3.5** SHAP readout — `python scripts/ai_shap_readout.py` → [edge-ai-3-5-shap-readout.md](./edge-ai-3-5-shap-readout.md)
- **3.6** L1–L4 labels — `python scripts/ai_compare_labels.py` → [edge-ai-3-6-label-comparison.md](./edge-ai-3-6-label-comparison.md)
- **3.6** L2/L4 label comparison
- **8.x** regime gate (parallel track)
