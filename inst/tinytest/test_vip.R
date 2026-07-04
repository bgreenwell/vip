# Load Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Increase length of each feature name
for (i in seq_along(names(friedman1))) {
  if (names(friedman1)[i] != "y") {
    names(friedman1)[i] <- paste0(names(friedman1)[i], "_ABCDEFGH")
  }
}

# Fit an additive linear regression model
fit <- lm(y ~ ., data = friedman1)

# Compute VI scores
vis <- vi(fit, abbreviate_feature_names = 3, rank = TRUE)

# Expectations
expect_error(vi("a"))  # unrecognized model type
expect_true(all(vis$Importance %in% 1L:10L))
expect_true(unique(nchar(vis$Variable)) == 3L)

# Ranks should assign 1 to the most important feature, regardless of sorting
vis_unsorted <- vi(fit, sort = FALSE, rank = TRUE)
top <- vi(fit)$Variable[1L]  # most important feature
expect_identical(
  current = vis_unsorted$Importance[vis_unsorted$Variable == top],
  target = 1
)


################################################################################
#
# Plotting (tinyplot/base R graphics)
#
################################################################################

# Permutation-based VI scores with raw scores retained (for boxplots/violins)
pfun <- function(object, newdata) predict(object, newdata = newdata)
set.seed(944)  # for reproducibility
vis_permute <- vi(fit, method = "permute", train = friedman1, target = "y",
                  nsim = 5, metric = "rmse", pred_wrapper = pfun)

# `vip()` draws a plot as a side effect and invisibly returns the plotted
# "vi" object; smoke test all four geoms (plus options) on a null device
pdf(NULL)
p1 <- vip(vis_permute)  # geom = "col"
p2 <- vip(vis_permute, geom = "point", horizontal = FALSE)
p3 <- vip(vis_permute, geom = "boxplot", num_features = 5,
          aesthetics = list(fill = "grey90"))
p4 <- vip(vis_permute, geom = "violin", all_permutations = TRUE, jitter = TRUE)
p5 <- vip(vis_permute, all_permutations = TRUE, include_type = TRUE)
p6 <- vip(fit, num_features = 5)  # model object directly
dev.off()
for (p in list(p1, p2, p4, p5)) {
  expect_inherits(p, class = "vi")
  expect_identical(nrow(p), target = 10L)
}
expect_identical(nrow(p3), target = 5L)  # num_features = 5
expect_identical(nrow(p6), target = 5L)

# Boxplots/violins require raw permutation scores
expect_error(vip(vi(fit), geom = "boxplot"), pattern = "keep = TRUE")
expect_error(vip(vi(fit), geom = "violin"), pattern = "keep = TRUE")

# The ggplot2-specific `mapping` argument is deprecated (warn and ignore)
pdf(NULL)
expect_warning(vip(vis_permute, mapping = "anything"), pattern = "deprecated")
dev.off()
