# ==============================================================================
# 04_derive_sleep_anchored_exposure.R
#
# Merge sleep and MVPA metrics, apply the exposure-related QC used in the study,
# exclude baseline diabetes, derive the sleep-anchored phase angle, and create
# Q1-Q5 only in the final eligible cohort.
#
# Run from repository root:
#   Rscript R/04_derive_sleep_anchored_exposure.R
# ==============================================================================

source(file.path("R", "00_utils.R"))

validate_baseline_diabetes_flag <- function(x) {
  x_num <- suppressWarnings(as.numeric(x))

  if (any(!is.finite(x_num))) {
    stop(
      "baseline_diabetes contains missing or non-numeric values. ",
      "Use 0 = no baseline diabetes and 1 = baseline diabetes.",
      call. = FALSE
    )
  }

  if (any(!x_num %in% c(0, 1))) {
    stop(
      "baseline_diabetes must be coded only as 0 or 1.",
      call. = FALSE
    )
  }

  as.integer(x_num)
}

derive_sleep_anchored_exposure <- function(
  sleep_summary,
  mvpa_metrics,
  eligibility
) {
  assert_required_columns(
    sleep_summary,
    c(
      "participant_id",
      "habitual_sleep_midpoint_h",
      "mean_sleep_duration_h",
      "mean_sleep_period_count"
    ),
    object_name = "Sleep summary"
  )

  assert_required_columns(
    mvpa_metrics,
    c(
      "participant_id",
      "mvpa_centroid_h",
      "mvpa_resultant_length"
    ),
    object_name = "MVPA metrics"
  )

  assert_required_columns(
    eligibility,
    c(
      "participant_id",
      "baseline_diabetes"
    ),
    object_name = "Eligibility input"
  )

  if (anyDuplicated(sleep_summary$participant_id)) {
    stop("Duplicate participant_id in sleep summary.", call. = FALSE)
  }

  if (anyDuplicated(mvpa_metrics$participant_id)) {
    stop("Duplicate participant_id in MVPA metrics.", call. = FALSE)
  }

  if (anyDuplicated(eligibility$participant_id)) {
    stop("Duplicate participant_id in eligibility input.", call. = FALSE)
  }

  eligibility$participant_id <- as.character(
    eligibility$participant_id
  )

  eligibility$baseline_diabetes <- validate_baseline_diabetes_flag(
    eligibility$baseline_diabetes
  )

  merged <- merge(
    sleep_summary,
    mvpa_metrics,
    by = "participant_id",
    all = FALSE,
    sort = FALSE
  )

  merged <- merge(
    merged,
    eligibility[
      ,
      c("participant_id", "baseline_diabetes"),
      drop = FALSE
    ],
    by = "participant_id",
    all = FALSE,
    sort = FALSE
  )

  # ---------------------------------------------------------------------------
  # Exposure-related QC sequence retained from the study analysis.
  # ---------------------------------------------------------------------------

  keep <- is.finite(
    merged$habitual_sleep_midpoint_h
  )

  keep <- keep &
    is.finite(merged$mean_sleep_duration_h) &
    merged$mean_sleep_duration_h >= 3 &
    merged$mean_sleep_duration_h <= 12

  keep <- keep &
    is.finite(merged$mean_sleep_period_count) &
    merged$mean_sleep_period_count >= 5 &
    merged$mean_sleep_period_count <= 30

  keep <- keep &
    is.finite(merged$mvpa_resultant_length) &
    merged$mvpa_resultant_length >= 0.3

  # Q1-Q5 were defined after exclusion of baseline diabetes.
  keep <- keep &
    merged$baseline_diabetes == 0L

  final <- merged[
    keep,
    ,
    drop = FALSE
  ]

  if (nrow(final) == 0L) {
    stop("No participants remain after exposure QC.", call. = FALSE)
  }

  if (
    any(!is.finite(final$mvpa_centroid_h)) ||
      any(!is.finite(final$habitual_sleep_midpoint_h))
  ) {
    stop(
      "Non-finite centroid or sleep midpoint remained after QC.",
      call. = FALSE
    )
  }

  final$phase_angle_h <- (
    final$mvpa_centroid_h -
      final$habitual_sleep_midpoint_h
  ) %% 24

  quintile_number <- ntile_equal_frequency(
    final$phase_angle_h,
    n = 5L
  )

  final$Exposure <- factor(
    paste0("Q", quintile_number),
    levels = paste0("Q", 1:5),
    ordered = TRUE
  )

  final
}

main <- function() {
  cfg <- load_private_config()

  required_cfg <- c(
    "ELIGIBILITY_CSV",
    "PRIVATE_OUTPUT_DIR"
  )

  missing_cfg <- required_cfg[
    !vapply(required_cfg, exists, logical(1), envir = cfg, inherits = FALSE)
  ]

  if (length(missing_cfg) > 0L) {
    stop(
      "Missing configuration variable(s): ",
      paste(missing_cfg, collapse = ", "),
      call. = FALSE
    )
  }

  sleep_path <- file.path(
    cfg$PRIVATE_OUTPUT_DIR,
    "02_sleep_summary.csv"
  )

  mvpa_path <- file.path(
    cfg$PRIVATE_OUTPUT_DIR,
    "03_mvpa_circular_metrics.csv"
  )

  sleep_summary <- read_private_csv(sleep_path)
  mvpa_metrics <- read_private_csv(mvpa_path)
  eligibility <- read_private_csv(cfg$ELIGIBILITY_CSV)

  final <- derive_sleep_anchored_exposure(
    sleep_summary = sleep_summary,
    mvpa_metrics = mvpa_metrics,
    eligibility = eligibility
  )

  output_path <- file.path(
    cfg$PRIVATE_OUTPUT_DIR,
    "04_sleep_anchored_mvpa_exposure.csv"
  )

  write_private_csv(final, output_path)

  message(
    "Sleep-anchored MVPA exposure derived for ",
    nrow(final),
    " eligible participants. Participant-level output remains private."
  )
}

if (sys.nframe() == 0L) {
  main()
}
