# ==============================================================================
# Run GGIR 3.0.0 for one combined NHANES PAX80 participant file
# ==============================================================================

source(file.path("R", "00_utils.R"))

run_ggir_nhanes <- function(
  combined_file,
  ggir_input_dir,
  ggir_output_dir,
  seqn
) {
  if (!requireNamespace("GGIR", quietly = TRUE)) {
    stop("Package GGIR is required.", call. = FALSE)
  }

  installed_ggir <- as.character(utils::packageVersion("GGIR"))

  if (!identical(installed_ggir, "3.0.0")) {
    stop(
      "GGIR version mismatch. Study processing used GGIR 3.0.0; found ",
      installed_ggir, ".",
      call. = FALSE
    )
  }

  probe <- GGIR::read.myacc.csv(
    rmc.file = combined_file,
    rmc.nrow = 8000,
    rmc.firstrow.acc = 2,
    rmc.col.time = 1,
    rmc.col.acc = 2:4,
    rmc.unit.acc = "g",
    rmc.unit.time = "POSIX",
    rmc.format.time = "%Y-%m-%d %H:%M:%OS",
    rmc.sf = 80,
    desiredtz = "UTC"
  )

  if (
    !is.list(probe) ||
      is.null(probe$data) ||
      nrow(probe$data) < 100L
  ) {
    stop(
      "GGIR import probe did not return a valid accelerometer object.",
      call. = FALSE
    )
  }

  rm(probe)
  invisible(gc())

  study_name <- paste0("NHANES_", seqn)

  GGIR::GGIR(
    mode = 1:5,
    datadir = ggir_input_dir,
    outputdir = ggir_output_dir,
    studyname = study_name,
    f0 = 1,
    f1 = 1,
    overwrite = TRUE,
    do.parallel = FALSE,
    maxNcores = 1,
    chunksize = 1,
    idloc = 2,
    windowsizes = c(5, 900, 3600),
    desiredtz = "UTC",
    sensor.location = "wrist",

    rmc.firstrow.acc = 2,
    rmc.col.time = 1,
    rmc.col.acc = 2:4,
    rmc.unit.acc = "g",
    rmc.unit.time = "POSIX",
    rmc.format.time = "%Y-%m-%d %H:%M:%OS",
    rmc.sf = 80,

    do.cal = TRUE,
    do.enmo = TRUE,
    do.anglez = TRUE,
    acc.metric = "ENMO",
    HASPT.algo = "HDCZA",
    ignorenonwear = TRUE,

    includedaycrit = 16,
    includenightcrit = 16,
    excludefirstlast = FALSE,

    mvpathreshold = 100,
    threshold.lig = 40,
    threshold.mod = 100,
    threshold.vig = 400,

    part5_agg2_60seconds = TRUE,
    timewindow = "MM",
    save_ms5rawlevels = TRUE,
    save_ms5raw_format = "csv",
    save_ms5raw_without_invalid = FALSE,

    do.report = 4,
    do.visual = FALSE
  )

  invisible(study_name)
}

find_ggir_output_root <- function(output_dir, study_name) {
  candidates <- unique(
    c(output_dir, list.dirs(output_dir, recursive = TRUE))
  )

  candidates <- candidates[
    dir.exists(file.path(candidates, "meta")) &
      dir.exists(file.path(candidates, "results"))
  ]

  if (length(candidates) == 0L) {
    stop(
      "Could not locate a GGIR output root containing meta/ and results/.",
      call. = FALSE
    )
  }

  preferred <- candidates[
    grepl(study_name, candidates, fixed = TRUE)
  ]

  if (length(preferred) == 1L) {
    return(preferred)
  }

  if (length(candidates) == 1L) {
    return(candidates)
  }

  stop(
    "More than one possible GGIR output root was found.",
    call. = FALSE
  )
}

find_minute_file <- function(ggir_root, seqn) {
  files <- list.files(
    ggir_root,
    pattern = "\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )

  normal_paths <- gsub("\\\\", "/", files)

  files <- files[
    grepl("meta/ms5\\.outraw", normal_paths, ignore.case = TRUE)
  ]

  good <- vapply(
    files,
    function(f) {
      hdr <- tryCatch(
        names(data.table::fread(
          f,
          nrows = 0L,
          showProgress = FALSE
        )),
        error = function(e) character()
      )

      all(
        c("timenum", "acc", "invalidepoch") %in% tolower(hdr)
      )
    },
    logical(1)
  )

  files <- files[good]

  preferred <- files[
    grepl(as.character(seqn), basename(files), fixed = TRUE)
  ]

  if (length(preferred) == 1L) {
    return(preferred)
  }

  if (length(files) == 1L) {
    return(files)
  }

  stop(
    "Could not uniquely identify the 60-s GGIR Part 5 time-series file.",
    call. = FALSE
  )
}

find_sleep_file <- function(ggir_root) {
  files <- list.files(
    ggir_root,
    pattern = "^part4_nightsummary_sleep_cleaned\\.csv$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) != 1L) {
    stop(
      "Expected exactly one part4_nightsummary_sleep_cleaned.csv.",
      call. = FALSE
    )
  }

  files[1L]
}
