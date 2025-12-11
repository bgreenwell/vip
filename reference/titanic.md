# Survival of Titanic passengers

A data set containing the survival outcome, passenger class, age, sex,
and the number of family members for a large number of passengers aboard
the ill-fated Titanic.

## Format

A data frame with 1309 observations on the following 6 variables:

- `survived` - binary with levels `"yes"` for survived and `"no"`
  otherwise;

- `pclass` - integer giving the corresponding passenger (i.e., ticket)
  class with values 1–3;

- `age` - the age in years of the corresponding passenger (with 263
  missing values);

- `sex` - factor giving the sex of each passenger with levels `"male"`
  and `"female"`;

- `sibsp` - integer giving the number of siblings/spouses aboard for
  each passenger (ranges from 0–8);

- `parch` - integer giving the number of parents/children aboard for
  each passenger (ranges from 0–9).

## Source

<https://hbiostat.org/data/>.

## Note

As mentioned in the column description, `age` contains 263 `NA`s (or
missing values). For a complete version (or versions) of the data set,
see
[titanic_mice](https://koalaverse.github.io/vip/reference/titanic_mice.md).
