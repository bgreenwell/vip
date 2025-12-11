# Claude Development Guide for vip Package

## Project Overview

The **vip** (Variable Importance Plots) package is a comprehensive R
framework for constructing variable importance plots from various
machine learning models. It provides both model-specific and
model-agnostic approaches to feature importance, serving as a critical
tool for interpretable machine learning (IML).

### Key Features

- **Unified Interface**: Single API
  ([`vi()`](https://koalaverse.github.io/vip/reference/vi.md) and
  [`vip()`](https://koalaverse.github.io/vip/reference/vip.md)) for 40+
  different ML model types
- **Multiple VI Methods**: Model-specific, permutation-based,
  SHAP-based, and variance-based approaches
- **Extensive Model Support**: Integration with major R ML ecosystems
  (tidymodels, caret, mlr, etc.)
- **Professional Visualization**: ggplot2-based plotting with
  customizable aesthetics
- **Academic Rigor**: Peer-reviewed methodology published in The R
  Journal (2020)

### Architecture

    vip/
    ├── R/                          # Source code (12 files, ~3,735 lines)
    │   ├── vi.R                   # Main VI computation interface
    │   ├── vip.R                  # Main plotting interface
    │   ├── vi_model.R             # Model-specific methods (42 S3 methods)
    │   ├── vi_permute.R           # Permutation-based importance
    │   ├── vi_shap.R              # Shapley-based importance
    │   ├── vi_firm.R              # Variance-based importance
    │   └── ...                    # Utilities and helpers
    ├── inst/tinytest/             # Test suite (28 files, ~1,581 lines)
    ├── man/                       # Documentation (11 .Rd files)
    ├── vignettes/                 # Package vignette
    └── data/                      # Example datasets

## Development Workflow

### Test-Driven Development (TDD) Framework

This project follows **strict test-driven development** using the
`tinytest` framework, chosen for its: - **Zero dependencies**:
Lightweight testing without external deps - **CRAN compatibility**:
Seamless integration with R package ecosystem - **Conditional testing**:
Graceful handling of optional dependencies - **Clear output**: Simple,
readable test results

#### TDD Cycle for vip Development

1.  **Write Tests First**

    ``` r
    # Example: Adding new model support
    # File: inst/tinytest/test_pkg_newmodel.R

    # Check dependencies first
    exit_if_not(requireNamespace("newmodel", quietly = TRUE))

    # Load test data
    data("test_dataset")

    # Fit model
    model <- newmodel::fit_model(target ~ ., data = test_dataset)

    # Test vi() method
    vi_scores <- vi(model)
    expect_inherits(vi_scores, c("vi", "tbl_df", "tbl", "data.frame"))
    expect_equal(nrow(vi_scores), ncol(test_dataset) - 1L)
    expect_true(all(c("Variable", "Importance") %in% names(vi_scores)))
    ```

2.  **Implement S3 Methods**

    ``` r
    # File: R/vi_model.R
    #' @export
    vi_model.newmodel <- function(object, ...) {
      # Extract importance scores
      importance <- newmodel::variable_importance(object)

      # Convert to standard format
      tibble::tibble(
        Variable = names(importance),
        Importance = as.numeric(importance)
      )
    }
    ```

3.  **Run Tests and Refactor**

    ``` r
    # Run specific tests
    tinytest::run_test_file("inst/tinytest/test_pkg_newmodel.R")

    # Run full suite
    tinytest::test_package("vip")
    ```

### Core Testing Patterns

#### 1. Conditional Testing for Optional Dependencies

``` r
# Always check dependencies before running tests
exit_if_not(
  requireNamespace("randomForest", quietly = TRUE),
  requireNamespace("pdp", quietly = TRUE)
)
```

#### 2. Standardized Test Structure

``` r
# Standard expectation function for VI objects
expectations <- function(object, n_features) {
  # Check class
  expect_identical(class(object), 
                   target = c("vi", "tbl_df", "tbl", "data.frame"))
  
  # Check dimensions
  expect_identical(n_features, target = nrow(object))
  
  # Check required columns
  expect_true(all(c("Variable", "Importance") %in% names(object)))
  
  # Check for valid importance scores
  expect_true(all(is.numeric(object$Importance)))
  expect_true(all(is.finite(object$Importance)))
}
```

#### 3. Model-Specific Test Patterns

``` r
# Pattern for testing model-specific implementations
test_model_vi <- function(model, expected_features) {
  # Test basic vi() call
  vi_result <- vi(model)
  expectations(vi_result, length(expected_features))
  
  # Test with different methods
  for (method in c("model", "permute", "shap", "firm")) {
    if (supports_method(model, method)) {
      vi_method <- vi(model, method = method)
      expectations(vi_method, length(expected_features))
    }
  }
  
  # Test vip() plotting
  p <- vip(model)
  expect_inherits(p, "ggplot")
}
```

## R Best Practices Implementation

### 1. Package Structure

- **DESCRIPTION**: Proper metadata, versioning, and dependency
  management
- **NAMESPACE**: Clean exports using roxygen2 `@export` tags
- **Imports**: Minimal dependencies (5 core imports)
- **S3 Methods**: Consistent dispatch system for 40+ model types

### 2. Code Style and Documentation

``` r
# Roxygen2 documentation standard
#' Variable importance
#'
#' Compute variable importance scores for the predictors in a model.
#'
#' @param object A fitted model object
#' @param method Character string specifying VI type ("model", "permute", "shap", "firm")
#' @param feature_names Character vector of feature names to compute
#' @param sort Logical indicating whether to sort results
#' @param ... Additional arguments passed to specific methods
#'
#' @return A tibble with Variable and Importance columns
#'
#' @examples
#' \dontrun{
#' library(randomForest)
#' rf <- randomForest(Species ~ ., data = iris)
#' vi_scores <- vi(rf)
#' }
#'
#' @export
vi <- function(object, ...) {
  UseMethod("vi")
}
```

### 3. Error Handling and Validation

``` r
# Input validation pattern
vi_validate_inputs <- function(object, method, ...) {
  # Check object class
  if (!inherits(object, "list") && !is.function(predict)) {
    stop("'object' must be a fitted model with a predict method")
  }
  
  # Validate method
  valid_methods <- c("model", "permute", "shap", "firm")
  if (!method %in% valid_methods) {
    stop("'method' must be one of: ", paste(valid_methods, collapse = ", "))
  }
}
```

### 4. Performance Considerations

``` r
# Efficient parallel processing with foreach
vi_permute_parallel <- function(object, train, metric, nsim, parallel = FALSE, ...) {
  if (parallel && foreach::getDoParRegistered()) {
    results <- foreach::foreach(i = seq_len(nsim), .combine = rbind) %dopar% {
      compute_permutation_importance(object, train, metric)
    }
  } else {
    results <- foreach::foreach(i = seq_len(nsim), .combine = rbind) %do% {
      compute_permutation_importance(object, train, metric)
    }
  }
  results
}
```

### 5. ggplot2 Compatibility (Important!)

With ggplot2’s transition to S7 classes, testing ggplot object classes
requires updated approaches:

``` r
# ❌ DEPRECATED: Direct class testing (will break with ggplot2 S7)
expect_identical(class(p), c("gg", "ggplot"))

# ✅ RECOMMENDED: Use is_ggplot() for forward compatibility
expect_true(ggplot2::is_ggplot(p))

# Alternative approaches:
expect_true(inherits(p, "ggplot"))  # fallback option
```

**Key Points:** - Always use
[`ggplot2::is_ggplot()`](https://ggplot2.tidyverse.org/reference/is_tests.html)
rather than [`class()`](https://rdrr.io/r/base/class.html) for ggplot
objects in tests - This ensures compatibility with both current and
future ggplot2 versions - Updated in vip 0.4.1 to address [issue
\#162](https://github.com/koalaverse/vip/issues/162)

### 6. Documentation and README Style Guidelines

**Sentence Case Requirements:** - **ALWAYS use sentence case** for all
headings, bullet points, and descriptions - Examples: - ✅ “Key
features” (not “Key Features”)  
- ✅ “Model-specific variable importance” (not “Model-Specific Variable
Importance”) - ✅ “Adding model support” (not “Adding Model Support”)

**Emoji Usage Guidelines:** - **Section headers**: Emojis are encouraged
(🚀, ✨, 🛠️, etc.) - **Tables and content**: Use sparingly, only when
they add clear value - **Lists and bullets**: Avoid emojis in favor of
clean, readable text - **General rule**: When in doubt, leave it out

**Examples:**

``` markdown
# ✅ GOOD
## 🚀 Quick start
- **Universal interface**: Works with 40+ model types
- **Multiple methods**: Model-specific, permutation, SHAP

# ❌ AVOID
## 🚀 Quick Start  # Title case
- **🎯 Universal Interface**: Works with 40+ model types  # Emoji in bullet + title case
- **🔬 Multiple Methods**: Model-specific, permutation, SHAP  # Same issues
```

## Development Workflow

The modern R package development workflow uses **devtools** and
**usethis** to streamline common tasks. Always ensure devtools is loaded
in interactive sessions:

``` r
# Add to ~/.Rprofile for automatic loading
if (interactive()) {
  require("devtools", quietly = TRUE)
  # automatically attaches usethis
}
```

### Core Development Cycle

The iterative development workflow follows this pattern:

    Edit code → load_all() → Run tests → document() → check()
       ↓            ↓            ↓            ↓          ↓
     R files    Run code    tinytest    Update     Full
               locally      suite        docs      checks

### Essential devtools Commands

**Keyboard shortcuts shown for RStudio**

#### Load and Develop

``` r
# Load all package code (Ctrl/Cmd + Shift + L)
devtools::load_all()
# This simulates installing and loading the package
# Much faster than build + install during development
```

#### Documentation

``` r
# Rebuild docs and NAMESPACE (Ctrl/Cmd + Shift + D)
devtools::document()

# Check documentation with spell check
devtools::spell_check()
```

#### Check and Validate

``` r
# Check complete package (Ctrl/Cmd + Shift + E)
devtools::check()

# Check with CRAN settings
devtools::check(cran = TRUE)
```

#### Build and Install

``` r
# Build source package (.tar.gz)
devtools::build()

# Build binary package
devtools::build(binary = TRUE)

# Install package locally
devtools::install()

# Install with vignettes
devtools::install(build_vignettes = TRUE)
```

### Testing with tinytest

``` r
# Run all tests
tinytest::test_package("vip")

# Run specific test file
tinytest::run_test_file("inst/tinytest/test_vi_firm.R")

# Test with coverage
covr::package_coverage()
```

### Package Setup (One-Time)

``` r
# Initialize version control
usethis::use_git()

# Connect to GitHub
usethis::use_github()

# Set up continuous integration
usethis::use_github_action("check-standard")

# Set up pkgdown website
usethis::use_pkgdown_github_pages()
```

### Creating New Components

``` r
# Create new R file
usethis::use_r("file-name")

# Create new test file (creates in inst/tinytest/)
usethis::use_test("file-name")

# Create vignette
usethis::use_vignette("vignette-name")

# Create article (website only)
usethis::use_article("article-name")

# Add package dependency
usethis::use_package("packagename", type = "Imports")
usethis::use_package("packagename", type = "Suggests")
```

### Alternative: R CMD Commands

For advanced users or CI/CD pipelines, traditional R CMD commands are
available:

``` bash
# Build source package
R CMD build .

# Check package (CRAN standards)
R CMD check vip_*.tar.gz --as-cran

# Install package
R CMD INSTALL .

# Generate documentation (alternative to devtools::document())
Rscript -e "roxygen2::roxygenise()"
```

### Code Quality Tools

``` r
# Check code style
lintr::lint_package()

# Format code (if using styler)
styler::style_pkg()

# Check for potential issues
goodpractice::gp()
```

## Adding New Model Support

### Step-by-Step TDD Process

1.  **Create Test File**

    ``` r
    # File: inst/tinytest/test_pkg_NEWMODEL.R
    exit_if_not(requireNamespace("NEWMODEL", quietly = TRUE))

    # Load test data and fit model
    data("test_data")  # or create synthetic data
    model <- NEWMODEL::fit_function(formula, data = test_data)

    # Define expectations
    expectations <- function(object) {
      expect_inherits(object, c("vi", "tbl_df", "tbl", "data.frame"))
      expect_equal(nrow(object), ncol(test_data) - 1L)
      expect_true(all(c("Variable", "Importance") %in% names(object)))
    }

    # Test vi_model method
    vi_result <- vi(model, method = "model")
    expectations(vi_result)

    # Test vip plotting
    p <- vip(model)
    expect_inherits(p, "ggplot")
    ```

2.  **Implement S3 Method**

    ``` r
    # File: R/vi_model.R
    #' @export
    vi_model.NEWMODEL <- function(object, type = NULL, ...) {
      # Extract variable importance
      imp <- NEWMODEL::importance_function(object, type = type)

      # Convert to standard tibble format
      tibble::tibble(
        Variable = names(imp),
        Importance = as.numeric(imp)
      )
    }
    ```

3.  **Update Documentation**

    - Add to `vi_model.R` details section
    - Update DESCRIPTION Enhances field if needed
    - Add example to package vignette

4.  **Run Tests**

    ``` r
    # Test new implementation
    tinytest::run_test_file("inst/tinytest/test_pkg_NEWMODEL.R")

    # Run full test suite
    tinytest::test_package("vip")
    ```

## Quality Assurance Checklist

### Before Committing

All tests pass: `tinytest::test_package("vip")`

Documentation builds: `roxygen2::roxygenise()`

Examples run: `R CMD check --run-donttest`

Code style consistent: `lintr::lint_package()`

News file updated for user-facing changes

### Before Release

Version number updated in DESCRIPTION

NEWS.md updated with changes

All suggested packages tested

CRAN checks pass: `R CMD check --as-cran`

Reverse dependency checks completed

## Known Technical Debt

Current FIXME items to address: 1. `get_feature_names.R:58` - Component
location verification 2. `vi_model.R:588,615,642` - Extra row handling
in model outputs  
3. `vi_permute.R:443` - Yardstick integration optimization

## Resources

- **Package Website**: <https://koalaverse.github.io/vip/>
- **CRAN Page**: <https://cran.r-project.org/package=vip>
- **GitHub Repository**: <https://github.com/koalaverse/vip/>
- **R Journal Paper**: <https://doi.org/10.32614/RJ-2020-013>
- **tinytest Documentation**:
  <https://cran.r-project.org/package=tinytest>

------------------------------------------------------------------------

This guide ensures consistent, high-quality development following R
package best practices and test-driven development methodology.
