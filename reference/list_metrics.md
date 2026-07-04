# List metrics

List all available performance metrics.

## Usage

``` r
list_metrics()
```

## Value

A data frame with the following columns:

- `metric` - the optimization or tuning metric;

- `description` - a brief description about the metric;

- `task` - whether the metric is suitable for regression or
  classification;

- `smaller_is_better` - logical indicating whether or not a smaller
  value of the metric is considered better.

- `yardstick_function` - the name of the corresponding vector function
  from the
  [yardstick](https://yardstick.tidymodels.org/reference/yardstick-package.html)
  package.

## Examples

``` r
(metrics <- list_metrics())
#>          metric                              description
#> 1      accuracy                  Classification accuracy
#> 2  bal_accuracy         Balanced classification accuracy
#> 3        youden Youden's index (or Youden's J statistic)
#> 4       roc_auc                     Area under ROC curve
#> 5        pr_auc   Area under precision-recall (PR) curve
#> 6       logloss                                 Log loss
#> 7         brier                              Brier score
#> 8           mae                      Mean absolute error
#> 9          mape           Mean absolute percentage error
#> 10         rmse                  Root mean squared error
#> 11          rsq                  R-squared (correlation)
#> 12     rsq_trad                  R-squared (traditional)
#>                                task smaller_is_better yardstick_function
#> 1  Binary/multiclass classification             FALSE       accuracy_vec
#> 2  Binary/multiclass classification             FALSE   bal_accuracy_vec
#> 3  Binary/multiclass classification             FALSE        j_index_vec
#> 4             Binary classification             FALSE        roc_auc_vec
#> 5             Binary classification             FALSE         pr_auc_vec
#> 6  Binary/multiclass classification              TRUE    mn_log_loss_vec
#> 7  Binary/multiclass classification              TRUE    brier_class_vec
#> 8                        Regression              TRUE            mae_vec
#> 9                        Regression              TRUE           mape_vec
#> 10                       Regression              TRUE           rmse_vec
#> 11                       Regression             FALSE            rsq_vec
#> 12                       Regression             FALSE       rsq_trad_vec
metrics[metrics$task == "Binary classification", ]
#>    metric                            description                  task
#> 4 roc_auc                   Area under ROC curve Binary classification
#> 5  pr_auc Area under precision-recall (PR) curve Binary classification
#>   smaller_is_better yardstick_function
#> 4             FALSE        roc_auc_vec
#> 5             FALSE         pr_auc_vec
```
