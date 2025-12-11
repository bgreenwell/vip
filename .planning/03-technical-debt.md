# Priority 3: Technical Debt Resolution

**Impact**: Resolve uncertainties, improve code confidence
**Timeline**: 5-7 days
**Risk**: Low to Medium

## 3.1 Investigate H2O Extra Row Issue

**Effort**: 2-3 hours (including comprehensive testing)
**Impact**: Resolves uncertainty in production code
**Risk**: Medium (affects H2O users)

**Locations**: R/vi_model.R:588, 615, 642
**Issue**: `# FIXME: Extra row at the bottom?`

### Investigation steps
1. Create comprehensive H2O test cases across model types
2. Document actual h2o.varimp() output structure
3. Verify whether extra row exists and under what conditions
4. Implement proper fix or confirm current approach
5. Update documentation

### Testing considerations (from Gemini)
- H2O tests are flaky in CI environments
- Use `skip_on_cran()` to avoid CRAN issues
- Ensure reliable local and GitHub Actions testing

## 3.2 Clarify Formula Component Extraction

**Effort**: 1-2 hours
**Impact**: Code correctness and confidence
**Risk**: Low (well-tested area)

**Location**: R/get_feature_names.R:58
**Issue**: `# FIXME: IS the RHS always located in the third component?`

### Action items
1. Review R formula documentation (see `?formula`, `?terms`)
2. Add test cases for edge cases:
   - Multiple LHS: `cbind(y1, y2) ~ x1 + x2`
   - Nested formulas: `y ~ x + I(x^2)`
   - No intercept: `y ~ x - 1`
   - Interaction terms: `y ~ x1 * x2`
3. Either confirm the assumption or generalize logic
4. Document the behavior
5. Remove FIXME comment

## 3.3 Review Yardstick Integration

**Effort**: 2-3 hours
**Impact**: Clean up legacy code
**Risk**: Low (metrics working correctly)

**Location**: R/vi_permute.R:443-451
**Issue**: `# FIXME: How to handle this with new yardstick integration?`

### Investigation
1. Review current yardstick usage in R/metrics.R:125-160
2. Understand why legacy code (lines 444-451) was commented
3. Determine if reference class handling is still needed
4. Test with various yardstick metric types

### Options
- Remove if truly obsolete
- Document why it's kept for reference
- Restore if still needed for edge cases

## 3.4 Clarify pred_wrapper Default Value

**Effort**: 1 hour
**Impact**: API design clarity
**Risk**: Low (documentation issue)

**Location**: R/vi_permute.R:308
**Issue**: `# FIXME: Why give this a default?`

### Investigation
1. Review API design rationale
2. Check how NULL default is handled downstream
3. Identify use cases where NULL makes sense

### Options
1. **Keep NULL default** and document why (least disruptive)
2. **Remove default** (breaking change - needs deprecation cycle per Gemini)
3. **Make pred_wrapper required** for certain methods only

**Recommendation (from Gemini)**: If changing, use deprecation warning cycle:
- v0.5.0: Warn when NULL is passed
- v0.6.0: Remove NULL default

## 3.5 Improve foreach Variable Binding

**Effort**: 30 minutes
**Impact**: Cleaner code quality
**Risk**: Very low

**Location**: R/vi_permute.R:327
**Issue**: `i <- j <- NULL  # FIXME: Is there a better way to fix this?`

### Current workaround
```r
i <- j <- NULL  # To avoid R CMD check NOTE
```

### Better approaches
1. Use `.data` pronoun if applicable
2. Add proper `@importFrom foreach` documentation
3. Use `utils::globalVariables(c("i", "j"))`
4. Restructure foreach to avoid the issue

## 3.6 Implement Native PLS Support (Optional)

**Effort**: 4-6 hours
**Impact**: Removes caret dependency for PLS
**Risk**: Low (optional enhancement)
**Priority**: Lower (nice-to-have)

**Location**: R/vi_model.R:980
**Issue**: `# FIXME: For now, just default to using caret.`

### Action (if pursued)
1. Research pls package variable importance methods
2. Implement vi_model.mvr method
3. Add comprehensive tests
4. Document native implementation
5. Keep caret fallback for compatibility

## Summary of FIXME Comments

| Location | Issue | Effort | Priority |
|----------|-------|--------|----------|
| vi_model.R:588,615,642 | H2O extra row | 2-3h | High |
| get_feature_names.R:58 | Formula RHS | 1-2h | Medium |
| vi_permute.R:443 | Yardstick legacy | 2-3h | Medium |
| vi_permute.R:308 | pred_wrapper default | 1h | Low |
| vi_permute.R:327 | foreach binding | 30m | Low |
| vi_model.R:980 | Native PLS | 4-6h | Optional |

## Deliverables

- All FIXME comments resolved or documented
- Production code confidence improved
- No lingering uncertainties
- Better documentation of design decisions
