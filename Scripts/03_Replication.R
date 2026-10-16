# We reproduce the paper's two main analyses for all forty variables:
# the homologous in-sample regressions and the Campbell-Thompson
# out-of-sample tests,covering both the main sample ending in December 2021 
# (matching the paper) and the extended sample ending in November 2023.

source("Scripts/01_Setup.R")

dir.create("Output", showWarnings = FALSE)

# We build a helper that runs the full replication for one panel and
# tags every row with the sample label. The script calls it twice
# below, once for the main sample and once for the extended sample,
# and binds the two results into one table
run_replication_for_sample <- function(full_panel, sample_label) {
  
  # We build the quarterly and annual versions of the target once,
  # inside the helper, so each sample gets targets computed from its
  # own panel. They are needed because crdstd is quarterly and gpce
  # and gip are annual, and every regression pairs each predictor
  # with the premium summed over its own horizon
  quarterly_target <- full_panel %>%
    mutate(period = floor_date(date, "quarter")) %>%
    group_by(period) %>%
    summarise(target_q = sum(equity_premium)) %>%
    rename(date = period)
  
  annual_target <- full_panel %>%
    mutate(period = floor_date(date, "year")) %>%
    group_by(period) %>%
    summarise(target_a = sum(equity_premium)) %>%
    rename(date = period)
  
  # We swap the real-time output gap into a copy of the panel. Every
  # out-of-sample calculation for ogap must use the real-time
  # version, because GWZ's appendix requires the OOS variable to use
  # data only up to the period of the trend regression. The
  # in-sample regressions keep the full-sample ogap, matching the
  # paper
  ogap_realtime <- read_csv("Data/Processed/ogap_realtime.csv")
  
  panel_ogap_realtime <- full_panel %>%
    select(-ogap) %>%
    left_join(ogap_realtime %>% rename(ogap = ogap_realtime), by = "date")
  
  # We define all forty variables in one table, each with its
  # frequency and the length of its initial estimation window for
  # the out-of-sample tests. Following GWZ, the first forecast uses
  # twenty years of data. The one exception is crdstd: its data
  # begin only in 1990 and GWZ therefore starts its out-of-sample period after ten years
  variable_settings <- tibble(
    variable = c(
      "dp", "dy", "ep", "de", "svar", "bm_agg", "ntis",
      "tbl", "lty", "ltr", "tms", "dfy", "infl",
      "ogap", "wtexas", "ygap", "ndrbl",
      "ocm", "sm", "ebm", "npy",
      "csi", "nef", "nxf", "cdi",
      "ivol", "iskew", "beta",
      "dm", "dfnl",
      "mom", "gpa", "ag", "rev", "me", "roe", "sue",
      "crdstd", "gpce", "gip"
    ),
    frequency = c(
      rep("monthly", 37),
      "quarterly", "annual", "annual"
    ),
    initial_window_years = c(
      rep(20, 37),
      10, 20, 20
    )
  )
  
  # In-sample homologous regression for one predictor. We regress the
  # premium, in percentage points, on the standardized once-lagged
  # predictor and report a Newey-West t-statistic with one lag. The
  # standardization matches the paper's Table 3: each coefficient is
  # the effect of a one standard deviation move in the predictor,
  # which makes variables with different units comparable
  run_homologous <- function(data, predictor, frequency = "monthly") {
    
    reg_data <- build_regression_data(data, predictor, frequency,
                                      quarterly_target = quarterly_target,
                                      annual_target = annual_target) %>%
      mutate(
        target_pct = target * 100,
        predictor_z = as.numeric(scale(predictor_lag))
      )
    
    model <- lm(target_pct ~ predictor_z, data = reg_data)
    nw_result <- coeftest(model, vcov = NeweyWest(model, lag = 1))
    
    tibble(
      variable = predictor,
      frequency = frequency,
      n_obs = nrow(reg_data),
      coefficient = nw_result["predictor_z", "Estimate"],
      nw_t = nw_result["predictor_z", "t value"],
      r_squared = summary(model)$r.squared
    )
  }
  
  homologous_results <- pmap_dfr(
    variable_settings %>% select(variable, frequency),
    function(variable, frequency) run_homologous(full_panel, variable, frequency)
  ) %>%
    mutate(sample = sample_label)
  
  # Out-of-sample Campbell-Thompson test for one predictor. We
  # convert the initial window length into the index of the first
  # forecast and hand the data to the shared run_oos_once loop, which
  # expands the estimation window, truncates negative forecasts at
  # zero, and benchmarks against the historical mean
  run_oos_ct <- function(data, predictor, frequency = "monthly",
                         initial_window_years = 20) {
    
    reg_data <- build_regression_data(data, predictor, frequency,
                                      quarterly_target = quarterly_target,
                                      annual_target = annual_target)
    
    n <- nrow(reg_data)
    cutoff <- reg_data$date[1] %m+% years(initial_window_years)
    start_index <- sum(reg_data$date <= cutoff) + 1
    
    oos <- run_oos_once(reg_data, start_index)
    
    tibble(
      variable = predictor,
      frequency = frequency,
      oos_start = reg_data$date[start_index],
      n_oos = n - start_index + 1,
      oos_r2 = oos$oos_r2
    )
  }
  
  # We run the test for every variable. ogap alone uses the real-time panel
  oos_results <- pmap_dfr(
    variable_settings,
    function(variable, frequency, initial_window_years) {
      input_panel <- if (variable == "ogap") panel_ogap_realtime else full_panel
      run_oos_ct(input_panel, variable, frequency, initial_window_years)
    }
  ) %>%
    mutate(sample = sample_label)
  
  list(homologous = homologous_results, oos = oos_results)
}

# We run the replication on both sample ends and put the results together.
main_panel     <- read_csv("Data/Processed/full_panel.csv")
extended_panel <- read_csv("Data/Processed/full_panel_extended.csv")

main_run     <- run_replication_for_sample(main_panel, "main")
extended_run <- run_replication_for_sample(extended_panel, "extended")

homologous_results <- bind_rows(main_run$homologous, extended_run$homologous)
oos_results        <- bind_rows(main_run$oos, extended_run$oos)

write_csv(homologous_results, "Output/homologous_results.csv")
write_csv(oos_results, "Output/oos_results.csv")