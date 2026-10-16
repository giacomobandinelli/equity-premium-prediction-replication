# We compute bootstrapped significance for the replication: p-values
# for the in-sample Newey-West t-statistics, for the out-of-sample
# MSE-F statistics, and for the conjoint in-sample and out-of-sample
# test, all under GWZ's null of no predictability.
source("Scripts/01_Setup.R")

# We load the finished panel. The bootstraps run on the main sample
# only, which ends in December 2021 and matches the paper
full_panel <- read_csv("Data/Processed/full_panel.csv")

dir.create("Output", showWarnings = FALSE)

# We build the frequency-matched targets once, because crdstd, gpce,
# and gip must be bootstrapped at their own frequency.
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

# We swap the real-time output gap into a copy of the panel
ogap_realtime <- read_csv("Data/Processed/ogap_realtime.csv")

panel_ogap_realtime <- full_panel %>%
  select(-ogap) %>%
  left_join(ogap_realtime %>% rename(ogap = ogap_realtime), by = "date")

# We download raw industrial production once, because ogap's
# bootstrap recipe rebuilds the variable from a simulated production
# series in every replication
indpro_raw <- download_data(domain = "fred", series = "INDPRO")

indpro_sorted <- indpro_raw %>% arrange(date)
log_level_indpro <- log(indpro_sorted$value)
growth_indpro <- diff(log_level_indpro)

# We give each of the forty variables its frequency, its initial
# out-of-sample window, and the process that simulates it under the
# null of no predictability. Following GWZ's appendix: persistent
# level-type variables get an AR(1) with Stambaugh-corrected
# persistence; the growth rates wtexas, gpce, and gip are drawn iid;
# and ogap is rebuilt from a simulated production series
# (macro_filter). Our twenty long-short portfolio returns are also
# drawn iid, because monthly long-short returns show essentially no
# serial correlation, so an AR(1) adds nothing for them
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

dgp_settings <- tibble(
  variable = variable_settings$variable,
  dgp_type = case_when(
    variable_settings$variable == "ogap" ~ "macro_filter",
    variable_settings$variable %in% c("wtexas", "gpce", "gip") ~ "iid",
    variable_settings$variable %in% c(
      "dp", "dy", "ep", "de", "svar", "bm_agg", "ntis",
      "tbl", "lty", "ltr", "tms", "dfy", "infl",
      "ygap", "ndrbl", "crdstd"
    ) ~ "ar1",
    TRUE ~ "iid"
  )
)

bootstrap_settings <- variable_settings %>%
  left_join(dgp_settings, by = "variable")




# In-sample bootstrap under the null of no predictability. 
# The simulated predictor follows an AR(1) whose persistence is Stambaugh-corrected.
# The simulated return is its own sample mean plus a
# resampled residual, so it is unpredictable by construction. We
# simulate ten percent extra observations, started at the sample
# mean, and drop them as burn-in so the starting value leaves no
# trace, all as the appendix describes.
run_ar1_bootstrap <- function(x_t, y_t1, n_boot, seed) {
  set.seed(seed)
  n <- length(y_t1)
  
  alpha_hat <- mean(y_t1)
  u1 <- y_t1 - alpha_hat
  
  x_lag <- x_t[1:(n - 1)]
  x_lead <- x_t[2:n]
  ar1_model <- lm(x_lead ~ x_lag)
  rho_hat <- coef(ar1_model)[2]
  rho_star <- rho_hat + (1 + 3 * rho_hat) / n
  mu_star <- mean(x_t) * (1 - rho_star)
  u2 <- x_lead - mu_star - rho_star * x_lag
  
  n_sim <- floor(n * 1.1)
  n_burn <- n_sim - n
  boot_t <- numeric(n_boot)
  
  for (b in 1:n_boot) {
    # We draw one shared index for both residual series because the
    # appendix requires the bootstrap to preserve the
    # cross-correlation of the return and predictor shocks.
    draw_idx <- sample(1:(n - 1), n_sim, replace = TRUE)
    u1_star <- u1[draw_idx]
    u2_star <- u2[draw_idx]
    
    x_sim <- numeric(n_sim + 1)
    x_sim[1] <- mean(x_t)
    for (s in 1:n_sim) {
      x_sim[s + 1] <- mu_star + rho_star * x_sim[s] + u2_star[s]
    }
    y_sim <- alpha_hat + u1_star
    
    keep_idx <- (n_burn + 1):n_sim
    boot_t[b] <- nw_t_stat(y_sim[keep_idx], x_sim[keep_idx])
  }
  
  boot_t
}

# We run the iid bootstrap, GWZ's rule for the growth-rate
# variables. We draw x and y with two independent random indices,
# so any relation in a simulated draw is due to chance alone.
run_iid_bootstrap <- function(x_t, y_t1, n_boot, seed) {
  set.seed(seed)
  n <- length(y_t1)
  
  alpha_hat <- mean(y_t1)
  u1 <- y_t1 - alpha_hat
  
  boot_t <- numeric(n_boot)
  
  for (b in 1:n_boot) {
    y_sim <- alpha_hat + u1[sample(1:n, n, replace = TRUE)]
    x_sim <- x_t[sample(1:n, n, replace = TRUE)]
    
    boot_t[b] <- nw_t_stat(y_sim, x_sim)
  }
  
  boot_t
}

# We run the macro-filter recipe, specific to ogap. We resample the
# growth rate of industrial production, rebuild a simulated level
# series, and refit the same full-sample quadratic trend used to
# build the real in-sample variable, as the appendix states.
# We keep the simulated predictor in its own time order
# rather than reshuffling it, because the appendix builds the
# bootstrapped x by applying the filter to the simulated series.
# Only y is resampled, which imposes the null
run_macro_filter_bootstrap <- function(target_dates, y_t1, n_boot, seed) {
  set.seed(seed)
  
  n_raw <- length(log_level_indpro)
  n_target <- length(y_t1)
  alpha_hat <- mean(y_t1)
  u1 <- y_t1 - alpha_hat
  
  t_index <- 1:n_raw
  trend_x <- cbind(1, t_index, t_index^2)
  date_pos <- match(target_dates, indpro_sorted$date)
  
  boot_t <- numeric(n_boot)
  
  for (b in 1:n_boot) {
    growth_draw <- sample(growth_indpro, n_raw - 1, replace = TRUE)
    sim_level <- log_level_indpro[1] + c(0, cumsum(growth_draw))
    
    sim_gap <- .lm.fit(trend_x, sim_level)$residuals
    sim_gap_lag <- dplyr::lag(sim_gap, 1)
    
    x_sim <- sim_gap_lag[date_pos]
    y_sim <- alpha_hat + u1[sample(1:n_target, n_target, replace = TRUE)]
    
    valid <- !is.na(x_sim)
    boot_t[b] <- nw_t_stat(y_sim[valid], x_sim[valid])
  }
  
  boot_t
}

# We bootstrap each variable in the way assigned to it above. The
# regression data are built at each variable's own frequency with
# the frequency-matched target, so the statistic tested here is the
# same Newey-West t the in-sample table reports, and the
# bootstrapped p-values apply to exactly the statistic shown in the
# table
run_is_bootstrap <- function(data, predictor, dgp_type = "ar1",
                             frequency = "monthly",
                             n_boot = 10000, seed = 42) {
  
  reg_data <- build_regression_data(data, predictor, frequency,
                                    quarterly_target = quarterly_target,
                                    annual_target = annual_target)
  
  x_t          <- reg_data$predictor_lag
  y_t1         <- reg_data$target
  target_dates <- reg_data$date
  
  real_t <- nw_t_stat(y_t1, x_t)
  
  boot_t <- switch(dgp_type,
                   ar1 = run_ar1_bootstrap(x_t, y_t1, n_boot, seed),
                   iid = run_iid_bootstrap(x_t, y_t1, n_boot, seed),
                   macro_filter = run_macro_filter_bootstrap(target_dates, y_t1, n_boot, seed)
  )
  
  # We use a two-sided p-value, because the homologous table tests
  # whether a coefficient differs from zero in either direction
  p_value <- mean(abs(boot_t) >= abs(real_t))
  sig <- case_when(
    p_value <= 0.01 ~ "***",
    p_value <= 0.05 ~ "**",
    p_value <= 0.10 ~ "*",
    TRUE ~ ""
  )
  
  tibble(variable = predictor, dgp_type = dgp_type, frequency = frequency,
         real_t = real_t, boot_p_value = p_value, boot_sig = sig)
}

is_bootstrap_results <- pmap_dfr(
  bootstrap_settings %>% select(variable, frequency, dgp_type),
  function(variable, frequency, dgp_type) {
    run_is_bootstrap(full_panel, variable, dgp_type = dgp_type,
                     frequency = frequency, n_boot = 10000)
  }
)

write_csv(is_bootstrap_results, "Output/is_bootstrap_results.csv")



# Out of Sample Bootstrap

# We define the three simulators that the out-of-sample and joint
# sections share, each returning a full simulated regression dataset
# under the null of no predictability. The AR(1) simulator below
# draws both residual series with one shared index, keeping the
# return and predictor shocks paired by date, exactly as in the
# in-sample bootstrap above
simulate_ar1 <- function(reg_data, rho_star, mu_star, mean_x, alpha_hat, u1, u2) {
  m <- nrow(reg_data)
  draw_idx <- sample(1:length(u2), m, replace = TRUE)
  
  x_sim <- numeric(m)
  x_sim[1] <- mean_x
  for (s in 2:m) {
    x_sim[s] <- mu_star + rho_star * x_sim[s - 1] + u2[draw_idx[s - 1]]
  }
  y_sim <- alpha_hat + u1[draw_idx]
  
  tibble(date = reg_data$date, target = y_sim, predictor_lag = x_sim)
}

# The iid simulator draws x and y independently.
simulate_iid <- function(reg_data, alpha_hat, u1) {
  m <- nrow(reg_data)
  y_sim <- alpha_hat + u1[sample(1:m, m, replace = TRUE)]
  x_sim <- reg_data$predictor_lag[sample(1:m, m, replace = TRUE)]
  
  tibble(date = reg_data$date, target = y_sim, predictor_lag = x_sim)
}

# The macro-filter simulator rebuilds a simulated production series
# and returns both versions of the simulated gap, built from that
# one series and one simulated return series, so the two simulated
# statistics stay as dependent as the two real ones. The full-sample
# filter feeds the simulated in-sample t-statistic, matching how the
# real in-sample ogap is built. The real-time filter feeds the
# simulated out-of-sample statistics, because the appendix requires
# the bootstrapped OOS variable to use only prevailing data. Both
# simulated predictors stay in their own time order; only y is
# resampled
simulate_macro_filter <- function(reg_data, alpha_hat, u1) {
  n_raw <- length(log_level_indpro)
  m <- nrow(reg_data)
  
  growth_draw <- sample(growth_indpro, n_raw - 1, replace = TRUE)
  sim_level <- log_level_indpro[1] + c(0, cumsum(growth_draw))
  
  t_index <- 1:n_raw
  full_gap <- .lm.fit(cbind(1, t_index, t_index^2), sim_level)$residuals
  rt_gap <- realtime_quadratic_gap(sim_level)
  
  full_gap_lag <- dplyr::lag(full_gap, 1)
  rt_gap_lag <- dplyr::lag(rt_gap, 1)
  date_pos <- match(reg_data$date, indpro_sorted$date)
  
  y_sim <- alpha_hat + u1[sample(1:m, m, replace = TRUE)]
  
  list(
    is_data = tibble(date = reg_data$date, target = y_sim,
                     predictor_lag = full_gap_lag[date_pos]) %>% drop_na(),
    oos_data = tibble(date = reg_data$date, target = y_sim,
                      predictor_lag = rt_gap_lag[date_pos]) %>% drop_na()
  )
}

# We bootstrap the out-of-sample MSE-F statistic for one variable.
# Each replication builds a simulated dataset under the null, runs
# the identical expanding-window forecast loop on it, and records
# the simulated MSE-F. The p-value is the share of simulated MSE-F
# values at least as large as the real one, a one-sided test because
# only better-than-benchmark forecasting counts as evidence
run_oos_bootstrap <- function(data, predictor, dgp_type = "ar1",
                              frequency = "monthly",
                              initial_window_years = 20, n_boot = 1000, seed = 42) {
  
  set.seed(seed)
  
  reg_data <- build_regression_data(data, predictor, frequency,
                                    quarterly_target = quarterly_target,
                                    annual_target = annual_target)
  
  cutoff <- reg_data$date[1] %m+% years(initial_window_years)
  start_index <- sum(reg_data$date <= cutoff) + 1
  
  real_result <- run_oos_once(reg_data, start_index)
  
  x_full <- reg_data$predictor_lag
  y_full <- reg_data$target
  m <- length(x_full)
  alpha_hat <- mean(y_full)
  u1 <- y_full - alpha_hat
  
  if (dgp_type == "ar1") {
    ar1_model <- lm(x_full[2:m] ~ x_full[1:(m - 1)])
    rho_hat <- coef(ar1_model)[2]
    rho_star <- rho_hat + (1 + 3 * rho_hat) / m
    mu_star <- mean(x_full) * (1 - rho_star)
    u2 <- x_full[2:m] - mu_star - rho_star * x_full[1:(m - 1)]
  }
  
  boot_mse_f <- numeric(n_boot)
  
  for (b in 1:n_boot) {
    if (dgp_type == "macro_filter") {
      sim_data <- simulate_macro_filter(reg_data, alpha_hat, u1)$oos_data
    } else {
      sim_data <- switch(dgp_type,
                         ar1 = simulate_ar1(reg_data, rho_star, mu_star, mean(x_full), alpha_hat, u1, u2),
                         iid = simulate_iid(reg_data, alpha_hat, u1)
      )
    }
    
    boot_mse_f[b] <- run_oos_once(sim_data, start_index)$mse_f
  }
  
  tibble(
    variable = predictor,
    dgp_type = dgp_type,
    real_oos_r2 = real_result$oos_r2,
    real_mse_f = real_result$mse_f,
    boot_p_value = mean(boot_mse_f >= real_result$mse_f),
    n_boot = n_boot
  )
}

# We run the test for every variable. ogap alone uses the real-time panel
oos_bootstrap_results <- pmap_dfr(
  bootstrap_settings,
  function(variable, frequency, initial_window_years, dgp_type) {
    input_panel <- if (variable == "ogap") panel_ogap_realtime else full_panel
    run_oos_bootstrap(input_panel, variable, dgp_type = dgp_type,
                      frequency = frequency,
                      initial_window_years = initial_window_years,
                      n_boot = 1000)
  }
)

write_csv(oos_bootstrap_results, "Output/oos_bootstrap_results.csv")



# Joint Significance
# We bootstrap the conjoint significance of the in-sample and
# out-of-sample evidence. Each replication builds one simulated
# dataset and computes both the Newey-West t and the MSE-F from that
# same dataset, so the joint p-value respects the dependence between
# the two statistics instead of treating them as independent draws.
# data carries the in-sample version of each variable and data_oos
# the out-of-sample version; the two differ only for ogap
run_joint_bootstrap <- function(data, predictor, dgp_type = "ar1",
                                frequency = "monthly",
                                initial_window_years = 20, n_boot = 1000,
                                seed = 42, data_oos = data) {
  
  set.seed(seed)
  
  reg_data <- build_regression_data(data, predictor, frequency,
                                    quarterly_target = quarterly_target,
                                    annual_target = annual_target)
  
  if (identical(data_oos, data)) {
    reg_data_oos <- reg_data
  } else {
    reg_data_oos <- build_regression_data(data_oos, predictor, frequency,
                                          quarterly_target = quarterly_target,
                                          annual_target = annual_target)
  }
  
  cutoff <- reg_data_oos$date[1] %m+% years(initial_window_years)
  start_index <- sum(reg_data_oos$date <= cutoff) + 1
  
  real_is_t <- nw_t_stat(reg_data$target, reg_data$predictor_lag)
  real_mse_f <- run_oos_once(reg_data_oos, start_index)$mse_f
  
  x_full <- reg_data$predictor_lag
  y_full <- reg_data$target
  m <- length(x_full)
  alpha_hat <- mean(y_full)
  u1 <- y_full - alpha_hat
  
  if (dgp_type == "ar1") {
    ar1_model <- lm(x_full[2:m] ~ x_full[1:(m - 1)])
    rho_hat <- coef(ar1_model)[2]
    rho_star <- rho_hat + (1 + 3 * rho_hat) / m
    mu_star <- mean(x_full) * (1 - rho_star)
    u2 <- x_full[2:m] - mu_star - rho_star * x_full[1:(m - 1)]
  }
  
  boot_is_t <- numeric(n_boot)
  boot_mse_f <- numeric(n_boot)
  
  for (b in 1:n_boot) {
    if (dgp_type == "macro_filter") {
      sim_pair <- simulate_macro_filter(reg_data_oos, alpha_hat, u1)
      sim_is_data <- sim_pair$is_data
      sim_oos_data <- sim_pair$oos_data
    } else {
      sim_data <- switch(dgp_type,
                         ar1 = simulate_ar1(reg_data, rho_star, mu_star, mean(x_full), alpha_hat, u1, u2),
                         iid = simulate_iid(reg_data, alpha_hat, u1)
      )
      sim_is_data <- sim_data
      sim_oos_data <- sim_data
    }
    
    boot_is_t[b] <- nw_t_stat(sim_is_data$target, sim_is_data$predictor_lag)
    boot_mse_f[b] <- run_oos_once(sim_oos_data, start_index)$mse_f
  }
  
  # The joint p-value is the share of null draws in which pure
  # chance produces results as strong as our real ones on both
  # statistics at once.
  joint_p <- mean(abs(boot_is_t) >= abs(real_is_t) & boot_mse_f >= real_mse_f)
  
  tibble(
    variable = predictor,
    dgp_type = dgp_type,
    real_is_t = real_is_t,
    real_mse_f = real_mse_f,
    joint_p_value = joint_p,
    joint_checkmark = joint_p < 0.05,
    n_boot = n_boot
  )
}

joint_results <- pmap_dfr(
  bootstrap_settings,
  function(variable, frequency, initial_window_years, dgp_type) {
    oos_input <- if (variable == "ogap") panel_ogap_realtime else full_panel
    run_joint_bootstrap(full_panel, variable, dgp_type = dgp_type,
                        frequency = frequency,
                        initial_window_years = initial_window_years,
                        n_boot = 1000, data_oos = oos_input)
  }
)

write_csv(joint_results, "Output/joint_results.csv")