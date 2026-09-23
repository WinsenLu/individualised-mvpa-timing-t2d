# ==============================================================================
# Batch driver for NHANES exposure derivation
#
# Run from repository root:
#   Rscript R/07_batch_process.R
# ==============================================================================

options(stringsAsFactors = FALSE)

Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  VECLIB_MAXIMUM_THREADS = "1",
  NUMEXPR_NUM_THREADS = "1"
)

required_packages <- c(
  "GGIR",
  "data.table",
  "R.utils",
  "future",
  "future.apply",
  "parallelly"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing R package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

data.table::setDTthreads(1L)

source(file.path("R", "00_utils.R"))
source(file.path("R", "06_process_participant.R"))

cfg <- load_config()

required_cfg <- c(
  "INPUT_DIR",
  "BATCH_ROOT",
  "MAX_OUTER_WORKERS",
  "COMBINED_INPUT_COMPRESSION",
  "FORCE_REPROCESS",
  "REQUESTED_SEQNS"
)

missing_cfg <- required_cfg[
  !vapply(
    required_cfg,
    exists,
    logical(1),
    envir = cfg,
    inherits = FALSE
  )
]

if (length(missing_cfg) > 0L) {
  stop(
    "Missing configuration value(s): ",
    paste(missing_cfg, collapse = ", "),
    call. = FALSE
  )
}

if (!dir.exists(cfg$INPUT_DIR)) {
  stop(
    "INPUT_DIR does not exist: ",
    cfg$INPUT_DIR,
    call. = FALSE
  )
}

dir.create(
  cfg$BATCH_ROOT,
  recursive = TRUE,
  showWarnings = FALSE
)

archive_pattern <- paste0(
  "^[0-9]+(",
  "\\.tar$|\\.tar\\.(bz2|gz|xz)$|\\.(tbz2|tgz|txz)$",
  ")"
)

archive_files <- list.files(
  cfg$INPUT_DIR,
  full.names = TRUE,
  recursive = FALSE
)

archive_files <- archive_files[
  grepl(
    archive_pattern,
    basename(archive_files),
    ignore.case = TRUE
  )
]

if (length(archive_files) == 0L) {
  stop(
    "No participant archives were found in INPUT_DIR.",
    call. = FALSE
  )
}

extract_seqn <- function(path) {
  b <- basename(path)

  if (!grepl("^[0-9]+", b)) {
    return(NA_character_)
  }

  sub(
    "^([0-9]+).*",
    "\\1",
    b
  )
}

manifest <- data.table::data.table(
  SEQN = vapply(
    archive_files,
    extract_seqn,
    character(1)
  ),
  archive = normalise_path_soft(
    archive_files
  )
)

manifest <- manifest[
  !is.na(SEQN) &
    nzchar(SEQN)
]

if (anyDuplicated(manifest$SEQN)) {
  stop(
    "Duplicate participant archives detected.",
    call. = FALSE
  )
}

requested <- as.character(
  cfg$REQUESTED_SEQNS
)

requested <- requested[
  nzchar(requested)
]

if (length(requested) > 0L) {
  missing_requested <- setdiff(
    requested,
    manifest$SEQN
  )

  if (length(missing_requested) > 0L) {
    stop(
      "Requested SEQN not found in archive directory: ",
      paste(missing_requested, collapse = ", "),
      call. = FALSE
    )
  }

  manifest <- manifest[
    SEQN %in% requested
  ]
}

result_path <- function(seqn) {
  file.path(
    cfg$BATCH_ROOT,
    paste0("GGIR_", seqn),
    "04_derived",
    "sleep_anchored_mvpa_phase_angle.csv"
  )
}

run_one <- function(i) {
  seqn <- as.character(
    manifest$SEQN[i]
  )

  archive <- as.character(
    manifest$archive[i]
  )

  existing <- result_path(
    seqn
  )

  if (
    !isTRUE(cfg$FORCE_REPROCESS) &&
      file.exists(existing)
  ) {
    return(
      data.table::fread(
        existing,
        showProgress = FALSE
      )
    )
  }

  process_one_participant(
    seqn = seqn,
    archive = archive,
    batch_root = cfg$BATCH_ROOT,
    combined_input_compression =
      cfg$COMBINED_INPUT_COMPRESSION,
    delete_large_intermediates = TRUE
  )
}

available <- parallelly::availableCores(
  omit = 2L
)

n_workers <- max(
  1L,
  min(
    as.integer(cfg$MAX_OUTER_WORKERS),
    as.integer(available),
    nrow(manifest)
  )
)

if (n_workers == 1L) {
  result_list <- lapply(
    seq_len(nrow(manifest)),
    run_one
  )
} else {
  future::plan(
    future::multisession,
    workers = n_workers
  )

  result_list <- tryCatch(
    future.apply::future_lapply(
      X = seq_len(nrow(manifest)), FUN = run_one,
      future.seed = FALSE, future.chunk.size = 1L
    ),
    finally = future::plan(future::sequential)
  )
}

master <- data.table::rbindlist(
  result_list,
  fill = TRUE,
  use.names = TRUE
)

data.table::setorder(
  master,
  SEQN
)

master_file <- file.path(
  cfg$BATCH_ROOT,
  "NHANES_PAX80_sleep_anchored_MVPA_phase_angle_summary.csv"
)

atomic_fwrite(
  master,
  master_file
)

message(
  "Exposure derivation complete. Master output: ",
  master_file
)
