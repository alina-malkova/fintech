********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Regression Analysis - Does fintech/alternative data mitigate 
*          effects of limited banking access?
* Author:  Alina Malkova
* Date:    February 2026
********************************************************************************

clear all
set more off
set maxvar 32000
cap log close

* Set paths
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

cap mkdir "$results"

log using "$dofiles/06_regression_analysis.log", replace

********************************************************************************
* LOAD DATA
********************************************************************************

di "==========================================="
di "Loading Merged CAPS + Geographic Data"
di "==========================================="

use "$data/caps_geographic_merged.dta", clear

di "Observations: " _N
di "Years: 2003-2014"

********************************************************************************
* VARIABLE SETUP
********************************************************************************

di ""
di "==========================================="
di "Setting Up Variables"
di "==========================================="

* Outcome variables (from published paper)
* anytoise = switched to incorporated self-employment
* anytouse = switched to unincorporated self-employment

* Treatment: closure_zip (bank branch closures at ZIP level)

* Create interaction terms
gen closure_x_fintech = closure_zip * fintech_share
label var closure_x_fintech "Closure × Fintech Share"

gen closure_x_banking_desert = closure_zip * banking_desert
label var closure_x_banking_desert "Closure × Banking Desert"

gen closure_x_branches = closure_zip * branches_per_10k
label var closure_x_branches "Closure × Branch Density"

gen closure_x_econ_connect = closure_zip * economic_connectedness
label var closure_x_econ_connect "Closure × Economic Connectedness"

gen closure_x_broadband = closure_zip * pct_broadband
label var closure_x_broadband "Closure × Broadband Access"

* Standardize key variables for comparability
foreach var in fintech_share branches_per_10k economic_connectedness pct_broadband {
    cap drop `var'_z
    egen `var'_z = std(`var')
    label var `var'_z "`var' (standardized)"
}

* Create standardized interactions
gen closure_x_fintech_z = closure_zip * fintech_share_z
gen closure_x_branches_z = closure_zip * branches_per_10k_z
gen closure_x_econ_connect_z = closure_zip * economic_connectedness_z
gen closure_x_broadband_z = closure_zip * pct_broadband_z

********************************************************************************
* TABLE 1: SUMMARY STATISTICS
********************************************************************************

di ""
di "==========================================="
di "TABLE 1: Summary Statistics"
di "==========================================="

* Panel A: Main variables
di "Panel A: Main Variables"
sum anytoise anytouse closure_zip treat_zip

* Panel B: Geographic data
di ""
di "Panel B: Geographic Alternative Data"
sum fintech_share branches_per_10k banking_desert economic_connectedness ///
    pct_broadband food_desert_share dollar_stores_per_10k

* Panel C: By banking desert status
di ""
di "Panel C: By Banking Desert Status"
bysort banking_desert: sum anytoise anytouse closure_zip fintech_share

********************************************************************************
* TABLE 2: MAIN RESULTS - BANKING ACCESS AND SELF-EMPLOYMENT
********************************************************************************

di ""
di "==========================================="
di "TABLE 2: Banking Access and Self-Employment"
di "==========================================="

* Column 1: Baseline - Branch closure effect
di "Column 1: Baseline"
reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
est store t2_c1
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 2: Add branch density
di "Column 2: Add Branch Density"
reghdfe anytoise closure_zip branches_per_10k, absorb(mergerID year) cluster(county_fips)
est store t2_c2
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 3: Branch density interaction
di "Column 3: Branch Density Interaction"
reghdfe anytoise closure_zip branches_per_10k closure_x_branches, absorb(mergerID year) cluster(county_fips)
est store t2_c3
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 4: Banking desert indicator
di "Column 4: Banking Desert Indicator"
reghdfe anytoise closure_zip banking_desert closure_x_banking_desert, absorb(mergerID year) cluster(county_fips)
est store t2_c4
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Display Table 2
esttab t2_c1 t2_c2 t2_c3 t2_c4, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip branches_per_10k closure_x_branches banking_desert closure_x_banking_desert) ///
    mtitles("Baseline" "+Branches" "+Interaction" "Banking Desert") ///
    scalars("fe_ind Individual FE" "fe_year Year FE") ///
    title("Table 2: Banking Access and Incorporated Self-Employment")

********************************************************************************
* TABLE 3: FINTECH AND SELF-EMPLOYMENT (2010-2017 only)
********************************************************************************

di ""
di "==========================================="
di "TABLE 3: Fintech Penetration (2010-2017)"
di "==========================================="

preserve
keep if year >= 2010 & year <= 2017
di "Observations in fintech sample (2010-2017): " _N

* Column 1: Fintech share
di "Column 1: Fintech Share"
reghdfe anytoise closure_zip fintech_share, absorb(mergerID year) cluster(county_fips)
est store t3_c1
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 2: Fintech interaction
di "Column 2: Fintech Interaction"
reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
est store t3_c2
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 3: Add branch density
di "Column 3: Add Branch Density"
reghdfe anytoise closure_zip fintech_share closure_x_fintech branches_per_10k, absorb(mergerID year) cluster(county_fips)
est store t3_c3
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Display Table 3
esttab t3_c1 t3_c2 t3_c3, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip fintech_share closure_x_fintech branches_per_10k) ///
    mtitles("Fintech" "+Interaction" "+Branches") ///
    scalars("fe_ind Individual FE" "fe_year Year FE") ///
    title("Table 3: Fintech Penetration and Self-Employment (2010-2017)")

restore

********************************************************************************
* TABLE 4: SOCIAL CAPITAL AND ALTERNATIVE DATA
********************************************************************************

di ""
di "==========================================="
di "TABLE 4: Social Capital and Alternative Data"
di "==========================================="

* Column 1: Economic connectedness (Facebook)
di "Column 1: Economic Connectedness"
reghdfe anytoise closure_zip economic_connectedness closure_x_econ_connect, absorb(mergerID year) cluster(county_fips)
est store t4_c1
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 2: Broadband access
di "Column 2: Broadband Access"
reghdfe anytoise closure_zip pct_broadband closure_x_broadband, absorb(mergerID year) cluster(county_fips)
est store t4_c2
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Column 3: Combined - social capital + broadband
di "Column 3: Combined Model"
reghdfe anytoise closure_zip economic_connectedness closure_x_econ_connect ///
    pct_broadband closure_x_broadband, absorb(mergerID year) cluster(county_fips)
est store t4_c3
estadd local fe_ind "Yes"
estadd local fe_year "Yes"

* Display Table 4
esttab t4_c1 t4_c2 t4_c3, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip economic_connectedness closure_x_econ_connect pct_broadband closure_x_broadband) ///
    mtitles("Econ Connect" "Broadband" "Combined") ///
    scalars("fe_ind Individual FE" "fe_year Year FE") ///
    title("Table 4: Social Capital and Digital Access")

********************************************************************************
* TABLE 5: UNINCORPORATED SELF-EMPLOYMENT
********************************************************************************

di ""
di "==========================================="
di "TABLE 5: Unincorporated Self-Employment"
di "==========================================="

* Repeat key specs for unincorporated
di "Column 1: Baseline"
reghdfe anytouse closure_zip, absorb(mergerID year) cluster(county_fips)
est store t5_c1

di "Column 2: Branch density"
reghdfe anytouse closure_zip branches_per_10k closure_x_branches, absorb(mergerID year) cluster(county_fips)
est store t5_c2

di "Column 3: Economic connectedness"
reghdfe anytouse closure_zip economic_connectedness closure_x_econ_connect, absorb(mergerID year) cluster(county_fips)
est store t5_c3

* Display Table 5
esttab t5_c1 t5_c2 t5_c3, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip branches_per_10k closure_x_branches economic_connectedness closure_x_econ_connect) ///
    mtitles("Baseline" "Branches" "Social Capital") ///
    title("Table 5: Unincorporated Self-Employment")

********************************************************************************
* TABLE 6: STANDARDIZED COEFFICIENTS FOR COMPARISON
********************************************************************************

di ""
di "==========================================="
di "TABLE 6: Standardized Coefficients"
di "==========================================="

* Use standardized variables for comparable effect sizes
di "Standardized coefficients (all in SD units)"

reghdfe anytoise closure_zip branches_per_10k_z closure_x_branches_z ///
    economic_connectedness_z closure_x_econ_connect_z, ///
    absorb(mergerID year) cluster(county_fips)
est store t6_std

esttab t6_std, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip *_z) ///
    title("Table 6: Standardized Coefficients (Incorporated SE)")

********************************************************************************
* KEY RESULTS INTERPRETATION
********************************************************************************

di ""
di "==========================================="
di "KEY RESULTS INTERPRETATION"
di "==========================================="

di ""
di "Hypothesis: Areas with better alternative data/fintech access"
di "experience smaller negative effects from bank branch closures"
di ""
di "Key coefficients to examine:"
di "  1. closure_zip: Main effect of branch closure"
di "  2. closure_x_branches: Mitigation from branch density"
di "  3. closure_x_econ_connect: Mitigation from social capital"
di "  4. closure_x_fintech: Mitigation from fintech (2010-2017)"
di ""
di "If main effect is negative and interaction is positive:"
di "  → Alternative data/fintech mitigates harm from closures"
di ""

********************************************************************************
* SAVE RESULTS
********************************************************************************

* Export main tables to LaTeX
esttab t2_c1 t2_c2 t2_c3 t2_c4 using "$results/table2_banking_access.tex", replace ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip branches_per_10k closure_x_branches banking_desert closure_x_banking_desert) ///
    mtitles("Baseline" "+Branches" "+Interaction" "Banking Desert") ///
    title("Banking Access and Incorporated Self-Employment")

esttab t4_c1 t4_c2 t4_c3 using "$results/table4_social_capital.tex", replace ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip economic_connectedness closure_x_econ_connect pct_broadband closure_x_broadband) ///
    mtitles("Econ Connect" "Broadband" "Combined") ///
    title("Social Capital and Digital Access")

* Save estimates
estimates save "$results/regression_estimates.ster", replace

log close

di ""
di "==========================================="
di "Analysis Complete!"
di "==========================================="
di ""
di "Results saved to: $results/"
di "  - table2_banking_access.tex"
di "  - table4_social_capital.tex"
di "  - regression_estimates.ster"
di ""
di "Log file: $dofiles/06_regression_analysis.log"
