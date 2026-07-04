#' Construct a "vi" object
#'
#' Internal constructor for the data frame of variable importance scores
#' returned by all of the `vi_*()` functions; ensures a consistent structure
#' (column names, `"type"` attribute, and `"vi"` class). Note that base R's
#' `[.data.frame` and `na.omit()` preserve both the class and the custom
#' attributes of `"vi"` objects, which the `vi()` and `plot.vi()` pipelines
#' rely on.
#'
#' @param variable Character vector of feature names.
#'
#' @param importance Numeric vector of variable importance scores.
#'
#' @param type Character string describing the type of variable importance;
#' stored in the `"type"` attribute (e.g., for use in axis labels).
#'
#' @param sign Optional character vector giving the sign (i.e., `"POS"` or
#' `"NEG"`) of each (linear model-like) coefficient.
#'
#' @keywords internal
#' @noRd
new_vi <- function(variable, importance, type, sign = NULL) {
  # Strip any names/dimnames carried by the inputs (e.g., from named vectors
  # or matrix columns) so the resulting columns are always plain vectors
  tib <- if (is.null(sign)) {
    data.frame(
      "Variable" = unname(variable),
      "Importance" = unname(importance),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(
      "Variable" = unname(variable),
      "Importance" = unname(importance),
      "Sign" = unname(sign),
      stringsAsFactors = FALSE
    )
  }
  attr(tib, which = "type") <- type
  class(tib) <- c("vi", class(tib))
  tib
}


#' Sign of a coefficient/statistic
#'
#' Returns `"POS"`, `"NEG"`, or `"ZERO"`; exactly-zero coefficients (common
#' with lasso models) should not be labelled positive or negative (#104).
#'
#' @keywords internal
#' @noRd
coef_sign <- function(x) {
  ifelse(x > 0, yes = "POS", no = ifelse(x < 0, yes = "NEG", no = "ZERO"))
}


#' @keywords internal
abbreviate_names <- function(x, minlength) {
  x$Variable <- abbreviate(x$Variable, minlength = minlength)
  x
}


#' @keywords internal
check_var_fun <- function(x) {
  # x should be a named list of two functions with names "con" and "cat"
  if (!is.list(x)) {
    stop("Argument `var_fun` should be a list.", call. = FALSE)
  }
  if (length(x) != 2L) {
    stop("FUN should be a list of length 2.", call. = FALSE)
  }
  if (!identical(sort(names(x)), c("cat", "con"))) {
    stop("Argument `var_fun` should be a list with components \"con\" and \"cat\".",
         call. = FALSE)
  }
  if (!all(vapply(x, is.function, logical(1L)))) {
    stop("Argument `var_fun` should be a list of two functions.", call. = FALSE)
  }
}


#' @keywords internal
sort_importance_scores <- function(x, decreasing) {
  x <- x[order(x$Importance, decreasing = decreasing), ]
  rownames(x) <- NULL  # don't display shuffled row numbers
  x
}
