# Check dependencies without installing packages or accessing study data.
required_packages <- c("GGIR")
cat(R.version.string, "\n")
missing <- character()
for (package in required_packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    missing <- c(missing, package)
  } else {
    cat(package, as.character(utils::packageVersion(package)), "\n")
  }
}
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)
if (utils::packageVersion("GGIR") != "3.0.0") stop("Exposure processing requires GGIR 3.0.0.", call. = FALSE)
