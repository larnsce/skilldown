# _skilldown.yml: optional site configuration (issue #5).
#
# Zero-config first: build_site() without the file produces the site it
# always has, and every key below only overrides a default. The resolved
# values feed the $SKILLDOWN_* variables substituted into the Quarto
# template, so a power user can still edit the template itself in a
# skilldown/ settings directory (skilldown_setup()).

sd_config_keys <- c(
  "url", "title", "navbar", "reference", "articles", "news", "theme",
  "bootswatch", "exclude", "surfaces"
)

#' Site configuration: `_skilldown.yml`
#'
#' @description
#' An optional `_skilldown.yml` at the root of a skill collection overrides
#' the defaults [build_site()] uses. Without the file the defaults do all
#' the work; the file never has to exist. The keys mirror `_pkgdown.yml`
#' where they transfer.
#'
#' | Key | Effect |
#' |-----|--------|
#' | `title` | Site title. Default: the name of the collection directory. |
#' | `url` | Site URL, written as Quarto's `site-url` so the sitemap and canonical links resolve there. |
#' | `theme` | Bootswatch theme of the HTML format. Default `cosmo`. `bootswatch` is accepted as an alias. |
#' | `news` | Root-relative path of the changelog page. Default: `NEWS.md`, then `CHANGELOG.md`. |
#' | `exclude` | Globs, relative to the collection root, dropped from discovery and rendering: a skill whose directory matches, an article whose path matches. |
#' | `navbar` | `left` and `right` lists of Quarto navbar entries. An entry whose `text` matches a generated entry replaces it; any other entry is appended. |
#' | `reference` | Sections of the skills index, each with a `title`, an optional `desc` and `contents` (skill names, or globs over names and directories). A skill no section selects is listed last under "Other skills", with a validation note. |
#' | `articles` | Sections of the articles index in the same shape; `contents` match `docs/` files with or without the `docs/` prefix and the `.md` extension. |
#' | `surfaces` | Reserved for the agents, commands and plugin-manifest sections of a later version. Read and ignored for now. |
#'
#' Unknown keys are reported and ignored. A file that is not valid YAML, or
#' a key of the wrong shape, stops the build with a message naming it: the
#' configuration is the site author's own file, unlike the collection
#' content, which is only ever reported on.
#'
#' @examples
#' \dontrun{
#' # _skilldown.yml
#' # title: My skills
#' # url: https://example.org/skills
#' # theme: flatly
#' # exclude:
#' #   - skills/wip-*
#' # navbar:
#' #   right:
#' #     - text: Docs
#' #       href: https://example.org/docs
#' # reference:
#' #   - title: Core
#' #     desc: The skills to start with.
#' #     contents: [alpha, beta]
#' #   - title: Data
#' #     contents: [data-*]
#' }
#' @name skilldown_config
NULL

# Read and validate _skilldown.yml. Returns a list with one element per
# supported key (NULL, or an empty vector, when the key is unset) plus
# `file`, the path read or NA when the collection has no configuration.
read_config <- function(src) {
  file <- fs::path(src, "_skilldown.yml")
  cfg <- list()
  has_file <- fs::file_exists(file)
  if (has_file) {
    cfg <- tryCatch(
      yaml::read_yaml(file),
      error = function(e) {
        cli::cli_abort(c(
          "{.path _skilldown.yml} is not valid YAML.",
          x = conditionMessage(e)
        ))
      }
    )
    if (is.null(cfg)) cfg <- list()
    if (!is.list(cfg) || (length(cfg) > 0 && is.null(names(cfg)))) {
      cli::cli_abort("{.path _skilldown.yml} must be a mapping of keys to values.")
    }
    unknown <- setdiff(names(cfg), sd_config_keys)
    if (length(unknown) > 0) {
      cli::cli_warn(
        "Ignoring unknown {.path _skilldown.yml} key{?s}: {.val {unknown}}."
      )
    }
    cfg <- cfg[intersect(names(cfg), sd_config_keys)]
  }

  scalar <- function(key) {
    v <- cfg[[key]]
    if (is.null(v)) return(NULL)
    if (!(is.character(v) || is.numeric(v)) || length(v) != 1) {
      cli::cli_abort(
        "{.path _skilldown.yml}: {.field {key}} must be a single string."
      )
    }
    v <- trimws(as.character(v))
    if (!nzchar(v)) NULL else v
  }
  strings <- function(key) {
    v <- cfg[[key]]
    if (is.null(v)) return(character())
    v <- unlist(v)
    if (!is.character(v)) {
      cli::cli_abort("{.path _skilldown.yml}: {.field {key}} must be a list of strings.")
    }
    v[nzchar(trimws(v))]
  }
  navbar <- cfg$navbar
  if (!is.null(navbar)) {
    if (!is.list(navbar) || is.null(names(navbar)) ||
        length(setdiff(names(navbar), c("left", "right"))) > 0) {
      cli::cli_abort(
        "{.path _skilldown.yml}: {.field navbar} takes only {.field left} and {.field right} lists."
      )
    }
    for (side in names(navbar)) {
      entries <- navbar[[side]]
      ok <- is.list(entries) && all(vapply(entries, function(e) {
        is.list(entries) && is.list(e) && !is.null(names(e))
      }, logical(1)))
      if (!ok) {
        cli::cli_abort(
          "{.path _skilldown.yml}: {.field navbar.{side}} must be a list of navbar entries (mappings)."
        )
      }
    }
  }

  list(
    title = scalar("title"),
    url = scalar("url"),
    theme = sd_or(scalar("theme"), scalar("bootswatch")),
    news = scalar("news"),
    exclude = strings("exclude"),
    navbar = navbar,
    reference = read_sections(cfg$reference, "reference"),
    articles = read_sections(cfg$articles, "articles"),
    surfaces = cfg$surfaces,
    file = if (has_file) as.character(file) else NA_character_
  )
}

# Validate a `reference` or `articles` list of sections: each a mapping
# with `title`, optional `desc`, and `contents` (one string or a list).
read_sections <- function(x, key) {
  if (is.null(x)) return(NULL)
  if (!is.list(x) || !is.null(names(x)) && length(x) > 0 && !is.list(x[[1]])) {
    cli::cli_abort(
      "{.path _skilldown.yml}: {.field {key}} must be a list of sections."
    )
  }
  lapply(seq_along(x), function(i) {
    sec <- x[[i]]
    if (!is.list(sec) || is.null(sec$title) || !nzchar(trimws(as.character(sec$title)[1]))) {
      cli::cli_abort(
        "{.path _skilldown.yml}: {.field {key}} section {i} needs a {.field title}."
      )
    }
    contents <- unlist(sec$contents)
    if (is.null(contents) || !is.character(contents) || length(contents) == 0) {
      cli::cli_abort(
        "{.path _skilldown.yml}: {.field {key}} section {.val {sec$title}} needs {.field contents} (one or more names or globs)."
      )
    }
    list(
      title = as.character(sec$title)[1],
      desc = if (!is.null(sec$desc)) as.character(sec$desc)[1],
      contents = contents
    )
  })
}

# Which of `paths` match any of the shell-style `globs`. A glob without a
# wildcard matches exactly; a trailing `*` matches everything below.
sd_excluded <- function(paths, globs) {
  if (length(paths) == 0 || length(globs) == 0) {
    return(rep(FALSE, length(paths)))
  }
  rx <- vapply(sub("/+$", "", globs), utils::glob2rx, character(1))
  vapply(paths, function(p) {
    any(vapply(rx, function(r) grepl(r, p), logical(1)))
  }, logical(1), USE.NAMES = FALSE)
}

# Which items match any of `patterns`, given several spellings per item
# (`forms`, a list of equal-length character vectors: for a skill its
# name and its directory, for an article its path with and without the
# `docs/` prefix and extension).
sd_select <- function(patterns, forms) {
  n <- length(forms[[1]])
  if (n == 0) return(logical())
  rx <- vapply(patterns, utils::glob2rx, character(1))
  vapply(seq_len(n), function(i) {
    spellings <- vapply(forms, `[[`, character(1), i)
    any(vapply(rx, function(r) any(grepl(r, spellings)), logical(1)))
  }, logical(1))
}

# Merge user navbar entries into the generated ones for one side: an
# entry whose `text` matches a generated entry replaces it, the rest are
# appended in order.
sd_merge_navbar <- function(generated, user) {
  if (is.null(user)) return(generated)
  for (entry in user) {
    text <- entry$text
    idx <- if (is.null(text)) integer() else {
      which(vapply(generated, function(g) identical(g$text, text), logical(1)))
    }
    if (length(idx) > 0) {
      generated[[idx[1]]] <- entry
    } else {
      generated <- c(generated, list(entry))
    }
  }
  generated
}

# A sectioned index: for each section a level-two heading, the optional
# description, and the rows it selects (`rows` are ready-made markdown
# lines, one per item). Every item lands in the first section that
# selects it; the leftovers go under `other_title`. Returns the lines and
# the leftover indices (for the validation note).
sd_sectioned <- function(sections, selected, rows, header, other_title) {
  lines <- character()
  assigned <- rep(FALSE, length(rows))
  for (i in seq_along(sections)) {
    sec <- sections[[i]]
    sel <- selected[[i]] & !assigned
    assigned <- assigned | sel
    lines <- c(
      lines, if (length(lines) > 0) "", sprintf("## %s", sec$title),
      if (!is.null(sec$desc)) c("", sec$desc),
      "", header, rows[sel]
    )
  }
  leftover <- which(!assigned)
  if (length(leftover) > 0) {
    lines <- c(lines, "", sprintf("## %s", other_title), "", header, rows[leftover])
  }
  list(lines = lines, leftover = leftover)
}
