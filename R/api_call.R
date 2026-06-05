# PowStat/R/api_call.R
# Internal function for making API calls

#' @keywords internal
powstat_api_call <- function(operation, params) {
  base_url <- .powstat_env$server_url
  timeout <- .powstat_env$timeout
  
  if (
    is.null(base_url) ||
    !is.character(base_url) ||
    length(base_url) != 1 ||
    nchar(base_url) == 0
  ) {
    cli::cli_abort(
      c(
        "x" = "PowStat server is not configured.",
        "i" = "Use {.fn powstat_set_server} or set environment variable {.envvar POWSTAT_SERVER_URL}."
      )
    )
  }
  
  if (!is.character(operation) || length(operation) != 1 || nchar(operation) == 0) {
    cli::cli_abort("operation must be a non-empty character string.")
  }
  
  token <- .powstat_get_api_token()
  
  payload <- list(
    operation = operation,
    params = params
  )
  
  req <- httr2::request(base_url) |>
    httr2::req_url_path_append("api", "v1", "compute") |>
    httr2::req_body_json(payload, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout) |>
    httr2::req_method("POST")
  
  if (!is.null(token) && nchar(token) > 0) {
    req <- req |>
      httr2::req_auth_bearer_token(token)
  }
  
  resp <- tryCatch(
    {
      httr2::req_perform(req)
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "x" = "PowStat API request failed.",
          "i" = "Please check server configuration, network connection, and authentication.",
          "i" = "Use {.fn powstat_health_check} to verify server availability.",
          "i" = "Error: {conditionMessage(e)}"
        )
      )
    }
  )
  
  status <- httr2::resp_status(resp)
  
  body <- tryCatch(
    {
      httr2::resp_body_json(resp, simplifyVector = FALSE)
    },
    error = function(e) {
      list(error = "Failed to parse server response as JSON.")
    }
  )
  
  if (status != 200) {
    msg <- body$error %||% body$message %||% "No details available"
    
    cli::cli_abort(
      c(
        "x" = "PowStat server returned an error.",
        "i" = "HTTP status: {status}",
        "i" = "Message: {msg}"
      )
    )
  }
  
  if (!is.null(body$error)) {
    cli::cli_abort(
      c(
        "x" = "PowStat computation failed.",
        "i" = "Message: {body$error}"
      )
    )
  }
  
  body
}

#' @keywords internal
.powstat_get_api_token <- function() {
  token <- .powstat_env$api_token
  
  if (
    !is.null(token) &&
    is.character(token) &&
    length(token) == 1 &&
    nchar(token) > 0
  ) {
    return(token)
  }
  
  token <- Sys.getenv("POWSTAT_API_TOKEN", unset = "")
  
  if (nchar(token) > 0) {
    return(token)
  }
  
  NULL
}

#' @keywords internal
.powstat_mask <- function(x, keep = 4) {
  if (
    is.null(x) ||
    !is.character(x) ||
    length(x) != 1 ||
    nchar(x) == 0
  ) {
    return("")
  }
  
  n <- nchar(x)
  
  if (n <= keep * 2) {
    return(paste0(substr(x, 1, 1), "***"))
  }
  
  paste0(
    substr(x, 1, keep),
    "...",
    substr(x, n - keep + 1, n)
  )
}

#' @keywords internal
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}
