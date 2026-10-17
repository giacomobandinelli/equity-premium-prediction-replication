# Full Results

Complete results for all 40 predictors. The README summarises the main findings; this file lists every variable. The same numbers are in `Output/Table_01_Replication.docx` and `Output/Table_02_SampleRobustness.docx`, and the underlying values are in the CSV files in `Output/`.

## Table 1: In-sample and out-of-sample results, main sample (to December 2021)

### Panel A: Predictors replicated from Goyal, Welch & Zafirov (2024)

| Variable | Name | Freq | n | β | NW t | IS R² (%) | OOS R² (%) | Joint p |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `ogap` | Output gap | M | 1140 | -0.16 | -0.40 | 0.09 | -0.03 | 0.20 |
| `wtexas` | Oil price change | M | 910 | -0.08 | -0.48 | 0.04 | -0.34 | 0.60 |
| `ndrbl` | New orders to shipments | M | 358 | 0.03 | 0.09 | 0.00 | -0.44 | 0.60 |
| `ygap` | Yield gap | M | 824 | 0.03 | 0.15 | 0.01 | -0.85 | 0.86 |
| `dp` | Dividend-price ratio | M | 1140 | 0.04 | 0.16 | 0.01 | 0.02 | 0.31 |
| `dy` | Dividend yield | M | 1140 | 0.08 | 0.33 | 0.03 | 0.15 | 0.11 |
| `ep` | Earnings-price ratio | M | 1140 | 0.16 | 0.93 | 0.10 | -0.57 | 0.40 |
| `de` | Dividend-payout ratio | M | 1140 | -0.15 | -0.51 | 0.09 | -1.00 | 0.64 |
| `svar` | Stock variance | M | 1140 | -0.11 | -0.26 | 0.05 | 0.02 | 0.23 |
| `bm_agg` | Book-to-market | M | 1140 | 0.16 | 0.43 | 0.09 | -0.60 | 0.66 |
| `ntis` | Net equity expansion | M | 1140 | -0.34 | -1.19 | 0.44 | -0.13 | 0.18 |
| `tbl` | Treasury-bill yield | M | 1140 | -0.29* | -1.92 | 0.32 | 0.41** | 0.02 ✓ |
| `lty` | Long-term yield | M | 1140 | -0.24 | -1.64 | 0.22 | 0.48** | 0.02 ✓ |
| `ltr` | Long-term return | M | 1140 | 0.22 | 1.56 | 0.18 | -0.38 | 0.12 |
| `tms` | Term spread | M | 1140 | 0.17 | 1.05 | 0.12 | -0.09 | 0.24 |
| `dfy` | Default yield spread | M | 1140 | -0.01 | -0.02 | 0.00 | -0.06 | 0.39 |
| `infl` | Inflation | M | 1140 | -0.20 | -0.90 | 0.15 | 0.22* | 0.05 |
| `crdstd` | Credit standards | Q | 126 | -1.74 | -1.60 | 4.87 | 4.14** | 0.02 ✓ |
| `gpce` | Consumption growth | A | 74 | -5.05*** | -4.23 | 9.93 | 3.38* | 0.00 ✓ |
| `gip` | Industrial-production growth | A | 95 | -0.96 | -0.23 | 0.26 | -0.63 | 0.41 |

### Panel B: New predictors (tidyfinance factor library)

| Variable | Name | Freq | n | β | NW t | IS R² (%) | OOS R² (%) | Joint p |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `ocm` | Operating cash flow to market | M | 474 | 0.12 | 0.47 | 0.08 | -0.34 | 0.50 |
| `sm` | Sales to market | M | 737 | 0.00 | -0.01 | 0.00 | -0.23 | 0.69 |
| `ebm` | Enterprise book-to-market | M | 708 | -0.08 | -0.45 | 0.04 | -0.01 | 0.28 |
| `dm` | Debt to market | M | 737 | 0.11 | 0.66 | 0.07 | 0.19 | 0.12 |
| `npy` | Net payout yield | M | 737 | -0.13 | -0.73 | 0.10 | -0.01 | 0.26 |
| `csi` | Composite share issuance | M | 677 | -0.36* | -1.90 | 0.71 | 0.90** | 0.01 ✓ |
| `nef` | Net equity financing | M | 600 | -0.22 | -1.16 | 0.26 | -0.21 | 0.20 |
| `nxf` | Net external financing | M | 600 | -0.23 | -1.21 | 0.30 | -0.08 | 0.16 |
| `cdi` | Composite debt issuance | M | 677 | -0.14 | -0.72 | 0.11 | -0.61 | 0.46 |
| `me` | Size | M | 737 | 0.22 | 1.29 | 0.28 | 0.46* | 0.04 ✓ |
| `beta` | Market beta | M | 672 | 0.24 | 1.37 | 0.32 | 0.59** | 0.04 ✓ |
| `ivol` | Idiosyncratic volatility | M | 695 | -0.18 | -0.92 | 0.18 | 0.50* | 0.06 |
| `iskew` | Idiosyncratic skewness | M | 695 | -0.23 | -1.46 | 0.30 | 0.16 | 0.10 |
| `dfnl` | Change in financial liabilities | M | 725 | -0.19 | -1.07 | 0.21 | 0.08 | 0.18 |
| `mom` | Momentum | M | 726 | -0.10 | -0.65 | 0.06 | 0.02 | 0.26 |
| `rev` | Long-term reversal | M | 678 | -0.26 | -1.20 | 0.38 | 0.51* | 0.05 |
| `gpa` | Gross profitability | M | 737 | -0.13 | -0.81 | 0.10 | 0.29* | 0.08 |
| `ag` | Asset growth | M | 725 | -0.08 | -0.52 | 0.04 | -0.04 | 0.31 |
| `roe` | Return on equity | M | 660 | -0.11 | -0.52 | 0.06 | -0.03 | 0.31 |
| `sue` | Earnings surprise | M | 593 | -0.13 | -0.70 | 0.09 | -0.08 | 0.32 |

**Notes.**
- Each row is the predictive regression $r_{t+1} = \alpha + \beta x_t + \varepsilon_{t+1}$, where $r$ is the log equity premium in percentage points and $x$ is the predictor, lagged one period and standardised. β is the change in the next period's premium for a one-standard-deviation increase in the predictor.
- Freq: M = monthly, Q = quarterly, A = annual. n is the number of non-overlapping observations.
- NW t is the Newey–West t-statistic with one lag. IS R² is the in-sample R².
- OOS R² is the Campbell–Thompson out-of-sample R² against the prevailing mean, with negative forecasts set to zero. The first 20 years of each variable (10 for crdstd) are used for estimation only. For ogap, the out-of-sample forecasts use a real-time version of the output gap.
- β stars come from a two-sided bootstrap test of the Newey–West t-statistic (10,000 replications). OOS R² stars come from a one-sided bootstrap test of the MSE-F statistic (1,000 replications). Both are under the null of no predictability.
- Joint p is the bootstrapped joint significance of the in-sample and out-of-sample results (1,000 replications); ✓ marks p < 0.05.
- Significance: `*` p ≤ 0.10, `**` p ≤ 0.05, `***` p ≤ 0.01.

## Table 2: Sample robustness, main sample (to December 2021) against extended sample (to November 2023)

### Panel A: Predictors replicated from Goyal, Welch & Zafirov (2024)

| Variable | β (main) | NW t (main) | OOS R² % (main) | β (ext.) | NW t (ext.) | OOS R² % (ext.) |
|---|---:|---:|---:|---:|---:|---:|
| `ogap` | -0.16 | -0.40 | -0.03 | -0.15 | -0.39 | -0.03 |
| `wtexas` | -0.08 | -0.48 | -0.34 | -0.11 | -0.72 | -0.28 |
| `ndrbl` | 0.03 | 0.09 | -0.44 | 0.00 | 0.02 | -0.35 |
| `ygap` | 0.03 | 0.15 | -0.85 | 0.05 | 0.25 | -0.79 |
| `dp` | 0.04 | 0.16 | 0.02 | 0.07 | 0.29 | 0.03 |
| `dy` | 0.08 | 0.33 | 0.15 | 0.11 | 0.43 | 0.17 |
| `ep` | 0.16 | 0.93 | -0.57 | 0.18 | 1.02 | -0.50 |
| `de` | -0.15 | -0.51 | -1.00 | -0.13 | -0.42 | -1.01 |
| `svar` | -0.11 | -0.26 | 0.02 | -0.11 | -0.27 | 0.02 |
| `bm_agg` | 0.16 | 0.43 | -0.60 | 0.17 | 0.48 | -0.54 |
| `ntis` | -0.34 | -1.19 | -0.13 | -0.33 | -1.19 | -0.16 |
| `tbl` | -0.29* | -1.92 | 0.41** | -0.27 | -1.77 | 0.30 |
| `lty` | -0.24 | -1.64 | 0.48** | -0.22 | -1.50 | 0.39 |
| `ltr` | 0.22 | 1.56 | -0.38 | 0.21 | 1.51 | -0.39 |
| `tms` | 0.17 | 1.05 | -0.09 | 0.16 | 1.00 | -0.10 |
| `dfy` | -0.01 | -0.02 | -0.06 | 0.00 | -0.01 | -0.06 |
| `infl` | -0.20 | -0.90 | 0.22* | -0.21 | -0.96 | 0.24 |
| `crdstd` | -1.74 | -1.60 | 4.14** | -1.30 | -1.28 | 1.96 |
| `gpce` | -5.05*** | -4.23 | 3.38* | -5.20 | -4.43 | 4.29 |
| `gip` | -0.96 | -0.23 | -0.63 | -1.01 | -0.24 | -0.56 |

### Panel B: New predictors (tidyfinance factor library)

| Variable | β (main) | NW t (main) | OOS R² % (main) | β (ext.) | NW t (ext.) | OOS R² % (ext.) |
|---|---:|---:|---:|---:|---:|---:|
| `ocm` | 0.12 | 0.47 | -0.34 | 0.03 | 0.14 | -0.44 |
| `sm` | 0.00 | -0.01 | -0.23 | -0.06 | -0.38 | -0.20 |
| `ebm` | -0.08 | -0.45 | -0.01 | -0.11 | -0.62 | 0.02 |
| `dm` | 0.11 | 0.66 | 0.19 | 0.06 | 0.34 | 0.09 |
| `npy` | -0.13 | -0.73 | -0.01 | -0.16 | -0.92 | 0.06 |
| `csi` | -0.36* | -1.90 | 0.90** | -0.38 | -2.06 | 0.86 |
| `nef` | -0.22 | -1.16 | -0.21 | -0.22 | -1.23 | -0.18 |
| `nxf` | -0.23 | -1.21 | -0.08 | -0.21 | -1.11 | -0.27 |
| `cdi` | -0.14 | -0.72 | -0.61 | -0.17 | -0.90 | -0.46 |
| `me` | 0.22 | 1.29 | 0.46* | 0.21 | 1.24 | 0.42 |
| `beta` | 0.24 | 1.37 | 0.59** | 0.17 | 0.95 | 0.45 |
| `ivol` | -0.18 | -0.92 | 0.50* | -0.15 | -0.77 | 0.38 |
| `iskew` | -0.23 | -1.46 | 0.16 | -0.20 | -1.29 | 0.04 |
| `dfnl` | -0.19 | -1.07 | 0.08 | -0.25 | -1.44 | 0.19 |
| `mom` | -0.10 | -0.65 | 0.02 | -0.07 | -0.44 | -0.05 |
| `rev` | -0.26 | -1.20 | 0.51* | -0.32 | -1.51 | 0.69 |
| `gpa` | -0.13 | -0.81 | 0.29* | -0.10 | -0.59 | 0.20 |
| `ag` | -0.08 | -0.52 | -0.04 | -0.11 | -0.68 | -0.06 |
| `roe` | -0.11 | -0.52 | -0.03 | -0.12 | -0.59 | -0.01 |
| `sue` | -0.13 | -0.70 | -0.08 | -0.09 | -0.47 | -0.16 |

**Notes.** Same regressions and statistics as Table 1, estimated over the main and the extended sample. The bootstraps run on the main sample only, so the extended-sample columns have no significance stars.
