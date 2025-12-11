# Priority 2: Code Quality and Test Infrastructure

**Impact**: Long-term maintainability
**Timeline**: 3-5 days (split across releases)
**Risk**: Low to Medium

## 2.1 Create Centralized Test Helpers

**Effort**: 2-3 hours
**Impact**: Reduces ~100+ lines of duplicated test code
**Risk**: Low

### Create inst/tinytest/tinytest_setup.R

```r
# Dependency checking helper
check_requires <- function(...) {
  packages <- c(...)
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      exit_file(paste("Package", pkg, "missing"))
    }
  }
}

# Standardized data generation
setup_friedman <- function(seed = 101, n_bins = NULL) {
  if (is.null(n_bins)) {
    gen_friedman(seed = seed)
  } else {
    gen_friedman(seed = seed, n_bins = n_bins)
  }
}

# VI structure validation
assert_vi_structure <- function(object, n_features) {
  expect_identical(class(object),
                   c("vi", "tbl_df", "tbl", "data.frame"))
  expect_identical(nrow(object), n_features)
  expect_true(all(c("Variable", "Importance") %in% names(object)))
}

# Feature names assertion
assert_feature_names <- function(fit, expected_names) {
  actual <- vip:::get_feature_names(fit)
  expect_identical(actual, expected_names)
}
```

### Refactor 24 test files
Files using `gen_friedman()` and `exit_if_not()` should migrate to helpers.

## 2.2 Consolidate H2O Model Methods

**Effort**: 1-2 hours
**Impact**: Reduces ~50 lines of duplicated code
**Risk**: Medium (requires H2O testing)

**IMPORTANT (from Gemini)**: Add H2O tests BEFORE consolidating code.

### Current state (R/vi_model.R:582-656)
Three nearly identical methods:
- vi_model.H2OBinomialModel
- vi_model.H2OMultinomialModel
- vi_model.H2ORegressionModel

### Proposed solution

```r
# Internal helper
.vi_model_h2o <- function(object) {
  tib <- tibble::as_tibble(h2o::h2o.varimp(object))
  if (object@algorithm == "glm") {
    names(tib) <- c("Variable", "Importance", "Sign")
  } else {
    tib <- tib[1L:2L]
    names(tib) <- c("Variable", "Importance")
  }
  attr(tib, "type") <- "h2o"
  class(tib) <- c("vi", class(tib))
  tib
}

# Simplified S3 methods
vi_model.H2OBinomialModel <- function(object, ...) {
  .vi_model_h2o(object)
}

vi_model.H2OMultinomialModel <- function(object, ...) {
  .vi_model_h2o(object)
}

vi_model.H2ORegressionModel <- function(object, ...) {
  .vi_model_h2o(object)
}
```

### Testing strategy (from Gemini)
1. Add `skip_on_cran()` for H2O tests (they're flaky)
2. Force H2O tests in GitHub Actions
3. Verify behavior preservation before consolidation

## 2.3 Establish Coverage Baseline (Gemini suggestion)

**Effort**: 30 minutes
**Impact**: Guides safe refactoring

**Action**:
```r
# Run locally
covr::package_coverage()

# Set up Codecov integration for CI
usethis::use_coverage(type = "codecov")
```

**Purpose**: Know exactly which H2O lines are untested before refactoring.

## Implementation Order (Updated per Gemini)

1. Establish coverage baseline (`covr::package_coverage()`)
2. Create `tinytest_setup.R`
3. Refactor existing tests to use helpers
4. **Add H2O tests** (Priority 3.1 moved here)
5. Consolidate H2O code (now safe with tests)

## Deliverables

- Reusable test infrastructure
- Reduced code duplication
- Coverage reporting in place
- Safer refactoring foundation
