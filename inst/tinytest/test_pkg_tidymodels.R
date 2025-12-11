# Skip on CRAN releases FIRST (meta-package with 80+ dependency tree)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

# Exits
if (!requireNamespace("ranger", quietly = TRUE)) {
  exit_file("Package 'ranger' missing")
}
if (!requireNamespace("tidymodels", quietly = TRUE)) {
  exit_file("Package 'tidymodels' missing")
}



# FIXME: Switch to data set where we know the actual ranking of the features in
# terms of predictive performance.

################################################################################
# Fit a random forest to some sample data
################################################################################

# Load sample data from 'modeldata' package
data("bivariate", package = "modeldata")

# Define a 'ranger'-based random forest model
ranger_spec <- parsnip::rand_forest(trees = 1e3, mode = "classification") |>
  parsnip::set_engine("ranger", importance = "impurity")

# Fit models
set.seed(421)  # for reproduicbility
ranger_fit_workflow <-  # worflows
  workflows::workflow(Class ~ ., ranger_spec) |>
  parsnip::fit(bivariate_train)
ranger_fit_parsnip <-  # parsnip
  ranger_spec |>
  parsnip::fit(Class ~ ., data = bivariate_train)

# Extract underlying 'ranger' fits
fit_workflow <- workflows::extract_fit_engine(ranger_fit_workflow)
fit_parsnip <- parsnip::extract_fit_engine(ranger_fit_parsnip)


################################################################################
# Model-based variable importance
################################################################################

# Extract model-based VI scores
vi_mod_workflow <- vi(ranger_fit_workflow)
vi_mod_parsnip <- vi(ranger_fit_parsnip)

# Expect model-based VI scores to be of type "impurity"
expect_identical(attr(vi_mod_workflow, which = "type"), "impurity")
expect_identical(attr(vi_mod_parsnip, which = "type"), "impurity")

# Expect VI scores to be the same (when sorted in decreasing order)
expect_equivalent(vi_mod_workflow$Importance,
                  sort(fit_workflow$variable.importance, decreasing = TRUE))
expect_equivalent(vi_mod_parsnip$Importance,
                  sort(fit_parsnip$variable.importance, decreasing = TRUE))


################################################################################
# Permutation-based (i.e., model-agnostic) variable importance
################################################################################

# Define prediction wrapper for 'workflow' object
pfun <- function(object, newdata) {
  # Get predicted prob for class "One"
  predict(object, new_data = newdata , type = "prob")[[".pred_One"]]
}

# Compute permutation-based VI scores using AUC metric
set.seed(912)  # for reproducibility
vi_auc <- ranger_fit_workflow |>
  vi(method = "permute",
     target = "Class",
     metric = "roc_auc",
     pred_wrapper = pfun,
     event_level = "first",
     nsim = 10,
     train = bivariate_train,
     reference_class = "One")

# Not always the case, but here we can expect these to be in (0, 1)
expect_true(all(vi_auc$Importance > 0 & vi_auc$Importance < 1))


################################################################################
# FIRM-based (i.e., model-agnostic) variable importance
################################################################################

pfun <- function(object, newdata) {
  mean(predict(object, new_data = newdata, type = "prob")[[".pred_One"]])
}
vi_pd <- ranger_fit_workflow |>
  vi_firm(
    feature_names = c("A", "B"),  # required
    train = bivariate_train,      # required
    # pdp::partial()-specific arguments
    pred.fun = pfun
  )

# Not always the case, but here we can expect these to be in (0, 1)
expect_true(all(vi_pd$Importance > 0))
