# Individualised timing of the 24-h MVPA distribution — UK Biobank exposure derivation

This repository contains the R code used to derive the **individualised, sleep-anchored timing of moderate-to-vigorous physical activity (MVPA)** in the UK Biobank component of the study:

> *Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES*

The repository is intentionally limited to **exposure derivation**. It does not redistribute UK Biobank participant-level data and does not contain the complete incident type 2 diabetes outcome ascertainment or regression-analysis pipeline.

## Important UK Biobank data-governance notice

**Do not commit or upload any UK Biobank participant-level data to this repository.**

This includes, but is not limited to:

- participant identifiers or eIDs;
- raw `.cwa` accelerometer files;
- GGIR participant-level outputs;
- `part4_nightsummary_sleep_cleaned.csv`;
- phenotype extracts containing UK Biobank participant-level values;
- participant-level derived sleep, MVPA, centroid, resultant-vector, phase-angle, or quintile data;
- logs, notebooks, screenshots, or cached files that reveal participant-level information.

All participant-level inputs and outputs must remain inside an authorised UK Biobank research environment. The supplied `.gitignore` is a safeguard, not a substitute for manual review or UK Biobank's repository-audit procedures.

## Analysis environment

The study exposure was derived using:

- **R 4.3.1**
- **GGIR 3.0.0**
- HDCZA sleep detection via `GGIR(..., def.noc.sleep = 1)`

The downstream exposure scripts use base R only.

## Exposure definition

For participant \(i\), the exposure was derived in two components.

### 1. Habitual sleep midpoint, \(S_i\)

GGIR 3.0.0 was used to process UK Biobank raw wrist accelerometry (field 90001). The night-level file `part4_nightsummary_sleep_cleaned.csv` provides `sleeponset` and `wakeup` in continuous decimal hours.

For each valid night:

```text
nightly sleep midpoint = ((sleeponset + wakeup) / 2) mod 24
```

GGIR represents wake time after midnight on a continuous clock (for example, values may exceed 24 h), so the midpoint is calculated before wrapping the result onto the 24-h clock.

Each nightly midpoint is mapped onto the unit circle, and the circular mean across valid nights is taken as the participant-level habitual sleep midpoint \(S_i\).

The same night-level GGIR output is used to calculate:

- mean sleep duration (`SleepDurationInSpt`);
- mean number of sleep periods (`number_sib_sleepperiod`).

### 2. Habitual MVPA centroid, \(M_i\), and concentration, \(R_i\)

UK Biobank inputs:

- field **40033**: Moderate-Vigorous – Day hour average;
- fields **90060–90083**: hourly wear duration from 00:00–00:59 through 23:00–23:59.

Field 40033 is represented as a 24-element hourly MVPA profile. Each hourly MVPA value is multiplied by the corresponding hourly wear duration and by 60 to obtain wear-time-weighted MVPA minutes.

The 24 hourly bins are represented by their midpoints:

```text
00:00–00:59 -> 0.5 h
01:00–01:59 -> 1.5 h
...
23:00–23:59 -> 23.5 h
```

For hour midpoint \(h_j\):

```text
theta_j = 2*pi*h_j/24
```

The weighted circular vector is then used to derive:

- the circular centroid \(M_i\), representing the temporal centre of the complete 24-h MVPA distribution;
- resultant vector length \(R_i\), representing temporal concentration / phase definability.

Participants with zero estimable weighted MVPA have undefined \(M_i\) and \(R_i\).

### 3. Exposure QC and sleep-anchored phase angle

The exposure-related QC sequence is:

1. habitual sleep midpoint available;
2. mean sleep duration between 3 and 12 h, inclusive;
3. mean number of sleep periods between 5 and 30, inclusive;
4. \(R_i \ge 0.3\);
5. exclusion of prevalent/baseline diabetes before exposure quintiles were defined.

The individualised sleep-anchored MVPA phase angle is:

```text
phase_angle_h = (MVPA_centroid_h - habitual_sleep_midpoint_h) mod 24
```

Higher values indicate later habitual MVPA timing relative to the participant's habitual sleep midpoint.

The exposure was analysed:

- continuously, per 1-h later timing; and
- in quintiles Q1–Q5.

**Q1–Q5 must be created only after the final baseline-diabetes exclusion and exposure QC.**

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
|   |-- 01_run_GGIR_HDCZA.R
|   |-- 02_derive_habitual_sleep_midpoint.R
|   |-- 03_derive_MVPA_circular_metrics.R
|   |-- 04_derive_sleep_anchored_exposure.R
|-- tests/
|   |-- run_synthetic_tests.R
|-- tools/
|   |-- check_environment.R
|   |-- check_public_repo.R
|   |-- validate.R
```

## Private input contract

Because UK Biobank data cannot be distributed with the public repository, the code uses a small **standardised private input contract**.

### A. GGIR night summary

Private input:

```text
part4_nightsummary_sleep_cleaned.csv
```

Required columns:

```text
ID
night
sleeponset
wakeup
SleepDurationInSpt
number_sib_sleepperiod
```

`ID` is used only as an internal join key. It must never be committed to the public repository.

### B. Hourly MVPA input

Create a participant-level private CSV inside the authorised UK Biobank environment with these standardised columns:

```text
participant_id
mvpa_hourly_profile
wear_h00
wear_h01
...
wear_h23
```

where:

- `mvpa_hourly_profile` is the 24-value comma-separated profile from UK Biobank field 40033;
- `wear_h00` to `wear_h23` correspond, in order, to fields 90060 to 90083 and are expressed in hours.

The public code deliberately uses standardised column names instead of relying on export-specific UK Biobank column names.

### C. Baseline-diabetes eligibility input

To reproduce the manuscript quintiles, provide a private participant-level file containing:

```text
participant_id
baseline_diabetes
```

`baseline_diabetes` must be coded `0` for no baseline diabetes and `1` for baseline diabetes.

The derivation of this flag is part of the study-specific cohort/outcome construction and is deliberately kept separate from this exposure-focused repository. The script requires this flag before defining Q1–Q5.

## Configuration

Copy:

```text
config/config.example.R
```

to:

```text
config/config.R
```

and edit only the private paths.

`config/config.R` is ignored by Git.

Do **not** place UK Biobank data inside the repository directory.

## Running order

Run all commands from the repository root.

### Step 1 — GGIR/HDCZA

If raw `.cwa` files still need to be processed:

```bash
Rscript R/01_run_GGIR_HDCZA.R
```

This script checks that GGIR is exactly version 3.0.0 before processing.

If the study GGIR output already exists, this step can be skipped.

### Step 2 — habitual sleep midpoint

```bash
Rscript R/02_derive_habitual_sleep_midpoint.R
```

Private output:

```text
02_sleep_summary.csv
```

### Step 3 — MVPA circular centroid and R

```bash
Rscript R/03_derive_MVPA_circular_metrics.R
```

Private output:

```text
03_mvpa_circular_metrics.csv
```

### Step 4 — QC, phase angle, and Q1–Q5

```bash
Rscript R/04_derive_sleep_anchored_exposure.R
```

Private output:

```text
04_sleep_anchored_mvpa_exposure.csv
```

All outputs contain participant-level derived data and **must remain private**.

## Synthetic tests

The repository contains no real UK Biobank observations. Formula-level checks use artificial values only:

```bash
Rscript tests/run_synthetic_tests.R
```

The tests check:

- midpoint calculation across midnight;
- circular averaging around midnight;
- MVPA centroid for a single occupied hourly bin;
- resultant vector length for concentrated and uniform profiles;
- modulo-24 phase-angle calculation;
- deterministic quintile assignment.

Quintiles use `floor((rank - 1) * 5 / N) + 1`, with ties resolved by input row order after merging. Preserve that order when reproducing the allocation. For sample sizes not divisible by five this differs from `dplyr::ntile`; identical phase values can fall in adjacent groups.

## Scope and reproducibility boundary

This repository reproduces the **UK Biobank exposure derivation** described in the manuscript:

```text
raw accelerometry
-> HDCZA night-level sleep timing
-> habitual circular sleep midpoint S
-> wear-time-weighted 24-h MVPA distribution
-> circular centroid M and resultant length R
-> exposure QC / baseline-diabetes exclusion
-> sleep-anchored phase angle
-> Q1-Q5
```

It does not contain participant-level data and requires approved access to the underlying UK Biobank data.

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
