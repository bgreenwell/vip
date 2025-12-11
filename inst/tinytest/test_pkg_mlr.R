# Skip on CRAN releases FIRST to avoid loading mlr namespace (conflicts with mlr3)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

# Exits
if (!requireNamespace("mlr", quietly = TRUE)) {
  exit_file("Package 'mlr' missing")
}
if (!requireNamespace("ranger", quietly = TRUE)) {
  exit_file("Package 'ranger' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
task <- mlr::makeRegrTask("friedman", data = friedman1, target = "y")
lrnr <- mlr::makeLearner("regr.ranger", importance = "impurity")
fit <- mlr::train(lrnr, task = task)

# Compute model-based VI scores
vis <- vi_model(fit)

# Expect `vi()` and `vi_model()` to both work
expect_identical(
  current = vi(fit, sort = FALSE),
  target = vi_model(fit)
)

# Expectations for `vi_model()`
expect_identical(
  current = vis$Importance,
  target = unname(fit$learner.model$variable.importance)
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.WrappedModel(fit),
  target = paste0("x", 1L:10L)
)

# Clean up
unloadNamespace("mlr")
