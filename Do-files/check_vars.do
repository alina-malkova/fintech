clear all
set maxvar 32000
use "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research/Data/caps_geographic_merged.dta", clear

di "=== Looking for self-employment/business variables ==="
lookfor self employ business incorp

di ""
di "=== Looking for branch closure variables ==="
lookfor branch closure bank

di ""
di "=== Looking for individual ID ==="
lookfor id

di ""
di "=== Looking for demographic controls ==="
lookfor age female male married educ college

di ""
di "=== Check fintech and geographic variables ==="
ds fintech* economic* banking* branch*
