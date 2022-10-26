## load packages
library(pvm)
## helper functions
loginfo <- function(fmt, ...) {
  msg <- sprintf(fmt, ...)
  cat(sprintf("(%s) ", Sys.time()))
  cat(msg)
  cat("\n")
}
