# Survival of Titanic passengers

The [titanic](https://koalaverse.github.io/vip/reference/titanic.md)
data set contains 263 missing values (i.e., `NA`'s) in the `age` column.
This version of the data contains imputed values for the `age` column
using *multivariate imputation by chained equations* via the
[mice](https://cran.r-project.org/package=mice) package. Consequently,
this is a list containing 11 imputed versions of the observations
contained in the
[titanic](https://koalaverse.github.io/vip/reference/titanic.md) data
frame; each completed data set has the same dimension and column
structure as
[titanic](https://koalaverse.github.io/vip/reference/titanic.md).

## Source

Greenwell, Brandon M. (2022). Tree-Based Methods for Statistical
Learning in R. CRC Press.
