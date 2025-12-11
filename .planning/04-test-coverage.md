# Priority 4: Test Coverage Improvements

**Impact**: Higher reliability, easier refactoring
**Timeline**: 3-4 hours
**Risk**: Very low

## Current Coverage Gaps

Based on codebase analysis, the following areas need expanded testing:

## 4.1 list_metrics() Function

**Current state**: Minimal testing (test_vi_permute.R:22)
**Needed coverage**:

```r
# File: inst/tinytest/test_metrics.R (create new)

# Test data frame structure
metrics <- list_metrics()
expect_inherits(metrics, "data.frame")
expect_true(all(c("metric", "task", "direction") %in% names(metrics)))

# Test all regression metrics are present
regression <- metrics[metrics$task == "Regression", ]
expect_true("rmse" %in% regression$metric)
expect_true("mae" %in% regression$metric)
expect_true("rsq" %in% regression$metric)

# Test binary classification metrics
binary <- metrics[grepl("binary", metrics$task, ignore.case = TRUE), ]
expect_true("accuracy" %in% binary$metric)
expect_true("roc_auc" %in% binary$metric)

# Test metric directions are valid
expect_true(all(metrics$direction %in% c("minimize", "maximize")))

# Test no duplicates
expect_identical(nrow(metrics), length(unique(metrics$metric)))
```

## 4.2 vip() Plotting Function

**Current state**: Only 3 files test basic ggplot creation
**Needed coverage**:

```r
# File: inst/tinytest/test_vip.R (expand existing)

# Test different geom types
data("titanic_mice")
titanic <- titanic_mice[[1L]]
set.seed(101)
rfo <- ranger::ranger(survived ~ ., data = titanic)

# Default geom
p1 <- vip(rfo)
expect_true(ggplot2::is_ggplot(p1))

# Boxplot geom
p2 <- vip(rfo, geom = "boxplot")
expect_true(ggplot2::is_ggplot(p2))

# Violin geom
p3 <- vip(rfo, geom = "violin")
expect_true(ggplot2::is_ggplot(p3))

# Test horizontal orientation
p4 <- vip(rfo, horizontal = FALSE)
expect_true(ggplot2::is_ggplot(p4))

# Test num_features parameter
p5 <- vip(rfo, num_features = 3)
expect_true(ggplot2::is_ggplot(p5))

# Test include_type parameter
p6 <- vip(rfo, include_type = TRUE)
expect_true(ggplot2::is_ggplot(p6))

# Test aesthetics customization
p7 <- vip(rfo, aesthetics = list(color = "red", fill = "blue"))
expect_true(ggplot2::is_ggplot(p7))
```

## 4.3 get_training_data() Function

**Current state**: Scattered testing in 4 model-specific files
**Needed coverage**:

```r
# File: inst/tinytest/test_get_training_data.R (create new)

# Test models that store training data
f1 <- gen_friedman(seed = 101)
rfo <- ranger::ranger(y ~ ., data = f1)

# Should work for ranger
training_data <- vip:::get_training_data(rfo)
expect_inherits(training_data, "data.frame")
expect_equal(nrow(training_data), nrow(f1))

# Test error for models without training data
gbm_fit <- gbm::gbm(y ~ ., data = f1, distribution = "gaussian",
                     n.trees = 10, verbose = FALSE, keep.data = FALSE)
expect_error(vip:::get_training_data(gbm_fit))

# Test with different model types
# (add more as applicable)
```

## 4.4 Package Data Validation

**Current state**: No dedicated tests
**Needed coverage**:

```r
# File: inst/tinytest/test_data.R (create new)

# Test titanic dataset
data("titanic")
expect_inherits(titanic, "data.frame")
expect_equal(nrow(titanic), 1309)
expect_equal(ncol(titanic), 6)
expect_true(all(c("survived", "pclass", "age", "sex", "sibsp", "parch") %in% names(titanic)))

# Test for NA values
expect_true(sum(is.na(titanic$age)) > 0)  # Should have missing values

# Test titanic_mice dataset
data("titanic_mice")
expect_inherits(titanic_mice, "list")
expect_equal(length(titanic_mice), 11)

# Each imputed dataset should have same structure
for (i in seq_along(titanic_mice)) {
  expect_inherits(titanic_mice[[i]], "data.frame")
  expect_equal(nrow(titanic_mice[[i]]), 1309)
  expect_equal(ncol(titanic_mice[[i]]), 6)
  # Should NOT have missing values
  expect_equal(sum(is.na(titanic_mice[[i]])), 0)
}
```

## 4.5 Runnable Examples (Gemini suggestion)

**Issue**: Many examples wrapped in `\dontrun{}`
**Impact**: Examples not exercised during R CMD check

### Action items
1. Review all `\dontrun{}` blocks in Rd files
2. Convert to `\donttest{}` where appropriate
3. Ensure examples run when Suggests packages available
4. Add conditional checks: `if (requireNamespace("pdp")) { ... }`

**Files to review**:
- man/vi_firm.Rd
- man/vi_shap.Rd
- man/vi_permute.Rd
- Other model-specific examples

## 4.6 Update Remaining ggplot2 Checks

**Locations**:
- inst/tinytest/test_vi_firm.R:24
- inst/tinytest/test_vi_permute.R:35

**Change**:
```r
# Replace
expect_identical(class(object), target = c("gg", "ggplot"))

# With
expect_true(ggplot2::is_ggplot(object))
```

## Implementation Checklist

- [ ] Create test_metrics.R with comprehensive list_metrics() tests
- [ ] Expand test_vip.R with plotting parameter variations
- [ ] Create test_get_training_data.R for unified testing
- [ ] Create test_data.R for package data validation
- [ ] Review and update \dontrun{} examples to \donttest{}
- [ ] Update remaining ggplot2 class checks
- [ ] Run `covr::package_coverage()` to measure improvement

## Expected Outcome

- Baseline coverage: ~70-80% (estimate)
- Target coverage: ~85-90% (realistic goal)
- Critical functions fully tested
- Examples validated during checks
- Safer refactoring foundation
