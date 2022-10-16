#!Rscript
## load dependency
source("src/_helper.R")
## get target version
args <- commandArgs(TRUE)
target.version <- args[1]
loginfo("target.version: %s", target.version)
## load dsr-{version}.yml
target.dsr.path <- sprintf('dsr-%s.yml', target.version)
loginfo("The dsr-%s.yml is: ", target.version)
dsr.pvm <- readLines(target.dsr.path)
cat(dsr.pvm, sep = "\n")
loginfo("Parsing...")
dsr.tokens <- regmatches(
  dsr.pvm,
  regexec(
    "^\\s{2}([^:]*): (.*)$",
    dsr.pvm
  )
)
dsr.tokens <- dsr.tokens[sapply(dsr.tokens, length) == 3]
pkg.version.str <- strsplit(target.version, ".", fixed = TRUE)[[1]]
pkg.version.str <- head(pkg.version.str, 2)
pkg.version.str <- paste(pkg.version.str, collapse = '.')
loginfo('Retrieving MRAN pkg index...')
mran.pkgs <- available.packages(
  sprintf(
    'https://cran.microsoft.com/snapshot/%s/bin/windows/contrib/%s',
    pvm::R.release.dates[target.version] + 14,
    pkg.version.str
  )
)

. <- lapply(dsr.tokens, function(dsr.token) {
  pkg <- dsr.token[2]
  version <- dsr.token[3]
  loginfo("Checking %s(%s)", pkg, version)
  . <- mran.pkgs[mran.pkgs[,"Package"] == pkg, c("Version", "Priority")]
  mran.version <- .[1]
  mran.priority <- .[2]
  loginfo("MRAN version: %s priority: %s", mran.version, mran.priority)
  check <- TRUE
  if (!is.na(mran.priority)) {
    loginfo(sprintf('ERROR: Suspicious priority of pkg: %s on R version: %s', pkg, target.version))
    check <- FALSE
  }
  if (mran.version != version) {
    loginfo(sprintf("ERROR: Found inconsistent version of pkg: %s on R version: %s. pvm: %s mran: %s", pkg, target.version, version, mran.version))
    check <- FALSE
  }
  check
})
if (!all(unlist(.))) {
  stop('Got an error')
}
