# Check dependencies
exit_if_not(
  requireNamespace("pdp", quietly = TRUE),
  requireNamespace("ranger", quietly = TRUE)
)

# Load package data
data("titanic_mice")

# Use one of the available (imputed) versions of the Titanic data
titanic <- titanic_mice[[1L]]

# Feature names
xnames <- names(subset(titanic, select = -survived))

# Fit a default probability forest
set.seed(1511)  # for reproducibility
rfo <- ranger(survived ~ ., data = titanic, probability = TRUE)

# Function to run expectations
expectations <- function(object) {

  # Check class
  expect_identical(class(object),
                   target = c("vi", "tbl_df", "tbl", "data.frame"))

  # Check dimensions (should be one row for each feature)
  expect_identical(ncol(titanic) - 1L, target = nrow(object))

  # Check top five predictors
  expect_identical(xnames, object[["Variable"]])

  # Check attributes
  expect_true("effects" %in% names(attributes(object)))

}

# Prediction wrappers
pfun.pd <- function(object, newdata) {
  mean(predict(object, data = newdata)$predictions[, "yes"])
}
pfun.ice <- function(object, newdata) {
  predict(object, data = newdata)$predictions[, "yes"]
}

# Compute PD-based importance
vis_pd <- vi_firm(rfo)  # default (centered) logit scale
vis_pd_prob <- vi_firm(rfo, prob = TRUE)  # probability scale
vis_pd_pfun <- vi_firm(rfo, pred.fun = pfun.pd)

# Expectations
expectations(vis_pd)
expect_equal(vis_pd_prob, vis_pd_pfun)

# Compute ICE-based importance
vis_ice <- vi_firm(rfo, ice = TRUE, prob = TRUE, var_continuous = mad)  # use ICE plots
vis_ice_pfun <- vi_firm(rfo, pred.fun = pfun.ice, var_continuous = mad)

# Expectations
expectations(vis_ice)
expect_equal(vis_ice, vis_ice_pfun)

# Use `vi()` function
vis_ice_vi <- vi(rfo, method = "firm", ice = TRUE, prob = TRUE,
                 var_continuous = mad)

# Expectations
expect_identical(sort(vis_ice$Importance), sort(vis_ice_vi$Importance))

# Check computation by hand!
age.effect <- attr(vis_ice, which = "effects")$age
x <- mean(tapply(age.effect$yhat, INDEX = age.effect$yhat.id, FUN = mad))
y <- vis_ice[vis_ice$Variable == "age", "Importance", drop = TRUE]
expect_identical(x, y)
