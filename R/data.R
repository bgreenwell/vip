#' Survival of Titanic passengers
#'
#' A data set containing the survival outcome, passenger class, age, sex, and
#' the number of family members for a large number of passengers aboard the
#' ill-fated Titanic.
#'
#' @note As mentioned in the column description, `age` contains 263 `NA`s (or
#' missing values). For a complete version (or versions) of the data set, see
#' [titanic_mice].
#'
#' @format A data frame with 1309 observations on the following 6 variables:
#'
#'   * `survived` - binary with levels `"yes"` for survived and `"no"`
#'   otherwise;
#'   * `pclass` - integer giving the corresponding passenger (i.e., ticket)
#'   class with values 1--3;
#'   * `age` - the age in years of the corresponding passenger (with 263
#'   missing values);
#'   * `sex` - factor giving the sex of each passenger with levels
#'   `"male"` and `"female"`;
#'   * `sibsp` - integer giving the number of siblings/spouses aboard for each
#'   passenger (ranges from 0--8);
#'   * `parch` - integer giving the number of parents/children aboard for each
#'   passenger (ranges from 0--9).
#'
#' @source <https://hbiostat.org/data/>.
#'
#' @name titanic
#' @docType data
#' @keywords datasets
NULL


#' Survival of Titanic passengers
#'
#' The [titanic] data set contains 263 missing values (i.e., `NA`'s) in the
#' `age` column. This version of the data contains imputed values for the
#' `age` column using *multivariate imputation by chained equations* via
#' the [mice](https://cran.r-project.org/package=mice) package. Consequently,
#' this is a list containing 11 imputed versions of the observations contained
#' in the [titanic] data frame; each completed data set has the same dimension
#' and column structure as [titanic].
#'
#' @source
#' Greenwell, Brandon M. (2022). Tree-Based Methods for Statistical Learning in
#' R. CRC Press.
#'
#' @name titanic_mice
#' @docType data
#' @keywords datasets
NULL
