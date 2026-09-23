# ==============================================================================
# Fit and pool the eight primary Cox models
# ==============================================================================

fit_one_pooled_cox <- function(
  imp,
  formula,
  model_name,
  exposure_type
) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop(
      "Package 'survival' is required.",
      call. = FALSE
    )
  }

  if (!requireNamespace("mice", quietly = TRUE)) {
    stop(
      "Package 'mice' is required.",
      call. = FALSE
    )
  }

  fits <- lapply(
    seq_len(imp$m),
    function(i) {
      completed <- mice::complete(
        imp,
        action = i
      )

      survival::coxph(
        formula = formula,
        data = completed
      )
    }
  )

  pooled <- mice::pool(
    mice::as.mira(fits)
  )

  out <- summary(
    pooled,
    conf.int = TRUE,
    exponentiate = TRUE
  )

  out$model <- model_name
  out$exposure_type <- exposure_type

  # Standardise names used in the output across mice versions.
  names(out)[names(out) == "estimate"] <- "HR"
  names(out)[names(out) %in% c("2.5 %", "conf.low")] <- "conf_low"
  names(out)[names(out) %in% c("97.5 %", "conf.high")] <- "conf_high"

  required_output <- c(
    "term",
    "HR",
    "conf_low",
    "conf_high",
    "p.value"
  )

  missing_output <- setdiff(
    required_output,
    names(out)
  )

  if (length(missing_output) > 0L) {
    stop(
      "Unexpected pooled-summary structure; missing column(s): ",
      paste(missing_output, collapse = ", "),
      call. = FALSE
    )
  }

  out
}

fit_all_primary_models <- function(
  imp,
  model_formulas
) {
  result_list <- list()

  for (nm in names(model_formulas)) {
    exposure_type <- if (
      grepl("_quintile$", nm)
    ) {
      "quintile"
    } else {
      "continuous"
    }

    model_name <- sub(
      "_(quintile|continuous)$",
      "",
      nm
    )

    result_list[[nm]] <- fit_one_pooled_cox(
      imp = imp,
      formula = model_formulas[[nm]],
      model_name = model_name,
      exposure_type = exposure_type
    )
  }

  all_terms <- do.call(
    rbind,
    result_list
  )

  rownames(all_terms) <- NULL

  exposure_terms <- all_terms[
    (
      all_terms$exposure_type == "quintile" &
        grepl("^Exposure", all_terms$term)
    ) |
      (
        all_terms$exposure_type == "continuous" &
          all_terms$term == "Phase_angle_hour"
      ),
    ,
    drop = FALSE
  ]

  list(
    all_terms = all_terms,
    exposure_terms = exposure_terms
  )
}
