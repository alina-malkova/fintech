# Fintech Creditworthiness Assessment Research Project

## Principal Investigator
Alina Malkova, Florida Institute of Technology

## Research Topic
Assessment of creditworthiness using CAPS data and advanced fintech assessment technologies

## Background: Published Paper
- **Title**: "Knockin' on the Bank's Door"
- **Journal**: Southern Economic Journal (SEJ), 2024
- **Data**: Community Advantage Panel Survey (CAPS) from UNC's Center for Community Capital
- **Method**: Shift-share design examining how bank branch closures affect self-employment dynamics
- **Key Finding**: Bank branch closures lead to decline in incorporated businesses

## Proposed Extension
Examine whether fintech alternatives can fill the credit gap left by bank branch closures, specifically:
- Can fintech-style credit assessment methods better identify creditworthy borrowers among the low-to-moderate income population?
- Do alternative scoring methods using behavioral/survey data predict loan performance better than traditional metrics for underserved borrowers?

## Why CAPS Data is Valuable
1. **Geographic Precision**: Individual-level location data (zip code) allows matching respondents to local bank branch closures
2. **Panel Structure**: Tracks same individuals over time
3. **Rich Behavioral Variables**: Income volatility, savings patterns, digital banking usage, credit history, payment patterns
4. **Target Population**: Low-to-moderate income borrowers are exactly the population fintech claims to serve better

## CAPS Limitation as a Feature
- CAPS only covers low-to-medium income borrowers (Community Advantage Program targeted affordable lending)
- External validity concern for general population
- **However**: For fintech creditworthiness research, this is the RIGHT population
  - Fintech's value proposition is serving underserved borrowers (thin-file, low-to-moderate income, minorities)
  - These are the marginal borrowers who lose access when branches close
  - The paper asks: "Could fintech methods better identify creditworthy borrowers among the population that traditional banks struggle with?"

## Research Design Concept
1. Construct alternative credit scores using CAPS behavioral variables:
   - Payment patterns
   - Income stability
   - Digital banking usage
   - Savings behavior
   - Employment history
   - Bill payment consistency
2. Benchmark alternative scores against actual loan performance outcomes in CAPS
3. Test whether fintech-style scoring could reduce credit rationing for the population that loses access when branches close
4. Interact fintech "readiness" measures with branch closure instrument from published paper

## Available Data Sources for Fintech Context

### Primary Data
- **CAPS (Community Advantage Panel Survey)**: Main dataset with individual-level geocoded financial behavior

### Supplementary Public Data for Fintech Penetration
| Source | Geography | Content | Access |
|--------|-----------|---------|--------|
| HMDA + Fuster et al. classification | Zip code | Fintech mortgage lender market share | Public |
| FDIC Summary of Deposits | Zip code | Bank branch locations/closures | Public |
| FDIC Unbanked Survey | State/MSA | Alternative financial services usage | Public |
| CRA Small Business Lending | Census tract | Bank small business loans | Public |
| PPP Loan Data | Zip code | Fintech lender PPP participation | Public |
| Fed Small Business Credit Survey | National | Online lender application rates | Public |

### Restricted Data Alternatives (if needed)
- NY Fed Consumer Credit Panel (requires Fed collaboration)
- PSID geocoded files (ICPSR restricted-use application)
- National Mortgage Database (FHFA research program)

## Key References
- Fuster, Plosser, Schnabl & Vickery (2019) - Fintech lender classification methodology
- Jagtiani & Lemieux (Philadelphia Fed) - Fintech lending research
- CFPB Section 1033 open banking rule (October 2024) - Policy hook

## Research Questions to Address
1. Which CAPS variables best predict loan performance using non-traditional metrics?
2. How do fintech-style scores compare to traditional credit scores for CAPS borrowers?
3. Do borrowers who would be "fintech-eligible" experience different outcomes when local branches close?
4. What is the potential credit expansion from alternative scoring methods for underserved populations?

## Data Strategy: Use Fuster et al. Pre-Computed County Data

### Decision
Use existing Fuster et al. (2019) county-year level fintech penetration data rather than processing raw HMDA files.

### Data Linkage Structure
```
CAPS Individual Data (zip code)
        │
        ├──► FDIC Summary of Deposits (branch closures) [EXISTING from published paper]
        │
        └──► Fuster et al. County-Level Fintech Data (NEW layer)
                │
                ├── fintech_share = loan_amount / total_lending
                └── Coverage: 3,125 counties × 8 years (2010-2017)
```

### Downloaded Data
**Location**: `Data/Fintech_Classification/`

| File | Description |
|------|-------------|
| `fintech_county_shares.csv` | County-year fintech lending (CSV) |
| `fintech_county_lending.dta` | County-year fintech lending (Stata) |
| `fintech_classification.xlsx` | Fintech lender HMDA IDs |
| `lender_national_shares.xlsx` | All lender market shares |

### Data Structure
```
fips,year,loan_amount,total_lending
01001,2010,.007675,.212044
01001,2011,.009057,.179795
...
```

- `fips`: 5-digit county FIPS code
- `year`: 2010-2017
- `loan_amount`: Fintech mortgage lending volume (billions $)
- `total_lending`: Total mortgage lending volume (billions $)
- **Fintech share** = `loan_amount / total_lending`

### Merge Strategy

**Step 1**: Create zip-to-county crosswalk
- Use HUD USPS ZIP Code Crosswalk or Census ZCTA-to-County file
- CAPS zip codes → County FIPS codes

**Step 2**: Merge fintech data
- Match on county FIPS + year
- Each CAPS respondent gets county-level fintech environment

### Stata Do-File Template
```stata
* ============================================
* Merge CAPS with Fuster et al. Fintech Data
* ============================================

* 1. Load fintech county data
import delimited "Data/Fintech_Classification/fintech_county_shares.csv", clear
rename fips county_fips
gen fintech_share = loan_amount / total_lending
label var fintech_share "Fintech mortgage market share"
save "Data/fintech_county.dta", replace

* 2. Load zip-to-county crosswalk (already downloaded)
import delimited "Data/Crosswalks/zcta_county_primary.csv", clear
rename zcta zip
destring zip, replace
destring county_fips, replace
save "Data/zip_county_xwalk.dta", replace

* 3. Add county FIPS to CAPS data
use "caps_analysis.dta", clear
rename zipcode zip
merge m:1 zip using "Data/zip_county_xwalk.dta"
drop if _merge == 2
drop _merge

* 4. Merge fintech penetration
merge m:1 county_fips year using "Data/fintech_county.dta"
drop if _merge == 2
drop _merge

* 5. Create interaction with branch closure
gen branch_x_fintech = branch_closure * fintech_share

* 6. Run extended specification
reghdfe self_employment branch_closure fintech_share branch_x_fintech ///
    $controls, absorb(id year) cluster(county_fips)
```

### Empirical Specification
```
Y_it = β₁(BranchClosure_ct) + β₂(FintechShare_ct)
     + β₃(BranchClosure_ct × FintechShare_ct) + X_it + α_i + δ_t + ε_it
```

Where:
- Y_it = Self-employment outcome for individual i at time t
- BranchClosure_ct = Branch closure measure in county c at time t
- FintechShare_ct = Fintech market share in county c at time t
- **β₃ = Key coefficient**: Does fintech mitigate branch closure effects?

### Hypothesis
- β₁ < 0 (branch closures hurt self-employment, as in published paper)
- β₃ > 0 (fintech presence mitigates the negative effect)

## Next Steps
1. [x] Download Fuster et al. fintech county data ✓
2. [x] Obtain ZIP-County crosswalk ✓ (Census Bureau 2020)
3. [x] Download Social Capital Atlas (Facebook data) ✓
4. [x] Download additional geographic datasets ✓
   - Food Access Atlas (USDA 2019) ✓
   - Broadband Access (Census ACS 2019) ✓
   - Dollar Stores (Census CBP 2019) ✓
   - Banking Deserts (FDIC SOD 2023) ✓
5. [ ] Merge all data with CAPS
6. [ ] Replicate main specification with fintech interaction
7. [ ] Identify CAPS variables for alternative creditworthiness scoring

## Geographic Alternative Data Sources
**Documentation**: `Data/Geographic_Alternative_Data_Sources.md`

### Downloaded:
| Dataset | Geography | Location |
|---------|-----------|----------|
| Fuster Fintech | County | `Fintech_Classification/` |
| ZCTA-County Crosswalk | ZCTA | `Crosswalks/` |
| **Social Capital Atlas** | ZIP | `Social_Capital/` |
| **Food Access Atlas** | Tract → County | `Food_Access/` |
| **Broadband Access** | ZIP | `Broadband/` |
| **Dollar Stores** | County | `Dollar_Stores/` |
| **Banking Access/Deserts** | County | `Banking_Deserts/` |

### Banking Access Data Details
**Source**: FDIC Summary of Deposits (2023)
- 77,770 bank branches nationwide
- Aggregated to county level (3,247 counties)
- **Key Variables**:
  - `num_branches`: Number of bank branches in county
  - `branches_per_10k`: Branches per 10,000 population
  - `banking_desert`: Counties with < 1 branch per 10k (n=178)
  - `low_branch_access`: Bottom 25% of branch density (n=805)
  - `no_branches`: Counties with zero branches (n=48)

## Downloaded Crosswalk
**Location**: `Data/Crosswalks/zcta_county_primary.csv`
- 33,791 ZCTAs mapped to primary county (largest area overlap)
- Use this to convert CAPS zip codes to county FIPS

## Stata Do-Files
**Location**: `Do-files/`

| File | Purpose |
|------|---------|
| `01_merge_fintech_data.do` | Merge CAPS with fintech data via crosswalk |
| `02_regression_analysis.do` | Main regression analysis |
| `03_fintech_credit_scores.do` | Construct fintech-style creditworthiness scores |
| `04_merge_geographic_data.do` | Merge ALL geographic alternative data sources |

## Fintech Creditworthiness Framework
**File**: `CAPS_Fintech_Creditworthiness_Variables.md`

Maps CAPS variables to fintech alternative credit scoring domains:
1. **Payment Behavior** - Mortgage delinquency, utility payments, bill collectors
2. **Income Stability** - Job loss, hours reduced, income volatility
3. **Financial Resilience** - Savings, emergency fund, retirement accounts
4. **Debt Burden** - Housing cost ratio, DTI
5. **AFS Usage** - Payday loans, pawnshops (negative signal)
6. **Stability** - Residential tenure, marital status
7. **Human Capital** - Education level
8. **Social Capital** - Community involvement, neighbor trust

### To Run:
1. Open `01_merge_fintech_data.do`
2. Modify paths and variable names (marked with MODIFY comments)
3. Run to create `caps_fintech_merged.dta`
4. Open `02_regression_analysis.do`
5. Modify outcome/control variable names
6. Run analysis

---

## Alternative Creditworthiness Research Direction (February 2026)

### Current Paper Status
The current paper tests county-level moderation (does fintech presence attenuate branch closure effects?). Results:
- Baseline: Significant interaction (β = 0.82, p < 0.05)
- With county FE: Coefficient drops to 0.28, loses significance
- Sample: N = 484 (147 individuals, 59 counties)
- **Assessment**: Results are fragile due to identification challenges

### Proposed Pivot: Individual-Level Fintech Creditworthiness
Instead of testing county-level moderators, develop an individual-level "fintech-style credit score" using CAPS behavioral variables.

**Core Insight**: CAPS has rich individual-level variables (payment history, income stability, savings, AFS usage) that mimic what fintech lenders actually use for alternative scoring. This approach:
1. Tests individual-level mechanisms (do characteristics fintech values predict better outcomes?)
2. Does NOT require fintech penetration to be exogenous
3. Uses geographic data as environmental context rather than key explanatory variable

### Research Design

**Step 1: Construct Fintech Creditworthiness Index**
- Payment Behavior Index (40% weight): utility payments, bill collectors, bankruptcy
- Income Stability Index (25%): job loss, income volatility, employment tenure
- Financial Resilience Index (15%): savings, emergency fund, health insurance
- Debt Burden Index (10%): DTI, housing cost ratio
- Other (10%): stability, education, AFS avoidance

**Step 2: Validate Against Loan Outcomes**
- Outcome: `default_90` (90+ day mortgage delinquency)
- Compare predictive power: Fintech score vs. traditional DTI/LTV
- Test: Does fintech score add predictive power? (likelihood ratio test)
- Measure: AUC comparison across scoring methods

**Step 3: Geographic Heterogeneity Tests**
- Is predictive advantage of fintech score stronger in banking deserts?
- Is predictive advantage stronger in high-fintech penetration areas? (revealed preference)
- Is predictive advantage stronger in high-broadband areas? (digital access enabled)

**Step 4: Branch Closure Integration**
- Key test: Do individuals with high fintech scores experience smaller self-employment losses from branch closures?
- Specification: `Y_it = β₁(Closure) + β₂(Closure × FintechScore_individual) + FE`
- This is a micro-level test of the mechanism

### Why This Is Stronger
| Current Approach | Alternative Approach |
|------------------|---------------------|
| County-level moderators | Individual-level predictors |
| Requires fintech penetration exogeneity | Does not require exogeneity |
| Tests "does fintech area help?" | Tests "do fintech-valued characteristics predict?" |
| N = 484, fragile identification | Uses full CAPS sample |
| Geographic data is key variable | Geographic data is context |

### Do-File
**File**: `Do-files/05_fintech_creditworthiness_analysis.do`

Sections:
1. Variable discovery (run `lookfor` commands)
2. Predictor variable construction (8 domains)
3. Composite index construction (4 approaches: weighted, simple, PCA, payment-focused)
4. Validation against loan outcomes (logit, AUC, LR tests)
5. Geographic heterogeneity (banking deserts, fintech penetration, broadband)
6. Branch closure integration (individual score × closure interaction)
7. Credit expansion analysis (misclassification rates)

### Next Steps
1. [x] Run variable discovery section to identify exact CAPS variable names
2. [x] Update variable names in do-file based on discovery
3. [x] Run analysis and assess fintech score predictive power
4. [x] Write up results for paper revision

### Key Results (February 14, 2026)
- **AUC = 0.926** - Exceptional predictive power for mortgage default
- **Pseudo R² = 0.457** - Very high for logit model
- **Default by tercile**: Bottom 33% = 52%, Middle = 9.4%, Top 33% = 0%
- **Marginal effect**: 1 SD increase → 14 pp reduction in default probability
- **Geographic heterogeneity**: AUC = 0.928 (non-desert) vs 0.911 (banking desert)
- **Branch closure × Resilience interaction**: -0.0083 (t = -1.67, p = 0.098) - marginally significant buffer effect
- **Branch closure × Emergency Fund**: -0.039 (t = -1.47) - protective but not significant
- Results added to paper as new Section 6 (now 44 pages)

### Key Hypothesis
If fintech-style scoring captures creditworthy borrowers that traditional metrics miss:
- Fintech score should predict default better than DTI alone
- Predictive advantage should be strongest in banking deserts (where soft info lost)
- High-scoring individuals should be more resilient to branch closures

---

## CAPS-HMDA Linkage Extension (February 14, 2026)

### Research Question
Do individuals with high fintech creditworthiness scores actually obtain fintech mortgage credit, especially when traditional bank branches close?

### Files Created
| File | Purpose |
|------|---------|
| `Paper/CAPS_HMDA_Research_Design.md` | Full research design document |
| `Do-files/06_caps_hmda_linkage.do` | Stata analysis do-file |
| `Scripts/process_hmda_fintech.py` | Python script for large HMDA file processing |

### Data Requirements
1. **HMDA LAR Data** (2010-2014): Download from https://ffiec.cfpb.gov/data-browser/
2. **Tract-ZIP Crosswalk**: Download from https://www.huduser.gov/portal/datasets/usps_crosswalk.html
3. **Fuster Fintech Classification**: Already have in `Data/Fintech_Classification/`

### Alternative Approach Results (Using County-Level Data)
Without raw HMDA data, created synthetic "fintech access" measure = Individual Score × County Fintech Share

| Test | Result |
|------|--------|
| Closure × Fintech Score | -0.00501 (t = -1.31) |
| Interpretation | Negative (buffering) but not significant |

### Key Insight
The individual-level fintech score interaction (-0.0050) is similar in magnitude to the resilience index interaction (-0.0083), suggesting the composite score captures the relevant protective characteristics.

### HMDA Data Processing - COMPLETE

#### Downloaded Data
| File | Size | Status |
|------|------|--------|
| hmda_2010.zip | 1.1 GB | Downloaded |
| hmda_2012.zip | 1.3 GB | Downloaded |
| hmda_2013.zip | 1.2 GB | Downloaded |
| hmda_2014.zip | 823 MB | Downloaded |
| panel_2010-2014.dat | 55 MB | Downloaded |
| **Total** | **~4.5 GB** | Complete |

Location: `Data/HMDA/LAR/` and `Data/HMDA/panel/`

#### RSSD-to-Respondent ID Mapping
Extracted 22 fintech lender respondent IDs from HMDA Panel files:
- Quicken Loans: `7197000003`
- Guaranteed Rate: `36-4327855`
- LoanDepot: `26-4599244`
- Movement Mortgage: `26-0595342`
- And 18 others (see `Data/HMDA/fintech_respondent_ids.txt`)

#### Processing Results
| Year | Total Loans | Fintech Loans | Fintech Share |
|------|-------------|---------------|---------------|
| 2010 | 7,339,586 | 238,830 | 3.25% |
| 2012 | 9,209,049 | 522,992 | 5.68% |
| 2013 | 8,089,135 | 590,114 | 7.30% |
| 2014 | 5,466,750 | 487,133 | 8.91% |

**Validation**: Correlation with Fuster county-level data = 0.84

#### Output Files
| File | Description |
|------|-------------|
| `Data/HMDA/hmda_fintech_tract_year.csv` | 281,747 tract-year observations |
| `Data/HMDA/hmda_fintech_county_year.csv` | 12,851 county-year observations |
| `Data/HMDA/hmda_fintech_zip_year.csv` | ZIP-year level for CAPS merging |
| `Data/HMDA/fintech_lender_mapping.csv` | RSSD to respondent_id mapping |

#### Implementation Status
1. ~~Download HMDA LAR files (2010-2014)~~ ✓ Complete (4.4 GB)
2. ~~Download HMDA Panel files for RSSD mapping~~ ✓ Complete
3. ~~Extract fintech respondent IDs~~ ✓ Complete (22 IDs)
4. ~~Process HMDA and flag fintech loans~~ ✓ Complete
5. ~~Aggregate to county/ZIP level~~ ✓ Complete
6. ~~Merge with CAPS and run analysis~~ ✓ Complete (Python)

#### Analysis Results
| Model | Coefficient | t-stat | p-value | N |
|-------|-------------|--------|---------|---|
| Closure × HMDA Share | +0.00479 | 1.92 | 0.054 | 10,368 |
| Closure × Fuster Share | +0.00114 | 0.37 | 0.710 | 13,027 |

**Key Finding**: The HMDA-based interaction is **marginally positive** (t = 1.92), opposite of expected buffering. This suggests fintech presence does NOT mitigate branch closure effects on self-employment.

**Interpretation**: Fintech lenders may enter areas where traditional banks are leaving, but they don't effectively substitute for relationship lending that supports small business formation. This is consistent with fintech's focus on standardized mortgage products rather than small business lending.

---

*Last updated: February 14, 2026*
