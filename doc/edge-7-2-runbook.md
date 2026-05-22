# EDGE-7.2 — Signal leg diagnostics runbook

Counts how often each **signal leg** passes vs **full AND chain** vs **executed** orders. No strategy change — diagnostics only.

---

## Run (T30 — required)

1. **F7** compile AEC.
2. Load **`AEC.P7-B_diag-p5f_EDGE-7-2.set`** (production **P5-F** stack).
3. **EURUSD M5** · **2020.01.01–2026.05.19** · deposit **200** · lot **0.01**.
4. Backtest should finish with metrics **≈ T48** (PF ~1.17 · ~1244 trades).
5. Journal: line starting with `DIAG summary bars=...`
6. File: **`AEC_P7-B_diag_summary.csv`** in Tester `MQL5/Files/`.

Archive → `doc/data/T30/`.

---

## Optional (T30b) — Phase 2 baseline

Same dates with **`AEC.P7-C_diag-p2c_EDGE-7-2.set`** (P2-C / T07-era stack, struct **0.15** ATR). Output: **`AEC_P7-C_diag_summary.csv`**. Compare leg funnel drift vs early stack.

---

## CSV metrics

| metric | Meaning |
|--------|---------|
| `bars` | New bars evaluated (after warm-up) |
| `bb` / `vol` | Leg pass count |
| `buy_struct` / `sell_struct` | Structure break leg |
| `buy_ema` / `sell_ema` | EMA momentum leg |
| `buy_disp` / `sell_disp` | Displacement leg |
| `full_buy` / `full_sell` | Full 6-leg AND chain |
| `near_buy_5of6` / `near_sell_5of6` | 5 of 6 legs (bottleneck hint) |
| `exec_buy` / `exec_sell` | Orders actually sent |

**Conversion checks:**

- `exec_buy / full_buy` — how many full BUY signals become trades (low → risk/cooldown/max 1 position).
- `full_buy / bb` — chain tightness.
- `near_*` high vs `full_*` low → which leg blocks the chain (use journal DEBUG if `InpLogLevel=2`).

---

## Pass criteria

- CSV written, `bars` > 0.
- `exec_buy + exec_sell` ≈ total trades in report (± a few).
- No change to production preset for live — diag is research-only.

---

## Inputs

| Input | P7-B / P7-C |
|-------|-------------|
| `InpDiagSignalLegs` | **true** |
| `InpDiagWriteSummaryCsv` | **true** |
| `InpDiagSummaryFile` | `AEC_P7-B_...` or `AEC_P7-C_...` |

Production **P5-F** keeps diag **off**.
