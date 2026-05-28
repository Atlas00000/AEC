# EDGE-AI-4 / AI-5 — MQL5 skip gate validation

Production stack (**P5-F**) + **logistic skip gate** (`Execution/AiEntryGate.mqh`).  
Skip entry when `P(L3_take) < InpAiMinProbTake` (default **0.45** from offline sweep).

**Recompile** `AEC.ex5` in MetaEditor after pulling this change.

---

## T70 — full range

| Item | Value |
|------|--------|
| Preset | `AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set` |
| Symbol / TF | EURUSD M5 |
| Deposit / lot | 200 / 0.01 |
| Dates | 2020.01.01 – 2026.05.19 |
| Compare | **T48** (P5-F, no AI) |

**Offline expectation (replay on T72 deals):** ~1117 trades · net ~+275 · PF ~1.19 · ~10.6% skips.

**Pass bar:** PF ≥ 1.17 · net > T48 (+271.30) · equity DD not worse than ~24%.

---

## T71 — holdout

| Item | Value |
|------|--------|
| Preset | `AEC.P10-C_ai-skip-holdout_EDGE-AI-4.set` (same inputs as P10-B) |
| Dates | 2024.01.01 – 2026.05.19 |
| Compare | **T51** (P8-B, no AI) |

**Offline expectation:** ~378 trades · net ~+104 · PF ~1.22.

**Pass bar:** PF ≥ 1.05 · net > 0 · prefer match or beat T51 (+93.57 / 1.18).

---

## Inputs

| Input | T70/T71 |
|--------|---------|
| `InpUseAiEntryFilter` | `true` |
| `InpAiMinProbTake` | `0.45` |

Model coefficients are embedded in `AiEntryGate.mqh` (from `data/ai/model_sklearn.json`). After retrain, update constants or regenerate via a future export script.

---

## Debug

Set `InpLogLevel=2` (Trace) to log `AI skip` / `AI take` per bar in the Experts tab.

---

## T70 / T71 results (2026-05-20) — PASS

| Test | Net | PF | Trades | Equity DD |
|------|----:|---:|-------:|----------:|
| T70 | +273.61 | 1.19 | 1144 | ~14% |
| T71 | +105.61 | 1.22 | 386 | ~16% |

Logged in `doc/test-results-log.md`. **Promoted (EDGE-AI-6):** production **P10-B** · `Inputs.mqh` defaults updated.

## Live / chart

Load **`AEC.P10-B_ai-skip-tau045_EDGE-AI-4.set`** or recompile and attach EA (compile defaults match P10-B). See [edge-8-3-production-lock.md](./edge-8-3-production-lock.md).

See [aiimplmentation.md](./aiimplmentation.md) · [edge-ai-0-runbook.md](./edge-ai-0-runbook.md).
