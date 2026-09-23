# Connecting exposure derivation to NHANES analysis

Retain exposure rows with `include_primary == TRUE` and join on `SEQN` to the appropriate eligible outcome sample. Require unique keys and investigate unmatched records. Preserve the fields `sleep_anchored_mvpa_phase_h`, `mean_mvpa_minutes_per_valid_day` and `mean_sleep_duration_h` without renaming.

Derive outcome eligibility, covariates, logarithmic outcomes and survey-design variables as specified in `INPUT_DATA_DICTIONARY.md` and the manuscript. For the two cycles combined, the required four-year weights are one-half of the respective two-year weights: `WTMEC4YR = WTMEC2YR/2`, `WTSAF4YR = WTSAF2YR/2`, and `WTSOG4YR = WTSOG2YR/2`. Use the appropriate weight for each outcome. Exposure-only output is not an analysis-ready outcome table.
