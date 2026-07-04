#' Variable importance plots
#'
#' Plot variable importance scores for the predictors in a model using
#' lightweight base R graphics (via the
#' [tinyplot](https://grantmcdermott.com/tinyplot/) package).
#'
#' @param object A fitted model (e.g., of class
#' [randomForest][randomForest::randomForest] object) or a [vi][vip::vi] object.
#'
#' @param num_features Integer specifying the number of variable importance
#' scores to plot. Default is `10`.
#'
#' @param geom Character string specifying which type of plot to construct.
#' The currently available options are described below.
#'
#'  * `geom = "col"` constructs a bar chart of the variable importance scores.
#'
#'  * `geom = "point"` constructs a Cleveland dot plot of the variable
#'  importance scores.
#'
#'  * `geom = "boxplot"` constructs a boxplot of the raw permutation scores
#'  for each feature. This option can only be used for the permutation-based
#'  importance method with `nsim > 1` and `keep = TRUE`; see
#'  [vi_permute][vip::vi_permute] for details.
#'
#'  * `geom = "violin"` constructs a violin plot of the raw permutation scores
#'  for each feature. This option can only be used for the permutation-based
#'  importance method with `nsim > 1` and `keep = TRUE`; see
#'  [vi_permute][vip::vi_permute] for details.
#'
#' @param mapping Deprecated and ignored (with a warning); as of vip 0.5.0,
#' plots are drawn with [tinyplot][tinyplot::tinyplot] (base R graphics)
#' instead of ggplot2, so ggplot2 aesthetic mappings no longer apply. Use the
#' `aesthetics` argument to set fixed graphical parameters instead.
#'
#' @param aesthetics Named list of additional graphical parameters passed on
#' to [tinyplot][tinyplot::tinyplot] (e.g., `col`, `fill`, `pch`, `cex`, or
#' `lwd`), used to set an aesthetic to a fixed value, like
#' `aesthetics = list(fill = "forestgreen")`. See example usage below.
#'
#' @param horizontal Logical indicating whether or not to plot the importance
#' scores on the x-axis (`TRUE`). Default is `TRUE`.
#'
#' @param all_permutations Logical indicating whether or not to plot all
#' permutation scores along with the average. Default is `FALSE`. (Only used for
#' permutation scores when `nsim > 1`.)
#'
#' @param jitter Logical indicating whether or not to jitter the raw permutation
#' scores. Default is `FALSE`. (Only used when `all_permutations = TRUE`.)
#'
#' @param include_type Logical indicating whether or not to include the type of
#' variable importance computed in the axis label. Default is `FALSE`.
#'
#' @param ... Additional optional arguments to be passed on to [vi][vip::vi].
#'
#' @return Draws a plot as a side effect and invisibly returns the underlying
#' [vi][vip::vi] object (a tibble of variable importance scores).
#'
#' @rdname vip
#'
#' @export
#'
#' @examples
#' #
#' # A projection pursuit regression example using permutation-based importance
#' #
#'
#' # Load the sample data
#' data(mtcars)
#'
#' # Fit a projection pursuit regression model
#' model <- ppr(mpg ~ ., data = mtcars, nterms = 1)
#'
#' # Construct variable importance plot (permutation importance, in this case)
#' set.seed(825)  # for reproducibility
#' pfun <- function(object, newdata) predict(object, newdata = newdata)
#' vip(model, method = "permute", train = mtcars, target = "mpg", nsim = 10,
#'     metric = "rmse", pred_wrapper = pfun)
#'
#' # Better yet, store the variable importance scores and then plot
#' set.seed(825)  # for reproducibility
#' vis <- vi(model, method = "permute", train = mtcars, target = "mpg",
#'           nsim = 10, metric = "rmse", pred_wrapper = pfun)
#' vip(vis, geom = "point", horizontal = FALSE)
#' vip(vis, geom = "point", horizontal = FALSE,
#'     aesthetics = list(col = "forestgreen", cex = 2))
#'
#' # Plot unaggregated permutation scores (boxplot plus raw jittered scores)
#' vip(vis, geom = "boxplot", all_permutations = TRUE, jitter = TRUE,
#'     aesthetics = list(fill = "grey90"))
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
#' vip(tree2, method = "permute", nsim = 10, target = "Class",
#'     metric = "logloss", pred_wrapper = pfun)
#' }
vip <- function(object, ...) {
  UseMethod("vip")
}


#' @rdname vip
#'
#' @export
vip.default <- function(
  object,
  num_features = 10L,
  geom = c("col", "point", "boxplot", "violin"),
  mapping = NULL,
  aesthetics = list(),
  horizontal = TRUE,
  all_permutations = FALSE,
  jitter = FALSE,
  include_type = FALSE,
  ...
) {

  # Character string specifying which type of plot to construct
  geom <- match.arg(geom, several.ok = FALSE)

  # Catch deprecated ggplot2-specific arguments
  if (!is.null(mapping)) {
    warning("Argument `mapping` is deprecated and will be ignored; as of vip ",
            "0.5.0, plots are drawn with tinyplot (base R graphics) instead ",
            "of ggplot2. Use the `aesthetics` argument to set fixed ",
            "graphical parameters (e.g., `aesthetics = list(col = \"red\")`).",
            call. = FALSE)
  }

  # Extract or compute importance scores
  imp <- if (inherits(object, what = "vi")) {
    object
  } else {
    vi(object = object, ...)  # compute variable importance scores
  }

  # Character string specifying the type of VI that was computed
  vi_type <- attr(imp, which = "type")

  # Integer specifying the number of features to include in the plot
  num_features <- as.integer(num_features)[1L]  # make sure num_features is a single integer
  if (num_features > nrow(imp) || num_features < 1L) {
    num_features <- nrow(imp)
  }
  imp <- sort_importance_scores(imp, decreasing = TRUE)  # make sure these are sorted first!
  imp <- imp[seq_len(num_features), ]  # only retain num_features variable importance scores

  # Clean up raw scores for permutation-based VI scores (long format)
  raw_scores <- NULL
  if (!is.null(attr(imp, which = "raw_scores"))) {
    raw_scores <- as.data.frame(attr(imp, which = "raw_scores"))
    raw_scores$Variable <- rownames(raw_scores)
    raw_scores <- stats::reshape(
      data = raw_scores,
      varying = (1L:(ncol(raw_scores) - 1)),
      v.names = "Importance",
      direction = "long",
      sep = "_"
    )
    raw_scores <- raw_scores[raw_scores$Variable %in% imp$Variable, ]
  }

  # Boxplots/violins display the raw permutation scores, so they require them
  if (geom %in% c("boxplot", "violin") && is.null(raw_scores)) {
    stop("To construct ", geom, "s for permutation-based importance scores ",
         "you must specify `keep = TRUE` in the call to `vi()` or ",
         "`vi_permute()`. Additionally, you also need to set `nsim >= 2`.",
         call. = FALSE)
  }

  # Order factor levels by increasing importance so that the most important
  # feature is displayed at the top of horizontal (i.e., flipped) plots
  lvls <- as.character(imp$Variable[order(imp$Importance)])
  plot_imp <- imp
  plot_imp$Variable <- factor(plot_imp$Variable, levels = lvls)
  if (!is.null(raw_scores)) {
    raw_scores$Variable <- factor(raw_scores$Variable, levels = lvls)
  }

  # Map geom to the corresponding tinyplot type and plotting data
  plot_type <- switch(geom,
    "col" = "barplot",
    "point" = "p",
    "boxplot" = "boxplot",
    "violin" = "violin"
  )
  plot_data <- if (geom %in% c("boxplot", "violin")) raw_scores else plot_imp

  # y-axis label (x-axis whenever `horizontal = TRUE`)
  ylab <- if (isTRUE(include_type)) {
    paste0("Importance (", vi_type, ")")
  } else {
    "Importance"
  }

  # Draw the plot; use do.call() so the call that tinyplot records (e.g., for
  # tinyplot_add()) holds values rather than `...` or local symbols
  do.call(tinyplot::tinyplot, args = c(
    list(
      Importance ~ Variable,
      data = plot_data,
      type = plot_type,
      flip = horizontal,
      xlab = "",
      ylab = ylab
    ),
    aesthetics
  ))

  # Overlay raw permutation scores (if available and requested)
  if (!is.null(raw_scores) && all_permutations) {
    tinyplot::tinyplot_add(
      data = raw_scores,
      type = if (jitter) "jitter" else "p"
    )
  }

  # Invisibly return the variable importance scores being plotted
  invisible(imp)

}


#' @rdname vip
#'
#' @export
vip.model_fit <- function(object, ...) {
  vip(parsnip::extract_fit_engine(object), ...)
}


#' @rdname vip
#'
#' @export
vip.workflow <- function(object, ...) {
  vip(workflows::extract_fit_engine(object), ...)
}

#' @rdname vip
#'
#' @export
vip.WrappedModel <- function(object, ...) {  # package: mlr
  vip(object$learner.model, ...)
}


#' @rdname vip
#'
#' @export
vip.Learner <- function(object, ...) {  # package: mlr3
  if (is.null(object$model)) {
    stop("No fitted model found. Did you forget to call ",
         deparse(substitute(object)), "$train()?",
         call. = FALSE)
  }
  vip(object$model, ...)
}
