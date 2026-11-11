# Chapter 5: Organ donor registration after a DMV wording change.
# Run from the mastering-metrics directory.
source("methods.R")

donors <- example_data("organ_donations", "causaldata")
donors$treated <- as.integer(donors$State == "California")
donors$post <- as.integer(donors$Quarter_Num >= 4)
donors$rate_pp <- 100 * donors$Rate
stopifnot(all(table(donors$State, donors$Quarter_Num) == 1))

# Work out the four means and both before/after changes.
means <- aggregate(rate_pp ~ treated + post, donors, mean)
ca <- means$rate_pp[means$treated == 1]
control <- means$rate_pp[means$treated == 0]
did <- diff(ca) - diff(control)
fit <- lm(rate_pp ~ factor(State) + factor(Quarter_Num) + treated:post, data = donors)
stopifnot(isTRUE(all.equal(unname(coef(fit)["treated:post"]), did)))

# Check sensitivity to removing each comparison state.
comparison_states <- unique(donors$State[donors$treated == 0])
leave_one_out <- vapply(comparison_states, function(state) {
  reduced <- subset(donors, State != state)
  means <- aggregate(rate_pp ~ treated + post, reduced, mean)
  diff(means$rate_pp[means$treated == 1]) - diff(means$rate_pp[means$treated == 0])
}, numeric(1))
results <- data.frame(
  group = c("California", "Comparison states", "California minus comparison"),
  pre = c(ca[1], control[1], ca[1] - control[1]),
  post = c(ca[2], control[2], ca[2] - control[2]),
  change = c(diff(ca), diff(control), did)
)
write.csv(results, "05-results.csv", row.names = FALSE)
write.csv(data.frame(removed = names(leave_one_out), did_pp = leave_one_out),
          "05-leave-one-out.csv", row.names = FALSE)

california <- subset(donors, treated == 1)
california <- california[order(california$Quarter_Num), ]
comparison <- aggregate(rate_pp ~ Quarter_Num, subset(donors, treated == 0), mean)
quarter <- california$Quarter_Num
counterfactual <- comparison$rate_pp +
  mean((california$rate_pp - comparison$rate_pp)[quarter < 4])
quarter_labels <- c("Q4 '10", "Q1 '11", "Q2 '11", "Q3 '11", "Q4 '11", "Q1 '12")

open_figure("05-donor-registration.png")
panel(c(0.8, 6.2), extendrange(c(california$rate_pp, comparison$rate_pp), f = 0.15),
      "Quarter", "Registration rate (%)", "A. California and comparison states",
      quarter, quarter_labels)
abline(v = 3.5, lty = 2, col = muted)
lines(quarter, california$rate_pp, type = "b", pch = 19, col = teal, lwd = 2.5)
lines(quarter, comparison$rate_pp, type = "b", pch = 17, col = rust, lwd = 2.5)
legend("right", c("California", "Comparison mean"), bty = "n",
       col = c(teal, rust), pch = c(19, 17), lwd = 2, cex = 0.84)
panel(c(0.8, 6.2), extendrange(c(california$rate_pp, counterfactual), f = 0.30),
      "Quarter", "Registration rate (%)", "B. Align the groups in the pre-period",
      quarter, quarter_labels)
abline(v = 3.5, lty = 2, col = muted)
lines(quarter, california$rate_pp, type = "b", pch = 19, col = teal, lwd = 2.5)
lines(quarter, counterfactual, type = "b", pch = 17, col = rust, lwd = 2.5)
legend("bottomleft", c("Observed California", "Implied counterfactual"), bty = "n",
       col = c(teal, rust), pch = c(19, 17), lwd = 2, cex = 0.82)
close_figure("Did changing the DMV question change sign-ups?",
             "05  Differences-in-differences  |  California's 2011 wording change",
             "Source: causaldata::organ_donations. Dashed vertical line marks the first policy quarter.")
print(results, row.names = FALSE)
cat("Leave-one-comparison-state-out range:", range(leave_one_out), "\n")

