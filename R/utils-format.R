#' @keywords internal
.powstat_to_df <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  
  if (is.data.frame(x)) {
    return(x)
  }
  
  # 如果是 list of rows: list(list(a=1,b=2), list(a=3,b=4))
  if (
    is.list(x) &&
    length(x) > 0 &&
    all(vapply(x, is.list, logical(1)))
  ) {
    all_names <- unique(unlist(lapply(x, names), use.names = FALSE))
    
    rows <- lapply(x, function(row) {
      out <- stats::setNames(vector("list", length(all_names)), all_names)
      
      for (nm in all_names) {
        val <- row[[nm]]
        if (is.null(val)) {
          out[[nm]] <- NA
        } else if (length(val) == 1) {
          out[[nm]] <- val
        } else {
          out[[nm]] <- paste(val, collapse = ", ")
        }
      }
      
      as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
    })
    
    return(do.call(rbind, rows))
  }
  
  as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
}



#' @keywords internal
.powstat_normalize_kv_wide <- function(df, key = "Metric", value = "Value") {
  if (is.null(df)) {
    return(NULL)
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  
  nms <- names(df)
  
  key_pattern <- paste0("^", key, "(\\.\\d+)?$")
  value_pattern <- paste0("^", value, "(\\.\\d+)?$")
  
  key_cols <- grep(key_pattern, nms, value = TRUE)
  value_cols <- grep(value_pattern, nms, value = TRUE)
  
  if (length(key_cols) <= 1 || length(value_cols) <= 1) {
    return(df)
  }
  
  get_suffix <- function(x, prefix) {
    sub(paste0("^", prefix), "", x)
  }
  
  key_suffix <- get_suffix(key_cols, key)
  value_suffix <- get_suffix(value_cols, value)
  
  suffixes <- intersect(key_suffix, value_suffix)
  
  out <- lapply(suffixes, function(suf) {
    kc <- paste0(key, suf)
    vc <- paste0(value, suf)
    
    data.frame(
      tmp_key = as.character(df[[kc]]),
      tmp_value = df[[vc]],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  
  out <- do.call(rbind, out)
  names(out) <- c(key, value)
  
  out <- out[
    !is.na(out[[key]]) &
      nzchar(as.character(out[[key]])),
    ,
    drop = FALSE
  ]
  
  row.names(out) <- NULL
  out
}



#' @keywords internal
.powstat_normalize_repeated_sets <- function(df, cols) {
  if (is.null(df)) {
    return(NULL)
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  
  nms <- names(df)
  
  # 找出所有后缀： "", ".1", ".2", ...
  suffixes <- unique(unlist(lapply(cols, function(col) {
    matched <- grep(paste0("^", col, "(\\.\\d+)?$"), nms, value = TRUE)
    sub(paste0("^", col), "", matched)
  })))
  
  if (length(suffixes) <= 1) {
    return(df)
  }
  
  out <- lapply(suffixes, function(suf) {
    row <- stats::setNames(vector("list", length(cols)), cols)
    
    for (col in cols) {
      candidate <- paste0(col, suf)
      
      if (candidate %in% nms) {
        row[[col]] <- df[[candidate]]
      } else {
        row[[col]] <- NA
      }
    }
    
    as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
  })
  
  out <- do.call(rbind, out)
  
  # 删除全空行
  keep <- apply(out, 1, function(z) {
    any(!is.na(z) & nzchar(as.character(z)))
  })
  
  out <- out[keep, , drop = FALSE]
  row.names(out) <- NULL
  
  out
}


#' @keywords internal
.powstat_line <- function(char = "-", width = 92) {
  cat(paste(rep(char, width), collapse = ""), "\n", sep = "")
}

#' @keywords internal
.powstat_section <- function(title, width = 92) {
  cat("\n")
  cat(title, "\n", sep = "")
  .powstat_line("-", width)
}


#' @keywords internal
.powstat_print_kv <- function(df, key_col = 1, value_col = 2, digits = 6, key_width = 42) {
  if (is.null(df) || nrow(df) == 0) {
    cat("No data available.\n")
    return(invisible(NULL))
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  
  key <- as.character(df[[key_col]])
  value <- df[[value_col]]
  
  if (is.numeric(value)) {
    value <- format(round(value, digits), nsmall = 0, trim = TRUE, scientific = FALSE)
  } else {
    value <- as.character(value)
  }
  
  cat(
    sprintf(
      paste0("  %-", key_width, "s %s\n"),
      names(df)[key_col],
      names(df)[value_col]
    )
  )
  
  for (i in seq_along(key)) {
    cat(
      sprintf(
        paste0("  %-", key_width, "s %s\n"),
        key[i],
        value[i]
      )
    )
  }
  
  invisible(NULL)
}



#' @keywords internal
.powstat_print_df <- function(df, digits = 6) {
  if (is.null(df) || nrow(df) == 0) {
    cat("No data available.\n")
    return(invisible(NULL))
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  
  numeric_cols <- vapply(df, is.numeric, logical(1))
  df[numeric_cols] <- lapply(df[numeric_cols], function(x) {
    round(x, digits)
  })
  
  print(df, row.names = FALSE, right = FALSE)
  
  invisible(NULL)
}


#' @keywords internal
#' @keywords internal
.powstat_print_wide_df <- function(df, digits = 6, cols_per_block = 6) {
  if (is.null(df) || nrow(df) == 0) {
    cat("No data available.\n")
    return(invisible(NULL))
  }
  
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  
  numeric_cols <- vapply(df, is.numeric, logical(1))
  df[numeric_cols] <- lapply(df[numeric_cols], function(x) {
    round(x, digits)
  })
  
  n <- ncol(df)
  
  if (is.null(cols_per_block) || is.infinite(cols_per_block) || cols_per_block >= n) {
    print(df, row.names = FALSE, right = FALSE)
    return(invisible(NULL))
  }
  
  blocks <- split(seq_len(n), ceiling(seq_len(n) / cols_per_block))
  
  for (i in seq_along(blocks)) {
    if (i > 1) {
      cat("\n")
    }
    
    print(
      df[, blocks[[i]], drop = FALSE],
      row.names = FALSE,
      right = FALSE
    )
  }
  
  invisible(NULL)
}


