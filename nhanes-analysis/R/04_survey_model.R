# ==============================================================================
# NHANES survey-weighted primary Model 3 and Rubin pooling
# ==============================================================================

build_survey_designs <- function(
  completed_list,
  weight_name
) {
  assert_packages("survey")

  options(
    survey.lonely.psu = "adjust"
  )

  lapply(
    completed_list,
    function(d) {
      survey::svydesign(
        ids = ~SDMVPSU,
        strata = ~SDMVSTRA,
        weights = stats::as.formula(
          paste0("~", weight_name)
        ),
        nest = TRUE,
        data = d
      )
    }
  )
}

make_primary_formula <- function(outcome) {
  stats::as.formula(
    paste(
      outcome,
      "~",
      paste(
        c(
          "sleep_anchored_mvpa_phase_h",
          primary_model_covariates
        ),
        collapse = " + "
      )
    )
  )
}

fit_model3_in_imputations <- function(
  design_list,
  formula,
  analysis_type
) {
  lapply(
    design_list,
    function(des) {
      if (identical(analysis_type, "binary")) {
        survey::svyglm(
          formula = formula,
          design = des,
          family = stats::quasibinomial(
            link = "logit"
          )
        )
      } else {
        survey::svyglm(
          formula = formula,
          design = des,
          family = stats::gaussian()
        )
      }
    }
  )
}

pool_survey_models <- function(
  fitted_models,
  analysis_type
) {
  assert_packages("mitools")

  if (identical(analysis_type, "binary")) {
    df_complete <- min(
      vapply(
        fitted_models,
        function(x) x$df.residual,
        numeric(1)
      )
    )
  } else {
    df_complete <- fitted_models[[1]]$df.residual
  }

  mitools::MIcombine(
    fitted_models,
    df.complete = df_complete
  )
}

extract_pooled_results <- function(pooled_model) {
  beta <- pooled_model$coefficients
  variance <- pooled_model$variance
  se <- sqrt(diag(variance))
  df_mi <- pooled_model$df

  if (length(df_mi) == 1L) {
    df_mi <- rep(
      df_mi,
      length(beta)
    )
  }

  t_value <- beta / se

  p_value <- 2 * stats::pt(
    abs(t_value),
    df = df_mi,
    lower.tail = FALSE
  )

  critical_t <- stats::qt(
    0.975,
    df = df_mi
  )

  ci_lower <- beta - critical_t * se
  ci_upper <- beta + critical_t * se

  missinfo <- pooled_model$missinfo

  if (length(missinfo) == 1L) {
    missinfo <- rep(
      missinfo,
      length(beta)
    )
  }

  data.frame(
    model = "Model 3",
    term = names(beta),
    beta = as.numeric(beta),
    SE = as.numeric(se),
    df = as.numeric(df_mi),
    CI_lower = as.numeric(ci_lower),
    CI_upper = as.numeric(ci_upper),
    t_value = as.numeric(t_value),
    P_value = as.numeric(p_value),
    missing_information_percent =
      100 * as.numeric(missinfo),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

fit_primary_model3 <- function(
  completed_list,
  spec
) {
  designs <- build_survey_designs(
    completed_list,
    spec$weight
  )

  formula <- make_primary_formula(
    outcome = spec$primary_outcome
  )

  fits <- fit_model3_in_imputations(
    design_list = designs,
    formula = formula,
    analysis_type = spec$analysis_type
  )

  pooled <- pool_survey_models(
    fitted_models = fits,
    analysis_type = spec$analysis_type
  )

  all_terms <- extract_pooled_results(
    pooled
  )

  exposure <- all_terms[
    all_terms$term == "sleep_anchored_mvpa_phase_h",
    ,
    drop = FALSE
  ]

  if (nrow(exposure) != 1L) {
    stop(
      spec$label,
      ": primary exposure coefficient could not be uniquely identified.",
      call. = FALSE
    )
  }

  if (identical(spec$analysis_type, "binary")) {
    exposure$OR <- exp(exposure$beta)
    exposure$OR_CI_lower <- exp(exposure$CI_lower)
    exposure$OR_CI_upper <- exp(exposure$CI_upper)
  } else {
    exposure$percent_difference <- percent_difference(
      exposure$beta
    )
    exposure$percent_CI_lower <- percent_difference(
      exposure$CI_lower
    )
    exposure$percent_CI_upper <- percent_difference(
      exposure$CI_upper
    )
  }

  list(
    all_terms = all_terms,
    exposure = exposure
  )
}
