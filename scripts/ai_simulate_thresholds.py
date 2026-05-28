#!/usr/bin/env python3
"""
EDGE-AI-2 — Simulate skip-if P(take) < tau on historical deals (no MT5 rerun).

  python scripts/ai_simulate_thresholds.py

Requires ai_build_dataset.py + ai_train_skip_model.py outputs.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import DEFAULT_AI_DIR, FEATURE_COLS, REF_T48, REF_T51, pf_net_stats, write_json

try:
    import numpy as np
except ImportError:
    print("pip install numpy")
    sys.exit(1)


def load_model(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def score_rows(model: dict, rows: list[dict]) -> np.ndarray:
    mean = np.array(model["scaler_mean"])
    scale = np.array(model["scaler_scale"])
    coef = np.array(model["coef"])
    intercept = model["intercept"]
    x = np.array([[int(r[c]) for c in FEATURE_COLS] for r in rows], dtype=float)
    xs = (x - mean) / scale
    logit = intercept + xs @ coef
    return 1.0 / (1.0 + np.exp(-logit))


def load_csv(path: Path) -> list[dict]:
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument("--tau-min", type=float, default=0.35)
    ap.add_argument("--tau-max", type=float, default=0.65)
    ap.add_argument("--tau-step", type=float, default=0.05)
    args = ap.parse_args()
    d = args.data_dir
    model_path = d / "model_sklearn.json"
    all_path = d / "aec_trades_ml.csv"
    hold_path = d / "aec_trades_holdout.csv"
    if not model_path.is_file() or not all_path.is_file():
        print("Run ai_build_dataset.py and ai_train_skip_model.py first.")
        sys.exit(1)

    model = load_model(model_path)
    all_rows = load_csv(all_path)
    hold_rows = load_csv(hold_path) if hold_path.is_file() else []
    proba_all = score_rows(model, all_rows)
    proba_hold = score_rows(model, hold_rows) if hold_rows else np.array([])

    baseline_all = pf_net_stats([float(r["net_profit"]) for r in all_rows])
    baseline_hold = pf_net_stats([float(r["net_profit"]) for r in hold_rows]) if hold_rows else {}

    sweep = []
    tau = args.tau_min
    while tau <= args.tau_max + 1e-9:
        sweep.append(
            {
                "tau": round(tau, 2),
                "full": simulate(all_rows, proba_all, tau),
                "holdout": simulate(hold_rows, proba_hold, tau) if hold_rows else {},
            }
        )
        tau += args.tau_step

    def passes_t48(s: dict) -> bool:
        return s.get("pf", 0) >= REF_T48["pf"] and s.get("net", 0) > REF_T48["net"]

    def passes_t51(s: dict) -> bool:
        if not s:
            return False
        return s.get("pf", 0) >= 1.05 and s.get("net", 0) > 0

    best = None
    for row in sweep:
        f = row["full"]
        h = row["holdout"]
        if passes_t48(f) and passes_t51(h):
            if best is None or f["net"] > best["full"]["net"]:
                best = row

    out_csv = d / "threshold_sweep.csv"
    with out_csv.open("w", encoding="utf-8", newline="") as f:
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
        ]
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for row in sweep:
            fu, ho = row["full"], row.get("holdout") or {}
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
                }
            )

    summary = {
        "baseline_full": baseline_all,
        "baseline_holdout": baseline_hold,
        "ref_T48": REF_T48,
        "ref_T51": REF_T51,
        "best_tau": best["tau"] if best else None,
        "best_full": best["full"] if best else None,
        "best_holdout": best.get("holdout") if best else None,
        "verdict": "promising" if best else "reject_offline",
    }
    write_json(d / "threshold_sweep_summary.json", summary)

    print("EDGE-AI-2 threshold sweep\n")
    print(f"Baseline full:  trades={baseline_all['trades']} net={baseline_all['net']} PF={baseline_all['pf']}")
    print(f"Reference T48:  trades={REF_T48['trades']} net={REF_T48['net']} PF={REF_T48['pf']}")
    print(f"\n{'tau':>5} {'trades':>7} {'net':>9} {'PF':>6} {'skip%':>7}  | holdout net PF")
    for row in sweep:
        fu, ho = row["full"], row.get("holdout") or {}
        hn = f"{ho.get('net', 0):>7.1f} {ho.get('pf', 0):>5.2f}" if ho else "   —    —"
        print(
            f"{row['tau']:>5.1f} {fu.get('trades', 0):>7} {fu.get('net', 0):>9.2f} "
            f"{fu.get('pf', 0):>6.3f} {fu.get('skip_pct', 0):>6.1f}%  | {hn}"
        )

    if best:
        print(f"\nBest offline tau*: {best['tau']} (beats T48 net+PF, holdout PASS gate)")
        print("Next: EDGE-AI-4 MQL5 gate if you want live tester validation.")
    else:
        print("\nNo tau beat T48 on full range with holdout PASS — stay on P5-F or try AI-3 features.")
    print(f"\nWrote: {out_csv}")


if __name__ == "__main__":
    main()
