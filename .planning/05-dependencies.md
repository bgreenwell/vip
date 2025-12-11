# Priority 5: Dependency Optimization

**Impact**: Correct dependency classification, developer clarity
**Timeline**: 1-2 hours
**Risk**: Very low

## Current Dependency Structure

**Imports (5 core)**: foreach, ggplot2, stats, tibble, utils, yardstick
**Suggests (14)**: Testing/docs + supporting packages
**Enhances (18)**: ML ecosystem integration

## Assessment: Well-Optimized

The package has an excellent dependency structure. Only minor clarifications needed.

## 5.1 Clarify pdp Dependency Status

**Current state**: pdp in Suggests, used in R/vi_firm.R:210
**Issue**: Direct usage without defensive check... wait, checking code...

### Investigation result

**Location**: R/vi_firm.R:210
```r
pd <- pdp::partial(...)
```

**Defensive check**: R/vi_firm.R has `if (!requireNamespace("pdp"...))` checks in place.

### Gemini recommendation: Keep as-is

✅ **Already compliant with CRAN policies**
- pdp is correctly in Suggests
- Defensive checks are present
- Moving to Imports would burden users who don't need FIRM

**Action**: ✨ No change needed. Document this decision.

## 5.2 Verify utils Import Necessity

**Effort**: 15 minutes
**Impact**: Minor cleanup

### Investigation
Usage count in codebase: 0 active `utils::` calls found

### Action
1. Verify utils isn't used by vignette building
2. Check if required by roxygen2/devtools tooling
3. If truly unused, remove from DESCRIPTION Imports
4. Test package build after removal

**Likely outcome**: Can be removed (base package, probably not needed)

## 5.3 Document Namespace Strategy

**Effort**: 30 minutes
**Impact**: Developer clarity
**Risk**: None

### Current pattern (excellent!)
- Minimal NAMESPACE imports (only 4 items from foreach, stats)
- Consistent `::` notation throughout codebase
- All packages use explicit qualification

### Action
Add section to CLAUDE.md:

```markdown
## Namespace and Import Strategy

The vip package follows a **minimal NAMESPACE, explicit qualification** pattern:

### Rationale
- **Clarity**: `ggplot2::ggplot()` is more readable than bare `ggplot()`
- **Conflict avoidance**: No risk of function name conflicts
- **Maintainability**: Easy to identify package origins
- **Performance**: Negligible overhead with modern R

### NAMESPACE Imports
Only essential items imported:
- `foreach::%do%`, `foreach::%dopar%`, `foreach::foreach` (parallel iteration)
- `stats::reorder` (used in vip() function)

### Why Not More Imports?
Common question: "Why isn't ggplot2 imported to NAMESPACE?"

**Answer**: All ggplot2 functions use `::` notation in the code:
```r
# In R/vip.R
ggplot2::ggplot(data, ggplot2::aes(...)) +
  ggplot2::geom_col() +
  ggplot2::coord_flip()
```

This is intentional and follows best practices for modern R package development.

### Adding New Dependencies
When adding a new package dependency:
1. Add to DESCRIPTION (Imports or Suggests)
2. Use `::` notation in code
3. Only add to NAMESPACE if absolutely necessary (e.g., operators like %do%)
```

## 5.4 Consider CI Enhancements (Gemini)

**Effort**: 1 hour
**Impact**: Better automated quality checks

### Lint workflow (from Priority 1.4)
Add automated style checking via lintr.

### Dependency checks workflow
```yaml
# .github/workflows/dependency-check.yaml
name: dependency-check

on:
  pull_request:
    paths:
      - 'DESCRIPTION'
      - 'NAMESPACE'

jobs:
  check-deps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Check for unused dependencies
        run: |
          install.packages(c("desc", "pak"))
          # Custom script to validate DESCRIPTION
        shell: Rscript {0}
```

## Summary

| Item | Status | Action Required |
|------|--------|-----------------|
| pdp dependency | ✅ Correct | Document rationale |
| utils import | ⚠️ Verify | Check if needed, possibly remove |
| Namespace strategy | ✅ Good | Add documentation |
| CI enhancements | 💡 Optional | Add lint + dep check workflows |

## Deliverables

- Documentation of namespace approach in CLAUDE.md
- Verification of utils necessity
- Optional: Enhanced CI workflows
- No breaking changes to dependency structure
