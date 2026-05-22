#!/usr/bin/env python3
"""
EDGE-7.3 post-process: MAE/MFE in R + bucket CSVs from existing P7-D deals export.

No Strategy Tester rerun — uses M5 bar high/low between entry and close (same logic as
MaeMfeTracker::RebuildFromHistory). Requires MetaTrader 5 terminal running with the
last tester history still loaded.

  pip install MetaTrader5
  python scripts/p7d_mae_mfe_postprocess.py

Optional:
  python scripts/p7d_mae_mfe_postprocess.py --deals path/to/AEC_P7-D_deals.csv --out-dir path/to/Files
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

try:
    import MetaTrader5 as mt5
except ImportError:
    mt5 = None  # type: ignore

# P7-D / P5-F preset defaults
SYMBOL = "EURUSD"
MAGIC = 260513001
SL_POINTS = 200
MFE_LABELS = ("0-0.3", "0.3-0.6", "0.6-1.0", "1.0-1.5", "1.5+")
MAE_LABELS = ("0-0.5", "0.5-1.0", "1.0+")

DEFAULT_DEALS = Path(
    r"c:\Users\emili\AppData\Roaming\MetaQuotes\Tester"
    r"\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000"
    r"\MQL5\Files\AEC_P7-D_deals.csv"
)


@dataclass
class Bucket:
    trades: int = 0
    wins: int = 0
    gross_profit: float = 0.0
    gross_loss: float = 0.0

    def add(self, net: float) -> None:
        self.trades += 1
        if net > 0:
            self.wins += 1
            self.gross_profit += net
        elif net < 0:
            self.gross_loss += net

    @property
    def net(self) -> float:
        return self.gross_profit + self.gross_loss

    def pf(self) -> float:
        if self.gross_loss >= 0:
            return 999.0 if self.gross_profit > 0 else 0.0
        if self.gross_profit <= 0:
            return 0.0
        return self.gross_profit / abs(self.gross_loss)

    def win_rate(self) -> float:
        return 100.0 * self.wins / self.trades if self.trades else 0.0


@dataclass
class TradeExcursion:
    position_id: int
    direction: str
    net: float
    mfe_r: float
    mae_r: float


def parse_dt(s: str) -> datetime:
    return datetime.strptime(s.strip(), "%Y.%m.%d %H:%M:%S")


def mfe_bin(mfe_r: float) -> int:
    if mfe_r < 0.3:
        return 0
    if mfe_r < 0.6:
        return 1
    if mfe_r < 1.0:
        return 2
    if mfe_r < 1.5:
        return 3
    return 4


def mae_bin(mae_r: float) -> int:
    if mae_r < 0.5:
        return 0
    if mae_r < 1.0:
        return 1
    return 2


def excursion_from_bars(
    direction: str, entry: float, risk: float, rates
) -> tuple[float, float]:
    mfe_r = 0.0
    mae_r = 0.0
    if risk <= 0:
        return mfe_r, mae_r
    is_buy = direction.upper() == "BUY"
    for bar in rates:
        hi = float(bar[2])
        lo = float(bar[3])
        if is_buy:
            fav = (hi - entry) / risk
            adv = (entry - lo) / risk
        else:
            fav = (entry - lo) / risk
            adv = (hi - entry) / risk
        mfe_r = max(mfe_r, fav)
        mae_r = max(mae_r, adv)
    return mfe_r, mae_r


def load_history_index(
    symbol: str, magic: int, t0: datetime, t1: datetime
) -> dict[int, tuple[float, str]]:
    """position_id -> (entry_price, direction) from DEAL_ENTRY_IN."""
    deals = mt5.history_deals_get(t0, t1, group=f"*{symbol}*")
    out: dict[int, tuple[float, str]] = {}
    if deals is None:
        return out
    for d in deals:
        if d.magic != magic or d.entry != mt5.DEAL_ENTRY_IN:
            continue
        pid = int(d.position_id)
        if pid <= 0 or pid in out:
            continue
        direction = "BUY" if d.type == mt5.DEAL_TYPE_BUY else "SELL"
        out[pid] = (float(d.price), direction)
    return out


def compute_excursion(
    symbol: str,
    point: float,
    sl_points: int,
    position_id: int,
    direction: str,
    entry_time: datetime,
    close_time: datetime,
    net: float,
    history_index: dict[int, tuple[float, str]],
) -> TradeExcursion:
    risk = sl_points * point
    entry = None
    meta = history_index.get(position_id)
    if meta:
        entry, direction = meta
    if entry is None or entry <= 0:
        rates_probe = mt5.copy_rates_range(symbol, mt5.TIMEFRAME_M5, entry_time, close_time)
        if rates_probe is not None and len(rates_probe) > 0:
            entry = float(rates_probe[0]["open"])
    if entry is None or entry <= 0:
        return TradeExcursion(position_id, direction, net, 0.0, 0.0)

    rates = mt5.copy_rates_range(symbol, mt5.TIMEFRAME_M5, entry_time, close_time)
    if rates is None or len(rates) == 0:
        return TradeExcursion(position_id, direction, net, 0.0, 0.0)

    mfe_r, mae_r = excursion_from_bars(direction, entry, risk, rates)
    return TradeExcursion(position_id, direction, net, mfe_r, mae_r)


def read_deals(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter=";"))


def write_enriched_deals(path: Path, rows: list[dict], excursions: dict[int, TradeExcursion]) -> None:
    base_cols = [
        "close_time",
        "entry_time",
        "entry_hour",
        "entry_weekday",
        "entry_month",
        "direction",
        "net_profit",
        "profit",
        "swap",
        "commission",
        "volume",
        "mfe_r",
        "mae_r",
        "deal_id",
        "position_id",
        "symbol",
    ]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=base_cols, delimiter=";")
        w.writeheader()
        for row in rows:
            pid = int(row["position_id"])
            ex = excursions.get(pid)
            mfe = f"{ex.mfe_r:.3f}" if ex else "0.000"
            mae = f"{ex.mae_r:.3f}" if ex else "0.000"
            out = {k: row.get(k, "") for k in base_cols if k not in ("mfe_r", "mae_r")}
            out["mfe_r"] = mfe
            out["mae_r"] = mae
            w.writerow(out)


def write_buckets(path: Path, trades: list[TradeExcursion]) -> None:
    tax = {
        "loser_never_green": Bucket(),
        "loser_fought_mfe05": Bucket(),
        "loser_other": Bucket(),
        "winner": Bucket(),
    }
    mfe_bins = [Bucket() for _ in range(5)]
    mfe_win = [Bucket() for _ in range(5)]
    mfe_loss = [Bucket() for _ in range(5)]
    mae_loss_bins = [Bucket() for _ in range(3)]

    for t in trades:
        fb = mfe_bin(t.mfe_r)
        mfe_bins[fb].add(t.net)
        if t.net > 0:
            tax["winner"].add(t.net)
            mfe_win[fb].add(t.net)
        elif t.net < 0:
            mb = mae_bin(t.mae_r)
            mae_loss_bins[mb].add(t.net)
            mfe_loss[fb].add(t.net)
            if t.mfe_r < 0.2:
                tax["loser_never_green"].add(t.net)
            elif t.mfe_r >= 0.5:
                tax["loser_fought_mfe05"].add(t.net)
            else:
                tax["loser_other"].add(t.net)

    def row(bucket_type: str, key: str, outcome: str, b: Bucket) -> dict | None:
        if b.trades <= 0:
            return None
        return {
            "bucket_type": bucket_type,
            "bucket_key": key,
            "outcome": outcome,
            "trades": str(b.trades),
            "wins": str(b.wins),
            "gross_profit": f"{b.gross_profit:.2f}",
            "gross_loss": f"{b.gross_loss:.2f}",
            "net": f"{b.net:.2f}",
            "profit_factor": f"{b.pf():.4f}",
            "win_rate_pct": f"{b.win_rate():.2f}",
        }

    cols = [
        "bucket_type",
        "bucket_key",
        "outcome",
        "trades",
        "wins",
        "gross_profit",
        "gross_loss",
        "net",
        "profit_factor",
        "win_rate_pct",
    ]
    rows: list[dict] = []
    for key, b in tax.items():
        outcome = "win" if key == "winner" else "loss"
        r = row("taxonomy", key, outcome, b)
        if r:
            rows.append(r)
    for i, label in enumerate(MFE_LABELS):
        for outcome, b in (("ALL", mfe_bins[i]), ("win", mfe_win[i]), ("loss", mfe_loss[i])):
            r = row("mfe_bin", label, outcome, b)
            if r:
                rows.append(r)
    for i, label in enumerate(MAE_LABELS):
        r = row("mae_bin_loss", label, "loss", mae_loss_bins[i])
        if r:
            rows.append(r)

    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, delimiter=";")
        w.writeheader()
        w.writerows(rows)


def main() -> int:
    ap = argparse.ArgumentParser(description="EDGE-7.3 MAE/MFE post-process (no backtest rerun)")
    ap.add_argument("--deals", type=Path, default=DEFAULT_DEALS)
    ap.add_argument("--out-dir", type=Path, default=None, help="default: same folder as deals CSV")
    ap.add_argument("--symbol", default=SYMBOL)
    ap.add_argument("--magic", type=int, default=MAGIC)
    ap.add_argument("--sl-points", type=int, default=SL_POINTS)
    args = ap.parse_args()

    if mt5 is None:
        print("Install: pip install MetaTrader5", file=sys.stderr)
        return 1

    if not args.deals.is_file():
        print(f"Deals file not found: {args.deals}", file=sys.stderr)
        return 1

    out_dir = args.out_dir or args.deals.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    if not mt5.initialize():
        print(f"MT5 initialize failed: {mt5.last_error()}", file=sys.stderr)
        print("Open MetaTrader 5 (same terminal as tester) and retry.", file=sys.stderr)
        return 1

    try:
        if not mt5.symbol_select(args.symbol, True):
            print(f"symbol_select failed: {args.symbol}", file=sys.stderr)
            return 1

        info = mt5.symbol_info(args.symbol)
        if info is None:
            print(f"symbol_info failed: {args.symbol}", file=sys.stderr)
            return 1
        point = float(info.point)

        deal_rows = read_deals(args.deals)
        print(f"Loaded {len(deal_rows)} closes from {args.deals}")

        t0 = min(parse_dt(r["entry_time"]) for r in deal_rows)
        t1 = max(parse_dt(r["close_time"]) for r in deal_rows)
        history_index = load_history_index(args.symbol, args.magic, t0, t1)
        print(f"History index: {len(history_index)} entry deals (MT5)")

        excursions: dict[int, TradeExcursion] = {}
        for i, row in enumerate(deal_rows):
            pid = int(row["position_id"])
            if pid in excursions:
                continue
            entry_t = parse_dt(row["entry_time"])
            close_t = parse_dt(row["close_time"])
            net = float(row["net_profit"])
            direction = row["direction"]
            ex = compute_excursion(
                args.symbol,
                point,
                args.sl_points,
                pid,
                direction,
                entry_t,
                close_t,
                net,
                history_index,
            )
            excursions[pid] = ex
            if (i + 1) % 200 == 0:
                print(f"  ... {i + 1}/{len(deal_rows)}")

        trades = list(excursions.values())
        nonzero_mfe = sum(1 for t in trades if t.mfe_r > 0.001)
        print(f"Computed {len(trades)} positions, nonzero mfe_r: {nonzero_mfe}")

        deals_out = out_dir / "AEC_P7-D_deals.csv"
        buckets_out = out_dir / "AEC_P7-D_mae_mfe_buckets.csv"
        write_enriched_deals(deals_out, deal_rows, excursions)
        write_buckets(buckets_out, trades)
        print(f"Wrote {deals_out}")
        print(f"Wrote {buckets_out}")

        losers = [t for t in trades if t.net < 0]
        if losers:
            dead = sum(1 for t in losers if t.mfe_r < 0.2)
            fought = sum(1 for t in losers if t.mfe_r >= 0.5)
            print(
                f"Losers {len(losers)}: never_green {dead} ({100*dead/len(losers):.1f}%), "
                f"fought_mfe05 {fought} ({100*fought/len(losers):.1f}%)"
            )
    finally:
        mt5.shutdown()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
