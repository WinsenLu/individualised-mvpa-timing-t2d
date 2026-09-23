# Software environment

The manuscript reports R 4.3.1. Exposure processing requires GGIR 3.0.0 and checks this version before running. Exact study versions of other packages were not supplied; the validation versions below must not be treated as a recovered study lockfile.

Synthetic validation was performed with R 4.5.1 on Windows and these installed versions:

| Package | Validation version |
|---|---|
| GGIR | 3.0.0 |
| data.table | 1.18.4 |
| R.utils | 2.13.0 |
| future | 1.75.0 |
| future.apply | 1.20.2 |
| parallelly | 1.48.0 |

## Install

Install R and then run the following in R. Package installation requires network access and may require system build tools. Scripts never install dependencies automatically.

```r
install.packages(c("data.table", "R.utils", "future", "future.apply", "parallelly"), repos = "https://cloud.r-project.org")
install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_version("GGIR", version = "3.0.0", repos = "https://cloud.r-project.org", upgrade = "never")

```

For a reproducible validation environment, install the versions in the table with `remotes::install_version()` in a separate R library. The table records direct dependencies; it does not pin every transitive dependency. Save `sessionInfo()` and an environment lockfile within the authorised analysis environment when running on study data. Do not publish local library paths or participant-level objects.

## Validation limits

The tests use generated artificial data. They check configuration, syntax, formulas, input handling and the analysis steps they exercise. They do not reproduce cohort selection, raw multi-day device calibration, manuscript estimates, or results outside the README scope. Raw GGIR processing requires appropriate multi-day accelerometer input. Synthetic integration tests use fewer imputations and iterations to keep the test run short; production defaults remain those documented in the README.
