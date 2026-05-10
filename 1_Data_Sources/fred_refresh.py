"""
fred_refresh.py
---------------
Refresh 13_DS_CSV_MacroIndicators.csv from the live FRED API.

Series fetched:
    MORTGAGE30US  - 30Y fixed mortgage rate (weekly -> resampled to monthly mean)
    CSUSHPINSA    - Case-Shiller National Home Price Index (monthly)
    CPIAUCSL      - CPI All Urban Consumers (monthly)
    FEDFUNDS      - Effective Federal Funds Rate (monthly)
    HOUST         - Housing Starts: Total (monthly, SAAR, thousands)

Requirements:
    pip install pandas fredapi
    export FRED_API_KEY=<your_key>          # https://fred.stlouisfed.org/docs/api/api_key.html

Run:
    python fred_refresh.py > 13_DS_CSV_MacroIndicators.csv
"""
import os
import sys
import pandas as pd
from fredapi import Fred

START = "2018-01-01"

SERIES = {
    "mortgage_30y_rate":         "MORTGAGE30US",
    "case_shiller_hpi":          "CSUSHPINSA",
    "cpi_all_urban":             "CPIAUCSL",
    "fed_funds_rate":            "FEDFUNDS",
    "housing_starts_thousands":  "HOUST",
}


def main() -> int:
    api_key = os.environ.get("FRED_API_KEY")
    if not api_key:
        print("ERROR: set FRED_API_KEY", file=sys.stderr)
        return 1

    fred = Fred(api_key=api_key)
    frames = {}
    for col, sid in SERIES.items():
        s = fred.get_series(sid, observation_start=START)
        s.index = pd.to_datetime(s.index)
        # Mortgage rate is weekly -> monthly mean. Everything else already monthly.
        if sid == "MORTGAGE30US":
            s = s.resample("MS").mean()
        else:
            s = s.resample("MS").first()
        frames[col] = s

    df = pd.concat(frames, axis=1).dropna(how="all")
    df.index.name = "period_date"
    df = df.round(2).reset_index()
    df["period_date"] = df["period_date"].dt.strftime("%Y-%m-%d")
    df.to_csv(sys.stdout, index=False, lineterminator="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
