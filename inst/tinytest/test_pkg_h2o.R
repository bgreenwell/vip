# Skip on CRAN releases FIRST to avoid h2o initialization issues
exit_if_not(at_home())

# Exits
if (!requireNamespace("h2o", quietly = TRUE)) {
  exit_file("Package 'h2o' missing")
}

# Load required packages
suppressMessages({
  library(h2o)
})

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman2 <- gen_friedman(seed = 101, n_bins = 2)
friedman3 <- gen_friedman(seed = 101, n_bins = 3)

# Initialize connection to H2O
h2o.init()
h2o.no_progress()

# Fit model(s)
fit1 <- h2o.glm(  # regression
  x = paste0("x", 1L:10L),
  y = "y",
  training_frame = as.h2o(friedman1)
)
fit2 <- h2o.glm(  # binary classification
  x = paste0("x", 1L:10L),
  y = "y",
  training_frame = as.h2o(friedman2),
  family = "binomial"
)
fit3 <- h2o.glm(  # multiclass classification
  x = paste0("x", 1L:10L),
  y = "y",
  training_frame = as.h2o(friedman3),
  family = "multinomial"
)

# Compute VI scores
vis1 <- vi_model(fit1)
vis2 <- vi_model(fit2)
vis3 <- vi_model(fit3)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = h2o.varimp(fit1)$relative_importance
)
expect_identical(
  current = vis2$Importance,
  target = h2o.varimp(fit2)$relative_importance
)
expect_identical(
  current = vis3$Importance,
  target = h2o.varimp(fit3)$relative_importance
)

# FIXME: Why not identical? Conversion issues?

# Non-GLM algorithms support the `type` argument for selecting which column
# of the H2O variable importance table to use
# https://github.com/bgreenwell/vip/issues/89
fit4 <- h2o.gbm(  # regression
  x = paste0("x", 1L:10L),
  y = "y",
  training_frame = as.h2o(friedman1),
  ntrees = 10
)
h2o_imp <- as.data.frame(h2o.varimp(fit4))
vis4 <- vi_model(fit4)  # default: relative_importance
expect_identical(vis4$Importance, target = h2o_imp$relative_importance)
expect_identical(attr(vis4, which = "type"), target = "relative_importance")
vis4_pct <- vi_model(fit4, type = "percentage")
expect_identical(vis4_pct$Importance, target = h2o_imp$percentage)
expect_identical(attr(vis4_pct, which = "type"), target = "percentage")
vis4_scl <- vi_model(fit4, type = "scaled_importance")
expect_identical(vis4_scl$Importance, target = h2o_imp$scaled_importance)

# Expectations for `get_training_data()`
expect_equal(
  current = vip:::get_training_data.H2ORegressionModel(fit1),
  target = friedman1
)
expect_equal(
  current = vip:::get_training_data.H2OBinomialModel(fit2),
  target = friedman2
)
expect_equal(
  current = vip:::get_training_data.H2OMultinomialModel(fit3),
  target = friedman3
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.H2ORegressionModel(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.H2OBinomialModel(fit2),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.H2OMultinomialModel(fit3),
  target = paste0("x", 1L:10L)
)

# Shutdown H2O connection
h2o.shutdown(prompt = FALSE)
