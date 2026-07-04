#' Variance-based variable importance
#'
#' Compute variance-based variable importance (VI) scores using a simple
#' \emph{feature importance ranking measure} (FIRM) approach; for details, see
#' \href{https://arxiv.org/abs/1805.04755}{Greenwell et al. (2018)} and
#' \href{https://arxiv.org/abs/1904.03959}{Scholbeck et al. (2019)}.
#'
#' @param object A fitted model object (e.g., a
#' [randomForest][randomForest::randomForest] object).
#'
#' @param feature_names Character string giving the names of the predictor
#' variables (i.e., features) of interest. If `NULL` (the default) then the
#' internal `get_feature_names()` function will be called to try and extract
#' them automatically. It is good practice to always specify this argument.
#'
#' @param train A matrix-like R object (e.g., a data frame or matrix)
#' containing the training data. If `NULL` (the default) then the
#' internal `get_training_data()` function will be called to try and extract it
#' automatically. It is good practice to always specify this argument.
#'
#' @param var_fun Deprecated; use `var_continuous` and `var_categorical`
#' instead.
#'
#' @param var_continuous Function used to quantify the variability of effects
#' for continuous features. Defaults to using the sample standard deviation
#' (i.e., [stats::sd()]).
#'
#' @param var_categorical Function used to quantify the variability of effects
#' for categorical features. Defaults to using the range divided by four; that
#' is, `function(x) diff(range(x)) / 4`.
#'
#' @param ... Additional arguments to be passed on to the [pdp::partial()]
#' function (e.g., `ice = TRUE`, `prob = TRUE`, or a prediction wrapper via the
#' `pred.fun` argument); see `?pdp::partial` for details on these and other
#' useful arguments.
#'
#' @return A tidy data frame (i.e., a [tibble][tibble::tibble] object) with two
#' columns:
#'
#' * `Variable` - the corresponding feature name;
#' * `Importance` - the associated importance, computed as described in
#' [Greenwell et al. (2018)](https://arxiv.org/abs/1805.04755).
#'
#' @details This approach is based on quantifying the relative "flatness" of the
#' effect of each feature and assumes the user has some familiarity with the
#' [pdp::partial()] function. Feature effects can be assessed
#' using *partial dependence* (PD) plots (Friedman, 2001) or
#' *individual conditional expectation* (ICE) plots (Goldstein et al., 2014).
#' These methods are model-agnostic and can be applied to any supervised
#' learning algorithm. By default, relative "flatness" is defined by computing
#' the standard deviation of the y-axis values for each feature effect plot for
#' numeric features; for categorical features, the default is to use range
#' divided by 4. This can be changed via the `var_continuous` and
#' `var_categorical` arguments. See
#' [Greenwell et al. (2018)](https://arxiv.org/abs/1805.04755) for details and
#' additional examples.
#'
#' @note This approach can provide misleading results in the presence of
#' interaction effects (akin to interpreting main effect coefficients in a
#' linear with higher level interaction effects).
#'
#' @references
#' J. H. Friedman. Greedy function approximation: A gradient boosting machine.
#' *Annals of Statistics*, **29**: 1189-1232, 2001.
#'
#' Goldstein, A., Kapelner, A., Bleich, J., and Pitkin, E., Peeking Inside the
#' Black Box: Visualizing Statistical Learning With Plots of Individual
#' Conditional Expectation. (2014) *Journal of Computational and Graphical
#' Statistics*, **24**(1): 44-65, 2015.
#'
#' Greenwell, B. M., Boehmke, B. C., and McCarthy, A. J. A Simple
#' and Effective Model-Based Variable Importance Measure. arXiv preprint
#' arXiv:1805.04755 (2018).
#'
#' Scholbeck, C. A. Scholbeck, and Molnar, C.,  and Heumann C., and Bischl, B.,
#' and Casalicchio, G. Sampling, Intervention, Prediction, Aggregation: A
#' Generalized Framework for Model-Agnostic Interpretations. arXiv preprint
#' arXiv:1904.03959 (2019).
#'
#'
#' @rdname vi_firm
#'
#' @export
#'
#' @examples
#' \dontrun{
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
#' # Compute variable importance scores using the FIRM method; note that the pdp
#' # package knows how to work with a "ppr" object, so there's no need to pass
#' # the training data or a prediction wrapper, but it's good practice.
#' vi_firm(mtcars.ppr, train = mtcars)
#'
#' # For unsupported models, need to define a prediction wrapper; this approach
#' # will work for ANY model (supported or unsupported, so better to just always
#' # define it pass it)
#' pfun <- function(object, newdata) {
#'   # To use partial dependence, this function needs to return the AVERAGE
#'   # prediction (for ICE, simply omit the averaging step)
#'   mean(predict(object, newdata = newdata))
#' }
#'
#' # Equivalent to the previous results (but would work if this type of model
#' # was not explicitly supported)
#' vi_firm(mtcars.ppr, pred.fun = pfun, train = mtcars)
#'
#' # Equivalent VI scores, but the output is sorted by default
#' vi(mtcars.ppr, method = "firm")
#'
#' # Use MAD to estimate variability of the partial dependence values
#' vi_firm(mtcars.ppr, var_continuous = stats::mad)
#'
#' # Plot VI scores
#' vip(mtcars.ppr, method = "firm", train = mtcars, pred.fun = pfun)
#' }
vi_firm <- function(object, ...) {
  UseMethod("vi_firm")
}


#' @rdname vi_firm
#'
#' @export
vi_firm.default <- function(
    object,
    feature_names = NULL,
    train = NULL,
    var_fun = NULL,
    var_continuous = stats::sd,
    var_categorical = function(x) diff(range(x)) / 4,
    ...
) {

  # Check for pdp package
  if (!requireNamespace("pdp", quietly = TRUE)) {
    stop("Package \"pdp\" needed for this function to work. ",
         "Please install it.", call. = FALSE)
  }

  # Catch deprecated arguments
  if (!is.null(var_fun)) {
    stop("Argument `var_fun` is deprecated; please use the `var_continuous` ",
         "and `var_categorical` arguments instead.",
         call. = FALSE)
  }

  # Try to extract feature names from `object`
  if (is.null(feature_names)) {
    feature_names <- get_feature_names(object)
  }

  # Try to extract training data if not supplied
  if (is.null(train)) {
    train <- get_training_data(object)
  }

  # Construct PD/ICE-based variable importance scores
  vis <- lapply(feature_names, function(x) {
    firm(object, feature_name = x, var_continuous = var_continuous,
         var_categorical = var_categorical, train = train, ...)
  })
  tib <- new_vi(feature_names, importance = unlist(vis), type = "firm")

  # Include the estimated feature effects as an additional attribute
  fe <- lapply(vis, FUN = function(x) attr(x, which = "effects"))
  names(fe) <- feature_names
  attr(tib, which = "effects") <- fe

  # Return results
  tib

}


#' Feature importance ranking measure
#'
#' Compute variable importance using a variance-based measure referred to as the
#' \emph{feature importance ranking measure} (FIRM).
#'
#' @keywords internal
#'
#' @noRd
firm <- function(object, feature_name, var_continuous, var_categorical, ...) {

  # Only allow for a single feature
  if (length(feature_name) != 1L) {
    stop("Only a single feature allowed in `firm()`.", call. = FALSE)
  }

  # Compute feature effect
  fe <- pdp::partial(object, pred.var = feature_name, ...)

  # Compute partial dependence-based variable importance scores
  var_fun <- if (is.factor(fe[[feature_name]])) {
    var_categorical  # categorical feature
  } else {
    var_continuous  # continuous feature
  }

  # Compute FIRM
  res <- if ("yhat.id" %in% names(fe)) {  # ICE
    mean(tapply(fe$yhat, INDEX = fe[["yhat.id"]], FUN = var_fun))
  } else {  # PD
    var_fun(fe$yhat)
  }

  # Include estimated feature effects as an additional attribute
  attr(res, which = "effects") <- fe

  # Return result
  res

}
