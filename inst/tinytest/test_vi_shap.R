# Exits
if (!requireNamespace("fastshap", quietly = TRUE)) {
  exit_file("Package 'fastshap' missing")
}

# Simulate Friedman benchmark data
trn1 <- gen_friedman(100, seed = 1421)
trn2 <- gen_friedman(100, seed = 1421, n_bins = 2)

# Fit a random forest
set.seed(1502)  # for reproducibility
fit1 <- lm(y ~ ., data = trn1)
fit2 <- glm(y ~ ., data = trn2, family = binomial(link = "logit"))

# Prediction wrapper
pfun <- function(object, newdata) {
  predict(object, newdata = newdata, type = "response")
}

# Compute SHAP-based VI scores
set.seed(1511)  # for reproducibility
vis1 <- vi_shap(fit1, pred_wrapper = pfun, nsim = 10, train = trn1)
vis2 <- vi_shap(fit2, pred_wrapper = pfun, nsim = 10, train = trn2)
vis3 <- vi(fit1, method = "shap", pred_wrapper = pfun, nsim = 10, train = trn1)

# Expectations
for (v in list(vis1, vis2, vis3)) {
  expect_inherits(v, c("vi", "data.frame"))
  expect_true(all(c("Variable", "Importance") %in% names(v)))
}
