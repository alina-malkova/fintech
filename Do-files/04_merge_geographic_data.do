********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Merge all geographic alternative data sources with CAPS
* Author:  Alina Malkova
* Date:    February 2026
*
* This do-file merges:
*   1. Fuster et al. Fintech County Data (already done in 01_)
*   2. Social Capital Atlas (Facebook economic connectedness) - Downloaded
*   3. Food Access Atlas (USDA 2019) - Downloaded
*   4. Broadband Access (Census ACS 2019) - Downloaded
*   5. Dollar Stores (Census CBP 2019) - Downloaded
*   6. Banking Access/Deserts (FDIC SOD 2023) - Downloaded
*   7. ACS Demographics (Census API or download)
********************************************************************************

clear all
set more off
cap log close

* Set paths
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global caps "$root/../Data"  // MODIFY: Your CAPS data location
global results "$root/Results"
global dofiles "$root/Do-files"

log using "$dofiles/04_merge_geographic_data.log", replace

********************************************************************************
* PART 1: PREPARE CROSSWALKS
********************************************************************************

di "==========================================="
di "PART 1: Preparing Geographic Crosswalks"
di "==========================================="

*------------------------------------------------------------------------------
* 1A. ZIP to County Crosswalk (already created)
*------------------------------------------------------------------------------
import delimited "$data/Crosswalks/zcta_county_primary.csv", clear
rename zcta zip
destring zip, replace
destring county_fips, replace
label var zip "ZIP/ZCTA code"
label var county_fips "County FIPS (primary)"
save "$data/Crosswalks/zip_county.dta", replace

di "ZIP-County crosswalk: " _N " ZIPs"

********************************************************************************
* PART 2: PREPARE SOCIAL CAPITAL ATLAS DATA
********************************************************************************

di "==========================================="
di "PART 2: Social Capital Atlas (Facebook Data)"
di "==========================================="

import delimited "$data/Social_Capital/social_capital_zip.csv", clear

* Rename key variables
rename ec_zip economic_connectedness
rename clustering_zip social_clustering
rename volunteering_rate_zip volunteering_rate
rename civic_organizations_zip civic_orgs
rename support_ratio_zip support_ratio

* Label variables
label var zip "ZIP code"
label var economic_connectedness "Economic connectedness (Chetty et al.)"
label var social_clustering "Social clustering coefficient"
label var volunteering_rate "Volunteering rate"
label var civic_orgs "Civic organizations rate"
label var support_ratio "Support ratio"

* Keep key variables
keep zip county economic_connectedness social_clustering ///
     volunteering_rate civic_orgs support_ratio ///
     ec_se_zip nbhd_ec_zip exposure_grp_mem_zip bias_grp_mem_zip

* Create standardized versions
foreach var in economic_connectedness social_clustering volunteering_rate {
    egen `var'_std = std(`var')
    label var `var'_std "`var' (standardized)"
}

* Create social capital index (composite)
gen social_capital_index = (economic_connectedness_std + ///
                            social_clustering_std + ///
                            volunteering_rate_std) / 3
label var social_capital_index "Social Capital Index (composite)"

* Summary stats
sum economic_connectedness social_clustering volunteering_rate civic_orgs

* Save
compress
save "$data/Social_Capital/social_capital_zip.dta", replace

di "Social Capital Atlas: " _N " ZIPs with data"

********************************************************************************
* PART 3: PREPARE FINTECH COUNTY DATA (from do-file 01)
********************************************************************************

di "==========================================="
di "PART 3: Fintech County Data"
di "==========================================="

* Check if already prepared
cap confirm file "$data/fintech_county_clean.dta"
if _rc {
    * Prepare if not exists
    import delimited "$data/Fintech_Classification/fintech_county_shares.csv", clear
    rename fips county_fips
    gen fintech_share = loan_amount / total_lending
    label var county_fips "County FIPS"
    label var year "Year"
    label var fintech_share "Fintech mortgage market share"

    * Standardize
    egen fintech_share_std = std(fintech_share)

    compress
    save "$data/fintech_county_clean.dta", replace
}
else {
    di "Fintech county data already prepared"
}

use "$data/fintech_county_clean.dta", clear
di "Fintech data: " _N " county-year observations"
tab year

********************************************************************************
* PART 4: PREPARE FOOD ACCESS ATLAS (DOWNLOADED)
********************************************************************************

di "==========================================="
di "PART 4: Food Access Atlas"
di "==========================================="

* Load pre-processed CSV (key variables extracted)
import delimited "$data/Food_Access/food_access_atlas_2019.csv", clear

* Rename tract variable
rename censustract tract_fips
destring tract_fips, replace

* Create food desert indicator
gen food_desert = (lilatracts_1and10 == 1)
label var food_desert "Low income + low food access tract (1mi urban/10mi rural)"

* Label key variables
label var lilatracts_1and10 "LILA tract (1mi urban, 10mi rural)"
label var lilatracts_halfand10 "LILA tract (0.5mi urban, 10mi rural)"
label var lowincometracts "Low income tract"
label var povertyrate "Poverty rate (%)"
label var medianfamilyincome "Median family income ($)"
label var lapop1share "% pop low access at 1 mile"
label var lalowi1share "% low-income pop low access at 1 mile"
label var lahunv1share "% households no vehicle low access"

* Create county FIPS from tract (first 5 digits)
gen str11 tract_str = string(tract_fips, "%011.0f")
gen county_fips = real(substr(tract_str, 1, 5))
label var county_fips "County FIPS"
drop tract_str

* Summary
sum food_desert povertyrate medianfamilyincome
tab food_desert

* Save at tract level
compress
save "$data/Food_Access/food_access_tract.dta", replace

di "Food Access Atlas: " _N " tracts"

* Aggregate to county level for merging with CAPS
preserve
collapse (mean) food_desert povertyrate medianfamilyincome ///
         lapop1share lalowi1share lahunv1share ///
         (sum) pop2010, by(county_fips)

rename food_desert food_desert_share
label var food_desert_share "Share of tracts that are food deserts"
label var povertyrate "Avg poverty rate in county"
label var pop2010 "County population 2010"

* Create high food desert county indicator
gen high_food_desert = (food_desert_share > 0.20)
label var high_food_desert "More than 20% of tracts are food deserts"

save "$data/Food_Access/food_access_county.dta", replace
di "Aggregated to " _N " counties"
restore

********************************************************************************
* PART 5: PREPARE BROADBAND DATA (from Census ACS)
********************************************************************************

di "==========================================="
di "PART 5: Broadband Access (Census ACS 2019)"
di "==========================================="

* Load ACS internet access data (downloaded via Census API)
import delimited "$data/Broadband/broadband_zcta_2019.csv", clear

* Label variables
label var zip "ZIP/ZCTA code"
label var total_households "Total households"
label var with_internet "Households with internet"
label var with_broadband "Households with broadband"
label var no_internet "Households without internet"
label var pct_internet "% with any internet"
label var pct_broadband "% with broadband"
label var pct_no_internet "% without internet"
label var low_broadband "Low broadband access (bottom 25%)"

* Create digital divide indicator
gen digital_divide = (pct_broadband < 70)
label var digital_divide "Digital divide area (<70% broadband)"

* Standardize for composite score
egen pct_broadband_std = std(pct_broadband)
label var pct_broadband_std "Broadband access (standardized)"

* Summary
sum pct_internet pct_broadband pct_no_internet
tab low_broadband
tab digital_divide

* Save
compress
save "$data/Broadband/broadband_zip.dta", replace

di "Broadband data: " _N " ZCTAs"

********************************************************************************
* PART 6: PREPARE DOLLAR STORES DATA (Census County Business Patterns)
********************************************************************************

di "==========================================="
di "PART 6: Dollar Stores (Census CBP 2019)"
di "==========================================="

* Load dollar stores data (NAICS 452319: All Other General Merchandise)
import delimited "$data/Dollar_Stores/dollar_stores_county_2019.csv", clear

* Fix county FIPS (ensure 5 digits)
tostring county_fips, replace
replace county_fips = "0" + county_fips if length(county_fips) == 4
destring county_fips, replace

* Label variables
label var county_fips "County FIPS"
label var dollar_stores "Number of dollar stores"
label var dollar_store_emp "Dollar store employment"
label var population "County population (2010)"
label var dollar_stores_per_10k "Dollar stores per 10,000 population"
label var high_dollar_stores "High dollar store density (top 25%)"

* Standardize for composite
egen dollar_stores_std = std(dollar_stores_per_10k)
label var dollar_stores_std "Dollar store density (standardized)"

* Summary
sum dollar_stores dollar_stores_per_10k high_dollar_stores

* Save at county level
compress
save "$data/Dollar_Stores/dollar_stores_county.dta", replace

di "Dollar stores data: " _N " counties"

********************************************************************************
* PART 7: PREPARE BANKING DESERTS DATA (FDIC Summary of Deposits)
********************************************************************************

di "==========================================="
di "PART 7: Banking Access/Deserts (FDIC SOD 2023)"
di "==========================================="

* Load banking access data (constructed from FDIC branch locations)
import delimited "$data/Banking_Deserts/banking_access_county_2023.csv", clear

* Fix county FIPS (ensure 5 digits)
tostring county_fips, replace
replace county_fips = "0" + county_fips if length(county_fips) == 4
destring county_fips, replace

* Label variables
label var county_fips "County FIPS"
label var num_branches "Number of bank branches"
label var total_deposits "Total deposits ($000s)"
label var population "County population (2020)"
label var branches_per_10k "Bank branches per 10,000 population"
label var low_branch_access "Low branch access (bottom 25%)"
label var banking_desert "Banking desert (< 1 branch/10k)"
label var no_branches "County has no bank branches"

* Standardize for composite
egen branches_per_10k_std = std(branches_per_10k)
label var branches_per_10k_std "Branch density (standardized)"

* Summary
sum num_branches branches_per_10k low_branch_access banking_desert no_branches
tab banking_desert
tab low_branch_access

* Save at county level
compress
save "$data/Banking_Deserts/banking_access_county.dta", replace

di "Banking access data: " _N " counties"
di "Counties with no branches: "
count if no_branches == 1
di "Banking deserts (< 1 branch/10k): "
count if banking_desert == 1

********************************************************************************
* PART 8: MERGE ALL DATA WITH CAPS
********************************************************************************

di "==========================================="
di "PART 7: Merging All Data with CAPS"
di "==========================================="

*------------------------------------------------------------------------------
* Load CAPS data
*------------------------------------------------------------------------------
* MODIFY THIS TO MATCH YOUR CAPS FILE
use "$caps/caps_analysis.dta", clear

* Store original N
local orig_n = _N
di "Original CAPS observations: `orig_n'"

*------------------------------------------------------------------------------
* Ensure ZIP is numeric
*------------------------------------------------------------------------------
* MODIFY: Your ZIP variable name
cap rename zipcode zip
cap destring zip, replace

*------------------------------------------------------------------------------
* Merge 1: ZIP to County crosswalk
*------------------------------------------------------------------------------
di "--- Merge 1: ZIP-County Crosswalk ---"
merge m:1 zip using "$data/Crosswalks/zip_county.dta", keep(master match) nogen
count if county_fips == .
di "Missing county FIPS: " r(N)

*------------------------------------------------------------------------------
* Merge 2: Social Capital Atlas (by ZIP)
*------------------------------------------------------------------------------
di "--- Merge 2: Social Capital Atlas ---"
merge m:1 zip using "$data/Social_Capital/social_capital_zip.dta", ///
    keep(master match) nogen keepusing(economic_connectedness social_clustering ///
    volunteering_rate civic_orgs social_capital_index *_std)

count if economic_connectedness == .
di "Missing social capital data: " r(N)

* Summary of social capital
sum economic_connectedness social_clustering volunteering_rate

*------------------------------------------------------------------------------
* Merge 3: Fintech penetration (by County-Year)
*------------------------------------------------------------------------------
di "--- Merge 3: Fintech Penetration ---"
merge m:1 county_fips year using "$data/fintech_county_clean.dta", ///
    keep(master match) nogen keepusing(fintech_share fintech_share_std ///
    loan_amount total_lending)

count if fintech_share == .
di "Missing fintech data: " r(N)
di "(Expected for years outside 2010-2017)"

* Summary of fintech
sum fintech_share if fintech_share != .
tab year if fintech_share != ., m

*------------------------------------------------------------------------------
* Merge 4: Food Access (by county)
*------------------------------------------------------------------------------
di "--- Merge 4: Food Access Atlas ---"
cap confirm file "$data/Food_Access/food_access_county.dta"
if _rc == 0 {
    merge m:1 county_fips using "$data/Food_Access/food_access_county.dta", ///
        keep(master match) nogen keepusing(food_desert_share high_food_desert ///
        povertyrate medianfamilyincome lahunv1share)

    count if food_desert_share == .
    di "Missing food access data: " r(N)

    * Summary
    sum food_desert_share high_food_desert povertyrate
}
else {
    di "Food access data not available - skipping"
}

*------------------------------------------------------------------------------
* Merge 5: Broadband (by ZIP)
*------------------------------------------------------------------------------
di "--- Merge 5: Broadband Access ---"
cap confirm file "$data/Broadband/broadband_zip.dta"
if _rc == 0 {
    merge m:1 zip using "$data/Broadband/broadband_zip.dta", ///
        keep(master match) nogen keepusing(pct_broadband pct_no_internet ///
        low_broadband digital_divide pct_broadband_std)

    count if pct_broadband == .
    di "Missing broadband data: " r(N)

    * Summary
    sum pct_broadband low_broadband digital_divide
}
else {
    di "Broadband data not available - skipping"
}

*------------------------------------------------------------------------------
* Merge 6: Dollar Stores (by County)
*------------------------------------------------------------------------------
di "--- Merge 6: Dollar Stores ---"
cap confirm file "$data/Dollar_Stores/dollar_stores_county.dta"
if _rc == 0 {
    merge m:1 county_fips using "$data/Dollar_Stores/dollar_stores_county.dta", ///
        keep(master match) nogen keepusing(dollar_stores dollar_stores_per_10k ///
        high_dollar_stores dollar_stores_std)

    count if dollar_stores == .
    di "Missing dollar stores data: " r(N)

    * Summary
    sum dollar_stores_per_10k high_dollar_stores
}
else {
    di "Dollar stores data not available - skipping"
}

*------------------------------------------------------------------------------
* Merge 7: Banking Access/Deserts (by County)
*------------------------------------------------------------------------------
di "--- Merge 7: Banking Access/Deserts ---"
cap confirm file "$data/Banking_Deserts/banking_access_county.dta"
if _rc == 0 {
    merge m:1 county_fips using "$data/Banking_Deserts/banking_access_county.dta", ///
        keep(master match) nogen keepusing(num_branches branches_per_10k ///
        low_branch_access banking_desert no_branches branches_per_10k_std)

    count if branches_per_10k == .
    di "Missing banking access data: " r(N)

    * Summary
    sum branches_per_10k banking_desert low_branch_access
    tab banking_desert, m
}
else {
    di "Banking deserts data not available - skipping"
}

********************************************************************************
* PART 9: CREATE COMPOSITE GEOGRAPHIC INDICATORS
********************************************************************************

di "==========================================="
di "PART 9: Creating Composite Indicators"
di "==========================================="

*------------------------------------------------------------------------------
* Geographic Fintech Readiness Index
*------------------------------------------------------------------------------
* Areas with high social capital + high fintech + high broadband = fintech ready

* Standardize components if not already
cap egen ec_std = std(economic_connectedness)
cap egen fintech_std = std(fintech_share)
cap egen broadband_std = std(pct_broadband)

* Composite: areas favorable for fintech adoption (2 or 3 components)
* Version with broadband
gen geo_fintech_ready = .
replace geo_fintech_ready = (economic_connectedness_std + fintech_share_std + pct_broadband_std) / 3 ///
    if economic_connectedness_std != . & fintech_share_std != . & pct_broadband_std != .
label var geo_fintech_ready "Geographic Fintech Readiness (composite)"

* Fallback version without broadband (if broadband missing)
gen geo_fintech_ready2 = .
replace geo_fintech_ready2 = (economic_connectedness_std + fintech_share_std) / 2 ///
    if economic_connectedness_std != . & fintech_share_std != . & geo_fintech_ready == .
replace geo_fintech_ready = geo_fintech_ready2 if geo_fintech_ready == .
drop geo_fintech_ready2

*------------------------------------------------------------------------------
* Underserved Area Indicator
*------------------------------------------------------------------------------
* Low social capital + low fintech + low broadband = underserved
gen underserved_area = .
replace underserved_area = (economic_connectedness_std < 0) & (fintech_share_std < 0) ///
    if economic_connectedness_std != . & fintech_share_std != .
label var underserved_area "Underserved area (low social capital + low fintech)"

* Digital desert: low broadband + low social capital
gen digital_desert = .
replace digital_desert = (pct_broadband_std < 0) & (economic_connectedness_std < 0) ///
    if pct_broadband_std != . & economic_connectedness_std != .
label var digital_desert "Digital desert (low broadband + low social capital)"

*------------------------------------------------------------------------------
* Financial Desert Indicator (combining banking + food deserts)
*------------------------------------------------------------------------------
* Areas with banking desert OR food desert = financial desert
gen financial_desert = .
replace financial_desert = (banking_desert == 1) | (high_food_desert == 1) ///
    if banking_desert != . | high_food_desert != .
replace financial_desert = banking_desert if financial_desert == . & banking_desert != .
replace financial_desert = high_food_desert if financial_desert == . & high_food_desert != .
label var financial_desert "Financial desert (banking or food desert)"

* Complete underserved: low fintech + banking desert + low social capital
gen complete_underserved = .
replace complete_underserved = (fintech_share_std < 0) & (banking_desert == 1) & ///
    (economic_connectedness_std < 0) ///
    if fintech_share_std != . & banking_desert != . & economic_connectedness_std != .
label var complete_underserved "Complete underserved (low fintech + banking desert + low social capital)"

* Summary of desert indicators
tab banking_desert, m
tab financial_desert, m
tab complete_underserved, m

*------------------------------------------------------------------------------
* Create terciles/quartiles for heterogeneity analysis
*------------------------------------------------------------------------------
* Social capital terciles
xtile ec_tercile = economic_connectedness, nq(3)
label var ec_tercile "Economic connectedness tercile"
label define ec_tercile 1 "Low" 2 "Medium" 3 "High"
label values ec_tercile ec_tercile

* Fintech penetration terciles
xtile fintech_tercile = fintech_share, nq(3)
label var fintech_tercile "Fintech penetration tercile"

*------------------------------------------------------------------------------
* Interaction terms for regression
*------------------------------------------------------------------------------
* MODIFY: Your branch closure variable
cap confirm variable branch_closure
if _rc == 0 {
    * Branch closure × Social capital
    gen branch_x_social = branch_closure * economic_connectedness_std
    label var branch_x_social "Branch closure × Economic connectedness"

    * Branch closure × Fintech
    gen branch_x_fintech = branch_closure * fintech_share_std
    label var branch_x_fintech "Branch closure × Fintech share"

    * Triple interaction
    gen branch_x_fintech_x_social = branch_closure * fintech_share_std * economic_connectedness_std
    label var branch_x_fintech_x_social "Branch × Fintech × Social capital"
}

********************************************************************************
* PART 9: SUMMARY STATISTICS
********************************************************************************

di "==========================================="
di "PART 9: Summary Statistics"
di "==========================================="

di ""
di "=== Sample Size ==="
di "Original CAPS: `orig_n'"
di "After merges: " _N

di ""
di "=== Geographic Data Coverage ==="
count if economic_connectedness != .
di "With social capital data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

count if fintech_share != .
di "With fintech data: " r(N) " (" %4.1f 100*r(N)/_N "%)"

count if economic_connectedness != . & fintech_share != .
di "With both: " r(N) " (" %4.1f 100*r(N)/_N "%)"

di ""
di "=== Key Variables Summary ==="
sum economic_connectedness fintech_share social_clustering volunteering_rate

di ""
di "=== Correlations ==="
cap corr economic_connectedness fintech_share social_clustering

di ""
di "=== Fintech by Social Capital Tercile ==="
table ec_tercile, stat(mean fintech_share) stat(sd fintech_share) stat(n fintech_share)

********************************************************************************
* PART 10: SAVE MERGED DATASET
********************************************************************************

di "==========================================="
di "PART 10: Saving Merged Dataset"
di "==========================================="

* Order key variables
order zip county_fips year ///
      economic_connectedness social_clustering volunteering_rate ///
      fintech_share geo_fintech_ready underserved_area

* Label dataset
label data "CAPS + Geographic Alternative Data (Social Capital, Fintech, etc.)"
notes: Merged `c(current_date)' using 04_merge_geographic_data.do
notes: Social Capital Atlas from Chetty et al. (2022) Nature
notes: Fintech data from Fuster et al. (2019) RFS

* Save
compress
save "$data/caps_geographic_merged.dta", replace

di ""
di "============================================"
di "MERGE COMPLETE"
di "============================================"
di "Output: $data/caps_geographic_merged.dta"
di ""

log close

********************************************************************************
* END OF FILE
********************************************************************************
