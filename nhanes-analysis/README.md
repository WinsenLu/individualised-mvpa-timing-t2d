# NHANES 2011–2014 main analysis for individualised MVPA timing

This repository contains R code for the **fully adjusted primary NHANES 2011–2014 analysis (Model 3 only)** in the study:

> *Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES*

The primary exposure is:

```text
sleep_anchored_mvpa_phase_h
```

and is modelled continuously per 1-h later individualised MVPA timing.

## Scope

The repository runs Model 3 only for five outcomes:

1. prevalent diabetes;
2. HbA1c;
3. fasting glucose;
4. fasting insulin;
5. 2-h OGTT glucose.

It includes:

- multiple imputation by chained equations (MICE);
- 20 imputed data sets for every outcome;
- NHANES complex-survey design;
- survey-weighted logistic regression for prevalent diabetes;
- survey-weighted linear regression for natural-log-transformed glycaemic measures;
- Rubin pooling using `mitools::MIcombine()`;
- odds ratios for prevalent diabetes;
- percentage differences for log-transformed glycaemic outcomes.

Models 1 and 2, restricted cubic spline analyses, and P values for nonlinearity are outside the scope of this public repository.

## Analysis environment

The study analyses were conducted in:

```text
R 4.3.1
```

Required packages:

```text
mice
survey
mitools
```

The scripts do not install packages automatically.

## Outcomes and survey weights

| Outcome | Analysis variable | Regression | Survey weight |
|---|---|---|---|
| Prevalent diabetes | `prevalent_diabetes` | Survey-weighted logistic regression | `WTMEC4YR` |
| HbA1c | `ln_LBXGH = log(LBXGH)` | Survey-weighted linear regression | `WTMEC4YR` |
| Fasting glucose | `ln_LBXGLU = log(LBXGLU)` | Survey-weighted linear regression | `WTSAF4YR` |
| Fasting insulin | `ln_fasting_insulin = log(LBXIN_RocheEq)` | Survey-weighted linear regression | `WTSAF4YR` |
| 2-h OGTT glucose | `ln_LBXGLT = log(LBXGLT)` | Survey-weighted linear regression | `WTSOG4YR` |

Variable definitions and coding are specified in `INPUT_DATA_DICTIONARY.md`.

## Fully adjusted Model 3

The only regression model fitted is:

```text
sleep_anchored_mvpa_phase_h
+ age
+ sex
+ race/ethnicity
+ education
+ household income
+ smoking
+ alcohol
+ total energy intake
+ Healthy Eating Index
+ mean MVPA minutes per valid day
+ mean sleep duration
```

## Missing-data strategy

Only the following six covariates are imputed:

```text
education_binary
household_income_binary
smoking_binary
alcohol_binary
total_energy_intake_kcal
HEI_score
```

Imputation methods:

```text
education_binary          -> logreg
household_income_binary   -> logreg
smoking_binary            -> logreg
alcohol_binary            -> logreg
total_energy_intake_kcal  -> pmm
HEI_score                 -> pmm
```

For every outcome:

```text
m = 20
maxit = 20
```

The imputation predictor set includes:

- NHANES cycle;
- the corresponding outcome;
- the primary exposure;
- age;
- sex;
- race/ethnicity;
- the six partially observed covariates;
- MVPA;
- sleep duration;
- the outcome-specific survey weight; and
- survey stratum as an auxiliary factor.

`SEQN` is never used as an imputation predictor. `SDMVPSU` is not used as an imputation predictor.

For continuous outcomes, the raw outcome is retained for validation but is not used as an imputation predictor; the natural-log-transformed outcome is used instead.

## Survey design

Each completed imputed data set is converted separately to an NHANES survey design:

```r
svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~OUTCOME_SPECIFIC_WEIGHT,
  nest = TRUE,
  data = completed_data
)
```

The analysis retains:

```r
options(survey.lonely.psu = "adjust")
```

## Effect estimates

For prevalent diabetes:

```text
OR = exp(beta)
```

For natural-log-transformed glycaemic outcomes:

```text
percentage difference = 100 * [exp(beta) - 1]
```

with confidence limits transformed in the same way.

## Repository structure

```text
.
|-- .gitattributes
|-- .gitignore
|-- CITATION.cff
|-- CODE_AVAILABILITY.md
|-- DEPENDENCIES.md
|-- EXPOSURE_MAPPING.md
|-- INPUT_DATA_DICTIONARY.md
|-- LICENSE
|-- README.md
|-- config/
|   |-- config.example.R
|-- R/
|   |-- 00_utils.R
|   |-- 01_outcome_specifications.R
|   |-- 02_prepare_analysis_data.R
|   |-- 03_multiple_imputation.R
|   |-- 04_survey_model.R
|   |-- 05_run_one_outcome.R
|   |-- 06_run_all_main_analyses.R
|-- tests/
|   |-- run_integration_tests.R
|   |-- run_synthetic_tests.R
|-- tools/
|   |-- check_environment.R
|   |-- check_public_repo.R
|   |-- validate.R
```

## Private input files

Example semantic filenames are:

```text
nhanes_prevalent_diabetes_analysis.csv
nhanes_hba1c_analysis.csv
nhanes_fasting_glucose_analysis.csv
nhanes_fasting_insulin_analysis.csv
nhanes_ogtt_analysis.csv
```

Researchers map their own local analysis-ready files to paths in private `config/config.R`.

No participant-level analysis file is included in this repository.

## Configuration

Copy:

```text
config/config.example.R
```

to:

```text
config/config.R
```

and edit the private paths.

## Run

From the repository root:

```bash
Rscript R/06_run_all_main_analyses.R
```

The script runs the fully adjusted Model 3 for all five outcomes.

## Main outputs

For each outcome:

```text
<outcome>_model3_all_terms.csv
<outcome>_model3_exposure_result.csv
```

Combined primary exposure results:

```text
nhanes_model3_results.csv
```

No manuscript result values are hard-coded as validation targets.

## Reproducibility boundary

This repository starts from the study's outcome-specific analysis-ready datasets. It does not perform upstream NHANES source-file downloads, exposure derivation, dietary-variable derivation, outcome ascertainment, or sample-selection files.

The separate exposure-derivation code should be used to construct `sleep_anchored_mvpa_phase_h`.

## Licence

This software is distributed under the [MIT License](LICENSE). The licence applies to the code and documentation; access to study data is governed separately.

## Installation and validation

See [DEPENDENCIES.md](DEPENDENCIES.md) for package installation and the distinction between the study and validation environments. Run the following commands from this repository root before configuring study inputs:

```bash
Rscript --vanilla tools/check_environment.R
Rscript --vanilla tools/validate.R
```

The validation script parses every R file, loads the example configuration and runs synthetic tests. It does not use study participants or establish numerical reproduction of the manuscript. The data contracts describe the required upstream preparation.

## Citation

Software citation metadata are provided in [CITATION.cff](CITATION.cff). When reporting results, also cite the associated study identified above.

See [EXPOSURE_MAPPING.md](EXPOSURE_MAPPING.md) for connecting the exposure output to the analysis input.
