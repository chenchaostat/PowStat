# PowStat/R/binary_two_arm.R
# Client-side function for binary endpoint, two-arm superiority

#' Binary Endpoint Two-Arm Superiority Design
#'
#' Calculate sample size and critical effect scale for a two-arm
#' superiority design with binary endpoint using Z pooled, Z unpooled,
#' and Fisher's exact test methods.
#'
#' @param p0 Numeric. Control group response rate (0, 1).
#' @param p1 Numeric. Treatment group response rate (0, 1). Must be > p0.
#' @param sided Integer. 1 or 2. Default 1.
#' @param allocationRatioPlanned Numeric. n1/n0 ratio. Default 1.
#' @param alpha Numeric. Significance level. Default 0.025.
#' @param beta Numeric. Type II error rate. Default 0.01.
#' @param n_fixed Integer or NULL. Fixed total sample size. Default NULL.
#' @param exact_max_n0 Integer. Maximum n0 for exact Fisher search. Default 5000.
#' @param digits Integer. Decimal places. Default 6.
#'
#' @return An object of class \code{PowStatBinaryTwoArm} containing:
#' \describe{
#'   \item{input}{Data frame of input parameters}
#'   \item{sample_size_summary}{Summary comparing methods}
#'   \item{fixed_n_criticalValuesEffectScale}{Results for fixed sample size}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' res <- ps_binary_two_arm(
#'   p0 = 0.1,
#'   p1 = 0.4,
#'   sided = 1,
#'   alpha = 0.025,
#'   beta = 0.15,
#'   allocationRatioPlanned = 1,
#'   n_fixed = 72
#' )
#' print(res)
#' }
ps_binary_two_arm <- function(
    p0,
    p1,
    sided = 1,
    allocationRatioPlanned = 1,
    alpha = 0.025,
    beta = 0.01,
    n_fixed = NULL,
    exact_max_n0 = 5000,
    digits = 6
) {
  # Client-side validation
  if (!sided %in% c(1, 2)) stop("sided must be 1 or 2.")
  if (p0 <= 0 || p0 >= 1) stop("p0 must be between 0 and 1.")
  if (p1 <= 0 || p1 >= 1) stop("p1 must be between 0 and 1.")
  if (p1 <= p0) stop("p1 must be greater than p0 for superiority.")
  if (alpha <= 0 || alpha >= 1) stop("alpha must be between 0 and 1.")
  if (beta <= 0 || beta >= 1) stop("beta must be between 0 and 1.")
  
  params <- list(
    p0 = p0,
    p1 = p1,
    sided = sided,
    allocationRatioPlanned = allocationRatioPlanned,
    alpha = alpha,
    beta = beta,
    n_fixed = n_fixed,
    exact_max_n0 = exact_max_n0,
    digits = digits
  )
  
  # result <- powstat_api_call("binary/two_arm", params)
  result <- powstat_api_call("binary_two_arm", params)
  
  
  # Convert to data frames
  if (!is.null(result$input)) {
    result$input <- as.data.frame(result$input, stringsAsFactors = FALSE)
  }
  if (!is.null(result$sample_size_summary)) {
    result$sample_size_summary <- as.data.frame(
      result$sample_size_summary, stringsAsFactors = FALSE
    )
  }
  if (!is.null(result$fixed_n_criticalValuesEffectScale)) {
    result$fixed_n_criticalValuesEffectScale <- as.data.frame(
      result$fixed_n_criticalValuesEffectScale, stringsAsFactors = FALSE
    )
  }
  
  class(result) <- "PowStatBinaryTwoArm"
  
  result
}

#' @export
print.PowStatBinaryTwoArm <- function(x, digits = 6, ...) {
  cat("\n")
  cat("====================================================================\n")
  cat(" Binary Endpoint | Two-Arm Superiority Design\n")
  cat(" Sample Size and Critical Effect Scale Summary\n")
  cat("====================================================================\n\n")
  
  cat("Study Parameters\n")
  cat("--------------------------------------------------------------------\n")
  if (!is.null(x$input)) {
    print(x$input, row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Sample Size and Critical Effect Scale Summary\n")
  cat("--------------------------------------------------------------------\n")
  if (!is.null(x$sample_size_summary)) {
    ss_print <- x$sample_size_summary
    numeric_cols <- sapply(ss_print, is.numeric)
    ss_print[numeric_cols] <- lapply(
      ss_print[numeric_cols], function(v) round(v, digits)
    )
    print(ss_print, row.names = FALSE, right = FALSE)
  }
  
  if (!is.null(x$fixed_n_criticalValuesEffectScale)) {
    cat("\n")
    cat("Fixed Sample Size: Critical Effect Scale and Achieved Power\n")
    cat("--------------------------------------------------------------------\n")
    fixed_print <- x$fixed_n_criticalValuesEffectScale
    numeric_cols <- sapply(fixed_print, is.numeric)
    fixed_print[numeric_cols] <- lapply(
      fixed_print[numeric_cols], function(v) round(v, digits)
    )
    print(fixed_print, row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Notes\n")
  cat("--------------------------------------------------------------------\n")
  cat("1. n1 = treatment group; n0 = control group.\n")
  cat("2. cv_pooled_manual uses the pooled Wald SE under the alternative average rate.\n")
  cat("3. cv_unpooled_manual uses the unpooled Wald SE under p1 and p0.\n")
  cat("4. Exact Fisher power is calculated by enumeration.\n")
  cat("\n")
  
  invisible(x)
}
