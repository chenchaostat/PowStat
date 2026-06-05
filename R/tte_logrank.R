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
      result[[field]] <- .powstat_to_df(result[[field]])
    }
  }
  
  # 防御性修复：Metric/Value 横向宽表转成长表
  if (!is.null(result$input)) {
    result$input <- .powstat_normalize_kv_wide(
      result$input,
      key = "Parameter",
      value = "Value"
    )
  }
  
  if (!is.null(result$model_summary)) {
    result$model_summary <- .powstat_normalize_kv_wide(
      result$model_summary,
      key = "Parameter",
      value = "Value"
    )
  }
  
  if (!is.null(result$event_summary)) {
    result$event_summary <- .powstat_normalize_kv_wide(
      result$event_summary,
      key = "Metric",
      value = "Value"
    )
  }
  
  if (!is.null(result$duration_summary)) {
    result$duration_summary <- .powstat_normalize_kv_wide(
      result$duration_summary,
      key = "Metric",
      value = "Value"
    )
  }
  
  # 防御性修复：Group/N/Group.1/N.1 转成长表
  if (!is.null(result$sample_size_summary)) {
    result$sample_size_summary <- .powstat_normalize_repeated_sets(
      result$sample_size_summary,
      cols = c("Group", "N", "Allocation_Proportion")
    )
  }
  
  
  result$digits <- digits
  
  class(result) <- "PowStatTTELogrank"
  
  result
}



#' @export
print.PowStatTTELogrank <- function(x, digits = x$digits %||% 6, ...) {
  old_width <- getOption("width")
  on.exit(options(width = old_width), add = TRUE)
  
  # 尽量给控制台更宽的显示空间
  options(width = max(140, old_width))
  
  cat("\n")
  .powstat_line("=", 92)
  cat(" Time-to-Event Endpoint | Two-Arm Logrank Design\n")
  cat(" Sample Size, Event Target, Calendar Duration and Boundary Summary\n")
  .powstat_line("=", 92)
  
  .powstat_section("Study Parameters")
  if (!is.null(x$input) && ncol(x$input) >= 2) {
    .powstat_print_kv(x$input, key_col = 1, value_col = 2, digits = digits, key_width = 42)
  } else {
    .powstat_print_df(x$input, digits = digits)
  }
  
  .powstat_section("Survival and Dropout Model")
  if (!is.null(x$model_summary) && ncol(x$model_summary) >= 2) {
    .powstat_print_kv(x$model_summary, key_col = 1, value_col = 2, digits = digits, key_width = 42)
  } else {
    .powstat_print_df(x$model_summary, digits = digits)
  }
  
  .powstat_section("Sample Size Information")
  .powstat_print_df(x$sample_size_summary, digits = digits)
  
  .powstat_section("Event and Information Summary")
  if (!is.null(x$event_summary) && ncol(x$event_summary) >= 2) {
    .powstat_print_kv(x$event_summary, key_col = 1, value_col = 2, digits = digits, key_width = 56)
  } else {
    .powstat_print_df(x$event_summary, digits = digits)
  }
  
  .powstat_section("Accrual and Study Duration Summary")
  if (!is.null(x$duration_summary) && ncol(x$duration_summary) >= 2) {
    .powstat_print_kv(x$duration_summary, key_col = 1, value_col = 2, digits = digits, key_width = 42)
  } else {
    .powstat_print_df(x$duration_summary, digits = digits)
  }
  
  .powstat_section("Analysis-Look Details")
  .powstat_print_wide_df(x$stages, digits = digits, cols_per_block = 6)
  
  .powstat_section("Notes")
  cat("1. Calendar_Time is measured from first subject in.\n")
  cat("2. Additional_Followup is the follow-up duration after completion of accrual.\n")
  cat("3. Event targets are rounded upward for calendar-duration calculations.\n")
  cat("4. MDD is the minimum detectable HR at the corresponding efficacy boundary.\n")
  cat("\n")
  
  invisible(x)
}
