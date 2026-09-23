# ==============================================================================
# Run the UK Biobank primary Cox analysis
#
# Scope:
#   - Exposure quintiles Q1-Q5
#   - Continuous Phase_angle_hour per 1 h
#   - Models 1-4
#   - MICE m = 20
#   - Rubin pooling
#
# Run from repository root:
#   Rscript R/05_run_main_analysis.R
# ==============================================================================

options(stringsAsFactors = FALSE)

required_packages <- c(
  "survival",
  "mice"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing R package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

source(file.path("R", "00_utils.R"))
source(file.path("R", "01_prepare_survival_data.R"))
source(file.path("R", "02_multiple_imputation.R"))
source(file.path("R", "03_model_specifications.R"))
source(file.path("R", "04_fit_primary_cox_models.R"))

cfg <- load_private_config()

required_cfg <- c(
  "INPUT_CSV",
  "OUTPUT_DIR",
  "MICE_M",
  "MICE_MAXIT",
  "MICE_SEED"
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

if (!file.exists(cfg$INPUT_CSV)) {
  stop(
    "Private input file not found: ",
    cfg$INPUT_CSV,
    call. = FALSE
  )
}

dir.create(
  cfg$OUTPUT_DIR,
  recursive = TRUE,
  showWarnings = FALSE
)

message("Reading private UK Biobank analysis input...")

raw_data <- utils::read.csv(
  cfg$INPUT_CSV,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

analysis_data <- prepare_survival_data(
  raw_data
)

rm(raw_data)
invisible(gc())

message("Creating multiple-imputation object...")

imp <- create_mice_object(
  analysis_data = analysis_data,
  m = cfg$MICE_M,
  maxit = cfg$MICE_MAXIT,
  seed = cfg$MICE_SEED
)

rm(analysis_data)
invisible(gc())

message("Fitting four quintile and four continuous Cox models...")

pooled_results <- fit_all_primary_models(
  imp = imp,
  model_formulas = primary_model_formulas
)

all_terms_file <- file.path(
  cfg$OUTPUT_DIR,
  "ukb_primary_cox_all_terms.csv"
)

exposure_terms_file <- file.path(
  cfg$OUTPUT_DIR,
  "ukb_primary_cox_exposure_terms.csv"
)

session_file <- file.path(
  cfg$OUTPUT_DIR,
  "sessionInfo.txt"
)

write_csv_private(
  pooled_results$all_terms,
  all_terms_file
)

write_csv_private(
  pooled_results$exposure_terms,
  exposure_terms_file
)

writeLines(
  capture.output(sessionInfo()),
  session_file
)

message(
  "Primary Cox analysis complete.\n",
  "Pooled exposure summaries: ",
  exposure_terms_file
)
