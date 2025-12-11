if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  exit_file("Skip on CRAN")
}

# Load Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman2 <- gen_friedman(seed = 101, n_bins = 2)

# Fit an additive linear regression model
fit_lm <- lm(y ~ ., data = friedman1)

# Fit an additive logistic regression model
fit_glm <- glm(y ~ ., data = friedman2, family = "binomial")

# Compute variable importance scores
vi_lm <- vi_model(fit_lm)
vi_glm <- vi_model(fit_glm)

# Expectations for `vi_model()`
expect_identical(
  current = vi_lm$Importance,
  target = unname(abs(summary(fit_lm)$coefficients[, "t value"])[-1])
)
expect_identical(
  current = vi_glm$Importance,
  target = unname(abs(summary(fit_glm)$coefficients[, "z value"])[-1])
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.lm(fit_lm),
  target = paste0("x", 1L:10L)
)

# Setting `type = "raw"` should return the aboldute value of the original
# coefficients (as opposed to |t-value| or |z-value|)
expect_identical(
  current = vi_model(fit_lm, type = "raw")$Importance,
  target = unname(abs(coef(fit_lm))[-1])
)
