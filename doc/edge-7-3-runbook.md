# EDGE-7.3 — MAE/MFE taxonomy runbook

Tracks **max favorable / adverse excursion in R** (vs entry SL risk) per position, then writes bucket PF/net.

**Stack:** production **P5-F** (same as T48).

---

## Run (T49)

### Option A — Post-process (recommended if deals CSV already exists)

No Strategy Tester rerun. Uses existing **`AEC_P7-D_deals.csv`** + MT5 history + M5 bars.

1. Keep **MT5** open (tester history still loaded).
2. `pip install MetaTrader5`
3. `python scripts/p7d_mae_mfe_postprocess.py`

See **`scripts/README.md`**. Writes enriched deals + buckets to Tester `MQL5/Files/`.

### Option B — In-test export (EA)

1. **F7** compile (`AEC v1.01` in journal).
2. Load **`AEC.P7-D_mae-mfe-export_EDGE-7-3.set`**.
3. **EURUSD M5** · **2020.01.01–2026.05.19** · deposit **200**.
4. Journal:
   - `Deal export: N closes maeMfe=on -> ...`
   - `MAE/MFE buckets: M positions -> AEC_P7-D_mae_mfe_buckets.csv`
5. Files in Tester `MQL5/Files/`:

| File | Content |
|------|---------|
| `AEC_P7-D_deals.csv` | Per close + **`mfe_r`** **`mae_r`** columns |
| `AEC_P7-D_segments.csv` | Hour/weekday/month PF (7.1) |
| `AEC_P7-D_mae_mfe_buckets.csv` | Taxonomy + bins (7.3) |

Archive → `doc/data/T49/`.

---

## Bucket taxonomy (losers)

| bucket_key | Rule |
|------------|------|
| `loser_never_green` | net &lt; 0 and **mfe_r &lt; 0.2** |
| `loser_fought_mfe05` | net &lt; 0 and **mfe_r ≥ 0.5** |
| `loser_other` | other losses |

**MFE bins (all trades):** `0-0.3` · `0.3-0.6` · `0.6-1.0` · `1.0-1.5` · `1.5+`  
**MAE bins (losses only):** `0-0.5` · `0.5-1.0` · `1.0+`

---

## How to read results

- High **`loser_never_green`** share → entry quality issue (aligns with MAE corr ~0.83).
- High **`loser_fought_mfe05`** → trades went green then lost → exit/timing, not pure entry filter.
- Winners in **`mfe_bin` `1.5+`** with good net → TP capture working.

**Not a production toggle** — `InpExportMaeMfe=false` on live presets.
