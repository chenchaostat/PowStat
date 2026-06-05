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
    plot = FALSE,
    digits = digits,
    ci_level = ci_level
  )
  
  result <- powstat_api_call("binary_single_arm", params)
  
  df_fields <- c(
    "input",
    "design_summary",
    "optimal_design",
    "fixed_design",
    "valid_designs",
    "power_curve"
  )
  
  for (field in df_fields) {
    if (!is.null(result[[field]])) {
      result[[field]] <- .powstat_to_df(result[[field]])
    }
  }
  
  if (!is.null(result$input)) {
    result$input <- .powstat_normalize_kv_wide(
      result$input,
      key = "Parameter",
      value = "Value"
    )
  }
  
  result$input_raw <- params
  result$digits <- digits
  
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
print.PowStatBinarySingleArm <- function(
    x,
    digits = x$digits %||% 4,
    show_valid = FALSE,
    ...
) {
  old_width <- getOption("width")
  on.exit(options(width = old_width), add = TRUE)
  
  options(width = max(140, old_width))
  
  cat("\n")
  .powstat_line("=", 92)
  cat(" Binary Endpoint | Single-Arm Exact Binomial Test Design\n")
  cat(" Sample Size, Critical Point and Power Summary\n")
  .powstat_line("=", 92)
  
  .powstat_section("Study Parameters")
  if (!is.null(x$input) && ncol(x$input) >= 2) {
    .powstat_print_kv(
      x$input,
      key_col = 1,
      value_col = 2,
      digits = digits,
      key_width = 42
    )
  } else {
    .powstat_print_df(x$input, digits = digits)
  }
  
  .powstat_section("Primary Design Summary")
  .powstat_print_df(x$design_summary, digits = digits)
  
  if (!is.null(x$optimal_design) && nrow(x$optimal_design) > 0) {
    .powstat_section("Optimal Design")
    .powstat_print_df(x$optimal_design, digits = digits)
  }
  
  if (!is.null(x$fixed_design) && nrow(x$fixed_design) > 0) {
    .powstat_section("Fixed Sample Size Design")
    .powstat_print_df(x$fixed_design, digits = digits)
  }
  
  if (show_valid) {
    .powstat_section("All Valid Designs Satisfying Target Power")
    .powstat_print_df(x$valid_designs, digits = digits)
  }
  
  .powstat_section("Notes")
  
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
  cat("5. Use print(x, show_valid = TRUE) to display all valid designs.\n")
  cat("\n")
  
  invisible(x)
}
