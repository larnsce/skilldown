# The every-time verbs: build_site() and preview_site() (issue #2).

# Every rendering verb gates on the Quarto CLI being discoverable, with
# an informative error naming the bundled-binary escape hatches
# (issue #2).
check_quarto <- function() {
  path <- quarto::quarto_path()
  if (is.null(path)) {
    cli::cli_abort(c(
      "The Quarto command line tool was not found.",
      i = "Install it from {.url https://quarto.org/docs/get-started/}.",
      i = paste(
        "Or point the {.envvar QUARTO_PATH} environment variable at a",
        "bundled binary, for example the one shipped with RStudio",
        "({.path /Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto})",
        "or Positron."
      )
    ))
  }
  invisible(path)
}

#' Build the documentation site for a skill collection
#'
#' Regenerates the working directory (see [generate_site()]), renders it
#' with Quarto, and copies the result to `dest`. The collection itself is
#' never modified.
#'
#' @param path Path to the skill collection.
#' @param dest Output directory for the rendered site, relative to
#'   `path`.
#' @param quiet Suppress Quarto's render output.
#' @return Invisibly, the manifest from [generate_site()].
#' @export
build_site <- function(path = ".", dest = "_site", quiet = FALSE) {
  check_quarto()
  path <- fs::path_abs(path)
  manifest <- generate_site(path)
  quarto::quarto_render(manifest$work, as_job = FALSE, quiet = quiet)

  site_dir <- fs::path(manifest$work, "_site")
  dest_dir <- fs::path(path, dest)
  if (fs::dir_exists(dest_dir)) fs::dir_delete(dest_dir)
  fs::dir_copy(site_dir, dest_dir)

  cli::cli_alert_success(
    "Built site for {.strong {manifest$title}}: {length(manifest$pages)} page{?s} in {.path {dest_dir}}."
  )
  if (manifest$n_normalized > 0) {
    cli::cli_alert_info(
      "Normalized frontmatter in {manifest$n_normalized} file{?s} (working copy only; sources untouched)."
    )
  }
  if (nrow(manifest$notes) > 0) {
    cli::cli_alert_warning("{nrow(manifest$notes)} validation note{?s}:")
    cli::cli_ul(sprintf("%s: %s", manifest$notes$file, manifest$notes$note))
  }
  invisible(manifest)
}

#' Preview the documentation site
#'
#' Regenerates the working directory and serves it with
#' `quarto::quarto_preview()`, which watches for changes and reloads.
#'
#' @inheritParams build_site
#' @return Invisibly, the manifest from [generate_site()].
#' @export
preview_site <- function(path = ".") {
  check_quarto()
  manifest <- generate_site(fs::path_abs(path))
  quarto::quarto_preview(manifest$work)
  invisible(manifest)
}
