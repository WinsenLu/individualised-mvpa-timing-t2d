# ==============================================================================
# Shared utilities for NHANES sleep-anchored MVPA timing derivation
# ==============================================================================

now_text <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
}

normalise_path_soft <- function(path) {
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

assert_required_columns <- function(data, required, object_name = "data") {
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      object_name, " is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

find_column_case_insensitive <- function(data, target, required = TRUE) {
  idx <- match(tolower(target), tolower(names(data)))
  if (is.na(idx)) {
    if (required) {
      stop("Required column was not found: ", target, call. = FALSE)
    }
    return(NA_character_)
  }
  names(data)[idx]
}

rename_required_columns <- function(data, targets) {
  for (target in targets) {
    actual <- find_column_case_insensitive(data, target, required = TRUE)
    if (!identical(actual, target)) {
      data.table::setnames(data, actual, target)
    }
  }
  invisible(data)
}

atomic_fwrite <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(pattern = "atomic_", tmpdir = dirname(path), fileext = ".csv")
  data.table::fwrite(x, tmp)
  ok <- file.copy(tmp, path, overwrite = TRUE)
  unlink(tmp, force = TRUE)
  if (!isTRUE(ok)) {
    stop("Failed to write file: ", path, call. = FALSE)
  }
  invisible(path)
}

safe_delete_path <- function(path, allowed_root) {
  if (!file.exists(path) && !dir.exists(path)) {
    return(invisible(FALSE))
  }

  root_abs <- normalise_path_soft(allowed_root)
  path_abs <- normalise_path_soft(path)
  root_key <- tolower(sub("/+$", "", root_abs))
  path_key <- tolower(sub("/+$", "", path_abs))

  if (
    identical(path_key, root_key) ||
      !startsWith(path_key, paste0(root_key, "/"))
  ) {
    stop(
      "Refused deletion outside the permitted processing root.\n",
      "Allowed root: ", root_abs, "\n",
      "Requested path: ", path_abs,
      call. = FALSE
    )
  }

  unlink(path, recursive = TRUE, force = TRUE)
  invisible(TRUE)
}

circular_summary_hours <- function(hours, weights = NULL) {
  hours <- as.numeric(hours)

  if (is.null(weights)) {
    weights <- rep(1, length(hours))
  }

  weights <- as.numeric(weights)

  keep <- is.finite(hours) & is.finite(weights) & weights > 0
  hours <- hours[keep] %% 24
  weights <- weights[keep]

  if (length(hours) == 0L || sum(weights) <= 0) {
    return(list(phase_h = NA_real_, R = NA_real_))
  }

  theta <- 2 * pi * hours / 24

  C <- sum(weights * cos(theta)) / sum(weights)
  S <- sum(weights * sin(theta)) / sum(weights)

  R <- sqrt(C^2 + S^2)

  angle <- atan2(S, C) %% (2 * pi)
  phase_h <- angle * 24 / (2 * pi)

  list(
    phase_h = phase_h,
    R = R
  )
}

forward_phase_angle <- function(mvpa_phase_h, sleep_midpoint_h) {
  (mvpa_phase_h - sleep_midpoint_h) %% 24
}

circular_distance_h <- function(a, b) {
  abs(((a - b + 12) %% 24) - 12)
}

load_config <- function() {
  config_path <- Sys.getenv(
    "NHANES_MVPA_CONFIG",
    unset = file.path("config", "config.R")
  )

  if (!file.exists(config_path)) {
    stop(
      "Configuration file not found: ", config_path, "\n",
      "Copy config/config.example.R to config/config.R and edit the paths.",
      call. = FALSE
    )
  }

  env <- new.env(parent = baseenv())
  sys.source(config_path, envir = env)
  env
}
