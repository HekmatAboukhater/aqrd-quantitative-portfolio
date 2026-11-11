# Chapter 3: Can sales taxes help isolate a price effect?
# Run from the mastering-metrics directory.
source("methods.R")

cig <- subset(example_data("CigarettesSW", "AER"), year == "1995")
cig$log_packs <- log(cig$packs)
cig$log_price <- log(cig$price / cig$cpi)
cig$log_income <- log(cig$income / cig$population / cig$cpi)
cig$sales_tax <- (cig$taxs - cig$tax) / cig$cpi

first_stage <- lm(log_price ~ sales_tax + log_income, data = cig)
reduced_form <- lm(log_packs ~ sales_tax + log_income, data = cig)
ols <- lm(log_packs ~ log_price + log_income, data = cig)

# Project the structural regressors on the excluded instrument and control.
# Use actual prices, not fitted prices, when calculating structural residuals.
x <- model.matrix(ols)
z <- model.matrix(first_stage)
x_fitted <- qr.fitted(qr(z), x)
iv_coefficients <- qr.coef(qr(x_fitted), cig$log_packs)
iv_residuals <- cig$log_packs - drop(x %*% iv_coefficients)
iv_vcov <- hc1(x_fitted, iv_residuals)
price_index <- match("log_price", colnames(x))
iv <- interval(iv_coefficients[price_index], sqrt(iv_vcov[price_index, price_index]),
               nrow(cig) - ncol(x))

first <- lm_interval(first_stage, "sales_tax")
reduced <- lm_interval(reduced_form, "sales_tax")
wald <- reduced$estimate / first$estimate
stopifnot(isTRUE(all.equal(wald, iv$estimate)))
results <- rbind(lm_interval(ols, "log_price"), iv, first, reduced)
results$model <- c("OLS", "2SLS", "First stage", "Reduced form")
results$n <- nrow(cig)
results$robust_first_stage_F <- c(NA, NA, (first$estimate / first$se)^2, NA)
write.csv(results, "03-results.csv", row.names = FALSE)

# Partial out log income so the first-stage line has the reported slope.
price_net <- residuals(lm(log_price ~ log_income, data = cig))
tax_net <- residuals(lm(sales_tax ~ log_income, data = cig))
open_figure("03-cigarette-prices.png")
panel(extendrange(tax_net, f = 0.08), extendrange(price_net, f = 0.10),
      "Real sales tax per pack, net of income", "Log real price, net of income",
      "A. The first stage")
points(tax_net, price_net, pch = 19, col = teal, cex = 0.95)
abline(lm(price_net ~ tax_net), col = rust, lwd = 2.8)
interval_panel(results[1:2, ], c("OLS", "2SLS"), "Price elasticity of packs sold",
               "B. OLS and IV with 95% intervals", c(rust, teal))
close_figure("What happens to sales when cigarettes cost more?",
             "03  Instrumental variables  |  48 states, 1995",
             "Source: AER::CigarettesSW. Models control for real income per person. Intervals use HC1.")
print(results, row.names = FALSE)
cat("Reduced form / first stage:", wald, "\n")

