********************************************************************************
* CAPS VARIABLE MAPPING
*
* Maps actual CAPS variable names to the fintech creditworthiness framework
* Run this AFTER loading the data and BEFORE constructing indices
*
* Based on variable discovery from 05_fintech_creditworthiness_analysis.do
********************************************************************************

* ============================================================================
* OUTCOME VARIABLES
* ============================================================================

* Mortgage delinquency - primary outcome
* delayedmort = "THERE HAS BEEN A TIME PUT OFF PAYING MORTGAGE"
gen default_90 = (delayedmort == 1) if delayedmort != .
label var default_90 "Ever delayed mortgage payment"

* Severity of delinquency on refinanced mortgage
gen default_severe = (severdelinrefiloan >= 3) if severdelinrefiloan != .
label var default_severe "Severe delinquency (90+ days)"

* Times delayed mortgage
gen times_delayed = timesdelayedmort if timesdelayedmort != .
label var times_delayed "Number of times delayed mortgage"

* ============================================================================
* DOMAIN 1: PAYMENT BEHAVIOR
* ============================================================================

* Late payment fees
gen penalized_late = (penlatepaycc == 1) if penlatepaycc != .
label var penalized_late "Penalized for late credit card payment"

* Difficulty paying mortgage
gen payment_difficulty = (delayedmort == 1) if delayedmort != .
label var payment_difficulty "Had difficulty paying mortgage"

* Refinance delinquency
gen prior_delinquency = (latpayrefiloan == 1) if latpayrefiloan != .
label var prior_delinquency "Late paying refinanced mortgage"

* ============================================================================
* DOMAIN 2: INCOME & EMPLOYMENT
* ============================================================================

* Employment status
gen employed = (working == 1) if working != .
label var employed "Currently working for pay"

* Job loss / layoff
gen job_loss = (layoff == 1) if layoff != .
label var job_loss "Lost full weeks of work"

* Same employer (stability)
gen same_employer = (sameempl == 1) if sameempl != .
label var same_employer "Working continuously with same employer"

* Job tenure (in months)
gen job_tenure_months = d_currempr if d_currempr != .
gen job_tenure = job_tenure_months / 12  // Convert to years
label var job_tenure "Years with current employer"

* Times out of work
gen times_unemployed = timesoutofwork_e if timesoutofwork_e != .
label var times_unemployed "Times out of work from layoff"

* Looking for work (unemployed)
gen unemployed = (lookforwork == 1) if lookforwork != .
label var unemployed "Currently looking for work"

* Multiple jobs
gen multiple_jobs = (numjobs > 1) if numjobs != .
label var multiple_jobs "Has more than one job"

* ============================================================================
* DOMAIN 3: FINANCIAL RESILIENCE / BUFFER
* ============================================================================

* Emergency money > monthly mortgage
gen has_emergency_fund = (savamt1 == 1) if savamt1 != .
label var has_emergency_fund "Can get emergency money > monthly mortgage"

* Emergency money > 2x monthly mortgage
gen has_large_buffer = (savamt2 == 1) if savamt2 != .
label var has_large_buffer "Can get emergency money > 2x monthly mortgage"

* Family/friend can lend emergency money
gen has_social_safety = (famlend == 1) if famlend != .
label var has_social_safety "Friend/family can lend emergency money"

* Home equity
gen home_equity = d_currhomeq if d_currhomeq != .
gen positive_equity = (home_equity > 0) if home_equity != .
label var home_equity "Current home equity amount"
label var positive_equity "Has positive home equity"

* Has savings account (check if variable exists)
cap gen has_savings = (savaccnt == 1) if savaccnt != .
cap label var has_savings "Has savings account"

* Has retirement account
cap gen has_retirement = (haveret == 1) if haveret != .
cap label var has_retirement "Has retirement account"

* Health insurance
cap gen has_health_insurance = (haveins == 1) if haveins != .
cap label var has_health_insurance "Has health insurance"

* ============================================================================
* DOMAIN 4: DEBT BURDEN
* ============================================================================

* Housing cost burden - mortgage payment relative to income
* incgroup is categorical (HOM2_133 TOTAL HH INCOME)
* Use approximate midpoints for income categories if needed
* For now, skip ratio and use cost burden indicators if available

cap gen housing_cost_ratio = .
cap gen cost_burdened = .
cap gen severely_burdened = .
label var cost_burdened "Housing costs > 30% of income"
label var severely_burdened "Housing costs > 50% of income"

* Credit card debt
gen has_cc_debt = (d_chcamtowed > 0) if d_chcamtowed != .
label var has_cc_debt "Has credit card debt"

* Student loan debt
gen has_student_debt = (d_slbalance > 0) if d_slbalance != .
label var has_student_debt "Has student loan debt"

* ============================================================================
* DOMAIN 5: ALTERNATIVE FINANCIAL SERVICES
* ============================================================================

* These variables may have different names in CAPS
* Search for: payday, pawn, rent_to_own, title_loan, check_cash

* Try common patterns
cap gen payday_loan = (usedpayday == 1) if usedpayday != .
cap gen pawnshop = (usedpawn == 1) if usedpawn != .
cap gen check_cashing = (usedcheckcash == 1) if usedcheckcash != .

* ============================================================================
* DOMAIN 6: STABILITY
* ============================================================================

* Marital status
cap gen married = (marstat == 1) if marstat != .
cap label var married "Currently married"

* Note: years_at_address may need to be derived from move dates

* ============================================================================
* DOMAIN 7: HUMAN CAPITAL
* ============================================================================

* Education - look for educ* variables
cap gen college_degree = (educat >= 16) if educat != .
cap gen high_school = (educat >= 12) if educat != .
cap label var college_degree "Has bachelor's degree or higher"
cap label var high_school "Has high school diploma"

* ============================================================================
* DOMAIN 8: DEMOGRAPHICS
* ============================================================================

* These are likely already in the data
cap confirm variable age
cap confirm variable female
cap confirm variable black
cap confirm variable hispanic

* ============================================================================
* CREATE INDICES WITH ACTUAL VARIABLES
* ============================================================================

* Payment Behavior Index
gen payment_index = 100
replace payment_index = payment_index - 25 if payment_difficulty == 1
replace payment_index = payment_index - 20 if prior_delinquency == 1
replace payment_index = payment_index - 15 if penalized_late == 1
replace payment_index = 0 if payment_index < 0
label var payment_index "Payment behavior score (0-100)"

* Income Stability Index
gen income_index = 100
replace income_index = income_index - 30 if job_loss == 1
replace income_index = income_index - 25 if unemployed == 1
replace income_index = income_index + 10 if job_tenure >= 2 & job_tenure != .
replace income_index = income_index + 10 if same_employer == 1
replace income_index = 0 if income_index < 0
replace income_index = 100 if income_index > 100
label var income_index "Income stability score (0-100)"

* Financial Resilience Index
gen resilience_index = 0
replace resilience_index = resilience_index + 25 if has_emergency_fund == 1
replace resilience_index = resilience_index + 25 if has_large_buffer == 1
replace resilience_index = resilience_index + 20 if positive_equity == 1
replace resilience_index = resilience_index + 15 if has_social_safety == 1
replace resilience_index = resilience_index + 15 if has_retirement == 1
replace resilience_index = 100 if resilience_index > 100
label var resilience_index "Financial resilience score (0-100)"

* Debt Burden Index
gen debt_index = 100
replace debt_index = debt_index - 20 if cost_burdened == 1
replace debt_index = debt_index - 20 if severely_burdened == 1
replace debt_index = debt_index - 10 if has_cc_debt == 1
replace debt_index = 0 if debt_index < 0
label var debt_index "Debt burden score (0-100, higher=better)"

* ============================================================================
* COMPOSITE FINTECH SCORE
* ============================================================================

* Weighted composite (based on fintech literature weights)
gen fintech_score = 0.40 * payment_index + ///
                    0.30 * income_index + ///
                    0.20 * resilience_index + ///
                    0.10 * debt_index

label var fintech_score "Fintech creditworthiness score (0-100)"

* Summary
sum payment_index income_index resilience_index debt_index fintech_score

di _n "=== Fintech Score Distribution ==="
sum fintech_score, d

di _n "=== Score by Default Status ==="
tab default_90, sum(fintech_score)

********************************************************************************
* END
********************************************************************************
