# EDGE-AI-3.6 — Label comparison (L1–L4)

Model: LightGBM v2 features · train <= 2023 · tau grid 0.75–0.90

Baseline (no skip): net **271.64** · PF **1.1869** · 1148 trades

## Label definitions

| ID | Column | Rule |
|----|--------|------|
| **L1** | `label_L1_take` | net_profit > 0 (profitable close) |
| **L2** | `label_L2_take` | mfe_r >= 1.0 (reached 1R favorable) |
| **L3** | `label_L3_take` | not never-green loser (mfe_r < 0.2 on loss) |
| **L4** | `label_L4_take` | net_r >= 0.5 (~half R at close) |

`net_r` = `net_profit` / 2.0 (fixed R dollars for 0.01 lot / 200pt SL)

## Results

| Label | Train %+ | Hold %+ | Train AUC | Hold AUC | Best tau | Full net | Full PF | Hold net | T70 | T71 |
|-------|---------:|----------:|----------:|---------:|---------:|---------:|--------:|---------:|:---:|:---:|
| **L1** | 37.15 | 38.05 | 0.8092 | 0.5471 | None | None | None | None | n | n |
| **L2** | 52.83 | 53.47 | 0.6634 | 0.4881 | None | None | None | None | n | n |
| **L3** | 83.53 | 81.49 | 0.8567 | 0.5562 | 0.82 | 382.03 | 1.3569 | 99.87 | Y | n |
| **L4** | 37.15 | 38.05 | 0.8092 | 0.5471 | None | None | None | None | n | n |

## Recommendation

- **No label beat T70+T71** on holdout at useful tau — keep production **L3** + v1 logistic gate.
- Best **T70-only** offline: **L3** at tau=0.82 (full net 382.03) — overfit risk on holdout.

Regenerate: `python scripts/ai_compare_labels.py`
