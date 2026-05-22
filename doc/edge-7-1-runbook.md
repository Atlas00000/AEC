# EDGE-7.1 — Deal export runbook

Export closed-trade history and **PF / net / win-rate** buckets for data-driven filters (hours, overlap, direction).

**Stack under test:** production **P5-E (T36)** — same inputs, export only.

---

## Run (T47)

1. **F7** compile AEC.
2. Load **`AEC.P7-A_deal-export_EDGE-7-1.set`** (copy to `MQL5/Profiles/Tester/` if needed).
3. **EURUSD M5** · **2020.01.01–2026.05.19** · deposit **200** · lot **0.01**.
4. Start backtest — expect metrics **≈ T36** (PF ~1.15, ~1302 trades).
5. On finish, check journal: `Deal export: N closes -> ...` (**N should ≈ trade count**, e.g. ~1302 for T36 stack).
6. If **N ≈ 2**, recompile (export uses `OnTester` + live deal buffer) and rerun.

---

## Outputs (Tester `MQL5/Files/`)

| File | Content |
|------|---------|
| `AEC_P7-A_deals.csv` | One row per **close** (OUT deal): entry hour/weekday/month, direction, net P&L |
| `AEC_P7-A_segments.csv` | Aggregates: `hour` / `weekday` / `month` × `ALL` / `BUY` / `SELL` |

**Weekday key:** `0` = Sunday … `6` = Saturday (broker time of **entry**).

**Hour key:** `0`–`23` broker hour at **entry** (signal bar window uses same clock).

---

## Archive

Copy to `doc/data/T47/`:

- `AEC_P7-A_deals.csv`
- `AEC_P7-A_segments.csv`
- Tester report HTML (optional)
- Journal excerpt with `Deal export:` line

Log row in `doc/test-results-log.md`.

---

## How to use segments

Open `AEC_P7-A_segments.csv` in Excel:

1. Filter `segment_type=hour`, `direction=ALL` — find hours with **PF &lt; 1** and negative **net**.
2. Compare `BUY` vs `SELL` in overlap hours **13–14** (validates EDGE-3.1 vs 3.16 vs 5.4).
3. Filter `segment_type=weekday` — Friday / Monday checks from phase1-analysis.
4. Filter `segment_type=month` — seasonal drift.

**Do not** change production filters from one bucket alone; confirm with full backtest (new EDGE ID).

---

## Inputs (code)

| Input | Default | P7-A |
|-------|---------|------|
| `InpExportDeals` | false | **true** |
| `InpDealExportFile` | `AEC_deals.csv` | `AEC_P7-A_deals.csv` |
| `InpDealSegmentFile` | `AEC_segments.csv` | `AEC_P7-A_segments.csv` |

Production presets leave export **off**.
