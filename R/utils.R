#' Construct a "vi" object
#'
#' Internal constructor for the tibble of variable importance scores returned
#' by all of the `vi_*()` functions; ensures a consistent structure (column
#' names, `"type"` attribute, and `"vi"` class).
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
  tib <- if (is.null(sign)) {
    tibble::tibble(
      "Variable" = variable,
      "Importance" = importance
    )
  } else {
    tibble::tibble(
      "Variable" = variable,
      "Importance" = importance,
      "Sign" = sign
    )
  }
  attr(tib, which = "type") <- type
  class(tib) <- c("vi", class(tib))
  tib
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
  x[order(x$Importance, decreasing = decreasing), ]
}
