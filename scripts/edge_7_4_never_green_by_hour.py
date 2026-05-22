#!/usr/bin/env python3
"""
EDGE-7.4 — never-green loser rate by entry hour (from deals + mfe_r).

Taxonomy (EDGE-7.3): loser_never_green = net < 0 and mfe_r < 0.2

  python scripts/edge_7_4_never_green_by_hour.py
  python scripts/edge_7_4_never_green_by_hour.py --deals train.csv --deals holdout.csv
"""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

NEVER_GREEN_MFE = 0.2
FOUGHT_MFE = 0.5
MIN_TRADES = 15

DEFAULT_FILES = Path(
    r"c:\Users\emili\AppData\Roaming\MetaQuotes\Tester"
    r"\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files"
)

DEFAULT_DEALS = (
    DEFAULT_FILES / "AEC_P8-A_train_deals.csv",
    DEFAULT_FILES / "AEC_P8-B_holdout_deals.csv",
)


def load_deals(paths: list[Path]) -> list[dict]:
    rows: list[dict] = []
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(f"Missing {path}")
        with path.open(encoding="utf-8") as f:
            batch = list(csv.DictReader(f, delimiter=";"))
        if batch and "mfe_r" not in batch[0]:
            raise ValueError(
                f"{path.name} has no mfe_r — run: python scripts/p7d_mae_mfe_postprocess.py --deals {path}"
            )
        rows.extend(batch)
    return rows


def analyze(rows: list[dict]) -> list[dict]:
    by_hour: dict[int, list[dict]] = defaultdict(list)
    for r in rows:
        by_hour[int(r["entry_hour"])].append(r)

    out: list[dict] = []
    for hour in sorted(by_hour):
        trades = by_hour[hour]
        n = len(trades)
        nets = [float(t["net_profit"]) for t in trades]
        net = sum(nets)
        wins = sum(1 for x in nets if x > 0)
        losers = [t for t in trades if float(t["net_profit"]) < 0]
        n_loss = len(losers)
        never = sum(1 for t in losers if float(t["mfe_r"]) < NEVER_GREEN_MFE)
        fought = sum(
            1 for t in losers if float(t["mfe_r"]) >= FOUGHT_MFE
        )
        gp = sum(float(t["net_profit"]) for t in trades if float(t["net_profit"]) > 0)
        gl = sum(float(t["net_profit"]) for t in trades if float(t["net_profit"]) < 0)
        pf = gp / abs(gl) if gl < 0 else (999.0 if gp > 0 else 0.0)
        never_pct_loss = 100.0 * never / n_loss if n_loss else 0.0
        never_pct_all = 100.0 * never / n if n else 0.0
        out.append(
            {
                "entry_hour": hour,
                "trades": n,
                "wins": wins,
                "losses": n_loss,
                "never_green": never,
                "fought_mfe05": fought,
                "never_green_pct_of_losses": round(never_pct_loss, 2),
                "never_green_pct_of_trades": round(never_pct_all, 2),
                "net": round(net, 2),
                "profit_factor": round(pf, 4),
                "win_rate_pct": round(100.0 * wins / n, 2) if n else 0.0,
            }
        )
    return out


def recommend(rows: list[dict], min_trades: int) -> list[str]:
    """Hours to consider blocking (high never-green among losers, enough sample)."""
    cands = [
        r
        for r in rows
        if r["trades"] >= min_trades
        and r["losses"] >= 10
        and r["never_green_pct_of_losses"] >= 50.0
    ]
    cands.sort(
        key=lambda r: (r["never_green_pct_of_losses"], r["never_green"]),
        reverse=True,
    )
    lines: list[str] = []
    for r in cands[:5]:
        lines.append(
            f"  hour {r['entry_hour']:02d}: {r['never_green_pct_of_losses']:.1f}% of losses never-green "
            f"({r['never_green']}/{r['losses']}), net {r['net']:+.2f}, PF {r['profit_factor']:.2f}"
        )
    weak_net = [
        r
        for r in rows
        if r["trades"] >= min_trades and r["net"] < 0 and r["profit_factor"] < 1.0
    ]
    weak_net.sort(key=lambda r: r["net"])
    for r in weak_net[:3]:
        lines.append(
            f"  hour {r['entry_hour']:02d}: weak net {r['net']:+.2f} PF {r['profit_factor']:.2f} "
            f"(segment 7.1 — compare EDGE-5.7)"
        )
    return lines


def write_csv(path: Path, rows: list[dict]) -> None:
    cols = [
        "entry_hour",
        "trades",
        "wins",
        "losses",
        "never_green",
        "fought_mfe05",
        "never_green_pct_of_losses",
        "never_green_pct_of_trades",
        "net",
        "profit_factor",
        "win_rate_pct",
    ]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, delimiter=";")
        w.writeheader()
        w.writerows(rows)


def main() -> int:
    ap = argparse.ArgumentParser(description="EDGE-7.4 never-green by entry hour")
    ap.add_argument(
        "--deals",
        type=Path,
        action="append",
        help="deals CSV (repeatable); default T50+T51 P8 exports",
    )
    ap.add_argument("--out", type=Path, default=None, help="output CSV path")
    ap.add_argument("--min-trades", type=int, default=MIN_TRADES)
    args = ap.parse_args()

    paths = args.deals if args.deals else list(DEFAULT_DEALS)
    rows = load_deals(paths)
    stats = analyze(rows)

    out_path = args.out or (paths[0].parent / "AEC_edge_7_4_never_green_by_hour.csv")
    write_csv(out_path, stats)

    print("EDGE-7.4 — never-green by entry hour (mfe_r < 0.2 on losers)\n")
    print(f"Trades: {len(rows)} from {len(paths)} file(s)\n")
    print(
        f"{'Hr':>3} {'Trd':>5} {'Loss':>5} {'NG':>4} {'NG%L':>6} {'Net':>8} {'PF':>6} {'WR%':>6}"
    )
    print("-" * 52)
    for r in stats:
        if r["trades"] < 1:
            continue
        print(
            f"{r['entry_hour']:>3} {r['trades']:>5} {r['losses']:>5} {r['never_green']:>4} "
            f"{r['never_green_pct_of_losses']:>5.1f}% {r['net']:>8.2f} "
            f"{r['profit_factor']:>6.2f} {r['win_rate_pct']:>6.1f}"
        )

    print(f"\nWrote {out_path}")
    print("\nCandidates for entry filter / EDGE-5.7 (never-green or weak net):")
    rec = recommend(stats, args.min_trades)
    if rec:
        print("\n".join(rec))
    else:
        print("  (none above thresholds — review table manually)")

    all_never = sum(r["never_green"] for r in stats)
    all_loss = sum(r["losses"] for r in stats)
    if all_loss:
        print(
            f"\nOverall: {all_never}/{all_loss} losses never-green "
            f"({100*all_never/all_loss:.1f}%) — baseline T49 ~45.8%"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
