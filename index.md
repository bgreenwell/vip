# vip ![](reference/figures/logo-vip.png)

Variable importance plots (VIPs) for R: quantify and visualize which
features drive a fitted model’s predictions.

- **One interface, many models** —
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) and
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) work with
  dozens of model classes out of the box (randomForest, ranger, gbm,
  xgboost, lightgbm, glmnet, caret, tidymodels, mlr3, …)
- **Model-specific and model-agnostic methods** — native importance
  measures (`method = "model"`), permutation importance
  (`method = "permute"`), Shapley-based importance (`method = "shap"`),
  and variance-based importance (`method = "firm"`)
- **Works with *any* model** — the model-agnostic methods only require a
  user-supplied prediction wrapper
- **Lightweight plotting** via
  [tinyplot](https://grantmcdermott.com/tinyplot/) (base R graphics)
- **Minimal dependencies** — imports only base R packages plus tinyplot
  (itself dependency-free)

## Installation

**vip** is no longer available on CRAN due to CRAN’s stringent and
ever-changing policies. It is now hosted on
[r-universe](https://bgreenwell.r-universe.dev/vip), which provides a
reliable alternative for distributing R packages.

``` r

# Latest stable release (recommended)
install.packages("vip", repos = c("https://bgreenwell.r-universe.dev", "https://cloud.r-project.org"))

# Or with pak
pak::pak("bgreenwell/vip@main")  # latest stable release
pak::pak("bgreenwell/vip")       # development version (devel branch)
```

## Migrating from vip 0.4.x

CRAN will archive the last CRAN release of **vip** (0.4.6) on
**2026-07-13**; all future releases live on r-universe (see above). vip
0.5.0 is also a breaking release — the main changes if you’re coming
from 0.4.x:

- **Plots are base R graphics now, not ggplot2.**
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) (and the
  new [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method
  for `"vi"` objects) draws via
  [tinyplot](https://grantmcdermott.com/tinyplot/) and invisibly returns
  the `"vi"` object, so `vip(fit) + theme_bw()` no longer works. Style
  plots with graphical parameters instead —
  `plot(vi(fit), type = "point", col = "red")` — or build your own
  ggplot from the tidy data frame that
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) returns.
- **[`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) returns a
  plain data frame** (class `"vi"`), not a tibble; call
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  on the result if you need one.
- `aesthetics` is deprecated in favor of `plot_args` in
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md); the
  ggplot2-era `mapping` argument is ignored with a warning;
  `geom = "col"` still works as an alias for `geom = "bar"`.
- **For package maintainers depending on vip**: keep vip in `Suggests`,
  use it conditionally
  ([`requireNamespace("vip", quietly = TRUE)`](https://rdrr.io/r/base/ns-load.html)),
  and declare
  `Additional_repositories: https://bgreenwell.r-universe.dev` in your
  DESCRIPTION — CRAN accepts this for Suggests-level dependencies.

See [NEWS.md](https://github.com/bgreenwell/vip/blob/main/NEWS.md) for
the complete list.

## Quick start

``` r

library(vip)

# Simulate Friedman 1 benchmark data; only x1-x5 are important!
trn <- gen_friedman(500, seed = 101)  # ?vip::gen_friedman

# Model-specific importance from a random forest
library(ranger)
set.seed(101)
rfo <- ranger(y ~ ., data = trn, importance = "impurity")
vi(rfo)    # data frame of variable importance scores
vip(rfo)   # variable importance plot

# Permutation importance works for ANY model; just supply a prediction wrapper
pfun <- function(object, newdata) predict(object, data = newdata)$predictions
set.seed(102)
vis <- vi(rfo, method = "permute", train = trn, target = "y", metric = "rmse",
          pred_wrapper = pfun, nsim = 10)

# "vi" objects have a plot() method; additional arguments are passed on to
# tinyplot::tinyplot()
plot(vis, type = "boxplot", all_permutations = TRUE, jitter = TRUE,
     fill = "grey90")
```

[`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) returns a
tidy data frame of importance scores, so results are easy to
post-process or plot with any graphics package.

## Documentation

- [Package website](https://bgreenwell.github.io/vip/) — function
  reference and the [introductory
  vignette](https://bgreenwell.github.io/vip/articles/vip.html)
- Greenwell, B. M., and Boehmke, B. C. (2020). “Variable Importance
  Plots—An Introduction to the vip Package.” *The R Journal*, 12(1),
  343–366.
  [doi:10.32614/RJ-2020-013](https://doi.org/10.32614/RJ-2020-013)
  (`citation("vip")`)
- For visualizing feature *effects* (which pair naturally with variable
  importance), see [pdp](https://bgreenwell.github.io/pdp/)

## Development

Development happens on the
[`devel`](https://github.com/bgreenwell/vip/tree/devel) branch (the
repository default); `main` holds stable releases, which is what
r-universe builds and the website documents. Please open pull requests
against `devel` and report bugs via the [issue
tracker](https://github.com/bgreenwell/vip/issues).
