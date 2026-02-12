********************************************************************************
* Heterogeneity Analysis
* Does fintech mitigation vary by borrower characteristics?
********************************************************************************

clear all
set more off
cap log close
log using "heterogeneity_analysis.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== HETEROGENEITY ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load Data with Demographic Variables
********************************************************************************

* Load key variables including demographics
use indivID year anytoise anytouse closure_zip fintech_share mergerID county_fips ///
    credit_score income age race education homeequity using ///
    "Data/caps_geographic_merged.dta", clear

* If variables don't exist, try alternative names
cap confirm variable credit_score
if _rc != 0 {
    cap rename creditscore credit_score
    cap rename fico credit_score
}

cap confirm variable income
if _rc != 0 {
    cap rename hhincome income
    cap rename totincome income
}

* Restrict to fintech analysis sample
keep if year >= 2010 & year <= 2014 & fintech_share != . & anytoise != .
di "Analysis sample: " _N " observations"

* Create interaction
gen closure_x_fintech = closure_zip * fintech_share

********************************************************************************
* PART 2: Create Heterogeneity Variables
********************************************************************************

di ""
di "=== CREATING SUBGROUPS ==="

* Credit score bins (if available)
cap {
    gen credit_low = (credit_score < 620) if credit_score != .
    gen credit_mid = (credit_score >= 620 & credit_score < 720) if credit_score != .
    gen credit_high = (credit_score >= 720) if credit_score != .
    di "Credit score bins created"
    tab credit_low credit_mid credit_high, m
}

* Income quartiles (if available)
cap {
    xtile income_quartile = income, nq(4)
    gen low_income = (income_quartile <= 2) if income_quartile != .
    di "Income quartiles created"
    tab income_quartile, m
}

* Age groups
cap {
    gen young = (age < 35) if age != .
    gen middle = (age >= 35 & age < 55) if age != .
    gen older = (age >= 55) if age != .
    di "Age groups created"
    tab young middle older, m
}

* Race (if available)
cap {
    gen minority = (race != 1) if race != .  // Assuming 1 = white
    di "Race indicator created"
    tab minority, m
}

* Education
cap {
    gen college = (education >= 4) if education != .  // Assuming 4+ = college
    di "Education indicator created"
    tab college, m
}

********************************************************************************
* PART 3: Baseline for Comparison
********************************************************************************

di ""
di "=== BASELINE REGRESSION ==="

reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
local base_coef = _b[closure_x_fintech]
local base_se = _se[closure_x_fintech]
di "Baseline interaction: " %7.4f `base_coef' " (SE = " %6.4f `base_se' ")"

********************************************************************************
* PART 4: Heterogeneity by Credit Score
********************************************************************************

di ""
di "=== HETEROGENEITY BY CREDIT SCORE ==="

cap {
    * Triple interaction: closure × fintech × credit_mid
    gen closure_x_fintech_x_credmid = closure_x_fintech * credit_mid
    gen closure_x_credmid = closure_zip * credit_mid
    gen fintech_x_credmid = fintech_share * credit_mid

    reghdfe anytoise closure_zip fintech_share closure_x_fintech ///
        credit_mid closure_x_credmid fintech_x_credmid closure_x_fintech_x_credmid, ///
        absorb(mergerID year) cluster(county_fips)

    di "Triple interaction (closure × fintech × mid-credit): " %7.4f _b[closure_x_fintech_x_credmid]
    di "This tests Jagtiani & Lemieux hypothesis: fintech helps moderate-credit borrowers most"
}

* Split sample by credit score
cap {
    di ""
    di "--- Split Sample by Credit Score ---"

    preserve
    keep if credit_mid == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Mid-credit (620-720): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if credit_low == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Low-credit (<620): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if credit_high == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "High-credit (720+): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore
}

********************************************************************************
* PART 5: Heterogeneity by Income
********************************************************************************

di ""
di "=== HETEROGENEITY BY INCOME ==="

cap {
    * Split sample
    preserve
    keep if low_income == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Low income (Q1-Q2): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if low_income == 0
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "High income (Q3-Q4): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore
}

********************************************************************************
* PART 6: Heterogeneity by Age
********************************************************************************

di ""
di "=== HETEROGENEITY BY AGE ==="

cap {
    preserve
    keep if young == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Young (<35): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if middle == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Middle (35-54): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if older == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Older (55+): coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore
}

********************************************************************************
* PART 7: Heterogeneity by Race
********************************************************************************

di ""
di "=== HETEROGENEITY BY RACE ==="

cap {
    preserve
    keep if minority == 1
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Minority: coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore

    preserve
    keep if minority == 0
    cap reghdfe anytoise closure_zip fintech_share closure_x_fintech, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        di "Non-minority: coef = " %7.4f _b[closure_x_fintech] " (SE = " %6.4f _se[closure_x_fintech] "), N = " e(N)
    }
    restore
}

********************************************************************************
* PART 8: Summary
********************************************************************************

di ""
di "=== HETEROGENEITY SUMMARY ==="
di ""
di "If fintech disproportionately helps mid-credit borrowers (620-720),"
di "this supports the algorithmic underwriting hypothesis from Jagtiani & Lemieux:"
di "fintech can better assess creditworthiness of 'thin file' borrowers."
di ""
di "Differential effects by income, age, or race would inform policy targeting."

log close
