# Copy a fixture collection into a temp directory so generation runs
# outside any git repository (repo_browse_url() must come back NA and
# snapshots stay deterministic).
local_fixture <- function(name, env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  dest <- fs::path(tmp, name)
  fs::dir_copy(test_path("fixtures", name), dest)
  dest
}

skip_if_no_quarto <- function() {
  testthat::skip_if(
    is.null(quarto::quarto_path()),
    "Quarto CLI not available"
  )
}

# Generate a fixture collection into a temp working directory and return
# the paths plus the manifest (shared by the site and config tests).
generate_fixture <- function(name, env = parent.frame()) {
  src <- local_fixture(name, env = env)
  work <- fs::path(withr::local_tempdir(.local_envir = env), "site")
  manifest <- suppressWarnings(generate_site(src, work = work))
  list(src = src, work = work, manifest = manifest)
}

read_work <- function(x, rel) {
  paste(readLines(fs::path(x$work, rel), warn = FALSE), collapse = "\n")
}
