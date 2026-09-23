# ==============================================================================
# Shared utilities for NHANES main analysis
# ==============================================================================

assert_packages <- function(packages) {
  missing <- packages[
    !vapply(
      packages,
      requireNamespace,
      logical(1),
      quietly = TRUE
    )
  ]

  if (length(missing) > 0L) {
    stop(
      "Missing R package(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

assert_required_columns <- function(data, required, object_name = "data") {
  missing <- setdiff(required, names(data))

  if (length(missing) > 0L) {
    stop(
      object_name,
      " is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

check_allowed_values <- function(x, allowed, variable_name) {
  observed <- unique(
    stats::na.omit(
      trimws(as.character(x))
    )
  )

  unexpected <- setdiff(observed, allowed)

  if (length(unexpected) > 0L) {
    stop(
      variable_name,
      " contains unexpected value(s): ",
      paste(unexpected, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

load_private_config <- function() {
  config_path <- Sys.getenv(
    "NHANES_MAIN_CONFIG",
    unset = file.path("config", "config.R")
  )

  if (!file.exists(config_path)) {
    stop(
      "Private configuration file not found: ",
      config_path,
      "\nCopy config/config.example.R to config/config.R and edit the paths.",
      call. = FALSE
    )
  }

  env <- new.env(parent = baseenv())
  sys.source(config_path, envir = env)

  env
}

write_private_csv <- function(x, path) {
  dir.create(
    dirname(path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  utils::write.csv(
    x,
    path,
    row.names = FALSE,
    na = ""
  )

  invisible(path)
}

percent_difference <- function(beta) {
  100 * (exp(beta) - 1)
}

recode_race4 <- function(x) {
  x <- as.character(x)
  out <- rep(NA_character_, length(x))

  out[x == "Non-Hispanic White"] <- "Non-Hispanic White"
  out[x == "Non-Hispanic Black"] <- "Non-Hispanic Black"
  out[x %in% c("Mexican American", "Other Hispanic")] <- "Hispanic"
  out[x %in% c("Non-Hispanic Asian", "Other / Multi-Racial")] <- "Other"

  factor(
    out,
    levels = c(
      "Non-Hispanic White",
      "Non-Hispanic Black",
      "Hispanic",
      "Other"
    )
  )
}

reset_factor_levels <- function(data) {
  data$cycle <- factor(
    data$cycle,
    levels = c("2011-2012", "2013-2014")
  )

  data$sex_model <- factor(
    data$sex_model,
    levels = c("Male", "Female")
  )

  data$race4 <- factor(
    data$race4,
    levels = c(
      "Non-Hispanic White",
      "Non-Hispanic Black",
      "Hispanic",
      "Other"
    )
  )

  data$education_binary <- factor(
    data$education_binary,
    levels = c("Others", "Less than high school")
  )

  data$household_income_binary <- factor(
    data$household_income_binary,
    levels = c(">= $20k", "<$20k")
  )

  data$smoking_binary <- factor(
    data$smoking_binary,
    levels = c("No", "Yes")
  )

  data$alcohol_binary <- factor(
    data$alcohol_binary,
    levels = c("No", "Yes")
  )

  data
}

# Combine binary and continuous results while retaining their distinct effect scales.
combine_exposure_results <- function(results) {
  tables <- lapply(results, function(x) x$exposure)
  columns <- unique(unlist(lapply(tables, names), use.names = FALSE))
  tables <- lapply(tables, function(x) {
    for (column in setdiff(columns, names(x))) x[[column]] <- NA_real_
    x[, columns, drop = FALSE]
  })
  out <- do.call(rbind, tables)
  rownames(out) <- NULL
  out
}
