********************************************************************************
* Instrumental Variables Analysis: Pre-Period Broadband as IV for Fintech
*
* Logic: Pre-period broadband infrastructure (2005-2008) predicts later fintech
* adoption but shouldn't directly affect 2010-2014 self-employment transitions
* conditional on controls.
*
* NOTE: This requires historical county-level broadband data. Currently using
* 2019 broadband as a placeholder to demonstrate methodology. The proper
* instrument would use 2005-2008 FCC Form 477 or ASU county broadband data.
********************************************************************************

clear all
set more off
cap log close
log using "broadband_iv_analysis.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== INSTRUMENTAL VARIABLES ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load and Merge Data
********************************************************************************

* Load only needed variables to avoid memory issues
use indivID year anytoise closure_zip fintech_share mergerID county_fips zip using "Data/caps_geographic_merged.dta", clear

* Restrict to fintech analysis sample
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
di "Fintech analysis sample: " _N " observations"

* Create interaction
gen closure_x_fintech = closure_zip * fintech_share

********************************************************************************
* PART 2: Check for Broadband Data
********************************************************************************

* Try to merge 2019 broadband (placeholder - ideally use pre-period broadband)
cap merge m:1 zip using "Data/Broadband/broadband_zip.dta", keepusing(broadband_pct)
if _rc == 0 {
    drop if _merge == 2
    gen has_broadband = (_merge == 3)
    drop _merge
    di "Merged broadband data"
}
else {
    di "Broadband data not found - creating placeholder"
    gen broadband_pct = .
    gen has_broadband = 0
}

********************************************************************************
* PART 3: OLS Baseline (for comparison with IV)
********************************************************************************

di ""
di "=== OLS BASELINE ==="

reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)

local ols_coef = _b[closure_x_fintech]
local ols_se = _se[closure_x_fintech]
di "OLS coefficient on interaction: " %7.4f `ols_coef' " (SE = " %6.4f `ols_se' ")"

********************************************************************************
* PART 4: First Stage - Does Broadband Predict Fintech?
********************************************************************************

di ""
di "=== FIRST STAGE: BROADBAND -> FINTECH ==="

if has_broadband[1] == 1 {
    * First stage regression
    reghdfe fintech_share broadband_pct, absorb(mergerID year) cluster(county_fips)

    local fs_coef = _b[broadband_pct]
    local fs_se = _se[broadband_pct]
    local fs_f = e(F)

    di "First stage coefficient: " %7.4f `fs_coef' " (SE = " %6.4f `fs_se' ")"
    di "First stage F-statistic: " %7.2f `fs_f'

    if `fs_f' < 10 {
        di "WARNING: Weak instrument (F < 10)"
    }
}
else {
    di "No broadband data available for first stage"
}

********************************************************************************
* PART 5: IV Estimation
********************************************************************************

di ""
di "=== IV ESTIMATION ==="

if has_broadband[1] == 1 {
    * Create instrument for interaction: broadband × closure
    gen closure_x_broadband = closure_zip * broadband_pct

    * 2SLS: instrument closure_x_fintech with closure_x_broadband
    * Note: This is a simplified IV - full implementation would use ivreg2

    cap ivreghdfe anytoise closure_zip fintech_share (closure_x_fintech = closure_x_broadband), absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        local iv_coef = _b[closure_x_fintech]
        local iv_se = _se[closure_x_fintech]
        di "IV coefficient on interaction: " %7.4f `iv_coef' " (SE = " %6.4f `iv_se' ")"
    }
    else {
        di "ivreghdfe not installed - trying ivreg2"
        cap ivreg2 anytoise closure_zip fintech_share (closure_x_fintech = closure_x_broadband) i.mergerID i.year, cluster(county_fips) first
        if _rc == 0 {
            local iv_coef = _b[closure_x_fintech]
            local iv_se = _se[closure_x_fintech]
            di "IV coefficient: " %7.4f `iv_coef' " (SE = " %6.4f `iv_se' ")"
        }
        else {
            di "IV estimation requires ivreg2 or ivreghdfe package"
            di "Install with: ssc install ivreg2"
        }
    }
}
else {
    di "Cannot run IV without broadband instrument data"
    di ""
    di "To implement this analysis:"
    di "1. Download historical county broadband data (2005-2008)"
    di "   - ASU Center on Technology, Data and Society"
    di "   - FCC Form 477 archives"
    di "2. Merge to CAPS data via zip-to-county crosswalk"
    di "3. Use pre-period broadband as instrument for fintech adoption"
}

********************************************************************************
* PART 6: Reduced Form (if IV fails)
********************************************************************************

di ""
di "=== REDUCED FORM ==="

if has_broadband[1] == 1 {
    * Reduced form: effect of closure × broadband on outcome
    reghdfe anytoise closure_zip broadband_pct closure_x_broadband, absorb(mergerID year) cluster(county_fips)

    local rf_coef = _b[closure_x_broadband]
    local rf_se = _se[closure_x_broadband]
    di "Reduced form coefficient: " %7.4f `rf_coef' " (SE = " %6.4f `rf_se' ")"

    * IV = reduced form / first stage
    if `fs_coef' != 0 {
        local iv_implied = `rf_coef' / `fs_coef'
        di "Implied IV coefficient: " %7.4f `iv_implied'
    }
}

********************************************************************************
* PART 7: Summary
********************************************************************************

di ""
di "=== ANALYSIS SUMMARY ==="
di ""
di "The IV strategy uses pre-period broadband infrastructure as an instrument"
di "for later fintech adoption. The identifying assumption is that conditional"
di "on merger-group and year FE, early broadband affects 2010-2014 self-employment"
di "transitions only through its effect on fintech availability."
di ""
di "Key requirements:"
di "1. Relevance: High broadband areas adopted more fintech (first stage)"
di "2. Exclusion: Early broadband doesn't directly affect later SE transitions"
di "   (conditional on FE and controls)"
di ""
di "This assumption is plausible if:"
di "- Broadband infrastructure was determined by factors like cable TV presence"
di "- These factors don't directly affect entrepreneurship 5-10 years later"
di "- The FE absorb time-invariant county characteristics"

log close
