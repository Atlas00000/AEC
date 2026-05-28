# EDGE-AI-0 / 1 / 2 — Offline ML pipeline (no MT5 rerun)

Run from the **AEC** repo folder after deal CSVs exist (P10-A, P7-D, or P8-A/B with `mfe_r`).

**Backtest (export):** load **`AEC.P10-A_ai-dataset-full_EDGE-AI-0.set`** · EURUSD M5 · deposit 200 · dates **2020.01.01 – 2026.05.19** · expect metrics ≈ T48. Copy preset to `MQL5/Profiles/Tester/` if missing from dropdown.

```bash
pip install -r requirements-ai.txt
python scripts/ai_build_dataset.py
python scripts/ai_train_skip_model.py
python scripts/ai_simulate_thresholds.py
```

**Inputs (tester `MQL5/Files/`):**

- `AEC_P8-A_train_deals.csv` + `AEC_P8-B_holdout_deals.csv` (best OOS split), or
- `AEC_P10-A_deals.csv` from **P10-A** one-shot full range, or
- `AEC_P7-D_deals.csv` (split by year)

If `mfe_r` missing: `python scripts/p7d_mae_mfe_postprocess.py`

**Outputs (`data/ai/`):**

| File | Phase |
|------|--------|
| `aec_trades_ml.csv` | AI-0 |
| `model_sklearn.json` | AI-1 |
| `threshold_sweep.csv` | AI-2 |

Schema: [ai-data-schema.md](./ai-data-schema.md) · Roadmap: [aiimplmentation.md](./aiimplmentation.md)

**Promote to MT5 (AI-4)** only if AI-2 finds a tau with full net/PF ≥ T48 and holdout PASS.

**AI-4 implemented:** recompile EA → run **T70** / **T71** per [edge-ai-4-runbook.md](./edge-ai-4-runbook.md).
