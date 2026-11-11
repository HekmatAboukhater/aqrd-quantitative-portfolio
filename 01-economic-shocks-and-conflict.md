# 1. Economic shocks and civil conflict

This was the exercise on whether a drop in economic growth raises the chance of civil conflict. One problem with just regressing conflict on growth is the direction can go both ways, fighting itself can bring down growth.

The paper uses changes in rainfall as an instrument for growth. The exercise starts with a simple OLS and IV comparison. Then we use current and lagged rainfall growth as instruments for current and lagged GDP growth, adding country fixed effects and country-specific trends (each observation is a country-year.

The first stage matters because rainfall needs to actually shift growth. for the causal interpretation there is another assumption, rainfall should affect conflict through the growth terms in the model. If it changes migration or local prices in ways that affect conflict even holding growth fixed, that's a problem for the exclusion restriction.

The units also matter here. Growth is stored as a fraction so a one percentage point change is 0.01 in the regression. The outcome is binary, I have to turn the predicted change in probability back into percentage points when explaining the coefficient.

## What the regressions gave me

| | OLS | Simple 2SLS | Panel 2SLS |
| --- | ---: | ---: | ---: |
| GDP growth, current year | — | — | -1.13 (1.40) |
| GDP growth, previous year | -0.08 (0.26) | -2.47 (1.41) | -2.55 (1.10) |
| Polity score control | Yes | Yes | No |
| Country fixed effects and trends | No | No | Yes |
| Country-years | 743 | 743 | 743 |
| Countries | 41 | 41 | 41 |

The outcome is a civil conflict indicator. Standard errors are clustered by country and shown in parentheses. The first two columns use the same Polity score control, the last column uses country fixed effects and separate trends for each country.

In the last column a 5 percentage point drop in last year's growth goes with about a 13 percentage point increase in the fitted probability of conflict, holding this year's growth fixed. the causal reading still depends on those rainfall assumptions above.

The [R script](economic-shocks-iv.R) uses the course extract at `data/miguel_africa.dta`. Run `Rscript economic-shocks-iv.R` from the repository root with `haven` and `fixest` installed. I used AI help to put the script together. The table was calculated separately from the course data and the panel coefficients match the class replication target to two decimals.

Source — Miguel, Satyanath, and Sergenti (2004), [Economic Shocks and Civil Conflict](https://emiguel.econ.berkeley.edu/research/economic-shocks-and-civil-conflict-an-instrumental-variables-approach/).
