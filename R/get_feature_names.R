#' Extract model formula
#'
#' Calls [formula][stats::formula] to extract the formulae from various
#' modeling objects, but returns `NULL` instead of an error for objects
#' that do not contain a formula component.
#'
#' @param object An appropriate fitted model object.
#'
#' @return Either a \code{\link[stats]{formula}} object or `NULL`.
#'
#' @keywords internal
#' @noRd
get_formula <- function(object) {
  UseMethod("get_formula")
}


#' @keywords internal
get_formula.default <- function(object) {
  tryCatch(
    expr = stats::formula(object),
    error = function(e) {
      NULL
    }
  )
}


#' @keywords internal
get_formula.constparty <- function(object) {
  get_formula.default(attr(stats::terms(object), which = "Formula_without_dot"))
}


#' Extract feature names
#'
#' Extract predictor names from a fitted model.
#'
#' @param object An appropriate fitted model object.
#'
#' @param ... Additional optional arguments.
#'
#' @keywords internal
get_feature_names <- function(object, ...) {
  UseMethod("get_feature_names")
}


#' @keywords internal
get_feature_names.default <- function(object, ...) {
  stop("Could not extract feature names from ", deparse(substitute(object)),
       ", please supply them via the `feature_names` argument.", call. = FALSE)
}


#' @keywords internal
get_feature_names.formula <- function(object, ...) {
  tryCatch(  # FIXME: IS the RHS always located in the third component?
    expr = all.vars(object[[3L]]),  # extract unique vars from RHS side of formula
    error = function(e) {  # in case formula doesn't have both a LHS and RHS, etc.
      get_feature_names.default(object)
    }
  )
}


# Package: C50 ----------------------------------------------------------------

#' @keywords internal
get_feature_names.C5.0 <- function(object, ...) {
  object$predictors
}


# Package: caret ---------------------------------------------------------------

#' @keywords internal
get_feature_names.train <- function(object, ...) {
  if (!is.null(object$trainingData)) {
    xn <- names(object$trainingData)
    xn[xn != ".outcome"]
  } else {
    get_feature_names.default(object)
  }
}


# Package: Cubist --------------------------------------------------------------

#' @keywords internal
get_feature_names.cubist <- function(object, ...) {
  object$vars$all
}


# Package: earth ----------------------------------------------------------------

#' @keywords internal
get_feature_names.earth <- function(object, ...) {
  object$namesx
}


# Package: gbm -----------------------------------------------------------------

#' @keywords internal
get_feature_names.gbm <- function(object, ...) {
  object$var.names
}


# Package: glmnet --------------------------------------------------------------

#' @keywords internal
get_feature_names.cv.glmnet <- function(object, ...) {
  object$glmnet.fit$beta@Dimnames[[1]]
}


#' @keywords internal
get_feature_names.glmnet <- function(object, ...) {
  object$beta@Dimnames[[1]]
}


#' @keywords internal
get_feature_names.multnet <- function(object, ...) {
  object$beta[[1L]]@Dimnames[[1L]]
}


# Package: h2o -----------------------------------------------------------------

#' @keywords internal
get_feature_names.H2OBinomialModel <- function(object, ...) {
  object@parameters$x
}


#' @keywords internal
get_feature_names.H2OMultinomialModel <- function(object, ...) {
  object@parameters$x
}


#' @keywords internal
get_feature_names.H2ORegressionModel <- function(object, ...) {
  object@parameters$x
}


# Package: mlr -----------------------------------------------------------------

#' @keywords internal
get_feature_names.WrappedModel <- function(object, ...) {
  object$features
}


# Package: mlr3 ----------------------------------------------------------------

#' @keywords internal
get_feature_names.Learner <- function(object, ...) {
  if (is.null(object$model)) {
    stop("No fitted model found. Did you forget to call ",
         deparse(substitute(object)), "$train()?",
         call. = FALSE)
  }
  get_feature_names(object$model, ...)
}


# Package: neuralnet -----------------------------------------------------------

#' @keywords internal
get_feature_names.nn <- function(object, ...) {
  # get_feature_names(get_formula(object))
  object$model.list$variables
}


# Package: nnet ----------------------------------------------------------------

#' @keywords internal
get_feature_names.nnet <- function(object, ...) {
  get_feature_names(get_formula(object))
}


# Package: pls -----------------------------------------------------------------

#' @keywords internal
get_feature_names.mvr <- function(object, ...) {
  get_feature_names(get_formula(object))
}


# Package: stats ---------------------------------------------------------------

#' @keywords internal
get_feature_names.lm <- function(object, ...) {
  get_feature_names(get_formula(object))
}


#' @keywords internal
get_feature_names.nls <- function(object, ...) {
  # all.vars(stats::formula(object)[[3L]])  # returns all params
  names(object$dataClasses)
}


#' @keywords internal
get_feature_names.ppr <- function(object, ...) {
  object$xnames
}


# Package: party ---------------------------------------------------------------

#' @keywords internal
get_feature_names.BinaryTree <- function(object, ...) {
  all.vars(object@data@formula$input)
}

#' @keywords internal
get_feature_names.RandomForest <- function(object, ...) {
  all.vars(object@data@formula$input)
}


# Package: partykit ------------------------------------------------------------

#' @keywords internal
get_feature_names.constparty <- function(object, ...) {
  get_feature_names(get_formula(object))
}


#' @keywords internal
get_feature_names.cforest <- function(object, ...) {
  get_feature_names(get_formula(object))
}


# Package: randomForest --------------------------------------------------------

#' @keywords internal
get_feature_names.randomForest <- function(object, ...) {
  rownames(object$importance)
}


# Package: ranger --------------------------------------------------------------

#' @keywords internal
get_feature_names.ranger <- function(object, ...) {
  if (!is.null(object$forest$independent.variable.names)) {
    object$forest$independent.variable.names
  } else if (!is.null(names(object$variable.importance))) {
    names(object$variable.importance)
  } else {
    stop("Unable to recover feature names from ranger models with `importance",
         " = \"none\"` and `write.forest = FALSE`.")
  }
}


# Package: rpart ---------------------------------------------------------------

#' @keywords internal
get_feature_names.rpart <- function(object, ...) {
  # names(object$variable.importance)
  get_feature_names(get_formula(object))
}


# Package: xgboost -------------------------------------------------------------

#' @keywords internal
get_feature_names.xgb.Booster <- function(object, ...) {
  feature_names <- xgboost::getinfo(object, name = "feature_name")
  if (is.null(feature_names)) {
    get_feature_names.default(object)
  } else {
    feature_names
  }
}
