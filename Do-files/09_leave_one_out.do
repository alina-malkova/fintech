********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Leave-One-Out Analysis by Merger Group
********************************************************************************

clear all
set more off
set maxvar 32000
cap log close

global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global dofiles "$root/Do-files"

log using "$dofiles/09_leave_one_out.log", replace

di "=== STARTING LEAVE-ONE-OUT ANALYSIS ==="
di "Time: " c(current_time)

use "$data/caps_geographic_merged.dta", clear
di "Loaded " _N " observations"

keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
di "Analysis sample: " _N " observations"

gen closure_x_fintech = closure_zip * fintech_share

di ""
di "=== BASELINE REGRESSION ==="
reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
local baseline = _b[closure_x_fintech]
local baseline_se = _se[closure_x_fintech]

di ""
di "Baseline coefficient: " %7.4f `baseline'
di "Baseline SE: " %6.4f `baseline_se'

di ""
di "=== LEAVE-ONE-OUT BY MERGER GROUP ==="
levelsof mergerID, local(mlist)

foreach m of local mlist {
    preserve
    quietly drop if mergerID == `m'
    local n_obs = _N
    capture noisily reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Drop mergerID=`m': coef=" %7.4f _b[closure_x_fintech] " SE=" %6.4f _se[closure_x_fintech] " N=" e(N)
    }
    else {
        di "Drop mergerID=`m': FAILED (N=`n_obs')"
    }
    restore
}

di ""
di "=== ANALYSIS COMPLETE ==="

log close
