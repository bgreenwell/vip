#' SHAP-based variable importance
#'
#' Compute SHAP-based VI scores for the predictors in a model. See details
#' below.
#'
#' @param object A fitted model object (e.g., a
#' [randomForest][randomForest::randomForest] object).
#'
#' @param feature_names Character string giving the names of the predictor
#' variables (i.e., features) of interest. If `NULL` (the default) then they
#' will be inferred from the `train` and `target` arguments (see below). It is
#' good practice to always specify this argument.
#'
#' @param train A matrix-like R object (e.g., a data frame or matrix)
#' containing the training data. If `NULL` (the default) then the
#' internal `get_training_data()` function will be called to try and extract it
#' automatically. It is good practice to always specify this argument.
#'
#' @param ... Additional arguments to be passed on to [fastshap::explain()]
#' (e.g., `nsim = 30`, `adjust = TRUE`, or a prediction wrapper via the
#' `pred_wrapper` argument); see `?fastshap::explain` for details on these and
#' other useful arguments.
#'
#' @return A tidy data frame (i.e., a [tibble][tibble::tibble] object) with two
#' columns:
#'
#' * `Variable` - the corresponding feature name;
#' * `Importance` - the associated importance, computed as the mean absolute
#' Shapley value.
#'
#' @details This approach to computing VI scores is based on the mean absolute
#' value of the SHAP values for each feature; see, for example,
#' <https://github.com/shap/shap> and the references therein.
#'
#' Strumbelj, E., and Kononenko, I. Explaining prediction models and individual
#' predictions with feature contributions. Knowledge and information systems
#' 41.3 (2014): 647-665.
#'
#' @rdname vi_shap
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(xgboost)
#'
#' # Simulate training data
#' trn <- gen_friedman(500, sigma = 1, seed = 101)  # ?vip::gen_friedman
#'
#' # Feature matrix
#' X <- data.matrix(subset(trn, select = -y))  # matrix of feature values
#'
#' # Fit an XGBoost model; hyperparameters were tuned using 5-fold CV
#' set.seed(859)  # for reproducibility
#' bst <- xgboost(X, label = trn$y, nrounds = 338, max_depth = 3, eta = 0.1,
#'                verbose = 0)
#'
#' # Construct VIP using "exact" SHAP values from XGBoost's internal Tree SHAP
#' # functionality
#' vip(bst, method = "shap", train = X, exact = TRUE, include_type = TRUE,
#'     geom = "point", horizontal = FALSE,
#'     plot_args = list(col = "forestgreen", pch = 17, cex = 2))
#'
#' # Use Monte-Carlo approach, which works for any model; requires prediction
#' # wrapper
#' pfun_prob <- function(object, newdata) {  # prediction wrapper
#'   # For Shapley explanations, this should ALWAYS return a numeric vector
#'   predict(object, newdata = newdata, type = "prob")[, "yes"]
#' }
#'
#' # Compute Shapley-based VI scores
#' set.seed(853)  # for reproducibility
#' vi_shap(rfo, train = subset(t1, select = -survived), pred_wrapper = pfun_prob,
#'         nsim = 30)
#' ## # A tibble: 5 × 2
#' ## Variable Importance
#' ##   <chr>         <dbl>
#' ## 1 pclass       0.104
#' ## 2 age          0.0649
#' ## 3 sex          0.272
#' ## 4 sibsp        0.0260
#' ## 5 parch        0.0291
#' }
vi_shap <- function(object, ...) {
  UseMethod("vi_shap")
}


#' @rdname vi_shap
#'
#' @export
vi_shap.default <- function(object, feature_names = NULL, train = NULL, ...) {

  # Check for fastshap package
  if (!requireNamespace("fastshap", quietly = TRUE)) {
    stop("Package \"fastshap\" needed for this function to work. ",
         "Please install it.", call. = FALSE)
  }
  if (utils::packageVersion("fastshap") < "0.1.0") {
    stop("Package \"fastshap (>= 0.1.0)\" needed for this function to work. ",
         "Please install it.", call. = FALSE)
  }

  # Try to extract feature names if not supplied
  if (is.null(feature_names)) {
    feature_names <- get_feature_names(object)
  }

  # Try to extract training data if not supplied
  if (is.null(train)) {
    train <- get_training_data(object)
  }

  # Make sure only the feature columns are used (e.g., no response)
  train <- train[, feature_names, drop = FALSE]

  # Compute SHAP values
  shap <- fastshap::explain(
    object = object,
    feature_names = feature_names,
    X = train,
    shap_only = TRUE,
    ...
  )

  # Construct SHAP-based variable importance scores
  tib <- new_vi(
    colnames(shap),
    importance = unname(colMeans(abs(as.matrix(shap)))),
    type = "mean(|Shapley value|)"
  )
  attr(tib, which = "shap") <- shap

  # Return results
  tib

}
