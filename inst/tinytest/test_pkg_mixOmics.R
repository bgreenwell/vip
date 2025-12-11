# Skip on CRAN releases FIRST (Bioconductor dependency complexity)
if (!identical(tolower(Sys.getenv("NOT_CRAN")), "true")) exit_file("Skip on CRAN")

# Exits
if (!requireNamespace("mixOmics", quietly = TRUE)) {
  exit_file("Bioconductor package 'mixOmics' missing")
}

# Generate Friedman benchmark data
friedman1 <- gen_friedman(seed = 101)
friedman3 <- gen_friedman(seed = 101, n_bins = 3)

# univariate regression
pls_mo <- mixOmics::pls(friedman1[, -1], friedman1[, 1, drop = FALSE], ncomp = 3)
spls_mo <- mixOmics::spls(friedman1[, -1], friedman1[, 1, drop = FALSE],  ncomp = 3)

pls_mo_imp <- mixOmics::vip(pls_mo)
spls_mo_imp <- mixOmics::vip(spls_mo)

# classification
plsda_mo <- mixOmics::plsda(friedman3[, -1], friedman3$y, ncomp = 3)
splsda_mo <- mixOmics::splsda(friedman3[, -1], friedman3$y, ncomp = 3)

plsda_mo_imp <- mixOmics::vip(plsda_mo)
splsda_mo_imp <- mixOmics::vip(splsda_mo)

# Expectations for `vi_model()`

for (i in 1:3) {

  pls_vip_imp <- vi_model(pls_mo, ncomp = i)
  expect_identical(
    current = pls_vip_imp$Importance,
    target = pls_mo_imp[,i]
  )

  spls_vip_imp <- vi_model(spls_mo, ncomp = i)
  expect_identical(
    current = spls_vip_imp$Importance,
    target = spls_mo_imp[,i]
  )

  plsda_vip_imp <- vi_model(plsda_mo, ncomp = i)
  expect_identical(
    current = plsda_vip_imp$Importance,
    target = plsda_mo_imp[,i]
  )

  splsda_vip_imp <- vi_model(splsda_mo, ncomp = i)
  expect_identical(
    current = splsda_vip_imp$Importance,
    target = splsda_mo_imp[,i]
  )

}

pls_vip_imp <- vi_model(pls_mo)
expect_identical(
  current = pls_vip_imp$Importance,
  target = pls_mo_imp[,3]
)

spls_vip_imp <- vi_model(spls_mo)
expect_identical(
  current = spls_vip_imp$Importance,
  target = spls_mo_imp[,3]
)

plsda_vip_imp <- vi_model(plsda_mo)
expect_identical(
  current = plsda_vip_imp$Importance,
  target = plsda_mo_imp[,3]
)

splsda_vip_imp <- vi_model(splsda_mo)
expect_identical(
  current = splsda_vip_imp$Importance,
  target = splsda_mo_imp[,3]
)

expect_error(
  vi_model(pls_mo, ncomp = 1:3),
  "should be a single integer"
)

expect_warning(
  too_many <- vi_model(pls_mo, ncomp = 300),
  "Results are for 3"
)
expect_identical(
  current = too_many$Importance,
  target = pls_mo_imp[,3]
)
