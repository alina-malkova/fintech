# CAPS Variable Identification Guide

## How to Use This Guide

Since the CAPS codebook isn't publicly accessible online, use this guide when you open your CAPS data in Stata:

1. Run `describe` to see all variable names
2. Run `codebook varname` for each variable of interest
3. Match variables to the categories below based on labels and values

---

## Variables Used in Published CAPS Research

Based on papers by Quercia, Riley, Tian, Ding, and others:

### Mortgage Performance (Outcome Variables)

From "Unemployment as an Adverse Trigger Event for Mortgage Default" (Quercia et al.):

| Likely Variable Pattern | Description | Values |
|------------------------|-------------|--------|
| `default*` or `delinq*` | Mortgage delinquency | 0/1 or days |
| `d30`, `d60`, `d90` | 30/60/90 day delinquency | 0/1 |
| `foreclos*` | Foreclosure status | 0/1 |
| `current` | Loan is current | 0/1 |
| `prepay*` | Prepayment | 0/1 |

**Stata command to find**:
```stata
lookfor default delinq foreclos current prepay mortgage
```

---

### Employment & Income (Key Trigger Variables)

From "Unemployment as an Adverse Trigger Event":
> "Household unemployment experience... affects mortgage default"

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `unemploy*` or `unemp*` | Unemployment spell |
| `job_loss` or `lost_job` | Lost job indicator |
| `employ*` | Employment status |
| `work*` | Working status |
| `income` or `hhinc*` | Household income |
| `inc_change` | Income change |
| `hours*` | Work hours |
| `tenure` or `job_ten*` | Job tenure |

**Stata command to find**:
```stata
lookfor employ unemp job income work hours tenure wage
```

---

### Savings & Precautionary Buffer

From "Unemployment as an Adverse Trigger Event":
> "Precautionary savings... can moderate mortgage default significantly"

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `saving*` | Savings account/amount |
| `check*` | Checking account |
| `bank*` | Bank account |
| `asset*` | Total assets |
| `wealth*` | Wealth measures |
| `emergen*` | Emergency fund |
| `retire*` | Retirement account |
| `buffer` | Financial buffer |

**Stata command to find**:
```stata
lookfor saving check bank asset wealth retire buffer emergency
```

---

### Credit & Debt

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `credit*` | Credit score or credit use |
| `fico` or `score` | Credit score |
| `debt*` | Debt amounts |
| `dti` | Debt-to-income |
| `ltv` | Loan-to-value |
| `equity` | Home equity |
| `card*` | Credit card |
| `loan*` | Other loans |

**Stata command to find**:
```stata
lookfor credit fico score debt dti ltv equity card loan
```

---

### Housing & Mortgage

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `mtg*` or `mort*` | Mortgage variables |
| `payment` or `pmt` | Monthly payment |
| `rate` | Interest rate |
| `house*` or `home*` | Housing variables |
| `value` | Home value |
| `cost*` | Housing costs |
| `own*` or `rent*` | Ownership status |
| `years_addr*` | Years at address |

**Stata command to find**:
```stata
lookfor mortgage mtg payment rate house home value own rent addr
```

---

### Financial Hardship Indicators

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `hardship*` | Financial hardship |
| `difficult*` | Payment difficulty |
| `behind*` | Behind on payments |
| `late*` | Late payments |
| `miss*` | Missed payments |
| `collect*` | Bill collectors |
| `bankrupt*` | Bankruptcy |
| `utility*` | Utility bills |
| `cutoff*` | Services cut off |

**Stata command to find**:
```stata
lookfor hardship difficult behind late miss collect bankrupt utility cut
```

---

### Alternative Financial Services

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `payday*` | Payday loans |
| `pawn*` | Pawnshop |
| `rent_to_own` or `rto` | Rent-to-own |
| `check_cash*` | Check cashing |
| `title_loan*` | Auto title loan |
| `afs*` | Alt financial services |

**Stata command to find**:
```stata
lookfor payday pawn rent_to check_cash title afs alternative
```

---

### Demographics & Controls

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `age` | Age |
| `female` or `male` or `sex` | Gender |
| `race` or `black` or `white` or `hisp*` | Race/ethnicity |
| `married` or `marital` | Marital status |
| `educ*` | Education |
| `college` | College degree |
| `child*` or `kids` | Children |
| `hh_size` | Household size |

**Stata command to find**:
```stata
lookfor age sex female male race black white hisp married educ child
```

---

### Social Capital (Unique to CAPS)

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `community*` | Community involvement |
| `volunteer*` | Volunteering |
| `church*` or `relig*` | Religious participation |
| `neighbor*` | Neighbor relations |
| `trust*` | Trust measures |
| `social*` | Social activities |
| `civic*` | Civic engagement |

**Stata command to find**:
```stata
lookfor community volunteer church relig neighbor trust social civic
```

---

### Geographic Identifiers

| Likely Variable Pattern | Description |
|------------------------|-------------|
| `zip*` | ZIP code |
| `state*` | State |
| `county*` or `fips` | County |
| `msa*` or `metro*` | Metro area |
| `tract*` | Census tract |

**Stata command to find**:
```stata
lookfor zip state county fips msa metro tract geo
```

---

## Quick Variable Discovery Script

Run this in Stata after loading your CAPS data:

```stata
* ============================================
* CAPS Variable Discovery Script
* ============================================

* 1. List all variables
describe, short

* 2. Search for key variable groups
di "=== OUTCOME VARIABLES ==="
lookfor default delinq foreclos current

di "=== EMPLOYMENT/INCOME ==="
lookfor employ unemp job income work

di "=== SAVINGS/ASSETS ==="
lookfor saving check bank asset wealth retire

di "=== FINANCIAL HARDSHIP ==="
lookfor hardship difficult behind late miss collect bankrupt

di "=== HOUSING ==="
lookfor mortgage mtg payment house home

di "=== DEMOGRAPHICS ==="
lookfor age sex female race black married educ

di "=== GEOGRAPHY ==="
lookfor zip state county fips

* 3. Export variable list to Excel
preserve
describe, replace clear
export excel using "caps_variables.xlsx", firstrow(variables) replace
restore
```

---

## Contact for CAPS Data Access

If you need the full codebook:

**UNC Center for Community Capital**
- Website: https://communitycapital.unc.edu/
- Data FAQ: https://communitycapital.unc.edu/our-work/community-advantage-program/caps-faq/
- Director: Roberto Quercia (retired 2020)

---

## Key Papers Using CAPS Data (for variable reference)

1. **Quercia, Riley & Tian** - "Unemployment as an Adverse Trigger Event for Mortgage Default"
   - Variables: unemployment, precautionary savings, unemployment benefits duration

2. **Ding, Quercia, Li & Ratcliffe** - "Risky Borrowers or Risky Mortgages"
   - Variables: credit scores, equity, default rates

3. **Quercia, Pennington-Cross & Tian** - "Mortgage Default and Prepayment Risks"
   - Variables: income categories, credit scores, equity, labor market conditions

4. **Riley, Ru & Quercia** - "The Community Advantage Program Database"
   - Cityscape 11(3), 2009 - Overview of database structure
