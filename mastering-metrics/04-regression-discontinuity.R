# Chapter 4: Cash assistance eligibility and support for the government.
# Run from the mastering-metrics directory.
source("methods.R")

households <- example_data("gov_transfers", "causaldata")
households$score <- 1000 * households$Income_Centered
households$eligible <- as.integer(households$score < 0)
households$support <- households$Support
print(table(Eligibility = households$eligible, Participation = households$Participation))

# The primary window is +/- 0.010 in the source units.
# Use separate local linear slopes on either side of the threshold.
windows <- c(5, 10, 15, 20)
fits <- lapply(windows, function(h) {
  lm(support ~ eligible * score, data = subset(households, abs(score) <= h))
})
results <- do.call(rbind, lapply(fits, lm_interval, term = "eligible"))
results$half_window <- windows / 1000
results$n <- vapply(fits, nobs, numeric(1))
write.csv(results, "04-results.csv", row.names = FALSE)

primary <- subset(households, abs(score) <= 10)
primary$bin <- floor(primary$score)
binned <- aggregate(cbind(score, support) ~ bin + eligible, primary, mean)
below <- seq(-10, 0, length.out = 60)
above <- seq(0, 10, length.out = 60)
fit_below <- predict(fits[[2]], data.frame(score = below, eligible = 1))
fit_above <- predict(fits[[2]], data.frame(score = above, eligible = 0))

open_figure("04-cash-assistance.png")
panel(c(-10.5, 10.5), extendrange(c(binned$support, fit_below, fit_above), f = 0.10),
      "Centered eligibility score (× 1,000)", "Government support (0–1 index)",
      "A. Support at the cutoff")
abline(v = 0, lty = 2, col = muted)
lines(below, fit_below, col = teal, lwd = 3)
lines(above, fit_above, col = rust, lwd = 3)
points(binned$score, binned$support, pch = 19, cex = 0.92,
       col = ifelse(binned$eligible == 1, teal, rust))
legend("topright", c("Eligible", "Ineligible"), col = c(teal, rust),
       pch = 19, bty = "n", cex = 0.88)
interval_panel(results, c("±0.005", "±0.010", "±0.015", "±0.020"),
               "Eligibility jump (index units)", "B. Changing the score window",
               c(muted, teal, muted, muted))
close_figure("Cash assistance and support for the government",
             "04  Regression discontinuity  |  Uruguay's PANES program",
             "Source: causaldata::gov_transfers. Dots are bin means, lines fit household records. HC1 95% intervals.")
print(results, row.names = FALSE)
print(predict(fits[[2]], data.frame(score = c(0, 0), eligible = c(0, 1))))

