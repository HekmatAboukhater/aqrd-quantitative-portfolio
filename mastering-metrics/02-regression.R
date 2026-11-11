# Chapter 2: Central air and home prices in Windsor.
# Run from the mastering-metrics directory.
source("methods.R")

homes <- example_data("HousePrices", "AER")
features <- c("price", "aircon", "lotsize", "bedrooms", "bathrooms",
              "stories", "garage", "prefer")
homes <- homes[complete.cases(homes[features]), ]
homes$central_air <- as.integer(homes$aircon == "yes")

raw <- lm(log(price) ~ central_air, data = homes)
size_adjusted <- lm(log(price) ~ central_air + log(lotsize), data = homes)
full <- lm(log(price) ~ central_air + log(lotsize) + bedrooms + bathrooms +
             stories + garage + prefer, data = homes)
results <- do.call(rbind, lapply(list(raw, size_adjusted, full), lm_interval, term = "central_air"))
results$model <- c("Unadjusted", "Lot size", "Property features")
results$n <- nrow(homes)
results$pct_difference <- 100 * expm1(results$estimate)
results$pct_low <- 100 * expm1(results$low)
results$pct_high <- 100 * expm1(results$high)
write.csv(results, "02-results.csv", row.names = FALSE)

# The two-variable omitted-variable-bias identity is exact in this sample.
lot_gap <- coef(lm(log(lotsize) ~ central_air, data = homes))["central_air"]
stopifnot(isTRUE(all.equal(
  unname(coef(raw)["central_air"] - coef(size_adjusted)["central_air"]),
  unname(coef(size_adjusted)["log(lotsize)"] * lot_gap)
)))

open_figure("02-home-prices.png")
panel(range(homes$lotsize) / 1000 + c(-0.4, 0.4),
      range(homes$price) / 1000 + c(-7, 7),
      "Lot size (thousands of square feet)", "Sale price (thousands of dollars)",
      "A. Compare homes on overlapping lot sizes")
points(homes$lotsize / 1000, homes$price / 1000, pch = 19, cex = 0.70,
       col = adjustcolor(ifelse(homes$central_air == 1, teal, rust), alpha.f = 0.44))
legend("topleft", c("Central air", "No central air"), bty = "n",
       col = c(teal, rust), pch = 19, cex = 0.88)
plotted <- data.frame(estimate = results$pct_difference,
                      low = results$pct_low, high = results$pct_high)
interval_panel(plotted, c("Raw", "Lot size", "Full controls"),
               "Difference in modeled price (%)", "B. How the comparison changes",
               c(rust, "#657A8D", teal))
close_figure("The home price premium for central air",
             "02  Regression  |  Windsor, Canada, 1987",
             "Source: AER::HousePrices. Same 546 sales in each model. Intervals use HC1 standard errors.")
print(results, row.names = FALSE)
print(aggregate(cbind(lotsize, price) ~ central_air, homes, mean))

