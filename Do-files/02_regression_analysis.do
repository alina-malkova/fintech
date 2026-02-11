********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Regression analysis - Does fintech mitigate branch closure effects?
* Author:  Alina Malkova
* Date:    February 2026
********************************************************************************

clear all
set more off
cap log close

* Set paths
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

* Start log
log using "$dofiles/02_regression_analysis.log", replace

* Load merged dataset
use "$data/caps_fintech_merged.dta", clear

********************************************************************************
* SETUP: Define Variables
********************************************************************************

* -------------------------
* MODIFY THESE TO MATCH YOUR CAPS DATA:
* -------------------------

* Outcome variable (from your published paper)
* Options: self_employed, incorporated, unincorporated, business_owner
global outcome "incorporated"  // CHANGE THIS

* Individual ID
global id "id"  // CHANGE THIS if different

* Time variable
global time "year"

* Branch closure measure (from your published paper)
global branch "branch_closure"  // CHANGE THIS

* Control variables (from your published paper)
* Example: age, education, income, married, etc.
global controls "age age2 female black hispanic married college"  // CHANGE THIS

* Cluster variable
global cluster "county_fips"

********************************************************************************
* TABLE 1: Summary Statistics
********************************************************************************

* Panel A: Full sample
estpost sum $outcome $branch fintech_share $controls
est store sumstats

* Panel B: By fintech penetration
estpost tabstat $outcome $branch, by(high_fintech) stat(mean sd n) nototal
est store sumstats_fintech

********************************************************************************
* TABLE 2: Main Results - Does Fintech Mitigate Branch Closure Effects?
********************************************************************************

* Baseline specification (replicate published paper result)
reghdfe $outcome $branch $controls, absorb($id $time) cluster($cluster)
est store m1
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Add fintech share
reghdfe $outcome $branch fintech_share $controls, absorb($id $time) cluster($cluster)
est store m2
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Add interaction (KEY SPECIFICATION)
reghdfe $outcome $branch fintech_share branch_x_fintech $controls, absorb($id $time) cluster($cluster)
est store m3
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Export table
esttab m1 m2 m3 using "$results/table2_main_results.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($branch fintech_share branch_x_fintech) ///
    order($branch fintech_share branch_x_fintech) ///
    mtitles("Baseline" "+ Fintech" "+ Interaction") ///
    scalars("fe_ind Individual FE" "fe_year Year FE" "N Observations" "r2_within R-squared") ///
    title("Effect of Branch Closures on Self-Employment: Role of Fintech") ///
    note("Standard errors clustered at county level in parentheses.")

* Display results
esttab m1 m2 m3, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep($branch fintech_share branch_x_fintech) ///
    mtitles("Baseline" "+ Fintech" "+ Interaction")

********************************************************************************
* TABLE 3: Heterogeneity by Fintech Quartile
********************************************************************************

* Generate quartile interactions
forval q = 1/4 {
    gen branch_Q`q' = $branch * (fintech_quartile == `q')
}

* Regression with quartile interactions
reghdfe $outcome branch_Q1 branch_Q2 branch_Q3 branch_Q4 $controls, ///
    absorb($id $time) cluster($cluster)
est store m_quartile

* Test: Q4 effect different from Q1?
test branch_Q4 = branch_Q1

* Display
esttab m_quartile, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(branch_Q*) ///
    title("Branch Closure Effects by Fintech Quartile")

********************************************************************************
* TABLE 4: Robustness - Alternative Specifications
********************************************************************************

* (1) County-year fixed effects instead of year FE
reghdfe $outcome $branch fintech_share branch_x_fintech $controls, ///
    absorb($id county_fips#$time) cluster($cluster)
est store r1

* (2) Standardized fintech measure
gen branch_x_fintech_std = $branch * fintech_share_std
reghdfe $outcome $branch fintech_share_std branch_x_fintech_std $controls, ///
    absorb($id $time) cluster($cluster)
est store r2

* (3) Log fintech share
gen branch_x_ln_fintech = $branch * ln_fintech_share
reghdfe $outcome $branch ln_fintech_share branch_x_ln_fintech $controls, ///
    absorb($id $time) cluster($cluster)
est store r3

* Export robustness table
esttab r1 r2 r3 using "$results/table4_robustness.tex", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("County×Year FE" "Standardized" "Log Fintech") ///
    title("Robustness Checks")

********************************************************************************
* FIGURE 1: Event Study / Dynamic Effects (if applicable)
********************************************************************************

* If you have event-time relative to branch closure, uncomment:
/*
* Generate event-time dummies interacted with fintech
forval t = -3/3 {
    if `t' < 0 {
        local tname = "m" + string(abs(`t'))
    }
    else if `t' == 0 {
        local tname = "0"
    }
    else {
        local tname = "p" + string(`t')
    }
    gen event_`tname' = (event_time == `t')
    gen event_`tname'_fintech = event_`tname' * fintech_share
}

* Event study regression
reghdfe $outcome event_m3-event_p3 event_m3_fintech-event_p3_fintech $controls, ///
    absorb($id $time) cluster($cluster) omit(event_m1 event_m1_fintech)

* Plot coefficients
coefplot, keep(event_*) vertical yline(0)
graph export "$results/figure1_event_study.pdf", replace
*/

********************************************************************************
* KEY INTERPRETATION
********************************************************************************

di ""
di "=============================================="
di "KEY RESULTS INTERPRETATION"
di "=============================================="
di ""
di "Hypothesis: Fintech mitigates negative effects of branch closures"
di ""
di "In the interaction model (m3):"
di "  - Coefficient on branch_closure (β1): Effect when fintech_share = 0"
di "  - Coefficient on branch_x_fintech (β3): Mitigation effect"
di ""
di "If β1 < 0 and β3 > 0:"
di "  → Branch closures hurt self-employment, but fintech reduces the harm"
di ""
di "Marginal effect at different fintech levels:"
di "  At fintech_share = 0.01: β1 + 0.01*β3"
di "  At fintech_share = 0.05: β1 + 0.05*β3"
di "  At fintech_share = 0.10: β1 + 0.10*β3"
di ""

* Calculate marginal effects at different fintech levels
qui reghdfe $outcome $branch fintech_share branch_x_fintech $controls, absorb($id $time) cluster($cluster)
local b1 = _b[$branch]
local b3 = _b[branch_x_fintech]

di "Based on estimates:"
di "  Marginal effect at fintech = 1%:  " %6.4f `b1' + 0.01*`b3'
di "  Marginal effect at fintech = 5%:  " %6.4f `b1' + 0.05*`b3'
di "  Marginal effect at fintech = 10%: " %6.4f `b1' + 0.10*`b3'

********************************************************************************
* Save estimates for later use
********************************************************************************

estimates save "$results/regression_estimates.ster", replace

log close

di ""
di "=== Analysis Complete ==="
di "Results saved to: $results/"

********************************************************************************
* END OF FILE
********************************************************************************
