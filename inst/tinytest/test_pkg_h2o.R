# Skip on CRAN releases FIRST to avoid h2o initialization issues
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

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
