# ==============================================================================
# Multiple imputation for the primary UK Biobank Cox analysis
# ==============================================================================

create_mice_object <- function(
  analysis_data,
  m = 20L,
  maxit = 5L,
  seed = 123L
) {
  if (!requireNamespace("mice", quietly = TRUE)) {
    stop(
      "Package 'mice' is required.",
      call. = FALSE
    )
  }

  # Nelson–Aalen cumulative hazard for the survival imputation model.
  analysis_data$H0 <- mice::nelsonaalen(
    analysis_data,
    time_years,
    status
  )

  # Imputation-model variables.
  #
  # valid_wear_days is intentionally absent.
  imputation_vars <- c(
    "status",
    "time_years",
    "H0",
    "Exposure",
    "Phase_angle_hour",
    "Age",
    "Sex",
    "TDI",
    "Smoking",
    "Ethnic",
    "Qualifications",
    "Occupation",
    "Alcohol",
    "Healthy_diet_score",
    "Coffee_tea",
    "Accelerometer_season",
    "Family_history_diabetes",
    "Hypertension",
    "Dyslipidemia",
    "Depression",
    "CVD",
    "MVPA_daily_min",
    "Average_Sleep_Duration",
    "R_MVPA"
  )

  assert_required_columns(
    analysis_data,
    imputation_vars,
    object_name = "Prepared survival data"
  )

  impute_data <- analysis_data[
    ,
    imputation_vars,
    drop = FALSE
  ]

  # In the analysis input these variables are fully observed and are used as
  # outcomes/exposures/auxiliary predictors rather than imputation targets.
  never_impute <- c(
    "status",
    "time_years",
    "H0",
    "Exposure",
    "Phase_angle_hour",
    "R_MVPA"
  )

  incomplete_fixed <- never_impute[
    vapply(
      impute_data[never_impute],
      function(x) any(is.na(x)),
      logical(1)
    )
  ]

  if (length(incomplete_fixed) > 0L) {
    stop(
      "Unexpected missing values in non-imputed analysis variable(s): ",
      paste(incomplete_fixed, collapse = ", "),
      call. = FALSE
    )
  }

  # Initialise MICE so that complete variables automatically receive method "".
  init <- mice::mice(
    impute_data,
    m = 1,
    maxit = 0,
    printFlag = FALSE
  )

  method <- init$method

  # Predictive mean matching for variables requiring imputation.
  method[method != ""] <- "pmm"

  # These variables remain predictors but are not imputation targets.
  method[intersect(names(method), never_impute)] <- ""

  predictor_matrix <- init$predictorMatrix

  # Variables that are not imputed should still remain available as predictors
  # for incomplete covariates. Their rows are zeroed; their columns are retained.
  predictor_matrix[never_impute, ] <- 0

  diag(predictor_matrix) <- 0

  imp <- mice::mice(
    impute_data,
    m = as.integer(m),
    maxit = as.integer(maxit),
    method = method,
    predictorMatrix = predictor_matrix,
    seed = as.integer(seed),
    printFlag = TRUE
  )

  imp
}
