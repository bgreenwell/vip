#' Metric table
#'
#' Single source of truth for the built-in performance metrics; used by both
#' `list_metrics()` and `get_metric()`.
#'
#' @keywords internal
#' @noRd
metric_table <- function() {
  data.frame(
    metric = c(
      # Classification
      "accuracy", "bal_accuracy", "youden", "roc_auc", "pr_auc", "logloss",
      "brier",
      # Regression
      "mae", "mape", "rmse", "rsq", "rsq_trad"
    ),
    description = c(
      "Classification accuracy",
      "Balanced classification accuracy",
      "Youden's index (or Youden's J statistic)",
      "Area under ROC curve",
      "Area under precision-recall (PR) curve",
      "Log loss",
      "Brier score",
      "Mean absolute error",
      "Mean absolute percentage error",
      "Root mean squared error",
      "R-squared (correlation)",
      "R-squared (traditional)"
    ),
    task = c(
      "Binary/multiclass classification",
      "Binary/multiclass classification",
      "Binary/multiclass classification",
      "Binary classification",
      "Binary classification",
      "Binary/multiclass classification",
      "Binary/multiclass classification",
      "Regression",
      "Regression",
      "Regression",
      "Regression",
      "Regression"
    ),
    smaller_is_better = c(
      FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE,
      TRUE, TRUE, TRUE, FALSE, FALSE
    ),
    yardstick_function = c(
      "accuracy_vec", "bal_accuracy_vec", "j_index_vec", "roc_auc_vec",
      "pr_auc_vec", "mn_log_loss_vec", "brier_class_vec",
      "mae_vec", "mape_vec", "rmse_vec", "rsq_vec", "rsq_trad_vec"
    ),
    stringsAsFactors = FALSE
  )
}


#' List metrics
#'
#' List all available performance metrics.
#'
#' @return A data frame with the following columns:
#' * `metric` - the optimization or tuning metric;
#' * `description` - a brief description about the metric;
#' * `task` - whether the metric is suitable for regression or classification;
#' * `smaller_is_better` - logical indicating whether or not a smaller value of
#' the metric is considered better.
#' * `yardstick_function` - the name of the corresponding vector function from
#' the [yardstick][yardstick::yardstick] package.
#'
#' @export
#'
#' @examples
#' (metrics <- list_metrics())
#' metrics[metrics$task == "Binary classification", ]
list_metrics <- function() {
  metric_table()
}


#' Get yardstick metric
#'
#' Grabs the corresponding function from yardstick based on provided string
#' description.
#'
#' @param metric String giving the name of the metric
#'
#' @return A list with two components:
#'
#' * `metric_fun` - the corresponding vector function from
#' [yardstick][yardstick::yardstick].
#' * `smaller_is_better` - a logical indicating whether or not a smaller value
#' of this metric is better.
#'
#' @keywords internal
#' @noRd
get_metric <- function(metric) {
  metric <- tolower(metric)  # just in case
  metrics <- metric_table()
  pos <- match(metric, table = metrics$metric)
  if (is.na(pos)) {
    stop("Metric \"", metric, "\" is not supported; use ",
         "`vip::list_metrics()` to print a list of currently supported ",
         "metrics. Alternatively, you can pass in a `yardstick` vector ",
         "function directly (e.g., `metric = yardstick::poisson_log_loss_vec`; ",
         "just be sure to also set the `smaller_is_better` argument).",
         call. = FALSE)
  }
  # Built-in metrics are provided by the yardstick package, which is only
  # required when a metric is specified by name (users can always supply their
  # own metric function instead)
  if (!requireNamespace("yardstick", quietly = TRUE)) {
    stop("Package \"yardstick\" needed to use built-in metrics (e.g., ",
         "`metric = \"", metric, "\"`). Please install it or supply a custom ",
         "metric function; see `?vip::vi_permute` for details.", call. = FALSE)
  }
  list(
    "metric_fun" = getExportedValue("yardstick",
                                    name = metrics$yardstick_function[pos]),
    "smaller_is_better" = metrics$smaller_is_better[pos]
  )
}
