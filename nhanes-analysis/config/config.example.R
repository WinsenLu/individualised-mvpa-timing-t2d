# ==============================================================================
# NHANES main-analysis private configuration
#
# Copy to:
#   config/config.R
#
# Edit config/config.R only. It is ignored by Git.
# ==============================================================================

# Outcome-specific analysis-ready participant-level files.
# Public example filenames are semantic placeholders only.
PREVALENT_DIABETES_CSV <- "/private/path/to/nhanes_prevalent_diabetes_analysis.csv"
HBA1C_CSV <- "/private/path/to/nhanes_hba1c_analysis.csv"
FASTING_GLUCOSE_CSV <- "/private/path/to/nhanes_fasting_glucose_analysis.csv"
FASTING_INSULIN_CSV <- "/private/path/to/nhanes_fasting_insulin_analysis.csv"
OGTT_CSV <- "/private/path/to/nhanes_ogtt_analysis.csv"

# Local/private output directory.
OUTPUT_DIR <- "/private/path/to/nhanes_main_analysis_output"

# Study imputation settings.
N_IMPUTATIONS <- 20L
N_ITERATIONS <- 20L

# Save participant-level MICE objects only when explicitly required.
# If TRUE, these files remain private and must not be committed.
SAVE_MICE_OBJECTS <- FALSE
