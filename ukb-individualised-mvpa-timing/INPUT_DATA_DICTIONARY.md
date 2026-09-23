# Input data dictionary

This document describes the **private inputs** required by the public exposure-derivation code. None of these participant-level files should be committed to Git.

## 1. Raw accelerometry for sleep processing

| Source | Item | Role |
|---|---|---|
| UK Biobank | Field 90001 | Raw wrist accelerometry (`.cwa`) used by GGIR 3.0.0/HDCZA |

The public GGIR script assumes that the relevant `.cwa` files have already been staged inside an authorised UK Biobank workspace. Cohort-specific selection of raw files is an upstream private operation.

## 2. GGIR night-level sleep summary

File:

```text
part4_nightsummary_sleep_cleaned.csv
```

Required columns:

| Column | Meaning in this pipeline | Use |
|---|---|---|
| `ID` | Participant-specific GGIR file identifier | Private join key only |
| `night` | Night index | Night-level record tracking |
| `sleeponset` | Sleep onset in continuous decimal hours | Nightly midpoint |
| `wakeup` | Final wake in continuous decimal hours; may exceed 24 after midnight | Nightly midpoint |
| `SleepDurationInSpt` | Sleep duration within the sleep period, hours | Participant-level mean sleep-duration QC |
| `number_sib_sleepperiod` | Number of sustained inactivity bouts / sleep periods as represented in the study GGIR output | Participant-level mean sleep-period-count QC |

The study analysis used **GGIR 3.0.0**.

## 3. UK Biobank hourly MVPA profile and wear time

Source fields:

| UK Biobank field | Meaning | Standardised private input |
|---|---|---|
| 40033 | Moderate-Vigorous – Day hour average; 24 hourly values | `mvpa_hourly_profile` |
| 90060 | Wear duration during 00:00–00:59 | `wear_h00` |
| 90061 | Wear duration during 01:00–01:59 | `wear_h01` |
| 90062 | Wear duration during 02:00–02:59 | `wear_h02` |
| 90063 | Wear duration during 03:00–03:59 | `wear_h03` |
| 90064 | Wear duration during 04:00–04:59 | `wear_h04` |
| 90065 | Wear duration during 05:00–05:59 | `wear_h05` |
| 90066 | Wear duration during 06:00–06:59 | `wear_h06` |
| 90067 | Wear duration during 07:00–07:59 | `wear_h07` |
| 90068 | Wear duration during 08:00–08:59 | `wear_h08` |
| 90069 | Wear duration during 09:00–09:59 | `wear_h09` |
| 90070 | Wear duration during 10:00–10:59 | `wear_h10` |
| 90071 | Wear duration during 11:00–11:59 | `wear_h11` |
| 90072 | Wear duration during 12:00–12:59 | `wear_h12` |
| 90073 | Wear duration during 13:00–13:59 | `wear_h13` |
| 90074 | Wear duration during 14:00–14:59 | `wear_h14` |
| 90075 | Wear duration during 15:00–15:59 | `wear_h15` |
| 90076 | Wear duration during 16:00–16:59 | `wear_h16` |
| 90077 | Wear duration during 17:00–17:59 | `wear_h17` |
| 90078 | Wear duration during 18:00–18:59 | `wear_h18` |
| 90079 | Wear duration during 19:00–19:59 | `wear_h19` |
| 90080 | Wear duration during 20:00–20:59 | `wear_h20` |
| 90081 | Wear duration during 21:00–21:59 | `wear_h21` |
| 90082 | Wear duration during 22:00–22:59 | `wear_h22` |
| 90083 | Wear duration during 23:00–23:59 | `wear_h23` |

Private participant-level input file:

```text
participant_id,mvpa_hourly_profile,wear_h00,...,wear_h23
```

The code does not assume a particular UK Biobank export-header convention. Researchers should standardise their authorised private extract to these column names before running the exposure pipeline.

### Expected units

- `mvpa_hourly_profile`: hourly MVPA proportion/value from field 40033, represented as 24 comma-separated numeric values in chronological order.
- `wear_h00`–`wear_h23`: wear duration in hours.

The study calculation multiplies hourly MVPA values by wear duration and by 60 to obtain wear-time-weighted MVPA minutes.

## 4. Baseline-diabetes eligibility flag

Private input:

```text
participant_id,baseline_diabetes
```

Coding:

- `0` = no baseline diabetes;
- `1` = baseline diabetes.

This input is required because the study defined Q1–Q5 **after** baseline-diabetes exclusion. The detailed disease-ascertainment pipeline is outside the scope of this exposure-focused repository.

## 5. Outputs

All outputs are participant-level derived UK Biobank data and remain private:

| Output | Contents |
|---|---|
| `02_sleep_summary.csv` | habitual sleep midpoint and sleep QC summaries |
| `03_mvpa_circular_metrics.csv` | MVPA centroid, resultant length, wear and MVPA summaries |
| `04_sleep_anchored_mvpa_exposure.csv` | final phase angle and Q1–Q5 after QC |

Do not commit any output file.
