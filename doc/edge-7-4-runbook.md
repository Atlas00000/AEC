# EDGE-7.4 — Never-green % by entry hour

Script-only (no backtest). Uses **mfe_r** from EDGE-7.3 post-process.

**Rule:** `loser_never_green` = net &lt; 0 and **mfe_r &lt; 0.2**

---

## Run

```bash
pip install MetaTrader5
python scripts/p7d_mae_mfe_postprocess.py --deals path/to/deals.csv   # if no mfe_r yet
python scripts/edge_7_4_never_green_by_hour.py
```

Default inputs: `AEC_P8-A_train_deals.csv` + `AEC_P8-B_holdout_deals.csv` (T50+T51, P5-F stack).

Output: `AEC_edge_7_4_never_green_by_hour.csv` in tester `MQL5/Files/`.

---

## How to use output

| Column | Meaning |
|--------|---------|
| `never_green_pct_of_losses` | % of losing trades that never reached 0.2R MFE |
| `net` / `profit_factor` | Hour P/L (cross-check EDGE-7.1 segments) |

**Pick one hour gate for Phase 9** (e.g. **EDGE-5.7**): prefer hours with **high NG%** and **weak net** · enough trades (≥15).

Do **not** block hours with high never-green but **strong net** (e.g. h13 BUY was profitable in 7.1).

---

## Result (2026-05-21) — **done**

Source: T50+T51 deals (**1249** trades) with **mfe_r** · `AEC_edge_7_4_never_green_by_hour.csv`

| Hour | Trades | Losses | Never-green | NG% of losses | Net | PF |
|------|-------:|-------:|------------:|--------------:|----:|---:|
| 8 | 217 | 139 | 42 | 30.2% | +29.08 | 1.10 |
| 9 | 119 | 74 | 22 | 29.7% | +30.79 | 1.21 |
| 10 | 110 | 66 | 18 | 27.3% | +43.98 | 1.33 |
| 11 | 143 | 88 | 21 | 23.9% | +43.09 | 1.24 |
| 12 | 179 | 114 | 28 | 24.6% | +27.36 | 1.12 |
| 13 | 211 | 134 | 41 | 30.6% | +40.29 | 1.15 |
| 14 | 77 | 49 | 15 | 30.6% | +13.32 | 1.13 |
| 15 | 140 | 86 | 20 | 23.3% | +43.54 | 1.25 |
| **16** | **45** | **32** | **13** | **40.6%** | **−12.10** | **0.81** |
| 17 | 8 | 3 | 0 | 0.0% | +13.99 | 3.32 |

**Recommendation for EDGE-5.7:** block **hour 16** (only hour with **net &lt; 0** and **PF &lt; 1** in 8–17 window; highest NG% among traded hours).

**Do not block h13–h15** on never-green alone — positive net despite ~30% NG. **Do not repeat** coarse BUY block [13,15) (EDGE-5.4 reject).

*Note: aggregate NG% (~28%) differs from T49 bucket script (~46%) if mfe_r source differs; use **relative hour ranks** for gating.*
