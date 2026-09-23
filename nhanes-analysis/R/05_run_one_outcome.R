# ==============================================================================
# Run one NHANES outcome through MICE + primary Model 3
# ==============================================================================

run_one_outcome <- function(
  input_csv,
  output_dir,
  outcome_key,
  spec,
  n_imputations = 20L,
  n_iterations = 20L,
  save_mice_object = FALSE
) {
  if (!file.exists(input_csv)) {
    stop(
      spec$label,
      ": input file not found: ",
      input_csv,
      call. = FALSE
    )
  }

  data <- utils::read.csv(
    input_csv,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = c(
      "",
      "NA",
      "N/A",
      "NaN"
    )
  )

  data <- prepare_analysis_data(
    data,
    spec
  )

  mice_run <- create_mice_object(
    data = data,
    spec = spec,
    m = n_imputations,
    maxit = n_iterations
  )

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  if (isTRUE(save_mice_object)) {
    saveRDS(
      mice_run$imp,
      file.path(
        output_dir,
        paste0(
          outcome_key,
          "_mice_m",
          n_imputations,
          ".rds"
        )
      )
    )
  }

  completed <- complete_imputations(
    mice_run$imp,
    spec
  )

  results <- fit_primary_model3(
    completed_list = completed,
    spec = spec
  )

  all_terms <- results$all_terms
  all_terms$outcome <- spec$label
  all_terms$analysis_type <- spec$analysis_type
  all_terms$survey_weight <- spec$weight
  all_terms$n_imputations <- n_imputations
  all_terms$mice_iterations <- n_iterations
  all_terms$mice_seed <- spec$seed

  exposure <- results$exposure
  exposure$outcome <- spec$label
  exposure$analysis_type <- spec$analysis_type
  exposure$survey_weight <- spec$weight
  exposure$n_imputations <- n_imputations
  exposure$mice_iterations <- n_iterations
  exposure$mice_seed <- spec$seed

  write_private_csv(
    all_terms,
    file.path(
      output_dir,
      paste0(
        outcome_key,
        "_model3_all_terms.csv"
      )
    )
  )

  write_private_csv(
    exposure,
    file.path(
      output_dir,
      paste0(
        outcome_key,
        "_model3_exposure_result.csv"
      )
    )
  )

  list(
    all_terms = all_terms,
    exposure = exposure
  )
}
