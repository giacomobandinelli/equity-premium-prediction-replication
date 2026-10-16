# We download every input and build the two analysis panels. The
# script has four parts: the Goyal and Welch predictor file, the
# seven variables we construct from FRED, the twenty new variables
# from the tidyfinance factor library, and the merge into one panel.

source("Scripts/01_Setup.R")


# We download Goyal's monthly predictor file, which contains the
# equity premium and thirteen of the paper's predictor variables
# already constructed
macro_predictors <- download_data(
  domain = "macro_predictors",
  dataset = "monthly"
)

# We rename bm to bm_agg to distinguish the aggregate Goyal
# book-to-market ratio from ebm, the cross-sectional book-to-market
# factor added later, so the two cannot be confused
macro_predictors <- macro_predictors %>%
  rename(bm_agg = bm)

# We save the raw download so the submitted data contain a frozen
# snapshot of the file our numbers are built from
write_csv(macro_predictors, "Data/Raw/macro_predictors.csv")


# Variables Built from FRED
# We download monthly industrial production, the input for three of
# the seven built variables
indpro_raw <- download_data(domain = "fred", series = "INDPRO")

# We build the output gap as the residual from regressing log
# industrial production on a linear and a quadratic time trend,
# following GWZ's appendix definition
ogap_data <- indpro_raw %>%
  arrange(date) %>%
  select(date, indpro = value) %>%
  mutate(
    log_indpro = log(indpro),
    t = row_number(),
    t2 = t^2
  )

ogap_model <- lm(log_indpro ~ t + t2, data = ogap_data)

ogap <- ogap_data %>%
  mutate(ogap = residuals(ogap_model)) %>%
  select(date, ogap)

# Real-time version of the output gap. The full-sample version above
# serves the in-sample results, matching the paper. However, all out-of-sample
# calculations must use this one instead, because GWZ's appendix
# requires the OOS gap to use data only up to the trend regression date.
ogap_realtime <- ogap_data %>%
  mutate(ogap_realtime = realtime_quadratic_gap(log_indpro)) %>%
  select(date, ogap_realtime)

# We build wtexas as the month-over-month percent change in the West
# Texas Intermediate oil price, matching the appendix formula.
wti_raw <- download_data(domain = "fred", series = "WTISPLC")

wtexas <- wti_raw %>%
  arrange(date) %>%
  mutate(wtexas = (value - lag(value)) / lag(value)) %>%
  select(date, wtexas)

# We measure gip as the growth of industrial production over the
# fourth quarter alone, because Moller and Rangvid define
# end-of-the-year growth as the December level of industrial
# production divided by the September level. We compute the
# three-month percent change on the monthly series first, then keep
# only the December value, which equals their December-over-September
# definition exactly
gip <- indpro_raw %>%
  arrange(date) %>%
  mutate(gip = (value - lag(value, 3)) / lag(value, 3)) %>%
  filter(month(date) == 12) %>%
  select(date, gip)

# We build gpce, the fourth-quarter growth rate of real per-capita
# consumption of nondurable goods and services, from the two FRED
# series listed in GWZ's appendix. We sum the two series, compute
# the quarter-over-quarter percent change, and keep only the
# October-dated observations, which FRED uses for the fourth quarter.
pce_nondurable_raw <- download_data(domain = "fred", series = "A796RX0Q048SBEA")
pce_services_raw   <- download_data(domain = "fred", series = "A797RX0Q048SBEA")

gpce <- pce_nondurable_raw %>%
  select(date, nondurable = value) %>%
  left_join(pce_services_raw %>% select(date, services = value), by = "date") %>%
  arrange(date) %>%
  mutate(
    pce_total = nondurable + services,
    pct_change = (pce_total - lag(pce_total)) / lag(pce_total)
  ) %>%
  filter(month(date) == 10) %>%
  select(date, gpce = pct_change)

# We build ndrbl as the log ratio of new orders to shipments of
# durable goods, matching the appendix formula. The two FRED series
# begin in 1992.
new_orders_raw <- download_data(domain = "fred", series = "DGORDER")
shipments_raw  <- download_data(domain = "fred", series = "AMDMVS")

ndrbl <- new_orders_raw %>%
  select(date, new_orders = value) %>%
  left_join(shipments_raw %>% select(date, shipments = value), by = "date") %>%
  arrange(date) %>%
  mutate(ndrbl = log(new_orders / shipments)) %>%
  select(date, ndrbl)

# We take the loan officer credit standards series unmodified, in
# percentage points, as GWZ's appendix specifies. The scale has no
# effect on any reported statistic: the in-sample regression
# standardizes the predictor and the out-of-sample loop
# re-estimates the slope
crdstd_raw <- download_data(domain = "fred", series = "DRTSCILM")

crdstd <- crdstd_raw %>%
  arrange(date) %>%
  select(date, crdstd = value)

# We build the yield gap as the log earnings-price ratio minus the
# log gross ten-year Treasury yield. We take the earnings-price ratio
# from the Goyal file and the yield from FRED, converting it from
# percent to decimal before taking the log
treasury_10y_raw <- download_data(domain = "fred", series = "GS10")

ygap <- macro_predictors %>%
  select(date, ep) %>%
  left_join(treasury_10y_raw %>% select(date, y10 = value), by = "date") %>%
  mutate(ygap = ep - log(1 + y10 / 100)) %>%
  select(date, ygap)


# New Variables from the Factor Library
new_variable_codes <- c(
  "ocm", "sm", "ebm", "npy",
  "csi", "nef", "nxf", "cdi",
  "ivol", "iskew", "beta",
  "dm", "dfnl",
  "mom", "gpa", "ag", "rev", "me", "roe",
  "sue"
)

# We wrap each download so one failure does not stop the other
# downloads. A failed variable is dropped from the merge, and the
# error only appears when script 03 first asks for the missing column
safe_download <- possibly(
  ~ download_data(
    domain = "tidyfinance",
    dataset = "factor_library",
    sorting_variable = .x
  ),
  otherwise = NULL
)

factor_library_list <- map(new_variable_codes, safe_download)
names(factor_library_list) <- new_variable_codes

# We stack the twenty downloads into one long table and keep only
# the date, the variable code, and the portfolio return
new_variables_data <- map_dfr(compact(factor_library_list), ~ .x %>%
                                select(date, sorting_variable, ret))


# Merged Panel
# Goyal stores the premium shifted forward: rp_div in month t's row
# is the premium earned in month t + 1. Our build_regression_data
# lags the predictor instead, and keeping both shifts would put a
# two-month gap between predictor and return. We shift the premium
# back one row, so each row holds the premium earned in that month
paper_variables <- macro_predictors %>%
  arrange(date) %>%
  mutate(equity_premium = lag(rp_div, 1)) %>%
  left_join(ogap,   by = "date") %>%
  left_join(wtexas, by = "date") %>%
  left_join(gip,    by = "date") %>%
  left_join(gpce,   by = "date") %>%
  left_join(ndrbl,  by = "date") %>%
  left_join(crdstd, by = "date") %>%
  left_join(ygap,   by = "date")

# We spread the twenty new variables into one column each and join
# them onto the same monthly date grid
new_variables_wide <- new_variables_data %>%
  pivot_wider(names_from = sorting_variable, values_from = ret)

full_panel <- paper_variables %>%
  left_join(new_variables_wide, by = "date")

# We replace exact zeros in the twenty new variables with NA,
# because the factor library reports an exact zero return before
# enough firms exist to build a valid portfolio. An exact zero
# therefore always means not yet observed, never a genuine return
full_panel <- full_panel %>%
  arrange(date) %>%
  mutate(across(all_of(new_variable_codes), ~ na_if(.x, 0)))

# We save two panels. GWZ's sample ends in December 2021, so we trim
# the main panel to that date and compute every replication number
# over the same period as the paper. The extended panel serves as
# an alternative sample period in the robustness analysis
full_panel_extended <- full_panel

full_panel <- full_panel %>%
  filter(date <= as.Date("2021-12-01"))

write_csv(ogap_realtime,      "Data/Processed/ogap_realtime.csv")
write_csv(full_panel,         "Data/Processed/full_panel.csv")
write_csv(full_panel_extended, "Data/Processed/full_panel_extended.csv")