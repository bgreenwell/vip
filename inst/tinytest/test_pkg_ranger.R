if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("ranger", quietly = TRUE)) {
  exit_file("Package 'ranger' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman3 <- gen_friedman(seed = 101, n_bins = 3)

# Fit model(s)
set.seed(101)
fit1 <- ranger::ranger(y ~ ., data = friedman1)
fit2 <- ranger::ranger(y ~ ., data = friedman1, importance = "impurity")

# Compute model-based VI scores
vis <- vi_model(fit2)

# Expectations for `vi_model()`
expect_error(vi_model(fit1))
expect_identical(
  current = vis$Importance,
  target = unname(fit2$variable.importance)
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.ranger(fit1),
  target = paste0("x", 1L:10L)
)
