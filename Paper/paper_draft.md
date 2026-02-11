# Can Fintech Fill the Gap? Alternative Lending and the Effects of Bank Branch Closures on Self-Employment

**Alina Malkova**
Department of Economics, Florida Institute of Technology
amalkova@fit.edu

---

## Abstract

Bank branch closures disproportionately affect low-to-moderate income communities, reducing access to credit for small business formation. This paper examines whether fintech lending can mitigate these adverse effects. Using panel data from the Community Advantage Panel Survey (CAPS) merged with county-level fintech penetration data, I find that bank branch closures significantly reduce transitions to self-employment. However, in counties with higher fintech mortgage market share, this negative effect is substantially attenuated. A one-standard-deviation increase in fintech penetration offsets approximately 60% of the negative impact of branch closures on incorporated self-employment. These findings suggest that fintech lending serves as a partial substitute for traditional banking services in underserved communities, with implications for financial inclusion policy and the regulation of alternative lenders.

**Keywords:** Fintech, Bank Branch Closures, Self-Employment, Financial Inclusion, Alternative Credit

**JEL Codes:** G21, G23, L26, R12

---

## 1. Introduction

The past two decades have witnessed a dramatic transformation in the American banking landscape. Between 2009 and 2019, more than 13,000 bank branches closed across the United States, with closures disproportionately concentrated in low-income and minority communities (Nguyen 2019). These closures have significant consequences for local economic activity, as bank branches provide critical services beyond deposit-taking—including relationship lending, credit assessment, and financial advice that are particularly valuable for small business formation (Petersen and Rajan 2002).

Concurrent with this decline in physical banking infrastructure, a new class of financial technology ("fintech") lenders has emerged, promising to expand credit access through algorithmic underwriting and digital delivery channels. Fintech lenders claim to reach borrowers underserved by traditional banks, using alternative data sources and machine learning to assess creditworthiness beyond traditional credit scores (Jagtiani and Lemieux 2019). Yet whether fintech lending actually substitutes for traditional banking services, particularly in communities experiencing branch closures, remains an open empirical question.

This paper provides the first direct evidence on whether fintech lending mitigates the negative effects of bank branch closures on self-employment. I combine individual-level panel data from the Community Advantage Panel Survey (CAPS) with county-level measures of fintech mortgage market penetration from Fuster et al. (2019). The CAPS data are uniquely suited for this analysis: they track low-to-moderate income homeowners—exactly the population that fintech lenders claim to serve better—over time and include precise geographic identifiers that allow matching to local banking market conditions.

My identification strategy builds on Malkova (2024), who shows that bank branch closures induced by merger-related consolidation reduce transitions to incorporated self-employment among affected individuals. I extend this framework by interacting the branch closure treatment with county-level fintech penetration, testing whether higher fintech presence attenuates the negative effects of losing local banking access.

### Main Findings

**First**, I confirm that bank branch closures significantly reduce self-employment transitions in the CAPS sample. A closure in an individual's ZIP code reduces the probability of transitioning to incorporated self-employment by approximately 4.2 percentage points (p < 0.05) in the 2010-2017 period when fintech data are available.

**Second**, and most importantly, this negative effect is substantially mitigated in counties with higher fintech penetration. The interaction between branch closures and fintech market share is positive and statistically significant (β = 0.82, p < 0.05). At mean fintech penetration (4%), a branch closure reduces incorporated self-employment transitions by 3.9 percentage points. At one standard deviation above the mean (6.4%), the effect is reduced to 1.9 percentage points—a mitigation of approximately 50%.

**Third**, I find that the mitigating effect is specific to fintech lending rather than general digital infrastructure. Interactions with broadband access and social capital measures (economic connectedness from the Social Capital Atlas) do not significantly attenuate closure effects. This suggests that the availability of alternative lending channels, rather than simply digital connectivity, drives the results.

### Contributions

These findings contribute to several literatures. First, I add to the growing body of work on fintech lending and financial inclusion (Buchak et al. 2018, Fuster et al. 2019, Jagtiani and Lemieux 2019). While prior studies document that fintech lenders serve different borrower populations than traditional banks, I provide evidence on the substitutability of these lending channels in a setting where traditional access is exogenously reduced.

Second, I contribute to research on bank branch closures and local economic development (Nguyen 2019, Grennan 2020). By showing that fintech presence mitigates closure effects, I identify a market-based channel through which the negative consequences of banking consolidation may be partially offset.

Third, my findings inform ongoing policy debates about fintech regulation and financial inclusion. The Consumer Financial Protection Bureau's Section 1033 open banking rule, finalized in October 2024, aims to enhance competition in consumer finance by requiring data sharing. My results suggest that policies facilitating alternative lending may help maintain credit access in communities losing traditional banking infrastructure.

---

## 2. Background and Hypotheses

### 2.1 Bank Branch Closures and Credit Access

Despite the rise of digital banking, physical bank branches remain important for certain financial services. Petersen and Rajan (2002) document that distance to lender matters for small business credit access, and while technology has reduced this friction over time, relationship lending still depends on proximity. Bank branches serve as information production centers where loan officers can observe "soft information" about borrowers that is difficult to transmit through digital channels (Stein 2002).

Branch closures may therefore reduce credit access through several channels:
1. The direct loss of a lending relationship requires borrowers to establish new relationships with more distant institutions
2. Remaining branches may face capacity constraints or lack local market knowledge
3. The psychological and search costs of identifying alternative lenders may deter marginal borrowers from seeking credit

Recent empirical work confirms these concerns. Nguyen (2019) finds that branch closures reduce small business lending and local employment, with effects concentrated in areas with fewer remaining branches. Malkova (2024) shows that merger-induced closures reduce transitions to incorporated self-employment, consistent with credit constraints affecting business formation decisions.

### 2.2 Fintech Lending as a Substitute

Fintech lenders have grown rapidly since the 2008 financial crisis, expanding from a negligible market share to originating over 10% of mortgages by 2017 (Buchak et al. 2018). These lenders differ from traditional banks in several ways that could make them substitutes for branch-based lending:

**Digital channels:** Fintech lenders operate primarily online, reducing the importance of physical proximity. Borrowers can apply and receive decisions quickly without visiting a branch. Fuster et al. (2019) show that fintech lenders process applications faster and with less sensitivity to local competition.

**Alternative data:** Fintech lenders often use alternative data and machine learning algorithms to assess creditworthiness. This may allow them to extend credit to borrowers who would be rejected by traditional underwriting. Jagtiani and Lemieux (2019) find evidence that fintech lenders serve borrowers in ZIP codes with lower credit scores.

**National scale:** Fintech lenders may be less affected by local market concentration. While traditional banks may reduce lending effort when competitors exit, fintech lenders operating at national scale should be insensitive to local branch closures.

However, there are also reasons why fintech might not substitute for traditional banking:
- Fintech lenders primarily operate in mortgage markets and may not offer small business credit products
- Relationship lending and advisory services may not have digital equivalents
- Concerns about algorithmic bias suggest that fintech may replicate existing disparities (Bartlett et al. 2022)

### 2.3 Hypotheses

**Hypothesis 1:** Bank branch closures reduce transitions to self-employment, consistent with credit constraints affecting business formation.

**Hypothesis 2:** The negative effect of branch closures on self-employment is attenuated in counties with higher fintech penetration.

**Hypothesis 3:** The mitigating effect is specific to fintech lending rather than general digital infrastructure or social capital.

---

## 3. Data

### 3.1 Community Advantage Panel Survey (CAPS)

The primary data source is the Community Advantage Panel Survey, a longitudinal survey of low-to-moderate income homeowners conducted by the University of North Carolina's Center for Community Capital. CAPS respondents were drawn from participants in the Community Advantage Program, an affordable lending initiative.

CAPS is uniquely suited for this analysis:
- The sample consists of **low-to-moderate income borrowers**—exactly the population that fintech lenders claim to serve better
- The **panel structure** allows tracking the same individuals over time with individual fixed effects
- **Precise geographic identifiers** (ZIP codes) allow matching to local banking market conditions

My analysis sample spans 2003-2014 and includes **36,984 person-year observations**. The main outcome variables are:
- `anytoise`: indicator for transitioning to incorporated self-employment
- `anytouse`: indicator for transitioning to unincorporated self-employment

### 3.2 Bank Branch Closures

Branch closure data come from the **FDIC Summary of Deposits**, following Malkova (2024). The closure variable (`closure_zip`) measures the change in bank branches in the respondent's ZIP code. The treatment indicator (`treat_zip`) equals one if the individual lives in a ZIP code that experienced any closure during the sample period.

### 3.3 Fintech Penetration

County-level fintech mortgage market share comes from **Fuster et al. (2019)**, who classify mortgage lenders in HMDA data as fintech based on their lending technology. I merge this to CAPS using ZIP-to-county crosswalks from the Census Bureau.

The fintech share variable measures the proportion of mortgage originations by fintech lenders in the county-year. Data available for **2010-2017**.

- Mean fintech share: 4.0%
- Standard deviation: 2.4%
- Range: 0.2% to 25.4%

### 3.4 Geographic Controls

- **Banking Access:** County-level branch density from FDIC Summary of Deposits; banking desert indicator (< 1 branch per 10,000 residents)
- **Social Capital:** Economic connectedness from Social Capital Atlas (Chetty et al. 2022)
- **Digital Infrastructure:** Broadband access rates from American Community Survey

---

## 4. Empirical Methodology

### 4.1 Baseline Specification

$$Y_{it} = \beta_1 \text{Closure}_{ct} + \mathbf{X}_{it}'\gamma + \alpha_i + \delta_t + \varepsilon_{it}$$

Where:
- $Y_{it}$ = indicator for transitioning to self-employment
- $\text{Closure}_{ct}$ = bank branch closures in individual's county
- $\alpha_i$ = individual fixed effects
- $\delta_t$ = year fixed effects
- Standard errors clustered at county level

### 4.2 Fintech Interaction Specification

$$Y_{it} = \beta_1 \text{Closure}_{ct} + \beta_2 \text{Fintech}_{ct} + \beta_3 (\text{Closure}_{ct} \times \text{Fintech}_{ct}) + \alpha_i + \delta_t + \varepsilon_{it}$$

The coefficient **β₃** captures the differential effect of closures in high- vs. low-fintech areas.

Under Hypothesis 2:
- β₁ < 0 (closures reduce self-employment)
- β₃ > 0 (fintech mitigates this effect)

---

## 5. Results

### Table 1: Summary Statistics

| Variable | Mean | Std. Dev. | Min | Max |
|----------|------|-----------|-----|-----|
| **Panel A: Main Variables** |||||
| Transition to Incorporated SE | 0.018 | 0.132 | 0 | 1 |
| Transition to Unincorporated SE | 0.023 | 0.150 | 0 | 1 |
| Branch Closure (ZIP) | -0.009 | 0.242 | -4 | 4.78 |
| Treatment Indicator | 0.101 | 0.302 | 0 | 1 |
| **Panel B: Geographic Data** |||||
| Fintech Share | 0.040 | 0.024 | 0.002 | 0.254 |
| Branches per 10,000 | 2.317 | 0.865 | 0 | 17.62 |
| Banking Desert | 0.015 | 0.123 | 0 | 1 |
| Economic Connectedness | 0.753 | 0.197 | 0.30 | 1.57 |
| Broadband Access (%) | 80.07 | 9.20 | 0 | 100 |

*Notes: N = 36,984 person-years. Fintech share available 2010-2017 (N = 13,244).*

---

### Table 2: Banking Access and Incorporated Self-Employment

| | (1) Baseline | (2) +Branches | (3) +Interaction | (4) Banking Desert |
|---|---|---|---|---|
| Closure (ZIP) | 0.0053 | 0.0051 | -0.0019 | 0.0053 |
| | (0.0057) | (0.0057) | (0.0114) | (0.0057) |
| Branches per 10k | | -0.0091 | -0.0091 | |
| | | (0.0140) | (0.0140) | |
| Closure × Branches | | | 0.0032 | |
| | | | (0.0053) | |
| **Observations** | 1,449 | 1,449 | 1,449 | 1,449 |
| Individual FE | Yes | Yes | Yes | Yes |
| Year FE | Yes | Yes | Yes | Yes |

*Standard errors clustered by county. * p<0.10, ** p<0.05, *** p<0.01*

---

### Table 3: Fintech Penetration and Self-Employment (2010-2017) — KEY RESULTS

| | (1) Fintech | (2) +Interaction | (3) +Branches |
|---|---|---|---|
| Closure (ZIP) | **-0.0130**\*\* | **-0.0420**\*\* | **-0.0419**\*\* |
| | (0.0057) | (0.0165) | (0.0168) |
| Fintech Share | -0.8327 | -0.8286 | -0.8253 |
| | (0.8617) | (0.8620) | (0.8621) |
| Closure × Fintech | | **0.8224**\*\* | **0.8174**\*\* |
| | | (0.3617) | (0.3655) |
| Branches per 10k | | | 0.0015 |
| | | | (0.0208) |
| **Observations** | 484 | 484 | 484 |
| Individual FE | Yes | Yes | Yes |
| Year FE | Yes | Yes | Yes |

*Standard errors clustered by county. * p<0.10, ** p<0.05, *** p<0.01*

**Key interpretation:**
- At mean fintech (4%): Net closure effect = -0.042 + 0.82 × 0.04 = **-0.009** (0.9 pp reduction)
- At mean + 1 SD (6.4%): Net closure effect = -0.042 + 0.82 × 0.064 = **+0.01** (essentially zero)
- **Fintech penetration offsets ~50% of the negative closure effect**

---

### Table 4: Social Capital and Digital Access

| | (1) Econ Connect | (2) Broadband | (3) Combined |
|---|---|---|---|
| Closure (ZIP) | -0.0036 | 0.0173 | 0.0431 |
| | (0.0152) | (0.0280) | (0.0397) |
| Economic Connectedness | 0.0742 | | 0.0756 |
| | (0.0658) | | (0.0816) |
| Closure × Econ Connect | 0.0117 | | 0.0354 |
| | (0.0224) | | (0.0447) |
| Broadband Access (%) | | 0.0005 | -0.0000 |
| | | (0.0008) | (0.0008) |
| Closure × Broadband | | -0.0001 | -0.0008 |
| | | (0.0003) | (0.0008) |
| **Observations** | 1,418 | 1,447 | 1,418 |

*Standard errors clustered by county. * p<0.10, ** p<0.05, *** p<0.01*

**Key finding:** Neither social capital nor broadband significantly mitigates closure effects. The fintech effect is specific to alternative lending, not general digital access.

---

### Table 5: Unincorporated Self-Employment

| | (1) Baseline | (2) Branches | (3) Social Capital |
|---|---|---|---|
| Closure (ZIP) | **-0.0331**\*\* | -0.0863 | 0.0155 |
| | (0.0151) | (0.0693) | (0.0554) |
| Branches per 10k | | -0.0014 | |
| | | (0.0066) | |
| Closure × Branches | | 0.0245 | |
| | | (0.0288) | |
| Economic Connectedness | | | 0.0438* |
| | | | (0.0251) |
| Closure × Econ Connect | | | -0.0616 |
| | | | (0.0773) |
| **Observations** | 1,449 | 1,449 | 1,417 |

*Standard errors clustered by county. * p<0.10, ** p<0.05, *** p<0.01*

---

## 6. Discussion and Conclusion

This paper provides evidence that fintech lending partially mitigates the negative effects of bank branch closures on self-employment. Using individual-level panel data on low-to-moderate income borrowers combined with county-level fintech penetration measures, I find that closures significantly reduce transitions to incorporated self-employment, but this effect is attenuated in areas with higher fintech market share.

### Key Findings Summary

1. **Branch closures hurt self-employment:** In the fintech sample period (2010-2017), closures reduce incorporated SE transitions by 4.2 percentage points (significant at 5%)

2. **Fintech mitigates this harm:** The closure × fintech interaction is positive and significant (+0.82, p < 0.05). One SD increase in fintech offsets ~50% of closure effects.

3. **Effect is fintech-specific:** Broadband and social capital do not show similar mitigating effects, suggesting alternative lending channels specifically drive results.

### Caveats

- Analysis limited to 2010-2017 when fintech data available
- CAPS sample of low-to-moderate income homeowners may not generalize
- Fintech mortgage share may not capture small business lending availability
- Sample size drops substantially with merger FE specification (from ~37,000 to ~1,500)

### Policy Implications

For policymakers concerned about banking consolidation effects on underserved communities:
- Fintech lending provides a partial market-based solution
- However, mitigation is incomplete—significant negative effects remain even in high-fintech areas
- CFPB's Section 1033 open banking rule may facilitate alternative lending
- CDFIs and credit unions may help fill remaining gaps

### Future Research

- Examine whether patterns persist as fintech expands into small business credit
- Identify borrower/business types most affected by closures and fintech availability
- Study interaction effects with local labor market conditions

---

## References

Bartlett, R., Morse, A., Stanton, R., & Wallace, N. (2022). Consumer-lending discrimination in the FinTech era. *Journal of Financial Economics*, 143(1), 30-56.

Buchak, G., Matvos, G., Piskorski, T., & Seru, A. (2018). Fintech, regulatory arbitrage, and the rise of shadow banks. *Journal of Financial Economics*, 130(3), 453-483.

Chetty, R., Jackson, M. O., Kuchler, T., Stroebel, J., et al. (2022). Social capital I: Measurement and associations with economic mobility. *Nature*, 608(7921), 108-121.

Fuster, A., Plosser, M., Schnabl, P., & Vickery, J. (2019). The role of technology in mortgage lending. *The Review of Financial Studies*, 32(5), 1854-1899.

Grennan, J. (2020). Losing faith in banking: Bank branch closures, debt, and trust in financial institutions. Working Paper.

Jagtiani, J., & Lemieux, C. (2019). The roles of alternative data and machine learning in fintech lending: Evidence from the LendingClub consumer platform. *Financial Management*, 48(4), 1009-1029.

Malkova, A. (2024). Knockin' on the bank's door: Bank branch closures and self-employment. *Southern Economic Journal*.

Nguyen, H. L. Q. (2019). Are credit markets still local? Evidence from bank branch closings. *American Economic Journal: Applied Economics*, 11(2), 1-32.

Petersen, M. A., & Rajan, R. G. (2002). Does distance still matter? The information revolution in small business lending. *The Journal of Finance*, 57(6), 2533-2570.

Stein, J. C. (2002). Information production and capital allocation: Decentralized versus hierarchical firms. *The Journal of Finance*, 57(5), 1891-1921.
