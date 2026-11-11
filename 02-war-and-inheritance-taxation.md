# 2. War and inheritance taxes

For this one the question was whether mass mobilization for war changed how governments tax inherited wealth. The first part is a difference-in-differences comparison of the UK and the Netherlands, i take the change in the average top inheritance tax rate for each country and subtract the Netherlands change from the UK change. In the course exercise the earlier period goes through 1914 and the later one starts in 1949.

The panel version lets us work with more countries and periods. We use country and period fixed effects, lagged variables, and in one specification country-specific trends. One practical bit in R is that a lag has to refer to the preceding period for the same country, so the data need to be sorted by time within each country (and checked for gaps.

The historical comparison needs parallel trends in the absence of the difference in mobilization. The leads and lags plot helps look for differences that were already showing up earlier, estimates close to zero can still be pretty imprecise.

This post is the write-up of the exercise, the replication table and plot are still to add.

Source — Scheve and Stasavage (2012), [Democracy, War, and Wealth](https://www.cambridge.org/core/journals/american-political-science-review/article/abs/democracy-war-and-wealth-lessons-from-two-centuries-of-inheritance-taxation/9AE36F339225AA03F2E2A516E16CC2AB).
