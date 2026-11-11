library(tidyverse)
library(rsample)
library(glmnet)
library(glmnetUtils)
library(glue)
library(gt)

library(nnet)
library(ranger)
library(hdm)

osha <- read_csv("data/osha.csv", show_col_types = FALSE)
#q1.1
#Predict injury rates using the 11 demographic variables
fit_demog_all <- lm(
  injury_rate ~ estab_age_netsmm1 + exp_imp_netsmm1 +
    exporter_netsmm1 + foreign_owned_netsmm1 +
    govt_contractor_netsmm1 + headquarters_netsmm1 +
    importer_netsmm1 + public_netsmm1 + standalone_netsmm1 +
    num_yrs_prev_on_sst + wp_days_2008,
  data = osha
)

# Total sum of squares
TSS <- sum((osha$injury_rate - mean(osha$injury_rate))^2)

#Sum of squared residuals
SSR <- sum(resid(fit_demog_all)^2)

#  R Squared 
R_squared <- 1 - SSR / TSS

c(TSS = TSS, SSR = SSR, R_squared = R_squared)

#1.2

# Simple Model
form_simpl <- injury_rate ~ has_tmin1_odi + any_insp_prior +
  any_complaint_tmin13 + num_nonfat_comp_insp_cy_tc99mm1 +
  initial_pen_cy_mzmm1 + ln_initial_pen_cy_mzmm1

fit_simpl_all <- lm(form_simpl, data = osha)

# Kitchen Sink Model
remove_vars <- c("id", "injuries", "injury_rate", "high_injury_rate")

kitch_vars <- setdiff(colnames(osha), remove_vars)

form_kitch <- as.formula(
  glue("injury_rate ~ {str_c(kitch_vars, collapse = ' + ')}")
)

fit_kitch_all <- lm(form_kitch, data = osha)

# Compare R Squared across the three models
c(
  Demographic = summary(fit_demog_all)$r.squared,
  Simple = summary(fit_simpl_all)$r.squared,
  Kitchen_sink = summary(fit_kitch_all)$r.squared
)

#Q2

# 2.1

set.seed(06510)

# Split the data
osha_split <- initial_split(osha, prop = 0.8)

# Extract the training and test datasets
osha_train <- training(osha_split)
osha_test <- testing(osha_split)

# Check the number of observations
nrow(osha_train)
nrow(osha_test)

#2.2




fit_simpl <- lm(form_simpl, data = osha_train)
fit_kitch <- lm(form_kitch, data = osha_train)

#LASSO 
set.seed(06510)
fit_lasso <- glmnetUtils::cv.glmnet(
  form_kitch, data = osha_train, alpha = 1
)

# Predict
osha_train_fit <- osha_train |>
  mutate(
    set = "Training",
    pred_simpl = predict(fit_simpl, newdata = osha_train),
    pred_kitch = predict(fit_kitch, newdata = osha_train),
    pred_lasso = as.vector(
      predict(fit_lasso, osha_train, s = "lambda.min")
    )
  )

# Predictions 
osha_test_fit <- osha_test |>
  mutate(
    set = "Testing",
    pred_simpl = predict(fit_simpl, newdata = osha_test),
    pred_kitch = predict(fit_kitch, newdata = osha_test),
    pred_lasso = as.vector(
      predict(fit_lasso, osha_test, s = "lambda.min")
    )
  )

#RMSE
rmse_table <- bind_rows(osha_train_fit, osha_test_fit) |>
  pivot_longer(
    cols = c(pred_simpl, pred_kitch, pred_lasso),
    names_to = "model",
    names_prefix = "pred_",
    values_to = "pred"
  ) |>
  group_by(set, model) |>
  summarize(
    RMSE = sqrt(mean((injury_rate - pred)^2)),
    .groups = "drop"
  ) |>
  pivot_wider(names_from = set, values_from = RMSE) |>
  mutate(
    model = factor(
      model,
      levels = c("simpl", "kitch", "lasso"),
      labels = c("Simple", "Kitchen sink", "LASSO")
    )
  ) |>
  arrange(model) |>
  select(model, Training, Testing)

#Results
rmse_table |>
  gt() |>
  fmt_number(columns = c(Training, Testing), decimals = 3) |>
  cols_label(
    model = "Model",
    Training = "Training RMSE",
    Testing = "Testing RMSE"
  )

#2.3

lasso_coefs <- coef(fit_lasso, s = "lambda.min")

# Count 
sum(lasso_coefs[-1, , drop = TRUE] != 0)


#2.5


#1- Null model
fit_null <- lm(injury_rate ~ 1, data = osha_train)

# Create predictor matrices, excluding the intercept
x_train <- model.matrix(form_kitch, data = osha_train)[, -1, drop = FALSE]
x_test <- model.matrix(form_kitch, data = osha_test)[, -1, drop = FALSE]

#2- Ridge regression: alpha = 0
set.seed(06510)
fit_ridge <- glmnet::cv.glmnet(
  x = x_train,
  y = osha_train$injury_rate,
  alpha = 0
)

#3-Regression Tree
fit_forest <- ranger::ranger(
  form_kitch,
  data = osha_train,
  num.trees = 500,
  seed = 06510
)

# 4-Standardize neural-network predictors using training data
train_means <- colMeans(x_train)
train_sds <- apply(x_train, 2, sd)

# Avoid dividing by zero for any constant predictors
train_sds[train_sds == 0] <- 1

x_train_scaled <- scale(
  x_train,
  center = train_means,
  scale = train_sds
)

x_test_scaled <- scale(
  x_test,
  center = train_means,
  scale = train_sds
)

# - Neural network with three hidden units and continuous output
set.seed(06510)
fit_nnet <- nnet::nnet(
  x = x_train_scaled,
  y = osha_train$injury_rate,
  size = 3,
  linout = TRUE,
  rang = 0.01,
  decay = 1e-4,
  maxit = 10000,
  trace = FALSE
)

#Post-LASSO
set.seed(06510)
fit_postlasso <- hdm::rlasso(
  x = x_train,
  y = osha_train$injury_rate,
  post = TRUE
)

# Add training predictions to those from 2.2
train_fit_25 <- osha_train_fit |>
  mutate(
    pred_null = predict(fit_null, newdata = osha_train),
    pred_ridge = as.vector(
      predict(fit_ridge, newx = x_train, s = "lambda.min")
    ),
    pred_postlasso = as.vector(
      predict(fit_postlasso, newdata = x_train)
    ),
    pred_forest = predict(
      fit_forest, data = osha_train
    )$predictions,
    pred_nnet = as.vector(
      predict(fit_nnet, newdata = x_train_scaled)
    )
  )

# Add test predictions to those from 2.2
test_fit_25 <- osha_test_fit |>
  mutate(
    pred_null = predict(fit_null, newdata = osha_test),
    pred_ridge = as.vector(
      predict(fit_ridge, newx = x_test, s = "lambda.min")
    ),
    pred_postlasso = as.vector(
      predict(fit_postlasso, newdata = x_test)
    ),
    pred_forest = predict(
      fit_forest, data = osha_test
    )$predictions,
    pred_nnet = as.vector(
      predict(fit_nnet, newdata = x_test_scaled)
    )
  )

# Calculate RMSE for all 8 Models
rmse_table_25 <- bind_rows(train_fit_25, test_fit_25) |>
  pivot_longer(
    cols = starts_with("pred_"),
    names_to = "model",
    names_prefix = "pred_",
    values_to = "pred"
  ) |>
  group_by(set, model) |>
  summarize(
    RMSE = sqrt(mean((injury_rate - pred)^2)),
    .groups = "drop"
  ) |>
  pivot_wider(names_from = set, values_from = RMSE) |>
  mutate(
    model = factor(
      model,
      levels = c(
        "simpl", "kitch", "lasso", "null",
        "ridge", "postlasso", "forest", "nnet"
      ),
      labels = c(
        "Simple", "Kitchen sink", "LASSO", "Null",
        "Ridge", "Post-LASSO", "Random forest", "Neural network"
      )
    )
  ) |>
  arrange(model) |>
  select(model, Training, Testing)

# Comparison table
rmse_table_25 |>
  gt() |>
  fmt_number(columns = c(Training, Testing), decimals = 3) |>
  cols_label(
    model = "Model",
    Training = "Training RMSE",
    Testing = "Testing RMSE"
  )

# Check convergence 
fit_nnet$convergence

#Q3

form_simpl_logit <- update(form_simpl, high_injury_rate ~ .)
form_kitch_logit <- update(form_kitch, high_injury_rate ~ .)

#Simple logit
fit_simpl_logit <- glm(
  form_simpl_logit,
  data = osha_train,
  family = binomial()
)

#Kitchen sink logit
fit_kitch_logit <- glm(
  form_kitch_logit,
  data = osha_train,
  family = binomial()
)

#LASSO logit
set.seed(06510)
fit_lasso_logit <- glmnetUtils::cv.glmnet(
  form_kitch_logit,
  data = osha_train,
  family = "binomial",
  type.measure = "mse",
  alpha = 1
)

#Predictions
osha_test_logit <- osha_test |>
  mutate(
    pred_simpl = predict(
      fit_simpl_logit, newdata = osha_test, type = "response"
    ),
    pred_kitch = predict(
      fit_kitch_logit, newdata = osha_test, type = "response"
    ),
    pred_lasso = as.vector(
      predict(
        fit_lasso_logit, osha_test,
        s = "lambda.min", type = "response"
      )
    ),
    high_injury = factor(
      high_injury_rate,
      levels = c(0, 1),
      labels = c("Not high injury", "High injury")
    )
  )

#Scatterplot
plot_logit <- ggplot(
  osha_test_logit,
  aes(x = pred_kitch, y = pred_lasso,
      color = high_injury, shape = high_injury)
) +
  geom_abline(intercept = 0, slope = 1,
              linetype = "dashed", color = "gray70") +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c("gray60", "red3")) +
  scale_shape_manual(values = c(16, 17)) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    x = "Kitchen sink logit: predicted probability",
    y = "LASSO logit: predicted probability",
    color = "Actual outcome",
    shape = "Actual outcome"
  ) +
  theme_minimal()

print(plot_logit)
