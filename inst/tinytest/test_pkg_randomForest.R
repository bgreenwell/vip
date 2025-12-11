if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("randomForest", quietly = TRUE)) {
  exit_file("Package 'randomForest' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman2 <- gen_friedman(seed = 101, n_bins = 2)

# Fit model(s)
set.seed(101)
fit1 <- randomForest::randomForest(y ~ ., data = friedman1)
fit2 <- randomForest::randomForest(y ~ ., data = friedman1, importance = TRUE)
fit3 <- randomForest::randomForest(
  x = subset(friedman1, select = -y),
  y = friedman1$y
)
fit4 <- randomForest::randomForest(y ~ ., data = friedman2, importance = TRUE)

# Compute VI scores
vis1 <- vi_model(fit1)
vis2 <- vi_model(fit2, type = 1)
vis3 <- vi_model(fit3)
vis4 <- vi_model(fit4, type = 2, scale = FALSE)


# Expectations for `vi_model()`
expect_error(vi_model(fit1, type = 1))
expect_identical(
  current = vis1$Importance,
  target = unname(fit1$importance[, "IncNodePurity"])
)
expect_identical(
  current = vi_model(fit2, type = 1, scale = FALSE)$Importance,
  target = unname(fit2$importance[, "%IncMSE", drop = TRUE])
)
expect_identical(
  current = vis3$Importance,
  target = unname(fit3$importance[, "IncNodePurity"])
)
expect_identical(
  current = vis4$Importance,
  target = unname(fit4$importance[, "MeanDecreaseGini", drop = TRUE])
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.randomForest(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.randomForest(fit3),
  target = paste0("x", 1L:10L)
)
