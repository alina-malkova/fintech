clear all
set maxvar 32000
use "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research/Data/caps_geographic_merged.dta", clear

di "=== ID variables ==="
ds *ID* *id*

di ""
di "=== Variables with 'treat' or 'closure' ==="
lookfor treat closure

di ""
di "=== Check key outcome and treatment variables from published paper ==="
lookfor incorporated unincorporated
ds treat* closure*

di ""
di "=== Fintech and branch variables ==="
sum fintech_share branches_per_10k banking_desert economic_connectedness

di ""
di "=== Check for panel structure ==="
sum year
tab year
