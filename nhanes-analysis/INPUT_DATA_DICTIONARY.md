# Private input data dictionary

The repository uses five outcome-specific analysis-ready files.

Example semantic filenames:

```text
nhanes_prevalent_diabetes_analysis.csv
nhanes_hba1c_analysis.csv
nhanes_fasting_glucose_analysis.csv
nhanes_fasting_insulin_analysis.csv
nhanes_ogtt_analysis.csv
```

The actual local filenames may differ and are mapped in private `config/config.R`.

## Common variables

| Variable | Role |
|---|---|
| `SEQN` | NHANES participant sequence identifier; never used as an imputation predictor |
| `cycle` | NHANES cycle: `2011-2012` or `2013-2014` |
| `sleep_anchored_mvpa_phase_h` | Primary exposure, continuous hours in [0, 24) |
| `RIDAGEYR` | Age in years |
| `sex_model` | Sex model variable; reference = Male |
| `race4` | Four-category race/ethnicity variable; reference = Non-Hispanic White |
| `education_binary` | Education; reference = Others |
| `household_income_binary` | Household income; reference = `>= $20k` |
| `smoking_binary` | Smoking; reference = No |
| `alcohol_binary` | Alcohol intake; reference = No |
| `total_energy_intake_kcal` | Total energy intake, kcal/day |
| `HEI_score` | Healthy Eating Index score, 0–100 |
| `mean_mvpa_minutes_per_valid_day` | Mean MVPA minutes per valid accelerometer day |
| `mean_sleep_duration_h` | Mean sleep duration in hours |
| `SDMVSTRA` | NHANES masked variance pseudo-stratum |
| `SDMVPSU` | NHANES masked variance pseudo-PSU |

## Outcome-specific variables

### Prevalent diabetes

Required:

```text
prevalent_diabetes
WTMEC4YR
```

`prevalent_diabetes` is coded:

```text
0 = no diabetes
1 = diabetes
```

If `sex_model` and `race4` are not already present, the code can recreate them when the following source variables are available:

```text
sex
race_ethnicity
```

### HbA1c

Required:

```text
LBXGH
ln_LBXGH
WTMEC4YR
```

Validation:

```text
ln_LBXGH = log(LBXGH)
```

### Fasting glucose

Required:

```text
LBXGLU
ln_LBXGLU
WTSAF4YR
```

Validation:

```text
ln_LBXGLU = log(LBXGLU)
```

### Fasting insulin

Required:

```text
LBXIN_RocheEq
ln_fasting_insulin
WTSAF4YR
```

Validation:

```text
ln_fasting_insulin = log(LBXIN_RocheEq)
```

### 2-h OGTT glucose

Required:

```text
LBXGLT
ln_LBXGLT
WTSOG4YR
```

Validation:

```text
ln_LBXGLT = log(LBXGLT)
```

## Four-year survey weights

The analysis-ready files are expected to contain the already derived 4-year weights:

```text
WTMEC4YR
WTSAF4YR
WTSOG4YR
```

The main-analysis scripts do not reconstruct the 4-year weights.

## Variables allowed to be missing before MICE

Only:

```text
education_binary
household_income_binary
smoking_binary
alcohol_binary
total_energy_intake_kcal
HEI_score
```

All outcome, exposure, demographic, MVPA, sleep and survey-design variables required by a given analysis must already be complete.

## Model 3 covariates

The public code fits only:

```text
sleep_anchored_mvpa_phase_h
+ RIDAGEYR
+ sex_model
+ race4
+ education_binary
+ household_income_binary
+ smoking_binary
+ alcohol_binary
+ total_energy_intake_kcal
+ HEI_score
+ mean_mvpa_minutes_per_valid_day
+ mean_sleep_duration_h
```
