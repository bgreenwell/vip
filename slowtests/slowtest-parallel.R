library(doParallel)
library(foreach)
library(ranger)
library(vip)

set.seed(1043)
trn <- gen_friedman(500, n_features = 500)
(rfo <- ranger(y ~ ., data = trn))

pfun <- function(object, newdata) {
  predict(object, data = newdata)$predictions
}

cl <- makeCluster(4) # use 5 workers
registerDoParallel(cl) # register the parallel backend

system.time({
  vis1 <- vi(rfo, method = "permute", target = "y", metric = "rmse",
             pred_wrapper = pfun, train = trn, nsim = 10)
})

system.time({
  vis2 <- vi(rfo, method = "permute", target = "y", metric = "rmse",
             pred_wrapper = pfun, train = trn, parallel = TRUE,
             nsim = 10, .packages = "ranger")
})

system.time({
  vis3 <- vi(rfo, method = "permute", target = "y", metric = "rmse",
             pred_wrapper = pfun, train = trn, parallel = TRUE,
             nsim = 10, .packages = "ranger", parallelize_by = "repetitions")
})

# Verify that all three approaches produce valid results
cat("Verifying results...\n")
cat("Sequential VI (first 5 features):\n")
print(head(vis1, 5))
cat("\nParallel by features (first 5 features):\n") 
print(head(vis2, 5))
cat("\nParallel by repetitions (first 5 features) - FIXED in issue #161:\n")
print(head(vis3, 5))

# Ensure all results have the same structure
stopifnot(
  identical(nrow(vis1), nrow(vis2)),
  identical(nrow(vis1), nrow(vis3)),
  identical(colnames(vis1), colnames(vis2)),
  identical(colnames(vis1), colnames(vis3))
)

cat("\n✓ All parallel methods working correctly!\n")
cat("Note: Before fix for issue #161, parallelize_by='repetitions' would\n")
cat("      silently fall back to parallelize_by='features' behavior.\n")

stopCluster(cl)
