# SHAP-based variable importance

Compute SHAP-based VI scores for the predictors in a model. See details
below.

## Usage

``` r
vi_shap(object, ...)

# Default S3 method
vi_shap(object, feature_names = NULL, train = NULL, ...)
```

## Arguments

- object:

  A fitted model object (e.g., a
  [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  object).

- ...:

  Additional arguments to be passed on to
  [`fastshap::explain()`](https://bgreenwell.github.io/fastshap/reference/explain.html)
  (e.g., `nsim = 30`, `adjust = TRUE`, or a prediction wrapper via the
  `pred_wrapper` argument); see
  [`?fastshap::explain`](https://bgreenwell.github.io/fastshap/reference/explain.html)
  for details on these and other useful arguments.

- feature_names:

  Character string giving the names of the predictor variables (i.e.,
  features) of interest. If `NULL` (the default) then they will be
  inferred from the `train` and `target` arguments (see below). It is
  good practice to always specify this argument.

- train:

  A matrix-like R object (e.g., a data frame or matrix) containing the
  training data. If `NULL` (the default) then the internal
  `get_training_data()` function will be called to try and extract it
  automatically. It is good practice to always specify this argument.

## Value

A tidy data frame (specifically, a data frame inheriting from class
`"vi"`; use
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
if you prefer a tibble) with two columns:

- `Variable` - the corresponding feature name;

- `Importance` - the associated importance, computed as the mean
  absolute Shapley value.

## Details

This approach to computing VI scores is based on the mean absolute value
of the SHAP values for each feature; see, for example,
<https://github.com/shap/shap> and the references therein.

Strumbelj, E., and Kononenko, I. Explaining prediction models and
individual predictions with feature contributions. Knowledge and
information systems 41.3 (2014): 647-665.

## Examples

``` r
if (FALSE) { # \dontrun{
library(xgboost)

# Simulate training data
trn <- gen_friedman(500, sigma = 1, seed = 101)  # ?vip::gen_friedman

# Feature matrix
X <- data.matrix(subset(trn, select = -y))  # matrix of feature values

# Fit an XGBoost model; hyperparameters were tuned using 5-fold CV
set.seed(859)  # for reproducibility
bst <- xgboost(X, label = trn$y, nrounds = 338, max_depth = 3, eta = 0.1,
               verbose = 0)

# Construct VIP using "exact" SHAP values from XGBoost's internal Tree SHAP
# functionality
vip(bst, method = "shap", train = X, exact = TRUE, include_type = TRUE,
    geom = "point", horizontal = FALSE,
    plot_args = list(col = "forestgreen", pch = 17, cex = 2))

# Use Monte-Carlo approach, which works for any model; requires prediction
# wrapper
pfun_prob <- function(object, newdata) {  # prediction wrapper
  # For Shapley explanations, this should ALWAYS return a numeric vector
  predict(object, newdata = newdata, type = "prob")[, "yes"]
}

# Compute Shapley-based VI scores
set.seed(853)  # for reproducibility
vi_shap(rfo, train = subset(t1, select = -survived), pred_wrapper = pfun_prob,
        nsim = 30)
## Variable Importance
##   <chr>         <dbl>
## 1 pclass       0.104
## 2 age          0.0649
## 3 sex          0.272
## 4 sibsp        0.0260
## 5 parch        0.0291
} # }
```
