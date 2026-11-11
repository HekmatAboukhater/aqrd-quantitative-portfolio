# Economic shocks and civil conflict
# AQRD exercise based on Miguel, Satyanath, and Sergenti (2004).
# Run from the repository root with the course data in data/miguel_africa.dta.
# Optional: Rscript economic-shocks-iv.R /path/to/miguel_africa.dta
# Packages: haven and fixest. This portfolio version was prepared with AI help.

library(haven)
library(fixest)

args <- commandArgs(trailingOnly = TRUE)
data_path <- if (length(args) == 0L) "data/miguel_africa.dta" else args[[1L]]
data <- read_dta(data_path)

# Keep the comparison on a common sample.
simple_variables <- c("ccode", "any_prio", "polity2l", "gdp_g_l", "GPCP_g_l")
simple_data <- data[complete.cases(data[simple_variables]), ]

# The full model uses separate country intercepts and linear trends.
panel_variables <- c(
  "ccode", "any_prio", "year", "gdp_g", "gdp_g_l", "GPCP_g", "GPCP_g_l"
)
panel_data <- data[complete.cases(data[panel_variables]), ]
panel_data$country <- factor(panel_data$ccode)
year <- panel_data$year
if (inherits(year, c("Date", "POSIXt"))) {
  year <- as.integer(format(year, "%Y"))
}
year <- as.numeric(year)
panel_data$elapsed_year <- year - min(year)

# Country clusters and the usual finite-sample adjustments.
adjustment <- ssc(K.adj = TRUE, G.adj = TRUE)

ols <- feols(
  any_prio ~ gdp_g_l + polity2l,
  data = simple_data, vcov = ~ccode, ssc = adjustment
)
simple_iv <- feols(
  any_prio ~ polity2l | gdp_g_l ~ GPCP_g_l,
  data = simple_data, vcov = ~ccode, ssc = adjustment
)
panel_iv <- feols(
  any_prio ~ country * elapsed_year | gdp_g + gdp_g_l ~ GPCP_g + GPCP_g_l,
  data = panel_data, vcov = ~ccode, ssc = adjustment
)

# Report the growth estimates with country-clustered standard errors.
format_estimate <- function(model, term) {
  coefficients <- coeftable(model)
  sprintf(
    "%.2f (%.2f)",
    coefficients[term, "Estimate"],
    coefficients[term, "Std. Error"]
  )
}

comparison <- data.frame(
  Term = c(
    "GDP growth, current year",
    "GDP growth, previous year",
    "Polity score control",
    "Country fixed effects and trends",
    "Country-years",
    "Countries"
  ),
  OLS = c(
    "-", format_estimate(ols, "gdp_g_l"), "Yes", "No",
    nobs(ols), length(unique(simple_data$ccode))
  ),
  "Simple 2SLS" = c(
    "-", format_estimate(simple_iv, "fit_gdp_g_l"), "Yes", "No",
    nobs(simple_iv), length(unique(simple_data$ccode))
  ),
  "Panel 2SLS" = c(
    format_estimate(panel_iv, "fit_gdp_g"),
    format_estimate(panel_iv, "fit_gdp_g_l"), "No", "Yes",
    nobs(panel_iv), length(unique(panel_data$ccode))
  ),
  check.names = FALSE
)
print(comparison, row.names = FALSE)
