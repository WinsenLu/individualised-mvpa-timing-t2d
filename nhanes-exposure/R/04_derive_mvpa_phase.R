# ==============================================================================
# Derive participant-level habitual MVPA phase M and resultant length R
# ==============================================================================

source(file.path("R", "00_utils.R"))

derive_mvpa_summary <- function(
  minute_file,
  mvpa_threshold_mg = 100,
  min_valid_hours_per_day = 16
) {
  minute_header <- names(
    data.table::fread(
      minute_file,
      nrows = 0L,
      showProgress = FALSE
    )
  )

  targets <- c(
    "timenum",
    "ACC",
    "invalidepoch"
  )

  selected <- minute_header[
    match(tolower(targets), tolower(minute_header))
  ]

  if (anyNA(selected)) {
    stop(
      "Minute-level GGIR output is missing timenum, ACC, or invalidepoch.",
      call. = FALSE
    )
  }

  minute_data <- data.table::fread(
    minute_file,
    select = selected,
    showProgress = FALSE
  )

  rename_required_columns(
    minute_data,
    targets
  )

  minute_data[, timenum := as.numeric(timenum)]
  minute_data[, ACC := as.numeric(ACC)]
  minute_data[, invalidepoch := as.numeric(invalidepoch)]

  minute_data <- minute_data[
    is.finite(timenum) &
      is.finite(ACC) &
      !is.na(invalidepoch)
  ]

  if (nrow(minute_data) < 2L) {
    stop(
      "Minute-level GGIR output has fewer than two rows.",
      call. = FALSE
    )
  }

  if (anyDuplicated(minute_data$timenum)) {
    stop(
      "Duplicate timenum values detected in the 60-s series.",
      call. = FALSE
    )
  }

  data.table::setorder(
    minute_data,
    timenum
  )

  positive_steps <- diff(
    minute_data$timenum
  )

  positive_steps <- positive_steps[
    is.finite(positive_steps) &
      positive_steps > 0 &
      positive_steps <= 600
  ]

  median_epoch_seconds <- stats::median(
    positive_steps
  )

  if (
    !is.finite(median_epoch_seconds) ||
      abs(median_epoch_seconds - 60) > 0.01
  ) {
    stop(
      "GGIR Part 5 time series is not at 60-s resolution.",
      call. = FALSE
    )
  }

  minute_data[
    ,
    valid_epoch := invalidepoch == 0
  ]

  minute_data[
    ,
    timestamp := as.POSIXct(
      timenum,
      origin = "1970-01-01",
      tz = "UTC"
    )
  ]

  minute_data[
    ,
    date := as.Date(
      timestamp,
      tz = "UTC"
    )
  ]

  minute_data[
    ,
    minute_of_day :=
      as.integer(
        floor(
          (timenum %% 86400) / 60
        )
      )
  ]

  if (
    any(
      minute_data$minute_of_day < 0 |
        minute_data$minute_of_day > 1439
    )
  ) {
    stop(
      "minute_of_day is outside 0-1439.",
      call. = FALSE
    )
  }

  day_qc <- minute_data[
    ,
    .(
      valid_minutes = sum(valid_epoch),
      invalid_minutes = sum(!valid_epoch),
      mvpa_minutes_all_valid_epochs = sum(
        valid_epoch &
          ACC >= mvpa_threshold_mg
      )
    ),
    by = date
  ]

  day_qc[
    ,
    valid_day :=
      valid_minutes >=
        min_valid_hours_per_day * 60
  ]

  valid_dates <- day_qc[
    valid_day == TRUE,
    date
  ]

  activity_data <- minute_data[
    valid_epoch == TRUE &
      date %in% valid_dates
  ]

  n_valid_days <- length(
    valid_dates
  )

  minute_profile <- data.table::data.table(
    minute_of_day = 0:1439
  )

  observed_profile <- activity_data[
    ,
    .(
      valid_observations = .N,
      mvpa_minutes = sum(
        ACC >= mvpa_threshold_mg
      )
    ),
    by = minute_of_day
  ]

  minute_profile <- merge(
    minute_profile,
    observed_profile,
    by = "minute_of_day",
    all.x = TRUE
  )

  minute_profile[
    is.na(valid_observations),
    valid_observations := 0L
  ]

  minute_profile[
    is.na(mvpa_minutes),
    mvpa_minutes := 0L
  ]

  minute_profile[
    ,
    clock_hour_midpoint :=
      (minute_of_day + 0.5) / 60
  ]

  minute_profile[
    ,
    mvpa_probability :=
      ifelse(
        valid_observations > 0,
        mvpa_minutes / valid_observations,
        NA_real_
      )
  ]

  total_mvpa_minutes <- sum(
    minute_profile$mvpa_minutes
  )

  mvpa_circular <- circular_summary_hours(
    hours = minute_profile$clock_hour_midpoint,
    weights = minute_profile$mvpa_minutes
  )

  mean_mvpa_minutes_per_valid_day <- if (n_valid_days > 0L) {
    total_mvpa_minutes / n_valid_days
  } else {
    NA_real_
  }

  list(
    day_qc = day_qc,
    minute_profile = minute_profile,
    median_epoch_seconds = median_epoch_seconds,
    n_valid_days = n_valid_days,
    observed_total_mvpa_minutes = total_mvpa_minutes,
    mean_mvpa_minutes_per_valid_day = mean_mvpa_minutes_per_valid_day,
    habitual_mvpa_phase_h = mvpa_circular$phase_h,
    mvpa_resultant_length_R = mvpa_circular$R
  )
}
