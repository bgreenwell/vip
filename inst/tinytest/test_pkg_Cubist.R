if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("caret", quietly = TRUE)) {
  exit_file("Package 'caret' missing")
}
if (!requireNamespace("Cubist", quietly = TRUE)) {
  exit_file("Package 'Cubist' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
fit <- Cubist::cubist(
  x = subset(friedman1, select = -y),
  y = friedman1$y,
  committees = 10
)

# Compute VI scores
vis1 <- vi_model(fit)
vis2 <- caret::varImp(fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = vis2[vis1$Variable, , drop = TRUE]
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.cubist(fit),
  target = paste0("x", 1L:10L)
)
