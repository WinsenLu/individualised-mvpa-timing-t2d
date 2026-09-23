# ==============================================================================
# Outcome-specific specifications and primary Model 3 covariates
# ==============================================================================

outcome_specs <- list(
  prevalent_diabetes = list(
    label = "Prevalent diabetes",
    analysis_type = "binary",
    primary_outcome = "prevalent_diabetes",
    raw_outcome = NULL,
    weight = "WTMEC4YR",
    seed = 20260814L
  ),

  hba1c = list(
    label = "HbA1c",
    analysis_type = "continuous_log",
    primary_outcome = "ln_LBXGH",
    raw_outcome = "LBXGH",
    weight = "WTMEC4YR",
    seed = 20260814L
  ),

  fasting_glucose = list(
    label = "Fasting glucose",
    analysis_type = "continuous_log",
    primary_outcome = "ln_LBXGLU",
    raw_outcome = "LBXGLU",
    weight = "WTSAF4YR",
    seed = 20260814L
  ),

  fasting_insulin = list(
    label = "Fasting insulin",
    analysis_type = "continuous_log",
    primary_outcome = "ln_fasting_insulin",
    raw_outcome = "LBXIN_RocheEq",
    weight = "WTSAF4YR",
    seed = 20260815L
  ),

  ogtt = list(
    label = "2-h OGTT glucose",
    analysis_type = "continuous_log",
    primary_outcome = "ln_LBXGLT",
    raw_outcome = "LBXGLT",
    weight = "WTSOG4YR",
    seed = 20260813L
  )
)

primary_model_covariates <- c(
  "RIDAGEYR",
  "sex_model",
  "race4",
  "education_binary",
  "household_income_binary",
  "smoking_binary",
  "alcohol_binary",
  "total_energy_intake_kcal",
  "HEI_score",
  "mean_mvpa_minutes_per_valid_day",
  "mean_sleep_duration_h"
)

imputed_covariates <- c(
  "education_binary",
  "household_income_binary",
  "smoking_binary",
  "alcohol_binary",
  "total_energy_intake_kcal",
  "HEI_score"
)

binary_imputation_vars <- c(
  "education_binary",
  "household_income_binary",
  "smoking_binary",
  "alcohol_binary"
)

continuous_imputation_vars <- c(
  "total_energy_intake_kcal",
  "HEI_score"
)
