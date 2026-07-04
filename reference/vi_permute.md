# Permutation-based variable importance

Compute permutation-based variable importance scores for the predictors
in a model; for details on the algorithm, see Greenwell and Boehmke
(2020).

## Usage

``` r
vi_permute(object, ...)

# Default S3 method
vi_permute(
  object,
  feature_names = NULL,
  train = NULL,
  target = NULL,
  metric = NULL,
  smaller_is_better = NULL,
  type = c("difference", "ratio"),
  nsim = 1,
  keep = TRUE,
  sample_size = NULL,
  sample_frac = NULL,
  reference_class = NULL,
  event_level = NULL,
  pred_wrapper = NULL,
  verbose = FALSE,
  parallel = FALSE,
  parallelize_by = c("features", "repetitions"),
  ...
)
```

## Arguments

- object:

  A fitted model object (e.g., a
  [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  object).

- ...:

  Additional optional arguments to be passed on to
  [foreach](https://rdrr.io/pkg/foreach/man/foreach.html) (e.g.,
  `.packages` or `.export`).

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

- target:

  Either a character string giving the name (or position) of the target
  column in `train` or, if `train` only contains feature columns, a
  vector containing the target values used to train `object`.

- metric:

  Either a function or character string specifying the performance
  metric to use in computing model performance (e.g., RMSE for
  regression or accuracy for binary classification). If `metric` is a
  function, then it requires two arguments, `actual` and `predicted`,
  and should return a single, numeric value. Ideally, this should be the
  same metric that was used to train `object`. See
  [`list_metrics()`](https://bgreenwell.github.io/vip/reference/list_metrics.md)
  for a list of built-in metrics.

- smaller_is_better:

  Logical indicating whether or not a smaller value of `metric` is
  better. Default is `NULL`. Must be supplied if `metric` is a
  user-supplied function.

- type:

  Character string specifying how to compare the baseline and permuted
  performance metrics. Current options are `"difference"` (the default)
  and `"ratio"`.

- nsim:

  Integer specifying the number of Monte Carlo replications to perform.
  Default is 1. If `nsim > 1`, the results from each replication are
  simply averaged together (the standard deviation will also be
  returned).

- keep:

  Logical indicating whether or not to keep the individual permutation
  scores for all `nsim` repetitions. If `TRUE` (the default) then the
  individual variable importance scores will be stored in an attribute
  called `"raw_scores"`. (Only used when `nsim > 1`.)

- sample_size:

  Integer specifying the size of the random sample to use for each Monte
  Carlo repetition. Default is `NULL` (i.e., use all of the available
  training data). Cannot be specified with `sample_frac`. Can be used to
  reduce computation time with large data sets. A single subsample is
  drawn per repetition and the baseline performance is recomputed on
  that subsample, so all features within a repetition are compared on
  the same rows.

- sample_frac:

  Proportion specifying the size of the random sample to use for each
  Monte Carlo repetition. Default is `NULL` (i.e., use all of the
  available training data). Cannot be specified with `sample_size`. Can
  be used to reduce computation time with large data sets. See
  `sample_size` for details on how the subsampling is carried out.

- reference_class:

  Deprecated, use `event_level` instead; a warning is issued (and the
  argument otherwise ignored) if supplied.

- event_level:

  String specifying which factor level of `truth` to consider as the
  "event". Options are `"first"` (the default) or `"second"`. This
  argument is only applicable for binary classification when `metric` is
  one of `"roc_auc"`, `"pr_auc"`, or `"youden"`. This argument is passed
  on to the corresponding
  [yardstick](https://yardstick.tidymodels.org/reference/yardstick-package.html)
  metric.

- pred_wrapper:

  Prediction function that requires two arguments, `object` and
  `newdata`. The output of this function should be determined by the
  `metric` being used:

  - Regression - A numeric vector of predicted outcomes.

  - Binary classification - A vector of predicted class labels (e.g., if
    using misclassification error) or a vector of predicted class
    probabilities for the reference class (e.g., if using log loss or
    AUC).

  - Multiclass classification - A vector of predicted class labels
    (e.g., if using misclassification error) or a A matrix/data frame of
    predicted class probabilities for each class (e.g., if using log
    loss or AUC).

- verbose:

  Logical indicating whether or not to print information during the
  construction of variable importance scores. Default is `FALSE`.

- parallel:

  Logical indicating whether or not to run `vi_permute()` in parallel
  (using a backend provided by the
  [foreach](https://rdrr.io/pkg/foreach/man/foreach.html) package).
  Default is `FALSE`. If `TRUE`, the **foreach** package must be
  installed and a
  [foreach](https://rdrr.io/pkg/foreach/man/foreach.html)-compatible
  backend must be registered. Note that
  [`set.seed()`](https://rdrr.io/r/base/Random.html) will not work with
  [foreach](https://rdrr.io/pkg/foreach/man/foreach.html)'s parallelized
  for loops; for a workaround, see [this
  solution](https://github.com/bgreenwell/vip/issues/145).

- parallelize_by:

  Character string specifying whether to parallelize across features
  (`parallelize_by = "features"`) or repetitions
  (`parallelize_by = "repetitions"`); the latter is only useful whenever
  `nsim > 1`. Default is `"features"`.

## Value

A tidy data frame (specifically, a data frame inheriting from class
`"vi"`; use
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
if you prefer a tibble) with two columns:

- `Variable` - the corresponding feature name;

- `Importance` - the associated importance, computed as the average
  change in performance after a random permutation (or permutations, if
  `nsim > 1`) of the feature in question.

If `nsim > 1`, then an additional column (`StDev`) containing the
standard deviation of the individual permutation scores for each feature
is also returned; this helps assess the stability/variation of the
individual permutation importance for each feature.

## References

Brandon M. Greenwell and Bradley C. Boehmke, The R Journal (2020) 12:1,
pages 343-366.

## Examples
