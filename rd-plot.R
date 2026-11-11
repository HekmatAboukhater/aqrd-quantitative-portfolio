# PS-08: Problem 1 ---------------------------------------------------------
library(tidyverse)
library(haven)
library(patchwork)

# Load data; per Canvas instructions, place in data/ -----------------------
dat <- read_dta("data/mexico_localities.dta") |>
  mutate(
    above = as.integer(points >= 0),
    mng_index = mng_index_raw - mean(mng_index_raw),
    .by = state_id
  )

# 1.1: Two linear RD plots -------------------------------------------------
p_poverty <- ggplot(dat, aes(x = points, y = ln_im_loc2010_e_jawm)) +
  geom_point(alpha = 0.25, size = 1) +
  geom_smooth(aes(group = factor(above)), method = "lm",
              formula = y ~ x, se = FALSE, color = "#176D78") +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "Poverty index in 2010",
       x = "Score relative to eligibility cutoff",
       y = "Log poverty index") +
  theme_minimal(base_size = 12)

p_management <- ggplot(dat, aes(x = points, y = mng_index)) +
  geom_point(alpha = 0.25, size = 1) +
  geom_smooth(aes(group = factor(above)), method = "lm",
              formula = y ~ x, se = FALSE, color = "#176D78") +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "Land management index",
       x = "Score relative to eligibility cutoff",
       y = "Management index (state-demeaned)") +
  theme_minimal(base_size = 12)

p_1_1 <- p_poverty + p_management
print(p_1_1)
ggsave("PS08_1_1.png", p_1_1, width = 12, height = 5, dpi = 300)

# 1.2: Binned scatter and quadratic fits ---------------------------------
binned <- dat |>
  group_by(bin) |>
  summarize(mean_management = mean(mng_index), .groups = "drop")

p_1_2 <- ggplot(dat, aes(x = points, y = mng_index)) +
  geom_smooth(aes(group = factor(above)), method = "lm",
              formula = y ~ x + I(x^2), se = FALSE, color = "#176D78") +
  geom_point(data = binned, aes(x = bin, y = mean_management),
             inherit.aes = FALSE, color = "#B96B2A", size = 2) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(title = "PES eligibility and land management",
       subtitle = "Bin averages and separate quadratic fits",
       x = "Score relative to eligibility cutoff",
       y = "Management index (state-demeaned)") +
  theme_minimal(base_size = 12)

print(p_1_2)
ggsave("PS08_1_2.png", p_1_2, width = 8, height = 5, dpi = 300)
