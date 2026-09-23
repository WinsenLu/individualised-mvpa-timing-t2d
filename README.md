# Individualised timing of the 24-h MVPA distribution and type 2 diabetes

This repository contains the R code associated with the study:

> **Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES**

The project evaluates a **sleep-anchored, distribution-based measure of moderate-to-vigorous physical activity (MVPA) timing**. The exposure is defined by referencing the circular centroid of each participant's habitual 24-h MVPA distribution to that participant's habitual sleep midpoint.

The repository contains four code modules covering exposure derivation and the primary epidemiological analyses in **UK Biobank** and **US NHANES 2011–2014**.

## Repository structure

```text
individualised-mvpa-timing-t2d/
├── README.md
├── LICENSE
├── .gitignore
│
├── ukb-exposure/
│   ├── README.md
│   ├── DEPENDENCIES.md
│   ├── INPUT_DATA_DICTIONARY.md
│   ├── config/
│   └── R/
│
├── ukb-analysis/
│   ├── README.md
│   ├── DEPENDENCIES.md
│   ├── INPUT_DATA_DICTIONARY.md
│   ├── EXPOSURE_MAPPING.md
│   ├── config/
│   └── R/
│
├── nhanes-exposure/
│   ├── README.md
│   ├── DEPENDENCIES.md
│   ├── INPUT_DATA_DICTIONARY.md
│   ├── config/
│   └── R/
│
└── nhanes-analysis/
    ├── README.md
    ├── DEPENDENCIES.md
    ├── INPUT_DATA_DICTIONARY.md
    ├── EXPOSURE_MAPPING.md
    ├── config/
    └── R/
```

Each module contains its own detailed `README.md`, input-data dictionary, dependency information, configuration template, and analysis scripts.

## Code modules

### 1. `ukb-exposure`

Derives the individualised MVPA timing phenotype in UK Biobank.

The workflow includes:

- habitual sleep midpoint derived using HDCZA/GGIR;
- wear-time-weighted 24-h MVPA distribution;
- circular MVPA centroid;
- resultant vector length (`R`) as a measure of temporal concentration;
- exposure-related quality control;
- sleep-anchored MVPA phase angle;
- quintile categorisation for downstream analyses.

The primary exposure is:

```text
sleep_anchored_mvpa_phase_h = (habitual MVPA centroid - habitual sleep midpoint) mod 24
```

Higher values indicate later habitual MVPA timing relative to the participant's habitual sleep midpoint.

See [`ukb-exposure/README.md`](ukb-exposure/README.md) for the full input requirements and running order.

### 2. `ukb-analysis`

Runs the primary UK Biobank Cox proportional hazards analyses for incident type 2 diabetes.

The public module includes:

- preparation of survival-analysis data;
- multiple imputation by chained equations;
- four progressively adjusted Cox models;
- quintile-based and continuous per-1-h exposure models;
- pooled hazard ratios and 95% confidence intervals.

See [`ukb-analysis/README.md`](ukb-analysis/README.md) for model definitions and required inputs.

### 3. `nhanes-exposure`

Derives the corresponding individualised MVPA timing phenotype from NHANES 2011–2014 wrist accelerometry.

The workflow includes:

- processing of NHANES PAX80 raw wrist accelerometry;
- GGIR 3.0.0 processing;
- 60-s ENMO-based MVPA classification using a threshold of `>=100 mg`;
- valid-day and valid-night quality-control criteria;
- habitual sleep midpoint;
- 1,440-min habitual MVPA distribution;
- circular MVPA centroid and resultant vector length;
- sleep-anchored MVPA phase angle.

See [`nhanes-exposure/README.md`](nhanes-exposure/README.md) for details.

### 4. `nhanes-analysis`

Runs the fully adjusted primary NHANES analyses.

The public module covers five outcomes:

1. prevalent diabetes;
2. HbA1c;
3. fasting glucose;
4. fasting insulin;
5. 2-h oral glucose tolerance test (OGTT) glucose.

It includes:

- multiple imputation by chained equations (`m = 20`);
- NHANES complex-survey design;
- survey-weighted logistic regression for prevalent diabetes;
- survey-weighted linear regression for natural-log-transformed glycaemic outcomes;
- outcome-specific survey weights;
- Rubin pooling;
- odds ratios or percentage differences, as appropriate.

See [`nhanes-analysis/README.md`](nhanes-analysis/README.md) for the full model specification.

## Software environment

The manuscript analyses were conducted in:

```text
R 4.3.1
```

Exposure processing uses:

```text
GGIR 3.0.0
```

Other required packages are documented in the `DEPENDENCIES.md` file within each module. The scripts do not install packages automatically.

## Getting started

Clone the repository:

```bash
git clone https://github.com/WinsenLu/individualised-mvpa-timing-t2d.git
cd individualised-mvpa-timing-t2d
```

For each module that you intend to run:

1. read the module-specific `README.md`;
2. review `INPUT_DATA_DICTIONARY.md`;
3. copy the example configuration file:

```text
config/config.example.R
```

to:

```text
config/config.R
```

4. edit `config/config.R` to point to local authorised inputs and output directories;
5. check the required software and package versions;
6. run the scripts according to the order documented in the corresponding module-specific `README.md`.

`config/config.R` is intentionally excluded from version control.

## Data availability and governance

### UK Biobank

No UK Biobank participant-level data are included in this repository. Access to UK Biobank data requires approval from UK Biobank. Participant-level inputs and derived outputs must remain within an authorised research environment and must not be committed to this repository.

### NHANES

No participant-level analysis-ready or derived NHANES data are included in this repository. Public-use NHANES source data are available from the US National Center for Health Statistics (NCHS), subject to the terms and documentation provided by NCHS.

The root `.gitignore` is intentionally conservative and excludes common participant-level data formats, local configuration files, fitted objects, outputs, logs, archives, and other generated artefacts.

## Reproducibility scope

This public repository is intended to document the **exposure-derivation workflows and primary statistical analyses** when the appropriate source data and authorised inputs are available.

The current public UK Biobank analysis module does **not** include the restricted cubic spline, subgroup, sensitivity, joint MVPA timing-volume, or model-performance analyses described elsewhere in the manuscript.

The current public NHANES analysis module contains the fully adjusted primary model (Model 3) only; Models 1 and 2, restricted cubic spline analyses, and tests for nonlinearity are outside its current scope.

The repository does not contain participant-level study data. Reproduction of numerical results therefore requires access to the corresponding source data and construction of the analysis inputs described in the module documentation.

## Licence

The code in this repository is released under the [MIT License](LICENSE).

The licence applies to the source code in this repository and does not grant permission to redistribute UK Biobank data or any other restricted participant-level data.

## Citation

If you use this code, please cite the associated manuscript:

> Lu W, Yu S, Xiang J, et al. *Individualised timing of the 24-h MVPA distribution and type 2 diabetes: evidence from UK Biobank and NHANES.*

The full bibliographic citation can be updated after publication.

## Contact

For questions about the code or study, please use the contact information provided in the associated manuscript.
