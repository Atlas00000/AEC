"""Shared helpers for EDGE-AI scripts."""

from __future__ import annotations

import csv
import json
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

# P5-F reference (T48 / T51)
REF_T48 = {"pf": 1.17, "net": 271.30, "trades": 1244, "wr": 37.14}
REF_T51 = {"pf": 1.18, "net": 93.57, "trades": 419, "wr": 37.23}
REF_T70 = {"pf": 1.19, "net": 273.61, "trades": 1144, "wr": 37.5}
REF_T71 = {"pf": 1.22, "net": 105.61, "trades": 386, "wr": 37.5}
SL_POINTS = 200
# Fixed 0.01 lot EURUSD @ 200pt SL (~$2.02 avg loss in P10-E exports)
RISK_DOLLARS_PER_R = 2.0
TRAIN_YEAR_MAX = 2023

# Label thresholds (EDGE-AI label strategy)
L2_MFE_R_MIN = 1.0
L4_NET_R_MIN = 0.5
L3_NEVER_GREEN_MFE_MAX = 0.2

DEFAULT_TESTER_FILES = Path(
    r"c:\Users\emili\AppData\Roaming\MetaQuotes\Tester"
    r"\D0E8209F77C8CF37AD8BF550E51FF075\Agent-127.0.0.1-3000\MQL5\Files"
)

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_AI_DIR = REPO_ROOT / "data" / "ai"

FEATURE_COLS = ("entry_hour", "entry_weekday", "entry_month", "is_buy")

# v1 clock features + interactions (EDGE-AI-3.2+)
FEATURE_COLS_V1 = FEATURE_COLS

# Signal-bar features merged from AEC_*_signal_features.csv (no post-entry leakage)
SIGNAL_FEATURE_MERGE_COLS = (
    "signal_time",
    "spread_pts",
    "ai_prob_take",
    "loss_streak",
    "pass_bb",
    "pass_vol",
    "pass_struct",
    "pass_ema",
    "pass_disp",
    "pass_sess",
    "pass_htf",
    "pass_adx",
    "pass_atr_pct",
    "pass_prior_bar",
    "bb_expand_ratio",
    "bb_width_vs_avg",
    "squeeze_bars",
    "struct_break_atr",
    "displacement_atr",
    "prior_bar_range_atr",
    "atr_value",
    "atr_percentile",
    "adx_value",
)

# v2 model inputs: clock + signal-bar (exclude v1 gate score and string keys)
FEATURE_COLS_V2: tuple[str, ...] = FEATURE_COLS + tuple(
    c for c in SIGNAL_FEATURE_MERGE_COLS if c not in ("signal_time", "ai_prob_take")
) + ("hour_x_buy",)

INT_FEATURE_COLS = frozenset(
    {
        "spread_pts",
        "loss_streak",
        "pass_bb",
        "pass_vol",
        "pass_struct",
        "pass_ema",
        "pass_disp",
        "pass_sess",
        "pass_htf",
        "pass_adx",
        "pass_atr_pct",
        "pass_prior_bar",
        "squeeze_bars",
        "entry_hour",
        "entry_weekday",
        "entry_month",
        "is_buy",
        "label_L1_take",
        "label_L3_take",
        "label_never_green",
        "label_fought",
        "feature_join_ok",
    }
)


def parse_dt(s: str) -> datetime:
    return datetime.strptime(s.strip(), "%Y.%m.%d %H:%M:%S")


def pf_net_stats(nets: list[float]) -> dict:
    gp = sum(n for n in nets if n > 0)
    gl = sum(n for n in nets if n < 0)
    trades = len(nets)
    wins = sum(1 for n in nets if n > 0)
    net = gp + gl
    if gl >= 0:
        pf = 999.0 if gp > 0 else 0.0
    elif gp <= 0:
        pf = 0.0
    else:
        pf = gp / abs(gl)
    wr = 100.0 * wins / trades if trades else 0.0
    return {
        "trades": trades,
        "wins": wins,
        "net": round(net, 2),
        "pf": round(pf, 4),
        "wr": round(wr, 2),
    }


@dataclass
class DealRow:
    close_time: str
    entry_time: str
    entry_hour: int
    entry_weekday: int
    entry_month: int
    direction: str
    net_profit: float
    profit: float
    swap: float
    commission: float
    volume: float
    mfe_r: float
    mae_r: float
    deal_id: str
    position_id: str
    symbol: str
    source: str
    split: str


def read_deals_csv(path: Path, source: str, split_override: str | None = None) -> list[DealRow]:
    if not path.is_file():
        return []
    rows: list[DealRow] = []
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        for r in reader:
            entry_time = r["entry_time"]
            year = parse_dt(entry_time).year
            split = split_override or ("train" if year <= TRAIN_YEAR_MAX else "holdout")
            mfe = float(r["mfe_r"]) if "mfe_r" in r and r["mfe_r"].strip() else 0.0
            mae = float(r["mae_r"]) if "mae_r" in r and r["mae_r"].strip() else 0.0
            rows.append(
                DealRow(
                    close_time=r["close_time"],
                    entry_time=entry_time,
                    entry_hour=int(r["entry_hour"]),
                    entry_weekday=int(r["entry_weekday"]),
                    entry_month=int(r["entry_month"]),
                    direction=r["direction"].strip(),
                    net_profit=float(r["net_profit"]),
                    profit=float(r["profit"]),
                    swap=float(r["swap"]),
                    commission=float(r["commission"]),
                    volume=float(r["volume"]),
                    mfe_r=mfe,
                    mae_r=mae,
                    deal_id=r.get("deal_id", ""),
                    position_id=r.get("position_id", ""),
                    symbol=r.get("symbol", ""),
                    source=source,
                    split=split,
                )
            )
    return rows


def _parse_float(s: str) -> float:
    s = (s or "").strip()
    return float(s) if s else 0.0


def _parse_int(s: str) -> int:
    s = (s or "").strip()
    return int(float(s)) if s else 0


def read_signal_features_csv(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    rows: list[dict] = []
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        for r in reader:
            rows.append(dict(r))
    return rows


def signal_features_by_entry_time(
    feature_rows: list[dict],
    bar_minutes: int = 5,
    outcomes: frozenset[str] | None = None,
) -> dict[tuple[str, str], dict]:
    """Map (entry_time, direction) -> feature row; entry_time = signal_time + bar_minutes."""
    if outcomes is None:
        outcomes = frozenset({"executed"})
    index: dict[tuple[str, str], dict] = {}
    for r in feature_rows:
        if r.get("outcome", "").strip() not in outcomes:
            continue
        signal_time = r.get("signal_time", "").strip()
        direction = r.get("direction", "").strip()
        if not signal_time or not direction:
            continue
        entry_time = (parse_dt(signal_time) + timedelta(minutes=bar_minutes)).strftime(
            "%Y.%m.%d %H:%M:%S"
        )
        key = (entry_time, direction)
        if key not in index:
            index[key] = r
    return index


def feature_row_to_merge_dict(r: dict) -> dict:
    out: dict = {}
    for col in SIGNAL_FEATURE_MERGE_COLS:
        raw = r.get(col, "")
        if col in INT_FEATURE_COLS or col.startswith("pass_"):
            out[col] = _parse_int(raw)
        else:
            out[col] = _parse_float(raw) if col != "signal_time" else raw.strip()
    return out


def empty_feature_merge() -> dict:
    out: dict = {"feature_join_ok": 0}
    for col in SIGNAL_FEATURE_MERGE_COLS:
        if col == "signal_time":
            out[col] = ""
        elif col in INT_FEATURE_COLS or col.startswith("pass_"):
            out[col] = 0
        else:
            out[col] = 0.0
    return out


def merge_features_into_ml_row(ml: dict, feat: dict | None) -> dict:
    out = dict(ml)
    if feat is None:
        out.update(empty_feature_merge())
    else:
        merged = feature_row_to_merge_dict(feat)
        out.update(merged)
        out["feature_join_ok"] = 1
    out["hour_x_buy"] = int(out["entry_hour"]) * int(out["is_buy"])
    return out


def compute_labels(net_profit: float, mfe_r: float) -> dict:
    """L1–L4 + taxonomy helpers (see doc/aiimplmentation.md)."""
    never_green = 1 if net_profit < 0 and mfe_r < L3_NEVER_GREEN_MFE_MAX else 0
    fought = 1 if net_profit < 0 and mfe_r >= 0.5 else 0
    net_r = net_profit / RISK_DOLLARS_PER_R if RISK_DOLLARS_PER_R > 0 else 0.0
    return {
        "net_r": round(net_r, 4),
        "label_L1_take": 1 if net_profit > 0 else 0,
        "label_L2_take": 1 if mfe_r >= L2_MFE_R_MIN else 0,
        "label_L3_take": 0 if never_green else 1,
        "label_L4_take": 1 if net_r >= L4_NET_R_MIN else 0,
        "label_never_green": never_green,
        "label_fought": fought,
    }


def row_to_ml_dict(d: DealRow) -> dict:
    net = d.net_profit
    mfe = d.mfe_r
    labels = compute_labels(net, mfe)
    return {
        "close_time": d.close_time,
        "entry_time": d.entry_time,
        "entry_year": parse_dt(d.entry_time).year,
        "entry_hour": d.entry_hour,
        "entry_weekday": d.entry_weekday,
        "entry_month": d.entry_month,
        "direction": d.direction,
        "is_buy": 1 if d.direction == "BUY" else 0,
        "net_profit": net,
        "mfe_r": mfe,
        "mae_r": d.mae_r,
        **labels,
        "split": d.split,
        "source": d.source,
        "position_id": d.position_id,
    }


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def write_json(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")


def read_ml_csv(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def feature_value(row: dict, col: str) -> float:
    raw = row.get(col, "")
    if col in INT_FEATURE_COLS or col.startswith("pass_"):
        return float(_parse_int(str(raw)))
    return _parse_float(str(raw))
