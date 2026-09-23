# ==============================================================================
# Run all NHANES 2011–2014 fully adjusted primary analyses (Model 3 only)
#
# Run from repository root:
#   Rscript R/06_run_all_main_analyses.R
# ==============================================================================

options(stringsAsFactors = FALSE)

source(file.path("R", "00_utils.R"))

assert_packages(
  c(
    "mice",
    "survey",
    "mitools"
  )
)

source(file.path("R", "01_outcome_specifications.R"))
source(file.path("R", "02_prepare_analysis_data.R"))
source(file.path("R", "03_multiple_imputation.R"))
source(file.path("R", "04_survey_model.R"))
source(file.path("R", "05_run_one_outcome.R"))

cfg <- load_private_config()

required_cfg <- c(
  "PREVALENT_DIABETES_CSV",
  "HBA1C_CSV",
  "FASTING_GLUCOSE_CSV",
  "FASTING_INSULIN_CSV",
  "OGTT_CSV",
  "OUTPUT_DIR",
  "N_IMPUTATIONS",
  "N_ITERATIONS",
  "SAVE_MICE_OBJECTS"
)

missing_cfg <- required_cfg[
  !vapply(
    required_cfg,
    exists,
    logical(1),
    envir = cfg,
    inherits = FALSE
  )
]

if (length(missing_cfg) > 0L) {
  stop(
    "Missing configuration value(s): ",
    paste(missing_cfg, collapse = ", "),
    call. = FALSE
  )
}

if (as.integer(cfg$N_IMPUTATIONS) != 20L) {
  stop(
    "The NHANES analysis requires 20 imputed data sets.",
    call. = FALSE
  )
}

if (as.integer(cfg$N_ITERATIONS) != 20L) {
  stop(
    "The NHANES analysis requires 20 MICE iterations.",
    call. = FALSE
  )
}

dir.create(
  cfg$OUTPUT_DIR,
  recursive = TRUE,
  showWarnings = FALSE
)

input_paths <- list(
  prevalent_diabetes = cfg$PREVALENT_DIABETES_CSV,
  hba1c = cfg$HBA1C_CSV,
  fasting_glucose = cfg$FASTING_GLUCOSE_CSV,
  fasting_insulin = cfg$FASTING_INSULIN_CSV,
  ogtt = cfg$OGTT_CSV
)

all_results <- list()

for (outcome_key in names(input_paths)) {
  message(
    "\nRunning Model 3: ",
    outcome_specs[[outcome_key]]$label
  )

  all_results[[outcome_key]] <- run_one_outcome(
    input_csv = input_paths[[outcome_key]],
    output_dir = cfg$OUTPUT_DIR,
    outcome_key = outcome_key,
    spec = outcome_specs[[outcome_key]],
    n_imputations = cfg$N_IMPUTATIONS,
    n_iterations = cfg$N_ITERATIONS,
    save_mice_object = cfg$SAVE_MICE_OBJECTS
  )
}

combined <- combine_exposure_results(all_results)

write_private_csv(
  combined,
  file.path(
    cfg$OUTPUT_DIR,
    "nhanes_model3_results.csv"
  )
)

writeLines(
  capture.output(sessionInfo()),
  file.path(
    cfg$OUTPUT_DIR,
    "sessionInfo.txt"
  )
)

message(
  "\nNHANES Model 3 analyses complete.\n",
  "Combined primary exposure results: ",
  file.path(
    cfg$OUTPUT_DIR,
    "nhanes_model3_results.csv"
  )
)
