********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Merge CAPS data with Fuster et al. fintech county data
* Author:  Alina Malkova
* Date:    February 2026
********************************************************************************

clear all
set more off
cap log close

* Set paths - MODIFY THESE TO MATCH YOUR SETUP
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global caps "$root/../Data"  // Adjust to your CAPS data location
global dofiles "$root/Do-files"
global results "$root/Results"

* Create results folder if needed
cap mkdir "$results"

* Start log
log using "$dofiles/01_merge_fintech_data.log", replace

********************************************************************************
* STEP 1: Prepare Fintech County Data
********************************************************************************

* Load Fuster et al. county-level fintech data
import delimited "$data/Fintech_Classification/fintech_county_shares.csv", clear

* Rename and label variables
rename fips county_fips
label var county_fips "County FIPS code"
label var year "Year"
label var loan_amount "Fintech mortgage lending volume (billions)"
label var total_lending "Total mortgage lending volume (billions)"

* Create fintech market share
gen fintech_share = loan_amount / total_lending
label var fintech_share "Fintech mortgage market share"

* Create logged version (adding small constant for zeros)
gen ln_fintech_share = ln(fintech_share + 0.001)
label var ln_fintech_share "Log fintech market share"

* Create standardized version
egen fintech_share_std = std(fintech_share)
label var fintech_share_std "Fintech share (standardized)"

* Summary statistics
sum fintech_share, detail
tab year, sum(fintech_share)

* Save fintech data
compress
save "$data/fintech_county_clean.dta", replace

********************************************************************************
* STEP 2: Prepare ZCTA-County Crosswalk
********************************************************************************

* Load crosswalk (one county per ZCTA based on largest area overlap)
import delimited "$data/Crosswalks/zcta_county_primary.csv", clear

* Rename for merging
rename zcta zip
label var zip "ZIP/ZCTA code"
label var county_fips "County FIPS code (primary)"
label var county_name "County name"

* Convert to numeric
destring zip, replace
destring county_fips, replace

* Check for duplicates (should be none in primary file)
duplicates report zip
assert r(unique_value) == r(N)

* Save crosswalk
compress
save "$data/zip_county_crosswalk.dta", replace

********************************************************************************
* STEP 3: Merge with CAPS Data
********************************************************************************

* Load CAPS analysis dataset
* MODIFY THIS PATH AND FILENAME TO MATCH YOUR CAPS DATA
use "$caps/caps_analysis.dta", clear

* -------------------------
* MODIFY THESE VARIABLE NAMES TO MATCH YOUR CAPS DATA:
* -------------------------
* Assuming your CAPS data has:
*   - Individual ID: id or respondent_id
*   - Year: year or survey_year
*   - ZIP code: zipcode or zip
*   - Self-employment: self_employed or incorporated
*   - Branch closure measure: branch_closure or branches_closed

* Rename ZIP variable if needed (uncomment and modify)
* rename zipcode zip

* Convert ZIP to numeric if string
cap destring zip, replace

* -------------------------
* Merge 1: Add county FIPS via crosswalk
* -------------------------
merge m:1 zip using "$data/zip_county_crosswalk.dta", keep(master match) nogen

* Check merge rate
count if county_fips == .
di "Observations without county match: " r(N)

* -------------------------
* Merge 2: Add fintech penetration data
* -------------------------
merge m:1 county_fips year using "$data/fintech_county_clean.dta", keep(master match)

* Check merge rate
tab _merge
tab year if _merge == 1  // Years without fintech data (outside 2010-2017)
drop _merge

* Fill missing fintech values for years outside 2010-2017
* Option A: Use 2017 value for later years
* bys county_fips: egen fintech_2017 = max(cond(year==2017, fintech_share, .))
* replace fintech_share = fintech_2017 if fintech_share == . & year > 2017

* Option B: Set to missing (more conservative)
* (This is the default - do nothing)

********************************************************************************
* STEP 4: Create Analysis Variables
********************************************************************************

* -------------------------
* MODIFY: Your branch closure variable name
* -------------------------
* Assuming you have a variable called branch_closure from your published paper
* If not, create a placeholder:
cap confirm variable branch_closure
if _rc {
    di "NOTE: branch_closure variable not found. Create or rename your branch closure measure."
    * gen branch_closure = .  // Uncomment and replace with your variable
}

* Create interaction term
cap gen branch_x_fintech = branch_closure * fintech_share
label var branch_x_fintech "Branch closure × Fintech share"

* Create high/low fintech indicator (median split)
egen fintech_median = median(fintech_share)
gen high_fintech = (fintech_share > fintech_median) if fintech_share != .
label var high_fintech "Above median fintech penetration"

* Create fintech quartiles
xtile fintech_quartile = fintech_share, nq(4)
label var fintech_quartile "Fintech penetration quartile"

********************************************************************************
* STEP 5: Summary Statistics
********************************************************************************

* Fintech penetration summary by year
table year, stat(mean fintech_share) stat(sd fintech_share) stat(min fintech_share) stat(max fintech_share)

* Correlation with branch closures
cap corr branch_closure fintech_share

* Sample description
di "=== Sample Summary ==="
di "Total observations: " _N
count if fintech_share != .
di "Observations with fintech data: " r(N)
tab year if fintech_share != .

********************************************************************************
* STEP 6: Save Analysis Dataset
********************************************************************************

* Order key variables first
order id year zip county_fips fintech_share branch_closure branch_x_fintech

* Label dataset
label data "CAPS merged with Fuster et al. fintech county data"

* Save
compress
save "$data/caps_fintech_merged.dta", replace

di "=== Merge Complete ==="
di "Output saved to: $data/caps_fintech_merged.dta"

log close

********************************************************************************
* END OF FILE
********************************************************************************
