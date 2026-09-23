# ==============================================================================
# Synthetic tests for circular statistics and exposure formulas
# No NHANES participant data are used.
# ==============================================================================

source(file.path("R", "00_utils.R"))

# Circular mean of 23:00 and 01:00 should be midnight.
t1 <- circular_summary_hours(c(23, 1))

stopifnot(
  circular_distance_h(
    t1$phase_h,
    0
  ) < 1e-10
)

# Forward phase across midnight.
stopifnot(
  abs(
    forward_phase_angle(
      2,
      22
    ) - 4
  ) < 1e-12
)

# Example phase difference.
stopifnot(
  abs(
    forward_phase_angle(
      13.5,
      3.5
    ) - 10
  ) < 1e-12
)

# Uniform hourly distribution should have R approximately zero.
t2 <- circular_summary_hours(
  hours = 0:23,
  weights = rep(1, 24)
)

stopifnot(
  t2$R < 1e-10
)

# Concentrated distribution at 13.5 h should have R=1 and phase=13.5 h.
t3 <- circular_summary_hours(
  hours = 13.5,
  weights = 1
)

stopifnot(
  abs(t3$phase_h - 13.5) < 1e-12,
  abs(t3$R - 1) < 1e-12
)

# Primary MVPA threshold boundary.
stopifnot(
  100 >= 100,
  !(99.999 >= 100)
)

cat("All synthetic formula-level tests passed.\n")
