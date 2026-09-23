# ==============================================================================
# Derive participant-level habitual sleep midpoint S
# ==============================================================================

source(file.path("R", "00_utils.R"))

derive_sleep_summary <- function(sleep_file, seqn) {
  sleep_header <- names(
    data.table::fread(
      sleep_file,
      nrows = 0L,
      showProgress = FALSE
    )
  )

  required_targets <- c(
    "ID",
    "sleeponset",
    "wakeup",
    "SptDuration",
    "SleepDurationInSpt",
    "number_sib_sleepperiod"
  )

  required_select <- sleep_header[
    match(
      tolower(required_targets),
      tolower(sleep_header)
    )
  ]

  if (anyNA(required_select)) {
    missing <- required_targets[is.na(required_select)]

    stop(
      "Sleep summary is missing required study variable(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  optional_acc <- sleep_header[
    match("acc_available", tolower(sleep_header))
  ]

  select_columns <- c(
    required_select,
    optional_acc[!is.na(optional_acc)]
  )

  sleep_data <- data.table::fread(
    sleep_file,
    select = select_columns,
    showProgress = FALSE
  )

  rename_required_columns(
    sleep_data,
    required_targets
  )

  sleep_data[, ID := as.character(ID)]
  sleep_data <- sleep_data[ID == as.character(seqn)]

  sleep_data[, sleeponset := as.numeric(sleeponset)]
  sleep_data[, wakeup := as.numeric(wakeup)]
  sleep_data[, SptDuration := as.numeric(SptDuration)]
  sleep_data[, SleepDurationInSpt := as.numeric(SleepDurationInSpt)]
  sleep_data[, number_sib_sleepperiod := as.numeric(number_sib_sleepperiod)]

  sleep_data <- sleep_data[
    is.finite(sleeponset) &
      is.finite(wakeup) &
      is.finite(SptDuration) &
      wakeup > sleeponset &
      SptDuration > 0 &
      SptDuration <= 24
  ]

  acc_available_col <- find_column_case_insensitive(
    sleep_data,
    "acc_available",
    required = FALSE
  )

  if (!is.na(acc_available_col)) {
    sleep_data <- sleep_data[
      is.na(get(acc_available_col)) |
        as.character(get(acc_available_col)) %in% c("TRUE", "1")
    ]
  }

  n_valid_nights <- nrow(sleep_data)

  sleep_data[
    ,
    nightly_sleep_midpoint_h :=
      ((sleeponset + wakeup) / 2) %% 24
  ]

  sleep_circular <- circular_summary_hours(
    sleep_data$nightly_sleep_midpoint_h
  )

  mean_sleep_duration_h <- if (n_valid_nights > 0L) {
    mean(
      sleep_data$SleepDurationInSpt,
      na.rm = TRUE
    )
  } else {
    NA_real_
  }

  mean_number_sleep_periods <- if (n_valid_nights > 0L) {
    mean(
      sleep_data$number_sib_sleepperiod,
      na.rm = TRUE
    )
  } else {
    NA_real_
  }

  list(
    night_data = sleep_data,
    n_valid_nights = n_valid_nights,
    habitual_sleep_midpoint_h = sleep_circular$phase_h,
    sleep_midpoint_resultant_length_R = sleep_circular$R,
    mean_sleep_duration_h = mean_sleep_duration_h,
    mean_number_sleep_periods = mean_number_sleep_periods
  )
}
