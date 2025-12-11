# Skip on CRAN releases FIRST (platform-specific compilation issues)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

# Exits
if (!requireNamespace("lightgbm", quietly = TRUE)) {
  exit_file("Package 'lightgbm' missing")
}

# Load package data
data("titanic_mice")

# Basic example using imputed titanic data set
t3 <- titanic_mice[[1L]]

# Fit a simple model
set.seed(1449)  # for reproducibility
bst <- lightgbm::lightgbm(
  data = data.matrix(subset(t3, select = -survived)),
  label = ifelse(t3$survived == "yes", 1, 0),
  params = list("objective" = "binary", "force_row_wise" = TRUE),
  verbose = 0
)

# Compute VI scores
vi_gain <- vi_model(bst)
vi_cover <- vi_model(bst, type = "cover")
vi_frequency <- vi_model(bst, type = "frequency")
vi_lightgbm <- lightgbm::lgb.importance(model = bst)

# Expectations for `vi_model()`
expect_identical(
  current = vi_gain$Importance,
  target = vi_lightgbm$Gain
)
expect_identical(
  current = vi_cover$Importance,
  target = vi_lightgbm$Cover
)
expect_identical(
  current = vi_frequency$Importance,
  target = vi_lightgbm$Frequency
)
expect_identical(
  current = vi_model(bst, percentage = FALSE)$Importance,
  target = lightgbm::lgb.importance(bst, percentage = FALSE)$Gain
)

# Expectations for `get_training_data()`
expect_error(vip:::get_training_data.default(bst))

# Call `vip::vip()` directly
p <- vip(bst, method = "model", include_type = TRUE)

# Expect `p` to be a ggplot object (compatible with ggplot2 S7 transition)
expect_true(ggplot2::is_ggplot(p))
