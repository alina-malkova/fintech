"""
HMDA-Fintech Processing Script
Purpose: Process raw HMDA LAR data, flag fintech lenders, aggregate to ZIP level
Author: Research Assistant (Claude)
Date: February 2026

Usage:
    python process_hmda_fintech.py

Requirements:
    - pandas
    - openpyxl (for reading Excel fintech classification)
    - tqdm (optional, for progress bars)

Input files:
    - Data/HMDA/LAR/hmda_YYYY_nationwide.csv (raw HMDA files)
    - Data/Fintech_Classification/fintech_xlsx/fintech_classification.xlsx
    - Data/Crosswalks/tract_zip_crosswalk.csv (HUD USPS crosswalk)

Output files:
    - Data/HMDA/hmda_fintech_zip_year.csv
    - Data/HMDA/hmda_fintech_zip_year.dta (if stata_write available)
"""

import os
import pandas as pd
import numpy as np
from pathlib import Path
import zipfile
import io

# Set paths
ROOT = Path("/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Financial_Inclusion/Fintech Research")
HMDA_DIR = ROOT / "Data" / "HMDA" / "LAR"
OUTPUT_DIR = ROOT / "Data" / "HMDA"
FINTECH_CLASS = ROOT / "Data" / "Fintech_Classification" / "fintech_xlsx" / "fintech_classification.xlsx"
TRACT_ZIP_XWALK = ROOT / "Data" / "Crosswalks" / "tract_zip_crosswalk.csv"


def load_fintech_classification():
    """Load fintech lender respondent IDs from Panel file mapping."""
    print("Loading fintech lender classification...")

    # Try to load from our mapped respondent ID file first
    respondent_id_file = ROOT / "Data" / "HMDA" / "fintech_respondent_ids.txt"
    if respondent_id_file.exists():
        with open(respondent_id_file, 'r') as f:
            fintech_ids = set(line.strip() for line in f if line.strip())
        print(f"  Loaded {len(fintech_ids)} fintech respondent IDs from mapping file")
        return fintech_ids

    # Fallback: use known fintech respondent IDs from Panel file analysis
    print("  Using hardcoded fintech respondent IDs (from Panel file analysis)")
    known_fintech = {
        '7197000003',   # QUICKEN LOANS
        '36-4327855',   # GUARANTEED RATE
        '26-4599244',   # LOANDEPOT.COM
        '26-0595342',   # MOVEMENT MORTGAGE
        '1722400006',   # EVERETT FINANCIAL
        '75-2695327',   # EVERETT FINANCIAL (alt)
        '87-0691650',   # AVEX FUNDING (Better Mortgage)
        '26-0021318',   # AMERISAVE MORTGAGE
        '1614900001',   # ARK-LA-TEX FINANCIAL
        '75-2838184',   # ARK-LA-TEX FINANCIAL (alt)
        '1635900004',   # ENVOY MORTGAGE
        '7110800000',   # EVERGREEN MONEYSOURCE
        '91-1374387',   # EVERGREEN MONEYSOURCE (alt)
        '20-3702275',   # FBC MORTGAGE
        '42-1739728',   # HOMEWARD RESIDENTIAL
        '7354100002',   # MORTGAGE INVESTORS GROUP
        '83-0310268',   # MORTGAGE INVESTORS GROUP (alt)
        '7162800002',   # 21ST MORTGAGE
        '52-2091594',   # AMERICAN INTERNET MORTGAGE
        '27-2389039',   # AMERICAN NEIGHBORHOOD MORTGAGE
        '26-0508430',   # RPM MORTGAGE
        '95-3990375',   # SKYLINE FINANCIAL
    }
    print(f"  Using {len(known_fintech)} known fintech lenders")
    return known_fintech


def _process_chunks(chunks, fintech_ids, year, col_mapping):
    """Process HMDA data chunks and return aggregated tract-level data."""
    results = []

    for i, chunk in enumerate(chunks):
        # Rename columns if needed
        chunk.rename(columns=col_mapping, inplace=True)

        # Filter to originated loans
        if 'action_taken' in chunk.columns:
            chunk = chunk[chunk['action_taken'] == 1]

        # Filter to home purchase and refinance
        if 'loan_purpose' in chunk.columns:
            chunk = chunk[chunk['loan_purpose'].isin([1, 3])]

        # Filter to 1-4 family properties
        if 'property_type' in chunk.columns:
            chunk = chunk[chunk['property_type'] == 1]

        # Flag fintech loans
        if 'respondent_id' in chunk.columns:
            chunk['fintech_loan'] = chunk['respondent_id'].astype(str).str.strip().isin(fintech_ids).astype(int)
        else:
            chunk['fintech_loan'] = 0

        # Aggregate to tract level
        if 'census_tract_number' in chunk.columns:
            tract_agg = chunk.groupby(
                ['state_code', 'county_code', 'census_tract_number']
            ).agg({
                'loan_amount_000s': ['count', 'sum'],
                'fintech_loan': 'sum'
            }).reset_index()

            tract_agg.columns = ['state', 'county', 'tract', 'total_loans', 'total_amount', 'fintech_loans']
            results.append(tract_agg)

        if (i + 1) % 10 == 0:
            print(f"    Processed {(i + 1) * 500000:,} records...")

    if results:
        df_year = pd.concat(results, ignore_index=True)

        # Aggregate again (in case same tract appeared in multiple chunks)
        df_year = df_year.groupby(['state', 'county', 'tract']).agg({
            'total_loans': 'sum',
            'total_amount': 'sum',
            'fintech_loans': 'sum'
        }).reset_index()

        df_year['year'] = year
        df_year['fintech_share'] = df_year['fintech_loans'] / df_year['total_loans']

        print(f"    Year {year}: {len(df_year):,} tracts, "
              f"{df_year['fintech_loans'].sum():,} fintech loans "
              f"({df_year['fintech_loans'].sum() / df_year['total_loans'].sum() * 100:.2f}%)")

        return df_year

    return None


def process_hmda_year(year, fintech_ids, chunksize=500000):
    """Process one year of HMDA LAR data."""

    # Look for file with various naming conventions (including ZIP files)
    possible_files = [
        HMDA_DIR / f"hmda_{year}.zip",
        HMDA_DIR / f"hmda_{year}_nationwide.csv",
        HMDA_DIR / f"hmda_{year}_nationwide_all-records.csv",
        HMDA_DIR / f"hmda_{year}.csv",
        HMDA_DIR / f"lar_{year}.csv",
    ]

    hmda_file = None
    is_zip = False
    for f in possible_files:
        if f.exists():
            hmda_file = f
            is_zip = f.suffix == '.zip'
            break

    if hmda_file is None:
        print(f"  WARNING: No HMDA file found for {year}")
        return None

    print(f"  Processing {hmda_file.name} (zip={is_zip})...")

    # Columns to keep (adjust based on actual column names)
    use_cols = [
        'as_of_year', 'respondent_id', 'agency_code',
        'loan_type', 'property_type', 'loan_purpose',
        'loan_amount_000s', 'action_taken',
        'state_code', 'county_code', 'census_tract_number'
    ]

    # Alternative column names
    col_mapping = {
        'action_type': 'action_taken',
        'loan_amount': 'loan_amount_000s',
        'census_tract': 'census_tract_number',
    }

    results = []

    try:
        # Handle ZIP files by opening and extracting CSV
        if is_zip:
            with zipfile.ZipFile(hmda_file, 'r') as zf:
                # Find the CSV file inside the zip
                csv_names = [n for n in zf.namelist() if n.endswith('.csv')]
                if not csv_names:
                    print(f"  ERROR: No CSV found in {hmda_file.name}")
                    return None
                csv_name = csv_names[0]
                print(f"    Reading {csv_name} from zip...")

                # Open CSV from zip for reading
                with zf.open(csv_name) as csv_file:
                    # Read in chunks
                    chunks = pd.read_csv(
                        csv_file,
                        chunksize=chunksize,
                        low_memory=False,
                        dtype={'census_tract_number': str, 'state_code': str, 'county_code': str}
                    )
                    # Process chunks inside the context manager
                    return _process_chunks(chunks, fintech_ids, year, col_mapping)
        else:
            # Read in chunks to handle large files
            chunks = pd.read_csv(
                hmda_file,
                chunksize=chunksize,
                low_memory=False,
                dtype={'census_tract_number': str, 'state_code': str, 'county_code': str}
            )
            return _process_chunks(chunks, fintech_ids, year, col_mapping)

    except Exception as e:
        print(f"  ERROR processing {year}: {e}")
        return None

    return None


def aggregate_to_zip(df_tract, xwalk_file):
    """Aggregate tract-level data to ZIP level using crosswalk."""

    print("Aggregating to ZIP level...")

    try:
        xwalk = pd.read_csv(xwalk_file, dtype={'tract': str, 'zip': str})

        # Create tract FIPS for matching
        df_tract['tract_fips'] = (
            df_tract['state'].astype(str).str.zfill(2) +
            df_tract['county'].astype(str).str.zfill(3) +
            df_tract['tract'].astype(str).str.zfill(6)
        )

        # Merge with crosswalk
        df_merged = df_tract.merge(xwalk, on='tract_fips', how='left')

        # Weight by residential ratio (if available)
        if 'res_ratio' in df_merged.columns:
            df_merged['total_loans_w'] = df_merged['total_loans'] * df_merged['res_ratio']
            df_merged['fintech_loans_w'] = df_merged['fintech_loans'] * df_merged['res_ratio']
            df_merged['total_amount_w'] = df_merged['total_amount'] * df_merged['res_ratio']
        else:
            df_merged['total_loans_w'] = df_merged['total_loans']
            df_merged['fintech_loans_w'] = df_merged['fintech_loans']
            df_merged['total_amount_w'] = df_merged['total_amount']

        # Aggregate to ZIP
        df_zip = df_merged.groupby(['zip', 'year']).agg({
            'total_loans_w': 'sum',
            'fintech_loans_w': 'sum',
            'total_amount_w': 'sum'
        }).reset_index()

        df_zip.columns = ['zip', 'year', 'total_loans', 'fintech_loans', 'total_amount']
        df_zip['fintech_share_zip'] = df_zip['fintech_loans'] / df_zip['total_loans']

        print(f"  Created {len(df_zip):,} ZIP-year observations")

        return df_zip

    except Exception as e:
        print(f"  ERROR aggregating to ZIP: {e}")
        print("  Returning tract-level data instead")
        return df_tract


def main():
    """Main processing pipeline."""

    print("=" * 60)
    print("HMDA-FINTECH PROCESSING PIPELINE")
    print("=" * 60)

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Load fintech classification
    fintech_ids = load_fintech_classification()

    # Process each year
    all_years = []
    for year in range(2010, 2015):
        print(f"\nProcessing year {year}...")
        df_year = process_hmda_year(year, fintech_ids)
        if df_year is not None:
            all_years.append(df_year)

    if not all_years:
        print("\nNo HMDA data processed. Check that files exist in:")
        print(f"  {HMDA_DIR}")
        print("\nDownload HMDA LAR data from:")
        print("  https://ffiec.cfpb.gov/data-browser/")
        return

    # Combine all years
    df_all = pd.concat(all_years, ignore_index=True)
    print(f"\nCombined data: {len(df_all):,} tract-year observations")

    # Save tract-level data
    tract_output = OUTPUT_DIR / "hmda_fintech_tract_year.csv"
    df_all.to_csv(tract_output, index=False)
    print(f"Saved tract-level data to: {tract_output}")

    # Aggregate to ZIP level if crosswalk available
    if TRACT_ZIP_XWALK.exists():
        df_zip = aggregate_to_zip(df_all, TRACT_ZIP_XWALK)

        zip_output = OUTPUT_DIR / "hmda_fintech_zip_year.csv"
        df_zip.to_csv(zip_output, index=False)
        print(f"Saved ZIP-level data to: {zip_output}")

        # Try to save as Stata file
        try:
            import pyreadstat
            dta_output = OUTPUT_DIR / "hmda_fintech_zip_year.dta"
            pyreadstat.write_dta(df_zip, dta_output)
            print(f"Saved Stata file to: {dta_output}")
        except ImportError:
            print("Note: Install pyreadstat to save as .dta file")
    else:
        print(f"\nWARNING: Tract-ZIP crosswalk not found at:")
        print(f"  {TRACT_ZIP_XWALK}")
        print("Download from: https://www.huduser.gov/portal/datasets/usps_crosswalk.html")

    # Summary statistics
    print("\n" + "=" * 60)
    print("SUMMARY STATISTICS")
    print("=" * 60)

    for year in df_all['year'].unique():
        df_yr = df_all[df_all['year'] == year]
        ft_share = df_yr['fintech_loans'].sum() / df_yr['total_loans'].sum() * 100
        print(f"{year}: {df_yr['total_loans'].sum():>12,} loans, "
              f"{df_yr['fintech_loans'].sum():>8,} fintech ({ft_share:.2f}%)")

    print("\n" + "=" * 60)
    print("PROCESSING COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
