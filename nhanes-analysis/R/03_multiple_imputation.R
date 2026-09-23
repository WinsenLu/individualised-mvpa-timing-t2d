# ==============================================================================
# Outcome-specific MICE implementation
# ==============================================================================

create_mice_object <- function(
  data,
  spec,
  m = 20L,
  maxit = 20L
) {
  assert_packages("mice")

  mice_vars <- unique(
    c(
      "SEQN",
      "cycle",
      spec$primary_outcome,
      if (!is.null(spec$raw_outcome)) spec$raw_outcome,
      "sleep_anchored_mvpa_phase_h",
      "RIDAGEYR",
      "sex_model",
      "race4",
      imputed_covariates,
      "mean_mvpa_minutes_per_valid_day",
      "mean_sleep_duration_h",
      spec$weight,
      "SDMVSTRA",
      "SDMVPSU"
    )
  )

  mice_data <- data[
    ,
    mice_vars,
    drop = FALSE
  ]

  mice_data$SDMVSTRA_imp <- factor(
    mice_data$SDMVSTRA
  )

  ini <- mice::mice(
    mice_data,
    maxit = 0,
    printFlag = FALSE
  )

  method <- ini$method
  predictor_matrix <- ini$predictorMatrix

  method[] <- ""

  for (var in binary_imputation_vars) {
    if (any(is.na(mice_data[[var]]))) {
      method[var] <- "logreg"
    }
  }

  for (var in continuous_imputation_vars) {
    if (any(is.na(mice_data[[var]]))) {
      method[var] <- "pmm"
    }
  }

  predictor_matrix[,] <- 0

  imputation_predictors <- c(
    "cycle",
    spec$primary_outcome,
    "sleep_anchored_mvpa_phase_h",
    "RIDAGEYR",
    "sex_model",
    "race4",
    imputed_covariates,
    "mean_mvpa_minutes_per_valid_day",
    "mean_sleep_duration_h",
    spec$weight,
    "SDMVSTRA_imp"
  )

  targets <- imputed_covariates[
    vapply(
      mice_data[imputed_covariates],
      function(x) any(is.na(x)),
      logical(1)
    )
  ]

  for (target in targets) {
    predictors_this_target <- setdiff(
      imputation_predictors,
      target
    )

    predictor_matrix[
      target,
      predictors_this_target
    ] <- 1
  }

  predictor_matrix[, "SEQN"] <- 0
  predictor_matrix[, "SDMVSTRA"] <- 0
  predictor_matrix[, "SDMVPSU"] <- 0

  if (!is.null(spec$raw_outcome)) {
    predictor_matrix[, spec$raw_outcome] <- 0
  }

  imp <- mice::mice(
    data = mice_data,
    m = as.integer(m),
    maxit = as.integer(maxit),
    method = method,
    predictorMatrix = predictor_matrix,
    seed = as.integer(spec$seed),
    printFlag = TRUE
  )

  list(
    imp = imp,
    method = method,
    predictor_matrix = predictor_matrix
  )
}

complete_imputations <- function(
  imp,
  spec
) {
  completed <- lapply(
    seq_len(imp$m),
    function(i) {
      d <- mice::complete(
        imp,
        action = i
      )

      reset_factor_levels(d)
    }
  )

  analysis_vars <- unique(
    c(
      spec$primary_outcome,
      "sleep_anchored_mvpa_phase_h",
      primary_model_covariates,
      spec$weight,
      "SDMVSTRA",
      "SDMVPSU"
    )
  )

  for (i in seq_along(completed)) {
    missing_i <- analysis_vars[
      vapply(
        completed[[i]][analysis_vars],
        function(x) any(is.na(x)),
        logical(1)
      )
    ]

    if (length(missing_i) > 0L) {
      stop(
        spec$label,
        ": completed imputation ",
        i,
        " still contains missing model variable(s): ",
        paste(missing_i, collapse = ", "),
        call. = FALSE
      )
    }
  }

  completed
}
