# EDGE-8.3 — Production lock (P5-F)

**Locked after Phase 8 validation (8.1 PASS · 8.2 PASS).**  
Do not change defaults for live/demo without a new EDGE ID + OOS re-check.

---

## Production preset

| Item | Value |
|------|--------|
| **Preset** | `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set` |
| **Test ID** | **T48** (full range reference) |
| **Expert** | `AEC.mq5` · version **1.01** |
| **Symbol / TF** | **EURUSD M5** |
| **Deposit (research)** | **200** · fixed lot **0.01** |

---

## Validation summary (Phase 8)

| Check | Result |
|-------|--------|
| **8.1 Train** 2020–2023 (T50) | PF **1.17** · net **+179.77** · 830 trades |
| **8.1 Holdout** 2024–2026 (T51) | PF **1.18** · net **+93.57** · 419 trades · **PASS** |
| **8.2 Walk-forward** | **6/7** years net > 0 · 2020 flat · **PASS** |
| **Full range** (T48) | PF **1.17** · net **+271.30** · 1244 trades · DD ~24% |

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
| **Hour BUY block** | `InpUseHourDirectionFilter=true` · BUY **[14,15)** | **5.6** |

**Risk / exits (locked):** SL **200** pts · TP **400** pts (RR 2.0) · no Phase 6 exit overlays.

---

## `Inputs.mqh` compile defaults

**Full P5-F stack is the EA compile default** in `Config/Inputs.mqh` — attaching the EA without a preset uses the same logic as `AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set` (except `InpAllowTrading` stays **false** until you enable it).

Key production flags:

- `InpUseHourDirectionFilter = true` · BUY block **[14, 15)**
- `InpUsePostStreakGate = true` · `InpUseTradingHours = true` · **8–17**
- `InpMinBbReleaseExpandRatio = 1.10` · `InpMinStructBreakAtrMult = 0.20`
- `InpUseBbChopSkip = true` · `InpUsePriorBarRangeCap = true`
- All Phase **6/9** exit overlays **false** (`GiveBack`, `SoftNeverGreen`, partial, etc.)

---

## Research-only (off in production)

| Input | Production |
|-------|------------|
| `InpExportDeals` | **false** |
| `InpExportMaeMfe` | **false** |
| `InpDiagSignalLegs` | **false** |
| `InpForceTestSignal` | **false** |

Use **`AEC.P7-D`** or scripts for diagnostics — not on live chart preset.

---

## Files to ship

```
presets/tester/AEC.P5-F_block-buy-hours-1415_EDGE-5-6.set
MQL5/Profiles/Tester/  (copy of same)
doc/edge-8-1-runbook.md
doc/edge-8-2-runbook.md
doc/edge-8-3-production-lock.md  (this file)
```

---

## Before Phase 9 changes

Any new filter/exit → one backtest vs **P5-F** → **EDGE-8.1 holdout** again on winner → update this doc if promoted.

**Not promoted:** **EDGE-5.7** (T59/T60) · **EDGE-6.9–6.11** (T61–T64) · **EDGE-3.17** (T65 net −16.47).

**Phase 9 (2026-05):** no change to production stack — keep **P5-F** / **T48** inputs.
