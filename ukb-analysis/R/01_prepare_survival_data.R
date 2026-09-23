# ==============================================================================
# Construct UK Biobank prospective follow-up variables
# ==============================================================================

source(file.path("R", "00_utils.R"))

prepare_survival_data <- function(data) {
  required <- c(
    "Baseline_Date",
    "Date_E11_first_reported_.non.insulin.dependent_diabetes_mellitus.",
    "Date_of_death",
    "Date_lost_to_follow.up",
    "UK_Biobank_assessment_centre",
    "Exposure",
    "Phase_angle_hour",
    "Age",
    "Sex",
    "TDI",
    "Smoking",
    "Ethnic",
    "Qualifications",
    "Occupation",
    "Alcohol",
    "Healthy_diet_score",
    "Coffee_tea",
    "Hypertension",
    "Dyslipidemia",
    "Depression",
    "Accelerometer_season",
    "CVD",
    "Family_history_diabetes",
    "MVPA_daily_min",
    "Average_Sleep_Duration",
    "R_MVPA"
  )

  assert_required_columns(
    data,
    required,
    object_name = "UK Biobank primary-analysis input"
  )

  data$Baseline_Date <- parse_date_vector(
    data$Baseline_Date
  )

  data$Date_E11 <- parse_date_vector(
    data$Date_E11_first_reported_.non.insulin.dependent_diabetes_mellitus.
  )

  data$Date_of_death <- parse_date_vector(
    data$Date_of_death
  )

  data$Date_lost <- parse_date_vector(
    data$Date_lost_to_follow.up
  )

  data$Censor_Limit <- as.Date(NA)

  data$Censor_Limit[
    data$UK_Biobank_assessment_centre == "England"
  ] <- as.Date("2023-03-31")

  data$Censor_Limit[
    data$UK_Biobank_assessment_centre == "Scotland"
  ] <- as.Date("2022-08-31")

  data$Censor_Limit[
    data$UK_Biobank_assessment_centre == "Wales"
  ] <- as.Date("2022-05-31")

  if (any(is.na(data$Censor_Limit))) {
    stop(
      "Missing or unrecognised UK_Biobank_assessment_centre value(s). ",
      "Expected England, Scotland, or Wales.",
      call. = FALSE
    )
  }

  # pmin for Date objects is used only after a non-missing administrative
  # censoring date has been assigned to every participant.
  data$Study_End <- pmin(
    data$Date_of_death,
    data$Date_lost,
    data$Censor_Limit,
    na.rm = TRUE
  )

  data$Followup_End <- pmin(
    data$Date_E11,
    data$Study_End,
    na.rm = TRUE
  )

  data$status <- as.integer(
    !is.na(data$Date_E11) &
      !is.na(data$Baseline_Date) &
      data$Date_E11 > data$Baseline_Date &
      data$Date_E11 <= data$Study_End
  )

  data$time_years <- as.numeric(
    difftime(
      data$Followup_End,
      data$Baseline_Date,
      units = "days"
    )
  ) / 365.25

  data <- data[
    is.finite(data$time_years) &
      data$time_years > 0,
    ,
    drop = FALSE
  ]

  if (nrow(data) == 0L) {
    stop(
      "No participants remain after requiring positive follow-up time.",
      call. = FALSE
    )
  }

  # Convert categorical analysis variables to unordered factors.
  factor_vars <- c(
    "Exposure",
    "Sex",
    "Occupation",
    "Smoking",
    "Ethnic",
    "Qualifications",
    "Hypertension",
    "Dyslipidemia",
    "Depression",
    "Accelerometer_season",
    "CVD",
    "Family_history_diabetes"
  )

  data[factor_vars] <- lapply(
    data[factor_vars],
    function(x) factor(as.character(x), ordered = FALSE)
  )

  if (!"Q1" %in% levels(data$Exposure)) {
    stop(
      "Exposure must contain Q1 so that Q1 can be used as the reference group.",
      call. = FALSE
    )
  }

  data$Exposure <- stats::relevel(
    data$Exposure,
    ref = "Q1"
  )

  data
}
