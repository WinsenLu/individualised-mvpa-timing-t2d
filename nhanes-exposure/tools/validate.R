# Run from the repository root. No participant data are required.
files <- list.files(".", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)
for (file in files) parse(file, encoding = "UTF-8")
source("R/00_utils.R")
config_variable <- "NHANES_MVPA_CONFIG"
do.call(Sys.setenv, setNames(list("config/config.example.R"), config_variable))
config <- load_config()
stopifnot(is.environment(config), length(ls(config)) > 0L)
source("tests/run_synthetic_tests.R")
if (file.exists("tests/run_integration_tests.R")) source("tests/run_integration_tests.R")
source("tools/check_public_repo.R")
cat("Validation passed.\n")
