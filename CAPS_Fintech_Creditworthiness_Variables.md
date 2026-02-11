# CAPS Variables for Fintech-Style Creditworthiness Assessment

## Overview

This document maps Community Advantage Panel Survey (CAPS) variables to alternative credit scoring methods used by fintech lenders. The goal is to construct creditworthiness measures using non-traditional data that fintech companies use to serve underbanked populations.

## Fintech Alternative Credit Scoring: Key Domains

Fintech lenders use alternative data beyond traditional FICO scores:

| Domain | Traditional Credit | Fintech Alternative | CAPS Equivalent |
|--------|-------------------|---------------------|-----------------|
| Payment history | Credit card, loans | Rent, utilities, phone | Mortgage payments, bill payments |
| Income | Stated income | Cash flow analysis, bank data | Income, employment, income volatility |
| Stability | Length of credit | Employment tenure, residence | Job tenure, housing tenure |
| Capacity | Debt-to-income | Spending patterns, savings | Assets, savings, expenses |
| Character | Credit inquiries | Education, social capital | Education, community ties |

---

## CAPS Variables by Fintech Scoring Category

### 1. PAYMENT BEHAVIOR (Strongest Predictors)

**Mortgage Payment History** (CAPS tracks actual loan performance)
- `mortgage_delinquency` - Ever 30/60/90 days late on mortgage
- `mortgage_default` - 90+ day delinquency
- `foreclosure_status` - Foreclosure proceedings
- `payment_difficulty` - Self-reported difficulty making payments

**Bill Payment Patterns**
- `utility_behind` - Behind on utility bills
- `rent_behind` - Behind on rent (for renters sample)
- `phone_disconnected` - Phone service disconnected for non-payment
- `utilities_cutoff` - Utilities cut off for non-payment

**Financial Distress Indicators**
- `bill_collectors` - Contacted by bill collectors
- `bankruptcy` - Filed for bankruptcy
- `judgment` - Had judgment against them
- `repossession` - Vehicle or property repossessed

> **Fintech Application**: Payment history on non-credit obligations (rent, utilities) is the #1 alternative data source. TransUnion found rent payment reporting increases credit scores by ~60 points for thin-file borrowers.

---

### 2. INCOME & CASH FLOW

**Income Level**
- `household_income` - Total household income
- `personal_income` - Respondent's income
- `income_category` - Income brackets

**Income Stability/Volatility** (Key fintech variable)
- `income_change` - Income increased/decreased from last year
- `income_same_employer` - Income from same employer
- `income_sources` - Number of income sources
- `irregular_income` - Has irregular/variable income

**Employment Stability**
- `employed` - Currently employed
- `employment_status` - Full-time, part-time, unemployed
- `job_tenure` - Length at current job
- `employer_change` - Changed employers in past year
- `unemployment_spell` - Experienced unemployment

**Income Shocks**
- `job_loss` - Lost job in past year
- `hours_reduced` - Work hours reduced
- `wage_cut` - Experienced wage reduction

> **Fintech Application**: Income volatility is a key predictor. Fintech lenders analyze cash flow patterns - regular deposits indicate reliability. Gig workers with variable income need different assessment.

---

### 3. ASSETS & SAVINGS (Buffer Stock)

**Liquid Assets**
- `checking_account` - Has checking account
- `savings_account` - Has savings account
- `savings_balance` - Amount in savings
- `emergency_fund` - Has emergency savings
- `months_expenses` - Months of expenses covered by savings

**Non-Liquid Assets**
- `retirement_account` - Has 401k/IRA
- `retirement_balance` - Retirement account balance
- `vehicle_owned` - Owns vehicle
- `other_property` - Owns other real estate

**Net Worth**
- `total_assets` - Total asset value
- `total_debt` - Total debt
- `net_worth` - Assets minus debts
- `home_equity` - Equity in home

> **Fintech Application**: Savings behavior indicates financial discipline. Having 2-3 months expenses in savings strongly predicts loan repayment.

---

### 4. DEBT & OBLIGATIONS

**Debt Burden**
- `mortgage_payment` - Monthly mortgage payment
- `total_debt_payment` - Total monthly debt payments
- `debt_to_income` - Debt-to-income ratio
- `credit_card_debt` - Credit card balances
- `student_loans` - Student loan debt
- `auto_loans` - Auto loan debt

**Housing Cost Burden**
- `housing_cost_ratio` - Housing costs / income
- `cost_burdened` - Housing costs > 30% income
- `severely_burdened` - Housing costs > 50% income

> **Fintech Application**: Traditional DTI ratios, but fintech adds granularity on payment timing and prioritization.

---

### 5. FINANCIAL BEHAVIORS

**Banking Relationship**
- `bank_account` - Has bank account
- `unbanked` - No bank account
- `underbanked` - Has account but uses alt financial services
- `bank_type` - Bank, credit union, online

**Alternative Financial Services** (Negative signal)
- `payday_loan` - Used payday loans
- `pawnshop` - Used pawnshop
- `rent_to_own` - Used rent-to-own
- `check_cashing` - Used check cashing services
- `title_loan` - Used auto title loan

**Positive Financial Behaviors**
- `budget` - Maintains household budget
- `automatic_savings` - Has automatic savings transfers
- `direct_deposit` - Uses direct deposit
- `online_banking` - Uses online banking

> **Fintech Application**: Use of predatory financial services (payday, pawnshop) indicates financial stress but also lack of credit access. Fintech aims to serve these borrowers with better products.

---

### 6. STABILITY INDICATORS

**Residential Stability**
- `years_at_address` - Years at current address
- `moved_recently` - Moved in past year
- `own_rent` - Homeowner vs renter
- `housing_tenure` - Length of homeownership

**Family Stability**
- `marital_status` - Married, single, divorced
- `marital_change` - Marriage/divorce in past year
- `household_size` - Number in household
- `dependents` - Number of dependents

> **Fintech Application**: Residential stability correlates with creditworthiness. Frequent moves may indicate financial instability.

---

### 7. HUMAN CAPITAL & SOCIAL CAPITAL

**Education** (Predictive in fintech models)
- `education_level` - Highest education completed
- `college_degree` - Has bachelor's or higher
- `currently_enrolled` - Currently in school

**Social Capital** (Unique to CAPS)
- `community_involvement` - Participates in community organizations
- `volunteer` - Volunteers
- `neighbor_trust` - Trusts neighbors
- `social_support` - Has social support network
- `church_attendance` - Religious participation

> **Fintech Application**: Upstart pioneered using education as a credit variable. Social capital may indicate stability and community ties that correlate with repayment.

---

### 8. HEALTH & SHOCKS

**Health Shocks**
- `health_problem` - Major health problem
- `health_insurance` - Has health insurance
- `medical_debt` - Has medical debt
- `disability` - Has disability

**Other Shocks**
- `divorce` - Recently divorced
- `death_family` - Death in family
- `natural_disaster` - Affected by natural disaster

> **Fintech Application**: Health shocks are the #1 cause of bankruptcy. Health insurance coverage is protective.

---

## Constructing Fintech-Style Credit Scores from CAPS

### Approach 1: Payment Behavior Index

```stata
* Create payment behavior score (0-100, higher = better)
gen payment_score = 100

* Deduct for negative payment behaviors
replace payment_score = payment_score - 30 if mortgage_delinquency == 1
replace payment_score = payment_score - 20 if utility_behind == 1
replace payment_score = payment_score - 15 if bill_collectors == 1
replace payment_score = payment_score - 25 if bankruptcy == 1
replace payment_score = payment_score - 10 if phone_disconnected == 1
```

### Approach 2: Income Stability Index

```stata
* Income volatility measure
gen income_stable = 1
replace income_stable = 0 if job_loss == 1
replace income_stable = 0 if hours_reduced == 1
replace income_stable = 0 if income_change < 0

* Employment stability
gen emp_stable = (job_tenure >= 2) if job_tenure != .
```

### Approach 3: Financial Resilience Index

```stata
* Buffer stock measure
gen has_buffer = (months_expenses >= 2) if months_expenses != .

* Composite resilience score
gen resilience = 0
replace resilience = resilience + 1 if savings_account == 1
replace resilience = resilience + 1 if emergency_fund == 1
replace resilience = resilience + 1 if health_insurance == 1
replace resilience = resilience + 1 if retirement_account == 1
```

### Approach 4: Alternative Financial Services Index (Negative)

```stata
* AFS usage indicates credit constraints
gen afs_user = 0
replace afs_user = 1 if payday_loan == 1
replace afs_user = 1 if pawnshop == 1
replace afs_user = 1 if rent_to_own == 1
replace afs_user = 1 if title_loan == 1
```

### Approach 5: Composite Fintech Score

```stata
* Standardize components
foreach var in payment_score income_stable resilience {
    egen `var'_std = std(`var')
}

* Weighted composite (weights based on fintech literature)
gen fintech_score = 0.40 * payment_score_std + ///
                    0.30 * income_stable_std + ///
                    0.20 * resilience_std + ///
                    0.10 * education_std
```

---

## Predicting Loan Default with CAPS

### Outcome Variables

| Variable | Definition | Use |
|----------|------------|-----|
| `default_90` | 90+ days delinquent | Primary outcome |
| `default_60` | 60+ days delinquent | Alternative |
| `foreclosure` | Entered foreclosure | Severe outcome |
| `current` | Loan is current | Good outcome |

### Key Predictors (Based on Literature)

**Strong Predictors (from fintech research)**:
1. Prior delinquency on any obligation
2. Income volatility / job loss
3. Savings buffer (months of expenses)
4. Debt-to-income ratio
5. Housing cost burden

**Moderate Predictors**:
6. Use of alternative financial services
7. Health insurance status
8. Education level
9. Employment tenure
10. Marital stability

### Sample Prediction Model

```stata
* Logit model for mortgage default
logit default_90 ///
    /* Payment History */
    prior_delinquency utility_behind ///
    /* Income/Employment */
    income_volatility job_loss job_tenure ///
    /* Assets/Buffer */
    months_expenses savings_account ///
    /* Debt Burden */
    debt_to_income housing_cost_ratio ///
    /* AFS Usage */
    payday_loan ///
    /* Stability */
    years_at_address married ///
    /* Human Capital */
    college_degree ///
    /* Controls */
    age female black hispanic ///
    , cluster(county)

* Compare to traditional model
logit default_90 credit_score debt_to_income, cluster(county)

* Test if fintech variables add predictive power
lrtest
```

---

## Research Questions

1. **Predictive Power**: Do fintech-style variables (payment behavior, income stability, savings buffer) predict default better than traditional credit scores for LMI borrowers?

2. **Credit Expansion**: How many CAPS borrowers who defaulted would have been identified as risky by fintech scoring? How many good borrowers would have been approved?

3. **Fairness**: Do fintech variables reduce or increase disparities by race/ethnicity?

4. **Interaction with Branch Closures**: Do borrowers with stronger fintech-readiness indicators experience smaller negative effects from branch closures?

---

## Data Sources

- **CAPS Survey**: [UNC Center for Community Capital](https://communitycapital.unc.edu/our-work/community-advantage-program/survey/)
- **Fintech Credit Scoring**: [Plaid Alternative Credit Data](https://plaid.com/resources/lending/alternative-credit-data/)
- **Alternative Data Research**: [Federal Reserve - Give Me Some Credit](https://www.kansascityfed.org/research/payments-system-research-briefings/give-me-some-credit-using-alternative-data-to-expand-credit-access/)
- **Rent Reporting Impact**: [Experian Boost](https://www.experian.com/consumer-products/experian-boost.html)

---

## Variable Checklist for CAPS

Review your CAPS codebook and check which variables are available:

### Payment Behavior
- [ ] Mortgage delinquency (30/60/90 day)
- [ ] Utility payment status
- [ ] Bill collector contact
- [ ] Bankruptcy filing
- [ ] Foreclosure status

### Income & Employment
- [ ] Household income
- [ ] Employment status
- [ ] Job tenure
- [ ] Income change from prior year
- [ ] Job loss indicator

### Assets & Savings
- [ ] Savings account ownership
- [ ] Savings balance
- [ ] Emergency fund
- [ ] Retirement account
- [ ] Home equity

### Financial Behaviors
- [ ] Bank account ownership
- [ ] Payday loan usage
- [ ] Pawnshop usage
- [ ] Budget maintenance
- [ ] Online banking

### Stability
- [ ] Years at address
- [ ] Marital status
- [ ] Health insurance

### Human/Social Capital
- [ ] Education level
- [ ] Community involvement
- [ ] Social support
