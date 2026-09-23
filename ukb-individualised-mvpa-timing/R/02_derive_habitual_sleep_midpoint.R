# ==============================================================================
# 02_derive_habitual_sleep_midpoint.R
#
# Derive participant-level habitual sleep midpoint from:
#   part4_nightsummary_sleep_cleaned.csv
#
# Study software:
#   GGIR 3.0.0
#
# Required columns:
#   ID
#   night
#   sleeponset
#   wakeup
#   SleepDurationInSpt
#   number_sib_sleepperiod
#
# The study calculation:
#   1) calculate a midpoint for each valid night;
#   2) wrap each midpoint to the 24-h clock;
#   3) take the circular mean across nights.
#
# Run from repository root:
#   Rscript R/02_derive_habitual_sleep_midpoint.R
# ==============================================================================

source(file.path("R", "00_utils.R"))

derive_habitual_sleep_midpoint <- function(night_data) {
  required <- c(
    "ID",
    "night",
    "sleeponset",
    "wakeup",
    "SleepDurationInSpt",
    "number_sib_sleepperiod"
  )

  assert_required_columns(
    night_data,
    required,
    object_name = "GGIR night summary"
  )

  participant_id <- standardise_ggir_participant_id(night_data$ID)

  sleeponset_h <- suppressWarnings(as.numeric(night_data$sleeponset))
  wakeup_h <- suppressWarnings(as.numeric(night_data$wakeup))

  valid_timing <- is.finite(sleeponset_h) & is.finite(wakeup_h)

  if (!any(valid_timing)) {
    stop(
      "No rows contain finite sleeponset and wakeup values.",
      call. = FALSE
    )
  }

  # GGIR's continuous decimal-hour representation should retain temporal order:
  # wakeup is later than sleeponset and may therefore exceed 24 after midnight.
  duration_h <- wakeup_h - sleeponset_h

  invalid_order <- valid_timing & (
    !is.finite(duration_h) |
      duration_h <= 0 |
      duration_h > 24
  )

  if (any(invalid_order)) {
    stop(
      "Detected GGIR rows where wakeup is not later than sleeponset on the ",
      "continuous decimal-hour scale, or the interval exceeds 24 h. ",
      "Inspect the private GGIR input rather than silently correcting these rows.",
      call. = FALSE
    )
  }

  nightly_midpoint_h <- rep(NA_real_, nrow(night_data))
  nightly_midpoint_h[valid_timing] <- (
    (
      sleeponset_h[valid_timing] +
        wakeup_h[valid_timing]
    ) / 2
  ) %% 24

  work <- data.frame(
    participant_id = participant_id,
    night = night_data$night,
    nightly_sleep_midpoint_h = nightly_midpoint_h,
    sleep_duration_h = suppressWarnings(
      as.numeric(night_data$SleepDurationInSpt)
    ),
    sleep_period_count = suppressWarnings(
      as.numeric(night_data$number_sib_sleepperiod)
    ),
    stringsAsFactors = FALSE
  )

  work <- work[
    is.finite(work$nightly_sleep_midpoint_h),
    ,
    drop = FALSE
  ]

  split_data <- split(
    work,
    work$participant_id,
    drop = TRUE
  )

  result_list <- lapply(
    split_data,
    function(x) {
      data.frame(
        participant_id = x$participant_id[1L],
        n_valid_nights = nrow(x),
        habitual_sleep_midpoint_h = circular_mean_hours(
          x$nightly_sleep_midpoint_h
        ),
        mean_sleep_duration_h = mean_or_na(x$sleep_duration_h),
        mean_sleep_period_count = mean_or_na(x$sleep_period_count),
        stringsAsFactors = FALSE
      )
    }
  )

  result <- do.call(rbind, result_list)
  rownames(result) <- NULL

  result
}

main <- function() {
  cfg <- load_private_config()

  required_cfg <- c("NIGHT_SUMMARY_CSV", "PRIVATE_OUTPUT_DIR")
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

  night_data <- read_private_csv(cfg$NIGHT_SUMMARY_CSV)

  sleep_summary <- derive_habitual_sleep_midpoint(night_data)

  output_path <- file.path(
    cfg$PRIVATE_OUTPUT_DIR,
    "02_sleep_summary.csv"
  )

  write_private_csv(sleep_summary, output_path)

  message(
    "Sleep summary derived for ",
    nrow(sleep_summary),
    " participants. Participant-level output remains private."
  )
}

if (sys.nframe() == 0L) {
  main()
}
