if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("caret", quietly = TRUE)) {
  exit_file("Package 'caret' missing")
}
if (!requireNamespace("pls", quietly = TRUE)) {
  exit_file("Package 'pls' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
fit <- pls::mvr(y ~ ., data = friedman1)

# Compute VI scores
vis <- vi_model(fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis$Importance,
  target = caret::varImp(fit)$Overall
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.mvr(fit),
  target = paste0("x", 1L:10L)
)
