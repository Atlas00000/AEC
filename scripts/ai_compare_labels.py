#!/usr/bin/env python3
"""
EDGE-AI-3.6 — Compare L1/L2/L3/L4 labels (LightGBM + offline tau vs T70/T71).

  python scripts/ai_compare_labels.py

Requires aec_trades_ml.csv (v2) from ai_build_dataset.py.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    FEATURE_COLS_V2,
    REF_T70,
    REF_T71,
    REPO_ROOT,
    RISK_DOLLARS_PER_R,
    compute_labels,
    feature_value,
    pf_net_stats,
    read_ml_csv,
    write_json,
)

try:
    import lightgbm as lgb
    import numpy as np
    from sklearn.metrics import roc_auc_score
except ImportError:
    print("Install: pip install lightgbm scikit-learn numpy")
    sys.exit(1)

LABELS = (
    ("L1", "label_L1_take", "net_profit > 0 (profitable close)"),
    ("L2", "label_L2_take", "mfe_r >= 1.0 (reached 1R favorable)"),
    ("L3", "label_L3_take", "not never-green loser (mfe_r < 0.2 on loss)"),
    ("L4", "label_L4_take", "net_r >= 0.5 (~half R at close)"),
)

LGB_PARAMS = {
    "objective": "binary",
    "metric": "auc",
    "verbosity": -1,
    "learning_rate": 0.05,
    "num_leaves": 31,
    "min_data_in_leaf": 25,
    "feature_fraction": 0.85,
    "bagging_fraction": 0.85,
    "bagging_freq": 1,
    "seed": 42,
}


def ensure_labels(rows: list[dict]) -> None:
    for r in rows:
        if "label_L2_take" in r and r.get("label_L2_take", "") != "":
            continue
        net = float(r["net_profit"])
        mfe = float(r["mfe_r"])
        r.update(compute_labels(net, mfe))


def split_rows(rows: list[dict]) -> tuple[list[dict], list[dict]]:
    train = [r for r in rows if r.get("split") == "train"]
    hold = [r for r in rows if r.get("split") == "holdout"]
    return train, hold


def to_xy(rows: list[dict], label_key: str) -> tuple[np.ndarray, np.ndarray]:
    x = np.array([[feature_value(r, c) for c in FEATURE_COLS_V2] for r in rows], dtype=float)
    y = np.array([int(r[label_key]) for r in rows], dtype=int)
    return x, y


def train_lgb(x_train: np.ndarray, y_train: np.ndarray, x_hold: np.ndarray, y_hold: np.ndarray) -> lgb.Booster:
    train_set = lgb.Dataset(x_train, label=y_train, feature_name=list(FEATURE_COLS_V2))
    valid_set = lgb.Dataset(x_hold, label=y_hold, feature_name=list(FEATURE_COLS_V2), reference=train_set)
    return lgb.train(
        LGB_PARAMS,
        train_set,
        num_boost_round=500,
        valid_sets=[valid_set],
        callbacks=[lgb.early_stopping(50, verbose=False), lgb.log_evaluation(0)],
    )


def auc_safe(y: np.ndarray, proba: np.ndarray) -> float | None:
    if len(y) == 0 or len(set(y)) < 2:
        return None
    return round(float(roc_auc_score(y, proba)), 4)


def simulate_tau(rows: list[dict], proba: np.ndarray, tau: float) -> dict:
    nets = []
    for r, p in zip(rows, proba):
        if p >= tau:
            nets.append(float(r["net_profit"]))
    return pf_net_stats(nets)


def best_tau_for_t70_t71(
    all_rows: list[dict], hold_rows: list[dict], proba_all: np.ndarray, proba_hold: np.ndarray
) -> dict:
    best = {"tau": None, "full": {}, "holdout": {}, "passes_t70": False, "passes_t71": False}
    for tau_i in range(75, 91):
        tau = tau_i / 100.0
        full = simulate_tau(all_rows, proba_all, tau)
        hold = simulate_tau(hold_rows, proba_hold, tau)
        t70 = full.get("pf", 0) >= REF_T70["pf"] and full.get("net", 0) >= REF_T70["net"]
        t71 = hold.get("pf", 0) >= REF_T71["pf"] and hold.get("net", 0) >= REF_T71["net"]
        if t70 and t71:
            if best["tau"] is None or full.get("net", 0) > best["full"].get("net", -1e9):
                best = {
                    "tau": tau,
                    "full": full,
                    "holdout": hold,
                    "passes_t70": True,
                    "passes_t71": True,
                }
    if best["tau"] is not None:
        return best
    # fallback: best T70 only
    for tau_i in range(75, 91):
        tau = tau_i / 100.0
        full = simulate_tau(all_rows, proba_all, tau)
        t70 = full.get("pf", 0) >= REF_T70["pf"] and full.get("net", 0) >= REF_T70["net"]
        if t70 and (best["tau"] is None or full.get("net", 0) > best["full"].get("net", -1e9)):
            best = {
                "tau": tau,
                "full": full,
                "holdout": simulate_tau(hold_rows, proba_hold, tau),
                "passes_t70": True,
                "passes_t71": False,
            }
    return best


def label_stats(rows: list[dict], key: str) -> dict:
    n = len(rows)
    if n == 0:
        return {"n": 0, "positive_pct": 0.0}
    pos = sum(int(r[key]) for r in rows)
    return {"n": n, "positive_pct": round(100.0 * pos / n, 2)}


def write_readout_md(path: Path, results: list[dict], baseline: dict) -> None:
    lines = [
        "# EDGE-AI-3.6 — Label comparison (L1–L4)",
        "",
        "Model: LightGBM v2 features · train <= 2023 · tau grid 0.75–0.90",
        "",
        f"Baseline (no skip): net **{baseline['net']}** · PF **{baseline['pf']}** · {baseline['trades']} trades",
        "",
        "## Label definitions",
        "",
        "| ID | Column | Rule |",
        "|----|--------|------|",
    ]
    for lid, col, desc in LABELS:
        lines.append(f"| **{lid}** | `{col}` | {desc} |")
    lines.extend(
        [
            "",
            f"`net_r` = `net_profit` / {RISK_DOLLARS_PER_R} (fixed R dollars for 0.01 lot / 200pt SL)",
            "",
            "## Results",
            "",
            "| Label | Train %+ | Hold %+ | Train AUC | Hold AUC | Best tau | Full net | Full PF | Hold net | T70 | T71 |",
            "|-------|---------:|----------:|----------:|---------:|---------:|---------:|--------:|---------:|:---:|:---:|",
        ]
    )
    for r in results:
        lines.append(
            f"| **{r['id']}** | {r['train_pos_pct']} | {r['hold_pos_pct']} | "
            f"{r['train_auc']} | {r['hold_auc']} | {r['best_tau']} | "
            f"{r['full_net']} | {r['full_pf']} | {r['hold_net']} | "
            f"{'Y' if r['passes_t70'] else 'n'} | {'Y' if r['passes_t71'] else 'n'} |"
        )
    lines.extend(
        [
            "",
            "## Recommendation",
            "",
        ]
    )
    winners = [r for r in results if r["passes_t70"] and r["passes_t71"]]
    if winners:
        w = max(winners, key=lambda x: x["full_net"])
        lines.append(
            f"- **Primary label candidate:** **{w['id']}** (only label(s) passing T70+T71 offline at best tau)."
        )
    else:
        lines.append(
            "- **No label beat T70+T71** on holdout at useful tau — keep production **L3** + v1 logistic gate."
        )
        t70_only = [r for r in results if r["passes_t70"]]
        if t70_only:
            w = max(t70_only, key=lambda x: x["full_net"])
            lines.append(
                f"- Best **T70-only** offline: **{w['id']}** at tau={w['best_tau']} "
                f"(full net {w['full_net']}) — overfit risk on holdout."
            )
    lines.extend(
        [
            "",
            "Regenerate: `python scripts/ai_compare_labels.py`",
            "",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-3.6 label comparison")
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    args = ap.parse_args()
    d = args.data_dir
    ml_path = d / "aec_trades_ml.csv"
    if not ml_path.is_file():
        print("Run ai_build_dataset.py first.")
        sys.exit(1)

    rows = [r for r in read_ml_csv(ml_path) if int(r.get("feature_join_ok", 0) or 0) == 1]
    ensure_labels(rows)
    train_rows, hold_rows = split_rows(rows)
    if not train_rows or not hold_rows:
        print("Need train and holdout rows.")
        sys.exit(1)

    baseline = pf_net_stats([float(r["net_profit"]) for r in rows])
    results = []

    print("EDGE-AI-3.6 label comparison (LightGBM v2)\n")
    print(
        f"{'lbl':4} {'trn%+':>6} {'hld%+':>6} {'trAUC':>6} {'hoAUC':>6} "
        f"{'tau':>5} {'net':>8} {'PF':>5} {'h.net':>7} T70 T71"
    )

    for lid, key, _desc in LABELS:
        x_tr, y_tr = to_xy(train_rows, key)
        x_ho, y_ho = to_xy(hold_rows, key)
        model = train_lgb(x_tr, y_tr, x_ho, y_ho)
        p_all = model.predict(to_xy(rows, key)[0])
        p_ho = model.predict(x_ho)
        tr_auc = auc_safe(y_tr, model.predict(x_tr))
        ho_auc = auc_safe(y_ho, p_ho)
        best = best_tau_for_t70_t71(rows, hold_rows, p_all, p_ho)
        tr_s = label_stats(train_rows, key)
        ho_s = label_stats(hold_rows, key)
        entry = {
            "id": lid,
            "label_key": key,
            "train_pos_pct": tr_s["positive_pct"],
            "hold_pos_pct": ho_s["positive_pct"],
            "train_auc": tr_auc,
            "hold_auc": ho_auc,
            "best_iteration": model.best_iteration,
            "best_tau": best["tau"],
            "full_net": best["full"].get("net"),
            "full_pf": best["full"].get("pf"),
            "full_trades": best["full"].get("trades"),
            "hold_net": best["holdout"].get("net"),
            "hold_pf": best["holdout"].get("pf"),
            "passes_t70": best["passes_t70"],
            "passes_t71": best["passes_t71"],
        }
        results.append(entry)
        tau_s = f"{best['tau']:5.2f}" if best["tau"] is not None else "  n/a"
        print(
            f"{lid:4} {tr_s['positive_pct']:6.1f} {ho_s['positive_pct']:6.1f} "
            f"{tr_auc or 0:6.3f} {ho_auc or 0:6.3f} "
            f"{tau_s} {best['full'].get('net', 0):8.2f} "
            f"{best['full'].get('pf', 0):5.2f} {best['holdout'].get('net', 0):7.2f} "
            f"{'Y' if best['passes_t70'] else 'n'}   {'Y' if best['passes_t71'] else 'n'}"
        )

    out = {
        "baseline_full": baseline,
        "ref_T70": REF_T70,
        "ref_T71": REF_T71,
        "labels": results,
        "winner_t70_t71": next(
            (r["id"] for r in results if r["passes_t70"] and r["passes_t71"]), None
        ),
    }
    write_json(d / "label_comparison.json", out)
    readout = REPO_ROOT / "doc" / "edge-ai-3-6-label-comparison.md"
    write_readout_md(readout, results, baseline)

    print(f"\nWrote: {d / 'label_comparison.json'}")
    print(f"       {readout}")
    if out["winner_t70_t71"]:
        print(f"\nWinner (T70+T71): {out['winner_t70_t71']}")
    else:
        print("\nNo label passed T70+T71 — L3 remains default for skip gate.")


if __name__ == "__main__":
    main()
