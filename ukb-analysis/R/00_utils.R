# ==============================================================================
# Shared utilities
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

parse_date_vector <- function(x) {
  x <- as.character(x)
  out <- rep(as.Date(NA), length(x))

  formats <- c(
    "%Y/%m/%d",
    "%Y-%m-%d",
    "%Y-%m-%dT%H:%M:%SZ"
  )

  for (fmt in formats) {
    unresolved <- is.na(out) & !is.na(x) & nzchar(x)

    if (!any(unresolved)) {
      break
    }

    parsed <- as.Date(
      x[unresolved],
      format = fmt
    )

    out[which(unresolved)[!is.na(parsed)]] <-
      parsed[!is.na(parsed)]
  }

  invalid <- !is.na(x) & nzchar(trimws(x)) & is.na(out)
  if (any(invalid)) stop("Unparseable non-missing date; use YYYY-MM-DD.", call. = FALSE)
  out
}

load_private_config <- function() {
  config_path <- Sys.getenv(
    "UKB_COX_CONFIG",
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

write_csv_private <- function(x, path) {
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
