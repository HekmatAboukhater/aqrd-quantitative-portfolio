# Re-estimate the six behavioral effects in Figure 1 of Mousa (2020).
# Run here with Rscript analysis.R, or give a directory with the Zenodo CSVs.
# Source archive: https://doi.org/10.5281/zenodo.3942437

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L) stop("Provide at most one directory of source CSVs.")
download_inputs <- length(arguments) == 0L
input_dir <- if (download_inputs) tempdir() else arguments[1]
zenodo <- "https://zenodo.org/records/3942437/files"
checksums <- c(
  "wave-2.csv" = "fae806bd89779eec6bdb80e9e2915835",
  "waves-1-and-2.csv" = "ab3d1a736866ad02df9d1d11e5cb2c33",
  "mosul-outcome-wave-2.csv" = "74fb8da0cce10456546629ebbda464a5"
)

read_input <- function(filename) {
  path <- file.path(input_dir, filename)
  if (download_inputs) {
    url <- paste0(zenodo, "/", filename, "?download=1")
    download.file(url, path, mode = "wb", quiet = TRUE, method = "libcurl")
  }
  if (!file.exists(path)) stop("Missing archived file: ", path)
  if (unname(tools::md5sum(path)) != checksums[[filename]]) {
    stop("File does not match the Zenodo v1 checksum: ", path)
  }
  read.csv(path, stringsAsFactors = FALSE)
}

wave2 <- read_input("wave-2.csv")
pooled <- read_input("waves-1-and-2.csv")
voucher <- read_input("mosul-outcome-wave-2.csv")

# Retain the archive's binary outcome coding, as the published script does.
# A separate file supplies each of the pooled and restaurant-voucher samples.
baseline <- c("edu", "church", "income", "status1", "marital",
              "isis_abuse", "player_type", "birth.year")
wave2_controls <- c(baseline, "block")
outcomes <- data.frame(
  variable = c("train_t1", "voted_muslim_extra", "own_group_preference",
               "went_mosul", "attend", "donate_t1_new1"),
  label = c("Trained with Muslims six months later",
            "Voted for a Muslim player for an award",
            "Open to playing on a mixed team",
            "Redeemed a restaurant voucher in Mosul",
            "Attended a mixed social event",
            "Chose a charity serving both communities"),
  setting = rep(c("Soccer-related", "Outside soccer"), each = 3),
  file = c("waves-1-and-2.csv", "wave-2.csv", "wave-2.csv",
           "mosul-outcome-wave-2.csv", "waves-1-and-2.csv", "wave-2.csv")
)
sources <- list("wave-2.csv" = wave2, "waves-1-and-2.csv" = pooled,
                "mosul-outcome-wave-2.csv" = voucher)
control_sets <- list(c(baseline, "train_t0"), wave2_controls, wave2_controls,
                     "block", baseline, c(wave2_controls, "donate_t0_new1"))

analysis_sample <- function(data, outcome, controls) {
  columns <- c(outcome, "treated", "team", controls)
  data <- data[complete.cases(data[, columns]), columns]
  stopifnot(all(data[[outcome]] %in% 0:1), all(data$treated %in% 0:1))
  assignments <- tapply(data$treated, data$team, function(x) length(unique(x)))
  stopifnot(all(assignments == 1L))
  if ("block" %in% controls) data$block <- factor(data$block)
  if ("birth.year" %in% controls) data$birth.year <- data$birth.year - 1980
  data
}

# One-way team-clustered sandwich covariance with the CR1 correction.
# Sum the score contributions of all players on each team before squaring.
cluster_vcov <- function(model, team) {
  x <- model.matrix(model)
  n <- nrow(x)
  k <- ncol(x)
  g <- length(unique(team))
  stopifnot(length(team) == n, model$rank == k, g > 1L, n > k)

  team_scores <- rowsum(x * residuals(model), team, reorder = FALSE)
  bread <- chol2inv(chol(crossprod(x)))
  correction <- (g / (g - 1)) * ((n - 1) / (n - k))
  variance <- correction * bread %*% crossprod(team_scores) %*% bread
  dimnames(variance) <- list(colnames(x), colnames(x))
  variance
}

estimate_effect <- function(outcome, controls, data) {
  sample <- analysis_sample(data, outcome, controls)
  model <- lm(reformulate(c("treated", controls), response = outcome), data = sample)
  effect <- coef(model)[["treated"]]
  team_se <- sqrt(cluster_vcov(model, sample$team)["treated", "treated"])
  lower <- effect - qnorm(0.975) * team_se
  upper <- effect + qnorm(0.975) * team_se
  data.frame(
    players = nrow(sample),
    teams = length(unique(sample$team)),
    observed_control_pct = 100 * mean(sample[sample$treated == 0, outcome]),
    observed_treated_pct = 100 * mean(sample[sample$treated == 1, outcome]),
    adjusted_effect_pp = 100 * effect,
    clustered_se_pp = 100 * team_se,
    lower_95_pp = 100 * lower,
    upper_95_pp = 100 * upper
  )
}

estimates <- do.call(rbind, lapply(seq_len(nrow(outcomes)), function(i) {
  spec <- outcomes[i, ]
  cbind(spec, estimate_effect(spec$variable, control_sets[[i]], sources[[spec$file]]))
}))

# Verify the three on-field effects against the paper's rounded Figure 1 values.
stopifnot(identical(as.numeric(round(estimates$adjusted_effect_pp[1:3])), c(49, 26, 13)))
write.csv(estimates, "figure-1-effects.csv", row.names = FALSE)

# Remove one randomized team at a time and refit the training model.
training_sample <- analysis_sample(pooled, "train_t1", control_sets[[1]])
training_formula <- reformulate(c("treated", control_sets[[1]]), response = "train_t1")
teams <- sort(unique(training_sample$team))
loo <- do.call(rbind, lapply(seq_along(teams), function(i) {
  keep <- training_sample$team != teams[i]
  model <- lm(training_formula, data = training_sample[keep, ])
  data.frame(
    omitted_team = i,
    omitted_assignment = if (training_sample$treated[!keep][1] == 1) "Mixed team" else "All-Christian team",
    remaining_players = sum(keep),
    training_effect_pp = 100 * coef(model)[["treated"]]
  )
}))
write.csv(loo, "training-leave-one-team-out.csv", row.names = FALSE)

# Use base R graphics so the figures can be regenerated without extra packages.
paper <- "#FAF8F1"
ink <- "#152621"
muted <- "#465B55"
line <- "#D5DED7"
sport <- "#146855"
outside <- "#554989"

start_plot <- function(filename, height) {
  png(filename, width = 1580, height = height, res = 158, bg = paper, type = "cairo")
  par(mar = rep(0, 4), family = "sans", xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(c(0, 100), c(0, 100))
}

label <- function(x, y, text_value, size = 1, color = ink, bold = FALSE, align = 0) {
  text(x, y, text_value, adj = c(align, 0.5), cex = size, col = color,
       font = if (bold) 2 else 1)
}

# Figure 1, treatment-effect panel
start_plot("figure-1-effects.png", 850)
label(4.2, 93, "The largest effects were on soccer-related behavior", 1.53, bold = TRUE)
label(4.2, 86, "Re-estimating six effects of assignment to a mixed team in northern Iraq", 1.03, muted)

ticks <- seq(-20, 80, by = 20)
effect_x <- function(x) 36 + 54 * (x + 20) / 100
row_y <- c(67, 59, 51, 35, 27, 19)
colors <- rep(c(sport, outside), each = 3)
segments(effect_x(ticks), 15, effect_x(ticks), 73, col = line, lwd = 1.1)
segments(effect_x(0), 15, effect_x(0), 73, col = muted, lty = 2, lwd = 1.4)
label(4.2, 74.4, "Soccer-related", 0.97, sport, bold = TRUE)
label(4.2, 42.4, "Outside soccer", 0.97, outside, bold = TRUE)
label(95.7, 74.4, "Estimate", 0.86, muted, bold = TRUE, align = 1)
for (i in seq_len(nrow(estimates))) {
  row <- estimates[i, ]
  label(4.2, row_y[i], row$label, 0.94)
  segments(effect_x(row$lower_95_pp), row_y[i], effect_x(row$upper_95_pp), row_y[i],
           col = colors[i], lwd = 2.6)
  points(effect_x(row$adjusted_effect_pp), row_y[i], pch = 19, col = colors[i], cex = 1.35)
  label(95.7, row_y[i], sprintf("%+.1f", row$adjusted_effect_pp), 0.97, colors[i],
        bold = TRUE, align = 1)
}
label(effect_x(ticks), 11.7, ticks, 0.86, muted, align = 0.5)
label(63, 7.6, "Effect in percentage points", 0.91, muted, align = 0.5)
label(4.2, 3.1, "Mousa (2020), Figure 1. Lines show pointwise 95% intervals using team-clustered standard errors.", 0.72, muted)
invisible(dev.off())

# Sensitivity plot for the training outcome, using the range of omitted-team estimates.
start_plot("training-sensitivity.png", 555)
label(4.2, 89, "Training gains held up when any one team was left out", 1.5, bold = TRUE)
label(4.2, 78, "Each dot comes from refitting the model after dropping one team", 1.03, muted)
full_effect <- estimates$adjusted_effect_pp[1]
range_ticks <- pretty(c(loo$training_effect_pp, full_effect), n = 5)
sensitivity_x <- function(x) 28 + 66 * (x - min(range_ticks)) / diff(range(range_ticks))
segments(sensitivity_x(range_ticks), 23, sensitivity_x(range_ticks), 64, col = line, lwd = 1.15)
segments(sensitivity_x(full_effect), 23, sensitivity_x(full_effect), 65, col = ink, lty = 2, lwd = 1.5)
label(sensitivity_x(full_effect), 69, sprintf("Full sample  %.1f pp", full_effect),
      0.87, muted, align = 0.5)
for (i in seq_along(c("All-Christian team", "Mixed team"))) {
  assignment <- c("All-Christian team", "Mixed team")[i]
  y <- c(49, 34)[i]
  color <- c(outside, sport)[i]
  values <- loo$training_effect_pp[loo$omitted_assignment == assignment]
  offsets <- rep(c(-2.1, 0, 2.1), length.out = length(values))
  points(sensitivity_x(sort(values)), y + offsets, pch = 19,
         col = adjustcolor(color, alpha.f = 0.65), cex = 1.16)
  row_label <- c("Omitted an all-Christian team", "Omitted a mixed team")[i]
  label(4.2, y, row_label, 0.90, color)
}
label(sensitivity_x(range_ticks), 17.8, range_ticks, 0.85, muted, align = 0.5)
label(61, 11.5, "Effect on training with Muslims, percentage points", 0.90, muted, align = 0.5)
label(4.2, 4.5, "The spread shows sensitivity to dropping teams. Each fit uses the published controls.", 0.73, muted)
invisible(dev.off())

print(estimates[, c("variable", "players", "teams", "adjusted_effect_pp", "lower_95_pp", "upper_95_pp")],
      row.names = FALSE, digits = 4)
cat("\nLeave-one-team-out training range:", format(range(loo$training_effect_pp), digits = 4), "pp\n")
