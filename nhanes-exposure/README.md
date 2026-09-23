# NHANES individualised sleep-anchored MVPA timing exposure derivation

This repository contains R code used to derive the **individualised, sleep-anchored timing of moderate-to-vigorous physical activity (MVPA)** in the US National Health and Nutrition Examination Survey (NHANES) 2011–2014 component of the study:

> *Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES*

The repository is deliberately focused on **accelerometer exposure derivation**. It does not include glycaemic outcomes, survey-weighted regression models, multiple imputation, dietary covariates, or other downstream epidemiological analyses.

## Analysis environment

The study exposure derivation used:

- **R 4.3.1**
- **GGIR 3.0.0**
- NHANES PAX80 raw wrist accelerometry sampled at **80 Hz**
- HDCZA sleep detection
- 5-s short epochs for GGIR sleep processing
- 60-s ENMO epochs for the primary MVPA definition

The public code does not install packages automatically. The required packages are:

```text
GGIR
data.table
R.utils
future
future.apply
parallelly
```

## Primary exposure definition

The exposure is the forward interval from the participant-specific habitual sleep midpoint \(S\) to the circular centroid of the participant's habitual 24-h MVPA distribution \(M\):

```text
sleep_anchored_mvpa_phase_h = (M - S) mod 24
```

Higher values represent later habitual MVPA timing relative to the participant's habitual sleep midpoint.

### MVPA derivation

Raw NHANES PAX80 acceleration is processed in GGIR 3.0.0.

The study algorithm uses:

```text
Raw 80-Hz acceleration
    ↓
GGIR short epoch = 5 s
    ↓
ENMO
    ↓
GGIR Part 5 aggregation to 60-s epochs
    ↓
Valid 60-s epoch with mean ENMO ≥100 mg = MVPA
    ↓
Retain epochs from valid days only
(valid day = ≥16 h valid accelerometer data)
    ↓
Aggregate MVPA minutes by minute-of-day across valid days
    ↓
1,440-min habitual MVPA distribution
    ↓
Circular centroid M
+
resultant vector length R
```

For minute-of-day \(j = 0,\ldots,1439\), the temporal midpoint is:

```text
hour_midpoint_j = (j + 0.5) / 60
```

The circular centroid is weighted by the **number of MVPA minutes observed at each minute-of-day position across valid days**.

### Habitual sleep midpoint

The participant-level GGIR file:

```text
part4_nightsummary_sleep_cleaned.csv
```

is used to derive habitual sleep timing.

For each retained night:

```text
nightly_sleep_midpoint_h = ((sleeponset + wakeup) / 2) mod 24
```

The habitual sleep midpoint \(S\) is the circular mean of the nightly sleep midpoints.

### Exposure-related quality control

The primary phase is retained only when all of the following study criteria are satisfied:

- at least **5 valid accelerometer days**;
- each valid day contains at least **16 h** of valid accelerometer data;
- at least **3 valid nights**;
- mean sleep duration between **3 and 12 h**, inclusive;
- mean number of sleep periods between **5 and 30**, inclusive;
- at least one MVPA minute;
- MVPA resultant vector length **R ≥0.30**;
- finite sleep-anchored phase angle.

These criteria are part of the exposure-derivation pipeline. Other cohort-selection criteria described in the manuscript, such as age and pregnancy eligibility, are upstream epidemiological sample-selection steps and are not recreated in this exposure-only repository.

## Repository structure

```text
.
|-- .gitattributes
|-- .gitignore
|-- CITATION.cff
|-- CODE_AVAILABILITY.md
|-- DEPENDENCIES.md
|-- INPUT_DATA_DICTIONARY.md
|-- LICENSE
|-- README.md
|-- config/
|   |-- config.example.R
|-- R/
|   |-- 00_utils.R
|   |-- 01_prepare_pax80_input.R
|   |-- 02_run_ggir.R
|   |-- 03_derive_sleep_midpoint.R
|   |-- 04_derive_mvpa_phase.R
|   |-- 05_derive_sleep_anchored_phase.R
|   |-- 06_process_participant.R
|   |-- 07_batch_process.R
|-- tests/
|   |-- run_integration_tests.R
|   |-- run_synthetic_tests.R
|-- tools/
|   |-- check_environment.R
|   |-- check_public_repo.R
|   |-- validate.R
```

## Expected private input layout

Each participant archive contains multiple hourly raw sensor files with the header:

```text
HEADER_TIMESTAMP,X,Y,Z
```

The public pipeline expects participant archive names beginning with the NHANES sequence identifier and using one of the following formats:

```text
<SEQN>.tar
<SEQN>.tar.bz2
<SEQN>.tar.gz
<SEQN>.tar.xz
<SEQN>.tbz2
<SEQN>.tgz
<SEQN>.txz
```

No real participant archive is included in this repository.

## Configuration

Copy:

```text
config/config.example.R
```

to:

```text
config/config.R
```

and edit the local paths.

`config/config.R` is ignored by Git.

## Running the exposure pipeline

Run from the repository root.

### 1. Check the configuration

```bash
Rscript R/07_batch_process.R
```

The batch script:

1. discovers participant archives;
2. processes independent participants in parallel;
3. creates a temporary combined raw file per participant;
4. runs GGIR 3.0.0;
5. derives habitual sleep midpoint \(S\);
6. derives habitual MVPA centroid \(M\) and resultant vector length \(R\);
7. calculates the sleep-anchored phase angle;
8. applies the exposure-related QC criteria;
9. writes one compact participant-level result per participant;
10. rebuilds a master exposure table.

The raw source archives are never deleted.

## Output

The participant-level master output contains, among other processing variables:

```text
SEQN
n_valid_days
n_valid_nights
observed_total_mvpa_minutes
mean_mvpa_minutes_per_valid_day
habitual_mvpa_phase_h
mvpa_resultant_length_R
habitual_sleep_midpoint_h
sleep_midpoint_resultant_length_R
mean_sleep_duration_h
mean_number_sleep_periods
sleep_anchored_mvpa_phase_raw_h
sleep_anchored_mvpa_phase_h
include_primary
exclusion_reason
```

`SEQN` is the public NHANES sequence identifier. The repository contains code only and does not distribute participant-level output tables.

## Synthetic tests

Formula-level tests use artificial values only:

```bash
Rscript tests/run_synthetic_tests.R
```

They check:

- circular averaging across midnight;
- modulo-24 phase-angle calculation;
- the 100-mg MVPA threshold boundary;
- a uniform 24-h distribution producing \(R \approx 0\);
- a concentrated distribution producing the expected centroid.

## Reproducibility boundary

This repository implements the following exposure computation:

```text
NHANES PAX80 raw accelerometry
→ GGIR 3.0.0
→ valid 60-s ENMO epochs
→ valid-day filtering
→ habitual 1,440-min MVPA distribution
→ circular centroid M and R
→ GGIR/HDCZA night-level sleep timing
→ circular habitual sleep midpoint S
→ (M - S) mod 24
→ exposure QC
```

Downstream outcome modelling is provided separately in the NHANES main-analysis repository.

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
