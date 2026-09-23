# UK Biobank main Cox analysis for individualised MVPA timing

This repository contains the R code for the **primary UK Biobank Cox regression analysis** in the study:

> *Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES*

The code fits the four progressively adjusted Cox proportional hazards models specified in the manuscript for:

1. sleep-anchored MVPA timing quintiles (`Exposure`, Q1–Q5; Q1 reference); and
2. continuous sleep-anchored MVPA timing (`Phase_angle_hour`, per 1-h later timing).

The repository does **not** contain UK Biobank participant-level data and does not include restricted cubic spline, subgroup, sensitivity, joint timing-volume, or model-performance analyses.

## UK Biobank data-governance notice

No participant-level UK Biobank data should be committed to this repository.

Keep all input files containing UK Biobank data outside the public repository directory. Do not commit:

- eIDs or other participant identifiers;
- participant-level phenotype or outcome files;
- dates of diagnosis, death, loss to follow-up, or accelerometer wear;
- participant-level exposure or covariate values;
- multiple-imputation objects containing participant-level data;
- participant-level model matrices, residuals, predictions, or completed data sets;
- local logs or screenshots containing participant-level values.

The supplied `.gitignore` and repository-check script are safeguards only. Review the complete Git history using the current UK Biobank repository guidance and audit tools before publication.

## Analysis scope

The analysis implemented here is:

```text
Private participant-level UK Biobank analysis file
    ↓
derive follow-up and incident T2D event indicator
    ↓
derive Nelson–Aalen cumulative hazard H0
    ↓
multiple imputation by chained equations
m = 20, maxit = 5
    ↓
fit Cox models in each imputed data set
    ↓
pool coefficients using Rubin's rules
    ↓
report HRs, 95% CIs and P values
```

Missing covariates are imputed using predictive mean matching (`pmm`) within MICE.

The MICE predictor set includes:

- event indicator;
- follow-up time;
- Nelson–Aalen cumulative hazard estimate (`H0`);
- quintile exposure (`Exposure`);
- continuous exposure (`Phase_angle_hour`);
- all covariates used across Models 1–4; and
- `R_MVPA` as the auxiliary variable.

`valid_wear_days` is **not** included in the imputation model.

## Follow-up definition

Baseline is the end of accelerometer wear (`Baseline_Date`).

Incident type 2 diabetes is the first recorded E11 diagnosis occurring:

- after baseline; and
- on or before the applicable study end date.

Administrative censoring is country-specific:

```text
England  -> 2023-03-31
Scotland -> 2022-08-31
Wales    -> 2022-05-31
```

Follow-up ends at the earliest of:

- incident E11 diagnosis;
- death;
- loss to follow-up; or
- country-specific administrative censoring.

Participants with non-positive follow-up time are excluded before multiple imputation.

## Exposure definitions

### Quintile exposure

`Exposure` is an ordered timing classification:

```text
Q1
Q2
Q3
Q4
Q5
```

`Q1` is the reference group.

### Continuous exposure

`Phase_angle_hour` is modelled continuously.

The coefficient is interpreted per **1-h later individualised MVPA timing**.

## Four Cox models

### Model 1

Adjusted for:

- age;
- sex;
- ethnicity.

### Model 2

Model 1 plus:

- Townsend deprivation index;
- education;
- occupation and shift-work status;
- smoking status;
- alcohol intake;
- coffee and tea intake;
- healthy diet score;
- accelerometer wear season.

### Model 3

Model 2 plus:

- family history of diabetes;
- hypertension;
- dyslipidaemia;
- depression;
- cardiovascular disease.

### Model 4

Model 3 plus:

- total MVPA volume;
- sleep duration.

BMI is not included in the primary models.

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
|   |-- 01_prepare_survival_data.R
|   |-- 02_multiple_imputation.R
|   |-- 03_model_specifications.R
|   |-- 04_fit_primary_cox_models.R
|   |-- 05_run_main_analysis.R
|-- tests/
|   |-- run_synthetic_tests.R
|-- tools/
|   |-- check_environment.R
|   |-- check_public_repo.R
|   |-- validate.R
```

## Required R packages

The public script does not install packages automatically.

Required packages:

```text
survival
mice
```

The study analyses were conducted in R 4.3.1.

## Configuration

Copy:

```text
config/config.example.R
```

to:

```text
config/config.R
```

Then edit the private input and output paths.

`config/config.R` is ignored by Git.

The input file must remain in an authorised UK Biobank environment and must not be copied into this repository.

## Run

From the repository root:

```bash
Rscript R/05_run_main_analysis.R
```

The script writes only pooled model summaries and session information to the configured private output directory.

The main output files are:

```text
ukb_primary_cox_all_terms.csv
ukb_primary_cox_exposure_terms.csv
sessionInfo.txt
```

These files are generated locally and are not included in this public repository.

## Primary output interpretation

For quintile models, the exposure rows are:

```text
ExposureQ2
ExposureQ3
ExposureQ4
ExposureQ5
```

with Q1 as the reference.

For continuous models, the exposure row is:

```text
Phase_angle_hour
```

and represents the HR per 1-h later timing.

The P value from the continuous `Phase_angle_hour` coefficient corresponds to the linear trend test used for the primary Cox models.

## Reproducibility boundary

This repository covers only the primary Cox analyses based on:

```text
quintile exposure + continuous exposure
×
Models 1–4
×
MICE with 20 imputations
×
Rubin pooling
```

Restricted cubic spline analyses and P values for nonlinearity are outside this repository's scope.

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
