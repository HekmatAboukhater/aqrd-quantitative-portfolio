# 4. Predicting workplace injury risk

The question here is how well workplace characteristics and inspection records predict injuries in the OSHA case. I started with the smaller and larger regressions in R, adding variables can make the fit in the training data look better even when the model predicts worse on new cases.

The [R script](workplace-injury.R) splits the data 80/20 with a fixed seed. For LASSO it chooses the penalty by cross-validation using the training sample, then checks error on the held-out sample. The RMSE is in the same units as the injury rate (injuries with days away from work per 100 full-time equivalent workers. There's also a mean-only baseline, ridge, post-LASSO, a random forest and a small neural net. The last section uses logistic models to predict a high injury rate.

One thing I’d check before using it for future inspections is whether the same workplace appears across years. If it does, a split by workplace or a later test period could be a better test for that use. Estimating the effect of an inspection would be a separate causal question.

To run it, put the course file at `data/osha.csv` and install the packages loaded at the top of the script.

```sh
Rscript workplace-injury.R
```

I still need a fresh run to add the results table here.

Source — [Improving Worker Safety in the Era of Machine Learning (A)](https://store.hbr.org/product/improving-worker-safety-in-the-era-of-machine-learning-a/618019), Harvard Business School Case 618-019.
