#!/usr/bin/env python3
"""
EDGE-AI-3.4 — τ sweep for LightGBM v2 vs T70/T71 (offline replay on P10-E deals).

  python scripts/ai_simulate_thresholds_v2.py

Requires ai_build_dataset.py + ai_train_lgbm.py outputs.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    FEATURE_COLS_V2,
    REF_T48,
    REF_T51,
    REF_T70,
    REF_T71,
    feature_value,
    pf_net_stats,
    read_ml_csv,
    write_json,
)

try:
    import lightgbm as lgb
    import numpy as np
except ImportError:
    print("pip install lightgbm numpy")
    sys.exit(1)


def score_rows(model: lgb.Booster, rows: list[dict]) -> np.ndarray:
    if not rows:
        return np.array([])
    x = np.array(
        [[feature_value(r, c) for c in FEATURE_COLS_V2] for r in rows],
        dtype=float,
    )
    return model.predict(x)


def simulate(rows: list[dict], proba: np.ndarray, tau: float) -> dict:
    kept_nets = []
    skipped_ng = 0
    skipped_total = 0
    for r, p in zip(rows, proba):
        if p < tau:
            skipped_total += 1
            if int(r["label_never_green"]) == 1:
                skipped_ng += 1
            continue
        kept_nets.append(float(r["net_profit"]))
    stats = pf_net_stats(kept_nets)
    stats["skipped"] = skipped_total
    stats["skipped_never_green"] = skipped_ng
    stats["skip_pct"] = round(100 * skipped_total / len(rows), 2) if rows else 0
    stats["tau"] = tau
    return stats


def passes_t70(s: dict) -> bool:
    return s.get("pf", 0) >= REF_T70["pf"] and s.get("net", 0) >= REF_T70["net"]


def passes_t71(s: dict) -> bool:
    if not s:
        return False
    return s.get("pf", 0) >= REF_T71["pf"] and s.get("net", 0) >= REF_T71["net"]


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-3.4 v2 threshold sweep")
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument("--tau-min", type=float, default=0.75)
    ap.add_argument("--tau-max", type=float, default=0.90)
    ap.add_argument("--tau-step", type=float, default=0.01)
    args = ap.parse_args()
    d = args.data_dir
    model_txt = d / "model_lgbm.txt"
    meta_path = d / "model_lgbm.json"
    all_path = d / "aec_trades_ml.csv"
    hold_path = d / "aec_trades_holdout.csv"
    if not model_txt.is_file() or not all_path.is_file():
        print("Run ai_build_dataset.py and ai_train_lgbm.py first.")
        sys.exit(1)

    model = lgb.Booster(model_file=str(model_txt))
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.is_file() else {}

    all_rows = [r for r in read_ml_csv(all_path) if int(r.get("feature_join_ok", 0) or 0) == 1]
    hold_rows = [r for r in read_ml_csv(hold_path) if int(r.get("feature_join_ok", 0) or 0) == 1]

    proba_all = score_rows(model, all_rows)
    proba_hold = score_rows(model, hold_rows)

    baseline_all = pf_net_stats([float(r["net_profit"]) for r in all_rows])
    baseline_hold = pf_net_stats([float(r["net_profit"]) for r in hold_rows])

    sweep = []
    tau = args.tau_min
    while tau <= args.tau_max + 1e-9:
        sweep.append(
            {
                "tau": round(tau, 2),
                "full": simulate(all_rows, proba_all, tau),
                "holdout": simulate(hold_rows, proba_hold, tau),
            }
        )
        tau += args.tau_step

    best_t70 = None
    best_t70_t71 = None
    for row in sweep:
        f, h = row["full"], row["holdout"]
        if passes_t70(f):
            if best_t70 is None or f["net"] > best_t70["full"]["net"]:
                best_t70 = row
        if passes_t70(f) and passes_t71(h):
            if best_t70_t71 is None or f["net"] > best_t70_t71["full"]["net"]:
                best_t70_t71 = row

    out_csv = d / "threshold_sweep_v2.csv"
    fields = [
        "tau",
        "full_trades",
        "full_net",
        "full_pf",
        "full_wr",
        "full_skip_pct",
        "hold_trades",
        "hold_net",
        "hold_pf",
        "hold_wr",
        "beats_T70",
        "beats_T71",
    ]
    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for row in sweep:
            fu, ho = row["full"], row["holdout"]
            w.writerow(
                {
                    "tau": row["tau"],
                    "full_trades": fu.get("trades", 0),
                    "full_net": fu.get("net", 0),
                    "full_pf": fu.get("pf", 0),
                    "full_wr": fu.get("wr", 0),
                    "full_skip_pct": fu.get("skip_pct", 0),
                    "hold_trades": ho.get("trades", 0),
                    "hold_net": ho.get("net", 0),
                    "hold_pf": ho.get("pf", 0),
                    "hold_wr": ho.get("wr", 0),
                    "beats_T70": int(passes_t70(fu)),
                    "beats_T71": int(passes_t71(ho)),
                }
            )

    v1_best = None
    v1_path = d / "threshold_sweep_summary.json"
    if v1_path.is_file():
        v1_best = json.loads(v1_path.read_text(encoding="utf-8")).get("best_tau")

    summary = {
        "model": meta,
        "baseline_full": baseline_all,
        "baseline_holdout": baseline_hold,
        "ref_T48": REF_T48,
        "ref_T51": REF_T51,
        "ref_T70": REF_T70,
        "ref_T71": REF_T71,
        "v1_logistic_best_tau": v1_best,
        "best_tau_t70": best_t70["tau"] if best_t70 else None,
        "best_t70_full": best_t70["full"] if best_t70 else None,
        "best_tau_t70_t71": best_t70_t71["tau"] if best_t70_t71 else None,
        "best_t70_t71_full": best_t70_t71["full"] if best_t70_t71 else None,
        "best_t70_t71_holdout": best_t70_t71.get("holdout") if best_t70_t71 else None,
        "verdict": "promote_candidate" if best_t70_t71 else ("beats_T70_only" if best_t70 else "reject_offline"),
    }
    write_json(d / "threshold_sweep_v2_summary.json", summary)

    print("EDGE-AI-3.4 v2 threshold sweep (LightGBM)\n")
    print(
        f"Baseline (no skip): trades={baseline_all['trades']} net={baseline_all['net']} "
        f"PF={baseline_all['pf']}  (P10-E stack, no v2 gate)"
    )
    print(f"Reference T70:      net={REF_T70['net']} PF={REF_T70['pf']} trades={REF_T70['trades']}")
    print(f"Reference T71:      net={REF_T71['net']} PF={REF_T71['pf']} trades={REF_T71['trades']}")
    if v1_best is not None:
        print(f"v1 logistic best tau: {v1_best}\n")
    else:
        print()

    print(f"{'tau':>5} {'trades':>7} {'net':>9} {'PF':>6} {'skip%':>7}  | holdout net   PF  T70 T71")
    for row in sweep:
        fu, ho = row["full"], row["holdout"]
        flag = ""
        if passes_t70(fu) and passes_t71(ho):
            flag = " **"
        elif passes_t70(fu):
            flag = " T70"
        print(
            f"{row['tau']:>5.2f} {fu.get('trades', 0):>7} {fu.get('net', 0):>9.2f} "
            f"{fu.get('pf', 0):>6.3f} {fu.get('skip_pct', 0):>6.1f}%  | "
            f"{ho.get('net', 0):>7.2f} {ho.get('pf', 0):>5.2f}  "
            f"{int(passes_t70(fu))}   {int(passes_t71(ho))}{flag}"
        )

    if best_t70_t71:
        print(
            f"\nBest tau (T70+T71): {best_t70_t71['tau']} — full net={best_t70_t71['full']['net']} "
            f"PF={best_t70_t71['full']['pf']} | holdout net={best_t70_t71['holdout']['net']} "
            f"PF={best_t70_t71['holdout']['pf']}"
        )
        print("Next: EDGE-AI-3.7 MQL5 gate v2 if you want tester validation.")
    elif best_t70:
        print(f"\nBest tau (T70 only): {best_t70['tau']} - holdout did not beat T71 bar.")
    else:
        print("\nNo tau beat T70 offline - keep P10-B v1 gate or tune features.")
    print(f"\nWrote: {out_csv}")


if __name__ == "__main__":
    main()
