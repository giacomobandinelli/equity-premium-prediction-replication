# We format the result files from scripts 03 and 04 into Word documents.

source("Scripts/01_Setup.R")

library(flextable)   # We use this to write plain tables into Word files
library(officer)     # We use this for the landscape page setting

dir.create("Output", showWarnings = FALSE)

# We load the result files. The homologous and out-of-sample files now
# have a sample column, so we split each into its main and extended
# halves. The bootstrap files are computed on the main sample only
homologous_all <- read_csv("Output/homologous_results.csv")
oos_all <- read_csv("Output/oos_results.csv")
is_boot <- read_csv("Output/is_bootstrap_results.csv")
oos_boot <- read_csv("Output/oos_bootstrap_results.csv")
joint <- read_csv("Output/joint_results.csv")

homologous_main <- homologous_all %>% filter(sample == "main")
homologous_ext <- homologous_all %>% filter(sample == "extended")
oos_main <- oos_all %>% filter(sample == "main")
oos_ext <- oos_all %>% filter(sample == "extended")

# We fix the row order once. Panel A follows GWZ's Table 3, with the
# built monthly variables first, then the Goyal file variables, then
# the quarterly and annual variables. Panel B mirrors the same scheme
# for our own variables: valuation ratios, payout and issuance, size
# and risk, then momentum and fundamentals
panel_a_order <- c(
  "ogap", "wtexas", "ndrbl", "ygap",
  "dp", "dy", "ep", "de", "svar", "bm_agg", "ntis",
  "tbl", "lty", "ltr", "tms", "dfy", "infl",
  "crdstd", "gpce", "gip"
)

panel_b_order <- c(
  "ocm", "sm", "ebm", "dm",
  "npy", "csi", "nef", "nxf", "cdi",
  "me", "beta", "ivol", "iskew", "dfnl",
  "mom", "rev", "gpa", "ag", "roe", "sue"
)

# We define significance stars at the paper's thresholds, two-decimal formatting, and a frequency marker
make_stars <- function(p) {
  case_when(
    p <= 0.01 ~ "***",
    p <= 0.05 ~ "**",
    p <= 0.10 ~ "*",
    TRUE ~ ""
  )
}

fmt <- function(x) sprintf("%.2f", x)

freq_marker <- function(frequency) {
  case_when(
    frequency == "quarterly" ~ "q",
    frequency == "annual" ~ "a",
    TRUE ~ "m"
  )
}

# We insert a label row before each panel
panel_label_row <- function(template, label) {
  template %>%
    slice(0) %>%
    add_row() %>%
    mutate(across(everything(), ~ "")) %>%
    mutate(across(1, ~ label))
}

order_panels <- function(df) {
  bind_rows(
    panel_label_row(df, "Panel A: Replicated variables"),
    df %>% filter(variable %in% panel_a_order) %>%
      arrange(match(variable, panel_a_order)),
    panel_label_row(df, "Panel B: New variables"),
    df %>% filter(variable %in% panel_b_order) %>%
      arrange(match(variable, panel_b_order))
  )
}



# Table 1: replication results, main sample
# We create the full GWZ-style row per variable.
# Both R-squared columns are in percent
table_1 <- homologous_main %>%
  left_join(is_boot %>% select(variable, is_sig = boot_sig), by = "variable") %>%
  left_join(oos_main %>% select(variable, oos_r2), by = "variable") %>%
  left_join(oos_boot %>% mutate(oos_sig = make_stars(boot_p_value)) %>%
              select(variable, oos_sig), by = "variable") %>%
  left_join(joint %>% select(variable, joint_checkmark), by = "variable") %>%
  transmute(
    variable = variable,
    freq = freq_marker(frequency),
    n = as.character(n_obs),
    coef = paste0(fmt(coefficient), coalesce(is_sig, "")),
    nw_t = fmt(nw_t),
    r2_pct = fmt(r_squared * 100),
    oos_r2_pct = paste0(fmt(oos_r2 * 100), oos_sig),
    joint = if_else(joint_checkmark, "\u2713", "")
  ) %>%
  order_panels()

table_1_ft <- table_1 %>%
  rename(" " = variable, "Freq" = freq, "n" = n, "Coef" = coef,
         "NW t" = nw_t, "R2 (%)" = r2_pct, "OOS R2 (%)" = oos_r2_pct,
         "Joint" = joint) %>%
  flextable() %>%
  set_caption("Table 1: In-sample and out-of-sample replication results")

save_as_docx(table_1_ft, path = "Output/Table_01_Replication.docx")



# Table 2: sample robustness, main against extended sample
# We place the two samples side by side. The extended sample results
# have no stars, because the bootstraps run on the main sample only
main_block <- homologous_main %>%
  left_join(is_boot %>% select(variable, is_sig = boot_sig), by = "variable") %>%
  left_join(oos_main %>% select(variable, oos_r2), by = "variable") %>%
  left_join(oos_boot %>% mutate(oos_sig = make_stars(boot_p_value)) %>%
              select(variable, oos_sig), by = "variable") %>%
  transmute(
    variable = variable,
    coef_main = paste0(fmt(coefficient), coalesce(is_sig, "")),
    t_main = fmt(nw_t),
    oos_main_pct = paste0(fmt(oos_r2 * 100), oos_sig)
  )

ext_block <- homologous_ext %>%
  left_join(oos_ext %>% select(variable, oos_r2), by = "variable") %>%
  transmute(
    variable = variable,
    coef_ext = fmt(coefficient),
    t_ext = fmt(nw_t),
    oos_ext_pct = fmt(oos_r2 * 100)
  )

table_2 <- main_block %>%
  left_join(ext_block, by = "variable") %>%
  order_panels()

table_2_ft <- table_2 %>%
  rename(" " = variable,
         "Coef (main)" = coef_main, "NW t (main)" = t_main,
         "OOS R2 % (main)" = oos_main_pct,
         "Coef (ext)" = coef_ext, "NW t (ext)" = t_ext,
         "OOS R2 % (ext)" = oos_ext_pct) %>%
  flextable() %>%
  set_caption("Table 2: Main sample against extended sample")

save_as_docx(table_2_ft,
             path = "Output/Table_02_SampleRobustness.docx",
             pr_section = prop_section(page_size = page_size(orient = "landscape")))



# For each of the twenty new variables, we save the first and last
# month with data to a csv file.
full_panel_extended <- read_csv("Data/Processed/full_panel_extended.csv")

variable_starts <- full_panel_extended %>%
  select(date, all_of(panel_b_order)) %>%
  pivot_longer(-date, names_to = "variable", values_to = "value") %>%
  filter(!is.na(value)) %>%
  group_by(variable) %>%
  summarise(first_month = min(date), last_month = max(date)) %>%
  arrange(match(variable, panel_b_order))

write_csv(variable_starts, "Output/variable_starts.csv")