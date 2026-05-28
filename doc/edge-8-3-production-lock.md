# Production lock (P10-B / EDGE-AI-4)

**Locked after EDGE-AI-4/5 validation (T70/T71 PASS · 2026-05-20).**  
Supersedes **P5-F (T48)**. Do not change defaults without a new EDGE ID + OOS re-check.

---

## Production preset

| Item | Value |
|------|--------|
| **Preset** | `AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set` |
| **Test ID** | **T70** (full range) · **T71** (holdout) |
| **Prior preset** | `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set` (T48) |
| **Expert** | `AEC.mq5` · version **1.01** |
| **Symbol / TF** | **EURUSD M5** |
| **Deposit (research)** | **200** · fixed lot **0.01** |

---

## Validation summary

| Check | Result |
|-------|--------|
| **Full range** (T70) | PF **1.19** · net **+273.61** · 1144 trades · DD ~14% |
| **Holdout** 2024–2026 (T71) | PF **1.22** · net **+105.61** · 386 trades · **PASS** |
| **Prior P5-F** (T48) | PF **1.17** · net **+271.30** · 1244 trades · DD ~24% |
| **Prior holdout** (T51) | PF **1.18** · net **+93.57** · 419 trades |

**Phase 8 (P5-F):** still valid baseline; AI gate adds pre-trade skip on same stack.

### Validated scope vs extended history

| Window | Test | Verdict |
|--------|------|---------|
| **2020–2026** (research lock) | T70 / T71 | **PASS** — production basis |
| **2010–2026** (robustness) | **T73** | **Caution** — PF **0.98** · net **−79.93** · DD **~38%** (deposit 1000) |

Extended history suggests **regime dependence**; edge is not proven stable from 2010. Deploy with the understanding that validation is **2020+** unless a future EDGE re-tests older years. See T73 notes in [test-results-log.md](./test-results-log.md).

---

## Stack layers (do not remove without re-test)

| Layer | Inputs | EDGE |
|-------|--------|------|
| Hours | `InpUseTradingHours=true` · **8–17** | 2.1 |
| BB release | `InpMinBbReleaseExpandRatio=1.10` | 3.2 |
| Struct break | `InpMinStructBreakAtrMult=0.20` | 3.4 |
| Prior bar cap | `InpMaxPriorBarRangeAtrMult=2.0` | 4.4 |
| BB chop skip | `InpMinBbWidthVsAvgRatio=1.0` | 4.5 |
| Post-streak | `InpPostStreakLossCount=4` · pause **2700 s** | 5.5 |
| Hour BUY block | `InpUseHourDirectionFilter=true` · BUY **[14,15)** | 5.6 |
| **AI skip gate** | `InpUseAiEntryFilter=true` · `InpAiMinProbTake=0.45` | **AI-4** |

**Risk / exits (locked):** SL **200** pts · TP **400** pts (RR 2.0) · no Phase 6/9 exit overlays.

**AI model:** embedded logistic in `Execution/AiEntryGate.mqh` (from `data/ai/model_sklearn.json`).

---

## `Inputs.mqh` compile defaults

**Full P10-B stack** — attaching the EA without a preset matches `AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set` (except `InpAllowTrading` stays **false** until enabled).

Key production flags:

- `InpUseAiEntryFilter = true` · `InpAiMinProbTake = 0.45`
- `InpUseHourDirectionFilter = true` · BUY block **[14, 15)**
- `InpUsePostStreakGate = true` · `InpUseTradingHours = true` · **8–17**
- `InpMinBbReleaseExpandRatio = 1.10` · `InpMinStructBreakAtrMult = 0.20`
- `InpUseBbChopSkip = true` · `InpUsePriorBarRangeCap = true`
- All Phase **6/9** exit overlays **false**

---

## Research-only (off in production)

| Input | Production |
|-------|------------|
| `InpExportDeals` | **false** |
| `InpExportMaeMfe` | **false** |
| `InpDiagSignalLegs` | **false** |
| `InpForceTestSignal` | **false** |

Use **`AEC.P10-A`** / **`AEC.P7-D`** or scripts for deal export — not on live chart preset.

---

## Files to ship

```
presets/tester/AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set
MQL5/Profiles/Tester/  (copy of same)
doc/edge-ai-4-runbook.md
doc/edge-8-3-production-lock.md  (this file)
```

**Archive (baseline):** `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set`

---

## Before further changes

Any new filter/exit → backtest vs **P10-B (T70)** → holdout vs **T71** / T51 → update this doc if promoted.

**Not promoted:** EDGE-5.7 · Phase 9 exits · BB 1.12 alone.
