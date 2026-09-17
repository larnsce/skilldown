# Discovery of SKILL.md files in a collection (issue #3).

# Directory names that are never part of a skill collection. The working
# directory (.skilldown) is excluded so a build never discovers its own
# output.
sd_exclude_dirs <- c(
  ".git", "node_modules", ".skilldown", "_site", ".Rproj.user",
  "renv", ".quarto"
)

#' Discover skills in a collection
#'
#' Finds every `SKILL.md` under `path` and groups each one by its parent
#' directory. Supports the layouts observed in the wild: `skills/<name>/`,
#' category subdirectories (`skills/<category>/<name>/`), a single skill at
#' the repository root, and installed locations such as `.claude/skills/`.
#'
#' @param path Path to the root of a skill collection.
#' @param exclude Globs, relative to `path`, of skills to drop: a skill is
#'   excluded when its directory or its `SKILL.md` path matches. This is
#'   the `exclude` key of [skilldown_config]; [build_site()] passes it.
#' @return A data frame with one row per discovered skill: `skill_md` (path
#'   to the file), `dir` (its directory), `rel_dir` (directory relative to
#'   `path`; `"."` for a root skill) and `dir_name` (the directory name the
#'   spec requires the skill `name` to match). The `excluded` attribute
#'   lists the root-relative directories dropped by `exclude`.
#' @export
discover_skills <- function(path = ".", exclude = character()) {
  path <- fs::path_abs(path)
  if (!fs::dir_exists(path)) {
    cli::cli_abort("{.path {path}} is not a directory.")
  }
  files <- fs::dir_ls(
    path,
    recurse = TRUE,
    type = "file",
    regexp = "(^|/)SKILL\\.md$",
    all = TRUE
  )
  rel <- fs::path_rel(files, path)
  keep <- !vapply(
    fs::path_split(rel),
    function(parts) any(parts %in% sd_exclude_dirs),
    logical(1)
  )
  files <- files[keep]
  rel <- rel[keep]

  rel_dir_all <- as.character(fs::path_dir(rel))
  dropped <- sd_excluded(rel_dir_all, exclude) | sd_excluded(as.character(rel), exclude)
  excluded <- rel_dir_all[dropped]
  files <- files[!dropped]
  rel <- rel[!dropped]

  dir <- fs::path_dir(files)
  rel_dir <- fs::path_dir(rel)
  dir_name <- ifelse(
    rel_dir == ".",
    fs::path_file(path),
    fs::path_file(dir)
  )
  out <- data.frame(
    skill_md = as.character(files),
    dir = as.character(dir),
    rel_dir = as.character(rel_dir),
    dir_name = as.character(dir_name),
    stringsAsFactors = FALSE
  )
  out <- out[order(out$rel_dir), , drop = FALSE]
  attr(out, "excluded") <- excluded
  out
}
