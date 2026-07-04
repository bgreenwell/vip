if (requireNamespace("tinytest", quietly = TRUE)) {
  # Run the full suite for development versions (4 version components) or
  # whenever NOT_CRAN=true (e.g., set by GitHub Actions); CRAN-style checks of
  # a release version only run the dependency-free tests
  home <- length(unclass(packageVersion("vip"))[[1L]]) == 4 ||
    identical(tolower(Sys.getenv("NOT_CRAN")), "true")
  tinytest::test_package("vip", at_home = home)
}
