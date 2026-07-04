# Specify model formulae
form1 <- y ~ x1 + x2 + I(x2 ^ 2) + sin(x2)
form2 <- ~ x1 + x2 + I(x2 ^ 2) + sin(x2)  # no LHS
form3 <- terms(y ~ ., data = data.frame(y = 1:5, x1 = 1:5, x2 = 1:5))

# Expectations
expect_identical(
  current = vip:::get_feature_names.formula(form1),
  target = c("x1", "x2")
)
expect_error(
  current = vip:::get_feature_names.formula(form2)
)
expect_identical(  # check dot expansion
  current = vip:::get_feature_names.formula(form3),
  target = c("x1", "x2")
)
