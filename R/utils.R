# Small helpers shared across the pipeline.

# yaml::as.yaml() writes YAML 1.1 booleans (yes/no); Quarto reads YAML
# 1.2 and rejects them. Emit true/false verbatim.
sd_yaml <- function(x) {
  trimws(
    yaml::as.yaml(x, handlers = list(logical = yaml::verbatim_logical)),
    "right"
  )
}

# The https browse URL of the collection's origin remote, or NA when the
# collection is not a git repository (or has no remote). Used for
# repo-actions in the navbar and for blob-URL link rewriting (issue #6).
repo_browse_url <- function(path) {
  url <- tryCatch(
    suppressWarnings(system2(
      "git", c("-C", shQuote(path), "config", "--get", "remote.origin.url"),
      stdout = TRUE, stderr = FALSE
    )),
    error = function(e) character()
  )
  if (length(url) == 0 || !nzchar(url[1])) {
    return(NA_character_)
  }
  url <- trimws(url[1])
  # git@host:owner/repo(.git) -> https://host/owner/repo
  url <- sub("^git@([^:]+):", "https://\\1/", url)
  url <- sub("^ssh://git@", "https://", url)
  sub("\\.git$", "", url)
}

blob_url <- function(repo_url, rel_path) {
  paste0(repo_url, "/blob/HEAD/", rel_path)
}

image_exts <- c("png", "jpg", "jpeg", "gif", "svg", "webp", "avif")

# Rewrite relative markdown links on one page (issue #6):
# - links to pages in the rendered set stay relative,
# - links to a SKILL.md are redirected to its generated page (`aliases`,
#   a named character vector mapping root-relative source paths to
#   root-relative page paths),
# - image links stay relative (the files are copied alongside),
# - links to existing files outside the rendered set point to the
#   repository blob URL instead of a 404,
# - absolute URLs, anchors and mailto links are left alone.
# `page_rel_dir` is the page directory relative to the site root,
# `rendered` the set of root-relative markdown paths that become pages.
rewrite_links <- function(text, page_rel_dir, rendered, repo_url, root,
                          aliases = character()) {
  rx <- "\\]\\(([^()[:space:]]+)\\)"
  match_all <- gregexpr(rx, text, perl = TRUE)
  targets <- regmatches(text, match_all)
  if (length(targets[[1]]) == 0) {
    return(text)
  }
  rewritten <- vapply(targets[[1]], function(m) {
    target <- sub(rx, "\\1", m, perl = TRUE)
    if (grepl("^([a-zA-Z][a-zA-Z0-9+.-]*:|//|#|/)", target)) {
      return(m)
    }
    anchor <- ""
    if (grepl("#", target, fixed = TRUE)) {
      anchor <- sub("^[^#]*", "", target)
      target <- sub("#.*$", "", target)
      if (!nzchar(target)) {
        return(m)
      }
    }
    resolved <- fs::path_norm(fs::path(page_rel_dir, target))
    if (grepl("^\\.\\.", resolved)) {
      return(m)
    }
    resolved <- as.character(resolved)
    if (resolved %in% names(aliases)) {
      new_rel <- as.character(fs::path_rel(aliases[[resolved]], page_rel_dir))
      return(paste0("](", new_rel, anchor, ")"))
    }
    ext <- tolower(fs::path_ext(resolved))
    if (resolved %in% rendered || ext %in% image_exts) {
      return(m)
    }
    if (!is.na(repo_url) && fs::file_exists(fs::path(root, resolved))) {
      return(paste0("](", blob_url(repo_url, resolved), anchor, ")"))
    }
    m
  }, character(1), USE.NAMES = FALSE)
  regmatches(text, match_all) <- list(rewritten)
  text
}
