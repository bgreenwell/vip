# Check dependencies
exit_if_not(
  requireNamespace("ranger", quietly = TRUE)
)

# Prediction wrappers
pfun <- function(object, newdata) {  # classification and regression
  predict(object, data = newdata)$predictions
}
pfun_prob <- function(object, newdata) {  # probability estimation
  predict(object, data = newdata)$predictions[, "yes"]  # P(survived|x)
}

# Load package data
data("titanic_mice")

# Read in data sets
f1 <-  gen_friedman(seed = 101)  # regression
t3 <- titanic_mice[[1L]]  # classification

# List all available metrics
metrics <- list_metrics()
expect_true(inherits(metrics, what = "data.frame"))


################################################################################
#
# Regression
#
################################################################################

# Expectation function for models built on the Friedman 1 data set
expectations_f1 <- function(object) {
  # Check class
  expect_identical(class(object),
                   target = c("vi", "tbl_df", "tbl", "data.frame"))

  # Check dimensions (should be one row for each feature)
  expect_identical(ncol(f1) - 1L, target = nrow(object))

  # Check top five predictors
  expect_true(all(paste0("x", 1L:5L) %in% object$Variable[1L:5L]))
}

# Fit a (default) random forest
set.seed(1433)  # for reproducibility
rfo_f1 <- ranger::ranger(y ~ ., data = f1)

# Try all regression metrics
regression_metrics <- metrics[metrics$task == "Regression", ]$metric
set.seed(828)  # for reproducibility
vis <- lapply(regression_metrics, FUN = function(x) {
  vi(rfo_f1, method = "permute", target = "y", metric = x,
     pred_wrapper = pfun, nsim = 10)
})
lapply(vis, FUN = expectations_f1)

# Use a custom metric
rsquared <- function(truth, estimate) {
  cor(truth, estimate) ^ 2
}

# Compute permutation-based importance using R-squared (character string)
set.seed(925)  # for reproducibility
vis_rsquared <- vi_permute(
  object = rfo_f1,
  # train = f1,
  target = "y",
  metric = "rsq",
  pred_wrapper = pfun,
  sample_size = 90,
  nsim = 10
)
expectations_f1(vis_rsquared)

# Compute permutation-based importance using R-squared (custim function)
set.seed(925)  # for reproducibility
vis_rsquared_custom <- vi_permute(
  object = rfo_f1,
  train = subset(f1, select = -y),
  target = f1$y,
  metric = rsquared,
  smaller_is_better = FALSE,
  sample_frac = 0.9,
  pred_wrapper = pfun,
  nsim = 10
)
expectations_f1(vis_rsquared_custom)

# Check that results are identical
expect_equal(vis_rsquared, target = vis_rsquared_custom)

# Expected errors for `vi_permute()`
expect_error(  # missing `pred_wrapper`
  vi_permute(
    object = rfo_f1,
    train = subset(f1, select = -y),
    target = f1$y,
    metric = rsquared,
    smaller_is_better = FALSE,
    # pred_wrapper = pfun,
    sample_frac = 0.9
  )
)
expect_error(  # missing `target`
  vi_permute(
    object = rfo_f1,
    train = subset(f1, select = -y),
    # target = f1$y,
    metric = rsquared,
    smaller_is_better = FALSE,
    pred_wrapper = pfun,
    sample_frac = 0.9
  )
)
expect_error(  # missing `smaller_is_better`
  vi_permute(
    object = rfo_f1,
    train = subset(f1, select = -y),
    target = f1$y,
    metric = rsquared,
    # smaller_is_better = FALSE,
    pred_wrapper = pfun,
    sample_frac = 0.9
  )
)
expect_error(  # trying to set`sample_frac` and `sample_size`
  vi_permute(
    object = rfo_f1,
    train = subset(f1, select = -y),
    target = f1$y,
    metric = rsquared,
    smaller_is_better = FALSE,
    pred_wrapper = pfun,
    sample_frac = 0.9,
    sample_size = 90
  )
)
expect_error(  # setting `sample_frac` outside of range
  vi_permute(
    object = rfo_f1,
    train = subset(f1, select = -y),
    target = f1$y,
    metric = rsquared,
    smaller_is_better = FALSE,
    pred_wrapper = pfun,
    sample_frac = 1.9
  )
)


################################################################################
#
# Binary classification
#
################################################################################

# Expectation function for models built on the Friedman 1 data set
expectations_t3 <- function(object) {
  # Check class
  expect_identical(class(object),
                   target = c("vi", "tbl_df", "tbl", "data.frame"))

  # Check dimensions (should be one row for each feature)
  expect_identical(ncol(t3) - 1L, target = nrow(object))

  # Expect all VI scores to be positive
  expect_true(all(object$Importance > 0))
}

# Fit a (default) random forest
set.seed(1454)  # for reproducibility
rfo_t3 <- ranger::ranger(survived ~ ., data = t3)

# Try all binary classification metrics
binary_class_metrics <-
  metrics[grepl("binary", x = metrics$task, ignore.case = TRUE), ]$metric[1:3]
set.seed(928)  # for reproducibility
vis <- lapply(binary_class_metrics, FUN = function(x) {
  vi(rfo_t3, method = "permute", target = "survived", metric = x,
     pred_wrapper = pfun, nsim = 10)
})
lapply(vis, FUN = expectations_t3)

# Fit a (default) probability forest
set.seed(1508)  # for reproducibility
rfo_t3_prob <- ranger::ranger(survived ~ ., data = t3, probability = TRUE)

# Try all probability-based metrics
binary_prob_metrics <- c("roc_auc", "pr_auc", "logloss")
set.seed(1028)  # for reproducibility
vis <- lapply(binary_prob_metrics, FUN = function(x) {
  vi(rfo_t3_prob, method = "permute", target = "survived", metric = x,
     pred_wrapper = pfun_prob, nsim = 10, event_level = "second")
})
lapply(vis, FUN = expectations_t3)

# Try user-supplied metric with Brier score
brier <- function(truth, estimate)  {
  mean((ifelse(truth == "yes", 1, 0) - estimate) ^ 2)
}
expectations_t3(
  vi(rfo_t3_prob, method = "permute", target = "survived", metric = brier,
     pred_wrapper = pfun_prob, nsim = 10, smaller_is_better = TRUE)
)
expect_error(  # need to set `smalle_is_better` for non built-in metrics
  vi(rfo_t3_prob, method = "permute", target = "survived", metric = brier,
     pred_wrapper = pfun_prob, nsim = 10)
)


################################################################################
#
# Parallel processing tests
#
################################################################################

# Test parallel processing with features (default behavior)
set.seed(1234)
vis_parallel_features <- vi_permute(
  object = rfo_f1,
  target = "y",
  metric = "rmse",
  pred_wrapper = pfun,
  nsim = 5,
  parallel = TRUE,
  parallelize_by = "features"
)
expectations_f1(vis_parallel_features)

# Test parallel processing with repetitions 
set.seed(1234)
vis_parallel_reps <- vi_permute(
  object = rfo_f1,
  target = "y", 
  metric = "rmse",
  pred_wrapper = pfun,
  nsim = 5,
  parallel = TRUE,
  parallelize_by = "repetitions"
)
expectations_f1(vis_parallel_reps)

# Test that results are similar between parallel methods (should be identical with same seed)
expect_equal(vis_parallel_features, vis_parallel_reps, tolerance = 1e-6)

# Test warning when trying to parallelize by repetitions with nsim = 1
expect_warning(
  vi_permute(
    object = rfo_f1,
    target = "y",
    metric = "rmse", 
    pred_wrapper = pfun,
    nsim = 1,
    parallel = TRUE,
    parallelize_by = "repetitions"
  ),
  "Parallelizing across repititions only works when `nsim > 1`"
)

# Test that non-parallel results match parallel results structure
set.seed(1234)
vis_sequential <- vi_permute(
  object = rfo_f1,
  target = "y",
  metric = "rmse",
  pred_wrapper = pfun,
  nsim = 5,
  parallel = FALSE
)
expectations_f1(vis_sequential)

# Verify all results have same structure and variables
expect_identical(vis_parallel_features$Variable, vis_sequential$Variable)
expect_identical(vis_parallel_reps$Variable, vis_sequential$Variable)
