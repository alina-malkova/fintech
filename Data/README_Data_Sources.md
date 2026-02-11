# Data Sources for Fintech Research

## Downloaded Data

### 1. Fuster et al. Fintech Lender Classification (DOWNLOADED)
**Location**: `Fintech_Classification/`

| File | Description |
|------|-------------|
| `fintech_classification.xlsx` | List of fintech-classified lenders with HMDA RSSD IDs |
| `lender_national_shares.xlsx` | Annual ranked lists of all U.S. mortgage lenders, fintech classification, origination volume, market share (2010-2017) |
| `fintech_county_lending.dta` | County-level fintech lending data (Stata format, 2010-2017) |
| `fintech_county_shares.csv` | County-level fintech lending shares (CSV format, 2010-2017) |

**Variables in county data**:
- `fips` - County FIPS code
- `year` - Year (2010-2017)
- `loan_amount` - Fintech lending volume (share)
- `total_lending` - Total lending volume

**Citation**: Fuster, Andreas, Matthew Plosser, Philipp Schnabl, and James Vickery. "The Role of Technology in Mortgage Lending." *Review of Financial Studies* 32(5), 2019.

**Source**: https://pages.stern.nyu.edu/~pschnabl/data/data_fintech.htm

---

### 2. HMDA Data Science Kit (DOWNLOADED)
**Location**: `HMDA/HMDA_Data_Science_Kit/`

**Available LAR (Loan Application Register) Files**: 2017-2022
**Available Panel Files**: 2004-2022
**Available Transmittal Sheet Files**: 2004-2022

#### To Download HMDA LAR Data:

```bash
cd "HMDA/HMDA_Data_Science_Kit"

# List available files
bash download_scripts/download_hmda.sh -a

# Download specific year LAR file (WARNING: ~500MB each)
bash download_scripts/download_hmda.sh -s lar_2018
bash download_scripts/download_hmda.sh -s lar_2019
bash download_scripts/download_hmda.sh -s lar_2020
bash download_scripts/download_hmda.sh -s lar_2021
bash download_scripts/download_hmda.sh -s lar_2022

# Download all LAR files at once
bash download_scripts/download_hmda.sh -l

# Download Panel files (lender information)
bash download_scripts/download_hmda.sh -p
```

---

### 3. ZCTA-County Crosswalk (DOWNLOADED)
**Location**: `Crosswalks/`
**Source**: U.S. Census Bureau 2020 Relationship Files

| File | Description |
|------|-------------|
| `zcta_county_2020.txt` | Raw Census ZCTA-County relationship file |
| `zcta_county_primary.csv` | **USE THIS** - One county per ZCTA (largest area overlap) |
| `zcta_county_full.csv` | All ZCTA-County relationships with area |
| `zcta_county_crosswalk.csv` | All relationships (no area) |

**Primary crosswalk structure** (`zcta_county_primary.csv`):
```
zcta,county_fips,county_name
10001,36061,New York County
10002,36061,New York County
...
```

**Coverage**: 33,791 unique ZCTAs → 3,232 counties

**Note**: Includes Puerto Rico (72xxx). US states only: 33,660 ZCTAs.

---

## Data Matching Strategy

### Option A: Use Pre-Computed County Data (2010-2017)
The Fuster et al. `fintech_county_shares.csv` already contains county-year level fintech penetration.

**To merge with CAPS**:
1. Convert CAPS zip codes to county FIPS codes
2. Merge on county FIPS + year

### Option B: Extend to Recent Years (2018-2022)
1. Download HMDA LAR files for 2018-2022
2. Apply Fuster et al. lender classification to identify fintech lenders
3. Aggregate to county-year level
4. Append to existing 2010-2017 data

---

## Key Links

- **Fuster et al. Data**: https://pages.stern.nyu.edu/~pschnabl/data/data_fintech.htm
- **HMDA Data Browser**: https://ffiec.cfpb.gov/data-browser/
- **HMDA Historic Data (2007-2017)**: https://www.consumerfinance.gov/data-research/hmda/historic-data/
- **CFPB HMDA GitHub**: https://github.com/cfpb/HMDA_Data_Science_Kit
