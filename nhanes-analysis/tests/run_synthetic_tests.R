# ==============================================================================
# Synthetic formula-level checks
# No NHANES participant data are used.
# ==============================================================================

source(file.path("R", "00_utils.R"))

stopifnot(
  abs(
    percent_difference(log(1.01)) - 1
  ) < 1e-10
)

race_test <- recode_race4(
  c(
    "Non-Hispanic White",
    "Non-Hispanic Black",
    "Mexican American",
    "Other Hispanic",
    "Non-Hispanic Asian",
    "Other / Multi-Racial"
  )
)

stopifnot(
  identical(
    as.character(race_test),
    c(
      "Non-Hispanic White",
      "Non-Hispanic Black",
      "Hispanic",
      "Hispanic",
      "Other",
      "Other"
    )
  )
)

cat("All synthetic formula-level tests passed.\n")
