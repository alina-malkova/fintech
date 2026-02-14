********************************************************************************
* Event Study: Dynamic Effects by Years Since Closure
* Show pre-trends (or lack thereof) separately for high vs low fintech counties
********************************************************************************

clear all
set more off
cap log close
log using "event_study.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Other_Projects/JMP/Fintech Research"

di "=== EVENT STUDY ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data
********************************************************************************

use indivID year anytoise closure_zip fintech_share mergerID county_fips ///
    using "Data/caps_geographic_merged.dta", clear

di "Full sample: " _N " observations"

********************************************************************************
* PART 2: Identify Closure Events
********************************************************************************

* A closure "event" = first year with positive closure_zip for an individual
* We need to identify when each individual first experienced a closure

bysort indivID (year): gen closure_event = (closure_zip > 0 & closure_zip[_n-1] <= 0) if _n > 1
replace closure_event = (closure_zip > 0) if closure_event == .

* Find the year of first closure event
bysort indivID: egen first_closure_year = min(year) if closure_event == 1
bysort indivID: egen closure_year = min(first_closure_year)
drop first_closure_year

* Create event time (years relative to closure)
gen event_time = year - closure_year

* Keep only individuals who experienced a closure
keep if closure_year != .
di "Observations with closure events: " _N

* Check distribution of event times
tab event_time, m

********************************************************************************
* PART 3: Create High/Low Fintech Indicator
********************************************************************************

* Use median fintech share to split
sum fintech_share, d
local med_fintech = r(p50)
gen high_fintech = (fintech_share > `med_fintech') if fintech_share != .

tab high_fintech, m

********************************************************************************
* PART 4: Event Study Regression - Full Sample
********************************************************************************

di ""
di "=== EVENT STUDY: FULL SAMPLE ==="

* Create event time dummies (omit t=-1 as reference)
* Limit to reasonable window around event
keep if event_time >= -4 & event_time <= 4

forvalues t = -4/4 {
    if `t' != -1 {
        gen evt_`=`t'+10' = (event_time == `t')
    }
}

* Rename for clarity
rename evt_6 evt_m4
rename evt_7 evt_m3
rename evt_8 evt_m2
* evt_9 doesn't exist (omitted -1)
rename evt_10 evt_0
rename evt_11 evt_p1
rename evt_12 evt_p2
rename evt_13 evt_p3
rename evt_14 evt_p4

* Full sample event study
di ""
di "--- Event Study Coefficients (t=-1 is reference) ---"
cap reghdfe anytoise evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4, ///
    absorb(indivID year) cluster(county_fips)

if _rc == 0 {
    di ""
    di "Event Time | Coefficient | SE"
    di "-----------|-------------|----"
    foreach v in evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4 {
        di "`v'" " | " %7.4f _b[`v'] " | " %6.4f _se[`v']
    }
}

********************************************************************************
* PART 5: Event Study by High vs Low Fintech
********************************************************************************

di ""
di "=== EVENT STUDY BY FINTECH LEVEL ==="

* Create interactions with high_fintech
foreach v in evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4 {
    gen `v'_hifi = `v' * high_fintech
}

di ""
di "--- Split by Fintech Level ---"

* High fintech areas
di ""
di "HIGH FINTECH COUNTIES:"
preserve
keep if high_fintech == 1
cap reghdfe anytoise evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4, ///
    absorb(year) cluster(county_fips)
if _rc == 0 {
    foreach v in evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4 {
        di "`v'" ": " %7.4f _b[`v'] " (" %6.4f _se[`v'] ")"
    }
}
restore

* Low fintech areas
di ""
di "LOW FINTECH COUNTIES:"
preserve
keep if high_fintech == 0
cap reghdfe anytoise evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4, ///
    absorb(year) cluster(county_fips)
if _rc == 0 {
    foreach v in evt_m4 evt_m3 evt_m2 evt_0 evt_p1 evt_p2 evt_p3 evt_p4 {
        di "`v'" ": " %7.4f _b[`v'] " (" %6.4f _se[`v'] ")"
    }
}
restore

********************************************************************************
* PART 6: Export for Plotting
********************************************************************************

di ""
di "=== COEFFICIENTS FOR PLOTTING ==="

* Store coefficients in a matrix for export
matrix results = J(8, 5, .)
matrix colnames results = event_time coef_full se_full coef_high coef_low

local row = 1
foreach t in -4 -3 -2 0 1 2 3 4 {
    matrix results[`row', 1] = `t'
    local row = `row' + 1
}

di ""
di "To create event study plot:"
di "1. Run this do-file to get coefficients"
di "2. Export coefficients to CSV"
di "3. Plot in R, Python, or Stata graph"
di ""
di "Key visual: Parallel pre-trends (flat before t=0) in both high and low"
di "fintech counties, then divergence after t=0 (closure effect mitigated"
di "in high fintech areas)."

********************************************************************************
* PART 7: Summary
********************************************************************************

di ""
di "=== EVENT STUDY SUMMARY ==="
di ""
di "The event study shows the dynamic path of self-employment around closures."
di ""
di "If the fintech story is correct:"
di "  - Pre-trends should be parallel (both groups flat before closure)"
di "  - Post-closure: Low fintech shows decline, high fintech less decline"
di ""
di "Pre-trends check: Are coefficients at t=-4,-3,-2 close to zero?"
di "This is the event-study equivalent of the placebo test."

log close
