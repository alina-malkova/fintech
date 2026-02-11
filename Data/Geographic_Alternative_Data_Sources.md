# Geographic Alternative Data Sources for Fintech Credit Assessment

## Overview

This document lists publicly available geographic datasets that can be merged with CAPS data by ZIP code, county, or census tract to create fintech-style alternative creditworthiness measures.

---

## 1. SOCIAL CAPITAL (Facebook/Meta Data)

### Social Capital Atlas (Chetty et al., 2022)
**The strongest predictor of economic mobility identified to date.**

| Feature | Details |
|---------|---------|
| **Source** | Opportunity Insights / Harvard / Meta |
| **URL** | https://www.socialcapital.org |
| **Geography** | ZIP code, County, High School, College |
| **Years** | 2022 (based on Facebook friendships) |
| **Format** | CSV download |

**Key Variables**:
- `economic_connectedness` - Fraction of high-SES friends among low-SES individuals
- `cohesiveness` - Clustering coefficient (how connected are your friends to each other)
- `civic_engagement` - Volunteering rates derived from Facebook groups
- `friending_bias` - Tendency to befriend similar vs. different SES

**Why It Matters for Credit**:
> "If children with low-SES parents were to grow up in counties with economic connectedness comparable to that of the average child with high-SES parents, their incomes in adulthood would increase by 20% on average."

**Research Citation**:
Chetty, R., et al. (2022). "Social Capital I: Measurement and Associations with Economic Mobility." *Nature* 608: 108-121.

---

## 2. DIGITAL ACCESS / BROADBAND

### A. National Neighborhood Data Archive (NaNDA) - Broadband
| Feature | Details |
|---------|---------|
| **Source** | ICPSR / University of Michigan |
| **URL** | https://www.openicpsr.org/openicpsr/project/128841 |
| **Geography** | ZIP Code Tabulation Area (ZCTA) |
| **Years** | 2014-2020 |
| **Format** | Stata, CSV |

**Key Variables**:
- Internet availability by technology type
- Download/upload speeds
- Provider competition

### B. FCC Broadband Data Collection
| Feature | Details |
|---------|---------|
| **Source** | Federal Communications Commission |
| **URL** | https://broadbandmap.fcc.gov/data-download |
| **Geography** | Census Block, Tract, County, State |
| **Years** | 2020-present |
| **Format** | CSV |

**Key Variables**:
- Served/underserved/unserved locations
- Technology type (fiber, cable, DSL, wireless)
- Speed tiers available

**Why It Matters for Credit**:
- Digital access enables online banking, fintech apps
- Broadband adoption correlates with business growth (213% faster in rural areas)
- Proxy for digital financial inclusion

---

## 3. FINANCIAL SERVICES LANDSCAPE

### A. FDIC Summary of Deposits (Bank Branches)
| Feature | Details |
|---------|---------|
| **Source** | FDIC |
| **URL** | https://www.fdic.gov/resources/data-tools/summary-of-deposits/ |
| **Geography** | ZIP code (branch address) |
| **Years** | Annual, 1994-present |
| **Format** | CSV |

**Key Variables**:
- Branch locations by institution
- Deposits by branch
- Branch open/close dates

### B. Federal Reserve Banking Deserts Dashboard
| Feature | Details |
|---------|---------|
| **Source** | Federal Reserve |
| **URL** | https://fedcommunities.org/data/banking-deserts-dashboard/ |
| **Geography** | Census Tract |
| **Years** | 2019-2025 |
| **Format** | Interactive (downloadable) |

**Key Variables**:
- Banking desert indicator (no branch within 2/5/10 miles)
- Distance to nearest branch
- Branch count by tract

### C. Payday Lender Locations
| Feature | Details |
|---------|---------|
| **Source** | State licensing data, Census business patterns |
| **URL** | Varies by state; see Chicago Fed research |
| **Geography** | ZIP code, County |

**Research Reference**:
- Chicago Fed Letter 2024: "New Evidence on Where Payday Lenders Locate"
- Federal Reserve FEDS 2009-33: "Determinants of the Locations of Payday Lenders"

**Why It Matters for Credit**:
- High payday lender density = credit-constrained population
- Banking deserts indicate limited traditional credit access
- Branch closures trigger search for alternative credit

---

## 4. RETAIL ENVIRONMENT (Financial Stress Proxies)

### A. Dollar Stores Dataset
| Feature | Details |
|---------|---------|
| **Source** | ICPSR / National Neighborhood Data Archive |
| **URL** | https://www.icpsr.umich.edu/web/NACDA/studies/209324 |
| **Geography** | Census Tract, ZCTA |
| **Years** | 1990-2021 |
| **Format** | Stata, CSV |

**Key Variables**:
- Number of dollar stores
- Dollar store density (per capita, per sq mile)
- Year of entry

**Why It Matters for Credit**:
- Dollar store density correlates with low-income areas
- Proxy for limited retail/banking services
- Associated with food deserts

### B. USDA Food Access Research Atlas
| Feature | Details |
|---------|---------|
| **Source** | USDA Economic Research Service |
| **URL** | https://www.ers.usda.gov/data-products/food-access-research-atlas/download-the-data |
| **Geography** | Census Tract |
| **Years** | 2010, 2015, 2019 |
| **Format** | Excel, CSV |

**Key Variables**:
- `LowAccessTracts` - Low food access indicator
- `LATracts_half` - Low access at ½ mile
- `LATracts1` - Low access at 1 mile
- `LATracts10` - Low access at 10 miles (rural)
- `LAhalfand10` - Low access urban and rural
- `HUNVFlag` - Low access + low vehicle access

**Why It Matters for Credit**:
- Food deserts overlap with banking deserts
- Proxy for underserved communities
- Correlates with financial stress

---

## 5. RELIGIOUS / COMMUNITY ORGANIZATIONS

### A. Association of Religion Data Archives (ARDA)
| Feature | Details |
|---------|---------|
| **Source** | ARDA / Penn State |
| **URL** | https://www.thearda.com/data-archive |
| **Geography** | County |
| **Years** | Various (Religious Congregations studies) |
| **Format** | CSV, SPSS |

**Key Variables**:
- Number of congregations by denomination
- Adherents per capita
- Congregations per capita

### B. National Center for Charitable Statistics (NCCS)
| Feature | Details |
|---------|---------|
| **Source** | Urban Institute |
| **URL** | https://nccs.urban.org/ |
| **Geography** | ZIP code (nonprofit addresses) |
| **Format** | CSV |

**Key Variables**:
- Number of nonprofits by ZIP
- Nonprofit categories (religious, social services, etc.)
- Total revenues/assets

**Why It Matters for Credit**:
- Religious participation correlates with social capital
- Community organizations provide informal support networks
- Nonprofits indicate community investment

---

## 6. ECONOMIC INDICATORS

### A. Census American Community Survey (ACS)
| Feature | Details |
|---------|---------|
| **Source** | U.S. Census Bureau |
| **URL** | https://data.census.gov |
| **Geography** | ZIP code (ZCTA), Census Tract, County |
| **Years** | Annual (1-year, 5-year estimates) |
| **Format** | CSV, API |

**Key Variables**:
- Median household income
- Poverty rate
- Unemployment rate
- Educational attainment
- Homeownership rate
- Commute time
- Health insurance coverage
- Computer/internet access

### B. Bureau of Labor Statistics (BLS) - Local Area Unemployment
| Feature | Details |
|---------|---------|
| **Source** | BLS |
| **URL** | https://www.bls.gov/lau/ |
| **Geography** | County, Metro Area |
| **Years** | Monthly |
| **Format** | CSV |

**Key Variables**:
- Unemployment rate
- Labor force participation
- Employment by industry

### C. County Business Patterns
| Feature | Details |
|---------|---------|
| **Source** | Census Bureau |
| **URL** | https://www.census.gov/programs-surveys/cbp.html |
| **Geography** | ZIP code, County |
| **Years** | Annual |
| **Format** | CSV |

**Key Variables**:
- Number of establishments by industry
- Employment by industry
- Payroll by industry

---

## 7. HOUSING & REAL ESTATE

### A. Zillow Home Value Index
| Feature | Details |
|---------|---------|
| **Source** | Zillow Research |
| **URL** | https://www.zillow.com/research/data/ |
| **Geography** | ZIP code, County, Metro |
| **Years** | Monthly, 2000-present |
| **Format** | CSV |

**Key Variables**:
- ZHVI (Zillow Home Value Index)
- Rent index
- Home value appreciation
- Inventory levels

### B. Federal Housing Finance Agency (FHFA) House Price Index
| Feature | Details |
|---------|---------|
| **Source** | FHFA |
| **URL** | https://www.fhfa.gov/data/hpi |
| **Geography** | ZIP code, Census Tract, County, Metro |
| **Years** | Quarterly |
| **Format** | CSV |

**Key Variables**:
- House price index
- Price appreciation rates

---

## 8. HEALTH INDICATORS

### A. CDC PLACES Dataset
| Feature | Details |
|---------|---------|
| **Source** | CDC |
| **URL** | https://www.cdc.gov/places |
| **Geography** | Census Tract, County |
| **Years** | Annual |
| **Format** | CSV |

**Key Variables**:
- Health outcomes (diabetes, obesity, mental health)
- Health behaviors (smoking, physical activity)
- Prevention measures (insurance coverage, checkups)
- Health status indicators

**Why It Matters for Credit**:
- Health shocks are #1 cause of bankruptcy
- Health insurance coverage is protective
- Population health indicates community resources

---

## 9. CRIME & SAFETY

### A. FBI Uniform Crime Reports
| Feature | Details |
|---------|---------|
| **Source** | FBI |
| **URL** | https://cde.ucr.cjis.gov/ |
| **Geography** | City, County |
| **Years** | Annual |
| **Format** | CSV |

**Key Variables**:
- Violent crime rate
- Property crime rate
- Crime by type

---

## Summary: Priority Datasets for Fintech Credit Assessment

| Rank | Dataset | Geography | Why Important |
|------|---------|-----------|---------------|
| 1 | **Social Capital Atlas** | ZIP | Strongest mobility predictor (Facebook connections) |
| 2 | **FDIC Summary of Deposits** | ZIP | Bank branch presence/closures |
| 3 | **Fuster Fintech Data** | County | ✓ Already downloaded |
| 4 | **Broadband Data (NaNDA)** | ZCTA | Digital access for fintech |
| 5 | **Food Access Atlas** | Tract | Underserved community proxy |
| 6 | **Dollar Stores (ICPSR)** | ZCTA | Financial stress proxy |
| 7 | **ACS Demographics** | ZCTA | Income, education, employment |
| 8 | **CDC PLACES** | Tract | Health/financial resilience |
| 9 | **Banking Deserts (Fed)** | Tract | Credit access indicator |

---

## Download Checklist

- [ ] Social Capital Atlas (socialcapital.org)
- [ ] NaNDA Broadband (ICPSR 128841)
- [ ] USDA Food Access Atlas
- [ ] Dollar Stores (ICPSR 209324)
- [ ] ACS 5-year estimates for CAPS ZCTAs
- [ ] CDC PLACES
- [ ] Fed Banking Deserts Dashboard
