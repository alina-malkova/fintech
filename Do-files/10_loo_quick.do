********************************************************************************
* Quick Leave-One-Out Analysis
* Uses subset of data to speed up analysis
********************************************************************************

clear all
set more off
cap log close

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
log using "loo_results.log", replace text

di "=== LOADING DATA ==="
di "Start: " c(current_time)

* Load only needed variables to speed up
use indivID year anytoise closure_zip fintech_share mergerID county_fips using "Data/caps_geographic_merged.dta", clear
di "Loaded " _N " obs at " c(current_time)

* Restrict sample
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
di "Analysis sample: " _N " observations"

* Create interaction
gen closure_x_fintech = closure_zip * fintech_share

di ""
di "=== BASELINE ==="
reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
local baseline = _b[closure_x_fintech]
local baseline_se = _se[closure_x_fintech]
di "Baseline: coef = " %7.4f `baseline' ", SE = " %6.4f `baseline_se'

di ""
di "=== LEAVE-ONE-OUT ==="
levelsof mergerID, local(mlist)
di "Merger groups: `mlist'"

foreach m of local mlist {
    preserve
    qui drop if mergerID == `m'
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Drop `m': coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    else {
        di "Drop `m': FAILED"
    }
    restore
}

di ""
di "=== COMPLETE ==="
di "End: " c(current_time)
log close
