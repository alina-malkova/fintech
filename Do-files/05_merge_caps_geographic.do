********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Merge CAPS data with all geographic alternative data sources
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
global caps "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Review SEj/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

cap mkdir "$results"

log using "$dofiles/05_merge_caps_geographic.log", replace

di "==========================================="
di "Merging CAPS with Geographic Data"
di "==========================================="

********************************************************************************
* LOAD CAPS DATA
********************************************************************************

di "--- Loading CAPS data ---"
use "$caps/working_feb24.dta", clear

* Store original N
local orig_n = _N
di "Original CAPS observations: `orig_n'"
di "Original CAPS variables: " c(k)

* Check key variables exist
sum zip year
tab year

********************************************************************************
* MERGE 1: ZIP TO COUNTY CROSSWALK
********************************************************************************

di ""
di "==========================================="
di "MERGE 1: ZIP to County Crosswalk"
di "==========================================="

* Merge with crosswalk to get county_fips
merge m:1 zip using "$data/Crosswalks/zip_county.dta", keep(master match) nogen

* Check merge
count if county_fips == .
di "Missing county_fips after crosswalk merge: " r(N)

* Label the new variable
label var county_fips "County FIPS (from ZIP crosswalk)"

********************************************************************************
* MERGE 2: SOCIAL CAPITAL ATLAS (BY ZIP)
********************************************************************************

di ""
di "==========================================="
di "MERGE 2: Social Capital Atlas (Facebook Data)"
di "==========================================="

merge m:1 zip using "$data/Social_Capital/social_capital_zip.dta", ///
    keep(master match) nogen keepusing(economic_connectedness social_clustering ///
    volunteering_rate civic_orgs social_capital_index ///
    economic_connectedness_std social_clustering_std volunteering_rate_std)

count if economic_connectedness == .
di "Missing economic connectedness: " r(N) " (" %4.1f 100*r(N)/_N "%)"

sum economic_connectedness social_clustering volunteering_rate

********************************************************************************
* MERGE 3: FINTECH PENETRATION (BY COUNTY-YEAR)
********************************************************************************

di ""
di "==========================================="
di "MERGE 3: Fintech Penetration (Fuster et al.)"
di "==========================================="

merge m:1 county_fips year using "$data/fintech_county_clean.dta", ///
    keep(master match) nogen keepusing(fintech_share fintech_share_std ///
    loan_amount total_lending)

count if fintech_share == .
di "Missing fintech share: " r(N) " (" %4.1f 100*r(N)/_N "%)"
di "(Note: Fintech data only covers 2010-2017)"

* Fintech coverage by year
tab year if fintech_share != ., m

sum fintech_share if fintech_share != .

********************************************************************************
* MERGE 4: BROADBAND ACCESS (BY ZIP)
********************************************************************************

di ""
di "==========================================="
di "MERGE 4: Broadband Access (Census ACS 2019)"
di "==========================================="

merge m:1 zip using "$data/Broadband/broadband_zip.dta", ///
    keep(master match) nogen keepusing(pct_internet pct_broadband ///
    pct_broadband_std low_broadband)

count if pct_broadband == .
di "Missing broadband data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

sum pct_broadband low_broadband

********************************************************************************
* MERGE 5: FOOD ACCESS (BY COUNTY)
********************************************************************************

di ""
di "==========================================="
di "MERGE 5: Food Access Atlas (USDA)"
di "==========================================="

merge m:1 county_fips using "$data/Food_Access/food_access_county.dta", ///
    keep(master match) nogen keepusing(food_desert_share high_food_desert ///
    povertyrate medianfamilyincome food_desert_std)

count if food_desert_share == .
di "Missing food access data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

sum food_desert_share high_food_desert

********************************************************************************
* MERGE 6: DOLLAR STORES (BY COUNTY)
********************************************************************************

di ""
di "==========================================="
di "MERGE 6: Dollar Stores (Census CBP)"
di "==========================================="

merge m:1 county_fips using "$data/Dollar_Stores/dollar_stores_county.dta", ///
    keep(master match) nogen keepusing(dollar_stores dollar_stores_per_10k ///
    high_dollar_stores dollar_stores_std)

count if dollar_stores == .
di "Missing dollar stores data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

sum dollar_stores_per_10k high_dollar_stores

********************************************************************************
* MERGE 7: BANKING ACCESS/DESERTS (BY COUNTY)
********************************************************************************

di ""
di "==========================================="
di "MERGE 7: Banking Access/Deserts (FDIC SOD)"
di "==========================================="

merge m:1 county_fips using "$data/Banking_Deserts/banking_access_county.dta", ///
    keep(master match) nogen keepusing(num_branches branches_per_10k ///
    low_branch_access banking_desert no_branches branches_per_10k_std)

count if branches_per_10k == .
di "Missing banking access data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

sum branches_per_10k banking_desert low_branch_access
tab banking_desert

********************************************************************************
* CREATE COMPOSITE INDICATORS
********************************************************************************

di ""
di "==========================================="
di "Creating Composite Indicators"
di "==========================================="

*------------------------------------------------------------------------------
* Fintech Readiness Index
*------------------------------------------------------------------------------
* Areas with high social capital + high fintech + high broadband = fintech ready

gen fintech_readiness = .
replace fintech_readiness = (economic_connectedness_std + fintech_share_std + pct_broadband_std) / 3 ///
    if economic_connectedness_std != . & fintech_share_std != . & pct_broadband_std != .
label var fintech_readiness "Fintech Readiness Index (composite)"

* Fallback: without broadband
replace fintech_readiness = (economic_connectedness_std + fintech_share_std) / 2 ///
    if fintech_readiness == . & economic_connectedness_std != . & fintech_share_std != .

sum fintech_readiness

*------------------------------------------------------------------------------
* Financial Desert Indicator
*------------------------------------------------------------------------------
* Combines banking desert and food desert

gen financial_desert = .
replace financial_desert = (banking_desert == 1) | (high_food_desert == 1) ///
    if banking_desert != . | high_food_desert != .
label var financial_desert "Financial desert (banking or food desert)"

tab financial_desert

*------------------------------------------------------------------------------
* Underserved Area Indicator
*------------------------------------------------------------------------------
gen underserved_area = .
replace underserved_area = (economic_connectedness_std < 0) & (fintech_share_std < 0) ///
    if economic_connectedness_std != . & fintech_share_std != .
label var underserved_area "Underserved (low social capital + low fintech)"

tab underserved_area

*------------------------------------------------------------------------------
* Digital Divide Indicator
*------------------------------------------------------------------------------
gen digital_divide = .
replace digital_divide = (low_broadband == 1) & (economic_connectedness_std < 0) ///
    if low_broadband != . & economic_connectedness_std != .
label var digital_divide "Digital divide (low broadband + low social capital)"

tab digital_divide

********************************************************************************
* SUMMARY
********************************************************************************

di ""
di "==========================================="
di "MERGE SUMMARY"
di "==========================================="

di ""
di "Final dataset:"
di "  Observations: " _N
di "  Variables: " c(k)

di ""
di "Geographic data coverage:"
sum economic_connectedness fintech_share pct_broadband food_desert_share ///
    dollar_stores_per_10k branches_per_10k

di ""
di "Composite indicators:"
tab1 financial_desert underserved_area digital_divide

********************************************************************************
* SAVE
********************************************************************************

di ""
di "==========================================="
di "Saving Merged Dataset"
di "==========================================="

* Compress to reduce file size
compress

* Save
save "$root/Data/caps_geographic_merged.dta", replace

di ""
di "Saved: $root/Data/caps_geographic_merged.dta"
di "Observations: " _N
di "Variables: " c(k)

log close
