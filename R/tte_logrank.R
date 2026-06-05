# PowStat/R/tte_logrank.R
# Client-side function for time-to-event logrank design

#' Time-to-Event Two-Arm Logrank Design
#'
#' Calculate sample size, event targets, calendar duration, and efficacy
#' boundaries for a two-arm logrank test design. Supports fixed designs
#' and group sequential designs (GSD) with three input modes.
#'
#' @param medsurv_control Numeric. Median survival in the control group (months).
#' @param hr Numeric. Hazard ratio (treatment/control). Must be != 1.
#' @param n_interim Integer. Number of interim analyses. 0 for fixed design.
#' @param info_frac Numeric vector or NULL. Information fractions for interim looks.
#' @param alpha Numeric. One-sided significance level. Default 0.025.
#' @param beta Numeric. Type II error rate. Default 0.1.
#' @param allocation_ratio Numeric. Treatment/control allocation ratio. Default 1.
#' @param accrual_rate Numeric or NULL. Accrual rate per month (Mode 1 or 2).
#' @param accrual_duration Numeric or NULL. Accrual duration in months (Mode 1 or 3).
#' @param n_total Integer or NULL. Total sample size (Mode 2).
#' @param total_study_duration Numeric or NULL. Total study duration in months (Mode 3).
#' @param dropout_rate_control Numeric. Annual dropout rate in control. Default 0.
#' @param dropout_rate_treatment Numeric. Annual dropout rate in treatment. Default same as control.
#' @param spending_function Character. Spending function name. Default "sfLDOF".
#' @param sided Integer. 1 or 2. Default 1.
#' @param digits Integer. Decimal places. Default 6.
#'
#' @details
#' Three input modes:
#' \itemize{
#'   \item Mode 1: \code{accrual_rate} + \code{accrual_duration} -> solve follow-up duration
#'   \item Mode 2: \code{accrual_rate} + \code{n_total} -> solve accrual duration then follow-up
#'   \item Mode 3: \code{accrual_duration} + \code{total_study_duration} -> solve sample size
#' }
#'
#' @return An object of class \code{PowStatTTELogrank} containing:
#' \describe{
#'   \item{input}{Study parameters}
#'   \item{model_summary}{Survival and dropout model}
#'   \item{sample_size_summary}{Sample size by group}
#'   \item{event_summary}{Event and information summary}
#'   \item{duration_summary}{Accrual and study duration}
#'   \item{stages}{Analysis-look details with boundaries}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' # Fixed design - Mode 1
#' res <- ps_tte_logrank(
#'   medsurv_control = 9.7,
#'   hr = 0.692,
#'   n_interim = 0,
#'   alpha = 0.025,
#'   beta = 0.15,
#'   accrual_rate = 20,
#'   accrual_duration = 21.5,
#'   dropout_rate_control = 0.10
#' )
#' print(res)
#'
#' # GSD - Mode 1
#' res_gsd <- ps_tte_logrank(
#'   medsurv_control = 9.7,
#'   hr = 0.692,
#'   n_interim = 1,
#'   info_frac = 0.7,
#'   alpha = 0.025,
#'   beta = 0.15,
#'   accrual_rate = 20,
#'   accrual_duration = 21.75,
#'   dropout_rate_control = 0.10,
#'   spending_function = "sfLDOF"
#' )
#' print(res_gsd)
#' }
ps_tte_logrank <- function(
    medsurv_control,
    hr,
    n_interim = 0,
    info_frac = NULL,
    alpha = 0.025,
    beta = 0.1,
    allocation_ratio = 1,
    accrual_rate = NULL,
    accrual_duration = NULL,
    n_total = NULL,
    total_study_duration = NULL,
    dropout_rate_control = 0,
    dropout_rate_treatment = dropout_rate_control,
    spending_function = "sfLDOF",
    sided = 1,
    digits = 6
) {
  # Client-side validation
  if (medsurv_control <= 0) stop("medsurv_control must be positive.")
  if (hr <= 0 || hr == 1) stop("hr must be positive and != 1.")
  if (alpha <= 0 || alpha >= 1) stop("alpha must be between 0 and 1.")
  if (beta <= 0 || beta >= 1) stop("beta must be between 0 and 1.")
  if (!sided %in% c(1, 2)) stop("sided must be 1 or 2.")
  if (n_interim < 0) stop("n_interim must be non-negative.")
  
  params <- list(
    medsurv_control = medsurv_control,
    hr = hr,
    n_interim = n_interim,
    info_frac = info_frac,
    alpha = alpha,
    beta = beta,
    allocation_ratio = allocation_ratio,
    accrual_rate = accrual_rate,
    accrual_duration = accrual_duration,
    n_total = n_total,
    total_study_duration = total_study_duration,
    dropout_rate_control = dropout_rate_control,
    dropout_rate_treatment = dropout_rate_treatment,
    spending_function = spending_function,
    sided = sided,
    digits = digits
  )
  
  # result <- powstat_api_call("tte/logrank", params)
  result <- powstat_api_call("tte_logrank", params)
  
  # Convert to data frames
  df_fields <- c(
    "input", "model_summary", "sample_size_summary",
    "event_summary", "duration_summary", "stages"
  )
  
  for (field in df_fields) {
    if (!is.null(result[[field]])) {
      result[[field]] <- as.data.frame(result[[field]], stringsAsFactors = FALSE)
    }
  }
  
  result$digits <- digits
  
  class(result) <- "PowStatTTELogrank"
  
  result
}

#' @export
print.PowStatTTELogrank <- function(x, digits = x$digits %||% 6, ...) {
  round_df <- function(df, digits) {
    df2 <- as.data.frame(df)
    numeric_cols <- sapply(df2, is.numeric)
    df2[numeric_cols] <- lapply(
      df2[numeric_cols], function(v) round(v, digits)
    )
    df2
  }
  
  cat("\n")
  cat("================================================================================\n")
  cat(" Time-to-Event Endpoint | Two-Arm Logrank Design\n")
  cat(" Sample Size, Event Target, Calendar Duration and Boundary Summary\n")
  cat("================================================================================\n\n")
  
  cat("Study Parameters\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$input)) {
    print(round_df(x$input, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Survival and Dropout Model\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$model_summary)) {
    print(round_df(x$model_summary, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Sample Size Information\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$sample_size_summary)) {
    print(round_df(x$sample_size_summary, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Event and Information Summary\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$event_summary)) {
    print(round_df(x$event_summary, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Accrual and Study Duration Summary\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$duration_summary)) {
    print(round_df(x$duration_summary, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Analysis-Look Details\n")
  cat("--------------------------------------------------------------------------------\n")
  if (!is.null(x$stages)) {
    print(round_df(x$stages, digits), row.names = FALSE, right = FALSE)
  }
  
  cat("\n")
  cat("Notes\n")
  cat("--------------------------------------------------------------------------------\n")
  cat("1. Calendar_Time is measured from first subject in.\n")
  cat("2. Additional_Followup is follow-up after completion of accrual.\n")
  cat("3. Event targets are rounded upward for calendar-duration calculations.\n")
  cat("4. MDD is the minimum detectable HR at the corresponding efficacy boundary.\n")
  cat("\n")
  
  invisible(x)
}
