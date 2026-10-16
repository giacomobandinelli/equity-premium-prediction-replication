# Packages and the four functions shared by all the scripts.
# Each script sources this file, so all of them use the same data
# construction, forecast loop, and test statistic.

library(tidyverse)      # We use this for all data cleaning and reshaping
library(tidyfinance)    # We use this to download the Goyal file, FRED series, and the factor library
library(sandwich)       # We use this for Newey-West covariance matrices
library(lmtest)         # We use this to apply those covariances to regression tests

# Builds the (y, x) pairs for one predictor at its own frequency.
# Monthly predictors are paired with next month's equity premium;
# quarterly and annual predictors with the log premium summed over
# the following quarter or year, which compounds it to the matching
# horizon (the homologous specification). The predictor is always
# lagged one period, so only information available before the return
# period enters the regression
build_regression_data <- function(data, predictor, frequency = "monthly",
                                  lag_periods = 1,
                                  quarterly_target = NULL,
                                  annual_target = NULL) {
  
  if (frequency == "monthly") {
    reg_data <- data %>%
      arrange(date) %>%
      mutate(predictor_lag = lag(.data[[predictor]], lag_periods)) %>%
      select(date, target = equity_premium, predictor_lag) %>%
      drop_na()
  }
  
  if (frequency == "quarterly") {
    reg_data <- data %>%
      filter(!is.na(.data[[predictor]])) %>%
      arrange(date) %>%
      mutate(predictor_lag = lag(.data[[predictor]], lag_periods)) %>%
      select(date, predictor_lag) %>%
      left_join(quarterly_target, by = "date") %>%
      select(date, target = target_q, predictor_lag) %>%
      drop_na()
  }
  
  if (frequency == "annual") {
    reg_data <- data %>%
      filter(!is.na(.data[[predictor]])) %>%
      arrange(date) %>%
      mutate(predictor_lag = lag(.data[[predictor]], lag_periods),
             year = year(date)) %>%
      select(year, predictor_lag) %>%
      left_join(annual_target %>% mutate(year = year(date)), by = "year") %>%
      mutate(date = make_date(year, 1, 1)) %>%
      select(date, target = target_a, predictor_lag) %>%
      drop_na()
  }
  
  reg_data %>% arrange(date)
}

# Newey-West t-statistic (lag 1) for a simple predictive regression.
# The in-sample tables and the bootstrap both call this one function,
# because bootstrapped critical values are only valid for the exact
# statistic we report.
nw_t_stat <- function(y, x) {
  model <- lm(y ~ x)
  coeftest(model, vcov = NeweyWest(model, lag = 1))[2, "t value"]
}

# Runs one full out-of-sample forecast test. We move through the data
# one date at a time, starting at start_index. At each date we fit the
# regression again, using only the observations that come before that
# date. We then forecast the next value. If the forecast is negative,
# we set it to zero, because Campbell and Thompson argue that a
# forecast of the equity premium should never be below zero. As a
# comparison, we also forecast with the simple average of all past
# values of the target. At the end we return two numbers: the
# out-of-sample R-squared, which tells us whether the model beat the
# simple average, and the MSE-F statistic, which the bootstrap in
# script 04 needs to test whether that improvement is significant.
run_oos_once <- function(reg_data, start_index) {
  n <- nrow(reg_data)
  model_sq_errors <- numeric(0)
  benchmark_sq_errors <- numeric(0)
  
  for (t in start_index:n) {
    train_data <- reg_data[1:(t - 1), ]
    test_row <- reg_data[t, ]
    
    model <- lm(target ~ predictor_lag, data = train_data)
    forecast <- max(as.numeric(predict(model, newdata = test_row)), 0)
    benchmark <- mean(train_data$target)
    actual <- test_row$target
    
    model_sq_errors <- c(model_sq_errors, (actual - forecast)^2)
    benchmark_sq_errors <- c(benchmark_sq_errors, (actual - benchmark)^2)
  }
  
  p <- length(model_sq_errors)
  mse_0 <- mean(benchmark_sq_errors)
  mse_1 <- mean(model_sq_errors)
  
  list(
    oos_r2 = 1 - sum(model_sq_errors) / sum(benchmark_sq_errors),
    mse_f = p * (mse_0 - mse_1) / mse_1
  )
}

# Builds a real-time version of a detrended gap variable. For every
# month s we fit a quadratic time trend using only months 1 to s, and
# we keep only the residual of month s. This way the gap value at any
# month uses no data from later months, which is what the GWZ appendix
# requires for out-of-sample tests of filter-based variables. We wait
# for min_obs months of data before producing the first value, because
# a trend fitted on very few points is not reliable.
realtime_quadratic_gap <- function(log_level, min_obs = 60) {
  n <- length(log_level)
  gap <- rep(NA_real_, n)
  for (s in min_obs:n) {
    t_idx <- 1:s
    fit <- .lm.fit(cbind(1, t_idx, t_idx^2), log_level[1:s])
    gap[s] <- fit$residuals[s]
  }
  gap
}