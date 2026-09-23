# ==============================================================================
# 03_derive_MVPA_circular_metrics.R
#
# Derive the wear-time-weighted circular centroid and resultant vector length
# from the UK Biobank 24-h MVPA profile.
#
# Standardised private input columns:
#   participant_id
#   mvpa_hourly_profile       <- UK Biobank field 40033
#   wear_h00 ... wear_h23     <- UK Biobank fields 90060 ... 90083
#
# Run from repository root:
#   Rscript R/03_derive_MVPA_circular_metrics.R
# ==============================================================================

source(file.path("R", "00_utils.R"))

parse_mvpa_profile_24 <- function(x) {
  pieces <- strsplit(
    as.character(x),
    split = ",",
    fixed = TRUE
  )

  lengths <- lengths(pieces)

  if (any(lengths != 24L)) {
    bad_n <- sum(lengths != 24L)

    stop(
      bad_n,
      " row(s) of mvpa_hourly_profile do not contain exactly 24 values.",
      call. = FALSE
    )
  }

  out <- t(
    vapply(
      pieces,
      function(v) {
        suppressWarnings(as.numeric(trimws(v)))
      },
      FUN.VALUE = numeric(24)
    )
  )

  storage.mode(out) <- "double"
  out
}

derive_mvpa_circular_metrics <- function(mvpa_data) {
  wear_columns <- sprintf("wear_h%02d", 0:23)

  required <- c(
    "participant_id",
    "mvpa_hourly_profile",
    wear_columns
  )

  assert_required_columns(
    mvpa_data,
    required,
    object_name = "Hourly MVPA input"
  )

  participant_id <- as.character(mvpa_data$participant_id)

  if (anyDuplicated(participant_id)) {
    stop(
      "Hourly MVPA input contains duplicate participant_id values.",
      call. = FALSE
    )
  }

  mvpa_matrix <- parse_mvpa_profile_24(
    mvpa_data$mvpa_hourly_profile
  )

  wear_matrix <- as.matrix(
    mvpa_data[, wear_columns, drop = FALSE]
  )

  suppressWarnings(
    storage.mode(wear_matrix) <- "double"
  )

  if (any(mvpa_matrix < 0, na.rm = TRUE)) {
    stop("Negative MVPA profile values detected.", call. = FALSE)
  }

  if (any(wear_matrix < 0, na.rm = TRUE)) {
    stop("Negative hourly wear-duration values detected.", call. = FALSE)
  }

  # Wear-time weighting:
  # hourly MVPA profile x corresponding hourly wear duration x 60 min/h.
  weighted_mvpa_min <- mvpa_matrix * wear_matrix * 60

  # Non-finite hourly products contribute zero to the weighted 24-h vector.
  weighted_mvpa_min_zero <- weighted_mvpa_min
  weighted_mvpa_min_zero[
    !is.finite(weighted_mvpa_min_zero)
  ] <- 0

  valid_wear_days <- rowSums(
    wear_matrix,
    na.rm = TRUE
  ) / 24

  valid_wear_days[
    !is.finite(valid_wear_days) |
      valid_wear_days <= 0
  ] <- NA_real_

  total_weighted_mvpa_min <- rowSums(
    weighted_mvpa_min_zero
  )

  mvpa_daily_min <- total_weighted_mvpa_min / valid_wear_days

  # Each hourly bin is represented by its temporal midpoint:
  # 0.5, 1.5, ..., 23.5 h.
  hour_midpoint <- seq(
    from = 0.5,
    to = 23.5,
    by = 1
  )

  theta <- 2 * pi * hour_midpoint / 24

  cosine_component <- cos(theta)
  sine_component <- sin(theta)

  C_mvpa <- as.vector(
    weighted_mvpa_min_zero %*% cosine_component
  )

  S_mvpa <- as.vector(
    weighted_mvpa_min_zero %*% sine_component
  )

  mvpa_resultant_length <- ifelse(
    total_weighted_mvpa_min > 0,
    sqrt(C_mvpa^2 + S_mvpa^2) /
      total_weighted_mvpa_min,
    NA_real_
  )

  mvpa_angle <- atan2(
    S_mvpa,
    C_mvpa
  )

  mvpa_angle[
    is.finite(mvpa_angle) & mvpa_angle < 0
  ] <- mvpa_angle[
    is.finite(mvpa_angle) & mvpa_angle < 0
  ] + 2 * pi

  mvpa_centroid_h <- ifelse(
    total_weighted_mvpa_min > 0,
    mvpa_angle * 24 / (2 * pi),
    NA_real_
  )

  data.frame(
    participant_id = participant_id,
    valid_wear_days = valid_wear_days,
    total_weighted_mvpa_min = total_weighted_mvpa_min,
    mvpa_daily_min = mvpa_daily_min,
    mvpa_centroid_h = mvpa_centroid_h,
    mvpa_resultant_length = mvpa_resultant_length,
    stringsAsFactors = FALSE
  )
}

main <- function() {
  cfg <- load_private_config()

  required_cfg <- c("MVPA_INPUT_CSV", "PRIVATE_OUTPUT_DIR")
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

  mvpa_data <- read_private_csv(cfg$MVPA_INPUT_CSV)

  mvpa_metrics <- derive_mvpa_circular_metrics(mvpa_data)

  output_path <- file.path(
    cfg$PRIVATE_OUTPUT_DIR,
    "03_mvpa_circular_metrics.csv"
  )

  write_private_csv(mvpa_metrics, output_path)

  message(
    "MVPA circular metrics derived for ",
    nrow(mvpa_metrics),
    " participants. Participant-level output remains private."
  )
}

if (sys.nframe() == 0L) {
  main()
}
