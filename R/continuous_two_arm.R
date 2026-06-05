# PowStat/R/continuous_two_arm.R
# Client-side function for continuous endpoint, two-arm MDD

#' Continuous Endpoint Two-Arm MDD Calculation
#'
#' Calculate the Minimal Detectable Difference (MDD) for a two-arm
#' parallel design with a continuous endpoint.
#'
#' @param groups Integer. Number of groups (1 or 2). Default is 2.
#' @param normalApproximation Logical. Use normal approximation? Default FALSE.
#' @param alpha Numeric. One-sided significance level. Default 0.025.
#' @param beta Numeric. Type II error rate. Default 0.2.
#' @param alternative Numeric. The hypothesized mean difference for power calculation.
#' @param sided Integer. 1 for one-sided, 2 for two-sided test.
#' @param stDev Numeric. Standard deviation. Must be positive.
#' @param allocationRatioPlanned Numeric. Allocation ratio (treatment/control). Default 1.
#' @param singlearmsamplesize Numeric. Per-group sample size for MDD formula calculation.
#' @param digits Integer. Number of decimal places in output.
#'
#' @return An object of class \code{PowStatContinuousTwoArm} containing:
#' \describe{
#'   \item{parameters}{Data frame of study parameters}
#'   \item{results}{Data frame comparing rpact and formula-based results}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' res <- ps_continuous_two_arm(
#'   alpha = 0.025,
#'   beta = 0.2,
#'   alternative = 4.023819,
#'   sided = 1,
#'   stDev = 19,
#'   allocationRatioPlanned = 1,
#'   singlearmsamplesize = 300
#' )
#' print(res)
#' }
ps_continuous_two_arm <- function(
    groups = 2,
    normalApproximation = FALSE,
    alpha = 0.025,
    beta = 0.2,
    alternative,
    sided = 1,
    stDev,
    allocationRatioPlanned = 1,
    singlearmsamplesize,
    digits = 5
) {
  # Input validation (client-side)
  if (!groups %in% c(1, 2)) stop("groups must be 1 or 2.")
  if (alpha <= 0 || alpha >= 1) stop("alpha must be between 0 and 1.")
  if (beta <= 0 || beta >= 1) stop("beta must be between 0 and 1.")
  if (!sided %in% c(1, 2)) stop("sided must be 1 or 2.")
  if (stDev <= 0) stop("stDev must be positive.")
  if (allocationRatioPlanned <= 0) stop("allocationRatioPlanned must be positive.")
  if (missing(singlearmsamplesize) || singlearmsamplesize <= 0) {
    stop("singlearmsamplesize must be provided and positive.")
  }
  if (missing(alternative)) stop("alternative must be provided.")
  
  params <- list(
    groups = groups,
    normalApproximation = normalApproximation,
    alpha = alpha,
    beta = beta,
    alternative = alternative,
    sided = sided,
    stDev = stDev,
    allocationRatioPlanned = allocationRatioPlanned,
    singlearmsamplesize = singlearmsamplesize,
    digits = digits
  )
  
  # result <- powstat_api_call("continuous/two_arm_mdd", params)
  result <- powstat_api_call("continuous_two_arm_mdd", params)
  
  
  result$parameters <- as.data.frame(result$parameters, stringsAsFactors = FALSE)
  result$results <- as.data.frame(result$results, stringsAsFactors = FALSE)
  
  class(result) <- "PowStatContinuousTwoArm"
  
  result
}

#' @export
print.PowStatContinuousTwoArm <- function(x, ...) {
  cat("\n")
  cat("============================================================\n")
  cat(" Continuous Endpoint | Two-Arm Design | MDD Calculation\n")
  cat("============================================================\n\n")
  
  cat("Study Parameters\n")
  cat("------------------------------------------------------------\n")
  print(x$parameters, row.names = FALSE, right = FALSE)
  
  cat("\n")
  cat("Main Results\n")
  cat("------------------------------------------------------------\n")
  print(x$results, row.names = FALSE, right = FALSE)
  
  cat("\n")
  cat("Notes\n")
  cat("------------------------------------------------------------\n")
  cat("1. Method 1 uses rpact to calculate the required sample size based on the specified alternative.\n")
  cat("2. Method 2 calculates MDD using:\n")
  cat("   MDD = (Z_alpha + Z_beta) * SD * sqrt(1/n1 + 1/n2)\n")
  cat("3. For one-sided tests, Z_alpha = qnorm(1 - alpha).\n")
  cat("4. For two-sided tests, Z_alpha = qnorm(1 - alpha / 2).\n")
  cat("\n")
  
  invisible(x)
}
