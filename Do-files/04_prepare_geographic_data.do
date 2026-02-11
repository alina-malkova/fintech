********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Prepare all geographic alternative data sources (no CAPS required)
* Author:  Alina Malkova
* Date:    February 2026
********************************************************************************

clear all
set more off
cap log close

* Set paths
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global dofiles "$root/Do-files"

log using "$dofiles/04_prepare_geographic_data.log", replace

di "==========================================="
di "Preparing Geographic Data Sources"
di "==========================================="

********************************************************************************
* PART 1: PREPARE CROSSWALKS
********************************************************************************

di "==========================================="
di "PART 1: Preparing Geographic Crosswalks"
di "==========================================="

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
* PART 3: PREPARE FINTECH COUNTY DATA
********************************************************************************

di "==========================================="
di "PART 3: Fintech County Data (Fuster et al.)"
di "==========================================="

import delimited "$data/Fintech_Classification/fintech_county_shares.csv", clear

rename fips county_fips

* Create fintech share
gen fintech_share = loan_amount / total_lending
replace fintech_share = 0 if fintech_share == . & total_lending > 0
replace fintech_share = . if total_lending == 0 | total_lending == .

label var county_fips "County FIPS"
label var year "Year"
label var loan_amount "Fintech lending volume"
label var total_lending "Total lending volume"
label var fintech_share "Fintech market share"

* Standardize
bysort year: egen fintech_share_std = std(fintech_share)
label var fintech_share_std "Fintech share (standardized by year)"

* Summary
sum fintech_share, detail
tab year

compress
save "$data/fintech_county_clean.dta", replace

di "Fintech data: " _N " county-year observations"

********************************************************************************
* PART 4: PREPARE FOOD ACCESS ATLAS DATA
********************************************************************************

di "==========================================="
di "PART 4: Food Access Atlas (USDA)"
di "==========================================="

cap confirm file "$data/Food_Access/food_access_atlas_2019.csv"
if _rc == 0 {
    import delimited "$data/Food_Access/food_access_atlas_2019.csv", clear varnames(1)

    * Stata auto-converts to lowercase, so variable names are already:
    * censustract, pop2010, lilatracts_1and10, lowincometracts, povertyrate, medianfamilyincome

    * Extract county FIPS from census tract
    tostring censustract, replace format(%11.0f)
    gen county_fips = substr(censustract, 1, 5)
    destring county_fips, replace

    * Rename truncated variable names
    rename lilatracts_1and10 lila_1and10
    rename lowincometracts low_income

    * Aggregate to county level
    collapse (mean) povertyrate medianfamilyincome ///
             (sum) pop2010 lila_1and10 ///
             (max) low_income, by(county_fips)

    * Create food desert share (population in food desert tracts as % of total)
    gen food_desert_share = lila_1and10 / pop2010 * 100
    replace food_desert_share = 0 if food_desert_share == .

    * High food desert indicator (top quartile)
    egen food_desert_p75 = pctile(food_desert_share), p(75)
    gen high_food_desert = food_desert_share > food_desert_p75 & food_desert_share != .
    drop food_desert_p75

    label var county_fips "County FIPS"
    label var food_desert_share "Share of pop in food desert tracts"
    label var high_food_desert "High food desert county (top 25%)"
    label var povertyrate "Average poverty rate"
    label var medianfamilyincome "Average median family income"

    * Standardize
    egen food_desert_std = std(food_desert_share)

    sum food_desert_share high_food_desert povertyrate

    compress
    save "$data/Food_Access/food_access_county.dta", replace

    di "Food Access data: " _N " counties"
}
else {
    di "Food Access data not available - skipping"
}

********************************************************************************
* PART 5: PREPARE BROADBAND DATA
********************************************************************************

di "==========================================="
di "PART 5: Broadband Access (Census ACS 2019)"
di "==========================================="

cap confirm file "$data/Broadband/broadband_zcta_2019.csv"
if _rc == 0 {
    import delimited "$data/Broadband/broadband_zcta_2019.csv", clear

    * Variable is already named 'zip' in the CSV

    label var zip "ZIP/ZCTA code"
    label var pct_internet "Percent with internet access"
    label var pct_broadband "Percent with broadband"
    label var pct_no_internet "Percent without internet"
    
    * Standardize
    egen pct_broadband_std = std(pct_broadband)
    label var pct_broadband_std "Broadband access (standardized)"
    
    * Digital divide indicator (bottom quartile) - may already exist in CSV
    cap drop low_broadband
    egen broadband_p25 = pctile(pct_broadband), p(25)
    gen low_broadband = pct_broadband < broadband_p25 & pct_broadband != .
    drop broadband_p25
    label var low_broadband "Low broadband access (bottom 25%)"
    
    sum pct_internet pct_broadband low_broadband
    
    compress
    save "$data/Broadband/broadband_zip.dta", replace
    
    di "Broadband data: " _N " ZIPs"
}
else {
    di "Broadband data not available - skipping"
}

********************************************************************************
* PART 6: PREPARE DOLLAR STORES DATA
********************************************************************************

di "==========================================="
di "PART 6: Dollar Stores (Census CBP 2019)"
di "==========================================="

cap confirm file "$data/Dollar_Stores/dollar_stores_county_2019.csv"
if _rc == 0 {
    import delimited "$data/Dollar_Stores/dollar_stores_county_2019.csv", clear
    
    * Fix county FIPS (ensure 5 digits)
    tostring county_fips, replace
    replace county_fips = "0" + county_fips if length(county_fips) == 4
    destring county_fips, replace
    
    label var county_fips "County FIPS"
    label var dollar_stores "Number of dollar stores"
    cap label var dollar_store_emp "Dollar store employment"
    cap label var population "County population"
    label var dollar_stores_per_10k "Dollar stores per 10,000 population"
    label var high_dollar_stores "High dollar store density (top 25%)"
    
    * Standardize
    egen dollar_stores_std = std(dollar_stores_per_10k)
    label var dollar_stores_std "Dollar store density (standardized)"
    
    sum dollar_stores dollar_stores_per_10k high_dollar_stores
    
    compress
    save "$data/Dollar_Stores/dollar_stores_county.dta", replace
    
    di "Dollar stores data: " _N " counties"
}
else {
    di "Dollar stores data not available - skipping"
}

********************************************************************************
* PART 7: PREPARE BANKING DESERTS DATA
********************************************************************************

di "==========================================="
di "PART 7: Banking Access/Deserts (FDIC SOD 2023)"
di "==========================================="

cap confirm file "$data/Banking_Deserts/banking_access_county_2023.csv"
if _rc == 0 {
    import delimited "$data/Banking_Deserts/banking_access_county_2023.csv", clear
    
    * Fix county FIPS (ensure 5 digits)
    tostring county_fips, replace
    replace county_fips = "0" + county_fips if length(county_fips) == 4
    destring county_fips, replace
    
    label var county_fips "County FIPS"
    label var num_branches "Number of bank branches"
    label var total_deposits "Total deposits ($000s)"
    label var population "County population (2020)"
    label var branches_per_10k "Bank branches per 10,000 population"
    label var low_branch_access "Low branch access (bottom 25%)"
    label var banking_desert "Banking desert (< 1 branch/10k)"
    label var no_branches "County has no bank branches"
    
    * Standardize
    egen branches_per_10k_std = std(branches_per_10k)
    label var branches_per_10k_std "Branch density (standardized)"
    
    sum num_branches branches_per_10k low_branch_access banking_desert no_branches
    tab banking_desert
    tab low_branch_access
    
    compress
    save "$data/Banking_Deserts/banking_access_county.dta", replace
    
    di "Banking access data: " _N " counties"
    di "Counties with no branches: "
    count if no_branches == 1
    di "Banking deserts (< 1 branch/10k): "
    count if banking_desert == 1
}
else {
    di "Banking deserts data not available - skipping"
}

********************************************************************************
* SUMMARY
********************************************************************************

di "==========================================="
di "DATA PREPARATION COMPLETE"
di "==========================================="

di ""
di "Prepared .dta files:"
di "  - $data/Crosswalks/zip_county.dta"
di "  - $data/Social_Capital/social_capital_zip.dta"
di "  - $data/fintech_county_clean.dta"
di "  - $data/Food_Access/food_access_county.dta"
di "  - $data/Broadband/broadband_zip.dta"
di "  - $data/Dollar_Stores/dollar_stores_county.dta"
di "  - $data/Banking_Deserts/banking_access_county.dta"
di ""
di "Next step: Modify 04_merge_geographic_data.do with your CAPS data path"
di "           and run to merge all data with CAPS."

log close
