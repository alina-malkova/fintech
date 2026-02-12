********************************************************************************
* Dose-Response Analysis
* Is fintech mitigation strongest where closures are most binding?
********************************************************************************

clear all
set more off
cap log close
log using "dose_response_analysis.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== DOSE-RESPONSE ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data
********************************************************************************

use indivID year anytoise anytouse closure_zip fintech_share mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear

* Restrict to fintech analysis sample
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
di "Analysis sample: " _N " observations"

* Merge branch density
merge m:1 county_fips using "Data/Banking_Deserts/banking_access_county.dta", ///
    keepusing(branches_per_10k banking_desert) keep(1 3) nogen

* Create interactions
gen closure_x_fintech = closure_zip * fintech_share

********************************************************************************
* PART 2: Triple Interaction - Closure × Fintech × Low Branch Density
********************************************************************************

di ""
di "=== TRIPLE INTERACTION: CLOSURE × FINTECH × LOW BRANCH DENSITY ==="
di "Testing: Is fintech mitigation strongest where branches are scarcest?"

* Create low branch density indicator (below median)
sum branches_per_10k, d
gen low_branch = (branches_per_10k < r(p50)) if branches_per_10k != .

* Triple interaction
gen closure_x_lowbranch = closure_zip * low_branch
gen fintech_x_lowbranch = fintech_share * low_branch
gen closure_x_fintech_x_lowbranch = closure_x_fintech * low_branch

di ""
di "--- Model 1: Baseline (for comparison) ---"
reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)

di ""
di "--- Model 2: Triple Interaction ---"
reghdfe anytoise closure_zip fintech_share closure_x_fintech ///
    low_branch closure_x_lowbranch fintech_x_lowbranch closure_x_fintech_x_lowbranch, ///
    absorb(mergerID year) cluster(county_fips)

di ""
di "Interpretation:"
di "  closure_x_fintech = effect in HIGH branch density areas"
di "  closure_x_fintech_x_lowbranch = ADDITIONAL effect in LOW branch density areas"
di "  If positive: fintech mitigation is STRONGER where branches are scarce"

********************************************************************************
* PART 3: Split Sample by Branch Density
********************************************************************************

di ""
di "=== SPLIT SAMPLE BY BRANCH DENSITY ==="

preserve
keep if low_branch == 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Low branch density: coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
}
else {
    di "Low branch density: insufficient observations or variation"
}
restore

preserve
keep if low_branch == 0
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "High branch density: coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
}
else {
    di "High branch density: insufficient observations or variation"
}
restore

********************************************************************************
* PART 4: Banking Desert Analysis
********************************************************************************

di ""
di "=== BANKING DESERT ANALYSIS ==="
di "Testing effect in banking deserts (<1 branch per 10k population)"

* Triple interaction with banking desert
gen closure_x_desert = closure_zip * banking_desert
gen fintech_x_desert = fintech_share * banking_desert
gen closure_x_fintech_x_desert = closure_x_fintech * banking_desert

cap reghdfe anytoise closure_zip fintech_share closure_x_fintech ///
    banking_desert closure_x_desert fintech_x_desert closure_x_fintech_x_desert, ///
    absorb(mergerID year) cluster(county_fips)

if _rc == 0 {
    di "Triple interaction (desert): " %7.4f _b[closure_x_fintech_x_desert] " (SE = " %6.4f _se[closure_x_fintech_x_desert] ")"
}
else {
    di "Banking desert analysis: insufficient variation"
}

********************************************************************************
* PART 5: Closure Intensity - Last Branch vs One of Several
********************************************************************************

di ""
di "=== CLOSURE INTENSITY ANALYSIS ==="
di "Is losing the last branch more damaging?"

* Create indicator for severe closure (lost most branches)
gen severe_closure = (closure_zip > 0.5) if closure_zip != .
tab severe_closure, m

* Interaction
gen severe_x_fintech = severe_closure * fintech_share

cap reghdfe anytoise severe_closure fintech_share severe_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Severe closure × fintech: " %7.4f _b[severe_x_fintech] " (SE = " %6.4f _se[severe_x_fintech] ")"
}

********************************************************************************
* PART 6: Summary
********************************************************************************

di ""
di "=== DOSE-RESPONSE SUMMARY ==="
di ""
di "If the triple interaction (closure × fintech × low_branch) is positive,"
di "fintech mitigation is STRONGEST where banking access is WORST."
di ""
di "This is the most compelling evidence for the story:"
di "Fintech fills the gap where traditional banking has retreated."
di ""
di "Power concern: With N ≈ 484 and triple interactions, we may lack"
di "power to detect even large effects. Null results are inconclusive."

log close
