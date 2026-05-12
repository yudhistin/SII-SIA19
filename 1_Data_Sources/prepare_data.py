"""
prepare_data.py
---------------
One-shot preprocessor: converts every downloaded dataset into the form
that the Data_Sources loader scripts expect.

Inputs (defaults expect them in the parent SII\\ working folder):
    rollingsales_{manhattan,brooklyn,queens,bronx,statenisland}.xlsx
    listings.csv.gz                       (Inside Airbnb Amsterdam)
    archive (4).zip                       (Realtor.com Kaggle download)
    MORTGAGE30US.csv                      (FRED, weekly)
    CSUSHPINSA.csv                        (FRED, monthly)

Outputs (written next to this script, ready for docker cp / mongoimport / \\COPY):
    rollingsales_{borough}.csv            (5 borough CSVs)
    listings_amsterdam.csv                (decompressed)
    realtor_listings.jsonl                (200k random sample, seed 19)
    13_DS_CSV_MacroIndicators_full.csv    (merged FRED, monthly)

Usage:
    cd 1_Data_Sources/
    pip install pandas openpyxl --break-system-packages
    python prepare_data.py

Override the input directory:
    python prepare_data.py --src "E:\\Matei\\School\\Master\\Anul2\\SII"
"""
from __future__ import annotations

import argparse
import gzip
import shutil
import sys
import zipfile
from pathlib import Path

BOROUGHS = ["manhattan", "brooklyn", "queens", "bronx", "statenisland"]


def convert_nyc_xlsx_to_csv(src: Path, dst: Path) -> None:
    """NYC publishes XLSX with 4 metadata rows + 1 header row + data."""
    import openpyxl
    for borough in BOROUGHS:
        xlsx = src / f"rollingsales_{borough}.xlsx"
        if not xlsx.exists():
            print(f"  - skip {borough}: {xlsx} not found", file=sys.stderr)
            continue
        out = dst / f"rollingsales_{borough}.csv"
        wb = openpyxl.load_workbook(xlsx, read_only=True, data_only=True)
        ws = wb.active
        with out.open("w", encoding="utf-8", newline="") as fh:
            import csv
            w = csv.writer(fh, quoting=csv.QUOTE_MINIMAL)
            for row in ws.iter_rows(values_only=True):
                # Strip trailing None cells
                cells = list(row)
                while cells and cells[-1] is None:
                    cells.pop()
                w.writerow([("" if c is None else c) for c in cells])
        wb.close()
        print(f"  ok {borough:14s} -> {out.name}")


def decompress_airbnb(src: Path, dst: Path) -> None:
    gz = src / "listings.csv.gz"
    if not gz.exists():
        print(f"  - skip airbnb: {gz} not found", file=sys.stderr)
        return
    out = dst / "listings_amsterdam.csv"
    with gzip.open(gz, "rb") as fin, out.open("wb") as fout:
        shutil.copyfileobj(fin, fout)
    print(f"  ok airbnb       -> {out.name}")


def sample_realtor(src: Path, dst: Path, n: int = 200_000, seed: int = 19) -> None:
    import pandas as pd

    zpath = src / "archive (4).zip"
    if not zpath.exists():
        print(f"  - skip realtor: {zpath} not found", file=sys.stderr)
        return
    with zipfile.ZipFile(zpath) as zf:
        with zf.open("realtor-data.zip.csv") as fh:
            df = pd.read_csv(fh, low_memory=False)
    print(f"  realtor full rows: {len(df):,}")
    sample = df.sample(n=min(n, len(df)), random_state=seed)
    out = dst / "realtor_listings.jsonl"
    sample.to_json(out, orient="records", lines=True)
    print(f"  ok realtor      -> {out.name} ({len(sample):,} docs)")


def merge_fred(src: Path, dst: Path) -> None:
    """Merge per-series FRED CSVs into one monthly indicators CSV."""
    import pandas as pd

    series = {
        "mortgage_30y_rate": ("MORTGAGE30US.csv", "MORTGAGE30US"),
        "case_shiller_hpi":  ("CSUSHPINSA.csv",  "CSUSHPINSA"),
    }
    frames = []
    for col, (fname, sid) in series.items():
        f = src / fname
        if not f.exists():
            print(f"  - skip FRED {sid}: {f} not found", file=sys.stderr)
            continue
        s = pd.read_csv(f, parse_dates=["observation_date"]).rename(
            columns={"observation_date": "period_date", sid: col}
        )
        # MORTGAGE30US is weekly -> resample to monthly mean
        s = s.set_index("period_date")[col]
        if sid == "MORTGAGE30US":
            s = s.resample("MS").mean()
        else:
            s = s.resample("MS").first()
        frames.append(s.rename(col))

    if not frames:
        print("  - no FRED inputs found, skipping merge")
        return

    df = pd.concat(frames, axis=1).dropna(how="all").round(2)
    df.index.name = "period_date"
    out = dst / "13_DS_CSV_MacroIndicators_full.csv"
    df.reset_index().to_csv(out, index=False, date_format="%Y-%m-%d")
    print(f"  ok FRED merged  -> {out.name} ({len(df)} months, "
          f"{df.index.min().date()} -> {df.index.max().date()})")


def main() -> int:
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", default=str(here.parent.parent),
                        help="Folder containing the downloaded datasets")
    parser.add_argument("--dst", default=str(here),
                        help="Folder to write prepared files (default: this script's dir)")
    args = parser.parse_args()

    src = Path(args.src).resolve()
    dst = Path(args.dst).resolve()
    dst.mkdir(parents=True, exist_ok=True)

    print(f"src = {src}")
    print(f"dst = {dst}")
    print("[1/4] NYC sales XLSX -> CSV")
    convert_nyc_xlsx_to_csv(src, dst)
    print("[2/4] Inside Airbnb listings.csv.gz -> CSV")
    decompress_airbnb(src, dst)
    print("[3/4] Realtor.com -> 200k JSONL")
    sample_realtor(src, dst)
    print("[4/4] FRED CSVs -> merged macro indicators")
    merge_fred(src, dst)
    print("\nDone. Files ready in:")
    print(f"  {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
