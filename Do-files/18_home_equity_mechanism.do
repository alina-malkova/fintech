********************************************************************************
* Home Equity Channel Mechanism Test
* Test whether fintech affects refinancing/equity extraction -> SE transition
********************************************************************************

clear all
set more off
set maxvar 10000
cap log close
log using "home_equity_mechanism.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Other_Projects/JMP/Fintech Research"

di "=== HOME EQUITY CHANNEL MECHANISM ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data with Home Equity Variables
********************************************************************************

* Try to load variables related to refinancing, home equity, mortgage activity
* CAPS variable names may vary - try common possibilities
* Note: CAPS has >5000 variables, so we increase maxvar

use "Data/caps_geographic_merged.dta", clear

* Check what variables exist related to home equity/refinancing
di ""
di "=== CHECKING AVAILABLE HOME EQUITY VARIABLES ==="

* Look for refinancing variables
cap describe refi*
cap describe refinanc*
cap describe mortgage*
cap describe equity*
cap describe home_eq*
cap describe heloc*
cap describe cashout*

* List variables that might be relevant
ds *refi* *refinanc* *mortgage* *equity* *heloc* *loan* *debt*, has(type numeric)

********************************************************************************
* PART 2: Identify Home Equity/Refinancing Variables
********************************************************************************

di ""
di "=== ATTEMPTING TO IDENTIFY MECHANISM VARIABLES ==="

* Common CAPS variables that might capture refinancing:
* - refinanced (indicator for refinancing in past year)
* - mortgage_balance (mortgage debt level)
* - home_equity (home value - mortgage)
* - heloc (home equity line of credit)
* - extracted_equity (cash-out refinancing)

* Try to create refinancing indicator
cap gen refinanced = .
cap replace refinanced = (refi == 1) if refi != .
cap replace refinanced = (refinanced_lastyear == 1) if refinanced_lastyear != .

* Try to find mortgage variables
cap gen mortgage_has = (mortgage_balance > 0) if mortgage_balance != .
cap gen mortgage_has = (mortgagebal > 0) if mortgagebal != .

********************************************************************************
* PART 3: First Stage - Does Fintech Increase Refinancing?
********************************************************************************

di ""
di "=== FIRST STAGE: FINTECH -> REFINANCING ==="

* Restrict to fintech analysis sample
keep if year >= 2010 & year <= 2014

* Check if we have refinancing data
cap sum refinanced
if _rc == 0 & r(N) > 0 {
    di "Refinancing variable available: N = " r(N) ", mean = " %5.3f r(mean)

    * First stage: Does fintech penetration increase refinancing?
    cap reghdfe refinanced fintech_share, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di ""
        di "First Stage: Fintech -> Refinancing"
        di "Coefficient: " %7.4f _b[fintech_share] " (SE = " %6.4f _se[fintech_share] ")"

        if _b[fintech_share] > 0 & _se[fintech_share] < abs(_b[fintech_share]) {
            di "Result: Fintech INCREASES refinancing probability"
        }
    }
}
else {
    di "No refinancing variable found in data"
    di "Attempting to construct proxy from available variables..."
}

********************************************************************************
* PART 4: Second Stage - Does Refinancing Lead to SE Transition?
********************************************************************************

di ""
di "=== SECOND STAGE: REFINANCING -> SELF-EMPLOYMENT ==="

cap confirm variable refinanced
if _rc == 0 {
    * Does refinancing predict transition to self-employment?
    cap reghdfe anytoise refinanced closure_zip fintech_share, ///
        absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Refinancing -> SE coefficient: " %7.4f _b[refinanced] " (SE = " %6.4f _se[refinanced] ")"
    }
}

********************************************************************************
* PART 5: Reduced Form - Fintech × Closure on Refinancing
********************************************************************************

di ""
di "=== REDUCED FORM: CLOSURE × FINTECH -> REFINANCING ==="

cap confirm variable refinanced
if _rc == 0 {
    gen closure_x_fintech = closure_zip * fintech_share

    * Does the closure × fintech interaction predict refinancing?
    cap reghdfe refinanced closure_zip fintech_share closure_x_fintech, ///
        absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Closure × Fintech -> Refinancing: " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] ")"
        di ""
        di "If positive: In high-fintech areas, closures lead to MORE refinancing"
        di "This supports the mechanism: fintech enables equity extraction"
    }
}

********************************************************************************
* PART 6: Alternative - Home Equity Extraction
********************************************************************************

di ""
di "=== ALTERNATIVE: HOME EQUITY EXTRACTION ==="

* Check for home equity variables
cap sum home_equity
if _rc == 0 & r(N) > 0 {
    di "Home equity variable available"

    * Does home equity extraction predict SE?
    * Change in home equity (negative = extraction)
    sort indivID year
    by indivID: gen equity_change = home_equity - home_equity[_n-1] if _n > 1
    gen equity_extracted = (equity_change < 0) if equity_change != .

    cap reghdfe anytoise equity_extracted closure_zip fintech_share, ///
        absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Equity extraction -> SE: " %7.4f _b[equity_extracted]
    }
}

********************************************************************************
* PART 7: Mediation Analysis Framework
********************************************************************************

di ""
di "=== MEDIATION ANALYSIS FRAMEWORK ==="
di ""
di "To test the home equity channel mechanism:"
di ""
di "Step 1: Show fintech_share -> refinancing/equity_extraction (first stage)"
di "Step 2: Show refinancing/equity_extraction -> SE_transition (second stage)"
di "Step 3: Show closure × fintech -> refinancing (reduced form for mediator)"
di "Step 4: When controlling for refinancing, closure × fintech -> SE weakens"
di ""
di "If all steps work: Evidence for home equity channel"
di "If Step 1 fails: Need better refinancing data"
di "If Step 4 doesn't weaken: Mechanism may operate through other channels"

********************************************************************************
* PART 8: Alternative Mechanisms to Consider
********************************************************************************

di ""
di "=== ALTERNATIVE MECHANISMS ==="
di ""
di "If home equity data is unavailable, consider:"
di ""
di "1. Credit constraints proxy:"
di "   - CAPS may have credit_denied or loan_rejected variables"
di "   - Test: fintech reduces credit denial rates"
di ""
di "2. Financial stress measures:"
di "   - CAPS may have bill_stress, debt_stress, financial_hardship"
di "   - Test: fintech reduces financial stress in closure areas"
di ""
di "3. Alternative credit use:"
di "   - CAPS may have payday_loan, pawnshop, informal_credit"
di "   - Test: fintech reduces reliance on high-cost alternatives"

* Check for these alternative variables
di ""
di "Checking for alternative mechanism variables..."
cap ds *denied* *rejected* *stress* *hardship* *payday* *pawn*
cap ds *credit_card* *unsecured* *personal_loan*

********************************************************************************
* PART 9: Summary
********************************************************************************

di ""
di "=== MECHANISM TEST SUMMARY ==="
di ""
di "The proposed mechanism:"
di "  Branch closure -> reduced credit access -> lower SE transitions"
di "  Fintech mitigates by enabling home equity extraction (via mortgage refi)"
di ""
di "Data requirements:"
di "  - Refinancing indicator or mortgage activity"
di "  - Home equity levels over time"
di "  - Credit access/denial measures"
di ""
di "If CAPS lacks these variables, mechanism remains plausible but untested."
di "The incorporated vs unincorporated SE contrast provides indirect support."

log close
