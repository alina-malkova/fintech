********************************************************************************
* Randomization Inference and Specification Curve
* Address small-sample concerns (484 obs, 59 counties, 10 merger groups)
********************************************************************************

clear all
set more off
cap log close
log using "randomization_inference.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== RANDOMIZATION INFERENCE ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data
********************************************************************************

use indivID year anytoise closure_zip fintech_share mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear

keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
gen closure_x_fintech = closure_zip * fintech_share

di "Analysis sample: " _N " observations"

********************************************************************************
* PART 2: Actual Estimate
********************************************************************************

di ""
di "=== ACTUAL ESTIMATE ==="

reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
local actual_coef = _b[closure_x_fintech]
local actual_se = _se[closure_x_fintech]
local actual_t = `actual_coef' / `actual_se'

di "Actual coefficient: " %7.4f `actual_coef'
di "Actual SE: " %6.4f `actual_se'
di "Actual t-stat: " %6.3f `actual_t'

********************************************************************************
* PART 3: Randomization Inference - Permute Fintech Across Counties
********************************************************************************

di ""
di "=== RANDOMIZATION INFERENCE ==="
di "Permuting fintech_share across counties 1000 times"

* Save original data
preserve

* Get unique county-fintech pairs
keep county_fips fintech_share
duplicates drop
tempfile county_fintech
save `county_fintech'

restore

* Store permutation results
local nperms = 1000
matrix permcoefs = J(`nperms', 1, .)

* Set seed for reproducibility
set seed 12345

forvalues p = 1/`nperms' {
    quietly {
        preserve

        * Shuffle fintech across counties
        keep county_fips fintech_share
        duplicates drop
        gen random = runiform()
        sort random
        gen fintech_shuffled = fintech_share[_n]
        drop random fintech_share
        rename fintech_shuffled fintech_share

        tempfile shuffled
        save `shuffled'

        restore, preserve

        * Merge shuffled fintech
        drop fintech_share closure_x_fintech
        merge m:1 county_fips using `shuffled', keep(1 3) nogen
        gen closure_x_fintech = closure_zip * fintech_share

        * Run regression
        cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
        if _rc == 0 {
            matrix permcoefs[`p', 1] = _b[closure_x_fintech]
        }

        restore
    }

    if mod(`p', 100) == 0 {
        di "Completed " `p' " permutations"
    }
}

* Calculate p-value
svmat permcoefs, names(perm)
count if abs(perm1) >= abs(`actual_coef') & perm1 != .
local n_extreme = r(N)
local ri_pvalue = `n_extreme' / `nperms'

di ""
di "=== RANDOMIZATION INFERENCE RESULTS ==="
di "Actual coefficient: " %7.4f `actual_coef'
di "Permutations with |coef| >= |actual|: " `n_extreme' " of " `nperms'
di "Randomization inference p-value: " %5.3f `ri_pvalue'

if `ri_pvalue' < 0.05 {
    di "Result: SIGNIFICANT at 5% level under randomization inference"
}
else if `ri_pvalue' < 0.10 {
    di "Result: SIGNIFICANT at 10% level under randomization inference"
}
else {
    di "Result: NOT significant under randomization inference"
}

* Distribution summary
sum perm1, d
di ""
di "Permutation distribution:"
di "  Mean: " %7.4f r(mean)
di "  SD: " %6.4f r(sd)
di "  Min: " %7.4f r(min)
di "  Max: " %7.4f r(max)

drop perm1

********************************************************************************
* PART 4: Specification Curve
********************************************************************************

di ""
di "=== SPECIFICATION CURVE ==="
di "Estimating interaction coefficient across all reasonable specifications"

* Reload data
use indivID year anytoise closure_zip fintech_share mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
gen closure_x_fintech = closure_zip * fintech_share

* Merge additional controls
merge m:1 county_fips using "Data/Banking_Deserts/banking_access_county.dta", ///
    keepusing(branches_per_10k) keep(1 3) nogen

* Matrix to store results
matrix specs = J(20, 4, .)  // coef, se, N, spec_id
local spec = 0

di ""
di "Specification | Coef | SE | N | Description"
di "-------------|------|-----|---|------------"

* Spec 1: Baseline
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | Baseline"
}

* Spec 2: No FE
local spec = `spec' + 1
cap reg anytoise closure_zip fintech_share closure_x_fintech, cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | No FE"
}

* Spec 3: Year FE only
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(year) cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | Year FE only"
}

* Spec 4: MergerID FE only
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID) cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | MergerID FE only"
}

* Spec 5: + County FE
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year county_fips) cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | + County FE"
}

* Spec 6: Control for branch density
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech branches_per_10k, absorb(mergerID year) cluster(county_fips)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | + Branch density"
}

* Spec 7: Robust SE (not clustered)
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) vce(robust)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | Robust SE"
}

* Spec 8: Cluster by merger
local spec = `spec' + 1
cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(mergerID)
if _rc == 0 {
    matrix specs[`spec', 1] = _b[closure_x_fintech]
    matrix specs[`spec', 2] = _se[closure_x_fintech]
    matrix specs[`spec', 3] = e(N)
    matrix specs[`spec', 4] = `spec'
    di %2.0f `spec' " | " %6.3f _b[closure_x_fintech] " | " %5.3f _se[closure_x_fintech] " | " e(N) " | Cluster by merger"
}

* Summary
di ""
di "=== SPECIFICATION CURVE SUMMARY ==="
svmat specs, names(s)
sum s1 if s1 != ., d
di "Coefficient range: " %6.3f r(min) " to " %6.3f r(max)
di "Median coefficient: " %6.3f r(p50)
di "Mean coefficient: " %6.3f r(mean)

count if s1 > 0 & s1 != .
local n_positive = r(N)
count if s1 != .
local n_total = r(N)
di "Positive coefficients: " `n_positive' " of " `n_total' " specifications"

********************************************************************************
* PART 5: Summary
********************************************************************************

di ""
di "=== INFERENCE SUMMARY ==="
di ""
di "1. Randomization inference p-value: " %5.3f `ri_pvalue'
di "   (More credible than clustered SE with 59 counties)"
di ""
di "2. Specification curve: coefficient positive in " `n_positive' "/" `n_total' " specs"
di "   (Shows robustness to modeling choices)"
di ""
di "With small samples, randomization inference provides more reliable"
di "p-values than asymptotic theory underlying clustered SE."

log close
