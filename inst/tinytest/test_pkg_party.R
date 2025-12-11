if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("party", quietly = TRUE)) {
  exit_file("Package 'party' missing")
}
if (!requireNamespace("varImp", quietly = TRUE)) {
  exit_file("Package 'varImp' missing")
}

# Load required packages
suppressMessages({
  library(party)
  library(varImp)
})

# Generate Friedman benchmark data
friedman2 <- gen_friedman(seed = 101, n_bins = 2)

# Fit model(s)
set.seed(101)
fit1 <- party::cforest(y ~ ., data = friedman2)
fit2 <- party::ctree(y ~ ., data = friedman2)

# Compute VI scores
set.seed(102)
vis1 <- vi_model(fit1)
set.seed(102)
vis2 <- vi_model(fit1, type = "auc")
set.seed(102)
vis3 <- party::varimp(fit1)
set.seed(102)
vis4 <- party::varimpAUC(fit1)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = unname(vis3)
)
expect_identical(
  current = vis2$Importance,
  target = unname(vis4)
)

# Expectations for `get_training_data()`
expect_equal(
  current = vip:::get_training_data.RandomForest(fit1),
  target = subset(friedman2, select = -y),
  check.attributes = FALSE
)
expect_equal(
  current = vip:::get_training_data.BinaryTree(fit2),
  target = subset(friedman2, select = -y),
  check.attributes = FALSE
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.RandomForest(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.BinaryTree(fit2),
  target = paste0("x", 1L:10L)
)
