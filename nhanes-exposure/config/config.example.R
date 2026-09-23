# ==============================================================================
# NHANES exposure-derivation configuration
#
# Copy to:
#   config/config.R
#
# Edit config/config.R only. It is ignored by Git.
# ==============================================================================

# Directory containing participant-specific PAX80 raw archives.
INPUT_DIR <- "/path/to/NHANES/PAX80_archives"

# Processing/output directory. Keep this outside the public repository.
BATCH_ROOT <- "/path/to/private/NHANES_GGIR_results"

# Number of independent participant workers.
MAX_OUTER_WORKERS <- 8L

# Temporary combined input:
#   "none" = uncompressed CSV
#   "gzip" = gzip-compressed CSV
COMBINED_INPUT_COMPRESSION <- "none"

# Reprocessing controls.
FORCE_REPROCESS <- FALSE

# Optional comma-separated sequence identifiers to process.
# Leave empty to process all discovered archives.
REQUESTED_SEQNS <- character(0)
