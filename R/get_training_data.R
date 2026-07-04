# Error message to display when training data cannot be extracted form object
msg <- paste0(
  "The training data could not be extracted from object. You can supply the ",
  "training data using the `train` argument."
)


#' @keywords internal
get_training_data <- function(object) {
  UseMethod("get_training_data")
}


#' @keywords internal
get_training_data.default <- function(object) {
  stop("Training data cannot be extracted from fitted model object. Please ",
       "supply the raw training data using the `train` argument.",
       call. = FALSE)
}


# Package: caret ---------------------------------------------------------------

#' @keywords internal
get_training_data.train <- function(object) {
  # By default, "train" object have a copy of the training data stored in
  # a component called "trainingData". Note that the returned data frame only
  # includes the feature columns
  train <- object$trainingData
  if (is.null(train)) {
    stop(msg, call. = FALSE)
  }
  train$.outcome <- NULL  # remove .outcome column
  train
}


# Package: h2o -----------------------------------------------------------------

#' @keywords internal
get_training_data.H2OBinomialModel <- function(object) {
  as.data.frame(h2o::h2o.getFrame(object@allparameters$training_frame))
}


#' @keywords internal
get_training_data.H2OMultinomialModel <- function(object) {
  as.data.frame(h2o::h2o.getFrame(object@allparameters$training_frame))
}


#' @keywords internal
get_training_data.H2ORegressionModel <- function(object) {
  as.data.frame(h2o::h2o.getFrame(object@allparameters$training_frame))
}


# Package: party ---------------------------------------------------------------

#' @keywords internal
get_training_data.BinaryTree <- function(object) {
  # WARNING: Returns feature columns only in a data frame with some additional
  # attributes
  object@data@get("input")
}


#' @keywords internal
get_training_data.RandomForest <- function(object) {
  # WARNING: Returns feature columns only in a data frame with some additional
  # attributes
  object@data@get("input")
}


# Package: workflow ------------------------------------------------------------

#' @keywords internal
get_training_data.workflow <- function(object) {
  stop("Training data cannot be extracted from workflow objects. Please ",
       "supply the raw training data using the `train` argument.",
       call. = FALSE)
}
