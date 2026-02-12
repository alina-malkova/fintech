********************************************************************************
* County-Level Business Formation Analysis
* Triangulation exercise with larger sample than individual-level CAPS
********************************************************************************

clear all
set more off
cap log close
log using "county_level_analysis.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"

di "=== COUNTY-LEVEL TRIANGULATION ANALYSIS ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Load pre-processed CBP panel (if exists) or process
********************************************************************************

cap confirm file "Data/CBP/cbp_county_panel.dta"
if _rc != 0 {
    di "Processing CBP data from scratch..."

    forvalues year = 2010/2017 {
        local yy = substr("`year'", 3, 2)
        di "  Processing CBP `year'..."
        import delimited "Data/CBP/cbp`yy'co.txt", clear
        gen str5 fips = string(fipstate, "%02.0f") + string(fipscty, "%03.0f")
        keep if naics == "------"
        keep fips est emp n1_4
        rename est establishments
        rename emp employment
        rename n1_4 small_estab
        gen year = `year'
        tempfile cbp`year'
        save `cbp`year''
    }

    use `cbp2010', clear
    forvalues year = 2011/2017 {
        append using `cbp`year''
    }

    destring employment, replace force
    sort fips year
    by fips: gen estab_growth = (establishments - establishments[_n-1]) / establishments[_n-1] * 100 if _n > 1
    save "Data/CBP/cbp_county_panel.dta", replace
}
else {
    di "Loading existing CBP panel..."
    use "Data/CBP/cbp_county_panel.dta", clear
}

********************************************************************************
* PART 2: Merge with Fintech Data
********************************************************************************

di ""
di "=== MERGING DATA ==="

cap rename fips county_fips
cap destring county_fips, replace

* Merge fintech penetration
merge m:1 county_fips year using "Data/fintech_county_clean.dta", keep(1 3) nogen
gen has_fintech = (fintech_share != .)

* Merge branch data
merge m:1 county_fips using "Data/Banking_Deserts/banking_access_county.dta", keepusing(branches_per_10k banking_desert) keep(1 3) nogen

********************************************************************************
* PART 3: Summary Statistics
********************************************************************************

di ""
di "=== SAMPLE STATISTICS ==="

count
di "Total county-year observations: " r(N)

count if has_fintech == 1
di "With fintech data: " r(N)

preserve
keep if has_fintech == 1
egen tag = tag(county_fips)
count if tag == 1
di "Unique counties with fintech: " r(N)
restore

sum establishments employment estab_growth fintech_share branches_per_10k if has_fintech == 1

********************************************************************************
* PART 4: County-Level Regressions
********************************************************************************

di ""
di "=== COUNTY-LEVEL REGRESSIONS ==="

* Keep years with fintech data
keep if year >= 2010 & year <= 2017 & has_fintech == 1

* Since we only have cross-sectional branch data, use banking_desert indicator
* Interact with fintech
gen desert_x_fintech = banking_desert * fintech_share

di ""
di "--- Model 1: Establishment Growth ~ Banking Desert × Fintech ---"
di "Testing: Do banking deserts have lower growth, mitigated by fintech?"
reghdfe estab_growth banking_desert fintech_share desert_x_fintech, absorb(year) cluster(county_fips)

di ""
di "--- Model 2: Add County FE ---"
reghdfe estab_growth banking_desert fintech_share desert_x_fintech, absorb(county_fips year) cluster(county_fips)

di ""
di "--- Model 3: Alternative - Branch Density × Fintech ---"
gen low_branch = (branches_per_10k < 2)
gen lowbranch_x_fintech = low_branch * fintech_share
reghdfe estab_growth low_branch fintech_share lowbranch_x_fintech, absorb(year) cluster(county_fips)

********************************************************************************
* PART 5: Summary
********************************************************************************

di ""
di "=== ANALYSIS COMPLETE ==="
di "End: " c(current_time)
di ""
di "This county-level analysis uses ~3,000 counties vs 59 in CAPS."
di "The identification is weaker (no merger-group variation), but provides"
di "complementary evidence on whether fintech presence correlates with"
di "stronger business formation in banking-underserved areas."

log close
