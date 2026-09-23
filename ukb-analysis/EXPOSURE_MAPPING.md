# Connecting exposure derivation to Cox analysis

Join the exposure output to the eligible analysis cohort using the private participant key. Require unique keys in both tables and investigate unmatched participants before analysis. Do not recalculate quintiles after dropping covariate-missing observations; covariates are handled by multiple imputation.

| Exposure output | Cox input |
|---|---|
| `Exposure` | `Exposure` |
| `phase_angle_h` | `Phase_angle_hour` |
| `mvpa_resultant_length` | `R_MVPA` |
| `mvpa_daily_min` | `MVPA_daily_min` |
| `mean_sleep_duration_h` | `Average_Sleep_Duration` |

Supply dates and covariates according to `INPUT_DATA_DICTIONARY.md`. Baseline diabetes ascertainment and the remaining cohort exclusions are upstream requirements. Exposure-only output is not a complete Cox input table.
