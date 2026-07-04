# Variable importance

Compute variable importance scores for the predictors in a model.

## Usage

``` r
vi(object, ...)

# Default S3 method
vi(
  object,
  method = c("model", "firm", "permute", "shap"),
  feature_names = NULL,
  abbreviate_feature_names = NULL,
  sort = TRUE,
  decreasing = TRUE,
  scale = FALSE,
  rank = FALSE,
  ...
)
```

## Arguments

- object:

  A fitted model object (e.g., a
  [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  object) or an object that inherits from class `"vi"`.

- ...:

  Additional optional arguments to be passed on to
  [vi_model](https://bgreenwell.github.io/vip/reference/vi_model.md),
  [vi_firm](https://bgreenwell.github.io/vip/reference/vi_firm.md),
  [vi_permute](https://bgreenwell.github.io/vip/reference/vi_permute.md),
  or [vi_shap](https://bgreenwell.github.io/vip/reference/vi_shap.md);
  see their respective help pages for details.

- method:

  Character string specifying the type of variable importance (VI) to
  compute. Current options are:

  - `"model"` (the default), for model-specific VI scores (see
    [vi_model](https://bgreenwell.github.io/vip/reference/vi_model.md)
    for details).

  - `"firm"`, for variance-based VI scores (see
    [vi_firm](https://bgreenwell.github.io/vip/reference/vi_firm.md) for
    details).

  - `"permute"`, for permutation-based VI scores (see
    [vi_permute](https://bgreenwell.github.io/vip/reference/vi_permute.md)
    for details).

  - `"shap"`, for Shapley-based VI scores (see
    [vi_shap](https://bgreenwell.github.io/vip/reference/vi_shap.md) for
    details).

- feature_names:

  Character string giving the names of the predictor variables (i.e.,
  features) of interest.

- abbreviate_feature_names:

  Integer specifying the length at which to abbreviate feature names.
  Default is `NULL` which results in no abbreviation (i.e., the full
  name of each feature will be printed).

- sort:

  Logical indicating whether or not to order the sort the variable
  importance scores. Default is `TRUE`.

- decreasing:

  Logical indicating whether or not the variable importance scores
  should be sorted in descending (`TRUE`) or ascending (`FALSE`) order
  of importance. Default is `TRUE`.

- scale:

  Logical indicating whether or not to scale the variable importance
  scores so that the largest is 100. Default is `FALSE`.

- rank:

  Logical indicating whether or not to rank the variable importance
  scores (i.e., convert to integer ranks). Default is `FALSE`.
  Potentially useful when comparing variable importance scores across
  different models using different methods.

## Value

A tidy data frame (specifically, a data frame inheriting from class
`"vi"`; use
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
if you prefer a tibble) with two columns:

- `Variable` - the corresponding feature name;

- `Importance` - the associated importance, computed by the requested
  `method` (e.g., the average change in performance after permutation
  for `method = "permute"`, or a model-specific measure for
  `method = "model"`); see the help page for the corresponding `vi_*()`
  function for details.

For
[lm](https://rdrr.io/r/stats/lm.html)/[glm](https://rdrr.io/r/stats/glm.html)-like
objects, whenever `method = "model"`, the sign (i.e., POS/NEG) of the
original coefficient is also included in a column called `Sign`.

If `method = "permute"` and `nsim > 1`, then an additional column
(`StDev`) containing the standard deviation of the individual
permutation scores for each feature is also returned; this helps assess
the stability/variation of the individual permutation importance for
each feature.

## Examples

``` r
#
# A projection pursuit regression example
#

# Load the sample data
data(mtcars)

# Fit a projection pursuit regression model
mtcars.ppr <- ppr(mpg ~ ., data = mtcars, nterms = 1)

# Prediction wrapper that tells vi() how to obtain new predictions from your
# fitted model
pfun <- function(object, newdata) predict(object, newdata = newdata)

# Compute permutation-based variable importance scores
set.seed(1434)  # for reproducibility
(vis <- vi(mtcars.ppr, method = "permute", target = "mpg", nsim = 10,
           metric = "rmse", pred_wrapper = pfun, train = mtcars))
#>    Variable    Importance       StDev
#> 1        wt  3.1695514364 0.373882437
#> 2        hp  2.1827729928 0.462192815
#> 3      gear  0.7551181168 0.367247278
#> 4      qsec  0.6742140316 0.239869036
#> 5       cyl  0.4616533211 0.157650064
#> 6        am  0.1728278221 0.144423078
#> 7        vs  0.0998791565 0.060458355
#> 8      drat  0.0264724266 0.056447801
#> 9      carb  0.0089795328 0.008853503
#> 10     disp -0.0008240667 0.007440299

# Plot variable importance scores (`plot()` passes its `...` on to
# `tinyplot::tinyplot()`)
plot(vis, type = "point", include_type = TRUE, all_permutations = TRUE,
     col = "forestgreen", cex = 2)


#
# A binary classification example
#
if (FALSE) { # \dontrun{
library(rpart)  # for classification and regression trees

# Load Wisconsin breast cancer data; see ?mlbench::BreastCancer for details
data(BreastCancer, package = "mlbench")
bc <- subset(BreastCancer, select = -Id)  # for brevity

# Fit a standard classification tree
set.seed(1032)  # for reproducibility
tree <- rpart(Class ~ ., data = bc, cp = 0)

# Prune using 1-SE rule (e.g., use `plotcp(tree)` for guidance)
cp <- tree$cptable
cp <- cp[cp[, "nsplit"] == 2L, "CP"]
tree2 <- prune(tree, cp = cp)  # tree with three splits

# Default tree-based VIP
vip(tree2)

# Computing permutation importance requires a prediction wrapper. For
# classification, the return value depends on the chosen metric; see
# `?vip::vi_permute` for details.
pfun <- function(object, newdata) {
  # Need vector of predicted class probabilities when using  log-loss metric
  predict(object, newdata = newdata, type = "prob")[, "malignant"]
}

# Permutation-based importance (note that only the predictors that show up
# in the final tree have non-zero importance)
set.seed(1046)  # for reproducibility
vi(tree2, method = "permute", nsim = 10, target = "Class", train = bc,
   metric = "logloss", pred_wrapper = pfun, reference_class = "malignant")

# Equivalent (but not sorted)
set.seed(1046)  # for reproducibility
vi_permute(tree2, nsim = 10, target = "Class", metric = "logloss",
           pred_wrapper = pfun, reference_class = "malignant")
} # }
```
