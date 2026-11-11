# AQRD In-class Exercise 1 — RD modeling choices ----
# Reproduces the three specifications with the uploaded classroom dataset.

library(haven)
library(dplyr)
library(broom)

# Prepare dataset ----
dat <- read_dta("data/mexico_localities.dta") |>
  mutate(above = as.integer(points >= 0))

# Main model: separate linear slopes, all data ----
rd_model <- lm(mng_index_raw ~ above * points, data = dat)
tidy(rd_model)

# 1. Common slope: remove the above-by-points interaction ----
rd_common <- lm(mng_index_raw ~ above + points, data = dat)
tidy(rd_common)

# 2a. Separate slopes, only localities within 10 points ----
rd_h10 <- lm(
  mng_index_raw ~ above * points,
  data = filter(dat, abs(points) <= 10)
)
tidy(rd_h10)

# 2b. Separate quadratic curves, all data ----
rd_quad <- lm(
  mng_index_raw ~ above * (points + I(points^2)),
  data = dat
)
tidy(rd_quad)

# 2. Compare the RD discontinuities and translate to practices ----
results <- bind_rows(
  tidy(rd_model) |> mutate(model = "linear, all data"),
  tidy(rd_h10) |> mutate(model = "linear, |points| <= 10"),
  tidy(rd_quad) |> mutate(model = "quadratic, all data")
) |>
  filter(term == "above") |>
  transmute(
    model,
    estimate,
    std.error,
    practices_out_of_12 = 12 * estimate,
    practices_se = 12 * std.error,
    p.value
  )

print(results)

# Optional: inspect slope coefficients and observation counts ----
coef(rd_model)
coef(rd_common)
coef(rd_h10)
coef(rd_quad)
nobs(rd_model)
nobs(rd_h10)
nobs(rd_quad)
