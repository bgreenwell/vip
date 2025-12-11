# Variance-based variable importance

Compute variance-based variable importance (VI) scores using a simple
*feature importance ranking measure* (FIRM) approach; for details, see
[Greenwell et al. (2018)](https://arxiv.org/abs/1805.04755) and
[Scholbeck et al. (2019)](https://arxiv.org/abs/1904.03959).

## Usage

``` r
vi_firm(object, ...)

# Default S3 method
vi_firm(
  object,
  feature_names = NULL,
  train = NULL,
  var_fun = NULL,
  var_continuous = stats::sd,
  var_categorical = function(x) diff(range(x))/4,
  ...
)
```

## Arguments

- object:

  A fitted model object (e.g., a
  [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  object).

- ...:

  Additional arguments to be passed on to the
  [`pdp::partial()`](https://rdrr.io/pkg/pdp/man/partial.html) function
  (e.g., `ice = TRUE`, `prob = TRUE`, or a prediction wrapper via the
  `pred.fun` argument); see
  [`?pdp::partial`](https://rdrr.io/pkg/pdp/man/partial.html) for
  details on these and other useful arguments.

- feature_names:

  Character string giving the names of the predictor variables (i.e.,
  features) of interest. If `NULL` (the default) then the internal
  [`get_feature_names()`](https://koalaverse.github.io/vip/reference/get_feature_names.md)
  function will be called to try and extract them automatically. It is
  good practice to always specify this argument.

- train:

  A matrix-like R object (e.g., a data frame or matrix) containing the
  training data. If `NULL` (the default) then the internal
  `get_training_data()` function will be called to try and extract it
  automatically. It is good practice to always specify this argument.

- var_fun:

  Deprecated; use `var_continuous` and `var_categorical` instead.

- var_continuous:

  Function used to quantify the variability of effects for continuous
  features. Defaults to using the sample standard deviation (i.e.,
  [`stats::sd()`](https://rdrr.io/r/stats/sd.html)).

- var_categorical:

  Function used to quantify the variability of effects for categorical
  features. Defaults to using the range divided by four; that is,
  `function(x) diff(range(x)) / 4`.

## Value

A tidy data frame (i.e., a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) object)
with two columns:

- `Variable` - the corresponding feature name;

- `Importance` - the associated importance, computed as described in
  [Greenwell et al. (2018)](https://arxiv.org/abs/1805.04755).

## Details

This approach is based on quantifying the relative "flatness" of the
effect of each feature and assumes the user has some familiarity with
the [`pdp::partial()`](https://rdrr.io/pkg/pdp/man/partial.html)
function. The Feature effects can be assessed using *partial dependence*
(PD) plots (Friedman, 2001) or *individual conditional expectation*
(ICE) plots (Goldstein et al., 2014). These methods are model-agnostic
and can be applied to any supervised learning algorithm. By default,
relative "flatness" is defined by computing the standard deviation of
the y-axis values for each feature effect plot for numeric features; for
categorical features, the default is to use range divided by 4. This can
be changed via the `var_continuous` and `var_categorical` arguments. See
[Greenwell et al. (2018)](https://arxiv.org/abs/1805.04755) for details
and additional examples.

## Note

This approach can provide misleading results in the presence of
interaction effects (akin to interpreting main effect coefficients in a
linear with higher level interaction effects).

## References

J. H. Friedman. Greedy function approximation: A gradient boosting
machine. *Annals of Statistics*, **29**: 1189-1232, 2001.

Goldstein, A., Kapelner, A., Bleich, J., and Pitkin, E., Peeking Inside
the Black Box: Visualizing Statistical Learning With Plots of Individual
Conditional Expectation. (2014) *Journal of Computational and Graphical
Statistics*, **24**(1): 44-65, 2015.

Greenwell, B. M., Boehmke, B. C., and McCarthy, A. J. A Simple and
Effective Model-Based Variable Importance Measure. arXiv preprint
arXiv:1805.04755 (2018).

Scholbeck, C. A. Scholbeck, and Molnar, C., and Heumann C., and Bischl,
B., and Casalicchio, G. Sampling, Intervention, Prediction, Aggregation:
A Generalized Framework for Model-Agnostic Interpretations. arXiv
preprint arXiv:1904.03959 (2019).

## Examples

``` r
if (FALSE) { # \dontrun{
#
# A projection pursuit regression example
#

# Load the sample data
data(mtcars)

# Fit a projection pursuit regression model
mtcars.ppr <- ppr(mpg ~ ., data = mtcars, nterms = 1)

# Compute variable importance scores using the FIRM method; note that the pdp
# package knows how to work with a "ppr" object, so there's no need to pass
# the training data or a prediction wrapper, but it's good practice.
vi_firm(mtcars.ppr, train = mtcars)

# For unsopported models, need to define a prediction wrapper; this approach
# will work for ANY model (supported or unsupported, so better to just always
# define it pass it)
pfun <- function(object, newdata) {
  # To use partial dependence, this function needs to return the AVERAGE
  # prediction (for ICE, simply omit the averaging step)
  mean(predict(object, newdata = newdata))
}

# Equivalent to the previous results (but would work if this type of model
# was not explicitly supported)
vi_firm(mtcars.ppr, pred.fun = pfun, train = mtcars)

# Equivalent VI scores, but the output is sorted by default
vi(mtcars.ppr, method = "firm")

# Use MAD to estimate variability of the partial dependence values
vi_firm(mtcars.ppr, var_continuous = stats::mad)

# Plot VI scores
vip(mtcars.ppr, method = "firm", train = mtcars, pred.fun = pfun)
} # }
```
