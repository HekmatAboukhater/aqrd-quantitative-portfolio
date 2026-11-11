# Shared data, inference and plotting helpers for the five chapter examples.

example_data <- function(name, package) {
  if (!nzchar(system.file(package = package))) {
    stop("Install the ", package, " package to load ", name, ".", call. = FALSE)
  }
  dataset <- new.env(parent = emptyenv())
  utils::data(list = name, package = package, envir = dataset)
  as.data.frame(get(name, envir = dataset, inherits = FALSE))
}

# HC1 sandwich covariance. For 2SLS use projected regressors and
# structural residuals evaluated at the original regressors.
hc1 <- function(design, residuals) {
  n <- nrow(design)
  k <- ncol(design)
  bread <- solve(crossprod(design))
  scores <- design * as.numeric(residuals)
  n / (n - k) * bread %*% crossprod(scores) %*% bread
}

interval <- function(estimate, se, df) {
  radius <- qt(0.975, df) * se
  data.frame(estimate = unname(estimate), se = unname(se),
             low = unname(estimate - radius), high = unname(estimate + radius))
}

lm_interval <- function(fit, term) {
  design <- model.matrix(fit)
  variance <- hc1(design, residuals(fit))
  index <- match(term, colnames(design))
  interval(coef(fit)[term], sqrt(variance[index, index]), df.residual(fit))
}

ink <- "#192F40"
muted <- "#506271"
teal <- "#16768B"
rust <- "#B75833"
paper <- "#FBFAF6"
grid <- "#DBE3E4"

open_figure <- function(file) {
  png(file, width = 1800, height = 990, res = 150, bg = paper,
      type = if (capabilities("cairo")) "cairo" else getOption("bitmapType"))
  par(mfrow = c(1, 2), oma = c(2.8, 1.2, 5.2, 1.2),
      mar = c(4.5, 4.7, 2.6, 1.1), mgp = c(2.8, 0.8, 0),
      family = "sans", fg = ink, col.lab = ink, col.axis = muted, las = 1)
}

panel <- function(xlim, ylim, xlab, ylab, heading, xticks = NULL, xlabels = NULL) {
  plot(NA_real_, NA_real_, type = "n", xlim = xlim, ylim = ylim,
       xlab = xlab, ylab = ylab, axes = FALSE, xaxs = "i", yaxs = "i")
  abline(h = axTicks(2), col = grid, lwd = 1)
  if (is.null(xticks)) {
    axis(1, col = grid, col.ticks = muted)
  } else {
    axis(1, at = xticks, labels = xlabels, col = grid, col.ticks = muted)
  }
  axis(2, col = grid, col.ticks = muted)
  box(bty = "l", col = grid)
  title(main = heading, adj = 0, col.main = ink, cex.main = 1.04)
}

interval_panel <- function(results, labels, xlab, heading, colors) {
  limits <- range(c(0, results$low, results$high))
  padding <- diff(limits) * 0.10
  limits <- limits + c(-padding, padding)
  y <- rev(seq_len(nrow(results)))
  par(mar = c(4.5, 6.2, 2.6, 1.1))
  plot(NA_real_, NA_real_, type = "n", xlim = limits, ylim = c(0.5, max(y) + 0.5),
       xlab = xlab, ylab = "", axes = FALSE, xaxs = "i", yaxs = "i")
  abline(v = axTicks(1), col = grid, lwd = 1)
  abline(v = 0, lty = 2, col = muted)
  axis(1, col = grid, col.ticks = muted)
  axis(2, at = y, labels = labels, tick = FALSE, cex.axis = 0.87)
  segments(results$low, y, results$high, y, col = colors, lwd = 3)
  points(results$estimate, y, pch = 19, cex = 1.35, col = colors)
  box(bty = "l", col = grid)
  title(main = heading, adj = 0, col.main = ink, cex.main = 1.04)
}

close_figure <- function(heading, subtitle, note) {
  mtext(heading, side = 3, outer = TRUE, adj = 0, line = 3.1,
        font = 2, cex = 1.8, col = ink)
  mtext(subtitle, side = 3, outer = TRUE, adj = 0, line = 1.5,
        cex = 1.0, col = muted)
  mtext(note, side = 1, outer = TRUE, adj = 0, line = 1.1,
        cex = 0.8, col = muted)
  invisible(dev.off())
}

