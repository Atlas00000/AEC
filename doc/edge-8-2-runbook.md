# EDGE-8.2 — Walk-forward (calendar years)

Confirm **P5-F** is not a one-off good period. Uses the same deal exports as **8.1** (no extra backtests required).

---

## Method

Split **T50 train** + **T51 holdout** deal CSVs by **entry year** (combined ≈ full P5-F stack 2020–2026).

```bash
python scripts/wf_8_2_summarize.py
```

Optional strict check: run each calendar year alone in Strategy Tester (fresh deposit each year) using presets `AEC.P8-WF-YYYY_EDGE-8-2.set` — only if you want isolated-year equity curves.

---

## Result (2026-05-21) — **PASS**

From `AEC_P8-A_train_deals.csv` + `AEC_P8-B_holdout_deals.csv` (**1249** closes).

| Year | Trades | Net | PF | WR% |
|------|-------:|----:|---:|----:|
| 2020 | 239 | −0.17 | 1.00 | 33.5 |
| 2021 | 182 | +43.03 | 1.19 | 37.4 |
| 2022 | 218 | +75.77 | 1.28 | 39.4 |
| 2023 | 191 | +61.14 | 1.26 | 38.7 |
| 2024 | 152 | +19.65 | 1.10 | 35.5 |
| 2025 | 196 | +53.91 | 1.22 | 38.3 |
| 2026 | 71 | +20.01 | 1.23 | 38.0 |

**Years net > 0:** **6 / 7** (2020 flat). **Verdict: PASS.**

**Readout:** 2020 is breakeven (PF 1.00); 2021–2026 all profitable with PF **1.10–1.28**. No catastrophic year.

---

## Pass / fail

| Verdict | Rule |
|---------|------|
| **PASS** | ≥ **6** calendar years with net **> 0**; no year with PF **< 0.85** and net **< −30** |
| **BORDERLINE** | 5 years positive, none deeply negative |
| **FAIL** | ≤ 4 years positive or any year large loss |

---

## Optional yearly tester runs

| Year | Tester From | To | Preset |
|------|-------------|-----|--------|
| 2020 | 2020.01.01 | 2020.12.31 | `AEC.P8-WF-2020_EDGE-8-2.set` |
| 2021 | 2021.01.01 | 2021.12.31 | `AEC.P8-WF-2021_EDGE-8-2.set` |
| … | … | … | … |
| 2026 | 2026.01.01 | 2026.05.19 | `AEC.P8-WF-2026_EDGE-8-2.set` |

Generate presets: `python scripts/generate_wf_8_2_presets.py`

Not required after script PASS above.
