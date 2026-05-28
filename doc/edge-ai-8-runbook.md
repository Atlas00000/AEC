# EDGE-AI-8 — Regime / era analysis (8.4 + T74 + T75)

## Presets (sync, do not copy manually)

```powershell
cd MQL5\Experts\AEC
.\scripts\sync_tester_presets.ps1
```

Then Strategy Tester → **Load** → `AEC.P10-F_...T74` or `AEC.P11-A_...T75`.

**Checklist:** [edge-ai-8-t74-t75-checklist.md](./edge-ai-8-t74-t75-checklist.md)

---

## 8.4 — Offline era split (Python)

From any `*_deals.csv`:

```bash
python scripts/ai_regime_summarize.py
python scripts/ai_regime_summarize.py --deals AEC_P10-E_deals.csv
```

Outputs:

| File | Content |
|------|---------|
| `data/ai/regime_by_year.csv` | PF/net per entry year |
| `data/ai/regime_eras.csv` | pre-2020 vs 2020+ buckets |
| `data/ai/regime_rolling_pf.csv` | 100-trade rolling PF |
| `doc/edge-ai-8-4-regime-readout.md` | Human readout |

**Note:** `P10-E` deals are **2020–2026 only**. For **2010–2019** you need **T74** or **T75** deal exports.

---

## T74 — P5-F long range (no AI)

| Item | Value |
|------|--------|
| Preset | **`AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set`** |
| Stack | Production **P5-F** (same as T48) |
| AI | **Off** (no `InpUseAiEntryFilter`) |
| Deposit / lot | **200** / **0.01** |
| Dates | **2010.01.01 – 2026.05.19** |
| Export | `AEC_P10-F_deals.csv` |

**Question answered:** Does the **signal stack alone** lose money on 2010–2026 (like T73), or is it mainly the **AI gate**?

**Pass bar (informal):** PF ≥ **1.0** on full range **or** clear positive **2020+** with documented negative pre-2020 era.

---

## T75 — P10-B + regime filters

| Item | Value |
|------|--------|
| Preset | **`AEC.P11-A_regime-gate_EDGE-AI-8-T75.set`** |
| Stack | **P10-B** + `InpUseAtrPercentileBand=true` (20–85) + `InpUseAdxMinFilter=true` (ADX≥18) |
| AI skip | **On** (τ=0.45) |
| Deposit / lot | **200** / **0.01** |

**Run twice:**

1. **Long:** 2010.01.01 – 2026.05.19 — vs T73 / T74  
2. **Short:** 2020.01.01 – 2026.05.19 — must **not** destroy T70 (+273 / PF 1.19)

Export: `AEC_P11-A_deals.csv` → re-run `ai_regime_summarize.py --deals AEC_P11-A_deals.csv`

**Pass bar for 2020+ run:** PF ≥ **1.17**, net ≥ **T48**, trades fewer OK if net↑; DD not worse than ~24%.

**Reject** if 2020+ PF drops below **1.10** (same lesson as historical P4-C ATR band test).

---

## References

| Test | Preset | Range | PF | Net |
|------|--------|-------|-----|-----|
| T48 | P5-F | 2020+ | 1.17 | +271 |
| T70 | P10-B | 2020+ | 1.19 | +274 |
| T73 | P10-B | 2010+ | 0.98 | −80 (dep 1000) |

Log results in `doc/test-results-log.md` as **T74** / **T75**.
