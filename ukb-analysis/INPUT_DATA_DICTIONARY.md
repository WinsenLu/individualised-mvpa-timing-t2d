# Private input data dictionary

The public repository contains code only. The participant-level analysis file must remain in an authorised UK Biobank research environment.

## Required outcome/follow-up variables

| Private input column | Role |
|---|---|
| `Baseline_Date` | End date of accelerometer wear; start of prospective follow-up |
| `Date_E11_first_reported_.non.insulin.dependent_diabetes_mellitus.` | First recorded E11 date |
| `Date_of_death` | Death date |
| `Date_lost_to_follow.up` | Loss-to-follow-up date |
| `UK_Biobank_assessment_centre` | Country grouping used for administrative censoring |

`UK_Biobank_assessment_centre` must be coded as:

```text
England
Scotland
Wales
```

## Exposure variables

| Private input column | Role |
|---|---|
| `Exposure` | Individualised sleep-anchored MVPA timing quintile Q1–Q5 |
| `Phase_angle_hour` | Continuous individualised sleep-anchored MVPA phase angle in hours |
| `R_MVPA` | Resultant vector length used as an auxiliary variable in multiple imputation |

## Model covariates

| Private input column | Manuscript variable |
|---|---|
| `Age` | Age |
| `Sex` | Sex |
| `Ethnic` | Ethnicity |
| `TDI` | Townsend deprivation index |
| `Qualifications` | Education |
| `Occupation` | Occupation and shift-work status |
| `Smoking` | Smoking status |
| `Alcohol` | Alcohol intake |
| `Coffee_tea` | Coffee and tea intake |
| `Healthy_diet_score` | Healthy diet score |
| `Accelerometer_season` | Accelerometer wear season |
| `Family_history_diabetes` | Family history of diabetes |
| `Hypertension` | Hypertension |
| `Dyslipidemia` | Dyslipidaemia |
| `Depression` | Depression |
| `CVD` | Cardiovascular disease |
| `MVPA_daily_min` | Total MVPA volume |
| `Average_Sleep_Duration` | Sleep duration |

## Variables intentionally not used in the final primary MICE model

`valid_wear_days` is not used as an auxiliary variable in the main-analysis code.

BMI, chronotype, genetic variables, wake-anchored timing variables, and alternative MVPA-timing definitions are outside the primary Model 1–4 analysis implemented here.

## Derived analysis variables

The code creates:

| Derived variable | Meaning |
|---|---|
| `Censor_Limit` | Country-specific administrative censoring date |
| `Study_End` | Earliest censoring date from death, loss to follow-up, or administrative censoring |
| `Followup_End` | Earliest of E11 diagnosis and study end |
| `status` | Incident T2D event indicator |
| `time_years` | Follow-up time in years |
| `H0` | Nelson–Aalen cumulative hazard estimate used by MICE |

No participant-level derived file is included in the repository.

## Coding and units

Dates accept `YYYY-MM-DD`, `YYYY/MM/DD` or UTC `YYYY-MM-DDTHH:MM:SSZ`; absent diagnosis, death or loss dates are missing. Non-missing unparseable dates are errors. Country labels are country groupings, not assessment-centre numeric codes.

Age is in years at accelerometer wear, alcohol in UK units/week, coffee and tea in cups/day, healthy diet score on the 0–5 scale, MVPA in minutes/day and sleep duration in hours. `Phase_angle_hour` is in [0,24); `R_MVPA` is a resultant vector length. The exposure-eligible input has R >= 0.30.

The manuscript categories are sex (male/female), ethnicity (white/non-white), education (college or university degree/other), smoking (current/previous/never), occupation (white-collar without shift work/blue-collar without shift work/shift worker/retired or other), and yes/no indicators for family history and the five listed health conditions. Non-informative responses are missing. Season is categorical.

The input must retain the study coding consistently. The code converts categorical covariates to unordered factors and uses R's factor-level ordering; only Q1 is explicitly set as a reference. Record the actual covariate levels and contrasts in the authorised analysis environment if interpreting covariate coefficients. Questionnaire instance 1 was preferred where available because of its proximity to accelerometry, otherwise instance 0, as described in ESM Table 1.
