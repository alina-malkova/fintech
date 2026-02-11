* Fix county_fips type in all geographic data files

clear all
set more off

global data "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research/Data"

* Fix fintech_county_clean.dta
di "Fixing fintech_county_clean.dta..."
use "$data/fintech_county_clean.dta", clear
describe county_fips
destring county_fips, replace force
describe county_fips
save "$data/fintech_county_clean.dta", replace

* Fix Food_Access
di "Fixing food_access_county.dta..."
use "$data/Food_Access/food_access_county.dta", clear
describe county_fips
cap destring county_fips, replace force
describe county_fips
save "$data/Food_Access/food_access_county.dta", replace

* Fix Dollar_Stores
di "Fixing dollar_stores_county.dta..."
use "$data/Dollar_Stores/dollar_stores_county.dta", clear
describe county_fips
cap destring county_fips, replace force
describe county_fips
save "$data/Dollar_Stores/dollar_stores_county.dta", replace

* Fix Banking_Deserts
di "Fixing banking_access_county.dta..."
use "$data/Banking_Deserts/banking_access_county.dta", clear
describe county_fips
cap destring county_fips, replace force
describe county_fips
save "$data/Banking_Deserts/banking_access_county.dta", replace

* Fix ZIP crosswalk
di "Fixing zip_county.dta..."
use "$data/Crosswalks/zip_county.dta", clear
describe county_fips
cap destring county_fips, replace force
describe county_fips
save "$data/Crosswalks/zip_county.dta", replace

di "Done fixing county_fips types!"
