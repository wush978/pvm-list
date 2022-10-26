#! #!Rscript
## load dependency
source("src/_helper.R")
all.versions <- names(pvm::R.release.dates)
all.versions <- as.package_version(all.versions)
. <- lapply(all.versions[all.versions >= '3.3.3'], function(version) {
  cat(as.character(version))
  cat('\n')
})
