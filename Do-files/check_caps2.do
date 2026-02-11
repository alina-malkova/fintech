clear all
set maxvar 32000
use "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Review SEj/Data/working_feb24.dta", clear

di "=== Dataset Info ==="
di "Variables: " c(k)
di "Observations: " _N

di ""
di "=== ZIP/Geographic variables ==="
ds *zip*
ds *county*
ds *state*
ds *fips*

di ""
di "=== Year variable ==="
ds year*
tab year if year != .

di ""
di "=== ID variable ==="
ds id*
