# PowStat/R/zzz.R
# Package-level environment for configuration

.powstat_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .powstat_env$server_url <- Sys.getenv(
    "POWSTAT_SERVER_URL",
    unset = ""
  )
  
  .powstat_env$api_token <- NULL
  
  timeout_env <- Sys.getenv("POWSTAT_TIMEOUT", unset = "")
  
  .powstat_env$timeout <- if (nchar(timeout_env) > 0) {
    as.numeric(timeout_env)
  } else {
    120
  }
  
  if (is.na(.powstat_env$timeout) || .powstat_env$timeout <= 0) {
    .powstat_env$timeout <- 120
  }
}
