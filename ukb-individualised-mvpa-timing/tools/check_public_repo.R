# Check the current source tree; Git history is not inspected.
files <- list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE)
files <- files[!grepl("(^|/)\\.git(/|$)", files)]
forbidden <- grepl("\\.(csv|tsv|rds|rda|rdata|parquet|feather|sav|dta|xlsx|cwa|zip|gz|bz2|xz|tar|log|png|pdf|docx)$", files, ignore.case = TRUE) |
  basename(files) %in% c(".Rhistory", ".Renviron", ".env", "config.R")
if (any(forbidden)) stop("Unexpected data, session or output files: ", paste(files[forbidden], collapse = ", "), call. = FALSE)
patterns <- c("[A-Za-z]:[/\\\\]Users[/\\\\][^/\\\\]+", "/home/[[:alnum:]_.-]+/", "gh[pousr]_[A-Za-z0-9]{20,}")
for (file in files) {
  if (file.info(file)$isdir) next
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  for (pattern in patterns) {
    if (any(grepl(pattern, lines, perl = TRUE))) stop("Potential path or credential in ", file, call. = FALSE)
  }
}
cat("Current-tree source checks passed; this is not a full-history or official data audit.\n")
