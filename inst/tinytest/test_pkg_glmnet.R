exit_if_not(at_home())

# Exits
if (!requireNamespace("glmnet", quietly = TRUE)) {
  exit_file("Package 'glmnet' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman3 <- gen_friedman(seed = 101, n_bins = 3)

# Fit model(s)
fit1 <- glmnet::glmnet(
  x = data.matrix(subset(friedman1, select = -y)),
  y = friedman1$y
)
fit2 <- glmnet::cv.glmnet(
  x = data.matrix(subset(friedman1, select = -y)),
  y = friedman1$y
)
fit3 <- glmnet::glmnet(
  x = data.matrix(subset(friedman3, select = -y)),
  y = friedman3$y,
  family = "multinomial"
)

# Compute VI scores
vis1 <- vi_model(fit1)
vis2 <- vi_model(fit2)
vis3 <- vi_model(fit3)

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = abs(coef(fit1, s = min(fit1$lambda))[-1L])
)
expect_identical(
  current = vis2$Importance,
  target = abs(coef(fit2, s = "lambda.1se")[-1L])
)
expect_identical(
  current = vis3$Importance,
  target = abs(coef(fit3, s = min(fit3$lambda))[[1L]][-1L])
)
expect_identical(
  current = vi_model(fit1, lambda = fit1$lambda[5L])$Importance,
  target = abs(coef(fit1, s = fit1$lambda[5L])[-1L])
)
expect_identical(
  current = vi_model(fit2, lambda = fit2$lambda[5L])$Importance,
  target = abs(coef(fit2, s = fit2$lambda[5L])[-1L])
)
expect_identical(
  current = vi_model(fit3, lambda = fit3$lambda[5L])$Importance,
  target = abs(coef(fit3, s = fit3$lambda[5L])[[1L]][-1L])
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.glmnet(fit1),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.cv.glmnet(fit2),
  target = paste0("x", 1L:10L)
)
expect_identical(
  current = vip:::get_feature_names.multnet(fit3),
  target = paste0("x", 1L:10L)
)

# Exactly-zero coefficients (e.g., lasso-shrunk) should get Sign = "ZERO"
# https://github.com/bgreenwell/vip/issues/104
vis_zero <- vi_model(fit1, lambda = 1.0)  # large penalty -> some zero coefs
expect_true(any(vis_zero$Importance == 0))
expect_identical(
  current = vis_zero$Sign[vis_zero$Importance == 0],
  target = rep("ZERO", times = sum(vis_zero$Importance == 0))
)
expect_true(all(vis_zero$Sign[vis_zero$Importance > 0] %in% c("POS", "NEG")))
