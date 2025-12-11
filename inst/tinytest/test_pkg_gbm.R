if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("gbm", quietly = TRUE)) {
  exit_file("Package 'gbm' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
fit <- gbm::gbm(y ~ ., distribution = "gaussian", data = friedman1,
                n.trees = 100, interaction.depth = 2, shrinkage = 0.1)

# Compute VI scores
vis1 <- vi_model(fit)
set.seed(102)
vis2 <- vi_model(fit, type = "permutation")
vis3 <- gbm::summary.gbm(fit, plotit = FALSE)
set.seed(102)
vis4 <- gbm::summary.gbm(fit, plotit = FALSE,
                         method = gbm::permutation.test.gbm)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = vis3$rel.inf
)
expect_identical(
  current = vis2$Importance,
  target = vis4$rel.inf
)

# # Expectations for `get_training_data()`
# expect_identical(
#   current = vip:::get_training_data.gbm(fit),
#   target = friedman1
# )

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.gbm(fit),
  target = paste0("x", 1L:10L)
)
