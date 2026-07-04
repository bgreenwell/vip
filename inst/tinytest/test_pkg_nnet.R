exit_if_not(at_home())

# Exits
if (!requireNamespace("nnet", quietly = TRUE)) {
  exit_file("Package 'nnet' missing")
}
if (!requireNamespace("NeuralNetTools", quietly = TRUE)) {
  exit_file("Package 'NeuralNetTools' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)  # for reproducibility
fit <- nnet::nnet(y ~ ., data = friedman1, size = 10, decay = 0.1,
                  linout = TRUE, maxit = 1000, trace = FALSE)

# Compute VI scores
vis1 <- vi_model(fit)
vis2 <- vi_model(fit, type = "garson")

# Expectations for `vi_model()`
expect_identical(
  current = vis1$Importance,
  target = NeuralNetTools::olden(fit, bar_plot = FALSE)$importance
)
expect_identical(
  current = vis2$Importance,
  target = NeuralNetTools::garson(fit, bar_plot = FALSE)$rel_imp
)

# Expectations for `get_feature_names()`
expect_identical(
  current = vip:::get_feature_names.nnet(fit),
  target = paste0("x", 1L:10L)
)

# Call `vip::vip()` directly; draws a plot (tinyplot/base R graphics) as a
# side effect and invisibly returns the plotted "vi" object
pdf(NULL)  # null graphics device
p <- vip(fit, method = "model", include_type = TRUE)
dev.off()
expect_inherits(p, class = "vi")
