********************************************************************************
* FINTECH-STYLE CREDITWORTHINESS ANALYSIS
*
* Purpose: Construct alternative credit scores from CAPS behavioral variables
*          and validate against loan outcomes
*
* Author: Alina Malkova
* Date: February 2026
*
* This do-file implements the research design outlined in the project notes:
* 1. Construct fintech-style credit indices from CAPS individual variables
* 2. Validate indices against actual loan performance (delinquency, default)
* 3. Compare predictive power vs. traditional credit metrics
* 4. Test heterogeneity by geographic environment (banking deserts, fintech, broadband)
* 5. Integrate with branch closure analysis
********************************************************************************

clear all
set more off
set maxvar 32767
set matsize 10000

* Set paths - MODIFY THESE
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/_Research/Financial_Inclusion/Fintech Research"
global data "$root/Data"
global output "$root/Output"
global results "$root/Results"

* Create results folder if needed
cap mkdir "$results"

* Log file
cap log close
log using "$results/fintech_creditworthiness_analysis.log", replace

********************************************************************************
* PART 0: VARIABLE DISCOVERY
* Run this section first to identify available variables in your CAPS data
********************************************************************************

use "$data/caps_geographic_merged.dta", clear

di _n "=============================================="
di "CAPS VARIABLE DISCOVERY"
di "=============================================="

di _n "=== OUTCOME VARIABLES (Loan Performance) ==="
lookfor default delinq foreclos current prepay mortgage late

di _n "=== PAYMENT BEHAVIOR ==="
lookfor hardship difficult behind late miss collect bankrupt utility cut phone

di _n "=== INCOME & EMPLOYMENT ==="
lookfor employ unemp job income work hours tenure wage loss

di _n "=== SAVINGS & ASSETS ==="
lookfor saving check bank asset wealth retire buffer emergency equity

di _n "=== DEBT & HOUSING COSTS ==="
lookfor debt dti ltv payment cost burden ratio mortgage

di _n "=== ALTERNATIVE FINANCIAL SERVICES ==="
lookfor payday pawn rent_to check_cash title afs alternative

di _n "=== STABILITY ==="
lookfor years_at address moved marital married divorce

di _n "=== HUMAN CAPITAL ==="
lookfor educ college degree school

di _n "=== SOCIAL CAPITAL ==="
lookfor community volunteer church relig neighbor trust social civic

di _n "=== DEMOGRAPHICS ==="
lookfor age sex female male race black white hisp

di _n "=== GEOGRAPHY ==="
lookfor zip state county fips msa tract

* Export full variable list
preserve
describe, replace clear
export excel using "$results/caps_variables_inventory.xlsx", firstrow(variables) replace
restore

di _n "Variable inventory exported to: $results/caps_variables_inventory.xlsx"
di "Review this file and update variable names below as needed."
di "=============================================="


********************************************************************************
* PART 1: DATA PREPARATION
* Load data and prepare variables
* NOTE: Variable names below are based on documentation - adjust as needed
********************************************************************************

use "$data/caps_geographic_merged.dta", clear

* Check sample size
di _n "Total observations: " _N
tab year, m

********************************************************************************
* PART 1A: OUTCOME VARIABLES
* Create standardized loan performance outcomes
********************************************************************************

* --- MODIFY VARIABLE NAMES BELOW BASED ON YOUR DATA ---

* Primary outcome: 90+ day delinquency
* Possible names: default90, d90, delinq90, mortgage_default, ever_default
cap gen default_90 = .
* replace default_90 = (YOUR_VARIABLE == 1)

* Secondary outcome: 60+ day delinquency
cap gen default_60 = .
* replace default_60 = (YOUR_VARIABLE == 1)

* Severe outcome: Foreclosure
cap gen foreclosure = .
* replace foreclosure = (YOUR_VARIABLE == 1)

* Good outcome: Loan is current
cap gen loan_current = .
* replace loan_current = (YOUR_VARIABLE == 1)

* Payment difficulty (self-reported)
cap gen payment_difficulty = .
* replace payment_difficulty = (YOUR_VARIABLE == 1)

* --- END MODIFY SECTION ---

* Summary of outcomes
di _n "=== OUTCOME VARIABLE SUMMARY ==="
foreach var in default_90 default_60 foreclosure loan_current payment_difficulty {
    cap sum `var'
    if _rc == 0 {
        di "`var': N = " r(N) ", Mean = " %5.3f r(mean)
    }
}


********************************************************************************
* PART 1B: PREDICTOR VARIABLES BY DOMAIN
* Create standardized predictors for fintech-style scoring
********************************************************************************

* ============================================================================
* DOMAIN 1: PAYMENT BEHAVIOR (Weight: 40% in fintech models)
* ============================================================================

di _n "=== DOMAIN 1: PAYMENT BEHAVIOR ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Utility payment problems
cap gen utility_behind = .
* replace utility_behind = (YOUR_VARIABLE == 1)

cap gen utilities_cutoff = .
* replace utilities_cutoff = (YOUR_VARIABLE == 1)

* Phone/telecom payment problems
cap gen phone_disconnected = .
* replace phone_disconnected = (YOUR_VARIABLE == 1)

* Bill collectors
cap gen bill_collectors = .
* replace bill_collectors = (YOUR_VARIABLE == 1)

* Bankruptcy
cap gen bankruptcy = .
* replace bankruptcy = (YOUR_VARIABLE == 1)

* Judgment against
cap gen judgment = .
* replace judgment = (YOUR_VARIABLE == 1)

* Repossession
cap gen repossession = .
* replace repossession = (YOUR_VARIABLE == 1)

* Prior mortgage delinquency (if available separately from outcome)
cap gen prior_delinquency = .
* replace prior_delinquency = (YOUR_VARIABLE == 1)

* --- END MODIFY SECTION ---

* Create Payment Behavior Index (0-100, higher = better payment behavior)
* Method: Start at 100, deduct for each negative indicator

gen payment_index = 100

* Deductions (adjust weights based on severity)
foreach var in utility_behind utilities_cutoff phone_disconnected ///
               bill_collectors bankruptcy judgment repossession prior_delinquency {
    cap replace payment_index = payment_index - 15 if `var' == 1 & `var' != .
}

* Floor at 0
replace payment_index = 0 if payment_index < 0

* Count of payment problems
egen payment_problems = rowtotal(utility_behind utilities_cutoff phone_disconnected ///
                                  bill_collectors bankruptcy judgment repossession), missing

sum payment_index payment_problems, d


* ============================================================================
* DOMAIN 2: INCOME & EMPLOYMENT STABILITY (Weight: 30%)
* ============================================================================

di _n "=== DOMAIN 2: INCOME STABILITY ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Employment status
cap gen employed = .
* replace employed = (YOUR_VARIABLE == 1)

cap gen unemployed = .
* replace unemployed = (YOUR_VARIABLE == 1)

* Job loss in past year
cap gen job_loss = .
* replace job_loss = (YOUR_VARIABLE == 1)

* Hours reduced
cap gen hours_reduced = .
* replace hours_reduced = (YOUR_VARIABLE == 1)

* Income change (code as: 1=decreased, 0=same/increased)
cap gen income_decreased = .
* replace income_decreased = (YOUR_VARIABLE == 1) if income decreased

* Job tenure (years at current job)
cap gen job_tenure = .
* replace job_tenure = YOUR_VARIABLE

* Irregular income
cap gen irregular_income = .
* replace irregular_income = (YOUR_VARIABLE == 1)

* Multiple income sources (positive signal)
cap gen multiple_income_sources = .
* replace multiple_income_sources = (YOUR_VARIABLE > 1) if YOUR_VARIABLE != .

* --- END MODIFY SECTION ---

* Create Income Stability Index (0-100, higher = more stable)
gen income_index = 100

* Deductions for instability
cap replace income_index = income_index - 30 if job_loss == 1 & job_loss != .
cap replace income_index = income_index - 15 if hours_reduced == 1 & hours_reduced != .
cap replace income_index = income_index - 20 if income_decreased == 1 & income_decreased != .
cap replace income_index = income_index - 10 if irregular_income == 1 & irregular_income != .
cap replace income_index = income_index - 25 if unemployed == 1 & unemployed != .

* Additions for stability
cap replace income_index = income_index + 10 if job_tenure >= 2 & job_tenure != .
cap replace income_index = income_index + 5 if multiple_income_sources == 1 & multiple_income_sources != .

* Bound between 0 and 100
replace income_index = 0 if income_index < 0
replace income_index = 100 if income_index > 100

* Binary stable indicator
gen income_stable = (job_loss != 1 & income_decreased != 1) if job_loss != . | income_decreased != .

sum income_index income_stable, d


* ============================================================================
* DOMAIN 3: FINANCIAL RESILIENCE / BUFFER STOCK (Weight: 20%)
* ============================================================================

di _n "=== DOMAIN 3: FINANCIAL RESILIENCE ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Savings account ownership
cap gen has_savings = .
* replace has_savings = (YOUR_VARIABLE == 1)

* Savings balance (if available)
cap gen savings_balance = .
* replace savings_balance = YOUR_VARIABLE

* Emergency fund
cap gen has_emergency_fund = .
* replace has_emergency_fund = (YOUR_VARIABLE == 1)

* Months of expenses covered
cap gen months_expenses = .
* replace months_expenses = YOUR_VARIABLE

* Retirement account
cap gen has_retirement = .
* replace has_retirement = (YOUR_VARIABLE == 1)

* Health insurance (protective)
cap gen has_health_insurance = .
* replace has_health_insurance = (YOUR_VARIABLE == 1)

* Home equity (can use LTV or equity amount)
cap gen home_equity = .
* replace home_equity = YOUR_VARIABLE

cap gen positive_equity = .
* replace positive_equity = (home_equity > 0) if home_equity != .

* --- END MODIFY SECTION ---

* Create Financial Resilience Index (count of protective factors)
gen resilience_index = 0

foreach var in has_savings has_emergency_fund has_retirement has_health_insurance positive_equity {
    cap replace resilience_index = resilience_index + 20 if `var' == 1 & `var' != .
}

* Additional points for substantial buffer
cap replace resilience_index = resilience_index + 10 if months_expenses >= 2 & months_expenses != .
cap replace resilience_index = resilience_index + 10 if months_expenses >= 6 & months_expenses != .

* Cap at 100
replace resilience_index = 100 if resilience_index > 100

* Binary: Has buffer (2+ months expenses or emergency fund)
gen has_buffer = (months_expenses >= 2 | has_emergency_fund == 1) if months_expenses != . | has_emergency_fund != .

sum resilience_index has_buffer, d


* ============================================================================
* DOMAIN 4: DEBT BURDEN
* ============================================================================

di _n "=== DOMAIN 4: DEBT BURDEN ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Debt-to-income ratio
cap gen dti = .
* replace dti = YOUR_VARIABLE

* Housing cost ratio (housing costs / income)
cap gen housing_cost_ratio = .
* replace housing_cost_ratio = YOUR_VARIABLE

* Cost burdened (>30% on housing)
cap gen cost_burdened = .
* replace cost_burdened = (housing_cost_ratio > 0.30) if housing_cost_ratio != .

* Severely cost burdened (>50% on housing)
cap gen severely_burdened = .
* replace severely_burdened = (housing_cost_ratio > 0.50) if housing_cost_ratio != .

* LTV ratio
cap gen ltv = .
* replace ltv = YOUR_VARIABLE

* Underwater (LTV > 100%)
cap gen underwater = .
* replace underwater = (ltv > 100) if ltv != .

* --- END MODIFY SECTION ---

* Create Debt Burden Index (0-100, higher = lower burden = better)
gen debt_index = 100

cap replace debt_index = debt_index - 20 if cost_burdened == 1 & cost_burdened != .
cap replace debt_index = debt_index - 30 if severely_burdened == 1 & severely_burdened != .
cap replace debt_index = debt_index - 25 if underwater == 1 & underwater != .
cap replace debt_index = debt_index - 15 if dti > 0.43 & dti != .  // QM threshold

replace debt_index = 0 if debt_index < 0

sum debt_index, d


* ============================================================================
* DOMAIN 5: ALTERNATIVE FINANCIAL SERVICES (Negative Signal)
* ============================================================================

di _n "=== DOMAIN 5: AFS USAGE ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Payday loan usage
cap gen payday_loan = .
* replace payday_loan = (YOUR_VARIABLE == 1)

* Pawnshop usage
cap gen pawnshop = .
* replace pawnshop = (YOUR_VARIABLE == 1)

* Rent-to-own
cap gen rent_to_own = .
* replace rent_to_own = (YOUR_VARIABLE == 1)

* Auto title loan
cap gen title_loan = .
* replace title_loan = (YOUR_VARIABLE == 1)

* Check cashing services
cap gen check_cashing = .
* replace check_cashing = (YOUR_VARIABLE == 1)

* --- END MODIFY SECTION ---

* AFS user indicator (any usage)
egen afs_count = rowtotal(payday_loan pawnshop rent_to_own title_loan check_cashing), missing
gen afs_user = (afs_count > 0) if afs_count != .

* AFS Index (0-100, higher = no AFS usage = better)
gen afs_index = 100
cap replace afs_index = afs_index - 20 if payday_loan == 1 & payday_loan != .
cap replace afs_index = afs_index - 15 if pawnshop == 1 & pawnshop != .
cap replace afs_index = afs_index - 15 if rent_to_own == 1 & rent_to_own != .
cap replace afs_index = afs_index - 25 if title_loan == 1 & title_loan != .
cap replace afs_index = afs_index - 10 if check_cashing == 1 & check_cashing != .

replace afs_index = 0 if afs_index < 0

sum afs_index afs_user afs_count, d


* ============================================================================
* DOMAIN 6: STABILITY INDICATORS
* ============================================================================

di _n "=== DOMAIN 6: STABILITY ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Residential stability
cap gen years_at_address = .
* replace years_at_address = YOUR_VARIABLE

cap gen moved_recently = .
* replace moved_recently = (YOUR_VARIABLE == 1)

* Marital stability
cap gen married = .
* replace married = (YOUR_VARIABLE == 1)

cap gen divorced_recently = .
* replace divorced_recently = (YOUR_VARIABLE == 1)

* --- END MODIFY SECTION ---

* Create Stability Index
gen stability_index = 50  // Start at midpoint

cap replace stability_index = stability_index + 20 if years_at_address >= 2 & years_at_address != .
cap replace stability_index = stability_index + 10 if years_at_address >= 5 & years_at_address != .
cap replace stability_index = stability_index - 15 if moved_recently == 1 & moved_recently != .
cap replace stability_index = stability_index + 10 if married == 1 & married != .
cap replace stability_index = stability_index - 20 if divorced_recently == 1 & divorced_recently != .

replace stability_index = 0 if stability_index < 0
replace stability_index = 100 if stability_index > 100

sum stability_index, d


* ============================================================================
* DOMAIN 7: HUMAN CAPITAL
* ============================================================================

di _n "=== DOMAIN 7: HUMAN CAPITAL ==="

* --- MODIFY VARIABLE NAMES BELOW ---

* Education level (years or categorical)
cap gen education_years = .
* replace education_years = YOUR_VARIABLE

cap gen college_degree = .
* replace college_degree = (YOUR_VARIABLE >= 16) | (YOUR_VARIABLE == "Bachelor's" etc.)

cap gen high_school = .
* replace high_school = (education_years >= 12) if education_years != .

* --- END MODIFY SECTION ---

* Education Index (simple version)
gen education_index = 50
cap replace education_index = education_index + 25 if high_school == 1 & high_school != .
cap replace education_index = education_index + 25 if college_degree == 1 & college_degree != .

sum education_index, d


* ============================================================================
* DOMAIN 8: SOCIAL CAPITAL (Can merge from Social Capital Atlas)
* ============================================================================

di _n "=== DOMAIN 8: SOCIAL CAPITAL ==="

* Individual-level from CAPS (if available)
* --- MODIFY VARIABLE NAMES BELOW ---

cap gen community_involvement = .
* replace community_involvement = (YOUR_VARIABLE == 1)

cap gen volunteer = .
* replace volunteer = (YOUR_VARIABLE == 1)

cap gen neighbor_trust = .
* replace neighbor_trust = YOUR_VARIABLE (scale variable)

cap gen social_support = .
* replace social_support = (YOUR_VARIABLE == 1)

* --- END MODIFY SECTION ---

* County-level from Social Capital Atlas (already merged?)
* Check if ec_county (economic connectedness) exists
cap confirm variable ec_county
if _rc == 0 {
    di "Social Capital Atlas variables found in data"
    sum ec_county, d
}

* Create Social Capital Index (individual level)
gen social_index = 50
cap replace social_index = social_index + 15 if community_involvement == 1 & community_involvement != .
cap replace social_index = social_index + 10 if volunteer == 1 & volunteer != .
cap replace social_index = social_index + 15 if social_support == 1 & social_support != .

replace social_index = 100 if social_index > 100

sum social_index, d


********************************************************************************
* PART 2: COMPOSITE FINTECH CREDITWORTHINESS INDICES
********************************************************************************

di _n "=============================================="
di "PART 2: COMPOSITE INDEX CONSTRUCTION"
di "=============================================="

* ============================================================================
* APPROACH 1: WEIGHTED COMPOSITE (Based on fintech literature)
* ============================================================================

* Weights from fintech credit scoring literature:
* - Payment behavior: 40% (strongest predictor)
* - Income stability: 25%
* - Financial resilience: 15%
* - Debt burden: 10%
* - Other (education, stability, AFS): 10%

gen fintech_score_weighted = 0.40 * payment_index + ///
                             0.25 * income_index + ///
                             0.15 * resilience_index + ///
                             0.10 * debt_index + ///
                             0.05 * stability_index + ///
                             0.03 * education_index + ///
                             0.02 * (100 - afs_user*100)

label var fintech_score_weighted "Fintech Creditworthiness Score (Weighted Composite)"

sum fintech_score_weighted, d


* ============================================================================
* APPROACH 2: SIMPLE ADDITIVE INDEX (Equal weights)
* ============================================================================

* Standardize each component to 0-1
foreach var in payment_index income_index resilience_index debt_index ///
               stability_index education_index afs_index social_index {
    cap gen `var'_std = `var' / 100
}

* Simple average of available components
egen fintech_score_simple = rowmean(payment_index_std income_index_std ///
                                     resilience_index_std debt_index_std ///
                                     stability_index_std education_index_std ///
                                     afs_index_std)

* Scale to 0-100
replace fintech_score_simple = fintech_score_simple * 100

label var fintech_score_simple "Fintech Creditworthiness Score (Simple Average)"

sum fintech_score_simple, d


* ============================================================================
* APPROACH 3: PRINCIPAL COMPONENTS ANALYSIS
* ============================================================================

* PCA on component indices
cap pca payment_index income_index resilience_index debt_index ///
        stability_index education_index afs_index social_index

if _rc == 0 {
    * Extract first principal component
    predict fintech_score_pca, score

    * Rescale to 0-100 for interpretability
    sum fintech_score_pca
    gen fintech_score_pca_scaled = (fintech_score_pca - r(min)) / (r(max) - r(min)) * 100

    label var fintech_score_pca_scaled "Fintech Score (PCA-based)"

    sum fintech_score_pca_scaled, d
}


* ============================================================================
* APPROACH 4: PAYMENT-FOCUSED INDEX (Mimics rent/utility reporting)
* ============================================================================

* This index focuses on payment behavior - what Experian Boost and similar products use

gen fintech_score_payment = 100

* Heavy weight on payment history
replace fintech_score_payment = fintech_score_payment - 25 if utility_behind == 1
replace fintech_score_payment = fintech_score_payment - 20 if utilities_cutoff == 1
replace fintech_score_payment = fintech_score_payment - 15 if phone_disconnected == 1
replace fintech_score_payment = fintech_score_payment - 30 if bill_collectors == 1
replace fintech_score_payment = fintech_score_payment - 40 if bankruptcy == 1

* Moderate weight on stability
replace fintech_score_payment = fintech_score_payment - 20 if job_loss == 1
replace fintech_score_payment = fintech_score_payment - 10 if income_decreased == 1

* Buffer provides protection
replace fintech_score_payment = fintech_score_payment + 15 if has_buffer == 1
replace fintech_score_payment = fintech_score_payment + 10 if has_savings == 1

* AFS usage is warning sign
replace fintech_score_payment = fintech_score_payment - 15 if afs_user == 1

* Bound
replace fintech_score_payment = 0 if fintech_score_payment < 0
replace fintech_score_payment = 100 if fintech_score_payment > 100

label var fintech_score_payment "Fintech Score (Payment-Focused)"

sum fintech_score_payment, d


* Create score terciles for heterogeneity analysis
foreach score in fintech_score_weighted fintech_score_simple fintech_score_payment {
    cap xtile `score'_tercile = `score', nq(3)
    cap label define tercile_lbl 1 "Low" 2 "Medium" 3 "High"
    cap label values `score'_tercile tercile_lbl
}


********************************************************************************
* PART 3: VALIDATE INDICES AGAINST LOAN OUTCOMES
********************************************************************************

di _n "=============================================="
di "PART 3: VALIDATION AGAINST LOAN OUTCOMES"
di "=============================================="

* ============================================================================
* 3A: DESCRIPTIVE COMPARISON BY SCORE TERCILE
* ============================================================================

di _n "=== Default Rates by Fintech Score Tercile ==="

* This shows whether the fintech score predicts default
cap tab fintech_score_weighted_tercile, sum(default_90)
cap tab fintech_score_payment_tercile, sum(default_90)


* ============================================================================
* 3B: PREDICTIVE REGRESSIONS
* ============================================================================

di _n "=== PREDICTIVE REGRESSIONS ==="

* Store results
cap estimates clear

* Model 1: Fintech Score Only
cap logit default_90 fintech_score_weighted, cluster(county_fips)
if _rc == 0 {
    estimates store m1_fintech
    di "Model 1 (Fintech Score): pseudo-R2 = " e(r2_p)
}

* Model 2: Traditional Metrics Only (if credit score available)
cap logit default_90 dti ltv, cluster(county_fips)
if _rc == 0 {
    estimates store m2_traditional
    di "Model 2 (DTI + LTV): pseudo-R2 = " e(r2_p)
}

* Model 3: Combined
cap logit default_90 fintech_score_weighted dti ltv, cluster(county_fips)
if _rc == 0 {
    estimates store m3_combined
    di "Model 3 (Combined): pseudo-R2 = " e(r2_p)
}

* Model 4: Full fintech-style model with component indices
cap logit default_90 payment_index income_index resilience_index ///
                     debt_index stability_index afs_user, cluster(county_fips)
if _rc == 0 {
    estimates store m4_components
    di "Model 4 (Components): pseudo-R2 = " e(r2_p)
}

* Output regression table
cap esttab m1_fintech m2_traditional m3_combined m4_components ///
    using "$results/creditworthiness_validation.csv", replace ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N r2_p, fmt(0 3) labels("Observations" "Pseudo R-squared")) ///
    title("Predicting Mortgage Default with Fintech-Style Scores") ///
    mtitles("Fintech Score" "Traditional" "Combined" "Components")


* ============================================================================
* 3C: ROC CURVES AND AUC COMPARISON
* ============================================================================

di _n "=== ROC/AUC ANALYSIS ==="

* Compare predictive accuracy using AUC
cap {
    * Fintech score
    logit default_90 fintech_score_weighted
    lroc, nograph
    local auc_fintech = r(area)

    * Traditional (DTI only as baseline)
    logit default_90 dti
    lroc, nograph
    local auc_dti = r(area)

    * Combined
    logit default_90 fintech_score_weighted dti
    lroc, nograph
    local auc_combined = r(area)

    di _n "AUC Comparison:"
    di "  Fintech Score Only:  " %5.3f `auc_fintech'
    di "  DTI Only:            " %5.3f `auc_dti'
    di "  Combined:            " %5.3f `auc_combined'
    di "  Improvement:         " %5.3f (`auc_combined' - `auc_dti')
}


* ============================================================================
* 3D: LIKELIHOOD RATIO TEST - Does Fintech Add Predictive Power?
* ============================================================================

di _n "=== LIKELIHOOD RATIO TEST ==="

* Nested model comparison
cap {
    * Restricted model (traditional only)
    quietly logit default_90 dti ltv
    estimates store restricted

    * Unrestricted model (add fintech score)
    quietly logit default_90 dti ltv fintech_score_weighted
    estimates store unrestricted

    * LR test
    lrtest restricted unrestricted

    di _n "LR Test: Does fintech score add predictive power?"
    di "Chi-squared = " r(chi2) ", p-value = " r(p)
}


********************************************************************************
* PART 4: GEOGRAPHIC HETEROGENEITY
* Test whether fintech-style scores have greater predictive power in
* areas with limited traditional banking access
********************************************************************************

di _n "=============================================="
di "PART 4: GEOGRAPHIC HETEROGENEITY"
di "=============================================="

* ============================================================================
* 4A: HETEROGENEITY BY BANKING DESERT STATUS
* ============================================================================

di _n "=== Heterogeneity by Banking Desert ==="

* Check if banking desert variable exists
cap confirm variable banking_desert
if _rc != 0 {
    * Create from branch density if available
    cap gen banking_desert = (branches_per_10k < 1) if branches_per_10k != .
}

* Interact fintech score with banking desert
cap logit default_90 c.fintech_score_weighted##i.banking_desert, cluster(county_fips)
if _rc == 0 {
    estimates store het_desert
    margins banking_desert, dydx(fintech_score_weighted)
    marginsplot, title("Marginal Effect of Fintech Score by Banking Desert Status")
    graph export "$output/het_banking_desert.png", replace
}

* Separate regressions by banking desert
di _n "--- Non-Desert Counties ---"
cap logit default_90 fintech_score_weighted if banking_desert == 0, cluster(county_fips)
if _rc == 0 di "Coefficient: " _b[fintech_score_weighted] ", N = " e(N)

di _n "--- Banking Desert Counties ---"
cap logit default_90 fintech_score_weighted if banking_desert == 1, cluster(county_fips)
if _rc == 0 di "Coefficient: " _b[fintech_score_weighted] ", N = " e(N)


* ============================================================================
* 4B: HETEROGENEITY BY FINTECH PENETRATION
* ============================================================================

di _n "=== Heterogeneity by Fintech Penetration ==="

* Check for fintech share variable
cap confirm variable fintech_share
if _rc == 0 {

    * Create high/low fintech indicator
    sum fintech_share, d
    gen high_fintech = (fintech_share > r(p50)) if fintech_share != .

    * Interaction model
    cap logit default_90 c.fintech_score_weighted##c.fintech_share, cluster(county_fips)
    if _rc == 0 {
        estimates store het_fintech

        * Margins at different fintech levels
        margins, dydx(fintech_score_weighted) at(fintech_share = (0.02 0.04 0.06 0.08))
        marginsplot, title("Marginal Effect by County Fintech Penetration")
        graph export "$output/het_fintech_share.png", replace
    }

    * Separate regressions
    di _n "--- Low Fintech Counties ---"
    cap logit default_90 fintech_score_weighted if high_fintech == 0, cluster(county_fips)

    di _n "--- High Fintech Counties ---"
    cap logit default_90 fintech_score_weighted if high_fintech == 1, cluster(county_fips)
}


* ============================================================================
* 4C: HETEROGENEITY BY BROADBAND ACCESS
* ============================================================================

di _n "=== Heterogeneity by Broadband Access ==="

cap confirm variable broadband_pct
if _rc == 0 {

    sum broadband_pct, d
    gen high_broadband = (broadband_pct > r(p50)) if broadband_pct != .

    * Interaction model
    cap logit default_90 c.fintech_score_weighted##c.broadband_pct, cluster(county_fips)
    if _rc == 0 {
        estimates store het_broadband
    }

    di _n "--- Low Broadband Counties ---"
    cap logit default_90 fintech_score_weighted if high_broadband == 0, cluster(county_fips)

    di _n "--- High Broadband Counties ---"
    cap logit default_90 fintech_score_weighted if high_broadband == 1, cluster(county_fips)
}


* ============================================================================
* 4D: TRIPLE INTERACTION - Where Does Fintech Scoring Matter Most?
* ============================================================================

di _n "=== Triple Interaction: Banking Desert × High Broadband ==="

* Fintech scoring should matter most in: banking deserts WITH broadband access
* (where fintech could help but traditional banks are absent)

cap gen desert_broadband = banking_desert * high_broadband

cap logit default_90 c.fintech_score_weighted##i.banking_desert##i.high_broadband, ///
    cluster(county_fips)
if _rc == 0 {
    estimates store triple

    * Margins by combination
    margins banking_desert#high_broadband, dydx(fintech_score_weighted)
}


********************************************************************************
* PART 5: INTEGRATION WITH BRANCH CLOSURE ANALYSIS
* Test: Do individuals with high fintech scores experience smaller
* negative effects from branch closures?
********************************************************************************

di _n "=============================================="
di "PART 5: BRANCH CLOSURE INTERACTION"
di "=============================================="

* ============================================================================
* 5A: BASELINE BRANCH CLOSURE EFFECT
* ============================================================================

di _n "=== Baseline: Branch Closure Effect on Self-Employment ==="

* Check for key variables
cap confirm variable closure_zip
cap confirm variable anytoise  // Transition to incorporated self-employment

if _rc == 0 {

    * Baseline closure effect
    cap reghdfe anytoise closure_zip, absorb(mergerID year) cluster(county_fips)
    if _rc == 0 {
        estimates store base_closure
        di "Baseline closure effect: " _b[closure_zip]
    }
}


* ============================================================================
* 5B: FINTECH SCORE × CLOSURE INTERACTION
* ============================================================================

di _n "=== Fintech Score × Branch Closure Interaction ==="

* Key test: Do individuals with characteristics fintech values (high fintech score)
* experience smaller losses from branch closures?

cap {
    * Create standardized score for interaction
    sum fintech_score_weighted
    gen fintech_score_std = (fintech_score_weighted - r(mean)) / r(sd)

    * Interaction model
    reghdfe anytoise closure_zip c.closure_zip#c.fintech_score_std, ///
            absorb(mergerID year) cluster(county_fips)
    estimates store closure_fintech

    di _n "Closure main effect: " _b[closure_zip]
    di "Closure × Fintech Score: " _b[c.closure_zip#c.fintech_score_std]

    * Interpretation:
    * - Negative main effect = closures hurt self-employment
    * - Positive interaction = high fintech score individuals less affected
}


* ============================================================================
* 5C: COMPONENT-LEVEL INTERACTIONS
* ============================================================================

di _n "=== Component-Level Interactions ==="

* Which specific characteristics buffer against closure effects?

foreach component in payment_index income_index resilience_index has_buffer afs_user {

    cap {
        sum `component'
        gen `component'_std = (`component' - r(mean)) / r(sd)

        reghdfe anytoise closure_zip c.closure_zip#c.`component'_std, ///
                absorb(mergerID year) cluster(county_fips)

        di "`component': interaction coef = " _b[c.closure_zip#c.`component'_std] ///
           " (SE = " _se[c.closure_zip#c.`component'_std] ")"

        drop `component'_std
    }
}


* ============================================================================
* 5D: HETEROGENEITY: Closure × Fintech Score × Geographic Environment
* ============================================================================

di _n "=== Three-Way Interaction: Closure × Score × Geography ==="

* Test whether the fintech score buffering effect is stronger in:
* - Banking deserts (where soft info is lost)
* - High-fintech areas (where fintech is available)
* - High-broadband areas (where digital access enables fintech)

cap {
    * Closure × Fintech Score × Banking Desert
    reghdfe anytoise c.closure_zip##c.fintech_score_std##i.banking_desert, ///
            absorb(mergerID year) cluster(county_fips)
    estimates store triple_desert

    * Closure × Fintech Score × High Fintech Area
    reghdfe anytoise c.closure_zip##c.fintech_score_std##i.high_fintech, ///
            absorb(mergerID year) cluster(county_fips)
    estimates store triple_fintech
}


********************************************************************************
* PART 6: CREDIT EXPANSION ANALYSIS
* How many "good" borrowers would traditional scoring miss?
********************************************************************************

di _n "=============================================="
di "PART 6: CREDIT EXPANSION ANALYSIS"
di "=============================================="

* ============================================================================
* 6A: IDENTIFY MISCLASSIFIED BORROWERS
* ============================================================================

di _n "=== Credit Expansion Potential ==="

* Define "high risk" by traditional metrics vs fintech score
* Assume DTI > 43% is traditional rejection threshold (QM rule)

cap {
    gen trad_reject = (dti > 0.43) if dti != .

    * High fintech score (top 50%)
    sum fintech_score_weighted, d
    gen fintech_approve = (fintech_score_weighted > r(p50)) if fintech_score_weighted != .

    * Actual outcome
    * good_outcome = did not default
    gen good_outcome = (default_90 == 0) if default_90 != .

    * Misclassification matrix
    di _n "=== Classification Matrix ==="
    di "Rows: Traditional decision (reject/approve)"
    di "Cols: Fintech decision (reject/approve)"
    tab trad_reject fintech_approve, row col

    * Focus on disagreements
    di _n "=== Disagreement Analysis ==="

    * Type 1: Trad rejects but Fintech would approve
    gen expansion_candidate = (trad_reject == 1 & fintech_approve == 1)
    sum good_outcome if expansion_candidate == 1
    di "Expansion candidates (Trad reject, Fintech approve):"
    di "  N = " r(N)
    di "  Good outcome rate = " %5.1f r(mean)*100 "%"

    * Type 2: Trad approves but Fintech would reject (additional risk flagged)
    gen risk_flagged = (trad_reject == 0 & fintech_approve == 0)
    sum good_outcome if risk_flagged == 1
    di _n "Risk flagged (Trad approve, Fintech reject):"
    di "  N = " r(N)
    di "  Good outcome rate = " %5.1f r(mean)*100 "%"

    * Comparison: Outcome rates
    di _n "=== Outcome Rates by Classification ==="
    tab trad_reject fintech_approve, sum(good_outcome)
}


* ============================================================================
* 6B: CREDIT EXPANSION IN BANKING DESERTS
* ============================================================================

di _n "=== Credit Expansion in Banking Deserts ==="

cap {
    * In banking deserts, how many good borrowers are being missed?
    sum expansion_candidate if banking_desert == 1
    local n_desert_expand = r(sum)
    local pct_desert = r(mean) * 100

    sum good_outcome if expansion_candidate == 1 & banking_desert == 1
    local good_rate_desert = r(mean) * 100

    di "In banking deserts:"
    di "  Expansion candidates: " `n_desert_expand' " (" %4.1f `pct_desert' "% of desert sample)"
    di "  Of these, " %4.1f `good_rate_desert' "% have good outcomes"
}


********************************************************************************
* PART 7: SAVE RESULTS AND CREATE OUTPUT
********************************************************************************

di _n "=============================================="
di "PART 7: SAVE AND OUTPUT"
di "=============================================="

* ============================================================================
* 7A: SAVE ANALYSIS DATASET
* ============================================================================

* Keep key variables
keep id year county_fips ///
     /* Outcomes */ default_90 default_60 foreclosure loan_current ///
     /* Component indices */ payment_index income_index resilience_index ///
                            debt_index stability_index afs_index social_index ///
     /* Composite scores */ fintech_score_weighted fintech_score_simple ///
                           fintech_score_payment fintech_score_pca_scaled ///
     /* Key predictors */ payment_problems income_stable has_buffer afs_user ///
     /* Geographic */ banking_desert high_fintech high_broadband fintech_share ///
     /* Branch closure */ closure_zip anytoise ///
     /* Demographics */ age female black hispanic married college_degree

compress
save "$results/caps_fintech_scores.dta", replace
di "Analysis dataset saved: $results/caps_fintech_scores.dta"


* ============================================================================
* 7B: SUMMARY TABLE
* ============================================================================

di _n "=== SUMMARY TABLE ==="

* Correlation of scores with outcomes
di _n "Correlation with Default (expected negative):"
foreach score in fintech_score_weighted fintech_score_simple fintech_score_payment {
    cap corr `score' default_90
    if _rc == 0 {
        di "  `score': r = " %6.3f r(rho)
    }
}

* Score distributions
di _n "Score Distributions:"
sum fintech_score_weighted fintech_score_simple fintech_score_payment, d


* ============================================================================
* 7C: EXPORT TABLES
* ============================================================================

* Export coefficient comparison table
cap esttab m1_fintech m2_traditional m3_combined m4_components ///
           het_desert het_fintech ///
    using "$results/all_regressions.tex", replace ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N r2_p, fmt(0 3)) ///
    title("Fintech Creditworthiness Analysis") ///
    star(* 0.10 ** 0.05 *** 0.01)


********************************************************************************
* WRAP UP
********************************************************************************

di _n "=============================================="
di "ANALYSIS COMPLETE"
di "=============================================="
di _n "Output files:"
di "  $results/caps_variables_inventory.xlsx"
di "  $results/caps_fintech_scores.dta"
di "  $results/creditworthiness_validation.csv"
di "  $results/all_regressions.tex"
di "  $results/fintech_creditworthiness_analysis.log"
di _n "Figures:"
di "  $output/het_banking_desert.png"
di "  $output/het_fintech_share.png"

log close

********************************************************************************
* END OF DO-FILE
********************************************************************************
