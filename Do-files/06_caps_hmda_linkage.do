********************************************************************************
* CAPS-HMDA Linkage Analysis
* Purpose: Test whether high fintech-score individuals obtain fintech credit
* Author: Research Assistant (Claude)
* Date: February 2026
********************************************************************************

clear all
set more off
set maxvar 32767

global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Financial_Inclusion/Fintech Research"

********************************************************************************
* PART 0: CHECK DATA AVAILABILITY
********************************************************************************

di _n "=============================================="
di "CHECKING DATA AVAILABILITY"
di "=============================================="

* Check for HMDA LAR data
cap confirm file "$root/Data/HMDA/LAR/hmda_2010_nationwide.csv"
local has_hmda_raw = (_rc == 0)

* Check for processed HMDA data
cap confirm file "$root/Data/HMDA/hmda_fintech_zip_year.dta"
local has_hmda_processed = (_rc == 0)

* Check for fintech classification
cap confirm file "$root/Data/Fintech_Classification/fintech_classification.xlsx"
local has_fintech_class = (_rc == 0)

di "Raw HMDA LAR data available: " `has_hmda_raw'
di "Processed HMDA data available: " `has_hmda_processed'
di "Fintech classification available: " `has_fintech_class'

if `has_hmda_processed' == 0 & `has_hmda_raw' == 0 {
    di _n "WARNING: No HMDA data found."
    di "To run this analysis, you need to:"
    di "  1. Download HMDA LAR data from https://ffiec.cfpb.gov/data-browser/"
    di "  2. Place files in $root/Data/HMDA/LAR/"
    di "  3. OR run the Python processing script first"
    di _n "Proceeding with ALTERNATIVE APPROACH using existing county-level data..."
}


********************************************************************************
* PART 1: PROCESS RAW HMDA DATA (if available)
* Skip if already processed or not available
********************************************************************************

if `has_hmda_raw' == 1 & `has_hmda_processed' == 0 {

    di _n "=============================================="
    di "PROCESSING RAW HMDA DATA"
    di "=============================================="

    * Note: This section requires significant memory and time
    * Consider running in Python for large files

    forvalues yr = 2010/2014 {
        di _n "Processing HMDA `yr'..."

        * Import raw HMDA LAR data
        import delimited "$root/Data/HMDA/LAR/hmda_`yr'_nationwide.csv", clear

        * Keep only originated loans
        keep if action_type == 1

        * Keep purchase and refinance loans on 1-4 family
        keep if inlist(loan_purpose, 1, 3)
        keep if property_type == 1

        * Create lender ID for matching
        gen lender_id = respondent_id

        * Merge with fintech classification
        merge m:1 lender_id using "$root/Data/Fintech_Classification/fintech_lenders.dta", ///
            keep(master match) nogen

        * Flag fintech loans
        gen fintech_loan = (fintech == 1) if fintech != .
        replace fintech_loan = 0 if fintech_loan == .

        * Aggregate to census tract level
        collapse (count) total_loans = loan_amount ///
                 (sum) fintech_loans = fintech_loan ///
                 (sum) total_amount = loan_amount, ///
            by(state_code county_code census_tract)

        gen year = `yr'

        * Save year file
        save "$root/Data/HMDA/hmda_tract_`yr'.dta", replace
    }

    * Append all years
    use "$root/Data/HMDA/hmda_tract_2010.dta", clear
    forvalues yr = 2011/2014 {
        append using "$root/Data/HMDA/hmda_tract_`yr'.dta"
    }

    * Create fintech share
    gen fintech_share_tract = fintech_loans / total_loans

    * Create tract FIPS
    gen tract_fips = state_code + county_code + census_tract

    * Save tract-level data
    save "$root/Data/HMDA/hmda_fintech_tract_year.dta", replace

    di "Tract-level HMDA data saved."

    * Aggregate to ZIP level using crosswalk
    * (Requires HUD USPS Tract-ZIP crosswalk)
    cap {
        merge m:1 tract_fips using "$root/Data/Crosswalks/tract_zip_crosswalk.dta"

        collapse (sum) total_loans fintech_loans total_amount ///
                 [pw=res_ratio], by(zip year)

        gen fintech_share_zip = fintech_loans / total_loans

        save "$root/Data/HMDA/hmda_fintech_zip_year.dta", replace
    }
}


********************************************************************************
* PART 2: ALTERNATIVE APPROACH - Use Existing County-Level Fintech Data
* This approach creates a "fintech access" proxy without requiring raw HMDA
********************************************************************************

di _n "=============================================="
di "ALTERNATIVE APPROACH: SYNTHETIC FINTECH ACCESS"
di "=============================================="

* Load CAPS with fintech scores
use "$root/Data/caps_geographic_merged.dta", clear
di "Loaded " _N " CAPS observations"

* Run variable mapping to get fintech scores
quietly do "$root/Do-files/05a_variable_mapping.do"

* Standardize fintech score
sum fintech_score
gen fintech_score_std = (fintech_score - r(mean)) / r(sd)

di _n "=== Fintech Score Distribution ==="
sum fintech_score fintech_score_std, d

* Check for county-level fintech share
cap confirm variable fintech_share
if _rc == 0 {
    di _n "County-level fintech share available."
    sum fintech_share, d

    * Create synthetic fintech access measure
    * Logic: High fintech score + High county fintech share = High fintech access

    * Standardize fintech share
    sum fintech_share
    gen fintech_share_std = (fintech_share - r(mean)) / r(sd) if fintech_share != .

    * Create interaction: Individual "fintech eligibility" × Local fintech availability
    gen fintech_access = fintech_score_std * fintech_share_std
    label var fintech_access "Synthetic fintech access (score × county share)"

    * Create high/low categories
    sum fintech_access, d
    gen high_fintech_access = (fintech_access > r(p50)) if fintech_access != .

    di _n "=== Synthetic Fintech Access ==="
    sum fintech_access, d
    tab high_fintech_access if default_90 != ., m
}
else {
    di "WARNING: County-level fintech_share not found."
    di "Creating proxy from individual score only."

    gen fintech_access = fintech_score_std
    gen high_fintech_access = (fintech_score_std > 0)
}


********************************************************************************
* PART 3: TEST 1 - REVEALED PREFERENCE
* Do high fintech score individuals live in high fintech areas?
********************************************************************************

di _n "=============================================="
di "TEST 1: REVEALED PREFERENCE"
di "Does fintech score correlate with local fintech penetration?"
di "=============================================="

cap {
    * Correlation
    corr fintech_score_std fintech_share_std if fintech_share_std != .

    * Regression: Do high-scoring individuals live in high-fintech areas?
    reg fintech_share_std fintech_score_std, robust
    estimates store revealed_pref

    di _n "Results:"
    di "If positive: high-scoring individuals live in high-fintech areas"
    di "This suggests revealed preference / self-selection into fintech-friendly areas"
}


********************************************************************************
* PART 4: TEST 2 - FINTECH ACCESS AND DEFAULT
* Does synthetic fintech access predict default?
********************************************************************************

di _n "=============================================="
di "TEST 2: FINTECH ACCESS AND DEFAULT"
di "=============================================="

* Baseline: Fintech score predicting default
di _n "=== Model 1: Fintech Score Only ==="
logit default_90 fintech_score_std, robust
estimates store m1_score
local auc1 = .
quietly lroc, nograph
local auc1 = r(area)
di "AUC: " %5.3f `auc1'

* Add fintech access
cap {
    di _n "=== Model 2: Fintech Score + County Fintech Share ==="
    logit default_90 fintech_score_std fintech_share_std, robust
    estimates store m2_access
    quietly lroc, nograph
    local auc2 = r(area)
    di "AUC: " %5.3f `auc2'

    di _n "=== Model 3: Fintech Score + Access Interaction ==="
    logit default_90 fintech_score_std fintech_share_std fintech_access, robust
    estimates store m3_interaction
    quietly lroc, nograph
    local auc3 = r(area)
    di "AUC: " %5.3f `auc3'
}


********************************************************************************
* PART 5: TEST 3 - BRANCH CLOSURE × FINTECH ACCESS
* Does fintech access buffer branch closure effects?
********************************************************************************

di _n "=============================================="
di "TEST 3: BRANCH CLOSURE × FINTECH ACCESS"
di "=============================================="

* Check for closure and self-employment variables
cap confirm variable closure_zip
cap confirm variable anytoise

di _n "=== Model 1: Baseline Closure Effect ==="
reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
estimates store closure_base

di _n "=== Model 2: Closure × Fintech Score ==="
reghdfe anytoise c.closure_zip##c.fintech_score_std, absorb(mergerID year) cluster(county_fips)
estimates store closure_score

di _n "Results:"
di "Closure main:     " %8.4f _b[closure_zip] " (SE = " %7.4f _se[closure_zip] ")"
di "Score main:       " %8.4f _b[fintech_score_std] " (SE = " %7.4f _se[fintech_score_std] ")"
di "Interaction:      " %8.4f _b[c.closure_zip#c.fintech_score_std] " (SE = " %7.4f _se[c.closure_zip#c.fintech_score_std] ")"

cap {
    di _n "=== Model 3: Closure × Fintech Access (Score × County Share) ==="
    reghdfe anytoise c.closure_zip##c.fintech_access, absorb(mergerID year) cluster(county_fips)
    estimates store closure_access

    di _n "Results:"
    di "Closure main:     " %8.4f _b[closure_zip] " (SE = " %7.4f _se[closure_zip] ")"
    di "Access main:      " %8.4f _b[fintech_access] " (SE = " %7.4f _se[fintech_access] ")"
    di "Interaction:      " %8.4f _b[c.closure_zip#c.fintech_access] " (SE = " %7.4f _se[c.closure_zip#c.fintech_access] ")"
}

di _n "=== Model 4: Closure × Resilience × Fintech Share (Triple) ==="
cap {
    reghdfe anytoise c.closure_zip##c.resilience_std##c.fintech_share_std, ///
        absorb(mergerID year) cluster(county_fips)
    estimates store closure_triple

    di _n "Three-way interaction (Closure × Resilience × Fintech Share):"
    di "  Coefficient: " %8.5f _b[c.closure_zip#c.resilience_std#c.fintech_share_std]
    di "  Std. Error:  " %8.5f _se[c.closure_zip#c.resilience_std#c.fintech_share_std]
}


********************************************************************************
* PART 6: TEST 4 - MEDIATION ANALYSIS
* Does fintech access mediate the resilience buffer?
********************************************************************************

di _n "=============================================="
di "TEST 4: MEDIATION ANALYSIS"
di "Does fintech access explain why resilience buffers closure effects?"
di "=============================================="

* Step 1: Total effect (Resilience → Self-employment after closure)
di _n "=== Step 1: Total Effect (Resilience on Closure) ==="
reghdfe anytoise c.closure_zip##c.resilience_std, absorb(mergerID year) cluster(county_fips)
local total_effect = _b[c.closure_zip#c.resilience_std]
di "Total effect (Closure × Resilience): " %8.5f `total_effect'

* Step 2: Effect of resilience on fintech access
cap {
    di _n "=== Step 2: Resilience → Fintech Access ==="
    reg fintech_access resilience_std, robust
    local resilience_to_access = _b[resilience_std]
    di "Resilience → Access: " %8.5f `resilience_to_access'
}

* Step 3: Direct effect controlling for fintech access
cap {
    di _n "=== Step 3: Direct Effect (Controlling for Fintech Access) ==="
    reghdfe anytoise c.closure_zip##c.resilience_std c.closure_zip##c.fintech_access, ///
        absorb(mergerID year) cluster(county_fips)
    local direct_effect = _b[c.closure_zip#c.resilience_std]
    di "Direct effect (Closure × Resilience | Access): " %8.5f `direct_effect'

    * Mediation proportion
    local mediated = (`total_effect' - `direct_effect') / `total_effect' * 100
    di _n "Mediation Analysis:"
    di "  Total effect:    " %8.5f `total_effect'
    di "  Direct effect:   " %8.5f `direct_effect'
    di "  Mediated (%%):    " %5.1f `mediated' "%%"
}


********************************************************************************
* PART 7: SUMMARY TABLE
********************************************************************************

di _n "=============================================="
di "SUMMARY: CAPS-HMDA LINKAGE ANALYSIS"
di "=============================================="

di _n "KEY FINDINGS:"
di "================================================================"

* Display available estimates
cap {
    estimates restore closure_score
    di "1. Closure × Fintech Score interaction: " %8.5f _b[c.closure_zip#c.fintech_score_std]
    di "   (Negative = high score buffers closure effect)"
}

cap {
    estimates restore closure_access
    di "2. Closure × Fintech Access interaction: " %8.5f _b[c.closure_zip#c.fintech_access]
    di "   (Negative = fintech access buffers closure effect)"
}

di _n "================================================================"
di "INTERPRETATION:"
di "If fintech access (score × local availability) shows stronger"
di "buffering than score alone, this suggests the mechanism operates"
di "through actual fintech credit availability, not just individual"
di "characteristics."
di "================================================================"


********************************************************************************
* PART 8: EXPORT RESULTS
********************************************************************************

di _n "=============================================="
di "EXPORTING RESULTS"
di "=============================================="

* Create results table
cap {
    esttab closure_base closure_score closure_access using ///
        "$root/Output/Tables/hmda_linkage_results.tex", ///
        replace booktabs ///
        title("Branch Closure Effects with Fintech Access Measures") ///
        mtitles("Baseline" "× Score" "× Access") ///
        stats(N r2_a, labels("Observations" "Adj. R-sq")) ///
        star(* 0.10 ** 0.05 *** 0.01)

    di "Results exported to Output/Tables/hmda_linkage_results.tex"
}

* Save working dataset
save "$root/Data/caps_hmda_analysis.dta", replace
di "Working dataset saved to Data/caps_hmda_analysis.dta"

di _n "=============================================="
di "ANALYSIS COMPLETE"
di "=============================================="
di _n "NEXT STEPS:"
di "1. If you have raw HMDA LAR data, run Part 1 to create ZIP-level measures"
di "2. Consider downloading HMDA data for more precise geographic matching"
di "3. The synthetic fintech access measure (score × county share) provides"
di "   initial evidence on the fintech credit access mechanism"
