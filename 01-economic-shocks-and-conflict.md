# 1. Economic shocks and civil conflict

This was the exercise on whether a drop in economic growth raises the chance of civil conflict. One problem with just regressing conflict on growth is the direction can go both ways, fighting itself can bring down growth.

The paper uses changes in rainfall as an instrument for growth. The exercise starts with a simple OLS and IV comparison. Then we use current and lagged rainfall growth as instruments for current and lagged GDP growth, adding country fixed effects and country-specific trends (each observation is a country-year.

The first stage matters because rainfall needs to actually shift growth. for the causal interpretation there is another assumption, rainfall should affect conflict through the growth terms in the model. If it changes migration or local prices in ways that affect conflict even holding growth fixed, that's a problem for the exclusion restriction.

The units also matter here. Growth is stored as a fraction so a one percentage point change is 0.01 in the regression. The outcome is binary, I have to turn the predicted change in probability back into percentage points when explaining the coefficient.

These are my notes on the design, the R file and table still need to go here.

Source — Miguel, Satyanath, and Sergenti (2004), [Economic Shocks and Civil Conflict](https://emiguel.econ.berkeley.edu/research/economic-shocks-and-civil-conflict-an-instrumental-variables-approach/).
