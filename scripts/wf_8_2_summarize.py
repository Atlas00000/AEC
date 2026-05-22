#!/usr/bin/env python3
"""EDGE-8.2 — calendar-year walk-forward from P5-F deal exports (T50 train + T51 holdout)."""

from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path

DEFAULT_FILES = Path(
    r"c:\Users\emili\AppData\Roaming\MetaQuotes\Tester"
    r"\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files"
)

DEAL_FILES = (
    "AEC_P8-A_train_deals.csv",
    "AEC_P8-B_holdout_deals.csv",
)


def pf(gp: float, gl: float) -> float:
    if gl >= 0:
        return 999.0 if gp > 0 else 0.0
    if gp <= 0:
        return 0.0
    return gp / abs(gl)


def load_deals(base: Path) -> list[dict]:
    rows: list[dict] = []
    for name in DEAL_FILES:
        path = base / name
        if not path.is_file():
            raise FileNotFoundError(f"Missing {path} — run T50 + T51 first.")
        with path.open(encoding="utf-8") as f:
            rows.extend(csv.DictReader(f, delimiter=";"))
    return rows


def yearly_stats(rows: list[dict]) -> dict[int, dict]:
    by_year: dict[int, list[float]] = defaultdict(list)
    for r in rows:
        y = int(r["entry_time"][:4])
        by_year[y].append(float(r["net_profit"]))

    out: dict[int, dict] = {}
    for y in sorted(by_year):
        nets = by_year[y]
        n = len(nets)
        gp = sum(x for x in nets if x > 0)
        gl = sum(x for x in nets if x < 0)
        wins = sum(1 for x in nets if x > 0)
        out[y] = {
            "trades": n,
            "net": sum(nets),
            "pf": pf(gp, gl),
            "wr": 100.0 * wins / n if n else 0.0,
        }
    return out


def verdict(stats: dict[int, dict]) -> str:
    years = sorted(stats)
    pos = sum(1 for y in years if stats[y]["net"] > 0)
    bad = [y for y in years if stats[y]["pf"] < 0.85 and stats[y]["net"] < -30]
    if bad:
        return f"FAIL (weak years: {bad})"
    if pos >= 6:
        return "PASS"
    if pos >= 5 and all(stats[y]["net"] > -20 for y in years):
        return "BORDERLINE"
    return "FAIL"


def main() -> None:
    import argparse

    ap = argparse.ArgumentParser(description="EDGE-8.2 yearly walk-forward summary")
    ap.add_argument("--files-dir", type=Path, default=DEFAULT_FILES)
    args = ap.parse_args()

    rows = load_deals(args.files_dir)
    stats = yearly_stats(rows)

    print("EDGE-8.2 walk-forward (calendar year from T50+T51 deals)\n")
    print(f"{'Year':<6} {'Trades':>7} {'Net':>10} {'PF':>7} {'WR%':>7}")
    print("-" * 42)
    for y in sorted(stats):
        s = stats[y]
        print(f"{y:<6} {s['trades']:>7} {s['net']:>10.2f} {s['pf']:>7.2f} {s['wr']:>7.1f}")

    pos = sum(1 for y in stats if stats[y]["net"] > 0)
    print(f"\nYears net > 0: {pos} / {len(stats)}")
    print(f"Verdict: {verdict(stats)}")
    print("\nGate: >= 6/7 years net > 0; no year PF < 0.85 with net < -30.")


if __name__ == "__main__":
    main()
