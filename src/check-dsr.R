#!Rscript
## load dependency
rm(list = ls(all.names = TRUE))
source("src/_helper.R")
## get target version
if (interactive()) {
  target.version <- readline('target version:')  
} else {
  args <- commandArgs(TRUE)
  target.version <- args[1]
}
loginfo("target.version: %s", target.version)
.cmd1 <- sprintf("docker run --rm rocker/r-ver:%s Rscript -e 'cat(deparse(names(which(installed.packages()[,c(\"Priority\")] ==\"base\"))))'", target.version)
.cmd2 <- sprintf("docker run --rm rocker/r-ver:%s Rscript -e 'cat(deparse(names(which(installed.packages()[,c(\"Priority\")] ==\"recommended\"))))'", target.version)
recom.pkgs <- c(
  eval(parse(text = system(.cmd1, intern = TRUE))),
  eval(parse(text = system(.cmd2, intern = TRUE)))
)

## load dsr-{version}.yml
target.dsr.path <- sprintf('dsr-%s.yml', target.version)
if (!file.exists(target.dsr.path)) {
  ## copy latest version
  .dsrs <- dir('.', '^dsr-[0-9\\.]+.yml$')
  .dsrs.v <- regmatches(x = .dsrs, m = regexec(pattern = '^dsr-(.+).yml$', text = .dsrs))
  .dsrs.v <- sapply(.dsrs.v, "[", 2)
  .dsrs.max.v <- max(package_version(.dsrs.v))
  loginfo('Copy from version: %s', .dsrs.max.v)
  stopifnot(file.copy(sprintf('dsr-%s.yml', .dsrs.max.v), target.dsr.path))
}
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


dsr.pkgs <- sapply(dsr.tokens, "[", 2)
. <- lapply(dsr.tokens, function(dsr.token) {
  pkg <- dsr.token[2]
  loginfo('pkg: %s', pkg)
  version <- dsr.token[3]
  loginfo("Checking %s(%s)", pkg, version)
  . <- mran.pkgs[pkg, c("Version", "Priority")]
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
  # check dependency
  dep.pkgs <- tools::package_dependencies(pkg, db = mran.pkgs, which = 'strong')[[pkg]]
  dep.check.result <- which(! dep.pkgs %in% dsr.pkgs)
  if (length(dep.check.result) > 0) {
    if (!all(dep.pkgs[dep.check.result] %in% recom.pkgs)) {
      check <- FALSE
      browser()
    }
  }
  check
})
if (!all(unlist(.))) {
  if (interactive()) file.edit(target.dsr.path)
  stop('Got an error')
}
