#!/usr/bin/env python3
"""
EDGE-AI-3.3 — Train LightGBM skip classifier on v2 signal-bar features (L3_take).

  pip install lightgbm scikit-learn numpy
  python scripts/ai_train_lgbm.py

Writes data/ai/model_lgbm.txt + model_lgbm.json + train_metrics_lgbm.json
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    FEATURE_COLS_V2,
    REF_T48,
    REF_T51,
    REF_T70,
    feature_value,
    read_ml_csv,
    write_json,
)

try:
    import lightgbm as lgb
    import numpy as np
    from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
except ImportError:
    print("Install: pip install lightgbm scikit-learn numpy")
    sys.exit(1)


def rows_to_xy(rows: list[dict], label_key: str = "label_L3_take") -> tuple[np.ndarray, np.ndarray]:
    if not rows:
        return np.empty((0, len(FEATURE_COLS_V2))), np.empty(0)
    x = np.array(
        [[feature_value(r, c) for c in FEATURE_COLS_V2] for r in rows],
        dtype=float,
    )
    y = np.array([int(r[label_key]) for r in rows], dtype=int)
    return x, y


def eval_split(name: str, model: lgb.Booster, x: np.ndarray, y: np.ndarray) -> dict:
    if len(y) == 0:
        return {"name": name, "n": 0}
    proba = model.predict(x)
    pred = (proba >= 0.5).astype(int)
    return {
        "name": name,
        "n": int(len(y)),
        "accuracy": round(float(accuracy_score(y, pred)), 4),
        "roc_auc": round(float(roc_auc_score(y, proba)), 4) if len(set(y)) > 1 else None,
        "report": classification_report(y, pred, output_dict=True, zero_division=0),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-3.3 LightGBM train")
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument(
        "--label",
        default="label_L3_take",
        choices=("label_L3_take", "label_L1_take", "label_L2_take", "label_L4_take"),
    )
    args = ap.parse_args()
    d = args.data_dir
    train_p = d / "aec_trades_train.csv"
    hold_p = d / "aec_trades_holdout.csv"
    if not train_p.is_file():
        print(f"Missing {train_p} — run: python scripts/ai_build_dataset.py")
        sys.exit(1)

    train_rows = [r for r in read_ml_csv(train_p) if int(r.get("feature_join_ok", 0) or 0) == 1]
    hold_rows = [r for r in read_ml_csv(hold_p) if int(r.get("feature_join_ok", 0) or 0) == 1]

    x_train, y_train = rows_to_xy(train_rows, args.label)
    x_hold, y_hold = rows_to_xy(hold_rows, args.label)

    train_set = lgb.Dataset(x_train, label=y_train, feature_name=list(FEATURE_COLS_V2))
    valid_set = lgb.Dataset(x_hold, label=y_hold, feature_name=list(FEATURE_COLS_V2), reference=train_set)

    params = {
        "objective": "binary",
        "metric": "auc",
        "verbosity": -1,
        "learning_rate": 0.05,
        "num_leaves": 31,
        "min_data_in_leaf": 25,
        "feature_fraction": 0.85,
        "bagging_fraction": 0.85,
        "bagging_freq": 1,
        "lambda_l1": 0.1,
        "lambda_l2": 0.1,
        "seed": 42,
    }

    model = lgb.train(
        params,
        train_set,
        num_boost_round=500,
        valid_sets=[valid_set],
        callbacks=[lgb.early_stopping(50, verbose=False), lgb.log_evaluation(0)],
    )

    imp = sorted(
        zip(FEATURE_COLS_V2, model.feature_importance(importance_type="gain")),
        key=lambda t: t[1],
        reverse=True,
    )
    importance = [{"feature": f, "gain": int(g)} for f, g in imp[:20]]

    train_m = eval_split("train", model, x_train, y_train)
    hold_m = eval_split("holdout", model, x_hold, y_hold)

    model_path = d / "model_lgbm.txt"
    model.save_model(str(model_path))

    meta = {
        "type": "lightgbm",
        "label": args.label,
        "features": list(FEATURE_COLS_V2),
        "best_iteration": model.best_iteration,
        "params": params,
        "model_file": model_path.name,
    }
    write_json(d / "model_lgbm.json", meta)

    report = {
        "label": args.label,
        "train_rows": len(train_rows),
        "holdout_rows": len(hold_rows),
        "train": train_m,
        "holdout": hold_m,
        "importance_top20": importance,
        "ref_T48": REF_T48,
        "ref_T51": REF_T51,
        "ref_T70": REF_T70,
        "next": "python scripts/ai_simulate_thresholds_v2.py",
    }
    write_json(d / "train_metrics_lgbm.json", report)

    print("EDGE-AI-3.3 LightGBM train\n")
    print(f"Features: {len(FEATURE_COLS_V2)}  best_iter={model.best_iteration}")
    print(f"Train n={train_m['n']}  acc={train_m.get('accuracy')}  AUC={train_m.get('roc_auc')}")
    if hold_m["n"]:
        print(f"Holdout n={hold_m['n']}  acc={hold_m.get('accuracy')}  AUC={hold_m.get('roc_auc')}")
    print("\nTop importance (gain):")
    for row in importance[:8]:
        print(f"  {row['feature']:22} {row['gain']}")
    print(f"\nModel: {model_path}")
    print("Next: python scripts/ai_simulate_thresholds_v2.py")


if __name__ == "__main__":
    main()
