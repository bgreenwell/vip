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


#' Skip tests on CRAN
#'
#' Internal helper for test files. Skips test execution on CRAN while allowing
#' tests to run locally and in CI/CD where NOT_CRAN=true is set.
#'
#' Set NOT_CRAN=true in your environment or CI/CD to run these tests.
#'
#' @keywords internal
skip_on_cran <- function() {
  # Check if NOT_CRAN environment variable is set to "true"
  # This should be set locally and in GitHub Actions, but not on CRAN
  not_cran <- identical(tolower(Sys.getenv("NOT_CRAN")), "true")

  if (!not_cran) {
    tinytest::exit_file("Skip on CRAN (set NOT_CRAN=true to run locally/CI)")
  }
}
