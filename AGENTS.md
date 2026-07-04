# AGENTS.md — vip

R package for **variable importance plots (VIPs)**: model-specific and
model-agnostic variable importance (VI) scores from fitted ML models.
Exports: `vi()` (front end), `vi_model()`, `vi_permute()`, `vi_firm()`,
`vi_shap()`, `plot.vi()` (plots), `vip()` (vi + plot in one call),
`list_metrics()`, and `gen_friedman()`.

## Branches & releases

- **`devel`** (default): all development and PRs. Version carries a `.9000`
  suffix; NEWS.md starts with `# vip (development version)`.
- **`main`**: stable releases only, tagged `vX.Y.Z`. r-universe (pinned to
  main in bgreenwell/bgreenwell.r-universe.dev) and the pkgdown site both
  build from main — never push experimental work there.
- Release: merge devel → main (`--no-ff`), drop the `.9000` suffix and dev
  NEWS heading, tag, push, `gh release create`; then **merge main back into
  devel** and bump devel to the next `.9000`. Never cherry-pick devel → main.

## Dependency philosophy

Keep Imports minimal: `stats, tinyplot, utils` — nothing else without
strong justification. Plotting is **tinyplot** (zero-dep base graphics), *not*
ggplot2 (removed in 0.5.0). `foreach` lives in Suggests and is only touched
when `parallel = TRUE` (see `ploop()` in `R/vi_permute.R`); `yardstick` lives
in Suggests and is only touched when a built-in metric string is used (see
`get_metric()` in `R/metrics.R`). Use `pkg::fun()` for Suggests packages.

## Commands

```bash
Rscript -e 'devtools::document()'                                             # after roxygen edits
Rscript -e 'pkgload::load_all("."); tinytest::run_test_dir("inst/tinytest")'  # full test suite
Rscript -e 'devtools::check()'                                                # before pushing
```

Tests use **tinytest** (not testthat) in `inst/tinytest/`. Model-specific
tests (`test_pkg_*.R`) are gated behind `at_home()` and skip on CRAN-style
checks; `tests/tinytest.R` also honors `NOT_CRAN=true` (set in CI). Always add
a NEWS.md entry; never edit `man/` by hand.

## Architecture (R/)

- `vi.R` — `vi()` front end: dispatches on `method` to the `vi_*()` worker,
  then handles sorting/abbreviation/scaling/ranking.
- `vi_model.R` — 40+ S3 methods for model-specific importance. Identical
  methods are aliased (e.g., `vi_model.nnet <- vi_model.nn`); shared logic
  lives in internal workers (`vi_glmnet()`, `vi_spark_importance()`,
  `vi_spark_lm()`). All methods return via the `new_vi()` constructor in
  `R/utils.R` (plain data.frame + `"type"` attribute + `"vi"` class; base
  `[.data.frame`/`na.omit()` preserve the class and custom attributes, which
  the `vi()`/`plot.vi()` pipelines rely on).
- `vi_permute.R` — permutation importance; sequential base-R loops with
  optional foreach parallelism via the internal `ploop()` helper. One
  subsample per repetition (baseline recomputed on the subsample).
- `vi_firm.R` — variance-based importance from `pdp::partial()` effects.
- `vi_shap.R` — mean(|Shapley value|) via `fastshap::explain()`.
- `vip.R` — plotting via tinyplot; `plot.vi()` is the engine (its `...` go
  straight to `tinyplot::tinyplot()`) and `vip()` is a thin wrapper whose
  `...` are reserved for `vi()`. Both draw as a side effect and invisibly
  return the plotted `"vi"` object.
- `metrics.R` — `metric_table()` is the single source of truth for built-in
  metrics; `get_metric()` resolves yardstick functions lazily.
- `get_feature_names.R` / `get_training_data.R` — per-model S3 helpers for
  recovering feature names/training data from fitted models.

## Gotchas

- **tinyplot records calls** for `tinyplot_add()` — build internal plot calls
  with `do.call()` so stored calls hold values, never `...` or local symbols.
- `vip()`/`plot.vi()` return the `vi` data frame **invisibly**; tests assert
  `expect_inherits(p, "vi")` on a null device (`pdf(NULL)`), not ggplot
  classes.
- `vip()` must NOT gain a `type` formal: its `...` forward to `vi()`, and
  `vi_permute()` has a documented `type = "difference"/"ratio"` passthrough
  that an own-formal would silently capture (hence `geom` in `vip()` vs.
  `type` in `plot.vi()`).
- Supporting a new model class = add `vi_model.<class>()` (+ optionally
  `get_feature_names.<class>()`), document in the `vi_model()` details
  section, and add an `at_home()`-gated `inst/tinytest/test_pkg_<pkg>.R`.
- `AGENTS.md`/`CLAUDE.md` are `.Rbuildignore`d and removed before pkgdown
  builds (the workflow does `rm -f AGENTS.md CLAUDE.md`).
