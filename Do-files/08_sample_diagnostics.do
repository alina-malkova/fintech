********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Sample Diagnostics - Addressing Reviewer Concerns
* Author:  Alina Malkova
* Date:    February 2026
*
* CONCERNS ADDRESSED:
* 1. Sample size drop from N=1,449 to N=484
* 2. Sign flip in closure coefficient across tables
* 3. Unique individuals/counties in fintech sample
* 4. Number experiencing closures in 2010-2017
********************************************************************************

clear all
set more off
set maxvar 32000
cap log close

global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

log using "$dofiles/08_sample_diagnostics.log", replace

********************************************************************************
* LOAD DATA
********************************************************************************

use "$data/caps_geographic_merged.dta", clear

* Recreate key variables
gen closure_x_fintech = closure_zip * fintech_share

********************************************************************************
* SECTION 1: EXPLAIN SAMPLE SIZE DROP
********************************************************************************

di ""
di "==========================================="
di "SECTION 1: Sample Size Diagnostics"
di "==========================================="

* Full sample
di "Full CAPS sample: " _N

* Count by year
di ""
di "Observations by year:"
tab year

* How many have non-missing outcome?
di ""
di "Non-missing anytoise: "
count if anytoise != .

* How many have non-missing treatment?
di ""
di "Non-missing closure_zip:"
count if closure_zip != .

* How many have non-missing fintech?
di ""
di "Non-missing fintech_share:"
count if fintech_share != .

* Breakdown of fintech availability
di ""
di "Fintech availability by year:"
tab year if fintech_share != ., missing

* Key insight: fintech data only available 2010-2017
di ""
di "Why N drops from ~1,449 to ~484:"
di "1. Table 2 uses mergerID FE which drops most observations"
di "2. Table 3 further restricts to 2010-2017 (fintech data period)"

* Show the actual sample construction
di ""
di "Step-by-step sample construction:"

* Step 1: Full sample
di "Step 1 - Full sample: " _N

* Step 2: Non-missing outcome
count if anytoise != .
di "Step 2 - Non-missing anytoise: " r(N)

* Step 3: Non-missing closure
count if anytoise != . & closure_zip != .
di "Step 3 - Non-missing closure_zip: " r(N)

* Step 4: Restrict to 2010-2017
count if anytoise != . & closure_zip != . & year >= 2010 & year <= 2017
di "Step 4 - Restrict to 2010-2017: " r(N)

* Step 5: Non-missing fintech
count if anytoise != . & closure_zip != . & year >= 2010 & year <= 2017 & fintech_share != .
di "Step 5 - Non-missing fintech_share: " r(N)

* Step 6: After FE estimation (singletons dropped)
di "Step 6 - After mergerID FE (singletons): ~484 (see reghdfe output)"

********************************************************************************
* SECTION 2: UNIQUE INDIVIDUALS AND COUNTIES
********************************************************************************

di ""
di "==========================================="
di "SECTION 2: Sample Composition (2010-2017)"
di "==========================================="

preserve
keep if year >= 2010 & year <= 2017 & fintech_share != . & anytoise != .

di "Fintech sample (2010-2017 with non-missing data):"
di "Total observations: " _N

* Unique individuals
codebook indivID, compact
di ""

* Unique counties
codebook county_fips, compact
di ""

* Unique mergerIDs (treatment groups)
codebook mergerID, compact
di ""

* How many experience closures?
di ""
di "Closure exposure in fintech sample:"
sum closure_zip
di ""
di "Observations with any closure (closure_zip < 0):"
count if closure_zip < 0
di "Observations with closure: " r(N)
di ""
di "Observations in treated ZIPs (treat_zip == 1):"
count if treat_zip == 1
di "Treated observations: " r(N)

* Distribution of closures
di ""
di "Distribution of closure_zip:"
tab closure_zip if closure_zip != 0, missing

restore

********************************************************************************
* SECTION 3: YEAR-BY-YEAR CLOSURE EFFECTS
********************************************************************************

di ""
di "==========================================="
di "SECTION 3: Year-by-Year Closure Effects"
di "==========================================="
di "Testing whether sign flip is driven by time period"

* Create year dummies for closure
forvalues y = 2003/2014 {
    gen closure_`y' = closure_zip * (year == `y')
}

* Year-by-year effects (without fintech)
di ""
di "Closure effect by year (no fintech controls):"
reghdfe anytoise closure_2003-closure_2014, absorb(mergerID) cluster(county_fips)

* Store coefficients
matrix coef_year = e(b)
di ""
di "Year-by-year coefficients:"
matrix list coef_year

* Alternative: Run separate regressions by period
di ""
di "=== Pre-fintech period (2003-2009) ==="
preserve
keep if year >= 2003 & year <= 2009
reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
restore

di ""
di "=== Fintech period (2010-2014) ==="
preserve
keep if year >= 2010 & year <= 2014
reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
restore

di ""
di "=== With vs without fintech controls (2010-2014) ==="
preserve
keep if year >= 2010 & year <= 2014 & fintech_share != .

di "Without fintech:"
reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
est store no_fintech

di ""
di "With fintech (main effect only):"
reghdfe anytoise closure_zip fintech_share, absorb(mergerID year) cluster(county_fips)
est store with_fintech

di ""
di "With fintech interaction:"
reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
est store with_interaction

esttab no_fintech with_fintech with_interaction, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("No Fintech" "+Fintech" "+Interaction") ///
    title("Closure Effect: With vs Without Fintech Controls")

restore

********************************************************************************
* SECTION 4: HORSE-RACE SPECIFICATION
********************************************************************************

di ""
di "==========================================="
di "SECTION 4: Horse-Race Specification"
di "==========================================="
di "All interactions in same regression"

preserve
keep if year >= 2010 & year <= 2017

* Create all interaction terms
cap drop closure_x_fintech
cap drop closure_x_broadband
cap drop closure_x_econ_connect

gen closure_x_fintech = closure_zip * fintech_share
gen closure_x_broadband = closure_zip * pct_broadband
gen closure_x_econ_connect = closure_zip * economic_connectedness

* Horse-race: all interactions together
di "Horse-race specification (all interactions simultaneous):"
reghdfe anytoise closure_zip ///
    fintech_share closure_x_fintech ///
    pct_broadband closure_x_broadband ///
    economic_connectedness closure_x_econ_connect, ///
    absorb(mergerID year) cluster(county_fips)
est store horse_race

esttab horse_race, ///
    b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(closure_zip *fintech* *broadband* *econ_connect*) ///
    title("Horse-Race: Fintech vs Broadband vs Social Capital")

restore

********************************************************************************
* SECTION 5: PRECISE MITIGATION CALCULATION
********************************************************************************

di ""
di "==========================================="
di "SECTION 5: Precise Mitigation Calculation"
di "==========================================="

preserve
keep if year >= 2010 & year <= 2017 & fintech_share != .

* Get coefficients from main spec
reghdfe anytoise closure_zip fintech_share closure_x_fintech, ///
    absorb(mergerID year) cluster(county_fips)

local beta_closure = _b[closure_zip]
local beta_interaction = _b[closure_x_fintech]

* Get fintech stats
sum fintech_share
local mean_fintech = r(mean)
local sd_fintech = r(sd)

di ""
di "Coefficient estimates:"
di "  Beta(closure) = " %6.4f `beta_closure'
di "  Beta(closure x fintech) = " %6.4f `beta_interaction'
di ""
di "Fintech share statistics:"
di "  Mean = " %6.4f `mean_fintech'
di "  SD = " %6.4f `sd_fintech'
di ""
di "Net closure effect at different fintech levels:"

* At mean fintech
local effect_mean = `beta_closure' + `beta_interaction' * `mean_fintech'
di "  At mean fintech (" %5.3f `mean_fintech' "): " %6.4f `effect_mean'

* At mean + 1 SD
local effect_plus1sd = `beta_closure' + `beta_interaction' * (`mean_fintech' + `sd_fintech')
di "  At mean + 1 SD (" %5.3f (`mean_fintech' + `sd_fintech') "): " %6.4f `effect_plus1sd'

* Mitigation calculation
local mitigation_1sd = 1 - (`effect_plus1sd' / `effect_mean')
di ""
di "MITIGATION CALCULATION:"
di "  Effect at mean fintech: " %6.4f `effect_mean'
di "  Effect at mean + 1 SD: " %6.4f `effect_plus1sd'
di "  Reduction from 1 SD increase: " %5.1f (100 * `mitigation_1sd') "%"

* Alternative: What fintech level fully offsets?
local fintech_offset = -`beta_closure' / `beta_interaction'
di ""
di "Fintech level that fully offsets closure effect: " %5.3f `fintech_offset'
di "  (Compare to mean = " %5.3f `mean_fintech' ", max = " %5.3f r(max) ")"

restore

********************************************************************************
* SECTION 6: FIX TABLE 2 COLUMN 4 (BANKING DESERT)
********************************************************************************

di ""
di "==========================================="
di "SECTION 6: Banking Desert Specification"
di "==========================================="

* The issue: banking_desert was collinear with FE
* Need to check why

preserve
* Full sample for Table 2
di "Checking banking desert variation:"
tab banking_desert, missing

* Check within mergerID variation
bysort mergerID: egen bd_sd = sd(banking_desert)
sum bd_sd
di ""
di "Within-mergerID std dev of banking_desert:"
di "  Mean = " r(mean)
di "  Most groups have zero within-group variation"
di "  This is why banking_desert is collinear with mergerID FE"

* Alternative: Use county-level regression without individual FE
di ""
di "Alternative: County-level analysis"
collapse (mean) anytoise closure_zip banking_desert fintech_share, by(county_fips year)

gen closure_x_desert = closure_zip * banking_desert

reghdfe anytoise closure_zip banking_desert closure_x_desert, ///
    absorb(year) cluster(county_fips)

restore

log close

di ""
di "==========================================="
di "Diagnostics Complete"
di "==========================================="
di "Log saved to: $dofiles/08_sample_diagnostics.log"
