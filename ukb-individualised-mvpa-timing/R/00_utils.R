# ==============================================================================
# Utility functions for UK Biobank individualised MVPA timing derivation
# ==============================================================================

assert_required_columns <- function(data, required, object_name = "data") {
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      object_name,
      " is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

read_private_csv <- function(path) {
  if (!file.exists(path)) {
    stop("Private input file not found: ", path, call. = FALSE)
  }

  utils::read.csv(
    path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_private_csv <- function(data, path) {
  output_dir <- dirname(path)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  utils::write.csv(
    data,
    file = path,
    row.names = FALSE,
    na = ""
  )

  invisible(path)
}

mean_or_na <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[is.finite(x)]

  if (length(x) == 0L) {
    return(NA_real_)
  }

  mean(x)
}

# Circular mean for clock time represented in decimal hours.
circular_mean_hours <- function(x, period = 24) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[is.finite(x)]

  if (length(x) == 0L) {
    return(NA_real_)
  }

  theta <- 2 * pi * (x %% period) / period

  mean_cos <- mean(cos(theta))
  mean_sin <- mean(sin(theta))

  resultant <- sqrt(mean_cos^2 + mean_sin^2)

  # A circular mean is not interpretable when the mean vector collapses to zero.
  if (!is.finite(resultant) || resultant < 1e-12) {
    return(NA_real_)
  }

  angle <- atan2(mean_sin, mean_cos)

  if (angle < 0) {
    angle <- angle + 2 * pi
  }

  angle * period / (2 * pi)
}

# GGIR ID is treated only as a private join key.
# No participant IDs should ever be written to the public repository.
standardise_ggir_participant_id <- function(x) {
  x <- basename(as.character(x))
  sub("_90001_0_0\\.cwa$", "", x)
}

# Rank-based quintiles using floor((rank - 1) * n / length(x)) + 1.
# Ties are resolved by input row order; this definition is not dplyr::ntile.
ntile_equal_frequency <- function(x, n = 5L) {
  if (length(x) == 0L) {
    return(integer(0))
  }

  if (any(!is.finite(x))) {
    stop("ntile_equal_frequency() requires complete finite values.", call. = FALSE)
  }

  n <- as.integer(n)

  if (n < 1L) {
    stop("n must be >= 1.", call. = FALSE)
  }

  # Secondary key preserves original row order when exact ties occur.
  ord <- order(x, seq_along(x))

  rank_position <- seq_along(ord)

  groups_sorted <- floor((rank_position - 1L) * n / length(x)) + 1L

  out <- integer(length(x))
  out[ord] <- groups_sorted
  out
}

load_private_config <- function() {
  config_path <- Sys.getenv(
    "UKB_MVPA_CONFIG",
    unset = file.path("config", "config.R")
  )

  if (!file.exists(config_path)) {
    stop(
      "Private configuration file not found: ",
      config_path,
      "\nCopy config/config.example.R to config/config.R and edit the private paths.",
      call. = FALSE
    )
  }

  config_env <- new.env(parent = baseenv())
  sys.source(config_path, envir = config_env)

  config_env
}
