# ==============================================================================
# 01_run_GGIR_HDCZA.R
#
# Run GGIR 3.0.0 / HDCZA on authorised UK Biobank raw accelerometry.
#
# Public repository rule:
#   No .cwa files, participant identifiers, GGIR outputs, or logs generated from
#   UK Biobank data should be committed to Git.
#
# Run from repository root:
#   Rscript R/01_run_GGIR_HDCZA.R
# ==============================================================================

source(file.path("R", "00_utils.R"))

run_ggir_hdczA <- function(cwa_dir, output_dir) {
  if (!requireNamespace("GGIR", quietly = TRUE)) {
    stop(
      "Package 'GGIR' is required. The study used GGIR version 3.0.0.",
      call. = FALSE
    )
  }

  installed_version <- as.character(utils::packageVersion("GGIR"))

  if (!identical(installed_version, "3.0.0")) {
    stop(
      "GGIR version mismatch. Study exposure processing used GGIR 3.0.0; ",
      "installed version is ",
      installed_version,
      ".",
      call. = FALSE
    )
  }

  if (!dir.exists(cwa_dir)) {
    stop("CWA_DIR does not exist: ", cwa_dir, call. = FALSE)
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  cwa_files <- list.files(
    path = cwa_dir,
    pattern = "\\.cwa$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(cwa_files) == 0L) {
    stop("No .cwa files were found in CWA_DIR.", call. = FALSE)
  }

  # Do not print participant-specific filenames.
  message("Number of authorised CWA files detected: ", length(cwa_files))

  GGIR::GGIR(
    mode = c(1, 2, 3, 4, 5),
    datadir = cwa_dir,
    outputdir = output_dir,
    overwrite = FALSE,
    do.report = c(2, 4, 5),

    # HDCZA sleep algorithm used in the study.
    def.noc.sleep = 1,

    # Settings retained from the study processing script.
    idloc = 1,
    do.cal = TRUE,
    storefolderstructure = FALSE,
    visualreport = FALSE,
    do.parallel = TRUE
  )

  invisible(TRUE)
}

main <- function() {
  cfg <- load_private_config()

  required_cfg <- c("CWA_DIR", "GGIR_OUTPUT_DIR")
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

  run_ggir_hdczA(
    cwa_dir = cfg$CWA_DIR,
    output_dir = cfg$GGIR_OUTPUT_DIR
  )
}

if (sys.nframe() == 0L) {
  main()
}
