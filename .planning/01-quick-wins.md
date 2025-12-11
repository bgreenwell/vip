# Priority 1: Quick Wins

**Impact**: High value, low effort improvements
**Timeline**: 1-2 days
**Risk**: Very low

## 1.1 Remove Commented-Out Code

**Effort**: 30 minutes
**Impact**: Improves readability, reduces clutter

### Test files (15 files)
Remove commented-out `library()` statements now handled by `exit_if_not()`:
- test_pkg_RSNNS.R
- test_pkg_nnet.R
- test_pkg_C50.R
- test_pkg_glmnet.R
- test_pkg_neuralnet.R
- test_pkg_xgboost.R
- test_pkg_pls.R
- test_pkg_lightgbm.R
- test_pkg_gbm.R
- test_pkg_caret.R
- test_pkg_randomForest.R
- (and others)

### R/vi_model.R (6+ locations)
Remove commented-out dependency check blocks:
- Lines 322-323
- Lines 357-358
- Lines 392-393
- Lines 424-425
- Lines 461-462
- Lines 668-669

### R/utils.R
- Lines 27-34: Remove commented-out `permute_columns()` function

### R/vi_permute.R
- Lines 444-451: Remove or document legacy yardstick integration code

## 1.2 Fix Typo

**Effort**: 1 minute
**Impact**: User-facing quality

**Location**: R/utils.R:18
**Change**: "comonents" → "components"

## 1.3 Update ggplot2 Class Checks

**Effort**: 30 minutes
**Impact**: Future-proof for ggplot2 S7 transition

**Locations**:
- inst/tinytest/test_vi_firm.R:24
- inst/tinytest/test_vi_permute.R:35

**Change**:
```r
# OLD
expect_identical(class(object), target = c("gg", "ggplot"))

# NEW
expect_true(ggplot2::is_ggplot(object))
```

## 1.4 Add CI Lint Workflow (Gemini suggestion)

**Effort**: 1 hour
**Impact**: Catch style issues automatically

**Action**: Add `.github/workflows/lint.yaml`:
```yaml
name: lint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Install lintr
        run: install.packages("lintr")
        shell: Rscript {0}
      - name: Lint
        run: lintr::lint_package()
        shell: Rscript {0}
```

## Deliverables

- Cleaner codebase (no dead code)
- Fixed typo in error message
- Future-proof ggplot2 compatibility
- Automated style checking
