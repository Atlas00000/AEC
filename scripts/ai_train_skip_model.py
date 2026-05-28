#!/usr/bin/env python3
"""
EDGE-AI-1 — Train skip classifier on train split (label L3_take default).

  pip install scikit-learn
  python scripts/ai_train_skip_model.py

Writes data/ai/model_sklearn.json + metrics report.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import DEFAULT_AI_DIR, FEATURE_COLS, REF_T48, REF_T51, write_json

try:
    import numpy as np
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import (
        accuracy_score,
        classification_report,
        roc_auc_score,
    )
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler
except ImportError:
    print("Install: pip install scikit-learn numpy")
    sys.exit(1)


def load_split(path: Path) -> tuple[np.ndarray, np.ndarray, list[float]]:
    import csv

    rows = []
    with path.open(encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            rows.append(r)
    if not rows:
        return np.empty((0, len(FEATURE_COLS))), np.empty(0), []
    x = np.array(
        [[int(r[c]) for c in FEATURE_COLS] for r in rows],
        dtype=float,
    )
    label_key = "label_L3_take"
    y = np.array([int(r[label_key]) for r in rows], dtype=int)
    nets = [float(r["net_profit"]) for r in rows]
    return x, y, nets


def coef_report(pipe: Pipeline, feature_names: tuple[str, ...]) -> list[dict]:
    lr: LogisticRegression = pipe.named_steps["clf"]
    coefs = lr.coef_[0]
    pairs = sorted(zip(feature_names, coefs), key=lambda t: abs(t[1]), reverse=True)
    return [{"feature": f, "coef": round(c, 4)} for f, c in pairs]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    args = ap.parse_args()
    d = args.data_dir
    train_p = d / "aec_trades_train.csv"
    hold_p = d / "aec_trades_holdout.csv"
    if not train_p.is_file():
        print(f"Missing {train_p} — run: python scripts/ai_build_dataset.py")
        sys.exit(1)

    x_train, y_train, _ = load_split(train_p)
    x_hold, y_hold, nets_hold = load_split(hold_p)

    pipe = Pipeline(
        [
            ("scale", StandardScaler()),
            ("clf", LogisticRegression(max_iter=2000, class_weight="balanced")),
        ]
    )
    pipe.fit(x_train, y_train)

    def eval_split(name: str, x, y) -> dict:
        if len(y) == 0:
            return {"name": name, "n": 0}
        pred = pipe.predict(x)
        proba = pipe.predict_proba(x)[:, 1]
        out = {
            "name": name,
            "n": int(len(y)),
            "accuracy": round(accuracy_score(y, pred), 4),
            "roc_auc": round(roc_auc_score(y, proba), 4) if len(set(y)) > 1 else None,
            "report": classification_report(y, pred, output_dict=True, zero_division=0),
        }
        return out

    train_m = eval_split("train", x_train, y_train)
    hold_m = eval_split("holdout", x_hold, y_hold)

    # Serialize coefficients for simple MT5 gate later
    lr: LogisticRegression = pipe.named_steps["clf"]
    scaler: StandardScaler = pipe.named_steps["scale"]
    model_out = {
        "type": "logistic_l3_take",
        "features": list(FEATURE_COLS),
        "scaler_mean": scaler.mean_.tolist(),
        "scaler_scale": scaler.scale_.tolist(),
        "coef": lr.coef_[0].tolist(),
        "intercept": float(lr.intercept_[0]),
    }
    write_json(d / "model_sklearn.json", model_out)

    report = {
        "label": "label_L3_take",
        "train": train_m,
        "holdout": hold_m,
        "coefficients": coef_report(pipe, FEATURE_COLS),
        "ref_T48": REF_T48,
        "ref_T51": REF_T51,
        "next": "python scripts/ai_simulate_thresholds.py",
    }
    write_json(d / "train_metrics.json", report)

    print("EDGE-AI-1 train (LogisticRegression, L3_take)\n")
    print(f"Train n={train_m['n']}  acc={train_m.get('accuracy')}  AUC={train_m.get('roc_auc')}")
    if hold_m["n"]:
        print(f"Holdout n={hold_m['n']}  acc={hold_m.get('accuracy')}  AUC={hold_m.get('roc_auc')}")
    print("\nTop coefficients:")
    for c in report["coefficients"][:6]:
        print(f"  {c['feature']:16} {c['coef']:+.4f}")
    print(f"\nModel: {d / 'model_sklearn.json'}")
    print("Next: python scripts/ai_simulate_thresholds.py")


if __name__ == "__main__":
    main()
