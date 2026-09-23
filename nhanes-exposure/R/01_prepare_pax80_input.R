# ==============================================================================
# Prepare one participant's NHANES PAX80 raw input for GGIR
# ==============================================================================

source(file.path("R", "00_utils.R"))

detect_archive_compression <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)

  magic <- as.integer(readBin(con, what = "raw", n = 6L))

  if (length(magic) >= 3L && identical(magic[1:3], c(66L, 90L, 104L))) {
    return("bzip2")
  }
  if (length(magic) >= 2L && identical(magic[1:2], c(31L, 139L))) {
    return("gzip")
  }
  if (
    length(magic) >= 6L &&
      identical(magic[1:6], c(253L, 55L, 122L, 88L, 90L, 0L))
  ) {
    return("xz")
  }

  NA_character_
}

extract_archive_safely <- function(archive, extract_dir) {
  if (!file.exists(archive)) {
    stop("Archive not found: ", archive, call. = FALSE)
  }

  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)

  status <- utils::untar(
    tarfile = archive,
    exdir = extract_dir,
    restore_times = TRUE
  )

  if (
    is.numeric(status) &&
      length(status) == 1L &&
      is.finite(status) &&
      status != 0
  ) {
    stop(
      "untar returned non-zero status ", status, " for: ", archive,
      call. = FALSE
    )
  }

  invisible(extract_dir)
}

open_binary_input <- function(path) {
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    gzfile(path, open = "rb")
  } else if (grepl("\\.bz2$", path, ignore.case = TRUE)) {
    bzfile(path, open = "rb")
  } else if (grepl("\\.xz$", path, ignore.case = TRUE)) {
    xzfile(path, open = "rb")
  } else {
    file(path, open = "rb")
  }
}

open_text_input <- function(path) {
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    gzfile(path, open = "rt")
  } else if (grepl("\\.bz2$", path, ignore.case = TRUE)) {
    bzfile(path, open = "rt")
  } else if (grepl("\\.xz$", path, ignore.case = TRUE)) {
    xzfile(path, open = "rt")
  } else {
    file(path, open = "rt")
  }
}

read_first_two_lines <- function(path) {
  con <- open_text_input(path)
  on.exit(close(con), add = TRUE)
  readLines(con, n = 2L, warn = FALSE)
}

normalise_header <- function(x) {
  x <- sub("^\ufeff", "", x)
  x <- gsub('"', "", x, fixed = TRUE)
  toupper(gsub("[[:space:]]+", "", x))
}

parse_nhanes_timestamp <- function(x) {
  x <- trimws(gsub('"', "", x, fixed = TRUE))
  as.POSIXct(x, format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")
}

identify_hourly_sensor_files <- function(extract_dir) {
  candidates <- list.files(
    extract_dir,
    pattern = "\\.csv(\\.(gz|bz2|xz))?$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(candidates) == 0L) {
    stop(
      "No hourly raw sensor CSV files were found after extraction.",
      call. = FALSE
    )
  }

  probes <- lapply(candidates, function(f) {
    z <- tryCatch(
      read_first_two_lines(f),
      error = function(e) character()
    )

    if (length(z) < 2L) {
      return(NULL)
    }

    if (!identical(normalise_header(z[1]), "HEADER_TIMESTAMP,X,Y,Z")) {
      return(NULL)
    }

    fields <- strsplit(z[2], ",", fixed = TRUE)[[1]]

    if (length(fields) != 4L) {
      return(NULL)
    }

    first_time <- parse_nhanes_timestamp(fields[1])
    first_acc <- suppressWarnings(
      as.numeric(gsub('"', "", fields[2:4], fixed = TRUE))
    )

    if (is.na(first_time) || any(!is.finite(first_acc))) {
      return(NULL)
    }

    data.frame(
      file = normalise_path_soft(f),
      source_basename = basename(f),
      first_time = first_time,
      stringsAsFactors = FALSE
    )
  })

  probes <- probes[!vapply(probes, is.null, logical(1))]

  if (length(probes) == 0L) {
    stop(
      "No raw sensor files with header HEADER_TIMESTAMP,X,Y,Z were found.",
      call. = FALSE
    )
  }

  ans <- data.table::rbindlist(probes)
  data.table::setorder(ans, first_time)

  if (anyDuplicated(ans$first_time)) {
    stop(
      "Duplicate first timestamps detected among hourly raw files.",
      call. = FALSE
    )
  }

  ans[]
}

copy_body_without_header <- function(
  input_path,
  output_connection,
  buffer_size = 8L * 1024L * 1024L
) {
  input_connection <- open_binary_input(input_path)
  on.exit(close(input_connection), add = TRUE)

  header_skipped <- FALSE
  pending <- raw(0)
  last_written_byte <- raw(0)
  newline_byte <- as.raw(0x0A)

  repeat {
    buf <- readBin(input_connection, what = "raw", n = buffer_size)

    if (length(buf) == 0L) {
      break
    }

    if (!header_skipped) {
      pending <- c(pending, buf)
      newline_position <- which(pending == newline_byte)[1]

      if (is.na(newline_position)) {
        if (length(pending) > 1024L * 1024L) {
          stop(
            "No header newline found within the first 1 MB of: ",
            input_path,
            call. = FALSE
          )
        }
        next
      }

      header_skipped <- TRUE

      if (newline_position < length(pending)) {
        body <- pending[(newline_position + 1L):length(pending)]
        writeBin(body, output_connection)
        last_written_byte <- tail(body, 1L)
      }

      pending <- raw(0)
    } else {
      writeBin(buf, output_connection)
      last_written_byte <- tail(buf, 1L)
    }
  }

  if (!header_skipped) {
    stop("No header newline found in: ", input_path, call. = FALSE)
  }

  if (
    length(last_written_byte) == 1L &&
      last_written_byte != newline_byte
  ) {
    writeBin(newline_byte, output_connection)
  }

  invisible(TRUE)
}

combine_hourly_sensor_files <- function(
  hourly_table,
  output_file,
  compression = "none"
) {
  if (nrow(hourly_table) < 1L) {
    stop("No hourly files supplied.", call. = FALSE)
  }

  if (!compression %in% c("none", "gzip")) {
    stop("compression must be 'none' or 'gzip'.", call. = FALSE)
  }

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

  if (file.exists(output_file)) {
    unlink(output_file, force = TRUE)
  }

  out <- if (identical(compression, "gzip")) {
    gzfile(output_file, open = "wb", compression = 1)
  } else {
    file(output_file, open = "wb")
  }

  on.exit(close(out), add = TRUE)

  writeBin(charToRaw("HEADER_TIMESTAMP,X,Y,Z\n"), out)

  for (i in seq_len(nrow(hourly_table))) {
    copy_body_without_header(hourly_table$file[i], out)
  }

  invisible(output_file)
}
