if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("C50", quietly = TRUE)) {
  exit_file("Package 'C50' missing")
}

# Generate Friedman benchmark data
friedman2 <- gen_friedman(seed = 101, n_bins = 2)

# Fit model(s)
fit1 <- C50::C5.0(y ~ ., friedman2)
fit2 <- C50::C5.0(x = friedman2[, paste0("x", 1L:10L)], y = friedman2$y)

# Compute VI scores
vis1 <- vi_model(fit1)
vis2 <- vi_model(fit2)

# Expectations for `vi_model()`
expect_identical(
  current = vis1,
  target = vis2
)
expect_identical(
  current = vis1$Importance,
  C50::C5imp(fit1, metric = "usage")$Overall
)
expect_identical(
  current = vi_model(fit1, type = "splits", pct = FALSE)$Importance,
  C50::C5imp(fit1, metric = "splits", pct = FALSE)$Overall
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.C5.0(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.C5.0(fit2),
  target = paste0("x", 1L:10L)
)
