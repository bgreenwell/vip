#' Permutation-based variable importance
#'
#' Compute permutation-based variable importance scores for the predictors in a
#' model; for details on the algorithm, see Greenwell and Boehmke (2020).
#'
#' @param object A fitted model object (e.g., a
#' [randomForest][randomForest::randomForest()] object).
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
#' @param target Either a character string giving the name (or position) of the
#' target column in `train` or, if `train` only contains feature
#' columns, a vector containing the target values used to train `object`.
#'
#' @param metric Either a function or character string specifying the
#' performance metric to use in computing model performance (e.g., RMSE for
#' regression or accuracy for binary classification). If `metric` is a
#' function, then it requires two arguments, `actual` and `predicted`,
#' and should return a single, numeric value. Ideally, this should be the same
#' metric that was used to train `object`. See [list_metrics()] for a list of
#' built-in metrics.
#'
#' @param smaller_is_better Logical indicating whether or not a smaller value
#' of `metric` is better. Default is `NULL`. Must be supplied if
#' `metric` is a user-supplied function.
#'
#' @param type Character string specifying how to compare the baseline and
#' permuted performance metrics. Current options are `"difference"` (the
#' default) and `"ratio"`.
#'
#' @param nsim Integer specifying the number of Monte Carlo replications to
#' perform. Default is 1. If `nsim > 1`, the results from each replication
#' are simply averaged together (the standard deviation will also be returned).
#'
#' @param keep Logical indicating whether or not to keep the individual
#' permutation scores for all `nsim` repetitions. If `TRUE` (the
#' default) then the individual variable importance scores will be stored in an
#' attribute called `"raw_scores"`. (Only used when `nsim > 1`.)
#'
#' @param sample_size Integer specifying the size of the random sample to use
#' for each Monte Carlo repetition. Default is `NULL` (i.e., use all of the
#' available training data). Cannot be specified with `sample_frac`. Can be
#' used to reduce computation time with large data sets.
#'
#' @param sample_frac Proportion specifying the size of the random sample to use
#' for each Monte Carlo repetition. Default is `NULL` (i.e., use all of the
#' available training data). Cannot be specified with `sample_size`. Can be
#' used to reduce computation time with large data sets.
#'
#' @param reference_class Deprecated, use `event_level` instead.
#'
#' @param event_level String specifying which factor level of `truth` to
#' consider as the "event". Options are `"first"` (the default) or `"second"`.
#' This argument is only applicable for binary classification when `metric` is
#' one of `"roc_auc"`, `"pr_auc"`, or `"youden"`. This argument is passed on to
#' the corresponding [yardstick][yardstick::yardstick] metric.
#'
#' @param pred_wrapper Prediction function that requires two arguments,
#' `object` and `newdata`. The output of this function should be
#' determined by the `metric` being used:
#'
#' * Regression - A numeric vector of predicted outcomes.
#' * Binary classification - A vector of predicted class labels (e.g., if using
#' misclassification error) or a vector of predicted class probabilities for the
#' reference class (e.g., if using log loss or AUC).
#' * Multiclass classification - A vector of predicted class labels (e.g., if
#' using misclassification error) or a A matrix/data frame of predicted class
#' probabilities for each class (e.g., if using log loss or AUC).
#'
#' @param verbose Logical indicating whether or not to print information during
#' the construction of variable importance scores. Default is `FALSE`.
#'
#' @param parallel Logical indicating whether or not to run `vi_permute()`
#' in parallel (using a backend provided by the [foreach][foreach::foreach]
#' package). Default is `FALSE`. If `TRUE`, a
#' [foreach][foreach::foreach]-compatible backend must be provided by must be
#' provided. Note that `set.seed()` will not not work with
#' [foreach][foreach::foreach]'s parellelized for loops; for a workaround, see
#' [this solution](https://github.com/koalaverse/vip/issues/145).
#'
#' @param parallelize_by Character string specifying whether to parallelize
#' across features (`parallelize_by = "features"`) or repetitions
#' (`parallelize_by = "repetitions"`); the latter is only useful whenever
#' `nsim > 1`. Default is `"features"`.
#'
#' @param ... Additional optional arguments to be passed on to
#' [foreach][foreach::foreach] (e.g., `.packages` or `.export`).
#'
#' @return A tidy data frame (i.e., a [tibble][tibble::tibble] object) with two
#' columns:
#'
#' * `Variable` - the corresponding feature name;
#' * `Importance` - the associated importance, computed as the average change in
#' performance after a random permutation (or permutations, if `nsim > 1`) of
#' the feature in question.
#'
#' If `nsim > 1`, then an additional column (`StDev`) containing the standard
#' deviation of the individual permutation scores for each feature is also
#' returned; this helps assess the stability/variation of the individual
#' permutation importance for each feature.
#'
#' @importFrom foreach foreach %do% %dopar%
#'
#' @references
#' Brandon M. Greenwell and Bradley C. Boehmke, The R Journal (2020) 12:1,
#' pages 343-366.
#'
#' @rdname vi_permute
#'
#' @export
#'
#' @examples
#' \dontrun{
#' #
#' # Regression example
#' #
#'
#' library(ranger)   # for fitting random forests
#'
#' # Simulate data from Friedman 1 benchmark; only x1-x5 are important!
#' trn <- gen_friedman(500, seed = 101)  # ?vip::gen_friedman
#'
#' # Prediction wrapper
#' pfun <- function(object, newdata) {
#'   # Needs to return vector of predictions from a ranger object; see
#'   # `ranger::predcit.ranger` for details on making predictions
#'   predict(object, data = newdata)$predictions
#' }
#'
#' # Fit a (default) random forest
#' set.seed(0803) # for reproducibility
#' rfo <- ranger(y ~ ., data = trn)
#'
#' # Compute permutation-based VI scores
#' set.seed(2021)  # for reproducibility
#' vis <- vi(rfo, method = "permute", target = "y", metric = "rsq",
#'           pred_wrapper = pfun, train = trn)
#' print(vis)
#'
#' # Same as above, but using `vi_permute()` directly
#' set.seed(2021)  # for reproducibility
#' vi_permute(rfo, target = "y", metric = "rsq", pred_wrapper = pfun
#'            train = trn)
#'
#' # Plot VI scores (could also replace `vi()` with `vip()` in above example)
#' vip(vis, include_type = TRUE)
#'
#' # Mean absolute error
#' mae <- function(truth, estimate) {
#'   mean(abs(truth - estimate))
#' }
#'
#' # Permutation-based VIP with user-defined MAE metric
#' set.seed(1101)  # for reproducibility
#' vi_permute(rfo, target = "y", metric = mae, smaller_is_better = TRUE,
#'            pred_wrapper = pfun, train = trn)
#'
#' # Same as above, but using `yardstick` package instead of user-defined metric
#' set.seed(1101)  # for reproducibility
#' vi_permute(rfo, target = "y", metric = yardstick::mae_vec,
#'            smaller_is_better = TRUE, pred_wrapper = pfun, train = trn)
#'
#' #
#' # Classification (binary) example
#' #
#'
#' library(randomForest)  # another package for fitting random forests
#'
#' # Complete (i.e., imputed version of titanic data); see `?vip::titanic_mice`
#' head(t1 <- titanic_mice[[1L]])
#' t1$pclass <- as.ordered(t1$pclass)  # makes more sense as an ordered factor
#'
#' # Fit another (default) random forest
#' set.seed(2053)  # for reproducibility
#' (rfo2 <- randomForest(survived ~ ., data = t1))
#'
#' # Define prediction wrapper for predicting class labels from a
#' # "randomForest" object
#' pfun_class <- function(object, newdata) {
#'   # Needs to return factor of classifications
#'   predict(object, newdata = newdata, type = "response")
#' }
#'
#' # Sanity check
#' pfun_class(rfo2, newdata = head(t1))
#' ##   1   2   3   4   5   6
#' ## yes yes yes  no yes  no
#' ## Levels: no yes
#'
#' # Compute mean decrease in accuracy
#' set.seed(1359)  # for reproducibility
#' vi(rfo2,
#'    method = "permute",
#'    train = t1,
#'    target = "survived",
#'    metric = "accuracy",  # or pass in `yardstick::accuracy_vec` directly
#'    # smaller_is_better = FALSE,  # no need to set for built-in metrics
#'    pred_wrapper = pfun_class,
#'    nsim = 30  # use 30 repetitions
#' )
#' ## # A tibble: 5 × 3
#' ##   Variable Importance   StDev
#' ##   <chr>         <dbl>   <dbl>
#' ## 1 sex          0.228  0.0110
#' ## 2 pclass       0.0825 0.00505
#' ## 3 age          0.0721 0.00557
#' ## 4 sibsp        0.0346 0.00430
#' ## 5 parch        0.0183 0.00236
#'
#' # Define prediction wrapper for predicting class probabilities from a
#' # "randomForest" object
#' pfun_prob <- function(object, newdata) {
#'   # Needs to return vector of class probabilities for event level of interest
#'   predict(object, newdata = newdata, type = "prob")[, "yes"]
#' }
#'
#' # Sanity check
#' pfun_prob(rfo2, newdata = head(t1))  # estiated P(survived=yes | x)
#' ##     1     2     3     4     5     6
#' ## 0.990 0.864 0.486 0.282 0.630 0.078
#'
#' # Compute mean increase in Brier score
#' set.seed(1411)  # for reproducibility
#' vi(rfo2,
#'    method = "permute",
#'    train = t1,
#'    target = "survived",
#'    metric = yardstick::brier_class_vec,  # or pass in `"brier"` directly
#'    smaller_is_better = FALSE,  # need to set when supplying a function
#'    pred_wrapper = pfun_prob,
#'    nsim = 30  # use 30 repetitions
#' )
#'
#' ## # A tibble: 5 × 3
#' ## Variable Importance   StDev
#' ##   <chr>         <dbl>   <dbl>
#' ## 1 sex          0.210  0.00869
#' ## 2 pclass       0.0992 0.00462
#' ## 3 age          0.0970 0.00469
#' ## 4 parch        0.0547 0.00273
#' ## 5 sibsp        0.0422 0.00200
#'
#' # Some metrics, like AUROC, treat one class as the "event" of interest. In
#' # such cases, it's important to make sure the event level (which typically
#' # defaults to which ever event class comes first in alphabetical order)
#' # matches the event class that corresponds to the prediction wrappers
#' # returned probabilities. To do this, you can (and should) set the
#' # `event_class` argument. For instance, our prediction wrapper specified
#' # `survived = "yes"` as the event of interest, but this is considered the
#' # second event:
#' levels(t1$survived)
#' ## [1] "no"  "yes"
#'
#' # So, we need to specify the second class as the event of interest via the
#' # `event_level` argument (otherwise, we would get the negative of the results
#' # we were hoping for; a telltale sign the event level and prediction wrapper
#' do not match)
#' set.seed(1413)  # for reproducibility
#' vi(rfo,
#'    method = "permute",
#'    train = t1,
#'    target = "survived",
#'    metric = "roc_auc",
#'    event_level = "second",  # use "yes" as class label/"event" of interest
#'    pred_wrapper = pfun_prob,
#'    nsim = 30  # use 30 repetitions
#' )
#'
#' ## # A tibble: 5 × 3
#' ## Variable Importance   StDev
#' ##   <chr>         <dbl>   <dbl>
#' ## 1 sex          0.229  0.0137
#' ## 2 pclass       0.0920 0.00533
#' ## 3 age          0.0850 0.00477
#' ## 4 sibsp        0.0283 0.00211
#' ## 5 parch        0.0251 0.00351
#' }
vi_permute <- function(object, ...) {
  UseMethod("vi_permute")
}


#' @rdname vi_permute
#'
#' @export
vi_permute.default <- function(
  object,
  feature_names = NULL,
  train = NULL,
  target = NULL,
  metric = NULL,
  smaller_is_better = NULL,
  type = c("difference", "ratio"),
  nsim = 1,
  keep = TRUE,
  sample_size = NULL,
  sample_frac = NULL,
  reference_class = NULL,  # deprecated
  event_level = NULL,
  pred_wrapper = NULL,  # FIXME: Why give this a default?
  verbose = FALSE,
  parallel = FALSE,
  parallelize_by = c("features", "repetitions"),
  ...
) {

  # # Check for yardstick package
  # if (!requireNamespace("yardstick", quietly = TRUE)) {
  #   stop("Package \"yardstick\" needed for this function to work. ",
  #        "Please install it.", call. = FALSE)
  # }

  # FIXME: Is there a better way to fix this?
  #
  # ❯ checking R code for possible problems ... NOTE
  # vi_permute.default: no visible binding for global variable ‘j’
  # Undefined global functions or variables:
  #   j
  i <- j <- NULL


  # Try to extract training data if not supplied
  if (is.null(train)) {
    train <- get_training_data(object)
  }

  # Throw informative error messages if required arguments are missing
  if (is.null(target)) {
    stop("Could not find target. Please specify a target variable via the ",
         "`target` argument; see `?vip::vi_permute` for details.",
         call. = FALSE)
  }
  if (is.null(metric)) {
    stop("Could not find metric. Please specify a valid metric via the ",
         "`metric` argument; see `?vip::vi_permute` for details.",
         call. = FALSE)
  }
  if (is.null(pred_wrapper)) {
    stop("Could not find prediction wrapper. Please specify a valid prediction ",
         "function via the `pred_wrapper` argument; see `?vip::vi_permute` ",
         "for details.", call. = FALSE)
  }

  # Extract feature names and separate features from target (if necessary)
  if (is.character(target)) {
    if (is.null(feature_names)) {
      feature_names <- setdiff(colnames(train), target)
    }
    train_x <- train[, feature_names]
    train_y <- train[, target, drop = TRUE]
  } else {
    if (is.null(feature_names)) {
      feature_names <- colnames(train)
    }
    train_x <- train
    train_y <- target
  }

  # Sample the data?
  if (!is.null(sample_size) && !is.null(sample_frac)) {
    stop("Arguments `sample_size` and `sample_frac` cannot both be specified.")
  }
  if (!is.null(sample_size)) {
    if (sample_size <= 0 || sample_size > nrow(train)) {
      stop("Argument `sample_size` must be in (0, ", nrow(train), "].")
    }
  }
  if (!is.null(sample_frac)) {
    if (sample_frac <= 0 || sample_frac > 1) {
      stop("Argument `sample_frac` must be in (0, 1].")
    }
    sample_size <- round(nrow(train) * sample_frac, digits = 0)
  }

  # Metric
  if (is.function(metric)) {  # user-supplied function

    # If `metric` is a user-supplied function, then `smaller_is_better` cannot
    # be `NULL`.
    if (is.null(smaller_is_better) || !is.logical(smaller_is_better)) {
      stop("Please specify a logical value for `smaller_is_better`.",
           call. = FALSE)
    }

    # Check prediction function arguments
    if (!all(c("object", "newdata") %in% names(formals(pred_wrapper)))) {
      stop("`pred_wrapper()` must be a function with arguments `object` and ",
           "`newdata`.", call. = FALSE)
    }

    # Check metric function arguments
    if (!all(c("truth", "estimate") %in% names(formals(metric)))) {
      stop("`metric()` must be a function with arguments `truth` and ",
           "`estimate`; consider using one of the vector metric functions ",
           "from the `yardstick` package (e.g., ",
           "`metric = yardstick::huber_loss_vec`).", call. = FALSE)
    }

    # # Check if reference class is provided
    # if (!is.null(reference_class)) {
    #   reference_class <- train_y[1L]
    # }
    # train_y <- ifelse(train_y == reference_class, yes = 1, no = 0)

    # Performance function
    metric_fun <- metric

  } else {

    # Get corresponding metric/performance function
    ys_metric <- get_metric(metric)
    # metric_fun <- ys_metric[["metric_fun"]]
    smaller_is_better <- ys_metric[["smaller_is_better"]]

    # Get metric function and update `event_level` arg if needed
    metric_fun <- if (!is.null(event_level)) {
      metric_fun <- function(truth, estimate) {
        fun <- ys_metric[["metric_fun"]]
        fun(truth, estimate = estimate, event_level = event_level)
      }
    } else {
      if (metric %in% c("roc_auc", "pr_auc", "youden")) {
        warning("Consider setting the `event_level` argument when using ",
                deparse(substitute(metric)), " as the metric; see ",
                "`?vip::vi_permute` for details. Defaulting to ",
                "`event_level = \"first\"`.", call. = FALSE)
      }
      ys_metric[["metric_fun"]]
    }

  }

  # Compute baseline metric for comparison
  baseline <- metric_fun(
    truth = train_y,
    estimate = pred_wrapper(object, newdata = train_x)
  )

  # Type of comparison
  type <- match.arg(type)
  `%compare%` <- if (type == "difference") {
    `-`
  } else {
    `/`
  }

  # Define ".do" operator
  `%do.reps%` <- `%do.features%` <- `%do%`
  if (isTRUE(parallel)) {
    parallelize_by <- match.arg(parallelize_by)
    if (parallelize_by == "repetitions") {
      if (nsim == 1) {
        warning("Parallelizing across repititions only works when `nsim > 1`.",
                call. = FALSE)
      } else{
        `%do.reps%` <- `%dopar%`
      }
    } else {
      `%do.features%` <- `%dopar%`
    }
  }

  # Construct VI scores
  #
  # Loop through each feature and do the following:
  #
  #   1. make a copy of the training data;
  #   2. permute the values of the original feature;
  #   3. get new predictions based on permuted data set;
  #   4. record difference in accuracy.

  vis <- foreach(i = seq_len(nsim), .combine = "cbind") %do.reps% {
    res <- foreach(j = seq_along(feature_names),
                   .combine = "rbind", ...) %do.features% {
      # if (verbose && !parallel) {
      #   message("Computing variable importance for ", x, "...")
      # }
      if (!is.null(sample_size)) {
        ids <- sample(length(train_y), size = sample_size, replace = FALSE)
        train_x <- train_x[ids, ]
        train_y <- train_y[ids]
      }
      permx <- train_x
      permx[, feature_names[j]] <- permx[sample(nrow(permx)), feature_names[j]]
      # train_x_permuted <- permute_columns(train_x, columns = feature_names[j])
      permuted <- metric_fun(
        truth = train_y,
        estimate = pred_wrapper(object, newdata = permx)
      )
      if (smaller_is_better) {
        permuted %compare% baseline  # e.g., RMSE
      } else {
        baseline %compare% permuted  # e.g., R-squared
      }
    }
  }

  # Construct tibble of variable importance scores
  tib <- tibble::tibble(
    "Variable" = feature_names,
    "Importance" = apply(vis, MARGIN = 1, FUN = mean)
  )
  if (nsim > 1) {
    tib$StDev <- apply(vis, MARGIN = 1, FUN = stats::sd)
  }

  # Add all nsim scores as an attribute
  if (nsim > 1 && keep) {
    rownames(vis) <- feature_names
    colnames(vis) <- paste0("permutation_", seq_len(ncol(vis)))
    attr(tib, which = "raw_scores") <- vis
  }

  # Add variable importance type attribute
  attr(tib, which = "type") <- "permutation"

  # Add "vi" class
  class(tib) <- c("vi", class(tib))

  # Return results
  tib

}
