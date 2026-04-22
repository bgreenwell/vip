# Model-specific variable importance

Compute model-specific variable importance scores for the predictors in
a fitted model.

## Usage

``` r
vi_model(object, ...)

# Default S3 method
vi_model(object, ...)

# S3 method for class 'C5.0'
vi_model(object, type = c("usage", "splits"), ...)

# S3 method for class 'train'
vi_model(object, ...)

# S3 method for class 'cubist'
vi_model(object, ...)

# S3 method for class 'earth'
vi_model(object, type = c("nsubsets", "rss", "gcv"), ...)

# S3 method for class 'gbm'
vi_model(object, type = c("relative.influence", "permutation"), ...)

# S3 method for class 'glmnet'
vi_model(object, lambda = NULL, ...)

# S3 method for class 'cv.glmnet'
vi_model(object, lambda = NULL, ...)

# S3 method for class 'H2OBinomialModel'
vi_model(object, ...)

# S3 method for class 'H2OMultinomialModel'
vi_model(object, ...)

# S3 method for class 'H2ORegressionModel'
vi_model(object, ...)

# S3 method for class 'lgb.Booster'
vi_model(object, type = c("gain", "cover", "frequency"), ...)

# S3 method for class 'mixo_pls'
vi_model(object, ncomp = NULL, ...)

# S3 method for class 'mixo_spls'
vi_model(object, ncomp = NULL, ...)

# S3 method for class 'WrappedModel'
vi_model(object, ...)

# S3 method for class 'Learner'
vi_model(object, ...)

# S3 method for class 'nn'
vi_model(object, type = c("olden", "garson"), ...)

# S3 method for class 'nnet'
vi_model(object, type = c("olden", "garson"), ...)

# S3 method for class 'RandomForest'
vi_model(object, type = c("accuracy", "auc"), ...)

# S3 method for class 'constparty'
vi_model(object, ...)

# S3 method for class 'cforest'
vi_model(object, ...)

# S3 method for class 'mvr'
vi_model(object, ...)

# S3 method for class 'mixo_pls'
vi_model(object, ncomp = NULL, ...)

# S3 method for class 'mixo_spls'
vi_model(object, ncomp = NULL, ...)

# S3 method for class 'WrappedModel'
vi_model(object, ...)

# S3 method for class 'Learner'
vi_model(object, ...)

# S3 method for class 'randomForest'
vi_model(object, ...)

# S3 method for class 'ranger'
vi_model(object, ...)

# S3 method for class 'rpart'
vi_model(object, ...)

# S3 method for class 'mlp'
vi_model(object, type = c("olden", "garson"), ...)

# S3 method for class 'ml_model_decision_tree_regression'
vi_model(object, ...)

# S3 method for class 'ml_model_decision_tree_classification'
vi_model(object, ...)

# S3 method for class 'ml_model_gbt_regression'
vi_model(object, ...)

# S3 method for class 'ml_model_gbt_classification'
vi_model(object, ...)

# S3 method for class 'ml_model_generalized_linear_regression'
vi_model(object, ...)

# S3 method for class 'ml_model_linear_regression'
vi_model(object, ...)

# S3 method for class 'ml_model_random_forest_regression'
vi_model(object, ...)

# S3 method for class 'ml_model_random_forest_classification'
vi_model(object, ...)

# S3 method for class 'lm'
vi_model(object, type = c("stat", "raw"), ...)

# S3 method for class 'model_fit'
vi_model(object, ...)

# S3 method for class 'workflow'
vi_model(object, ...)

# S3 method for class 'xgb.Booster'
vi_model(object, type = c("gain", "cover", "frequency"), ...)
```

## Source

Johan Bring (1994) How to Standardize Regression Coefficients, The
American Statistician, 48:3, 209-213, DOI:
10.1080/00031305.1994.10476059.

## Arguments

- object:

  A fitted model object (e.g., a
  [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  object). See the details section below to see how variable importance
  is computed for supported model types.

- ...:

  Additional optional arguments to be passed on to other methods. See
  the details section below for arguments that can be passed to specific
  object types.

- type:

  Character string specifying the type of variable importance to return
  (only used for some models). See the details section below for which
  methods this argument applies to.

- lambda:

  Numeric value for the penalty parameter of a
  [glmnet](https://glmnet.stanford.edu/reference/glmnet.html) model
  (this is equivalent to the `s` argument in
  [coef.glmnet](https://glmnet.stanford.edu/reference/predict.glmnet.html)).
  See the section on
  [glmnet](https://glmnet.stanford.edu/reference/glmnet.html) in the
  details below.

- ncomp:

  An integer for the number of partial least squares components to be
  used in the importance calculations. If more components are requested
  than were used in the model, all of the model's components are used.

## Value

A tidy data frame (i.e., a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) object)
with two columns:

- `Variable` - the corresponding feature name;

- `Importance` - the associated importance, computed as the average
  change in performance after a random permutation (or permutations, if
  `nsim > 1`) of the feature in question.

For
[lm](https://rdrr.io/r/stats/lm.html)/[glm](https://rdrr.io/r/stats/glm.html)-like
objects, the sign (i.e., POS/NEG) of the original coefficient is also
included in a column called `Sign`.

## Details

Computes model-specific variable importance scores depending on the
class of `object`:

- [C5.0](https://topepo.github.io/C5.0/reference/C5.0.html) - Variable
  importance is measured by determining the percentage of training set
  samples that fall into all the terminal nodes after the split. For
  example, the predictor in the first split automatically has an
  importance measurement of 100 percent since all samples are affected
  by this split. Other predictors may be used frequently in splits, but
  if the terminal nodes cover only a handful of training set samples,
  the importance scores may be close to zero. The same strategy is
  applied to rule-based models and boosted versions of the model. The
  underlying function can also return the number of times each predictor
  was involved in a split by using the option `metric = "usage"`. See
  [C5imp](https://topepo.github.io/C5.0/reference/C5imp.html) for
  details.

- [cubist](http://topepo.github.io/Cubist/reference/cubist.default.md) -
  The Cubist output contains variable usage statistics. It gives the
  percentage of times where each variable was used in a condition and/or
  a linear model. Note that this output will probably be inconsistent
  with the rules shown in the output from summary.cubist. At each split
  of the tree, Cubist saves a linear model (after feature selection)
  that is allowed to have terms for each variable used in the current
  split or any split above it. Quinlan (1992) discusses a smoothing
  algorithm where each model prediction is a linear combination of the
  parent and child model along the tree. As such, the final prediction
  is a function of all the linear models from the initial node to the
  terminal node. The percentages shown in the Cubist output reflects all
  the models involved in prediction (as opposed to the terminal models
  shown in the output). The variable importance used here is a linear
  combination of the usage in the rule conditions and the model. See
  [summary.cubist](http://topepo.github.io/Cubist/reference/summary.cubist.md)
  and [varImp](https://rdrr.io/pkg/caret/man/varImp.html) for details.

- [glmnet](https://glmnet.stanford.edu/reference/glmnet.html) - Similar
  to (generalized) linear models, the absolute value of the coefficients
  are returned for a specific model. It is important that the features
  (and hence, the estimated coefficients) be standardized prior to
  fitting the model. You can specify which coefficients to return by
  passing the specific value of the penalty parameter via the `lambda`
  argument (this is equivalent to the `s` argument in
  [coef.glmnet](https://glmnet.stanford.edu/reference/predict.glmnet.html)).
  By default, `lambda = NULL` and the coefficients corresponding to the
  final penalty value in the sequence are returned; in other words, you
  should ALWAYS SPECIFY `lambda`! For
  [cv.glmnet](https://glmnet.stanford.edu/reference/cv.glmnet.html)
  objects, the largest value of lambda such that the error is within one
  standard error of the minimum is used by default. For a multinomial
  response, the coefficients corresponding to the first class are used;
  that is, the first component of
  [coef.glmnet](https://glmnet.stanford.edu/reference/predict.glmnet.html).

- [cforest](https://rdrr.io/pkg/partykit/man/cforest.html) - Variable
  importance is measured in a way similar to those computed by
  [importance](https://rdrr.io/pkg/randomForest/man/importance.html).
  Besides the standard version, a conditional version is available that
  adjusts for correlations between predictor variables. If
  `conditional = TRUE`, the importance of each variable is computed by
  permuting within a grid defined by the predictors that are associated
  (with 1 - *p*-value greater than threshold) to the variable of
  interest. The resulting variable importance score is conditional in
  the sense of beta coefficients in regression models, but represents
  the effect of a variable in both main effects and interactions. See
  Strobl et al. (2008) for details. Note, however, that all random
  forest results are subject to random variation. Thus, before
  interpreting the importance ranking, check whether the same ranking is
  achieved with a different random seed - or otherwise increase the
  number of trees ntree in
  [ctree_control](https://rdrr.io/pkg/partykit/man/ctree_control.html).
  Note that in the presence of missings in the predictor variables the
  procedure described in Hapfelmeier et al. (2012) is performed. See
  [varimp](https://rdrr.io/pkg/partykit/man/varimp.html) for details.

- [earth](https://rdrr.io/pkg/earth/man/earth.html) - The
  [earth](https://rdrr.io/pkg/earth/man/earth.html) package uses three
  criteria for estimating the variable importance in a MARS model (see
  [evimp](https://rdrr.io/pkg/earth/man/evimp.html) for details):

  - The `nsubsets` criterion (`type = "nsubsets"`) counts the number of
    model subsets that include each feature. Variables that are included
    in more subsets are considered more important. This is the criterion
    used by
    [summary.earth](https://rdrr.io/pkg/earth/man/summary.earth.html) to
    print variable importance. By "subsets" we mean the subsets of terms
    generated by `earth()`'s backward pass. There is one subset for each
    model size (from one to the size of the selected model) and the
    subset is the best set of terms for that model size. (These subsets
    are specified in the `$prune.terms` component of `earth()`'s return
    value.) Only subsets that are smaller than or equal in size to the
    final model are used for estimating variable importance. This is the
    default method used by vi_model.

  - The `rss` criterion (`type = "rss"`) first calculates the decrease
    in the RSS for each subset relative to the previous subset during
    `earth()`’s backward pass. (For multiple response models, RSS's are
    calculated over all responses.) Then for each variable it sums these
    decreases over all subsets that include the variable. Finally, for
    ease of interpretation the summed decreases are scaled so the
    largest summed decrease is 100. Variables which cause larger net
    decreases in the RSS are considered more important.

  - The `gcv` criterion (`type = "gcv"`) is similar to the `rss`
    approach, but uses the GCV statistic instead of the RSS. Note that
    adding a variable can sometimes increase the GCV. (Adding the
    variable has a deleterious effect on the model, as measured in terms
    of its estimated predictive power on unseen data.) If that happens
    often enough, the variable can have a negative total importance, and
    thus appear less important than unused variables.

- [gbm](https://rdrr.io/pkg/gbm/man/gbm.html) - Variable importance is
  computed using one of two approaches (See
  [summary.gbm](https://rdrr.io/pkg/gbm/man/summary.gbm.html) for
  details):

  - The standard approach (`type = "relative.influence"`) described in
    Friedman (2001). When `distribution = "gaussian"` this returns the
    reduction of squared error attributable to each variable. For other
    loss functions this returns the reduction attributable to each
    variable in sum of squared error in predicting the gradient on each
    iteration. It describes the *relative influence* of each variable in
    reducing the loss function. This is the default method used by
    vi_model.

  - An experimental permutation-based approach (`type = "permutation"`).
    This method randomly permutes each predictor variable at a time and
    computes the associated reduction in predictive performance. This is
    similar to the variable importance measures Leo Breiman uses for
    random forests, but [gbm](https://rdrr.io/pkg/gbm/man/gbm.html)
    currently computes using the entire training dataset (not the
    out-of-bag observations).

- [H2OModel](https://rdrr.io/pkg/h2o/man/H2OModel-class.html) - See
  [h2o.varimp](https://rdrr.io/pkg/h2o/man/h2o.varimp.html) or visit
  <https://docs.h2o.ai/h2o/latest-stable/h2o-docs/variable-importance.html>
  for details.

- [nnet](https://rdrr.io/pkg/nnet/man/nnet.html) - Two popular methods
  for constructing variable importance scores with neural networks are
  the Garson algorithm (Garson 1991), later modified by Goh (1995), and
  the Olden algorithm (Olden et al. 2004). For both algorithms, the
  basis of these importance scores is the network’s connection weights.
  The Garson algorithm determines variable importance by identifying all
  weighted connections between the nodes of interest. Olden’s algorithm,
  on the other hand, uses the product of the raw connection weights
  between each input and output neuron and sums the product across all
  hidden neurons. This has been shown to outperform the Garson method in
  various simulations. For DNNs, a similar method due to Gedeon (1997)
  considers the weights connecting the input features to the first two
  hidden layers (for simplicity and speed); but this method can be slow
  for large networks.. To implement the Olden and Garson algorithms, use
  `type = "olden"` and `type = "garson"`, respectively. See
  [garson](https://rdrr.io/pkg/NeuralNetTools/man/garson.html) and
  [olden](https://rdrr.io/pkg/NeuralNetTools/man/olden.html) for
  details.

- [lm](https://rdrr.io/r/stats/lm.html)/[glm](https://rdrr.io/r/stats/glm.html) -
  In (generalized) linear models, variable importance is typically based
  on the absolute value of the corresponding *t*-statistics (Bring,
  1994). For such models, the sign of the original coefficient is also
  returned. By default, `type = "stat"` is used; however, if the inputs
  have been appropriately standardized then the raw coefficients can be
  used with `type = "raw"`. Note that Bring (1994) provides motivation
  for using the absolute value of the associated *t*-statistics.

- [sparklyr](https://rdrr.io/pkg/sparklyr/man/ml_feature_importances.html) -
  The Spark ML library provides standard variable importance measures
  for tree-based methods (e.g., random forests). See
  [ml_feature_importances](https://rdrr.io/pkg/sparklyr/man/ml_feature_importances.html)
  for details.

- [randomForest](https://rdrr.io/pkg/randomForest/man/randomForest.html)
  Random forests typically provide two measures of variable importance.

  - The first measure is computed from permuting out-of-bag (OOB) data:
    for each tree, the prediction error on the OOB portion of the data
    is recorded (error rate for classification and MSE for regression).
    Then the same is done after permuting each predictor variable. The
    difference between the two are then averaged over all trees in the
    forest, and normalized by the standard deviation of the differences.
    If the standard deviation of the differences is equal to 0 for a
    variable, the division is not done (but the average is almost always
    equal to 0 in that case).

  - The second measure is the total decrease in node impurities from
    splitting on the variable, averaged over all trees. For
    classification, the node impurity is measured by the Gini index. For
    regression, it is measured by residual sum of squares.

  See [importance](https://rdrr.io/pkg/randomForest/man/importance.html)
  for details, including additional arguments that can be passed via the
  `...` argument in vi_model.

- [cforest](https://rdrr.io/pkg/party/man/cforest.html) - Same approach
  described in [cforest](https://rdrr.io/pkg/partykit/man/cforest.html)
  (from package **partykit**) above. See
  [varimp](https://rdrr.io/pkg/party/man/varimp.html) and
  [varimpAUC](https://rdrr.io/pkg/party/man/varimp.html) (if
  `type = "auc"`) for details.

- [ranger](http://imbs-hl.github.io/ranger/reference/ranger.md) -
  Variable importance for
  [ranger](http://imbs-hl.github.io/ranger/reference/ranger.md) objects
  is computed in the usual way for random forests. The approach used
  depends on the `importance` argument provided in the initial call to
  [ranger](http://imbs-hl.github.io/ranger/reference/ranger.md). See
  [importance](http://imbs-hl.github.io/ranger/reference/importance.ranger.md)
  for details.

- [rpart](https://rdrr.io/pkg/rpart/man/rpart.html) - As stated in one
  of the [rpart](https://rdrr.io/pkg/rpart/man/rpart.html) vignettes. A
  variable may appear in the tree many times, either as a primary or a
  surrogate variable. An overall measure of variable importance is the
  sum of the goodness of split measures for each split for which it was
  the primary variable, plus "goodness" \* (adjusted agreement) for all
  splits in which it was a surrogate. Imagine two variables which were
  essentially duplicates of each other; if we did not count surrogates,
  they would split the importance with neither showing up as strongly as
  it should. See [rpart](https://rdrr.io/pkg/rpart/man/rpart.html) for
  details.

- [caret](https://rdrr.io/pkg/caret/man/train.html) - Various
  model-specific and model-agnostic approaches that depend on the
  learning algorithm employed in the original call to
  [caret](https://rdrr.io/pkg/caret/man/train.html). See
  [varImp](https://rdrr.io/pkg/caret/man/varImp.html) for details.

- [xgboost](https://rdrr.io/pkg/xgboost/man/xgboost.html) - For linear
  models, the variable importance is the absolute magnitude of the
  estimated coefficients. For that reason, in order to obtain a
  meaningful ranking by importance for a linear model, the features need
  to be on the same scale (which you also would want to do when using
  either L1 or L2 regularization). Otherwise, the approach described in
  Friedman (2001) for [gbm](https://rdrr.io/pkg/gbm/man/gbm.html)s is
  used. See
  [xgb.importance](https://rdrr.io/pkg/xgboost/man/xgb.importance.html)
  for details. For tree models, you can obtain three different types of
  variable importance:

  - Using `type = "gain"` (the default) gives the fractional
    contribution of each feature to the model based on the total gain of
    the corresponding feature's splits.

  - Using `type = "cover"` gives the number of observations related to
    each feature.

  - Using `type = "frequency"` gives the percentages representing the
    relative number of times each feature has been used throughout each
    tree in the ensemble.

- [lightgbm](https://rdrr.io/pkg/lightgbm/man/lightgbm.html) - Same as
  for [xgboost](https://rdrr.io/pkg/xgboost/man/xgboost.html) models,
  except
  [lgb.importance](https://rdrr.io/pkg/lightgbm/man/lgb.importance.html)
  (which this method calls internally) has an additional argument,
  `percentage`, that defaults to `TRUE`, resulting in the VI scores
  shown as a relative percentage; pass `percentage = FALSE` in the call
  to `vi_model()` to produce VI scores for
  [lightgbm](https://rdrr.io/pkg/lightgbm/man/lightgbm.html) models on
  the raw scale.

## Note

Inspired by the [caret](https://cran.r-project.org/package=caret)'s
[varImp](https://rdrr.io/pkg/caret/man/varImp.html) function.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic example using imputed titanic data set
t3 <- titanic_mice[[1L]]

# Fit a simple model
set.seed(1449)  # for reproducibility
bst <- lightgbm::lightgbm(
  data = data.matrix(subset(t3, select = -survived)),
  label = ifelse(t3$survived == "yes", 1, 0),
  params = list("objective" = "binary", "force_row_wise" = TRUE),
  verbose = 0
)

# Compute VI scores
vi(bst)  # defaults to `method = "model"`
vi_model(bst)  # same as above

# Same as above (since default is `method = "model"`), but returns a plot
vip(bst, geom = "point")
vi_model(bst, type = "cover")
vi_model(bst, type = "cover", percentage = FALSE)

# Compare to
lightgbm::lgb.importance(bst)
} # }
```
