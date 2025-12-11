if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("earth", quietly = TRUE)) {
  exit_file("Package 'earth' missing")
}

# Load required packages
suppressMessages({
  library(earth)
})

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
fit <- earth::earth(y ~ ., degree = 2, data = friedman1)

# Compute VI scores
vis_nsubsets <- vi_model(fit)
vis_rss <- vi_model(fit, type = "rss")
vis_gcv <- vi_model(fit, type = "gcv")
vis_earth <- earth::evimp(fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis_nsubsets[seq_len(nrow(vis_earth)), ]$Importance,
  target = unname(vis_earth[, "nsubsets", drop = TRUE])
)
expect_identical(
  current = vis_rss[seq_len(nrow(vis_earth)), ]$Importance,
  target = unname(vis_earth[, "rss", drop = TRUE])
)
expect_identical(
  current = vis_gcv[seq_len(nrow(vis_earth)), ]$Importance,
  target = unname(vis_earth[, "gcv", drop = TRUE])
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.earth(fit),
  target = paste0("x", 1L:10L)
)
