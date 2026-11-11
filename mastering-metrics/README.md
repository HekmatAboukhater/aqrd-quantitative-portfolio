# Mastering ’Metrics in R

Five short studies based on chapters 1–5 of Angrist and Pischke’s *Mastering ’Metrics*. I wanted to try the methods on questions that come up outside a textbook, like what adds to a home’s price and what happens when a household just qualifies for cash assistance.

| Chapter | Question | What the data show |
| --- | --- | --- |
| [1. Randomized trials](01-randomized-trials.md) | Did job training raise later earnings? | The training group earned **$1,794 more** on average in 1978. |
| [2. Regression](02-regression.md) | How much more did homes with central air sell for? | The modeled price gap falls from **43.9% to 17.8%** after adjusting for observed features. |
| [3. Instrumental variables](03-instrumental-variables.md) | How do cigarette sales respond to price? | The tax-instrumented price elasticity is **−1.14**. |
| [4. Regression discontinuity](04-regression-discontinuity.md) | Does qualifying for cash assistance change political support? | The main window gives a **+0.077** jump on a 0–1 support index. Smaller windows give less precise results. |
| [5. Differences-in-differences](05-differences-in-differences.md) | Did California’s DMV wording change donor registration? | The rate fell **2.25 percentage points relative to comparison states**. |

Each post links to the full R script, the numerical output, and a figure generated from the same run. The analyses are study exercises using public data. I used AI assistance for the code, analysis, and write-ups.

## Run the examples

Install the two data packages from R.

```r
install.packages(c("AER", "causaldata"))
```

Run the commands below from this directory, alongside [methods.R](methods.R).

```sh
Rscript 01-randomized-trials.R
Rscript 02-regression.R
Rscript 03-instrumental-variables.R
Rscript 04-regression-discontinuity.R
Rscript 05-differences-in-differences.R
```

Each script regenerates its PNG and CSV outputs. I ran the series in R 4.5.0 with AER 1.2-14 and causaldata 0.1.4. The book reference is Joshua D. Angrist and Jörn-Steffen Pischke, *Mastering ’Metrics: The Path from Cause to Effect* (Princeton University Press, 2015).

