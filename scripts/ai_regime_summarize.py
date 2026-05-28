#!/usr/bin/env python3
"""
EDGE-AI-8.4 — Era / calendar PF from deal export CSVs.

  python scripts/ai_regime_summarize.py
  python scripts/ai_regime_summarize.py --deals AEC_P10-E_deals.csv

Writes data/ai/regime_by_year.csv, regime_eras.csv, regime_summary.json
and doc/edge-ai-8-4-regime-readout.md
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ai_common import (
    DEFAULT_AI_DIR,
    DEFAULT_TESTER_FILES,
    L3_NEVER_GREEN_MFE_MAX,
    REF_T48,
    REF_T70,
    REF_T51,
    REPO_ROOT,
    parse_dt,
    pf_net_stats,
    read_deals_csv,
    write_csv,
    write_json,
)

# T73 reference (P10-B, 2010-2026, deposit 1000 — caution)
REF_T73 = {"pf": 0.98, "net": -79.93, "trades": 3163, "wr": 33.10, "deposit": 1000}

ERAS = (
    ("pre2020", "2010-2019", lambda y: y < 2020),
    ("era2020plus", "2020-2026", lambda y: y >= 2020),
    ("train_le2023", "train <=2023", lambda y: y <= 2023),
    ("holdout_ge2024", "holdout 2024+", lambda y: y >= 2024),
)


def load_deal_rows(path: Path, source: str) -> list[dict]:
    deals = read_deals_csv(path, source, None)
    rows = []
    for d in deals:
        year = parse_dt(d.entry_time).year
        never_green = 1 if d.net_profit < 0 and d.mfe_r < L3_NEVER_GREEN_MFE_MAX else 0
        rows.append(
            {
                "entry_time": d.entry_time,
                "entry_year": year,
                "entry_month": d.entry_month,
                "direction": d.direction,
                "net_profit": d.net_profit,
                "mfe_r": d.mfe_r,
                "mae_r": d.mae_r,
                "never_green": never_green,
            }
        )
    return rows


def stats_from_nets(nets: list[float], never_green: list[int]) -> dict:
    s = pf_net_stats(nets)
    n = len(nets)
    if n == 0:
        return {**s, "never_green_pct": 0.0}
    ng = sum(never_green)
    s["never_green_pct"] = round(100.0 * ng / max(1, sum(1 for x in nets if x < 0)), 2)
    return s


def bucket_rows(rows: list[dict], key_fn) -> dict[str, list[dict]]:
    buckets: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        buckets[key_fn(r)].append(r)
    return buckets


def summarize_bucket(name: str, group: list[dict]) -> dict:
    nets = [r["net_profit"] for r in group]
    ng = [r["never_green"] for r in group]
    s = stats_from_nets(nets, ng)
    return {"bucket": name, "trades": s["trades"], "net": s["net"], "pf": s["pf"], "wr": s["wr"], "never_green_pct": s["never_green_pct"]}


def rolling_pf(rows: list[dict], window: int = 100) -> list[dict]:
    ordered = sorted(rows, key=lambda r: r["entry_time"])
    out = []
    for i in range(window - 1, len(ordered)):
        chunk = ordered[i - window + 1 : i + 1]
        nets = [r["net_profit"] for r in chunk]
        ng = [r["never_green"] for r in chunk]
        end = ordered[i]
        s = stats_from_nets(nets, ng)
        out.append(
            {
                "end_entry_time": end["entry_time"],
                "end_year": end["entry_year"],
                "window": window,
                "trades": s["trades"],
                "net": s["net"],
                "pf": s["pf"],
                "wr": s["wr"],
            }
        )
    return out


def write_readout_md(
    path: Path,
    source_file: str,
    n_rows: int,
    year_rows: list[dict],
    era_rows: list[dict],
    full: dict,
    roll: list[dict],
) -> None:
    lines = [
        "# EDGE-AI-8.4 — Regime / era readout",
        "",
        f"Source: `{source_file}` · **{n_rows}** closed trades",
        "",
        "## Full sample",
        "",
        f"| Trades | Net | PF | WR% | Never-green % (of losers) |",
        f"|-------:|----:|---:|----:|--------------------------:|",
        f"| {full['trades']} | {full['net']} | {full['pf']} | {full['wr']} | {full.get('never_green_pct', 0)} |",
        "",
        "## By entry year",
        "",
        "| Year | Trades | Net | PF | WR% | NG% losers |",
        "|-----:|-------:|----:|---:|----:|-----------:|",
    ]
    for r in year_rows:
        flag = " *" if r["pf"] >= 1.15 and r["net"] > 20 else ""
        lines.append(
            f"| {r['bucket']} | {r['trades']} | {r['net']} | {r['pf']} | {r['wr']} | {r['never_green_pct']} |{flag}"
        )
    lines.extend(
        [
            "",
            "## Era buckets",
            "",
            "| Era | Trades | Net | PF | WR% | vs T70/T73 |",
            "|-----|-------:|----:|---:|----:|------------|",
        ]
    )
    for r in era_rows:
        note = ""
        if r["bucket"] == "era2020plus" and r["trades"]:
            note = " ~T70 window" if r["pf"] >= 1.1 else " below T70"
        if r["bucket"] == "pre2020":
            note = " T73 drag if negative"
        lines.append(
            f"| {r['bucket']} | {r['trades']} | {r['net']} | {r['pf']} | {r['wr']} |{note}"
        )
    if roll:
        bad = [x for x in roll if x["pf"] < 1.0 and x["net"] < 0]
        lines.extend(
            [
                "",
                "## Rolling 100-trade health",
                "",
                f"Windows: {len(roll)} · sub-PF windows: {len(bad)} "
                f"({round(100*len(bad)/len(roll),1)}%)",
                "",
                "Use to motivate **AI-8.2** (stand down when rolling PF &lt; 1).",
            ]
        )
    lines.extend(
        [
            "",
            "## References",
            "",
            f"| Test | Net | PF | Trades |",
            f"|------|----:|---:|-------:|",
            f"| T48 / P5-F 2020+ | {REF_T48['net']} | {REF_T48['pf']} | {REF_T48['trades']} |",
            f"| T70 / P10-B 2020+ | {REF_T70['net']} | {REF_T70['pf']} | {REF_T70['trades']} |",
            f"| T73 / P10-B 2010+ | {REF_T73['net']} | {REF_T73['pf']} | {REF_T73['trades']} |",
            "",
            "## Tester follow-ups",
            "",
            "| ID | Preset | Dates | Purpose |",
            "|----|--------|-------|---------|",
            "| **T74** | `AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set` | 2010–2026 · dep 200 | P5-F **no AI** — stack-only long history |",
            "| **T75** | `AEC.P11-A_regime-gate_EDGE-AI-8-T75.set` | 2010–2026 + 2020–2026 | P10-B + **ATR pct 20–85** + **ADX≥18** |",
            "",
            "Regenerate: `python scripts/ai_regime_summarize.py`",
            "",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser(description="EDGE-AI-8.4 regime summarize")
    ap.add_argument("--files-dir", type=Path, default=DEFAULT_TESTER_FILES)
    ap.add_argument("--deals", type=str, default="AEC_P10-E_deals.csv")
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_AI_DIR)
    ap.add_argument("--rolling-window", type=int, default=100)
    args = ap.parse_args()

    path = args.files_dir / args.deals
    if not path.is_file():
        print(f"Missing {path}")
        print("Run P10-E export or point --deals to an existing deals CSV.")
        sys.exit(1)

    rows = load_deal_rows(path, "regime_input")
    if not rows:
        print("No deal rows.")
        sys.exit(1)

    full = summarize_bucket("ALL", rows)
    by_year = bucket_rows(rows, lambda r: str(r["entry_year"]))
    year_summaries = [summarize_bucket(k, v) for k, v in sorted(by_year.items())]

    era_summaries = []
    for era_id, label, pred in ERAS:
        group = [r for r in rows if pred(r["entry_year"])]
        s = summarize_bucket(era_id, group)
        s["label"] = label
        era_summaries.append(s)

    roll = rolling_pf(rows, args.rolling_window)

    out = args.out_dir
    write_csv(out / "regime_by_year.csv", year_summaries, ["bucket", "trades", "net", "pf", "wr", "never_green_pct"])
    write_csv(
        out / "regime_eras.csv",
        era_summaries,
        ["bucket", "label", "trades", "net", "pf", "wr", "never_green_pct"],
    )
    if roll:
        write_csv(
            out / "regime_rolling_pf.csv",
            roll,
            ["end_entry_time", "end_year", "window", "trades", "net", "pf", "wr"],
        )

    summary = {
        "source": str(path),
        "n_trades": len(rows),
        "year_min": min(r["entry_year"] for r in rows),
        "year_max": max(r["entry_year"] for r in rows),
        "full": full,
        "by_year": year_summaries,
        "eras": era_summaries,
        "rolling_window": args.rolling_window,
        "rolling_sub_pf_count": sum(1 for x in roll if x["pf"] < 1.0 and x["net"] < 0),
        "ref_T48": REF_T48,
        "ref_T70": REF_T70,
        "ref_T73": REF_T73,
    }
    write_json(out / "regime_summary.json", summary)

    readout = REPO_ROOT / "doc" / "edge-ai-8-4-regime-readout.md"
    write_readout_md(readout, path.name, len(rows), year_summaries, era_summaries, full, roll)

    print("EDGE-AI-8.4 regime summarize\n")
    print(f"Source: {path.name}  trades={len(rows)}  years={summary['year_min']}-{summary['year_max']}\n")
    print(f"{'year':>6} {'trades':>7} {'net':>9} {'PF':>6} {'WR%':>6}")
    for r in year_summaries:
        print(f"{r['bucket']:>6} {r['trades']:>7} {r['net']:>9.2f} {r['pf']:>6.3f} {r['wr']:>6.1f}")
    print(f"\n{'era':>14} {'trades':>7} {'net':>9} {'PF':>6}")
    for r in era_summaries:
        print(f"{r['bucket']:>14} {r['trades']:>7} {r['net']:>9.2f} {r['pf']:>6.3f}")
    if summary["year_min"] >= 2020:
        print("\nNote: deals file is 2020+ only — run T74/T75 for 2010-2019 era split.")
    print(f"\nWrote: {out / 'regime_by_year.csv'}")
    print(f"       {readout}")


if __name__ == "__main__":
    main()
