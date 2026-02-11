clear all
set maxvar 32000
use "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Review SEj/Data/working_feb24.dta", clear
describe, short
di "Variables: " c(k)
di "Observations: " _N

* Check for key variables
di "=== ZIP variables ==="
lookfor zip

di "=== Year variables ==="
lookfor year

di "=== ID variables ==="
lookfor id
