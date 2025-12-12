# Skip tests on CRAN

Internal helper for test files. Skips test execution on CRAN while
allowing tests to run locally and in CI/CD where NOT_CRAN=true is set.

## Usage

``` r
skip_on_cran()
```

## Details

Set NOT_CRAN=true in your environment or CI/CD to run these tests.
