exit_if_not(at_home())

# Exits
if (!requireNamespace("xgboost", quietly = TRUE)) {
  exit_file("Package 'xgboost' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
fit <- xgboost::xgboost(  # params found using `autoxgb::autoxgb()`
  x = data.matrix(subset(friedman1, select = -y)),
  y = friedman1$y,
  max_depth = 3,
  learning_rate = 0.1,
  nrounds = 301,
  verbosity = 0
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

# Call `vip::vip()` directly; draws a plot (tinyplot/base R graphics) as a
# side effect and invisibly returns the plotted "vi" object
pdf(NULL)  # null graphics device
p <- vip(fit, method = "model", include_type = TRUE)
dev.off()
expect_inherits(p, class = "vi")
