# ==============================================================================
# Process one NHANES participant archive from raw data to exposure
# ==============================================================================

source(file.path("R", "00_utils.R"))
source(file.path("R", "01_prepare_pax80_input.R"))
source(file.path("R", "02_run_ggir.R"))
source(file.path("R", "03_derive_sleep_midpoint.R"))
source(file.path("R", "04_derive_mvpa_phase.R"))
source(file.path("R", "05_derive_sleep_anchored_phase.R"))

process_one_participant <- function(
  seqn,
  archive,
  batch_root,
  combined_input_compression = "none",
  delete_large_intermediates = TRUE
) {
  seqn <- as.character(seqn)

  work_root <- file.path(
    batch_root,
    paste0("GGIR_", seqn)
  )

  if (dir.exists(work_root)) {
    safe_delete_path(
      work_root,
      batch_root
    )
  }

  extract_dir <- file.path(
    work_root,
    "01_extracted"
  )

  ggir_input_dir <- file.path(
    work_root,
    "02_ggir_input"
  )

  ggir_output_dir <- file.path(
    work_root,
    "03_ggir_output"
  )

  derived_dir <- file.path(
    work_root,
    "04_derived"
  )

  for (d in c(
    extract_dir,
    ggir_input_dir,
    ggir_output_dir,
    derived_dir
  )) {
    dir.create(
      d,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }

  extract_archive_safely(
    archive,
    extract_dir
  )

  hourly_table <- identify_hourly_sensor_files(
    extract_dir
  )

  combined_extension <- if (
    identical(
      combined_input_compression,
      "gzip"
    )
  ) {
    ".csv.gz"
  } else {
    ".csv"
  }

  combined_file <- file.path(
    ggir_input_dir,
    paste0(
      seqn,
      "_raw",
      combined_extension
    )
  )

  combine_hourly_sensor_files(
    hourly_table,
    combined_file,
    compression = combined_input_compression
  )

  study_name <- run_ggir_nhanes(
    combined_file = combined_file,
    ggir_input_dir = ggir_input_dir,
    ggir_output_dir = ggir_output_dir,
    seqn = seqn
  )

  ggir_root <- find_ggir_output_root(
    ggir_output_dir,
    study_name
  )

  minute_file <- find_minute_file(
    ggir_root,
    seqn
  )

  sleep_file <- find_sleep_file(
    ggir_root
  )

  mvpa_summary <- derive_mvpa_summary(
    minute_file = minute_file,
    mvpa_threshold_mg = 100,
    min_valid_hours_per_day = 16
  )

  sleep_summary <- derive_sleep_summary(
    sleep_file = sleep_file,
    seqn = seqn
  )

  phase <- derive_primary_phase(
    mvpa_summary = mvpa_summary,
    sleep_summary = sleep_summary,
    min_valid_days = 5,
    min_valid_nights = 3,
    min_sleep_duration_h = 3,
    max_sleep_duration_h = 12,
    min_sleep_periods = 5,
    max_sleep_periods = 30,
    r_threshold = 0.30
  )

  result <- data.table::data.table(
    SEQN = seqn,
    ggir_version = as.character(
      utils::packageVersion("GGIR")
    ),
    minute_epoch_seconds =
      mvpa_summary$median_epoch_seconds,
    mvpa_threshold_mg = 100,
    n_valid_days =
      mvpa_summary$n_valid_days,
    n_valid_nights =
      sleep_summary$n_valid_nights,
    observed_total_mvpa_minutes =
      mvpa_summary$observed_total_mvpa_minutes,
    mean_mvpa_minutes_per_valid_day =
      mvpa_summary$mean_mvpa_minutes_per_valid_day,
    habitual_mvpa_phase_h =
      mvpa_summary$habitual_mvpa_phase_h,
    mvpa_resultant_length_R =
      mvpa_summary$mvpa_resultant_length_R,
    habitual_sleep_midpoint_h =
      sleep_summary$habitual_sleep_midpoint_h,
    sleep_midpoint_resultant_length_R =
      sleep_summary$sleep_midpoint_resultant_length_R,
    mean_sleep_duration_h =
      sleep_summary$mean_sleep_duration_h,
    mean_number_sleep_periods =
      sleep_summary$mean_number_sleep_periods,
    sleep_anchored_mvpa_phase_raw_h =
      phase$phase_raw_h,
    sleep_anchored_mvpa_phase_h =
      phase$phase_h,
    include_primary =
      phase$include_primary,
    exclusion_reason =
      phase$exclusion_reason
  )

  stopifnot(
    is.na(result$habitual_mvpa_phase_h) ||
      (
        result$habitual_mvpa_phase_h >= 0 &&
          result$habitual_mvpa_phase_h < 24
      ),
    is.na(result$habitual_sleep_midpoint_h) ||
      (
        result$habitual_sleep_midpoint_h >= 0 &&
          result$habitual_sleep_midpoint_h < 24
      ),
    is.na(result$sleep_anchored_mvpa_phase_raw_h) ||
      (
        result$sleep_anchored_mvpa_phase_raw_h >= 0 &&
          result$sleep_anchored_mvpa_phase_raw_h < 24
      )
  )

  atomic_fwrite(
    mvpa_summary$day_qc,
    file.path(
      derived_dir,
      "day_level_accelerometer_qc.csv"
    )
  )

  atomic_fwrite(
    mvpa_summary$minute_profile,
    file.path(
      derived_dir,
      "habitual_1440min_mvpa_profile.csv"
    )
  )

  atomic_fwrite(
    sleep_summary$night_data,
    file.path(
      derived_dir,
      "valid_nights_with_midpoints.csv"
    )
  )

  result_file <- file.path(
    derived_dir,
    "sleep_anchored_mvpa_phase_angle.csv"
  )

  atomic_fwrite(
    result,
    result_file
  )

  if (isTRUE(delete_large_intermediates)) {
    safe_delete_path(
      extract_dir,
      batch_root
    )

    safe_delete_path(
      ggir_input_dir,
      batch_root
    )

    safe_delete_path(
      ggir_output_dir,
      batch_root
    )
  }

  result
}
