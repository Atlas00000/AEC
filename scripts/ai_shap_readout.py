#!/usr/bin/env python3
"""
EDGE-AI-3.5 — SHAP top-15 readout for LightGBM v2 (train split).

  pip install shap lightgbm numpy
  python scripts/ai_shap_readout.py

Writes data/ai/shap_top15.csv, shap_summary.json, doc/edge-ai-3-5-shap-readout.md
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    FEATURE_COLS_V2,
    REPO_ROOT,
    feature_value,
    read_ml_csv,
    write_json,
)

try:
    import lightgbm as lgb
    import numpy as np
    import shap
except ImportError:
    print("Install: pip install shap lightgbm numpy")
    sys.exit(1)


def rows_to_matrix(rows: list[dict]) -> np.ndarray:
    return np.array(
        [[feature_value(r, c) for c in FEATURE_COLS_V2] for r in rows],
        dtype=float,
    )


def mean_abs_shap(values: np.ndarray) -> np.ndarray:
    return np.abs(values).mean(axis=0)


def rank_features(names: tuple[str, ...], scores: np.ndarray, top_n: int) -> list[dict]:
    pairs = sorted(zip(names, scores), key=lambda t: float(t[1]), reverse=True)
    total = float(scores.sum()) or 1.0
    out = []
    for i, (name, score) in enumerate(pairs[:top_n], start=1):
        out.append(
            {
                "rank": i,
                "feature": name,
                "mean_abs_shap": round(float(score), 6),
                "pct_of_total": round(100.0 * float(score) / total, 2),
            }
        )
    return out


def suggest_rule(feature: str) -> str:
    hints = {
        "bb_width_vs_avg": "Favor releases where band width vs lookback avg is higher (not chop).",
        "bb_expand_ratio": "Stronger bar-over-bar BB expansion on release improves L3 score.",
        "struct_break_atr": "Deeper structure penetration (x ATR) associates with model confidence.",
        "prior_bar_range_atr": "Very wide prior bar vs ATR may reduce take quality.",
        "displacement_atr": "Larger displacement body (x ATR) on signal bar matters.",
        "squeeze_bars": "More consecutive squeeze bars before release (model input).",
        "entry_weekday": "Calendar weekday effect remains in v2 (secondary to BB/struct).",
        "entry_hour": "Session hour still contributes after signal features.",
        "entry_month": "Seasonal/month bucket — weak alone, keep for regime work (AI-8).",
        "is_buy": "Direction asymmetry: BUY vs SELL baseline differs.",
        "hour_x_buy": "Interaction: morning BUY hours vs other slots.",
        "spread_pts": "Tighter spread at signal slightly favored.",
        "loss_streak": "Post-loss streak not used by this shallow model (gain=0).",
        "atr_value": "Absolute ATR level has minor role.",
        "atr_percentile": "Regime vol percentile unused in P10-E (filter off in export).",
        "adx_value": "ADX at signal unused in P10-E (filter off).",
    }
    for prefix in ("pass_bb", "pass_vol", "pass_struct", "pass_ema", "pass_disp"):
        if feature.startswith("pass_"):
            return "Leg pass flags are constant=1 on executed rows; no SHAP signal here."
    return hints.get(feature, "Review distribution vs label_L3_take in train CSV.")


def write_readout_md(path: Path, top15: list[dict], lgb_gain: list[dict], n_train: int) -> None:
    lines = [
        "# EDGE-AI-3.5 — SHAP readout (LightGBM v2)",
        "",
        f"Train rows (feature_join_ok=1): **{n_train}** · Model: `data/ai/model_lgbm.txt`",
        "",
        "## Top 15 features (mean |SHAP|)",
        "",
        "| Rank | Feature | mean \\|SHAP\\| | % of top-15 mass |",
        "|-----:|---------|--------------:|-----------------:|",
    ]
    mass = sum(r["mean_abs_shap"] for r in top15) or 1.0
    for r in top15:
        pct = round(100.0 * r["mean_abs_shap"] / mass, 1)
        lines.append(
            f"| {r['rank']} | `{r['feature']}` | {r['mean_abs_shap']:.4f} | {pct}% |"
        )
    lines.extend(
        [
            "",
            "## Interpretation (actionable)",
            "",
        ]
    )
    for r in top15[:8]:
        lines.append(f"- **{r['feature']}** — {suggest_rule(r['feature'])}")
    lines.extend(
        [
            "",
            "## vs LightGBM gain (train)",
            "",
            "| Feature | SHAP rank | Gain rank |",
            "|---------|----------:|----------:|",
        ]
    )
    gain_rank = {g["feature"]: i + 1 for i, g in enumerate(lgb_gain)}
    for r in top15[:10]:
        gr = gain_rank.get(r["feature"], "-")
        lines.append(f"| `{r['feature']}` | {r['rank']} | {gr} |")
    lines.extend(
        [
            "",
            "## Manual EDGE candidates (not auto-promoted)",
            "",
            "1. **BB quality gate** — require `bb_width_vs_avg` and/or `bb_expand_ratio` above train median on L3=1 rows.",
            "2. **Struct depth** — optional raise `InpMinStructBreakAtrMult` toward SHAP-favored penetration (test vs P3-F 0.20).",
            "3. **Do not tune on holdout** — holdout AUC ~0.56; use SHAP for hypothesis only until 3.4 passes T71.",
            "",
            "Regenerate: `python scripts/ai_shap_readout.py`",
            "",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-3.5 SHAP readout")
    ap.add_argument("--data-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument("--top-n", type=int, default=15)
    ap.add_argument("--sample-max", type=int, default=0, help="0 = all train rows")
    args = ap.parse_args()
    d = args.data_dir
    model_path = d / "model_lgbm.txt"
    train_path = d / "aec_trades_train.csv"
    metrics_path = d / "train_metrics_lgbm.json"

    if not model_path.is_file() or not train_path.is_file():
        print("Run ai_train_lgbm.py first.")
        sys.exit(1)

    train_rows = [r for r in read_ml_csv(train_path) if int(r.get("feature_join_ok", 0) or 0) == 1]
    if not train_rows:
        print("No train rows with feature_join_ok=1.")
        sys.exit(1)

    if args.sample_max > 0 and len(train_rows) > args.sample_max:
        rng = np.random.default_rng(42)
        idx = rng.choice(len(train_rows), size=args.sample_max, replace=False)
        train_rows = [train_rows[i] for i in sorted(idx)]

    x = rows_to_matrix(train_rows)
    model = lgb.Booster(model_file=str(model_path))
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(x)
    if isinstance(shap_values, list):
        shap_values = shap_values[1] if len(shap_values) > 1 else shap_values[0]

    scores = mean_abs_shap(np.asarray(shap_values))
    top15 = rank_features(FEATURE_COLS_V2, scores, args.top_n)

    lgb_gain = []
    if metrics_path.is_file():
        import json

        lgb_gain = json.loads(metrics_path.read_text(encoding="utf-8")).get("importance_top20", [])

    out_csv = d / "shap_top15.csv"
    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["rank", "feature", "mean_abs_shap", "pct_of_total", "suggested_rule"],
        )
        w.writeheader()
        for r in top15:
            w.writerow({**r, "suggested_rule": suggest_rule(r["feature"])})

    summary = {
        "n_train": len(train_rows),
        "top_n": args.top_n,
        "top_features": top15,
        "lgb_gain_top10": lgb_gain[:10],
        "readout_md": "doc/edge-ai-3-5-shap-readout.md",
    }
    write_json(d / "shap_summary.json", summary)

    readout_md = REPO_ROOT / "doc" / "edge-ai-3-5-shap-readout.md"
    write_readout_md(readout_md, top15, lgb_gain, len(train_rows))

    print("EDGE-AI-3.5 SHAP readout\n")
    print(f"Train sample: {len(train_rows)} rows\n")
    print(f"{'rank':>4} {'feature':22} {'mean|SHAP|':>12} {'%':>6}")
    for r in top15:
        print(f"{r['rank']:>4} {r['feature']:22} {r['mean_abs_shap']:12.4f} {r['pct_of_total']:6.2f}")
    print(f"\nWrote: {out_csv}")
    print(f"       {d / 'shap_summary.json'}")
    print(f"       {readout_md}")


if __name__ == "__main__":
    main()
