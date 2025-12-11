# Skip on CRAN releases FIRST (large dependency tree prone to version conflicts)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("caret", quietly = TRUE)) {
  exit_file("Package 'caret' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
fit <- caret::train(y ~ ., friedman1, method = "lm")

# Compute VI scores
vis1 <- vi_model(fit)
vis2 <- caret::varImp(fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = vis2$importance[vis1$Variable, , drop = TRUE]
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.train(fit),
  target = paste0("x", 1L:10L)
)
