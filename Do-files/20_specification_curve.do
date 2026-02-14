********************************************************************************
* Specification Curve Analysis
* Test robustness across many model specifications
********************************************************************************

clear all
set more off
cap log close
log using "specification_curve.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Other_Projects/JMP/Fintech Research"

di "=== SPECIFICATION CURVE ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data
********************************************************************************

use indivID year anytoise anytouse closure_zip fintech_share mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear

di "Full sample: " _N " observations"

* Create interaction
gen closure_x_fintech = closure_zip * fintech_share

* Restrict to analysis period
keep if year >= 2010 & year <= 2014

di "Analysis sample (2010-2014): " _N " observations"

********************************************************************************
* PART 2: Define Specifications
********************************************************************************

* We will vary:
* 1. Fixed effects: none, year, mergerID, mergerID+year, county
* 2. Clustering: robust, county, mergerID
* 3. Sample: full, pre-2012 only, homeowners only (if available)
* 4. Outcome: anytoise, anytouse

* Store results
tempfile results
postfile spec_results spec_id str50 spec_desc coef se pval n_obs using `results'

local spec_id = 0

********************************************************************************
* PART 3: Run Specifications
********************************************************************************

di ""
di "=== RUNNING SPECIFICATIONS ==="
di ""

* ------- Specification 1: No FE, robust SE -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': No FE, robust SE"
cap reg anytoise closure_zip fintech_share closure_x_fintech, robust
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("No FE, robust") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 2: Year FE only, robust SE -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': Year FE, robust SE"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(year) vce(robust)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("Year FE, robust") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 3: MergerID FE only, robust SE -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': MergerID FE, robust SE"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID) vce(robust)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("MergerID FE, robust") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 4: MergerID + Year FE, robust SE -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': MergerID + Year FE, robust SE"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) vce(robust)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("MergerID+Year FE, robust") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 5: County FE, robust SE -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': County FE, robust SE"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(county_fips) vce(robust)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("County FE, robust") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 6: MergerID + Year FE, county cluster (BASELINE) -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': MergerID + Year FE, county cluster [BASELINE]"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("BASELINE: MergerID+Year, county cluster") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ") *** BASELINE ***"
}

* ------- Specification 7: MergerID + Year FE, mergerID cluster -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': MergerID + Year FE, mergerID cluster"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(mergerID)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("MergerID+Year FE, mergerID cluster") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 8: County + Year FE, county cluster -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': County + Year FE, county cluster"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(county_fips year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("County+Year FE, county cluster") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 9: Alternative outcome (anytouse) -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': anytouse outcome, MergerID+Year FE, county cluster"
cap reghdfe anytouse closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("anytouse outcome") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

* ------- Specification 10: Pre-2012 sample only -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': Pre-2012 sample only"
preserve
keep if year <= 2012
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("Pre-2012 sample") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}
restore

* ------- Specification 11: Post-2012 sample only -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': Post-2012 sample only"
preserve
keep if year >= 2012
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("Post-2012 sample") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}
restore

* ------- Specification 12: Individual FE (different identification) -------
local spec_id = `spec_id' + 1
di "Spec `spec_id': Individual + Year FE, county cluster"
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(indivID year) cluster(county_fips)
if _rc == 0 {
    local b = _b[closure_x_fintech]
    local se = _se[closure_x_fintech]
    local p = 2*ttail(e(df_r), abs(`b'/`se'))
    local n = e(N)
    post spec_results (`spec_id') ("Individual+Year FE") (`b') (`se') (`p') (`n')
    di "  Coef: " %7.4f `b' " (SE = " %6.4f `se' ")"
}

postclose spec_results

********************************************************************************
* PART 4: Display Results Summary
********************************************************************************

di ""
di "=== SPECIFICATION CURVE RESULTS ==="
di ""

use `results', clear

di "Specification | Coefficient | SE | p-value | N"
di "--------------|-------------|-------|---------|--------"
forvalues i = 1/`=_N' {
    local desc = spec_desc[`i']
    local coef = coef[`i']
    local se = se[`i']
    local p = pval[`i']
    local n = n_obs[`i']
    di "`i'. " substr("`desc'", 1, 35) " | " %7.4f `coef' " | " %5.3f `se' " | " %5.3f `p' " | " %6.0f `n'
}

* Summary statistics
sum coef
di ""
di "Coefficient range: " %7.4f r(min) " to " %7.4f r(max)
di "Mean coefficient: " %7.4f r(mean)
di "SD of coefficients: " %7.4f r(sd)

* Count significant results
count if pval < 0.10
local sig10 = r(N)
count if pval < 0.05
local sig05 = r(N)
di ""
di "Significant at 10%: " `sig10' " / " _N " specifications"
di "Significant at 5%: " `sig05' " / " _N " specifications"

* Export to CSV for plotting
export delimited using "Output/specification_curve_results.csv", replace

********************************************************************************
* PART 5: Summary
********************************************************************************

di ""
di "=== SPECIFICATION CURVE SUMMARY ==="
di ""
di "The specification curve shows coefficient estimates across `=_N' specifications."
di ""
di "Key findings:"
di "  - Coefficient range shows robustness (or lack thereof)"
di "  - Percentage significant shows consistency of statistical inference"
di "  - Results exported to Output/specification_curve_results.csv for plotting"
di ""
di "For the paper: Create a plot with coefficients ordered by magnitude,"
di "with confidence intervals, showing which specifications are significant."

di ""
di "End: " c(current_time)

log close
