if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("xgboost", quietly = TRUE)) {
  exit_file("Package 'xgboost' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
fit <- xgboost::xgboost(  # params found using `autoxgb::autoxgb()`
  data = data.matrix(subset(friedman1, select = -y)),
  label = friedman1$y,
  max_depth = 3,
  eta = 0.1,
  nrounds = 301,
  verbose = 0
)

# Compute VI scores
vis_gain <- vi_model(fit)
vis_cover <- vi_model(fit, type = "cover")
vis_frequency <- vi_model(fit, type = "frequency")
vis_xgboost <- xgboost::xgb.importance(model = fit)

# Expectations for `vi_model()`
expect_identical(
  current = vis_gain$Importance,
  target = vis_xgboost$Gain
)
expect_identical(
  current = vis_cover$Importance,
  target = vis_xgboost$Cover
)
expect_identical(
  current = vis_frequency$Importance,
  target = vis_xgboost$Frequency
)

# Expectations for `get_training_data()`
expect_error(vip:::get_training_data.default(fit))

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.xgb.Booster(fit),
  target = paste0("x", 1L:10L)
)

# Call `vip::vip()` directly
p <- vip(fit, method = "model", include_type = TRUE)

# Expect `p` to be a ggplot object (compatible with ggplot2 S7 transition)
expect_true(ggplot2::is_ggplot(p))
