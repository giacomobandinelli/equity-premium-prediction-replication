# Equity Premium Prediction: Replication and Extension of Goyal, Welch & Zafirov (2024)

Replication and extension of Goyal, Welch & Zafirov (2024), ["A Comprehensive 2022 Look at the Empirical Performance of Equity Premium Prediction"](https://academic.oup.com/rfs/article/37/11/3490/7749383), *Review of Financial Studies* 37(11), using **public data only**.

---

## Research question

Can any variable predict next period's US equity premium better than the historical average of past returns?

The authors (GWZ) test 46 predictors from the literature. They put every predictor through the same regression and the same in-sample and out-of-sample tests, and they find that almost none beat the historical average. This project:

1. **Replicates** 20 of their predictors with public data only.
2. **Extends** the analysis to 20 new predictors: long-short factor portfolio returns from the tidyfinance factor library.
3. **Tests robustness** by extending the sample from December 2021 to November 2023.

## Data sources

All data are downloaded programmatically through the [`tidyfinance`](https://cran.r-project.org/package=tidyfinance) R package. Nothing is entered by hand.

| Source | Variables |
|---|---|
| Goyal's monthly predictor file (Welch–Goyal data) | Equity premium and 13 predictors: dp, dy, ep, de, svar, bm_agg, ntis, tbl, lty, ltr, tms, dfy, infl |
| FRED | ogap and gip (INDPRO), wtexas (WTISPLC), gpce (A796RX0Q048SBEA + A797RX0Q048SBEA), ndrbl (DGORDER / AMDMVS), crdstd (DRTSCILM, Senior Loan Officer Opinion Survey), ygap (GS10, combined with ep from Goyal's file) |
| tidyfinance factor library | 20 long-short portfolios: ocm, sm, ebm, dm, npy, csi, nef, nxf, cdi, me, beta, ivol, iskew, dfnl, mom, rev, gpa, ag, roe, sue |

**Equity premium.** The monthly log change of the S&P 500 index plus trailing twelve-month dividends, minus the monthly Treasury-bill rate.

**Samples.** The main sample runs from January 1927 to December 2021, matching GWZ's end date. The extended sample runs to November 2023. Each predictor enters only from its first available observation.

**Differences from GWZ's data**

| Difference | Reason |
|---|---|
| Equity premium from Goyal's S&P-based series, not CRSP | CRSP is not publicly available |
| wtexas starts in 1946 instead of 1926 | GWZ use Global Financial Data, which requires a subscription |
| ndrbl starts in 1992 instead of 1958 | The older Census series is not on FRED |
| The earnings-price ratio in ygap comes from Goyal's file | GWZ take it from Shiller's website |

## Methods

- **Predictive regression.** The model is $r_{t+1} = \alpha + \beta x_t + \varepsilon_{t+1}$. Every predictor is lagged one period, so it only uses information available before the return it forecasts.
  - In the in-sample regressions the predictor is standardised and the premium is in percentage points, so $\beta$ is the effect of a one-standard-deviation move.
  - Each variable is tested at its own frequency (GWZ's "homologous" specification). For the quarterly predictor (crdstd) and the annual ones (gpce, gip), the previous period's value forecasts the monthly log premium summed over the following calendar quarter or calendar year.
- **In-sample inference.** Newey–West t-statistics with one lag.
- **Out-of-sample evaluation.**
  - Expanding-window forecasts are compared with the prevailing mean of past returns, measured by the Campbell–Thompson out-of-sample R² (any negative forecast is set to zero).
  - The first 20 years of each variable are used for estimation only. crdstd is the exception: its data start in 1990, so it uses a 10-year initial window.
  - Significance comes from the MSE-F statistic of Clark and McCracken (2001) and McCracken (2007).
- **Bootstrap under the null of no predictability.** Following GWZ's appendix, three data-generating processes:
  - **AR(1) with Stambaugh-corrected persistence** for persistent level variables. Return and predictor shocks are drawn as pairs, which keeps their cross-correlation.
  - **iid** draws for growth rates and for the factor portfolio returns.
  - **Macro filter** for ogap: industrial production is simulated and the quadratic trend is refitted in every replication.
- **Joint test.** The joint in-sample/out-of-sample p-value is computed from the same simulated draws, so it accounts for the dependence between the two statistics.
- **Replications.** The in-sample bootstrap uses 10,000 replications; the out-of-sample and joint bootstraps use 1,000 (GWZ use 10,000). 1,000 replications take about five hours, so this keeps the project practical to rerun.

## Key results

Main sample. β is in percentage points per standard deviation; R² values are in per cent.
Significance: `*` p ≤ 0.10, `**` p ≤ 0.05, `***` p ≤ 0.01. A joint p-value below 0.05 means joint significance.

**Replicated predictors that beat the historical average out of sample**

| Variable | Freq | n | β | NW t | OOS R² | Joint p | GWZ β | GWZ OOS R² | GWZ joint |
|---|---|---|---|---|---|---|---|---|---|
| tbl (T-bill yield) | M | 1140 | −0.29* | −1.92 | 0.41** | 0.02 ✓ | −0.29 | 0.37 | ✓ |
| lty (long-term yield) | M | 1140 | −0.24 | −1.64 | 0.48** | 0.02 ✓ | −0.24 | 0.25 | ✓ |
| infl (inflation) | M | 1140 | −0.20 | −0.90 | 0.22* | 0.05 | −0.21 | 0.10 | – |
| crdstd (bank credit standards) | Q | 126 | −1.74 | −1.60 | 4.14** | 0.02 ✓ | −1.72 | 4.54 | ✓ |
| gpce (consumption growth) | A | 74 | −5.05*** | −4.23 | 3.38* | 0.00 ✓ | −5.78 | 5.43 | ✓ |

**New predictors (extension) with significant out-of-sample gains**

| Variable | n | β | NW t | OOS R² | Joint p | OOS R², sample to 2023 |
|---|---|---|---|---|---|---|
| csi (composite share issuance) | 677 | −0.36* | −1.90 | 0.90** | 0.01 ✓ | 0.86 |
| beta (market beta) | 672 | 0.24 | 1.37 | 0.59** | 0.04 ✓ | 0.45 |
| me (size) | 737 | 0.22 | 1.29 | 0.46* | 0.04 ✓ | 0.42 |
| rev (long-term reversal) | 678 | −0.26 | −1.20 | 0.51* | 0.05 | 0.69 |
| ivol (idiosyncratic volatility) | 695 | −0.18 | −0.92 | 0.50* | 0.06 | 0.38 |
| gpa (gross profitability) | 737 | −0.13 | −0.81 | 0.29* | 0.08 | 0.20 |

**Summary**
- Only **11 of 40** predictors beat the historical average out of sample at the 10% level, and **7 of 40** are jointly significant.
- The predictors that work are related to interest rates, credit and macroeconomic conditions (replicated set), and to issuance and risk (extension). None of the valuation ratios work.
- **Robustness to 2023:**
  - Coefficient signs and sizes barely change for almost all predictors. The bootstraps run on the main sample only, so the extended sample reports estimates without significance tests.
  - crdstd is the least stable: its out-of-sample R² falls from 4.14% to 1.96%. This matches GWZ's own warning that most of its performance comes from 2000–2002.
  - gpce strengthens, from 3.38% to 4.29%.

Full tables for all 40 predictors are in `Output/Table_01_Replication.docx` and `Output/Table_02_SampleRobustness.docx`.

## Comparison with the original paper

| Group | Match | Cause of any difference |
|---|---|---|
| Interest rate, credit and macro variables (tbl, lty, ltr, tms, infl, crdstd) | Coefficients differ by at most 0.02. Among the replicated variables, the same four (tbl, lty, crdstd, gpce) are jointly significant in both studies. | Same underlying data |
| Valuation ratios (dp, dy, ep, bm_agg, ygap) | Our coefficients are smaller: dp 0.04 vs 0.17, ep 0.16 vs 0.27. None are significant in either study. | Different equity premium series: Goyal's S&P-based series instead of CRSP |
| wtexas, ndrbl | wtexas OOS R² −0.34 vs 0.14; ndrbl β 0.03 vs −0.27, but out-of-sample results are close (−0.44 vs −0.47) | Shorter public samples miss the pre-war oil market (wtexas) and the 1974–75 oil-shock bear market (ndrbl) |
| ogap | β −0.16 vs −0.22; OOS R² −0.03 vs −0.20 | In-sample, ogap uses a quadratic trend fitted on the full sample, as in GWZ. That would leak future data into the forecasts, so out of sample the trend is re-estimated at each date with only the data available up to then. |
| gip | β −0.96 vs −0.28; neither significant | Short annual sample (95 years), where a few extreme years dominate; possibly data revisions |
| infl joint test | p = 0.05 vs GWZ 0.09 | Borderline case; 1,000 vs 10,000 bootstrap replications |

Overall, the results closely approximate GWZ's but are not an exact copy.

## Conclusion

Used one at a time in a simple linear regression, almost no predictor beats the historical average, and the few that do offer small, sample-dependent gains. This does not mean the equity premium is unpredictable. Models that combine several predictors, add control variables or allow non-linear relationships, as in Kelly, Malamud and Zhou (2024), may capture predictability that a single-variable regression misses.

## How to run

**Requirements:** R 4.2 or later.

```r
install.packages(c("tidyverse", "tidyfinance", "sandwich", "lmtest", "flextable", "officer"))
```

1. Open `Topic01_Replication.Rproj` in RStudio, or set the working directory to the repository root.
2. Run the scripts in order, each once. `01_Setup.R` is sourced automatically by each script.

| Script | What it does |
|---|---|
| `02_DataConstruction.R` | Downloads all data and builds the main and extended panels (needs internet) |
| `03_Replication.R` | In-sample regressions and out-of-sample R², both samples |
| `04_Bootstrap.R` | In-sample, out-of-sample and joint bootstraps (needs internet) |
| `05_PaperOutputs.R` | Writes the Word tables and variable availability file |

All results are written to `Output/`. The data files are not stored in this repository: script 02 downloads everything and fills `Data/Raw/` and `Data/Processed/`. Random seeds are fixed (`seed = 42`). FRED series are revised over time, so a fresh download can produce small numerical differences from the stored outputs.

## Repository structure

```
equity-premium-prediction-replication/
├── README.md
├── LICENSE
├── Topic01_Replication.Rproj
├── Scripts/
│   ├── 01_Setup.R            # shared functions: regression data, Newey–West t, OOS loop, real-time gap
│   ├── 02_DataConstruction.R
│   ├── 03_Replication.R
│   ├── 04_Bootstrap.R
│   └── 05_PaperOutputs.R
├── Data/
│   ├── Raw/                  # filled by script 02: snapshot of Goyal's file
│   └── Processed/            # filled by script 02: merged panels, real-time output gap
└── Output/                   # result CSVs and Word tables
```

## References

- Campbell, J.Y., Thompson, S.B. (2008). Predicting excess stock returns out of sample: Can anything beat the historical average? *Review of Financial Studies*, 21(4), 1509–1531.
- Clark, T.E., McCracken, M.W. (2001). Tests of equal forecast accuracy and encompassing for nested models. *Journal of Econometrics*, 105(1), 85–110.
- Goyal, A., Welch, I., Zafirov, A. (2024). A comprehensive 2022 look at the empirical performance of equity premium prediction. *Review of Financial Studies*, 37(11), 3490–3557.
- Kelly, B., Malamud, S., Zhou, K. (2024). The virtue of complexity in return prediction. *Journal of Finance*, 79(1), 459–503.
- McCracken, M.W. (2007). Asymptotics for out of sample tests of Granger causality. *Journal of Econometrics*, 140(2), 719–752.
- Newey, W.K., West, K.D. (1987). A simple, positive semi-definite, heteroskedasticity and autocorrelation consistent covariance matrix. *Econometrica*, 55(3), 703–708.
- Stambaugh, R.F. (1999). Predictive regressions. *Journal of Financial Economics*, 54(3), 375–421.
