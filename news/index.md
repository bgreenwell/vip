# Changelog

## vip 0.5.0

### New features

- New [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method
  for `"vi"` objects; this is now the primary plotting interface. Its
  `type` argument (`"bar"`, `"point"`, `"boxplot"`, or `"violin"`)
  selects the display, and additional arguments are passed directly on
  to
  [`tinyplot::tinyplot()`](https://grantmcdermott.com/tinyplot/man/tinyplot.html)
  (e.g., `plot(vi(fit), type = "point", col = "red", pch = 17)`).
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) remains
  as a convenience wrapper that computes and plots in one call (its
  `...` are reserved for
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md)).

### Breaking changes

- [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) now draws
  plots with lightweight base R graphics via the
  [tinyplot](https://grantmcdermott.com/tinyplot/) package instead of
  returning a ggplot2 object. The plot is drawn as a side effect and the
  underlying `"vi"` object is returned invisibly. Consequently:

  - The `mapping` argument (a ggplot2 aesthetic mapping) is deprecated
    and ignored with a warning.
  - The `aesthetics` argument is deprecated in favor of `plot_args`, a
    named list of base R graphical parameters (e.g., `col`, `fill`,
    `pch`, `cex`, `lwd`) passed on to
    [`tinyplot::tinyplot()`](https://grantmcdermott.com/tinyplot/man/tinyplot.html);
    supplying `aesthetics` warns but still works for this release.
  - `geom = "bar"` is the new preferred value for bar charts; the
    ggplot2-era value `"col"` is retained as a silent legacy alias.
  - ggplot2 was removed from the package’s dependencies entirely.

- [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) and friends
  now return a plain data frame with class `"vi"` instead of a tibble;
  printing changes accordingly. Use
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  on the result if you prefer a tibble.

- Slimmed down the dependency tree: **vip** now imports only `stats`,
  `tinyplot`, and `utils`:

  - `tibble` was removed entirely (see above).
  - `foreach` moved to Suggests; it is only needed (and only loaded)
    when calling
    [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
    with `parallel = TRUE`.
  - `yardstick` moved to Suggests; it is only needed when specifying a
    built-in metric by name (you can always supply your own metric
    function instead).

- When subsampling is requested via `sample_size` or `sample_frac`,
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  now draws a single subsample per Monte Carlo repetition and recomputes
  the baseline performance on that subsample. Previously, a different
  subsample was drawn for every feature and compared against a baseline
  computed on the full training set, which biased the scores and
  compared features on different rows. Results will differ slightly from
  previous versions whenever subsampling is used.

### Fixed

- `vi(..., rank = TRUE)` now correctly assigns rank 1 to the most
  important feature regardless of the `sort` and `decreasing` arguments;
  previously the ranks were reversed (and essentially meaningless)
  whenever `sort = FALSE`.

- [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  no longer errors when computing importance for a single feature (e.g.,
  `feature_names` of length one with `nsim = 1`).

- [`list_metrics()`](https://bgreenwell.github.io/vip/reference/list_metrics.md)
  now returns the `smaller_is_better` column as a logical (as
  documented) instead of a character vector, and correctly lists
  `j_index_vec` as the yardstick function backing the `"youden"` metric.

- The full test suite runs again under `R CMD check` in CI:
  `tests/tinytest.R` now honors the `NOT_CRAN` environment variable in
  addition to the development-version check, so `at_home()`-gated tests
  are no longer silently skipped for release versions.

- The (previously ignored) `verbose` argument to
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  now works as documented, and supplying the deprecated
  `reference_class` argument triggers a deprecation warning instead of
  being silently ignored.

- Exactly-zero coefficients (common with lasso models) now get
  `Sign = "POS"` instead of `"NEG"` in
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  output for glmnet and Spark ML linear models.

### Changed

- Major internal cleanup of
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md):
  all methods now share an internal `new_vi()` constructor, duplicate
  method definitions were removed, and identical methods are aliased. No
  user-visible changes.

- Small speedups in
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  (column-level permutation and
  [`rowMeans()`](https://rdrr.io/r/base/colSums.html)) and
  [`vi_shap()`](https://bgreenwell.github.io/vip/reference/vi_shap.md)
  ([`colMeans()`](https://rdrr.io/r/base/colSums.html)).

- The introductory vignette was rewritten as a plain, fast-building
  [`rmarkdown::html_vignette`](https://pkgs.rstudio.com/rmarkdown/reference/html_vignette.html)
  (the old precompiled, paper-length vignette is superseded by the R
  Journal article).

- Installation instructions now point to
  [r-universe](https://bgreenwell.r-universe.dev/vip); the package is no
  longer distributed on CRAN.

## vip 0.4.6

CRAN release: 2026-04-23

### Fixed

- Fixed CRAN check failures on r-devel (Linux/Fedora and macOS ARM64) in
  `test_vi_firm.R`. The test called
  [`ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md)
  without the `ranger::` namespace prefix —
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) loads a
  namespace but does not attach it, so unqualified function calls fail.
  Changed to
  [`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md).

- Fixed `test_vi_firm.R` to pass `train = titanic` explicitly to all
  [`vi_firm()`](https://bgreenwell.github.io/vip/reference/vi_firm.md) /
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) calls. The
  auto-extraction fallback in `get_training_data.default` is not
  implemented for ranger models.

- Narrowed two `expect_equal()` assertions in `test_vi_firm.R` to
  compare only `$Importance` values. The `prob = TRUE` shortcut and a
  custom `pfun` wrapper produce the same importance scores but different
  raw effect representations, so comparing full objects (including the
  `effects` attribute) was overly strict.

## vip 0.4.5

CRAN release: 2025-12-12

### Fixed

- Fixed CRAN check failures on macOS (M1/ARM64, Intel) and Linux
  platforms by implementing selective test skipping for all test_pkg\_\*
  files with platform-specific or large dependency trees. All 23
  package-specific test suites now skip on CRAN via `NOT_CRAN`
  environment variable, eliminating failures from external dependencies
  while maintaining comprehensive testing in CI/CD.

### Changed

- Expanded GitHub Actions CI/CD to 9 platform configurations covering
  all 13 CRAN check flavors:

  - Windows (release, devel)
  - macOS ARM64/M1 (release, devel)
  - macOS Intel (release)
  - Ubuntu/Debian (devel, release, oldrel-1, oldrel-2)

- Added `NOT_CRAN=true` environment variable to CI/CD workflows,
  enabling comprehensive testing of all ML package integrations (40+
  model types) while ensuring reliable CRAN submissions.

- Cleaned up test files by removing commented-out
  [`library()`](https://rdrr.io/r/base/library.html) statements from
  package-specific tests.

- Added `.github/CRAN_PLATFORM_COVERAGE.md` documenting the complete
  mapping between GitHub Actions configurations and CRAN check
  platforms.

## vip 0.4.3

CRAN release: 2025-12-10

### Fixed

- Fixed CRAN check failures by explicitly loading `titanic_mice` dataset
  in test files. Tests now use `data("titanic_mice")` before accessing
  the dataset to ensure availability across all platforms.

- Fixed ggplot class testing for ggplot2 S7 compatibility
  [(](https://github.com/koalaverse/vip/issues/162)[\#162](https://github.com/bgreenwell/vip/issues/162)).
  Replaced hardcoded class checks with
  [`ggplot2::is_ggplot()`](https://ggplot2.tidyverse.org/reference/is_tests.html)
  to ensure forward compatibility with ggplot2’s upcoming S7 transition.

- Fixed CRAN warnings by updating arXiv citation to DOI format and
  removing unnecessary `LazyData` field from DESCRIPTION.

### Changed

- Updated branch references from `master` to `main` throughout the
  package to align with modern git naming conventions
  [(](https://github.com/koalaverse/vip/pull/164)[\#164](https://github.com/bgreenwell/vip/issues/164)).
  - Updated GitHub Actions workflows to trigger on `main` branch
  - Updated codecov badge link in README
  - Fixed GitHub links in vignettes to point to `main` branch
- Refined README style and documentation:
  - Converted all headings to sentence case for consistency
  - Reduced emoji usage in content while keeping them in section headers
  - Added canonical CRAN hyperlinks to all package references
  - Improved overall clarity and professional appearance

### Added

- Added comprehensive CLAUDE.md development guide with:
  - Detailed TDD workflow and testing patterns
  - Style guidelines emphasizing sentence case and minimal emoji usage
  - ggplot2 S7 compatibility guidance
  - R package best practices and quality assurance checklists

### Removed

- Removed recognition section from README that contained inaccurate
  statistics.

## vip 0.4.1

CRAN release: 2023-08-21

### Changed

- Minor tweaks to URLs and tests to pass CRAN checks.

## vip 0.4.0

CRAN release: 2023-07-19

### Changed

- This NEWS file now follows the [Keep a
  Changelog](https://keepachangelog.com/en/1.0.0/) format.

- Removed lifecycle badge from `README` file.

- The training data has to be explicitly passed in more cases when using
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md),
  [`vi_shap()`](https://bgreenwell.github.io/vip/reference/vi_shap.md),
  and
  [`vi_firm()`](https://bgreenwell.github.io/vip/reference/vi_firm.md).

- Raised R version dependency to \>= 4.1.0 (the introduction of the
  native piper operator `|>`).

- The `vi_permute` function now relies on the
  [yardstick](https://cran.r-project.org/package=yardstick) package for
  compouting performance measures (e.g., RMSE and log loss);
  consequently, user-supplied metric functions now nned to conform to
  [yardstick](https://cran.r-project.org/package=yardstick) metric
  argument names.

- The `var_fun` argument in
  [`vi_firm()`](https://bgreenwell.github.io/vip/reference/vi_firm.md)
  has been deprecated; use the new `var_continuous` and
  `var_categorical` instead.

- The explicit `ice` argument in
  [`vi_firm()`](https://bgreenwell.github.io/vip/reference/vi_firm.md)
  has been removed; it was not really needed since it can be passed via
  the `...` argument.

- Removed [magrittr](https://cran.r-project.org/package=magrittr) from
  imports; it’s easy enough to just laod the package if you need it or
  use R’s newer internal pipe operator.

- Tweaked examples.

- Tests based on [fastshap](https://cran.r-project.org/package=fastshap)
  now check to make sure it’s available.

- Suppress loading of
  [mixOmics](https://bioconductor.org/packages/mixOmics/) in tests.

- Switched lifecycle badge from “maturing”, which has been superseded,
  to “experimental.”

- Fixed [H2O
  URL](https://docs.h2o.ai/h2o/latest-stable/h2o-docs/variable-importance.html)
  in `vi_model.R`.

- Removed the unnecessary `LazyData: true` line from the `DESCRIPTION`
  file.

- Switched to using markdown syntax in `roxygen2` comments.

### Added

- [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  now supports [lightgbm](https://cran.r-project.org/package=lightgbm)
  models. Thanks to [@nipnipj](https://github.com/nipnipj) for the
  suggestion
  [(](https://github.com/koalaverse/vip/issues/146)[\#146](https://github.com/bgreenwell/vip/issues/146)).

- The permutation importance method (i.e., function
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md))
  now integrates with and uses
  [yardstick](https://cran.r-project.org/package=yardstick) performance
  metrics.

- [`list_metrics()`](https://bgreenwell.github.io/vip/reference/list_metrics.md)
  gained an additional `smaller_is_better` column indicating whether or
  not the corresponding metric should be minimized
  (`smaller_is_better = TRUE`) or maximized
  (`smaller_is_better = FALSE`); thanks to
  [@topedo](https://github.com/topedo). Additionally, all the column
  names are now in lower case.

- Added support for partial least squares via the
  [mixOmics](https://bioconductor.org/packages/mixOmics/) package
  [(PR](https://github.com/koalaverse/vip/pull/129)
  [\#129](https://github.com/bgreenwell/vip/issues/129)); thanks to
  [@topedo](https://github.com/topedo).

- Added support for the
  [workflows](https://cran.r-project.org/package=workflows) and
  [parsnip](https://cran.r-project.org/package=parsnip) packages from
  the [tidymodels](https://www.tidymodels.org/) ecosystem
  [(PR](https://github.com/koalaverse/vip/pull/128)
  [\#128](https://github.com/bgreenwell/vip/issues/128)); thanks to
  [@topedo](https://github.com/topedo).

- New [pkgdown](https://cran.r-project.org/package=pkgdown) site and
  vignette based on our original R Journal article.

### Removed

- Function `add_sparklines()` seems out of scope and has been removed.
- Function `vint()` also seems out of scope and is too slow to implement
  for most practical problems; for now, the function will likely live on
  in the [moreparty](https://cran.r-project.org/package=moreparty)
  package.

### Fixed

- Fix model-based VI support for
  [mlr](https://cran.r-project.org/package=mlr),
  [mlr3](https://cran.r-project.org/package=mlr3),
  [parsnip](https://cran.r-project.org/package=parsnip), and
  [workflows](https://cran.r-project.org/package=workflows) model fits.

## vip 0.3.2

CRAN release: 2020-12-17

### Miscellaneous

- Add `tools/` to .Rbuildignore.

## vip 0.3.1

### Miscellaneous

- Change <http://spark.rstudio.com/mlib/> to
  <https://spark.posit.co/mlib/> in NEWS.md.

- Remove unnecessary codecov.yml file.

## vip 0.3.0

### User-visable changes

- Removed deprecated arguments from
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md); in
  particular, `bar`, `width`, `alpha`, `color`, `fill`, `size`, and
  `shape`. Users should instead rely on the `mapping` and `aesthetics`
  arguments; see
  [`?vip::vip`](https://bgreenwell.github.io/vip/reference/vip.md) for
  details.

### Bug fixes

- Fixed a couple bugs that occurred when using
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  with the [glmnet](https://cran.r-project.org/package=glmnet) package.
  In particular, we added a new `lamnda` parameter for specifying the
  value of the penalty term to use when extracting the estimated
  coefficients. This is equivalent to the `s` argument in
  `glmnet::coef()`; the name `lambda` was chosen to not conflict with
  other arguments in
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md).
  Additionally,
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  did not return the absolute value of the estimated coefficients for
  [glmnet](https://cran.r-project.org/package=glmnet) models like
  advertised, but is now fixed in this version
  [(](https://github.com/koalaverse/vip/issues/103)[\#103](https://github.com/bgreenwell/vip/issues/103)).

### Miscellaneous

- Switched from Travis-CI to GitHub Actions for continuous integration.

- Added a CITATION file and PDF-based vignette based off of the
  published article in [The R
  Journal](https://journal.r-project.org/articles/RJ-2020-013/index.html)
  [(](https://github.com/koalaverse/vip/issues/109)[\#109](https://github.com/bgreenwell/vip/issues/109)).

- Switch from
  [`tibble::as.tibble()`](https://tibble.tidyverse.org/reference/deprecated.html)—which
  was deprecated in [tibble](https://github.com/tidyverse/tibble)
  2.0.0—to
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  in a few function calls
  [(](https://github.com/koalaverse/vip/issues/101)[\#101](https://github.com/bgreenwell/vip/issues/101)).

## vip 0.2.2

CRAN release: 2020-04-06

### User-visible changes

- The `Importance` column from
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  no longer contains “inner” names; in accordance with breaking changes
  in [tibble](https://github.com/tidyverse/tibble) 3.0.0.

## vip 0.2.1

CRAN release: 2020-01-20

### Enhancements

- Added support for SHAP-based feature importance which makes use of the
  recent [fastshap](https://cran.r-project.org/package=fastshap) package
  on CRAN. To use, simply call
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) or
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) and
  specify `method = "shap"`, or you can just call
  [`vi_shap()`](https://bgreenwell.github.io/vip/reference/vi_shap.md)
  directly
  [(](https://github.com/koalaverse/vip/issues/87)[\#87](https://github.com/bgreenwell/vip/issues/87)).

- Added support for the
  [parsnip](https://cran.r-project.org/package=parsnip),
  [mlr](https://cran.r-project.org/package=mlr), and
  [mlr3](https://cran.r-project.org/package=mlr3) packages
  [(](https://github.com/koalaverse/vip/issues/94)[\#94](https://github.com/bgreenwell/vip/issues/94)).

- Added support for `"mvr"` objects from the
  [pls](https://cran.r-project.org/package=pls) package (currently just
  calls [`caret::varImp()`](https://rdrr.io/pkg/caret/man/varImp.html))
  [(](https://github.com/koalaverse/vip/issues/35)[\#35](https://github.com/bgreenwell/vip/issues/35)).

- The `"lm"` method for
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  gained a new `type` argument that allows users to use either (1) the
  raw coefficients if the features were properly standardized
  (`type = "raw"`), or (2) the absolute value of the corresponding *t*-
  or *z*-statistic (`type = "stat"`, the default)
  [(](https://github.com/koalaverse/vip/issues/77)[\#77](https://github.com/bgreenwell/vip/issues/77)).

- New function
  [`gen_friedman()`](https://bgreenwell.github.io/vip/reference/gen_friedman.md)
  for simulating data from the Friedman 1 benchmark problem; see
  [`?vip::gen_friedman`](https://bgreenwell.github.io/vip/reference/gen_friedman.md)
  for details.

### User-visible changes

- The `vi_pdp()` and `vi_ice()` functions have been deprecated and
  merged into a single new function called
  [`vi_firm()`](https://bgreenwell.github.io/vip/reference/vi_firm.md).
  Consequently, setting `method = "pdp"` and `method = "ice"` has also
  been deprecated; use `method = "firm"` instead.

- The `metric` and `pred_wrapper` arguments to
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  are no longer optional.

- The [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md)
  function gained a new argument, `geom`, for specifying which type of
  plot to construct. Current options are `geom = "col"` (the default),
  `geom = "point"`, `geom = "boxplot"`, or `geom = "violin"` (the latter
  two only work for permutation-based importance with `nsim > 1`)
  [(](https://github.com/koalaverse/vip/issues/79)[\#79](https://github.com/bgreenwell/vip/issues/79)).
  Consequently, the `bar` argument has been removed.

- The [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md)
  function gained two new arguments for specifying aesthetics: `mapping`
  and `aesthetics` (for fixed aesthetics like `color = "red"`).
  Consequently, the arguments `color`, `fill`, etc. have been removed
  [(](https://github.com/koalaverse/vip/issues/80)[\#80](https://github.com/bgreenwell/vip/issues/80)).

An example illustrating the above two changes is given below:

``` r

# Load required packages
library(ggplot2)  # for `aes_string()` function

# Load the sample data
data(mtcars)

# Fit a linear regression model
model <- lm(mpg ~ ., data = mtcars)

# Construct variable importance plots
p1 <- vip(model)
p2 <- vip(model, mapping = aes_string(color = "Sign"))
p3 <- vip(model, type = "dotplot")
p4 <- vip(model, type = "dotplot", mapping = aes_string(color = "Variable"),
          aesthetics = list(size = 3))
grid.arrange(p1, p2, p3, p4, nrow = 2)
```

- The [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md)
  function gained a new argument, `include_type`, which defaults to
  `FALSE`. If `TRUE`, the type of variable importance that was computed
  is included in the appropriate axis label. Set `include_type = TRUE`
  to revert to the old behavior.

### Miscellaneous

- Removed dependency on
  [ModelMetrics](https://cran.r-project.org/package=ModelMetrics) and
  the built-in family of performance metrics (`metric_*()`) are now
  documented and exported. See, for example, `?vip::metric_rmse`
  [(](https://github.com/koalaverse/vip/issues/93)[\#93](https://github.com/bgreenwell/vip/issues/93)).

- Switched to the
  [tinytest](https://cran.r-project.org/package=tinytest) framework
  [(](https://github.com/koalaverse/vip/issues/82)[\#82](https://github.com/bgreenwell/vip/issues/82)).

- Minor documentation improvements.

### Bug fixes

- The internal (i.e., not exported)
  [`get_feature_names()`](https://bgreenwell.github.io/vip/reference/get_feature_names.md)
  function does a better job with `"nnet"` objects containing factors.
  It also does a better job at extracting feature names from model
  objects containing a `"formula"` component.

- [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  now works correctly for `"glm"` objects with non-Gaussian families
  (e.g., logistic regression)
  [(](https://github.com/koalaverse/vip/issues/74)[\#74](https://github.com/bgreenwell/vip/issues/74)).

- Added appropriate **sparklyr** version dependency
  [(](https://github.com/koalaverse/vip/issues/59)[\#59](https://github.com/bgreenwell/vip/issues/59)).

## vip 0.1.3

CRAN release: 2019-07-03

### New functions

- Removed warnings from experimental functions.

- [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  gained a type argument (i.e., `type = "difference"` or
  `type = "ratio"`); this argument can be passed via
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) or
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) as well.

- `add_sparklines()` creates an HTML widget to display variable
  importance scores with a sparkline representation of each features
  effect (i.e., its partial dependence function)
  [(](https://github.com/koalaverse/vip/issues/64)[\#64](https://github.com/bgreenwell/vip/issues/64)).

- Added support for the Olden and Garson algorithms with neural networks
  fit using the **neuralnet**, **nnet**, and **RSNNS** packages
  [(](https://github.com/koalaverse/vip/issues/28)[\#28](https://github.com/bgreenwell/vip/issues/28)).

- Added support for GLMNET models fit using the **glmnet** package (with
  and without cross-validation).

### Breaking changes

- The `pred_fun` argument in
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  has been changed to `pred_wrapper`.

- The `FUN` argument to
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md),
  `vi_pdp()`, and `vi_ice()` has been changed to `var_fun`.

- Only the predicted class probabilities for the reference class are
  required (as a numeric vector) for binary classification when
  `metric = "auc"` or `metric = "logloss"`.

### Minor changes

- [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  gained a new logical `keep` argument. If `TRUE` (the default), the raw
  permutation scores from all `nsim` repetitions (provided `nsim > 1`)
  will be stored in an attribute called `"raw_scores"`.

- [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) gained
  new logical arguments `all_permutations` and `jitter` which help to
  visualize the raw permutation scores for all `nsim` repetitions
  (provided `nsim > 1`).

- You can now pass a `type` argument to
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  specifying how to compare the baseline and permuted performance
  metrics. Current choices are `"difference"` (the default) and
  `"ratio"`.

- Improved documentation (especially for
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  and
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)).

- Results from
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md),
  `vi_pdp()`, `vi_ice()`, and
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  now have class `"vi"`, making them easier to plot with
  [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md).

## vip 0.1.2

CRAN release: 2018-09-30

- Added `nsim` argument to
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  for reducing the sampling variability induced by permuting each
  predictor
  [(](https://github.com/koalaverse/vip/issues/36)[\#36](https://github.com/bgreenwell/vip/issues/36)).

- Added `sample_size` and `sample_frac` arguments to
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  for reducing the size of the training sample for every Monte Carlo
  repetition
  [(](https://github.com/koalaverse/vip/issues/41)[\#41](https://github.com/bgreenwell/vip/issues/41)).

- Greatly improved the documentation for
  [`vi_model()`](https://bgreenwell.github.io/vip/reference/vi_model.md)
  and the various objects it supports.

- New argument `rank`, which defaults to `FALSE`, available in
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md)
  [(](https://github.com/koalaverse/vip/issues/55)[\#55](https://github.com/bgreenwell/vip/issues/55)).

- Added support for Spark (G)LMs.

- [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) is now a
  generic which makes adding new methods easier (e.g., to support
  [DataRobot](https://www.datarobot.com/) models).

- Bug fixes.

## vip 0.1.1

CRAN release: 2018-09-27

- Fixed bug in `get_feature_names.ranger()` s.t. it never returns
  `NULL`; it either returns the feature names or throws an error if they
  cannot be recovered from the model object
  [(](https://github.com/koalaverse/vip/issues/43)[\#43](https://github.com/bgreenwell/vip/issues/43)).

- Added `pkgdown` site: <https://github.com/koalaverse/vip>.

- Changed `truncate_feature_names` argument of
  [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) to
  `abbreviate_feature_names` which abbreviates all feature names, rather
  than just truncating them.

- Added CRAN-related badges
  [(](https://github.com/koalaverse/vip/issues/32)[\#32](https://github.com/bgreenwell/vip/issues/32)).

- New generic
  [`vi_permute()`](https://bgreenwell.github.io/vip/reference/vi_permute.md)
  for constructing permutation-based variable importance scores
  [(](https://github.com/koalaverse/vip/issues/19)[\#19](https://github.com/bgreenwell/vip/issues/19)).

- Fixed bug and unnecessary error check in `vint()`
  [(](https://github.com/koalaverse/vip/issues/38)[\#38](https://github.com/bgreenwell/vip/issues/38)).

- New vignette on using `vip` with unsupported models (using the Keras
  API to TensorFlow as an example).

- Added basic [sparklyr](https://spark.posit.co/mlib/) support.

## vip 0.1.0

CRAN release: 2018-06-15

- Added support for XGBoost models (i.e., objects of class
  `"xgb.booster"`).

- Added support for ranger models (i.e., objects of class `"ranger"`).

- Added support for random forest models from the `party` package (i.e.,
  objects of class `"RandomForest"`).

- [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) gained a
  new argument, `num_features`, for specifying how many variable
  importance scores to plot. The default is set to `10`.

- `.` was changed to `_` in all argument names.

- [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) gained
  three new arguments: `truncate_feature_names` (for truncating feature
  names in the returned tibble), `sort` (a logical argument specifying
  whether or not the resulting variable importance scores should be
  sorted), and `decreasing` (a logical argument specifying whether or
  not the variable importance scores should be sorted in decreasing
  order).

- [`vi_model.lm()`](https://bgreenwell.github.io/vip/reference/vi_model.md),
  and hence [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md),
  contains an additional column called `Sign` that contains the sign of
  the original coefficients
  [(](https://github.com/koalaverse/vip/issues/27)[\#27](https://github.com/bgreenwell/vip/issues/27)).

- [`vi()`](https://bgreenwell.github.io/vip/reference/vi.md) gained a
  new argument, `scale`, for scaling the variable importance scores so
  that the largest is 100. Default is `FALSE`
  [(](https://github.com/koalaverse/vip/issues/24)[\#24](https://github.com/bgreenwell/vip/issues/24)).

- [`vip()`](https://bgreenwell.github.io/vip/reference/vip.md) gained
  two new arguments, `size` and `shape`, for controlling the size and
  shape of the points whenever `bar = FALSE`
  [(](https://github.com/koalaverse/vip/issues/9)[\#9](https://github.com/bgreenwell/vip/issues/9)).

- Added support for `"H2OBinomialModel"`, `"H2OMultinomialModel"`, and,
  `"H2ORegressionModel"` objects
  [(](https://github.com/koalaverse/vip/issues/8)[\#8](https://github.com/bgreenwell/vip/issues/8)).

## vip 0.0.1

- Initial release.
