#' Variable importance
#'
#' Compute variable importance scores for the predictors in a model.
#'
#' @param object A fitted model object (e.g., a
#' [randomForest][randomForest::randomForest] object) or an object that inherits
#' from class `"vi"`.
#'
#' @param method Character string specifying the type of variable importance
#' (VI) to compute. Current options are:
#'
#' * `"model"` (the default), for model-specific VI scores (see
#' [vi_model][vip::vi_model] for details).
#'
#' * `"firm"`, for variance-based VI scores (see [vi_firm][vip::vi_firm] for
#' details).
#'
#' * `"permute"`, for permutation-based VI scores (see
#' [vi_permute][vip::vi_permute] for details).
#'
#' * `"shap"`, for Shapley-based VI scores (see [vi_shap][vip::vi_shap] for
#' details).
#'
#' @param feature_names Character string giving the names of the predictor
#' variables (i.e., features) of interest.
#'
#' @param abbreviate_feature_names Integer specifying the length at which to
#' abbreviate feature names. Default is `NULL` which results in no
#' abbreviation (i.e., the full name of each feature will be printed).
#'
#' @param sort Logical indicating whether or not to order the sort the variable
#' importance scores. Default is `TRUE`.
#'
#' @param decreasing Logical indicating whether or not the variable importance
#' scores should be sorted in descending (`TRUE`) or ascending
#' (\code{FALSE}) order of importance. Default is `TRUE`.
#'
#' @param scale Logical indicating whether or not to scale the variable
#' importance scores so that the largest is 100. Default is `FALSE`.
#'
#' @param rank Logical indicating whether or not to rank the variable
#' importance scores (i.e., convert to integer ranks). Default is `FALSE`.
#' Potentially useful when comparing variable importance scores across different
#' models using different methods.
#'
#' @param ... Additional optional arguments to be passed on to
#' [vi_model][vip::vi_model], [vi_firm][vip::vi_firm],
#' [vi_permute][vip::vi_permute], or [vi_shap][vip::vi_shap]; see their
#' respective help pages for details.
#'
#' @return A tidy data frame (specifically, a data frame inheriting from class
#' `"vi"`; use `tibble::as_tibble()` if you prefer a tibble) with two
#' columns:
#'
#' * `Variable` - the corresponding feature name;
#' * `Importance` - the associated importance, computed by the requested
#' `method` (e.g., the average change in performance after permutation for
#' `method = "permute"`, or a model-specific measure for `method = "model"`);
#' see the help page for the corresponding `vi_*()` function for details.
#'
#' For [lm][stats::lm]/[glm][stats::glm]-like objects, whenever
#' `method = "model"`, the sign (i.e., POS/NEG) of the original coefficient is
#' also included in a column called `Sign`.
#'
#' If `method = "permute"` and `nsim > 1`, then an additional column (`StDev`)
#' containing the standard deviation of the individual permutation scores for
#' each feature is also returned; this helps assess the stability/variation of
#' the individual permutation importance for each feature.
#'
#' @rdname vi
#'
#' @export
#'
#' @examples
#' #
#' # A projection pursuit regression example
#' #
#'
#' # Load the sample data
#' data(mtcars)
#'
#' # Fit a projection pursuit regression model
#' mtcars.ppr <- ppr(mpg ~ ., data = mtcars, nterms = 1)
#'
#' # Prediction wrapper that tells vi() how to obtain new predictions from your
#' # fitted model
#' pfun <- function(object, newdata) predict(object, newdata = newdata)
#'
#' # Compute permutation-based variable importance scores
#' set.seed(1434)  # for reproducibility
#' (vis <- vi(mtcars.ppr, method = "permute", target = "mpg", nsim = 10,
#'            metric = "rmse", pred_wrapper = pfun, train = mtcars))
#'
#' # Plot variable importance scores (`plot()` passes its `...` on to
#' # `tinyplot::tinyplot()`)
#' plot(vis, type = "point", include_type = TRUE, all_permutations = TRUE,
#'      col = "forestgreen", cex = 2)
#'
#' #
#' # A binary classification example
#' #
#' \dontrun{
#' library(rpart)  # for classification and regression trees
#'
#' # Load Wisconsin breast cancer data; see ?mlbench::BreastCancer for details
#' data(BreastCancer, package = "mlbench")
#' bc <- subset(BreastCancer, select = -Id)  # for brevity
#'
#' # Fit a standard classification tree
#' set.seed(1032)  # for reproducibility
#' tree <- rpart(Class ~ ., data = bc, cp = 0)
#'
#' # Prune using 1-SE rule (e.g., use `plotcp(tree)` for guidance)
#' cp <- tree$cptable
#' cp <- cp[cp[, "nsplit"] == 2L, "CP"]
#' tree2 <- prune(tree, cp = cp)  # tree with three splits
#'
#' # Default tree-based VIP
#' vip(tree2)
#'
#' # Computing permutation importance requires a prediction wrapper. For
#' # classification, the return value depends on the chosen metric; see
#' # `?vip::vi_permute` for details.
#' pfun <- function(object, newdata) {
#'   # Need vector of predicted class probabilities when using  log-loss metric
#'   predict(object, newdata = newdata, type = "prob")[, "malignant"]
#' }
#'
#' # Permutation-based importance (note that only the predictors that show up
#' # in the final tree have non-zero importance)
#' set.seed(1046)  # for reproducibility
#' vi(tree2, method = "permute", nsim = 10, target = "Class", train = bc,
#'    metric = "logloss", pred_wrapper = pfun, reference_class = "malignant")
#'
#' # Equivalent (but not sorted)
#' set.seed(1046)  # for reproducibility
#' vi_permute(tree2, nsim = 10, target = "Class", metric = "logloss",
#'            pred_wrapper = pfun, reference_class = "malignant")
#' }
vi <- function(object, ...) {
  UseMethod("vi")
}


#' @rdname vi
#'
#' @export
vi.default <- function(
  object,
  method = c("model", "firm", "permute", "shap"),
  feature_names = NULL,
  abbreviate_feature_names = NULL,
  sort = TRUE,
  decreasing = TRUE,
  scale = FALSE,
  rank = FALSE,
  ...
) {

  # Construct VI scores
  method <- match.arg(method)
  if (method == "firm") {
    if (is.null(feature_names)) {
      feature_names <- get_feature_names(object)
    }
  }

  # Construct data frame of VI scores
  tib <- switch(method,
    "model" = vi_model(object, ...),
    "firm" = vi_firm(object, feature_names = feature_names, ...),
    "permute" = vi_permute(object, feature_names = feature_names, ...),
    vi_shap(object, feature_names = feature_names, ...)
  )

  # Save attribute
  vi_type <- attr(tib, which = "type")

  # Remove rows with NA
  tib <- stats::na.omit(tib)

  # Sort VI scores (if requested)
  if (sort) {
    tib <- sort_importance_scores(tib, decreasing = decreasing)
  }

  # Abbreviate feature names (if requested)
  if (!is.null(abbreviate_feature_names)) {
    tib <- abbreviate_names(tib, minlength = abbreviate_feature_names)
  }

  # Scale VI scores so that largest is 100
  if (scale) {
    tib$Importance <- tib$Importance / max(tib$Importance) * 100
  }

  # Rank VI scores (i.e., convert to ranks with 1 = most important); works
  # regardless of whether or how the scores are sorted
  if (rank) {
    tib$Importance <- rank(-tib$Importance, ties.method = "average")
  }

  # Restore attribute
  attr(tib, which = "type") <- vi_type

  # Add "vi" class
  if (!inherits(tib, what = "vi")) {  # In case class gets stripped?
    class(tib) <- c("vi", class(tib))
  }

  # Return results
  tib

}
