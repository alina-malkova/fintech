********************************************************************************
* SBA/CRA County-Level Outcomes
* Complementary evidence from small business lending data
********************************************************************************

clear all
set more off
cap log close
log using "sba_cra_outcomes.log", replace text

cd "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Other_Projects/JMP/Fintech Research"

di "=== SBA/CRA COUNTY-LEVEL OUTCOMES ==="
di "Start: " c(current_time)

********************************************************************************
* PART 1: Data Sources Overview
********************************************************************************

di ""
di "=== DATA SOURCES FOR SMALL BUSINESS LENDING ==="
di ""
di "1. SBA 7(a) and 504 Loan Data"
di "   - Public at ZIP code level"
di "   - Available from SBA.gov"
di "   - Covers SBA-guaranteed small business loans"
di ""
di "2. CRA Small Business Lending Data"
di "   - Public at census tract/county level"
di "   - Available from FFIEC"
di "   - Covers bank small business loans (< $1M)"
di ""
di "3. HMDA Data (already using via Fuster et al.)"
di "   - Mortgage originations by lender type"
di ""

********************************************************************************
* PART 2: Download/Check SBA Data
********************************************************************************

di ""
di "=== CHECKING FOR SBA DATA ==="

cap confirm file "Data/SBA/sba_loans_county.dta"
if _rc != 0 {
    di "SBA data not found locally"
    di ""
    di "To download SBA 7(a) loan data:"
    di "1. Visit: https://data.sba.gov/dataset/7-a-504-foia"
    di "2. Download yearly CSV files"
    di "3. Aggregate to county-year level"
    di ""
    di "Key variables:"
    di "  - GrossApproval (loan amount)"
    di "  - BorrZip (borrower ZIP, can map to county)"
    di "  - ApprovalFiscalYear"
    di "  - LoanStatus"
}
else {
    di "SBA data found - loading..."
    use "Data/SBA/sba_loans_county.dta", clear
}

********************************************************************************
* PART 3: Download/Check CRA Data
********************************************************************************

di ""
di "=== CHECKING FOR CRA DATA ==="

cap confirm file "Data/CRA/cra_small_business_county.dta"
if _rc != 0 {
    di "CRA data not found locally"
    di ""
    di "To download CRA small business lending data:"
    di "1. Visit: https://www.ffiec.gov/cra/craflatfiles.htm"
    di "2. Download disclosure data by year"
    di "3. Aggregate to county-year level"
    di ""
    di "Key variables:"
    di "  - SMALL_BUS_LOANS (count of loans)"
    di "  - SMALL_BUS_AMT (loan amounts)"
    di "  - TRACT/COUNTY identifiers"
}
else {
    di "CRA data found - loading..."
    use "Data/CRA/cra_small_business_county.dta", clear
}

********************************************************************************
* PART 4: Create Synthetic Analysis Framework
********************************************************************************

di ""
di "=== ANALYSIS FRAMEWORK ==="
di ""
di "Hypothesis: If fintech fills credit gaps from bank closures,"
di "we should see:"
di "  1. Branch closures reduce SBA/CRA lending (banks originate these)"
di "  2. In high-fintech counties, this reduction is attenuated"
di "  3. Or: Fintech penetration directly increases small business lending"
di ""

* Load county-level data we already have
cap use "Data/CBP/cbp_county_panel.dta", clear
if _rc != 0 {
    di "CBP county panel not found, checking for fintech county data..."
    cap use "Data/Fintech_Classification/fintech_county_lending.dta", clear
}

* Merge fintech data
cap rename fips county_fips
cap destring county_fips, replace
cap merge m:1 county_fips year using "Data/fintech_county_clean.dta", keep(1 3) nogen

* Merge branch data
cap merge m:1 county_fips using "Data/Banking_Deserts/banking_access_county.dta", ///
    keepusing(branches_per_10k banking_desert) keep(1 3) nogen

********************************************************************************
* PART 5: Proxy Analysis Using Establishment Data
********************************************************************************

di ""
di "=== PROXY ANALYSIS: ESTABLISHMENT DYNAMICS ==="
di ""
di "Without SBA/CRA loan data, we use CBP establishment counts as proxy"
di "for small business formation (correlated with lending outcomes)"

cap keep if year >= 2010 & year <= 2017 & fintech_share != .

* Interactions
cap gen desert_x_fintech = banking_desert * fintech_share

* Small establishment growth as outcome (proxy for new business formation)
cap confirm variable small_estab
if _rc == 0 {
    sort county_fips year
    by county_fips: gen small_growth = (small_estab - small_estab[_n-1]) / small_estab[_n-1] * 100 if _n > 1

    di ""
    di "--- Small Establishment Growth × Banking Access × Fintech ---"
    reghdfe small_growth banking_desert fintech_share desert_x_fintech, ///
        absorb(year) cluster(county_fips)
}

********************************************************************************
* PART 6: Template for SBA Analysis (when data available)
********************************************************************************

di ""
di "=== TEMPLATE FOR SBA LOAN ANALYSIS ==="
di ""
di "When SBA data is available, run:"
di ""
di "1. Load SBA loan data aggregated to county-year"
di "   use sba_loans_county.dta, clear"
di ""
di "2. Merge with fintech and branch data"
di "   merge m:1 county_fips year using fintech_county_clean.dta"
di "   merge m:1 county_fips using banking_access_county.dta"
di ""
di "3. Run regression:"
di "   reghdfe sba_loan_count banking_desert fintech_share desert_x_fintech, ///"
di "       absorb(county_fips year) cluster(county_fips)"
di ""
di "4. Interpretation:"
di "   - Negative desert coefficient: Deserts get fewer SBA loans"
di "   - Positive interaction: Fintech mitigates lending gap in deserts"

********************************************************************************
* PART 7: Template for CRA Analysis
********************************************************************************

di ""
di "=== TEMPLATE FOR CRA LOAN ANALYSIS ==="
di ""
di "When CRA data is available, run:"
di ""
di "1. Load CRA small business lending by county-year"
di "2. Create fintech × low_branch interaction"
di "3. Test: Does fintech increase small business lending in underserved areas?"
di ""
di "Advantage of CRA data:"
di "  - Directly measures bank small business lending"
di "  - Can identify if fintech substitutes for or complements bank lending"
di ""
di "Expected pattern if fintech fills gaps:"
di "  - Bank CRA lending declines with closures"
di "  - Total lending (bank + fintech) declines less in high-fintech areas"

********************************************************************************
* PART 8: Fintech Lender Identification in CRA
********************************************************************************

di ""
di "=== IDENTIFYING FINTECH LENDERS IN CRA DATA ==="
di ""
di "Apply Fuster et al. methodology to CRA data:"
di ""
di "1. Get lender names from CRA transmittal sheets"
di "2. Match to Fuster et al. fintech classification"
di "3. Calculate fintech share of small business lending by county"
di ""
di "Known fintech small business lenders:"
di "  - OnDeck Capital"
di "  - Kabbage (now part of AmEx)"
di "  - Funding Circle"
di "  - LendingClub (small business loans)"
di "  - BlueVine"
di "  - Credibly"
di ""
di "Note: Many fintech lenders are not banks and thus not in CRA data"
di "This limits CRA-based fintech measurement"

********************************************************************************
* PART 9: Summary
********************************************************************************

di ""
di "=== SBA/CRA ANALYSIS SUMMARY ==="
di ""
di "Current status: Framework created, awaiting data download"
di ""
di "Data needed:"
di "  1. SBA 7(a)/504 loan data by county-year (SBA.gov)"
di "  2. CRA small business lending by county-year (FFIEC)"
di ""
di "Expected findings if fintech fills credit gaps:"
di "  - Banking deserts have lower small business lending"
di "  - High-fintech deserts have less lending decline"
di "  - Fintech penetration positively predicts lending in underserved areas"
di ""
di "This would provide completely independent corroboration of the CAPS findings"
di "using administrative lending data rather than survey outcomes."

log close
