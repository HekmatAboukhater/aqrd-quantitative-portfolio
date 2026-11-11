# Chapter 1: Does a job training program raise later earnings?
# Run from the mastering-metrics directory.
source("methods.R")

jobs <- example_data("nsw_mixtape", "causaldata")
jobs <- jobs[complete.cases(jobs[c("treat", "age", "educ", "re74", "re75", "re78")]), ]
trained <- jobs[jobs$treat == 1, ]
control <- jobs[jobs$treat == 0, ]

# Difference in sample means and its Welch interval.
comparison <- t.test(trained$re78, control$re78)
raw <- data.frame(estimate = mean(trained$re78) - mean(control$re78),
                  se = unname(comparison$stderr),
                  low = comparison$conf.int[1], high = comparison$conf.int[2])
adjusted <- lm(re78 ~ treat + age + educ + re74 + re75, data = jobs)
results <- rbind(raw, lm_interval(adjusted, "treat"))
results$model <- c("Raw difference", "Baseline adjusted")
results$n <- nrow(jobs)
write.csv(results, "01-results.csv", row.names = FALSE)

# Baseline balance in standard deviation units.
baseline <- c("age", "educ", "re74", "re75")
balance <- data.frame(
  variable = baseline,
  training = vapply(trained[baseline], mean, numeric(1)),
  control = vapply(control[baseline], mean, numeric(1))
)
balance$smd <- (balance$training - balance$control) /
  sqrt((vapply(trained[baseline], var, numeric(1)) +
          vapply(control[baseline], var, numeric(1))) / 2)
write.csv(balance, "01-balance.csv", row.names = FALSE)

years <- c(1974, 1975, 1978)
earnings <- c("re74", "re75", "re78")
training_means <- vapply(trained[earnings], mean, numeric(1))
control_means <- vapply(control[earnings], mean, numeric(1))
open_figure("01-job-training.png")
panel(c(1973.8, 1978.2), c(0, 1.22 * max(training_means, control_means) / 1000),
      "Year", "Mean earnings (thousands of real dollars)", "A. Earnings by assignment",
      years, years)
abline(v = 1976, lty = 2, col = muted)
lines(years, training_means / 1000, type = "b", pch = 19, col = teal, lwd = 2.5)
lines(years, control_means / 1000, type = "b", pch = 17, col = rust, lwd = 2.5)
legend("topleft", c("Training", "Control"), bty = "n",
       col = c(teal, rust), pch = c(19, 17), lwd = 2, cex = 0.88)
interval_panel(results, c("Raw gap", "Adjusted"), "1978 earnings difference (real dollars)",
               "B. Estimated difference with 95% intervals", c(teal, rust))
close_figure("Did job training raise later earnings?",
             "01  Randomized trials  |  National Supported Work Demonstration",
             "Source: causaldata::nsw_mixtape. Dashed line marks the gap between baseline and follow-up.")
print(results, row.names = FALSE)
print(balance, row.names = FALSE)
print(rbind(training = c(nrow(trained), training_means), control = c(nrow(control), control_means)))

