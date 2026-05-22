#!/usr/bin/env python3
"""Summarize EDGE-8.1 T50 train + T51 holdout from segment CSV exports."""

from __future__ import annotations

import csv
from pathlib import Path

DEFAULT_FILES = Path(
    r"c:\Users\emili\AppData\Roaming\MetaQuotes\Tester"
    r"\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files"
)

PAIRS = (
    ("T50 train", "AEC_P8-A_train_segments.csv"),
    ("T51 holdout", "AEC_P8-B_holdout_segments.csv"),
)

REF_T48 = {"pf": 1.17, "net": 271.30, "trades": 1244, "wr": 37.14}


def read_total(seg_path: Path) -> dict | None:
    if not seg_path.is_file():
        return None
    with seg_path.open(encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter=";"):
            if (
                row.get("segment_type") == "total"
                and row.get("segment_key") == "ALL"
                and row.get("direction") == "ALL"
            ):
                return {
                    "trades": int(row["trades"]),
                    "net": float(row["net"]),
                    "pf": float(row["profit_factor"]),
                    "wr": float(row["win_rate_pct"]),
                }
    return None


def verdict_holdout(pf: float, net: float) -> str:
    if pf >= 1.05 and net > 0:
        return "PASS"
    if pf >= 1.0 and net > 0:
        return "BORDERLINE"
    return "FAIL"


def main() -> None:
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("--files-dir", type=Path, default=DEFAULT_FILES)
    args = ap.parse_args()
    base: Path = args.files_dir

    print("EDGE-8.1 OOS summary\n")
    print(f"{'Window':<14} {'Trades':>7} {'Net':>10} {'PF':>7} {'WR%':>7}  File")
    print("-" * 72)

    holdout = None
    for label, name in PAIRS:
        path = base / name
        t = read_total(path)
        if t is None:
            print(f"{label:<14} {'— missing —':>36}  {name}")
            continue
        print(
            f"{label:<14} {t['trades']:>7} {t['net']:>10.2f} {t['pf']:>7.4f} {t['wr']:>7.2f}  {name}"
        )
        if "holdout" in label:
            holdout = t

    print("\nReference T48 full range:", REF_T48)
    if holdout:
        v = verdict_holdout(holdout["pf"], holdout["net"])
        print(f"\nHoldout verdict: {v}  (gate: PF>=1.05, net>0)")
    else:
        print("\nRun T51 (P8-B) and export segments, then rerun this script.")


if __name__ == "__main__":
    main()
