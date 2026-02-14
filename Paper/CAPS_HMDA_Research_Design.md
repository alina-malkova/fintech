# CAPS-HMDA Linkage Research Design

## Research Question
**Do individuals with high fintech creditworthiness scores actually obtain fintech mortgage credit, especially when traditional bank branches close?**

## Motivation
The current paper validates that fintech-style creditworthiness characteristics (payment behavior, income stability, financial resilience) predict mortgage default well (AUC = 0.926). However, we cannot observe whether individuals with these characteristics actually *obtain* fintech credit when traditional sources become unavailable.

Linking CAPS to HMDA mortgage data would allow direct observation of:
1. Whether high fintech-score CAPS respondents live in areas with higher fintech lending activity
2. Whether fintech lending increases in CAPS respondents' neighborhoods after branch closures
3. Whether the branch closure buffering effect (Resilience × Closure interaction) operates through actual fintech credit access

## Data Sources

### 1. CAPS (Community Advantage Panel Survey)
- **Currently have**: Individual-level data with ZIP codes, years 2003-2014
- **Key variables**:
  - Fintech creditworthiness score (constructed)
  - ZIP code location
  - Branch closure exposure
  - Mortgage outcomes

### 2. HMDA (Home Mortgage Disclosure Act) Loan Application Register
- **Source**: CFPB Public Data (https://ffiec.cfpb.gov/data-browser/)
- **Years needed**: 2010-2014 (overlap with CAPS and fintech emergence)
- **Geography**: Census Tract → can be aggregated to ZIP code
- **Key variables**:
  - Respondent ID (lender identifier)
  - Census Tract, County, State
  - Loan amount, Action taken (originated, denied, etc.)
  - Loan purpose, Loan type

### 3. Fuster et al. Fintech Lender Classification
- **Currently have**: `Data/Fintech_Classification/fintech_classification.xlsx`
- **Content**: List of HMDA Respondent IDs classified as fintech lenders
- **Source**: Fuster, Plosser, Schnabl & Vickery (2019)

### 4. Geography Crosswalks
- **Currently have**: `Data/Crosswalks/zcta_county_primary.csv`
- **Need**: Census Tract to ZIP Code crosswalk (HUD USPS Crosswalk)

## Linkage Strategy

```
CAPS Individual Data (ZIP code, year)
        │
        ├──► Fintech Creditworthiness Score (constructed from CAPS variables)
        │
        └──► HMDA Aggregated Data (ZIP code, year)
                │
                ├── Total mortgage originations in ZIP
                ├── Fintech mortgage originations in ZIP (flagged by Fuster classification)
                ├── Fintech share = fintech originations / total originations
                └── Fintech lending growth (year-over-year change)
```

### Step 1: Download HMDA LAR Data
```bash
# From CFPB Data Browser or National Archives
# Files: hmda_2010_nationwide_all-records.csv through hmda_2014_nationwide_all-records.csv
# Size: ~2-5 GB per year
```

### Step 2: Process HMDA Data
For each year (2010-2014):
1. Load raw HMDA LAR file
2. Filter to:
   - Action Type = 1 (Loan originated)
   - Loan Purpose = 1 (Home purchase) or 3 (Refinancing)
   - Property Type = 1 (1-4 family dwelling)
3. Merge with Fuster fintech classification on Respondent ID
4. Flag loans from fintech lenders
5. Aggregate to Census Tract level:
   - Total originations
   - Fintech originations
   - Fintech share

### Step 3: Convert Census Tract to ZIP
- Use HUD USPS Crosswalk (census tract → ZIP)
- Weight by residential addresses if multiple ZIPs per tract
- Aggregate fintech metrics to ZIP level

### Step 4: Merge with CAPS
- Match on ZIP code × year
- Each CAPS respondent gets local fintech lending environment

## Empirical Specifications

### Test 1: Do High Fintech Score Individuals Live in High Fintech Lending Areas?
```
FintechShare_zt = α + β₁·FintechScore_i + X_it + δ_t + ε_it
```
- H1: β₁ > 0 (revealed preference: high-scoring individuals live where fintech lenders operate)

### Test 2: Does Fintech Lending Increase After Branch Closures?
```
ΔFintechShare_zt = α + β₁·Closure_zt + β₂·(Closure_zt × FintechScore_i) + α_m + δ_t + ε_it
```
- H2: β₁ > 0 (fintech fills gap left by closures)
- H3: β₂ > 0 (fintech response stronger where high-scoring individuals reside)

### Test 3: Does Fintech Credit Access Explain Resilience Buffer?
```
Y_it = β₁·Closure_zt + β₂·(Closure × Resilience) + β₃·(Closure × FintechShare)
     + β₄·(Closure × Resilience × FintechShare) + α_m + δ_t + ε_it
```
- If β₂ attenuates when controlling for β₃, fintech access mediates the resilience buffer

## Data Download Instructions

### HMDA LAR Data (2010-2014)
1. Visit: https://ffiec.cfpb.gov/data-browser/
2. Or use National Archives: https://www.ffiec.gov/hmda/hmdaflat.htm
3. Download files for each year (2010-2014)
4. Place in: `Data/HMDA/LAR/`

### HUD USPS Crosswalk (Tract to ZIP)
1. Visit: https://www.huduser.gov/portal/datasets/usps_crosswalk.html
2. Download "TRACT-ZIP" crosswalk
3. Place in: `Data/Crosswalks/`

## File Size Estimates
- HMDA LAR 2010-2014: ~15-20 GB total (raw)
- After filtering to originations: ~3-5 GB
- After aggregation to ZIP-year: ~50 MB
- Final merged dataset: ~100 MB

## Processing Requirements
- Stata 17+ or Python/pandas for large file handling
- Recommend processing on server or high-memory workstation
- Alternative: Use CFPB's filtered download to reduce initial file size

## Timeline
1. Download HMDA data and crosswalks (1-2 hours)
2. Process HMDA data and flag fintech lenders (2-4 hours)
3. Aggregate to ZIP level (1-2 hours)
4. Merge with CAPS and run analysis (1-2 hours)

## Expected Outputs
1. `Data/HMDA/hmda_fintech_zip_year.dta` - ZIP-year level fintech lending data
2. `Data/caps_hmda_merged.dta` - CAPS with fintech lending environment
3. `Output/Tables/hmda_linkage_results.tex` - Regression tables
4. New paper section: "Direct Evidence on Fintech Credit Access"

## Limitations
1. Cannot observe individual-level HMDA-CAPS matches (no individual identifiers)
2. HMDA covers mortgages only, not small business lending
3. ZIP-level aggregation introduces measurement error
4. Fintech classification may miss some digital lenders

## Alternative Approaches
If full HMDA processing is infeasible:
1. Use existing Fuster county-level fintech shares (already have)
2. Construct synthetic fintech access measure from:
   - County fintech share × individual fintech score
   - This proxies for "fintech eligibility" without requiring HMDA processing

---

## Implementation Status (February 14, 2026)

### Data Downloaded
| File | Size | Status |
|------|------|--------|
| hmda_2010.zip | 1.1 GB | Downloaded |
| hmda_2012.zip | 1.3 GB | Downloaded |
| hmda_2013.zip | 1.2 GB | Downloaded |
| hmda_2014.zip | 823 MB | Downloaded |
| **Total** | **4.4 GB** | Complete |

Location: `Data/HMDA/LAR/`

### Technical Challenge: RSSD-to-Respondent ID Mapping
The Fuster fintech classification uses **RSSD IDs** (Federal Reserve identifiers), but HMDA LAR data uses **respondent_id** (agency-specific lender ID). These are different identifier systems.

**HMDA respondent_id formats:**
- 10-digit numbers (e.g., '0000019506')
- EIN format (e.g., '26-2261031')
- RSSD IDs in numeric format (e.g., '3844577')

**Fuster RSSD IDs (examples):**
- 4324982 (AVEX FUNDING / Better Mortgage)
- 3844577 (EVERETT FINANCIAL)
- 3870099 (GUARANTEED RATE)
- 3870679 (QUICKEN LOANS)

To flag fintech lenders in raw HMDA data, we would need either:
1. HMDA Transmittal Sheet / Reporter Panel (maps respondent_id to lender name and RSSD)
2. Federal Reserve NIC data (contains RSSD-to-other-ID crosswalks)

### Current Solution: Use Pre-Computed County Data
The Fuster et al. county-level data (`Data/Fintech_Classification/fintech_county_shares.csv`) already contains pre-computed fintech shares. This data was created using the proper RSSD mapping by the original authors.

**What we have:**
- County-year level fintech_share = fintech_lending / total_lending
- Coverage: 3,125 counties × 8 years (2010-2017)
- Already merged with CAPS via ZIP-county crosswalk

**Current analysis results:**
- Closure × Fintech Score: -0.0050 (t = -1.31)
- Interpretation: Negative (buffering) but not statistically significant

### Potential Next Steps
1. **Download HMDA Reporter Panel** to create RSSD → respondent_id mapping
   - Source: FFIEC (requires registration)
   - Would enable ZIP-level fintech flagging

2. **Use downloaded HMDA for other purposes:**
   - Total lending volume by geography
   - Lender concentration (HHI)
   - Approval rates by geography

3. **Accept county-level analysis as sufficient:**
   - County level may actually be appropriate for branch closure effects
   - Fintech operates regionally, not hyper-locally
