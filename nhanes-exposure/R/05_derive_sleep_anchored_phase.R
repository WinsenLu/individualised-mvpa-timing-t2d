# ==============================================================================
# Apply exposure QC and derive the primary sleep-anchored MVPA phase
# ==============================================================================

source(file.path("R", "00_utils.R"))

derive_primary_phase <- function(
  mvpa_summary,
  sleep_summary,
  min_valid_days = 5,
  min_valid_nights = 3,
  min_sleep_duration_h = 3,
  max_sleep_duration_h = 12,
  min_sleep_periods = 5,
  max_sleep_periods = 30,
  r_threshold = 0.30
) {
  valid_days_ok <-
    mvpa_summary$n_valid_days >= min_valid_days

  valid_nights_ok <-
    sleep_summary$n_valid_nights >= min_valid_nights

  sleep_duration_ok <-
    is.finite(sleep_summary$mean_sleep_duration_h) &&
      sleep_summary$mean_sleep_duration_h >= min_sleep_duration_h &&
      sleep_summary$mean_sleep_duration_h <= max_sleep_duration_h

  sleep_period_count_ok <-
    is.finite(sleep_summary$mean_number_sleep_periods) &&
      sleep_summary$mean_number_sleep_periods >= min_sleep_periods &&
      sleep_summary$mean_number_sleep_periods <= max_sleep_periods

  any_mvpa <-
    is.finite(mvpa_summary$observed_total_mvpa_minutes) &&
      mvpa_summary$observed_total_mvpa_minutes > 0

  r_ok <-
    is.finite(mvpa_summary$mvpa_resultant_length_R) &&
      mvpa_summary$mvpa_resultant_length_R >= r_threshold

  phase_raw_h <- forward_phase_angle(
    mvpa_summary$habitual_mvpa_phase_h,
    sleep_summary$habitual_sleep_midpoint_h
  )

  phase_finite <- is.finite(
    phase_raw_h
  )

  include_primary <- all(
    valid_days_ok,
    valid_nights_ok,
    sleep_duration_ok,
    sleep_period_count_ok,
    any_mvpa,
    r_ok,
    phase_finite
  )

  reasons <- character()

  if (!valid_days_ok) {
    reasons <- c(reasons, paste0("valid_days<", min_valid_days))
  }

  if (!valid_nights_ok) {
    reasons <- c(reasons, paste0("valid_nights<", min_valid_nights))
  }

  if (!sleep_duration_ok) {
    reasons <- c(
      reasons,
      "mean_sleep_duration_outside_3_to_12h"
    )
  }

  if (!sleep_period_count_ok) {
    reasons <- c(
      reasons,
      "mean_sleep_period_count_outside_5_to_30"
    )
  }

  if (!any_mvpa) {
    reasons <- c(
      reasons,
      "zero_MVPA"
    )
  }

  if (any_mvpa && !r_ok) {
    reasons <- c(
      reasons,
      paste0("R<", r_threshold)
    )
  }

  if (!phase_finite) {
    reasons <- c(
      reasons,
      "nonfinite_phase_angle"
    )
  }

  exclusion_reason <- if (length(reasons) == 0L) {
    "included"
  } else {
    paste(
      reasons,
      collapse = ";"
    )
  }

  list(
    phase_raw_h = phase_raw_h,
    phase_h = if (include_primary) phase_raw_h else NA_real_,
    include_primary = include_primary,
    exclusion_reason = exclusion_reason
  )
}
