if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("rpart", quietly = TRUE)) {
  exit_file("Package 'rpart' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
fit <- rpart::rpart(y ~ ., data = friedman1)
no_splits <- rpart::rpart(y ~ ., data = friedman1, minsplit = 1e06)

# Compute VI scores
vis <- vi_model(fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis$Importance,
  target = unname(fit$variable.importance)
)
expect_error(vi(no_splits))

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.rpart(fit),
  target = paste0("x", 1L:10L)
)
