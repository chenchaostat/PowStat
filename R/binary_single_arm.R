# PowStat/R/binary_single_arm.R
# Client-side function for binary endpoint, single-arm exact binomial

#' Binary Endpoint Single-Arm Exact Binomial Design
#'
#' Calculate sample size, critical value, and power for a single-arm
#' exact binomial test design.
#'
#' @param p0 Numeric. Null hypothesis response rate (0, 1).
#' @param p1 Numeric. Alternative hypothesis response rate (0, 1).
#' @param alpha Numeric. Significance level. Default 0.025.
#' @param power_target Numeric. Target power. Default 0.90.
#' @param n_min Integer. Minimum sample size to search. Default 1.
#' @param n_max Integer. Maximum sample size to search. Default 200.
#' @param alternative Character. "greater" or "less". Default "greater".
#' @param n_fixed Integer or NULL. Fixed sample size to evaluate. Default NULL.
#' @param power_curve Logical. Compute power curve? Default TRUE.
#' @param p_seq Numeric vector. Sequence of true rates for power curve.
#' @param plot Logical. Generate power curve plot? Default TRUE.
#' @param digits Integer. Decimal places. Default 4.
#' @param ci_level Numeric. Confidence interval level. Default 0.95.
#'
#' @return An object of class \code{PowStatBinarySingleArm} containing:
#' \describe{
#'   \item{input}{Data frame of input parameters}
#'   \item{design_summary}{Summary of optimal and fixed designs}
#'   \item{optimal_design}{Smallest sample size meeting target power}
#'   \item{fixed_design}{Design for fixed sample size if specified}
#'   \item{valid_designs}{All designs meeting target power}
#'   \item{power_curve}{Power curve data if requested}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' res <- ps_binary_single_arm(
#'   p0 = 0.1,
#'   p1 = 0.3,
#'   alpha = 0.025,
#'   power_target = 0.90,
#'   n_fixed = 41
#' )
#' print(res)
#' }
ps_binary_single_arm <- function(
    p0,
    p1,
    alpha = 0.025,
    power_target = 0.90,
    n_min = 1,
    n_max = 200,
    alternative = "greater",
    n_fixed = NULL,
    power_curve = TRUE,
    p_seq = seq(0.01, 0.99, by = 0.01),
    plot = TRUE,
    digits = 4,
    ci_level = 0.95
) {
  # Client-side validation
  if (p0 <= 0 || p0 >= 1) stop("p0 must be between 0 and 1.")
  if (p1 <= 0 || p1 >= 1) stop("p1 must be between 0 and 1.")
  if (alpha <= 0 || alpha >= 1) stop("alpha must be between 0 and 1.")
  if (power_target <= 0 || power_target >= 1) stop("power_target must be between 0 and 1.")
  if (!alternative %in% c("greater", "less")) stop("alternative must be 'greater' or 'less'.")
  
  params <- list(
    p0 = p0,
    p1 = p1,
    alpha = alpha,
    power_target = power_target,
    n_min = n_min,
    n_max = n_max,
    alternative = alternative,
    n_fixed = n_fixed,
    power_curve = power_curve,
    p_seq = p_seq,
    plot = FALSE, # Server does not generate plots; client handles plotting
    digits = digits,
    ci_level = ci_level
  )
  
  # result <- powstat_api_call("binary/single_arm", params)
  result <- powstat_api_call("binary_single_arm", params)
  
  
  # Convert JSON results back to data frames
  if (!is.null(result$input)) {
    result$input <- as.data.frame(result$input, stringsAsFactors = FALSE)
  }
  if (!is.null(result$design_summary)) {
    result$design_summary <- as.data.frame(result$design_summary, stringsAsFactors = FALSE)
  }
  if (!is.null(result$optimal_design)) {
    result$optimal_design <- as.data.frame(result$optimal_design, stringsAsFactors = FALSE)
  }
  if (!is.null(result$fixed_design)) {
    result$fixed_design <- as.data.frame(result$fixed_design, stringsAsFactors = FALSE)
  }
  if (!is.null(result$valid_designs)) {
    result$valid_designs <- as.data.frame(result$valid_designs, stringsAsFactors = FALSE)
  }
  if (!is.null(result$power_curve)) {
    result$power_curve <- as.data.frame(result$power_curve, stringsAsFactors = FALSE)
  }
  
  result$input_raw <- params
  
  # Generate client-side plot if requested
  if (plot && power_curve && !is.null(result$power_curve)) {
    result$plot <- .build_power_curve_plot(result, params)
  }
  
  class(result) <- "PowStatBinarySingleArm"
  
  result
}

#' @importFrom rlang .data
NULL


#' @keywords internal
#' @keywords internal
.build_power_curve_plot <- function(result, params) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return(NULL)
  }
  
  df <- result$power_curve
  
  if (is.null(df) || nrow(df) == 0) {
    return(NULL)
  }
  
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$p, y = .data$power)) +
    ggplot2::geom_line(color = "#1F77B4", linewidth = 1.1) +
    ggplot2::geom_hline(
      yintercept = params$power_target,
      linetype = "dashed",
      color = "#D62728",
      linewidth = 0.8
    ) +
    ggplot2::geom_vline(
      xintercept = params$p0,
      linetype = "dotted",
      color = "grey40",
      linewidth = 0.8
    ) +
    ggplot2::geom_vline(
      xintercept = params$p1,
      linetype = "dashed",
      color = "#2CA02C",
      linewidth = 0.8
    ) +
    ggplot2::labs(
      title = "Power Curve: Single-Arm Exact Binomial Test",
      x = "True Response Rate",
      y = "Power"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, 0.1)
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  p
}


#' @export
print.PowStatBinarySingleArm <- function(x, digits = 4, show_valid = FALSE, ...) {
  cat("\n")
  cat("====================================================================\n")
  cat(" Binary Endpoint | Single-Arm Exact Binomial Test Design\n")
  cat(" Sample Size, Critical Point and Power Summary\n")
  cat("====================================================================\n\n")
  
  cat("Study Parameters\n")
  cat("--------------------------------------------------------------------\n")
  if (!is.null(x$input)) {
    print(x$input, row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Primary Design Summary\n")
  cat("--------------------------------------------------------------------\n")
  
  if (!is.null(x$design_summary) && nrow(x$design_summary) > 0) {
    summary_print <- x$design_summary
    numeric_cols <- sapply(summary_print, is.numeric)
    summary_print[numeric_cols] <- lapply(
      summary_print[numeric_cols], function(v) round(v, digits)
    )
    print(summary_print, row.names = FALSE, right = FALSE)
  } else {
    cat("No design satisfying the target power was found within the search range.\n")
  }
  
  if (show_valid && !is.null(x$valid_designs) && nrow(x$valid_designs) > 0) {
    cat("\n")
    cat("All Valid Designs Satisfying Target Power\n")
    cat("--------------------------------------------------------------------\n")
    valid_print <- x$valid_designs
    numeric_cols <- sapply(valid_print, is.numeric)
    valid_print[numeric_cols] <- lapply(
      valid_print[numeric_cols], function(v) round(v, digits)
    )
    print(valid_print, row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Notes\n")
  cat("--------------------------------------------------------------------\n")
  
  alt <- x$input_raw$alternative %||% "greater"
  
  if (alt == "greater") {
    cat("1. Rejection region is X >= critical point.\n")
    cat("2. Type I error is P(X >= r | p = p0).\n")
    cat("3. Power is P(X >= r | p = p1).\n")
  } else {
    cat("1. Rejection region is X <= critical point.\n")
    cat("2. Type I error is P(X <= r | p = p0).\n")
    cat("3. Power is P(X <= r | p = p1).\n")
  }
  
  cat("4. Confidence interval is Clopper-Pearson exact CI at the critical point.\n")
  cat("\n")
  
  invisible(x)
}
