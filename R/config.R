# PowStat/R/config.R
# Server configuration functions

#' Set PowStat Server URL
#'
#' @param url Character. The base URL of the PowStat public API gateway.
#' @param timeout Numeric. Request timeout in seconds. Default is 120.
#' @return Invisibly returns the previous server URL.
#' @export
#' @examples
#' \dontrun{
#' powstat_set_server("https://api.example.com")
#' }
powstat_set_server <- function(url, timeout = 120) {
  if (!is.character(url) || length(url) != 1 || nchar(url) == 0) {
    stop("url must be a non-empty character string.")
  }
  
  if (!is.numeric(timeout) || length(timeout) != 1 || timeout <= 0) {
    stop("timeout must be a positive number.")
  }
  
  url <- sub("/$", "", url)
  
  old_url <- .powstat_env$server_url
  .powstat_env$server_url <- url
  .powstat_env$timeout <- timeout
  
  cli::cli_inform(
    "PowStat server has been configured."
  )
  
  invisible(old_url)
}

#' Get Current PowStat Server URL
#'
#' @param masked Logical. Whether to mask the URL in output. Default TRUE.
#' @return Character. The current server URL.
#' @export
powstat_get_server <- function(masked = TRUE) {
  url <- .powstat_env$server_url
  
  if (masked) {
    return(.powstat_mask(url))
  }
  
  url
}

#' Set PowStat API Token
#'
#' @param token Character. API token issued by the PowStat service.
#' @return Invisibly returns TRUE.
#' @export
#' @examples
#' \dontrun{
#' powstat_set_api_token("your-token")
#' }
powstat_set_api_token <- function(token) {
  if (!is.character(token) || length(token) != 1 || nchar(token) == 0) {
    stop("token must be a non-empty character string.")
  }
  
  .powstat_env$api_token <- token
  
  cli::cli_inform("PowStat API token has been configured for this R session.")
  
  invisible(TRUE)
}

#' Clear PowStat API Token
#'
#' @return Invisibly returns TRUE.
#' @export
powstat_clear_api_token <- function() {
  .powstat_env$api_token <- NULL
  
  cli::cli_inform("PowStat API token has been cleared from this R session.")
  
  invisible(TRUE)
}

#' Get PowStat API Token Status
#'
#' @return Logical. TRUE if an API token is available.
#' @export
powstat_has_api_token <- function() {
  !is.null(.powstat_get_api_token())
}

#' Health Check for PowStat Server
#'
#' @return Logical. TRUE if the server is reachable and healthy.
#' @export
powstat_health_check <- function() {
  base_url <- .powstat_env$server_url
  timeout <- .powstat_env$timeout
  
  if (is.null(base_url) || !is.character(base_url) || length(base_url) != 1 || nchar(base_url) == 0) {
    cli::cli_abort(
      c(
        "x" = "PowStat server is not configured.",
        "i" = "Use {.fn powstat_set_server} or set environment variable {.envvar POWSTAT_SERVER_URL}."
      )
    )
  }
  
  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("health") |>
    httr2::req_timeout(timeout)
  
  token <- .powstat_get_api_token()
  
  if (!is.null(token) && nchar(token) > 0) {
    req <- req |>
      httr2::req_auth_bearer_token(token)
  }
  
  tryCatch(
    {
      resp <- httr2::req_perform(req)
      
      status <- httr2::resp_status(resp)
      
      if (status == 200) {
        cli::cli_inform(
          c("v" = "PowStat server is reachable and healthy.")
        )
        return(invisible(TRUE))
      } else {
        cli::cli_warn(
          "PowStat server returned a non-OK status."
        )
        return(invisible(FALSE))
      }
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "x" = "Cannot reach PowStat server.",
          "i" = "Please check server configuration, network connection, and authentication.",
          "i" = "Error: {conditionMessage(e)}"
        )
      )
    }
  )
}
