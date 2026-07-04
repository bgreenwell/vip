# vip <img src="man/figures/logo-vip.png" align="right" width="130" height="150" />

<!-- badges: start -->
[![r-universe version](https://bgreenwell.r-universe.dev/badges/vip)](https://bgreenwell.r-universe.dev/vip)
[![R-CMD-check](https://github.com/bgreenwell/vip/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bgreenwell/vip/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/bgreenwell/vip/branch/main/graph/badge.svg)](https://app.codecov.io/gh/bgreenwell/vip?branch=main)
[![Total Downloads](https://cranlogs.r-pkg.org/badges/grand-total/vip)](https://cranlogs.r-pkg.org/badges/grand-total/vip)
<!-- badges: end -->

Variable importance plots (VIPs) for R: quantify and visualize which features
drive a fitted model's predictions.

- **One interface, many models** — `vi()` and `vip()` work with dozens of
  model classes out of the box (randomForest, ranger, gbm, xgboost, lightgbm,
  glmnet, caret, tidymodels, mlr3, …)
- **Model-specific and model-agnostic methods** — native importance measures
  (`method = "model"`), permutation importance (`method = "permute"`),
  Shapley-based importance (`method = "shap"`), and variance-based importance
  (`method = "firm"`)
- **Works with *any* model** — the model-agnostic methods only require a
  user-supplied prediction wrapper
- **Lightweight plotting** via
  [tinyplot](https://grantmcdermott.com/tinyplot/) (base R graphics)
- **Minimal dependencies** — imports only base R packages plus tibble and
  tinyplot

## Installation

**vip** is no longer available on CRAN due to CRAN's stringent and
ever-changing policies. It is now hosted on
[r-universe](https://bgreenwell.r-universe.dev/vip), which provides a reliable
alternative for distributing R packages.

``` r
# Latest stable release (recommended)
install.packages("vip", repos = c("https://bgreenwell.r-universe.dev", "https://cloud.r-project.org"))

# Or with pak
pak::pak("bgreenwell/vip@main")  # latest stable release
pak::pak("bgreenwell/vip")       # development version (devel branch)
```

## Quick start

``` r
library(vip)

# Simulate Friedman 1 benchmark data; only x1-x5 are important!
trn <- gen_friedman(500, seed = 101)  # ?vip::gen_friedman

# Model-specific importance from a random forest
library(ranger)
set.seed(101)
rfo <- ranger(y ~ ., data = trn, importance = "impurity")
vi(rfo)    # tibble of variable importance scores
vip(rfo)   # variable importance plot

# Permutation importance works for ANY model; just supply a prediction wrapper
pfun <- function(object, newdata) predict(object, data = newdata)$predictions
set.seed(102)
vis <- vi(rfo, method = "permute", train = trn, target = "y", metric = "rmse",
          pred_wrapper = pfun, nsim = 10)
vip(vis, geom = "boxplot", all_permutations = TRUE, jitter = TRUE)
```

`vi()` returns a tidy tibble of importance scores, so results are easy to
post-process or plot with any graphics package.

## Documentation

- [Package website](https://bgreenwell.github.io/vip/) — function reference
  and the [introductory vignette](https://bgreenwell.github.io/vip/articles/vip.html)
- Greenwell, B. M., and Boehmke, B. C. (2020). "Variable Importance Plots—An
  Introduction to the vip Package." *The R Journal*, 12(1), 343–366.
  [doi:10.32614/RJ-2020-013](https://doi.org/10.32614/RJ-2020-013)
  (`citation("vip")`)
- For visualizing feature *effects* (which pair naturally with variable
  importance), see [pdp](https://bgreenwell.github.io/pdp/)

## Development

Development happens on the [`devel`](https://github.com/bgreenwell/vip/tree/devel)
branch (the repository default); `main` holds stable releases, which is what
r-universe builds and the website documents. Please open pull requests against
`devel` and report bugs via the
[issue tracker](https://github.com/bgreenwell/vip/issues).
