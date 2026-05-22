#!/usr/bin/env python3
"""Generate optional per-year Strategy Tester presets for EDGE-8.2 (strict WF)."""

from pathlib import Path

TEMPLATE_HEADER = """; AEC | P8-WF-{year} | EDGE-8.2 optional yearly walk-forward
; Tester dates: {from_d} – {to_d}
; Stack: P5-F · EURUSD M5 · deposit 200
"""

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "presets" / "tester" / "AEC.P8-B_oos-holdout_EDGE-8-1.set"
OUT_DIR = ROOT / "presets" / "tester"

YEARS = (
    (2020, "2020.01.01", "2020.12.31"),
    (2021, "2021.01.01", "2021.12.31"),
    (2022, "2022.01.01", "2022.12.31"),
    (2023, "2023.01.01", "2023.12.31"),
    (2024, "2024.01.01", "2024.12.31"),
    (2025, "2025.01.01", "2025.12.31"),
    (2026, "2026.01.01", "2026.05.19"),
)


def main() -> None:
    lines = SRC.read_text(encoding="utf-8").splitlines()
    idx = next(i for i, ln in enumerate(lines) if ln.startswith("InpAllowTrading="))
    body_lines = lines[idx:]

    for year, from_d, to_d in YEARS:
        header = TEMPLATE_HEADER.format(year=year, from_d=from_d, to_d=to_d)
        out = OUT_DIR / f"AEC.P8-WF-{year}_EDGE-8-2.set"
        text_lines = [header.rstrip(), ";"]
        for ln in body_lines:
            if ln.startswith("InpCsvFileName="):
                text_lines.append(f"InpCsvFileName=AEC_P8-WF_{year}_decisions.csv")
            elif ln.startswith("InpDiagSummaryFile="):
                text_lines.append(f"InpDiagSummaryFile=AEC_P8-WF_{year}_diag_summary.csv")
            elif ln.startswith("InpDealExportFile="):
                text_lines.append(f"InpDealExportFile=AEC_P8-WF_{year}_deals.csv")
            elif ln.startswith("InpDealSegmentFile="):
                text_lines.append(f"InpDealSegmentFile=AEC_P8-WF_{year}_segments.csv")
            elif ln.startswith("InpMaeMfeBucketFile="):
                text_lines.append(f"InpMaeMfeBucketFile=AEC_P8-WF_{year}_mae_mfe_buckets.csv")
            else:
                text_lines.append(ln)
        out.write_text("\n".join(text_lines) + "\n", encoding="utf-8")
        print("wrote", out.name)


if __name__ == "__main__":
    main()
