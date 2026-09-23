# ==============================================================================
# Private configuration template
#
# Copy to:
#   config/config.R
#
# Edit config/config.R only. It is ignored by Git.
# ==============================================================================

# Private participant-level analysis file.
INPUT_CSV <- "/secure/authorised/path/to/ukb_primary_analysis_input.csv"

# Private output directory for pooled aggregate model summaries.
OUTPUT_DIR <- "/secure/authorised/path/to/ukb_primary_cox_output"

# Multiple-imputation settings retained from the analysis script.
MICE_M <- 20L
MICE_MAXIT <- 5L
MICE_SEED <- 123L
