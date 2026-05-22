# EDGE-8.1 — OOS train / holdout (P5-F stack)

Validate **production P5-F** on unseen time before Phase 9 tweaks.

| Window | Test ID | Preset | Tester **From** | Tester **To** |
|--------|---------|--------|-----------------|---------------|
| **Train** (in-sample design period) | **T50** | `AEC.P8-A_oos-train_EDGE-8-1.set` | **2020.01.01** | **2023.12.31** |
| **Holdout** (OOS verdict) | **T51** | `AEC.P8-B_oos-holdout_EDGE-8-1.set` | **2024.01.01** | **2026.05.19** |

**Reference only (do not re-run unless auditing):** T48 full range 2020.01.01–2026.05.19 · PF **1.17** · net **+271.30** · 1244 trades.

---

## Tester settings (both runs)

| Setting | Value |
|---------|--------|
| Expert | **AEC** |
| Symbol | **EURUSD** |
| Period | **M5** |
| Deposit | **200** |
| Model | Every tick based on real ticks (or 1 minute OHLC if slow) |
| Optimization | **Off** |

1. **F7** compile `AEC.mq5` (journal: `AEC v1.01 EDGE-7.3` optional).
2. Load preset → set **dates in UI** (presets cannot set tester dates).
3. **Start** → wait for completion.
4. Journal: `Deal export: N closes maeMfe=on -> AEC_P8-...`
5. Copy report screenshot + CSVs → `doc/data/T50/` or `doc/data/T51/`.

Presets also copied to `MQL5/Profiles/Tester/` for the dropdown.

---

## Result (2026-05-21) — **PASS**

| Window | Trades | Net | PF | WR% | DD (equity) |
|--------|-------:|----:|---:|----:|------------:|
| T50 train 2020–2023 | 830 | +179.77 | 1.17 | 37.11% | ~23% |
| T51 holdout 2024–2026 | 419 | +93.57 | 1.18 | 37.23% | ~16% |

Holdout meets gate. Phase 9 improvements allowed (one tweak at a time; re-run 8.1 on winner).

---

## Pass / fail (EDGE-8.1)

**Primary gate = holdout (T51).** Train (T50) is context only — we already know the stack was built on 2020–2026.

| Metric | Train T50 (expect) | Holdout T51 (**verdict**) |
|--------|--------------------|---------------------------|
| Profit factor | ≥ 1.10 | **≥ 1.05** |
| Net profit | > 0 | **> 0** |
| Trades | ~600–900 | **≥ 200** (enough sample) |
| Equity DD % | note | **not >> train** (e.g. holdout DD < 1.5× train DD) |

| Verdict | Rule |
|---------|------|
| **PASS** | Holdout PF ≥ **1.05** and net **> 0** |
| **BORDERLINE** | Holdout PF **1.00–1.05** or net small positive — proceed to Phase 9 with caution |
| **FAIL** | Holdout PF **< 1.00** or net **≤ 0** — do **not** add Phase 9 filters; revisit stack |

After both runs:

```bash
python scripts/oos_8_1_summarize.py
```

(Reads segment `total;ALL;ALL` rows from exported CSVs.)

---

## Outputs

| Test | Deals | Segments |
|------|-------|----------|
| T50 | `AEC_P8-A_train_deals.csv` | `AEC_P8-A_train_segments.csv` |
| T51 | `AEC_P8-B_holdout_deals.csv` | `AEC_P8-B_holdout_segments.csv` |

Tester folder: see [paths.md](./paths.md).

---

## Log results

Add rows to [test-results-log.md](./test-results-log.md) and set **EDGE-8.1** in [edge-discovery.md](./edge-discovery.md) to **done** or **fail** with holdout PF/net.

**If PASS:** proceed to **EDGE-8.2** (walk-forward) or **Phase 9** (one bucket tweak + 8.1 on winner).
