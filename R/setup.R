# The run-once verbs: skilldown_setup() and
# use_skilldown_github_pages() (issue #2).

#' Set up skilldown for a skill collection
#'
#' Run once per collection. Copies the Quarto configuration template into
#' a `skilldown/` settings directory (where it can be edited; the
#' `$SKILLDOWN_*` variables are substituted on every render) and adds the
#' working and output directories to `.gitignore`. [build_site()] works
#' without this; the settings directory only overrides the defaults.
#'
#' @param path Path to the skill collection.
#' @return Invisibly, `path`.
#' @export
skilldown_setup <- function(path = ".") {
  path <- fs::path_abs(path)
  settings <- fs::path(path, "skilldown")
  fs::dir_create(settings)
  target <- fs::path(settings, "_quarto.yml")
  if (fs::file_exists(target)) {
    cli::cli_alert_info("{.path skilldown/_quarto.yml} already exists; leaving it alone.")
  } else {
    fs::file_copy(
      system.file("templates", "_quarto.yml", package = "skilldown"),
      target
    )
    cli::cli_alert_success("Created {.path skilldown/_quarto.yml} (edit to customize the site).")
  }

  gitignore <- fs::path(path, ".gitignore")
  entries <- c(".skilldown/", "_site/")
  existing <- if (fs::file_exists(gitignore)) readLines(gitignore, warn = FALSE) else character()
  missing <- setdiff(entries, trimws(existing))
  if (length(missing) > 0) {
    writeLines(c(existing, missing), gitignore)
    cli::cli_alert_success("Added {.val {missing}} to {.path .gitignore}.")
  }
  invisible(path)
}

#' Set up publishing to GitHub Pages
#'
#' Installs a GitHub Actions workflow that builds the site with skilldown
#' on every push to `main` and deploys it to GitHub Pages, then prints
#' the one-time repository settings to flip. There is no R-level publish
#' verb because the quarto package has none for GitHub Pages (issue #2);
#' the workflow also pins the Quarto version, so CI renders match local
#' ones.
#'
#' @param path Path to the skill collection.
#' @return Invisibly, the path of the installed workflow file.
#' @export
use_skilldown_github_pages <- function(path = ".") {
  path <- fs::path_abs(path)
  workflow_dir <- fs::path(path, ".github", "workflows")
  fs::dir_create(workflow_dir)
  target <- fs::path(workflow_dir, "publish-site.yaml")
  fs::file_copy(
    system.file("workflows", "publish-site.yaml", package = "skilldown"),
    target,
    overwrite = TRUE
  )
  cli::cli_alert_success("Installed {.path .github/workflows/publish-site.yaml}.")
  cli::cli_alert_info("One-time setup left to do on GitHub:")
  cli::cli_ol(c(
    "Commit and push the workflow file.",
    "Repository {.strong Settings > Pages}: set {.strong Source} to {.strong GitHub Actions}.",
    "Push to {.strong main} (or run the workflow manually) to publish."
  ))
  invisible(target)
}
