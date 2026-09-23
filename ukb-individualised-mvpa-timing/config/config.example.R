# ==============================================================================
# Private configuration template
#
# Copy this file to:
#   config/config.R
#
# Then edit config/config.R only.
# config/config.R is ignored by Git.
#
# IMPORTANT:
# Do not place UK Biobank participant-level data inside the repository.
# ==============================================================================

# Secure directory containing only the authorised .cwa files to be processed.
CWA_DIR <- "/secure/authorised/path/to/cwa"

# Secure GGIR output directory.
GGIR_OUTPUT_DIR <- "/secure/authorised/path/to/ggir_output"

# Actual study GGIR 3.0.0 night-summary file.
NIGHT_SUMMARY_CSV <- "/secure/authorised/path/to/part4_nightsummary_sleep_cleaned.csv"

# Private standardised UKB hourly MVPA input:
# participant_id, mvpa_hourly_profile, wear_h00, ..., wear_h23
MVPA_INPUT_CSV <- "/secure/authorised/path/to/ukb_hourly_mvpa_input.csv"

# Private baseline-diabetes eligibility input:
# participant_id, baseline_diabetes
ELIGIBILITY_CSV <- "/secure/authorised/path/to/baseline_diabetes_eligibility.csv"

# Private participant-level output directory.
PRIVATE_OUTPUT_DIR <- "/secure/authorised/path/to/derived_exposure_output"
