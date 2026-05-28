# EDGE-AI-8 — T74 / T75 tester checklist

**Before any run:** sync presets (no manual copy):

```powershell
cd MQL5\Experts\AEC
.\scripts\sync_tester_presets.ps1
```

In Strategy Tester → **Inputs** → **Load** → pick preset by name.

---

## Common settings (all runs)

| Setting | Value |
|---------|--------|
| Expert | `AEC.ex5` (recompile if `.mqh` changed) |
| Symbol | **EURUSD** |
| Period | **M5** |
| Model | Same as T48/T70 (e.g. **Every tick** or your locked model) |
| Deposit | **1000** for full **2010–2026** (match T73; dep **200** wipes account ~2014) |
| Deposit | **200** OK for **2020–2026 only** (match T48/T70) |
| Lot | **0.01** (fixed in preset) |
| Optimization | **Off** |

**Dates are set in the Tester UI** (presets cannot set From/To).

---

## Run 1 — T74 (P5-F long range, no AI)

| | |
|--|--|
| **Test ID** | **T74** |
| **Preset** | `AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set` |
| **From** | `2010.01.01` |
| **To** | `2026.05.19` (or latest available) |
| **Purpose** | Stack-only baseline on full history (vs T73) |

- [ ] Ran `sync_tester_presets.ps1`
- [ ] Loaded T74 preset
- [ ] Set dates **2010.01.01 – 2026.05.19**
- [ ] Backtest finished without errors
- [ ] Note **PF**, **net**, **trades**, **max DD%**
- [ ] Export present: `AEC_P10-F_deals.csv` in [Tester Files](./paths.md)

**Pass (informal):** PF ≥ **1.0** full range **or** positive **2020+** with documented weak pre-2020.

**T74a (dep 200):** Incomplete — wiped ~2014.  
**T74b (dep 1000):** **Done** — PF **0.98**, net **−95.91**, **3180** trades, pre2020 **−372** / 2020+ **+276** (PF 1.19). ≈ **T73**; AI not the T73 villain.

---

## Run 2 — T75 long (regime gate, full history)

| | |
|--|--|
| **Test ID** | **T75a** (log as T75 long) |
| **Preset** | `AEC.P11-A_regime-gate_EDGE-AI-8-T75.set` |
| **From** | `2010.01.01` |
| **To** | `2026.05.19` |
| **Stack** | P10-B + ATR pct **20–85** + ADX **≥18** + AI skip τ=0.45 |

- [ ] Loaded T75 preset (after sync)
- [ ] Dates **2010 – 2026**
- [ ] Record PF / net / trades / DD
- [ ] `AEC_P11-A_deals.csv` written (rename or archive before Run 3 if needed)

---

## Run 3 — T75 short (regime gate, production window)

| | |
|--|--|
| **Test ID** | **T75b** (log as T75 2020+) |
| **Preset** | Same `AEC.P11-A_regime-gate_EDGE-AI-8-T75.set` |
| **From** | `2020.01.01` |
| **To** | `2026.05.19` |

- [ ] Dates **2020 – 2026** only
- [ ] Compare to **T70**: PF ~**1.19**, net ~**+274**, ~**1144** trades
- [ ] **Reject** P11-A if 2020+ PF **&lt; 1.10**

**Pass bar:** PF ≥ **1.17**, net ≥ T48 (+271), DD not worse than ~24%.

---

## After all runs

1. Copy deal CSVs from Tester `MQL5\Files\` to `data\ai\` (optional).
2. Regenerate era readout:
   ```bash
   python scripts/ai_regime_summarize.py --deals AEC_P10-F_deals.csv
   python scripts/ai_regime_summarize.py --deals AEC_P11-A_deals.csv
   ```
3. Log rows in [test-results-log.md](./test-results-log.md) (T74, T75).
4. Say **proceed** in chat with headline numbers or CSV paths.

**Production unchanged** until T75 2020+ passes — stay on **P10-B**.
