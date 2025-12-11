# Skip on CRAN releases FIRST (C++ compilation issues on some platforms)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

# Exits
if (!requireNamespace("RSNNS", quietly = TRUE)) {
  exit_file("Package 'RSNNS' missing")
}
if (!requireNamespace("NeuralNetTools", quietly = TRUE)) {
  exit_file("Package 'NeuralNetTools' missing")
}


# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)

# Fit model(s)
set.seed(101)  # for reproducibility
fit <- RSNNS::mlp(
  x = subset(friedman1, select = -y),
  y = friedman1$y,
  size = 10,
  linOut = TRUE,
  maxit = 1000
)

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
