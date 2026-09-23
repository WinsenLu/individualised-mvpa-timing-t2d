# ==============================================================================
# Synthetic formula-level tests
#
# These tests generate artificial data in memory only.
# No UK Biobank participant-level data are used.
#
# Run from repository root:
#   Rscript tests/run_synthetic_tests.R
# ==============================================================================

source(file.path("R", "00_utils.R"))
source(file.path("R", "02_derive_habitual_sleep_midpoint.R"))
source(file.path("R", "03_derive_MVPA_circular_metrics.R"))
source(file.path("R", "04_derive_sleep_anchored_exposure.R"))

assert_close <- function(observed, expected, tol = 1e-8, label = "") {
  if (
    length(observed) != length(expected) ||
      any(abs(observed - expected) > tol)
  ) {
    stop(
      "Synthetic test failed: ",
      label,
      "\nObserved: ",
      paste(observed, collapse = ", "),
      "\nExpected: ",
      paste(expected, collapse = ", "),
      call. = FALSE
    )
  }
}

# ------------------------------------------------------------------------------
# Test 1: nightly midpoint across midnight
# ------------------------------------------------------------------------------

night_example <- data.frame(
  ID = c("SYNTHETIC_A_90001_0_0.cwa", "SYNTHETIC_A_90001_0_0.cwa"),
  night = c(1, 2),
  sleeponset = c(23, 23),
  wakeup = c(31, 31),
  SleepDurationInSpt = c(7, 7),
  number_sib_sleepperiod = c(10, 10),
  stringsAsFactors = FALSE
)

sleep_result <- derive_habitual_sleep_midpoint(night_example)

assert_close(
  sleep_result$habitual_sleep_midpoint_h,
  3,
  label = "23:00 to 07:00 midpoint should be 03:00"
)

# ------------------------------------------------------------------------------
# Test 2: circular mean near midnight
# ------------------------------------------------------------------------------

cm <- circular_mean_hours(c(23.5, 0.5))

if (!(cm < 1e-8 || abs(cm - 24) < 1e-8)) {
  stop(
    "Synthetic test failed: circular mean of 23.5 and 0.5 should be midnight.",
    call. = FALSE
  )
}

# ------------------------------------------------------------------------------
# Test 3: MVPA centroid and R for one occupied hourly bin
# ------------------------------------------------------------------------------

wear_names <- sprintf("wear_h%02d", 0:23)

one_bin_profile <- rep(0, 24)
one_bin_profile[14] <- 1
# Bin 14 in R indexing corresponds to 13:00-13:59, midpoint 13.5 h.

mvpa_one <- data.frame(
  participant_id = "SYNTHETIC_A",
  mvpa_hourly_profile = paste(one_bin_profile, collapse = ","),
  stringsAsFactors = FALSE
)

for (nm in wear_names) {
  mvpa_one[[nm]] <- 1
}

mvpa_one_result <- derive_mvpa_circular_metrics(mvpa_one)

assert_close(
  mvpa_one_result$mvpa_centroid_h,
  13.5,
  tol = 1e-8,
  label = "single occupied bin centroid"
)

assert_close(
  mvpa_one_result$mvpa_resultant_length,
  1,
  tol = 1e-8,
  label = "single occupied bin R"
)

# ------------------------------------------------------------------------------
# Test 4: uniform MVPA profile should have R approximately zero
# ------------------------------------------------------------------------------

uniform_mvpa <- data.frame(
  participant_id = "SYNTHETIC_B",
  mvpa_hourly_profile = paste(rep(1, 24), collapse = ","),
  stringsAsFactors = FALSE
)

for (nm in wear_names) {
  uniform_mvpa[[nm]] <- 1
}

uniform_result <- derive_mvpa_circular_metrics(uniform_mvpa)

if (
  !is.finite(uniform_result$mvpa_resultant_length) ||
    uniform_result$mvpa_resultant_length > 1e-12
) {
  stop(
    "Synthetic test failed: uniform 24-h MVPA profile should have R near zero.",
    call. = FALSE
  )
}

# ------------------------------------------------------------------------------
# Test 5: modulo-24 sleep-anchored phase
# ------------------------------------------------------------------------------

sleep_small <- data.frame(
  participant_id = paste0("S", 1:10),
  habitual_sleep_midpoint_h = rep(23, 10),
  mean_sleep_duration_h = rep(7, 10),
  mean_sleep_period_count = rep(10, 10),
  stringsAsFactors = FALSE
)

mvpa_small <- data.frame(
  participant_id = paste0("S", 1:10),
  mvpa_centroid_h = seq(0, 9),
  mvpa_resultant_length = rep(0.8, 10),
  stringsAsFactors = FALSE
)

elig_small <- data.frame(
  participant_id = paste0("S", 1:10),
  baseline_diabetes = rep(0, 10),
  stringsAsFactors = FALSE
)

final_small <- derive_sleep_anchored_exposure(
  sleep_summary = sleep_small,
  mvpa_metrics = mvpa_small,
  eligibility = elig_small
)

assert_close(
  final_small$phase_angle_h[1],
  1,
  label = "(00:00 - 23:00) mod 24 should equal 1 h"
)

# ------------------------------------------------------------------------------
# Test 6: equal-frequency quintiles
# ------------------------------------------------------------------------------

q <- ntile_equal_frequency(1:10, 5)

if (!identical(as.integer(q), rep(1:5, each = 2))) {
  stop(
    "Synthetic test failed: equal-frequency quintile allocation.",
    call. = FALSE
  )
}

cat("All synthetic tests passed.\n")
