# ==============================================================================
# Prespecified UK Biobank primary Cox model definitions
# ==============================================================================

model_covariates <- list(
  Model1 = c(
    "Age",
    "Sex",
    "Ethnic"
  ),

  Model2 = c(
    "Age",
    "Sex",
    "Ethnic",
    "TDI",
    "Qualifications",
    "Occupation",
    "Smoking",
    "Alcohol",
    "Coffee_tea",
    "Healthy_diet_score",
    "Accelerometer_season"
  ),

  Model3 = c(
    "Age",
    "Sex",
    "Ethnic",
    "TDI",
    "Qualifications",
    "Occupation",
    "Smoking",
    "Alcohol",
    "Coffee_tea",
    "Healthy_diet_score",
    "Accelerometer_season",
    "Family_history_diabetes",
    "Hypertension",
    "Dyslipidemia",
    "Depression",
    "CVD"
  ),

  Model4 = c(
    "Age",
    "Sex",
    "Ethnic",
    "TDI",
    "Qualifications",
    "Occupation",
    "Smoking",
    "Alcohol",
    "Coffee_tea",
    "Healthy_diet_score",
    "Accelerometer_season",
    "Family_history_diabetes",
    "Hypertension",
    "Dyslipidemia",
    "Depression",
    "CVD",
    "MVPA_daily_min",
    "Average_Sleep_Duration"
  )
)

make_cox_formula <- function(
  exposure,
  covariates
) {
  stats::as.formula(
    paste(
      "survival::Surv(time_years, status) ~",
      paste(
        c(exposure, covariates),
        collapse = " + "
      )
    )
  )
}

primary_model_formulas <- list()

for (model_name in names(model_covariates)) {
  primary_model_formulas[[paste0(model_name, "_quintile")]] <- make_cox_formula(
    exposure = "Exposure",
    covariates = model_covariates[[model_name]]
  )

  primary_model_formulas[[paste0(model_name, "_continuous")]] <- make_cox_formula(
    exposure = "Phase_angle_hour",
    covariates = model_covariates[[model_name]]
  )
}
