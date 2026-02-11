********************************************************************************
* Project: Fintech Creditworthiness Assessment
* Purpose: Construct fintech-style credit scores from CAPS variables
* Author:  Alina Malkova
* Date:    February 2026
*
* This do-file creates alternative creditworthiness measures using
* non-traditional data, mimicking fintech lender scoring methods.
********************************************************************************

clear all
set more off
cap log close

* Set paths
global root "/Users/amalkova/Library/CloudStorage/OneDrive-FloridaInstituteofTechnology/JMP/Fintech Research"
global data "$root/Data"
global results "$root/Results"
global dofiles "$root/Do-files"

log using "$dofiles/03_fintech_credit_scores.log", replace

* Load merged dataset
use "$data/caps_fintech_merged.dta", clear

********************************************************************************
* IMPORTANT: MODIFY VARIABLE NAMES TO MATCH YOUR CAPS DATA
*
* Review your CAPS codebook and replace placeholder variable names below
* with actual variable names from your dataset.
********************************************************************************

********************************************************************************
* DOMAIN 1: PAYMENT BEHAVIOR INDEX
*
* Payment history on non-credit obligations is the strongest fintech predictor.
* TransUnion found rent reporting increases scores by ~60 points.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* Examples from typical CAPS variables:

* Mortgage payment difficulty
* cap rename your_mortgage_late_var mortgage_late
* cap rename your_mortgage_30day_var delinq_30
* cap rename your_mortgage_60day_var delinq_60
* cap rename your_mortgage_90day_var delinq_90

* Utility/bill payments
* cap rename your_utility_behind_var utility_behind
* cap rename your_phone_cutoff_var phone_cutoff

* Financial distress
* cap rename your_bill_collectors_var bill_collectors
* cap rename your_bankruptcy_var bankruptcy

* --- CREATE PAYMENT BEHAVIOR SCORE ---

* Initialize score (0-100 scale, higher = better payment history)
gen payment_score = 100

* Deduct points for negative payment behaviors
* UNCOMMENT AND MODIFY based on your available variables:

* replace payment_score = payment_score - 30 if delinq_90 == 1
* replace payment_score = payment_score - 20 if delinq_60 == 1
* replace payment_score = payment_score - 15 if delinq_30 == 1
* replace payment_score = payment_score - 20 if utility_behind == 1
* replace payment_score = payment_score - 15 if bill_collectors == 1
* replace payment_score = payment_score - 25 if bankruptcy == 1
* replace payment_score = payment_score - 10 if phone_cutoff == 1

label var payment_score "Payment Behavior Score (0-100)"

********************************************************************************
* DOMAIN 2: INCOME STABILITY INDEX
*
* Income volatility is key - fintech analyzes cash flow patterns.
* Regular deposits from same employer indicate reliability.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_job_loss_var job_loss
* cap rename your_hours_reduced_var hours_reduced
* cap rename your_income_change_var income_change
* cap rename your_job_tenure_var job_tenure
* cap rename your_employed_var employed

* --- CREATE INCOME STABILITY MEASURES ---

* Income shock indicator
gen income_shock = 0
* replace income_shock = 1 if job_loss == 1
* replace income_shock = 1 if hours_reduced == 1
* replace income_shock = 1 if income_change < 0
label var income_shock "Experienced negative income shock"

* Employment stability (2+ years at job)
gen emp_stable = .
* replace emp_stable = (job_tenure >= 2) if job_tenure != .
label var emp_stable "Employed 2+ years at current job"

* Income stability score (0-100)
gen income_score = 100
* replace income_score = income_score - 40 if job_loss == 1
* replace income_score = income_score - 20 if hours_reduced == 1
* replace income_score = income_score - 15 if income_change < 0
* replace income_score = income_score + 10 if job_tenure >= 5
label var income_score "Income Stability Score (0-100)"

********************************************************************************
* DOMAIN 3: FINANCIAL RESILIENCE / BUFFER STOCK
*
* Savings buffer strongly predicts loan repayment.
* Having 2-3 months expenses in savings is protective.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_savings_account_var has_savings
* cap rename your_savings_amount_var savings_amount
* cap rename your_checking_account_var has_checking
* cap rename your_emergency_fund_var emergency_fund
* cap rename your_retirement_account_var has_retirement

* --- CREATE BUFFER MEASURES ---

* Has any savings
gen has_buffer = 0
* replace has_buffer = 1 if has_savings == 1 & savings_amount > 0
label var has_buffer "Has positive savings buffer"

* Months of expenses covered (if available)
* gen months_covered = savings_amount / monthly_expenses
* label var months_covered "Months of expenses covered by savings"

* Financial resilience score (count of positive indicators)
gen resilience_score = 0
* replace resilience_score = resilience_score + 25 if has_savings == 1
* replace resilience_score = resilience_score + 25 if has_checking == 1
* replace resilience_score = resilience_score + 25 if has_retirement == 1
* replace resilience_score = resilience_score + 25 if emergency_fund == 1
label var resilience_score "Financial Resilience Score (0-100)"

********************************************************************************
* DOMAIN 4: DEBT BURDEN
*
* Traditional debt-to-income, plus housing cost burden.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_mortgage_payment_var mortgage_pmt
* cap rename your_household_income_var hh_income
* cap rename your_total_debt_var total_debt

* --- CREATE DEBT BURDEN MEASURES ---

* Housing cost burden
gen housing_burden = .
* replace housing_burden = (mortgage_pmt * 12) / hh_income if hh_income > 0
label var housing_burden "Housing cost to income ratio"

* Cost burdened indicator (>30% of income)
gen cost_burdened = .
* replace cost_burdened = (housing_burden > 0.30) if housing_burden != .
label var cost_burdened "Housing costs > 30% of income"

* Severely burdened (>50%)
gen severely_burdened = .
* replace severely_burdened = (housing_burden > 0.50) if housing_burden != .
label var severely_burdened "Housing costs > 50% of income"

********************************************************************************
* DOMAIN 5: ALTERNATIVE FINANCIAL SERVICES USAGE
*
* Use of payday loans, pawnshops indicates credit constraints.
* These are NEGATIVE signals but also identify underserved population.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_payday_loan_var payday_loan
* cap rename your_pawnshop_var pawnshop
* cap rename your_rent_to_own_var rent_to_own
* cap rename your_check_cashing_var check_cashing
* cap rename your_title_loan_var title_loan

* --- CREATE AFS INDICATORS ---

* Any alternative financial service use
gen afs_user = 0
* replace afs_user = 1 if payday_loan == 1
* replace afs_user = 1 if pawnshop == 1
* replace afs_user = 1 if rent_to_own == 1
* replace afs_user = 1 if title_loan == 1
label var afs_user "Used alternative financial services"

* AFS intensity (count)
gen afs_count = 0
* replace afs_count = payday_loan + pawnshop + rent_to_own + title_loan
label var afs_count "Number of AFS types used"

********************************************************************************
* DOMAIN 6: STABILITY INDICATORS
*
* Residential and family stability correlate with creditworthiness.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_years_at_address_var years_address
* cap rename your_married_var married
* cap rename your_moved_var moved_recently

* --- CREATE STABILITY MEASURES ---

* Residential stability
gen residential_stable = .
* replace residential_stable = (years_address >= 2) if years_address != .
label var residential_stable "At address 2+ years"

* Stability score
gen stability_score = 0
* replace stability_score = stability_score + 50 if residential_stable == 1
* replace stability_score = stability_score + 50 if married == 1
label var stability_score "Stability Score (0-100)"

********************************************************************************
* DOMAIN 7: HUMAN CAPITAL
*
* Upstart pioneered using education. Correlates with earnings trajectory.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_education_var education
* cap rename your_college_var college_degree

* --- CREATE EDUCATION MEASURES ---

gen college = .
* replace college = (education >= 4) if education != .  // Adjust coding
label var college "Has college degree"

********************************************************************************
* DOMAIN 8: SOCIAL CAPITAL (Unique to CAPS)
*
* Community ties may indicate stability and informal support networks.
********************************************************************************

* --- MODIFY THESE VARIABLE NAMES ---
* cap rename your_community_var community_involved
* cap rename your_volunteer_var volunteer
* cap rename your_church_var church_attend
* cap rename your_neighbor_trust_var neighbor_trust

* --- CREATE SOCIAL CAPITAL MEASURES ---

gen social_capital = 0
* replace social_capital = social_capital + 1 if community_involved == 1
* replace social_capital = social_capital + 1 if volunteer == 1
* replace social_capital = social_capital + 1 if church_attend == 1
* replace social_capital = social_capital + 1 if neighbor_trust >= 3  // high trust
label var social_capital "Social Capital Index (0-4)"

********************************************************************************
* COMPOSITE FINTECH CREDIT SCORE
*
* Combine domains with weights based on fintech literature.
* Payment behavior is most important, followed by income stability.
********************************************************************************

* Standardize component scores
foreach var in payment_score income_score resilience_score stability_score {
    cap egen `var'_std = std(`var')
}

* Composite fintech score (weighted average)
* Weights based on fintech research:
*   - Payment behavior: 40%
*   - Income stability: 30%
*   - Financial resilience: 20%
*   - Stability: 10%

gen fintech_score = .
* replace fintech_score = 0.40 * payment_score_std + ///
*                         0.30 * income_score_std + ///
*                         0.20 * resilience_score_std + ///
*                         0.10 * stability_score_std

label var fintech_score "Composite Fintech Credit Score (standardized)"

* Create fintech score percentiles
* xtile fintech_pctile = fintech_score, nq(100)
* label var fintech_pctile "Fintech Score Percentile"

* Create fintech risk categories
gen fintech_risk = .
* replace fintech_risk = 1 if fintech_pctile <= 20  // High risk
* replace fintech_risk = 2 if fintech_pctile > 20 & fintech_pctile <= 40
* replace fintech_risk = 3 if fintech_pctile > 40 & fintech_pctile <= 60
* replace fintech_risk = 4 if fintech_pctile > 60 & fintech_pctile <= 80
* replace fintech_risk = 5 if fintech_pctile > 80  // Low risk
label var fintech_risk "Fintech Risk Category (1=High, 5=Low)"

********************************************************************************
* FINTECH "READINESS" FOR BRANCH CLOSURE ANALYSIS
*
* Create indicator for whether borrower would likely qualify
* for fintech credit based on alternative scoring.
********************************************************************************

* Fintech-ready: Above median on composite score
egen fintech_median = median(fintech_score)
gen fintech_ready = (fintech_score > fintech_median) if fintech_score != .
label var fintech_ready "Above median fintech score (fintech-ready)"

* Alternative: Based on key indicators
gen fintech_eligible = 0
* replace fintech_eligible = 1 if payment_score >= 70 & ///
*                                 income_shock == 0 & ///
*                                 has_buffer == 1
label var fintech_eligible "Likely fintech-eligible based on alt data"

********************************************************************************
* VALIDATION: COMPARE TO ACTUAL LOAN OUTCOMES
********************************************************************************

* Define default outcome (MODIFY to match your CAPS variable)
* cap rename your_default_var default_90

* Predictive comparison
di "=== Comparing Predictive Power ==="

* Model 1: Traditional (if you have credit score)
* logit default_90 credit_score, cluster(county_fips)
* est store traditional

* Model 2: Fintech-style
* logit default_90 payment_score income_score resilience_score, cluster(county_fips)
* est store fintech

* Model 3: Combined
* logit default_90 credit_score payment_score income_score resilience_score, cluster(county_fips)
* est store combined

* Compare AUC/ROC
* lroc, nograph
* estat classification

********************************************************************************
* SUMMARY STATISTICS
********************************************************************************

di "=== Fintech Score Components - Summary Statistics ==="
sum payment_score income_score resilience_score stability_score fintech_score

di "=== Fintech Score by Demographics ==="
* table female, stat(mean fintech_score) stat(sd fintech_score)
* table black, stat(mean fintech_score) stat(sd fintech_score)
* table college, stat(mean fintech_score) stat(sd fintech_score)

di "=== Default Rates by Fintech Risk Category ==="
* table fintech_risk, stat(mean default_90) stat(n default_90)

********************************************************************************
* SAVE DATASET WITH FINTECH SCORES
********************************************************************************

compress
save "$data/caps_fintech_scores.dta", replace

di "=== Fintech Score Construction Complete ==="
di "Output saved to: $data/caps_fintech_scores.dta"

log close

********************************************************************************
* END OF FILE
********************************************************************************
