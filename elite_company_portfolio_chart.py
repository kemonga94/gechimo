#!/usr/bin/env python3
"""
上場企業22銘柄の均等配分ポートフォリオ（円建て）1年チャート作成スクリプト

必要ライブラリのインストール（Windows / PowerShell例）:
    py -m pip install yfinance pandas matplotlib

出力:
    - elite_company_equal_weight_1y_chart.png
    - elite_company_equal_weight_1y_data.csv
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple

import matplotlib.pyplot as plt
import pandas as pd
import yfinance as yf


@dataclass
class Config:
    us_adr_tickers: List[str]
    jp_tickers: List[str]
    fx_ticker: str = "USDJPY=X"
    sp500_ticker: str = "^GSPC"
    topix_ticker: str = "1306.T"  # 代替候補: ^TPX
    period: str = "1y"
    output_chart: str = "elite_company_equal_weight_1y_chart.png"
    output_csv: str = "elite_company_equal_weight_1y_data.csv"


def fetch_adj_close(ticker: str, period: str = "1y") -> pd.Series:
    """auto_adjust=Trueで調整後終値系列を取得する。"""
    df = yf.download(
        ticker,
        period=period,
        interval="1d",
        auto_adjust=True,
        progress=False,
        threads=True,
    )
    if df.empty or "Close" not in df.columns:
        return pd.Series(dtype=float)
    s = df["Close"].copy()
    s.name = ticker
    return s


def normalize_to_100(series: pd.Series) -> pd.Series:
    """開始日100に指数化。"""
    first_valid = series.dropna()
    if first_valid.empty:
        return pd.Series(index=series.index, dtype=float)
    base = first_valid.iloc[0]
    return series / base * 100.0


def max_drawdown(index_series: pd.Series) -> float:
    """最大下落率（%）を負値で返す。"""
    roll_max = index_series.cummax()
    drawdown = index_series / roll_max - 1.0
    return drawdown.min() * 100.0


def build_portfolio(config: Config) -> Tuple[pd.DataFrame, List[str], List[str]]:
    all_tickers = config.us_adr_tickers + config.jp_tickers
    usd_tickers = set(config.us_adr_tickers)

    usd_jpy = fetch_adj_close(config.fx_ticker, config.period)
    if usd_jpy.empty:
        raise RuntimeError("USDJPY=X の取得に失敗しました。円換算ができません。")

    series_dict: Dict[str, pd.Series] = {}
    missing: List[str] = []

    for ticker in all_tickers:
        px = fetch_adj_close(ticker, config.period)
        if px.empty:
            missing.append(ticker)
            continue

        if ticker in usd_tickers:
            aligned = pd.concat([px, usd_jpy], axis=1)
            aligned.columns = ["px", "usd_jpy"]
            jpy_px = aligned["px"] * aligned["usd_jpy"]
            series_dict[ticker] = jpy_px.rename(ticker)
        else:
            series_dict[ticker] = px

    if not series_dict:
        raise RuntimeError("すべての銘柄取得に失敗しました。")

    prices = pd.concat(series_dict.values(), axis=1).sort_index()
    prices = prices.ffill()

    index_df = prices.apply(normalize_to_100)
    index_df = index_df.ffill()

    portfolio_index = index_df.mean(axis=1)
    index_df["Portfolio_EqualWeight"] = portfolio_index

    # 比較系列（取得できれば追加）
    bench_missing: List[str] = []

    spx = fetch_adj_close(config.sp500_ticker, config.period)
    if spx.empty:
        bench_missing.append(config.sp500_ticker)
    else:
        spx_jpy = (pd.concat([spx, usd_jpy], axis=1).ffill().iloc[:, 0] * pd.concat([spx, usd_jpy], axis=1).ffill().iloc[:, 1])
        index_df["S&P500_JPY"] = normalize_to_100(spx_jpy).reindex(index_df.index).ffill()

    topix = fetch_adj_close(config.topix_ticker, config.period)
    if topix.empty:
        bench_missing.append(config.topix_ticker)
    else:
        index_df["TOPIX"] = normalize_to_100(topix).reindex(index_df.index).ffill()

    # 出力時に見やすいよう必要列のみ
    output_cols = ["Portfolio_EqualWeight", "S&P500_JPY", "TOPIX"]
    for col in output_cols:
        if col not in index_df.columns:
            index_df[col] = pd.NA

    final_df = index_df[output_cols].copy()

    # 欠損銘柄警告を別リストに統合
    missing_all = missing + [f"(benchmark) {b}" for b in bench_missing]
    available = list(series_dict.keys())

    return final_df, missing_all, available


def plot_and_save(df: pd.DataFrame, config: Config) -> None:
    plt.figure(figsize=(12, 7))
    plt.plot(df.index, df["Portfolio_EqualWeight"], label="Equal-Weight Portfolio (JPY)", linewidth=2.2)

    if df["S&P500_JPY"].notna().any():
        plt.plot(df.index, df["S&P500_JPY"], label="S&P500 (JPY)", linewidth=1.6)
    if df["TOPIX"].notna().any():
        plt.plot(df.index, df["TOPIX"], label="TOPIX", linewidth=1.6)

    plt.title("Elite Company Equal-Weight Portfolio (Past 1 Year, JPY)")
    plt.xlabel("Date")
    plt.ylabel("Indexed Value (Start = 100)")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(config.output_chart, dpi=150)


def print_summary(df: pd.DataFrame) -> None:
    start_date = df.index.min().date()
    end_date = df.index.max().date()

    print("\n===== Summary =====")
    print(f"開始日: {start_date}")
    print(f"終了日: {end_date}")

    def calc_return(col: str) -> str:
        s = df[col].dropna()
        if s.empty:
            return "N/A"
        ret = (s.iloc[-1] / s.iloc[0] - 1.0) * 100
        return f"{ret:.2f}%"

    print(f"ポートフォリオの1年リターン: {calc_return('Portfolio_EqualWeight')}")
    print(f"S&P500円建ての1年リターン: {calc_return('S&P500_JPY')}")
    print(f"TOPIXの1年リターン: {calc_return('TOPIX')}")

    port = df["Portfolio_EqualWeight"].dropna()
    if not port.empty:
        mdd = max_drawdown(port)
        print(f"最高値からの最大下落率: {mdd:.2f}%")
    else:
        print("最高値からの最大下落率: N/A")


if __name__ == "__main__":
    cfg = Config(
        us_adr_tickers=[
            "JPM", "GS", "MS", "BAC", "C", "UBS", "DB",
            "GOOGL", "AMZN", "AAPL", "META", "MSFT",
        ],
        jp_tickers=[
            "8058.T", "8031.T", "8001.T", "8053.T", "8002.T",
            "8801.T", "8802.T", "9101.T", "9104.T", "9107.T",
        ],
    )

    result_df, missing_tickers, available_tickers = build_portfolio(cfg)

    if missing_tickers:
        print("[WARNING] 取得失敗した銘柄:")
        for m in missing_tickers:
            print(f"  - {m}")

    print(f"\n取得成功銘柄数: {len(available_tickers)} / 22")
    print("取得成功銘柄:", ", ".join(available_tickers))

    result_df.to_csv(cfg.output_csv, index_label="Date")
    plot_and_save(result_df, cfg)

    print_summary(result_df)

    print("\n出力完了:")
    print(f"  - {cfg.output_chart}")
    print(f"  - {cfg.output_csv}")
