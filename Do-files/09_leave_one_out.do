********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Leave-One-Out Analysis by Merger Group
* Author:  Alina Malkova
* Date:    February 2026
*
* Tests whether fintech interaction results are driven by specific merger groups
********************************************************************************

clear all
set more off
cap log close

global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

cd "$root"
log using "09_leave_one_out.log", replace

********************************************************************************
* LOAD DATA
********************************************************************************

use "$data/caps_geographic_merged.dta", clear

* Restrict to fintech period
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .

* Recreate interaction
gen closure_x_fintech = closure_zip * fintech_share

********************************************************************************
* BASELINE RESULT (ALL MERGER GROUPS)
********************************************************************************

di ""
di "==========================================="
di "BASELINE: All Merger Groups"
di "==========================================="

reghdfe anytoise closure_zip fintech_share closure_x_fintech, ///
    absorb(mergerID year) cluster(county_fips)

local baseline_coef = _b[closure_x_fintech]
local baseline_se = _se[closure_x_fintech]
local baseline_N = e(N)

di ""
di "Baseline interaction coefficient: " %6.4f `baseline_coef'
di "Baseline SE: " %6.4f `baseline_se'
di "Baseline N: " `baseline_N'

********************************************************************************
* LEAVE-ONE-OUT ANALYSIS
********************************************************************************

di ""
di "==========================================="
di "LEAVE-ONE-OUT BY MERGER GROUP"
di "==========================================="

* Get list of merger groups
levelsof mergerID, local(mergers)
local n_mergers : word count `mergers'
di "Number of merger groups: `n_mergers'"

* Store results
tempfile results
postfile handle mergerID_dropped N coef se pval using `results', replace

foreach m of local mergers {
    preserve

    * Drop one merger group
    drop if mergerID == `m'

    * Run regression
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, ///
        absorb(mergerID year) cluster(county_fips)

    if _rc == 0 {
        local coef = _b[closure_x_fintech]
        local se = _se[closure_x_fintech]
        local t = `coef' / `se'
        local pval = 2 * ttail(e(df_r), abs(`t'))
        local N = e(N)

        di "Dropping mergerID = `m': coef = " %6.4f `coef' " (SE = " %6.4f `se' "), N = " `N'

        post handle (`m') (`N') (`coef') (`se') (`pval')
    }
    else {
        di "Dropping mergerID = `m': regression failed (likely too few observations)"
        post handle (`m') (.) (.) (.) (.)
    }

    restore
}

postclose handle

********************************************************************************
* SUMMARIZE RESULTS
********************************************************************************

di ""
di "==========================================="
di "LEAVE-ONE-OUT SUMMARY"
di "==========================================="

use `results', clear

* Summary statistics
di ""
di "Coefficient range across leave-one-out samples:"
sum coef
local min_coef = r(min)
local max_coef = r(max)
local mean_coef = r(mean)

di ""
di "Baseline coefficient: " %6.4f `baseline_coef'
di "Mean leave-one-out coefficient: " %6.4f `mean_coef'
di "Min leave-one-out coefficient: " %6.4f `min_coef'
di "Max leave-one-out coefficient: " %6.4f `max_coef'

* How many remain significant at p < 0.10?
count if pval < 0.10
local n_sig = r(N)
di ""
di "Specifications with p < 0.10: `n_sig' out of `n_mergers'"

count if pval < 0.05
local n_sig05 = r(N)
di "Specifications with p < 0.05: `n_sig05' out of `n_mergers'"

* List results
di ""
di "Full results by dropped merger group:"
list mergerID_dropped N coef se pval, sep(0)

* Check for influential merger groups
gen coef_change = abs(coef - `baseline_coef')
sort coef_change
di ""
di "Most influential merger groups (largest coefficient change when dropped):"
list mergerID_dropped coef coef_change if _n <= 3

********************************************************************************
* EXPORT RESULTS
********************************************************************************

export delimited using "$results/leave_one_out_results.csv", replace

log close

di ""
di "==========================================="
di "Leave-One-Out Analysis Complete"
di "==========================================="
di "Results saved to: $results/leave_one_out_results.csv"
