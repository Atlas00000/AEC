#!/usr/bin/env python3
"""
EDGE-AI-0 / EDGE-AI-3.2 — Build ML dataset from AEC deal (+ optional signal feature) CSVs.

  python scripts/ai_build_dataset.py
  python scripts/ai_build_dataset.py --files-dir "C:\\...\\MQL5\\Files"
  python scripts/ai_build_dataset.py --deals AEC_P10-E_deals.csv --features AEC_P10-E_signal_features.csv

Requires deal CSVs with mfe_r/mae_r (P10-E/P10-A/P7-D export).
Signal join: entry_time = signal_time + --bar-minutes (default 5 for M5).
"""

from __future__ import annotations

import argparse
import sys
from datetime import timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    DEFAULT_TESTER_FILES,
    REF_T48,
    SIGNAL_FEATURE_MERGE_COLS,
    DealRow,
    merge_features_into_ml_row,
    read_deals_csv,
    read_signal_features_csv,
    row_to_ml_dict,
    signal_features_by_entry_time,
    write_csv,
    write_json,
)

DEAL_SOURCES = (
    ("P10-E_full", "AEC_P10-E_deals.csv", None),
    ("P8-A_train", "AEC_P8-A_train_deals.csv", "train"),
    ("P8-B_holdout", "AEC_P8-B_holdout_deals.csv", "holdout"),
    ("P10-A_full", "AEC_P10-A_deals.csv", None),
    ("P7-D_full", "AEC_P7-D_deals.csv", None),
)

DEFAULT_FEATURES_FILE = "AEC_P10-E_signal_features.csv"

BASE_OUT_FIELDS = [
    "close_time",
    "entry_time",
    "entry_year",
    "entry_hour",
    "entry_weekday",
    "entry_month",
    "direction",
    "is_buy",
    "net_profit",
    "mfe_r",
    "mae_r",
    "net_r",
    "label_L1_take",
    "label_L2_take",
    "label_L3_take",
    "label_L4_take",
    "label_never_green",
    "label_fought",
    "split",
    "source",
    "position_id",
    "feature_join_ok",
    "hour_x_buy",
]

OUT_FIELDS_V2 = BASE_OUT_FIELDS + list(SIGNAL_FEATURE_MERGE_COLS)

SIGNALS_OUT_FIELDS = [
    "signal_time",
    "entry_time",
    "symbol",
    "direction",
    "outcome",
    "split",
    "entry_year",
    "net_profit",
    "mfe_r",
    "mae_r",
    "label_L3_take",
    "feature_join_ok",
] + list(SIGNAL_FEATURE_MERGE_COLS)


def build_signals_ml(
    feature_rows: list[dict],
    deal_index: dict[tuple[str, str], dict],
    bar_minutes: int,
) -> list[dict]:
    from ai_common import TRAIN_YEAR_MAX, parse_dt

    rows: list[dict] = []
    for r in feature_rows:
        signal_time = r.get("signal_time", "").strip()
        direction = r.get("direction", "").strip()
        if not signal_time or not direction:
            continue
        entry_time = (parse_dt(signal_time) + timedelta(minutes=bar_minutes)).strftime(
            "%Y.%m.%d %H:%M:%S"
        )
        year = parse_dt(entry_time).year
        split = "train" if year <= TRAIN_YEAR_MAX else "holdout"
        merged = merge_features_into_ml_row(
            {
                "entry_time": entry_time,
                "entry_hour": int(r.get("entry_hour", 0) or 0),
                "is_buy": 1 if direction == "BUY" else 0,
            },
            r,
        )
        deal = deal_index.get((entry_time, direction))
        row = {
            "signal_time": signal_time,
            "entry_time": entry_time,
            "symbol": r.get("symbol", ""),
            "direction": direction,
            "outcome": r.get("outcome", ""),
            "split": split,
            "entry_year": year,
            "net_profit": "",
            "mfe_r": "",
            "mae_r": "",
            "label_L3_take": "",
            "feature_join_ok": merged["feature_join_ok"],
        }
        for col in SIGNAL_FEATURE_MERGE_COLS:
            if col != "signal_time":
                row[col] = merged.get(col, "")
        if deal:
            row["net_profit"] = deal["net_profit"]
            row["mfe_r"] = deal["mfe_r"]
            row["mae_r"] = deal["mae_r"]
            row["label_L3_take"] = deal["label_L3_take"]
        rows.append(row)
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-0 / 3.2 dataset build")
    ap.add_argument("--files-dir", type=Path, default=DEFAULT_TESTER_FILES)
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument("--deals", type=str, default="", help="Single deals CSV (overrides source list)")
    ap.add_argument("--features", type=str, default="", help="Signal features CSV for v2 merge")
    ap.add_argument("--bar-minutes", type=int, default=5, help="entry_time - signal_time (M5=5)")
    ap.add_argument("--fallback-p7d-only", action="store_true", help="Use only P7-D if P8 missing")
    ap.add_argument("--no-v1-only", action="store_true", help="Skip v2 columns even if features missing")
    args = ap.parse_args()

    all_deals: list[DealRow] = []
    loaded: list[tuple[str, int, Path]] = []

    if args.deals:
        path = args.files_dir / args.deals
        chunk = read_deals_csv(path, "custom_deals", None)
        if chunk:
            all_deals.extend(chunk)
            loaded.append(("custom_deals", len(chunk), path))
        else:
            print(f"Missing deals file: {path}")
            sys.exit(1)
    else:
        for name, fname, split_ov in DEAL_SOURCES:
            path = args.files_dir / fname
            chunk = read_deals_csv(path, name, split_ov)
            if chunk:
                all_deals.extend(chunk)
                loaded.append((name, len(chunk), path))
            elif not args.fallback_p7d_only or name in ("P10-A_full", "P10-D_full", "P7-D_full"):
                print(f"  skip (missing): {fname}")

    if not all_deals:
        print("No deal rows loaded. Run P10-E (or P10-A / P7-D / P8-A+B) with InpExportDeals=true.")
        print(f"Expected under: {args.files_dir}")
        sys.exit(1)

    prio = {
        "P10-E_full": 0,
        "P8-A_train": 1,
        "P8-B_holdout": 1,
        "P10-A_full": 2,
        "P7-D_full": 3,
        "custom_deals": 0,
    }
    by_pos: dict[str, DealRow] = {}
    for d in sorted(all_deals, key=lambda x: prio.get(x.source, 99)):
        key = d.position_id if d.position_id else f"_{d.deal_id}_{d.close_time}"
        if key not in by_pos or prio.get(d.source, 99) < prio.get(by_pos[key].source, 99):
            by_pos[key] = d

    features_path = args.files_dir / (args.features or DEFAULT_FEATURES_FILE)
    feature_rows = read_signal_features_csv(features_path)
    use_v2 = bool(feature_rows) and not args.no_v1_only
    feat_index = (
        signal_features_by_entry_time(feature_rows, bar_minutes=args.bar_minutes)
        if use_v2
        else {}
    )

    ml_rows: list[dict] = []
    join_ok = 0
    for d in by_pos.values():
        base = row_to_ml_dict(d)
        key = (d.entry_time, d.direction)
        feat = feat_index.get(key) if use_v2 else None
        if use_v2:
            row = merge_features_into_ml_row(base, feat)
            if row["feature_join_ok"]:
                join_ok += 1
        else:
            row = base
        ml_rows.append(row)

    out_fields = OUT_FIELDS_V2 if use_v2 else BASE_OUT_FIELDS
    train_rows = [r for r in ml_rows if r["split"] == "train"]
    holdout_rows = [r for r in ml_rows if r["split"] == "holdout"]

    missing_mfe = sum(1 for r in ml_rows if r["mfe_r"] == 0.0 and r["label_never_green"] == 0)
    if missing_mfe > len(ml_rows) * 0.5:
        print(
            "WARNING: >50% rows have mfe_r=0 — run p7d_mae_mfe_postprocess.py or enable InpExportMaeMfe."
        )

    if use_v2 and join_ok < len(ml_rows):
        print(
            f"WARNING: feature join matched {join_ok}/{len(ml_rows)} trades "
            f"(bar_minutes={args.bar_minutes}). Check TF or --bar-minutes."
        )

    out = args.out_dir
    write_csv(out / "aec_trades_ml.csv", ml_rows, out_fields)
    write_csv(out / "aec_trades_train.csv", train_rows, out_fields)
    write_csv(out / "aec_trades_holdout.csv", holdout_rows, out_fields)

    if use_v2 and feature_rows:
        deal_lookup = {((r["entry_time"], r["direction"])): r for r in ml_rows}
        signals_rows = build_signals_ml(feature_rows, deal_lookup, args.bar_minutes)
        write_csv(out / "aec_signals_ml.csv", signals_rows, SIGNALS_OUT_FIELDS)

    def split_stats(rows: list[dict]) -> dict:
        n = len(rows)
        if n == 0:
            return {"trades": 0}
        return {
            "trades": n,
            "pct_L3_take": round(100 * sum(r["label_L3_take"] for r in rows) / n, 2),
            "pct_never_green": round(100 * sum(r["label_never_green"] for r in rows) / n, 2),
            "pct_L1_win": round(100 * sum(r["label_L1_take"] for r in rows) / n, 2),
            "net_sum": round(sum(r["net_profit"] for r in rows), 2),
        }

    summary = {
        "schema": "v2" if use_v2 else "v1",
        "feature_file": str(features_path) if use_v2 else None,
        "bar_minutes": args.bar_minutes if use_v2 else None,
        "feature_join_matched": join_ok if use_v2 else None,
        "loaded_sources": [{"name": n, "rows": c, "path": str(p)} for n, c, p in loaded],
        "unique_trades": len(ml_rows),
        "train": split_stats(train_rows),
        "holdout": split_stats(holdout_rows),
        "ref_T48": REF_T48,
        "outputs": {
            "all": str(out / "aec_trades_ml.csv"),
            "train": str(out / "aec_trades_train.csv"),
            "holdout": str(out / "aec_trades_holdout.csv"),
        },
    }
    if use_v2 and feature_rows:
        summary["outputs"]["signals"] = str(out / "aec_signals_ml.csv")
        summary["signal_rows"] = len(feature_rows)

    write_json(out / "dataset_summary.json", summary)

    print("EDGE-AI-3.2 dataset build\n")
    for n, c, p in loaded:
        print(f"  {n}: {c} rows from {p.name}")
    if use_v2:
        print(f"  features: {len(feature_rows)} rows from {features_path.name}")
        print(f"  join: {join_ok}/{len(ml_rows)} trades matched (entry = signal + {args.bar_minutes}m)")
    print(f"\nUnique trades: {len(ml_rows)}  (train {len(train_rows)} / holdout {len(holdout_rows)})")
    print(f"Train L3_take%: {summary['train'].get('pct_L3_take', '—')}%  never_green: {summary['train'].get('pct_never_green', '—')}%")
    print(f"Holdout L3_take%: {summary['holdout'].get('pct_L3_take', '—')}%")
    print(f"\nWrote: {out / 'aec_trades_ml.csv'} ({summary['schema']})")
    if use_v2:
        print(f"       {out / 'aec_signals_ml.csv'}")
    print("Next: python scripts/ai_train_skip_model.py  (v1) or EDGE-AI-3.3 LightGBM")


if __name__ == "__main__":
    main()
