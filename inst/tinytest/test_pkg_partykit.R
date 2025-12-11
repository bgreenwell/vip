if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Exits
if (!requireNamespace("partykit", quietly = TRUE)) {
  exit_file("Package 'partykit' missing")
}

# Load required packages
suppressMessages({
  library(partykit)
})

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)
fit1 <- partykit::ctree(y ~ ., data = friedman1)
fit2 <- partykit::cforest(y ~ ., data = friedman1)

# Compute VI scores
set.seed(102)
vis1 <- vi_model(fit1)
set.seed(102)
vis2 <- vi_model(fit2)
set.seed(102)
vis3 <- partykit::varimp(fit1)
set.seed(102)
vis4 <- partykit::varimp(fit2)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance[seq_along(vis3)],
  target = unname(vis3)
)
expect_identical(
  current = vis2$Importance,
  target = unname(vis4)
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.constparty(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.cforest(fit2),
  target = paste0("x", 1L:10L)
)
