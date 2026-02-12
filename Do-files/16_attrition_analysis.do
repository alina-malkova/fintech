********************************************************************************
* Attrition and Sample Composition Analysis
* Check whether sign flip is driven by sample composition changes
********************************************************************************

clear all
set more off
cap log close
log using "attrition_analysis.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== ATTRITION AND SAMPLE COMPOSITION ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Full Data
********************************************************************************

use indivID year anytoise anytouse closure_zip mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear

di "Full sample: " _N " observations"

* Create period indicator
gen pre_period = (year >= 2003 & year <= 2009)
gen post_period = (year >= 2010 & year <= 2014)

********************************************************************************
* PART 2: Track Individual Presence in Each Period
********************************************************************************

di ""
di "=== INDIVIDUAL ATTRITION PATTERNS ==="

* Flag if individual ever appears in each period
bysort indivID: egen ever_pre = max(pre_period)
bysort indivID: egen ever_post = max(post_period)

* Create attrition categories
gen in_both = (ever_pre == 1 & ever_post == 1)
gen pre_only = (ever_pre == 1 & ever_post == 0)
gen post_only = (ever_pre == 0 & ever_post == 1)

* Count unique individuals
preserve
bysort indivID: keep if _n == 1

di ""
count if in_both == 1
di "Individuals in BOTH periods: " r(N)

count if pre_only == 1
di "Individuals in PRE-period only (attriters): " r(N)

count if post_only == 1
di "Individuals in POST-period only (new entrants): " r(N)

count
di "Total unique individuals: " r(N)

restore

********************************************************************************
* PART 3: Balance Table - Pre vs Post Period
********************************************************************************

di ""
di "=== BALANCE TABLE: PRE VS POST PERIOD ==="

di ""
di "--- Pre-Period (2003-2009) ---"
sum anytoise anytouse closure_zip if pre_period == 1 & anytoise != .

di ""
di "--- Post-Period (2010-2014) ---"
sum anytoise anytouse closure_zip if post_period == 1 & anytoise != .

* T-tests for differences
di ""
di "--- T-tests for Period Differences ---"
gen period = post_period
label define prd 0 "Pre" 1 "Post"
label values period prd

ttest anytoise, by(period)

********************************************************************************
* PART 4: Compare Attriters vs Stayers
********************************************************************************

di ""
di "=== COMPARING ATTRITERS VS STAYERS ==="
di "(Based on pre-period characteristics)"

* Use only pre-period observations
preserve
keep if pre_period == 1 & anytoise != .

di ""
di "--- Attriters (not observed in post-period) ---"
sum anytoise anytouse closure_zip if pre_only == 1

di ""
di "--- Stayers (observed in both periods) ---"
sum anytoise anytouse closure_zip if in_both == 1

* T-test: Are attriters different?
di ""
di "--- Selection Test: Attriters vs Stayers ---"
gen stayer = in_both
ttest anytoise, by(stayer)
ttest closure_zip, by(stayer)

restore

********************************************************************************
* PART 5: Closure Effect - Balanced Panel Check
********************************************************************************

di ""
di "=== CLOSURE EFFECT IN BALANCED PANEL ==="
di "(Same individuals observed in both periods)"

* Pre-period, full sample
di ""
di "--- Pre-Period: Full Sample ---"
cap reghdfe anytoise closure_zip if pre_period == 1, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Closure coefficient: " %7.4f _b[closure_zip] " (SE = " %6.4f _se[closure_zip] "), N = " e(N)
}

* Pre-period, balanced panel only
di ""
di "--- Pre-Period: Balanced Panel Only ---"
cap reghdfe anytoise closure_zip if pre_period == 1 & in_both == 1, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Closure coefficient: " %7.4f _b[closure_zip] " (SE = " %6.4f _se[closure_zip] "), N = " e(N)
}

* Post-period, full sample
di ""
di "--- Post-Period: Full Sample ---"
cap reghdfe anytoise closure_zip if post_period == 1, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Closure coefficient: " %7.4f _b[closure_zip] " (SE = " %6.4f _se[closure_zip] "), N = " e(N)
}

* Post-period, balanced panel only
di ""
di "--- Post-Period: Balanced Panel Only ---"
cap reghdfe anytoise closure_zip if post_period == 1 & in_both == 1, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    di "Closure coefficient: " %7.4f _b[closure_zip] " (SE = " %6.4f _se[closure_zip] "), N = " e(N)
}

********************************************************************************
* PART 6: Summary
********************************************************************************

di ""
di "=== ATTRITION SUMMARY ==="
di ""
di "Key finding: Does the sign flip persist in the balanced panel?"
di ""
di "If YES: Sign flip reflects genuine time variation (post-crisis conditions)"
di "If NO: Sign flip may be driven by who leaves/enters the sample"
di ""
di "Also check: Are attriters systematically different on observables?"
di "If attriters have different closure exposure, results may be biased."

log close
