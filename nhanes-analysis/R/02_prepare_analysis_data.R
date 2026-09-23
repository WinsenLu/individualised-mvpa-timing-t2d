# ==============================================================================
# Validate and standardise one outcome-specific analysis-ready data set
# ==============================================================================

prepare_analysis_data <- function(data, spec) {
  required <- c(
    "SEQN",
    "cycle",
    "sleep_anchored_mvpa_phase_h",
    "RIDAGEYR",
    "education_binary",
    "household_income_binary",
    "smoking_binary",
    "alcohol_binary",
    "total_energy_intake_kcal",
    "HEI_score",
    "mean_mvpa_minutes_per_valid_day",
    "mean_sleep_duration_h",
    "SDMVSTRA",
    "SDMVPSU",
    spec$weight,
    spec$primary_outcome
  )

  if (!is.null(spec$raw_outcome)) {
    required <- c(required, spec$raw_outcome)
  }

  assert_required_columns(
    data,
    required,
    object_name = spec$label
  )

  data$SEQN <- as.integer(data$SEQN)

  if (any(is.na(data$SEQN))) {
    stop(spec$label, ": missing SEQN.", call. = FALSE)
  }

  if (anyDuplicated(data$SEQN) > 0L) {
    stop(spec$label, ": duplicated SEQN.", call. = FALSE)
  }

  check_allowed_values(
    data$cycle,
    c("2011-2012", "2013-2014"),
    "cycle"
  )

  if (!"sex_model" %in% names(data)) {
    assert_required_columns(data, "sex", object_name = spec$label)

    check_allowed_values(
      data$sex,
      c("Male", "Female"),
      "sex"
    )

    data$sex_model <- factor(
      data$sex,
      levels = c("Male", "Female")
    )
  }

  if (!"race4" %in% names(data)) {
    assert_required_columns(
      data,
      "race_ethnicity",
      object_name = spec$label
    )

    check_allowed_values(
      data$race_ethnicity,
      c(
        "Non-Hispanic White",
        "Non-Hispanic Black",
        "Mexican American",
        "Other Hispanic",
        "Non-Hispanic Asian",
        "Other / Multi-Racial"
      ),
      "race_ethnicity"
    )

    data$race4 <- recode_race4(
      data$race_ethnicity
    )
  }

  check_allowed_values(
    data$sex_model,
    c("Male", "Female"),
    "sex_model"
  )

  check_allowed_values(
    data$race4,
    c(
      "Non-Hispanic White",
      "Non-Hispanic Black",
      "Hispanic",
      "Other"
    ),
    "race4"
  )

  check_allowed_values(
    data$education_binary,
    c("Others", "Less than high school"),
    "education_binary"
  )

  check_allowed_values(
    data$household_income_binary,
    c(">= $20k", "<$20k"),
    "household_income_binary"
  )

  check_allowed_values(
    data$smoking_binary,
    c("No", "Yes"),
    "smoking_binary"
  )

  check_allowed_values(
    data$alcohol_binary,
    c("No", "Yes"),
    "alcohol_binary"
  )

  data$RIDAGEYR <- as.numeric(data$RIDAGEYR)
  data$sleep_anchored_mvpa_phase_h <- as.numeric(
    data$sleep_anchored_mvpa_phase_h
  )
  data$total_energy_intake_kcal <- as.numeric(
    data$total_energy_intake_kcal
  )
  data$HEI_score <- as.numeric(data$HEI_score)
  data$mean_mvpa_minutes_per_valid_day <- as.numeric(
    data$mean_mvpa_minutes_per_valid_day
  )
  data$mean_sleep_duration_h <- as.numeric(
    data$mean_sleep_duration_h
  )
  data[[spec$weight]] <- as.numeric(
    data[[spec$weight]]
  )
  data$SDMVSTRA <- as.numeric(data$SDMVSTRA)
  data$SDMVPSU <- as.numeric(data$SDMVPSU)
  data[[spec$primary_outcome]] <- as.numeric(
    data[[spec$primary_outcome]]
  )

  if (!is.null(spec$raw_outcome)) {
    data[[spec$raw_outcome]] <- as.numeric(
      data[[spec$raw_outcome]]
    )
  }

  data <- reset_factor_levels(data)

  if (identical(spec$analysis_type, "binary")) {
    outcome_values <- sort(
      unique(data[[spec$primary_outcome]])
    )

    if (
      any(is.na(data[[spec$primary_outcome]])) ||
      !all(outcome_values %in% c(0, 1))
    ) {
      stop(
        spec$label,
        ": prevalent_diabetes must be complete and coded 0/1.",
        call. = FALSE
      )
    }
  }

  if (identical(spec$analysis_type, "continuous_log")) {
    if (
      any(is.na(data[[spec$raw_outcome]])) ||
      any(is.na(data[[spec$primary_outcome]]))
    ) {
      stop(
        spec$label,
        ": raw and log-transformed outcomes must be complete.",
        call. = FALSE
      )
    }

    if (any(data[[spec$raw_outcome]] <= 0)) {
      stop(
        spec$label,
        ": raw outcome contains non-positive value(s).",
        call. = FALSE
      )
    }

    log_difference <- max(
      abs(
        data[[spec$primary_outcome]] -
          log(data[[spec$raw_outcome]])
      ),
      na.rm = TRUE
    )

    if (
      !is.finite(log_difference) ||
      log_difference > 1e-10
    ) {
      stop(
        spec$label,
        ": log-transformed outcome is inconsistent with log(raw outcome).",
        call. = FALSE
      )
    }
  }

  if (any(!is.finite(data$sleep_anchored_mvpa_phase_h))) {
    stop(spec$label, ": exposure must be complete and finite.", call. = FALSE)
  }
  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  if (any(vapply(data[numeric_columns], function(x) any(is.infinite(x)), logical(1)))) {
    stop(spec$label, ": numeric input contains infinite values.", call. = FALSE)
  }

  if (
    any(
      data$sleep_anchored_mvpa_phase_h < 0 |
        data$sleep_anchored_mvpa_phase_h >= 24
    )
  ) {
    stop(
      spec$label,
      ": sleep_anchored_mvpa_phase_h is outside [0, 24).",
      call. = FALSE
    )
  }

  if (
    any(
      data$total_energy_intake_kcal <= 0,
      na.rm = TRUE
    )
  ) {
    stop(
      spec$label,
      ": total_energy_intake_kcal contains non-positive values.",
      call. = FALSE
    )
  }

  if (
    any(
      data$HEI_score < 0 |
        data$HEI_score > 100,
      na.rm = TRUE
    )
  ) {
    stop(
      spec$label,
      ": HEI_score is outside 0-100.",
      call. = FALSE
    )
  }

  if (
    any(
      data$mean_mvpa_minutes_per_valid_day < 0,
      na.rm = TRUE
    )
  ) {
    stop(
      spec$label,
      ": mean MVPA contains negative values.",
      call. = FALSE
    )
  }

  if (
    any(
      data$mean_sleep_duration_h <= 0,
      na.rm = TRUE
    )
  ) {
    stop(
      spec$label,
      ": mean sleep duration contains non-positive values.",
      call. = FALSE
    )
  }

  if (
    any(is.na(data[[spec$weight]])) ||
      any(data[[spec$weight]] <= 0)
  ) {
    stop(
      spec$label,
      ": invalid outcome-specific survey weight.",
      call. = FALSE
    )
  }

  must_be_complete <- unique(
    c(
      "cycle",
      spec$primary_outcome,
      "sleep_anchored_mvpa_phase_h",
      "RIDAGEYR",
      "sex_model",
      "race4",
      "mean_mvpa_minutes_per_valid_day",
      "mean_sleep_duration_h",
      spec$weight,
      "SDMVSTRA",
      "SDMVPSU"
    )
  )

  missing_fixed <- must_be_complete[
    vapply(
      data[must_be_complete],
      function(x) any(is.na(x)),
      logical(1)
    )
  ]

  if (length(missing_fixed) > 0L) {
    stop(
      spec$label,
      ": unexpected missing value(s) in non-imputed variable(s): ",
      paste(missing_fixed, collapse = ", "),
      call. = FALSE
    )
  }

  data
}
