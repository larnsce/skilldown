# Site generation: from a discovered collection to a renderable Quarto
# working directory (issues #2, #4, #6).

sd_theme_default <- "cosmo"

# Read and validate every skill in the collection. Returns a list with
# `skills` (kept) and `notes` (data.frame file/note across all, including
# skipped ones).
read_collection <- function(src) {
  found <- discover_skills(src)
  skills <- list()
  notes <- data.frame(file = character(), note = character())
  for (i in seq_len(nrow(found))) {
    row <- found[i, ]
    skill <- read_skill(row$skill_md, dir_name = row$dir_name)
    skill$rel_dir <- row$rel_dir
    skill$dir <- row$dir
    rel_md <- as.character(fs::path_rel(row$skill_md, src))
    if (length(skill$notes) > 0) {
      notes <- rbind(notes, data.frame(file = rel_md, note = skill$notes))
    }
    if (skill$skipped) {
      cli::cli_warn("Skipping {.path {rel_md}}: {skill$notes}")
    } else {
      skills[[length(skills) + 1]] <- skill
    }
  }
  list(skills = skills, notes = notes)
}

# Root-relative path of the generated page for a skill.
skill_page_path <- function(skill) {
  if (skill$rel_dir == ".") "skill.md" else fs::path(skill$rel_dir, "index.md")
}

# Root-relative markdown files bundled with a skill, split into pages
# that render (references/*.md) and plain files.
skill_bundled <- function(skill, src) {
  bundled <- character()
  for (sub in c("scripts", "references", "assets")) {
    d <- fs::path(skill$dir, sub)
    if (fs::dir_exists(d)) {
      files <- fs::dir_ls(d, type = "file", recurse = TRUE)
      bundled <- c(bundled, as.character(fs::path_rel(files, src)))
    }
  }
  bundled
}

# Escape pipes so a value survives inside a markdown table cell.
cell <- function(x) {
  gsub("|", "\\|", gsub("\n", " ", x), fixed = TRUE)
}

# Generate the markdown page for one skill: description, frontmatter
# table, the SKILL.md body verbatim, and the bundled-file listing
# (issue #4).
render_skill_page <- function(skill, src, rendered, aliases, repo_url,
                              report = NULL) {
  meta <- skill$meta
  page_dir <- if (skill$rel_dir == ".") "." else skill$rel_dir
  skill_md <- as.character(fs::path_rel(fs::path(skill$dir, "SKILL.md"), src))

  fields <- c(
    Name = sprintf("`%s`", skill$name),
    License = if (!is.null(meta$license)) cell(as.character(meta$license)[1]),
    Compatibility = if (!is.null(meta$compatibility)) cell(as.character(meta$compatibility)[1]),
    `Allowed tools` = if (!is.null(meta[["allowed-tools"]])) {
      cell(paste(unlist(meta[["allowed-tools"]]), collapse = ", "))
    }
  )
  if (is.list(meta$metadata) && length(meta$metadata) > 0) {
    fields <- c(fields, Metadata = cell(paste(
      sprintf("%s: %s", names(meta$metadata), vapply(meta$metadata, function(v) {
        paste(as.character(unlist(v)), collapse = ", ")
      }, character(1))),
      collapse = "; "
    )))
  }
  fields <- fields[!vapply(fields, is.null, logical(1))]
  table_md <- c(
    "| Field | Value |",
    "|-------|-------|",
    sprintf("| %s | %s |", names(fields), unlist(fields))
  )

  body <- skill$body
  # Drop a leading h1 that repeats the page title; the words stay on the
  # page via the title block, and the source file is never touched.
  nonblank <- which(nzchar(trimws(body)))
  if (length(nonblank) > 0) {
    first <- nonblank[1]
    if (grepl("^#[ \t]+", body[first]) &&
        identical(trimws(sub("^#[ \t]+", "", body[first])), skill$title)) {
      body <- body[-first]
    }
  }
  body_text <- rewrite_links(
    paste(body, collapse = "\n"),
    page_rel_dir = page_dir, rendered = rendered, aliases = aliases,
    repo_url = repo_url, root = src, report = report, page = skill_md
  )

  bundled <- skill_bundled(skill, src)
  bundled_md <- character()
  if (length(bundled) > 0) {
    items <- vapply(bundled, function(f) {
      rel_to_page <- as.character(fs::path_rel(f, page_dir))
      if (f %in% rendered) {
        sprintf("- [`%s`](%s)", rel_to_page, rel_to_page)
      } else if (!is.na(repo_url)) {
        sprintf("- [`%s`](%s)", rel_to_page, blob_url(repo_url, f))
      } else {
        sprintf("- `%s`", rel_to_page)
      }
    }, character(1), USE.NAMES = FALSE)
    bundled_md <- c("", "## Bundled files", "", items)
  }

  c(
    "---",
    sd_yaml(list(title = skill$title)),
    "---",
    "",
    as.character(meta$description),
    "",
    table_md,
    "",
    "::: {.callout-note}",
    paste(
      "This page publishes the skill body verbatim.",
      "It is the text the model executes, not a user guide."
    ),
    ":::",
    "",
    body_text,
    bundled_md
  )
}

# Copy a markdown page into the working directory, normalizing its
# frontmatter to strict YAML and applying the title fallback chain and
# link rewriting (issue #6). Returns TRUE when normalization changed the
# frontmatter. `report` collects missing link targets (issue #11); the
# page is reported under its root-relative source path.
normalize_page <- function(src_file, work_file, page_rel_dir, rendered,
                           aliases, repo_url, root, fallback_title,
                           report = NULL) {
  lines <- readLines(src_file, warn = FALSE, encoding = "UTF-8")
  parts <- split_frontmatter(lines)
  normalized <- FALSE
  meta <- list()
  if (!is.null(parts$yaml_text)) {
    meta <- parse_yaml_strict(parts$yaml_text)
    if (is.null(meta)) {
      meta <- parse_yaml_tolerant(parts$yaml_text)
      normalized <- TRUE
    }
    if (!is.list(meta)) meta <- list()
  }
  has_title <- !is.null(meta$title) && nzchar(trimws(as.character(meta$title)[1]))
  if (!has_title && is.na(first_h1(parts$body))) {
    meta$title <- fallback_title
    normalized <- TRUE
  }
  body <- rewrite_links(
    paste(parts$body, collapse = "\n"),
    page_rel_dir = page_rel_dir, rendered = rendered, aliases = aliases,
    repo_url = repo_url, root = root, report = report,
    page = as.character(fs::path_rel(src_file, root))
  )
  out <- if (length(meta) > 0) {
    c("---", sd_yaml(meta), "---", "", body)
  } else {
    body
  }
  fs::dir_create(fs::path_dir(work_file))
  writeLines(out, work_file, useBytes = TRUE)
  normalized
}

# Title of a markdown file for index listings: frontmatter title, first
# h1, then the file name.
page_title <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  parts <- split_frontmatter(lines)
  if (!is.null(parts$yaml_text)) {
    meta <- parse_yaml_strict(parts$yaml_text)
    if (is.null(meta)) meta <- parse_yaml_tolerant(parts$yaml_text)
    if (is.list(meta) && !is.null(meta$title) && nzchar(as.character(meta$title)[1])) {
      return(as.character(meta$title)[1])
    }
  }
  h1 <- first_h1(parts$body)
  if (!is.na(h1)) h1 else fs::path_ext_remove(fs::path_file(file))
}

#' Generate the Quarto working directory for a collection
#'
#' Builds the renderable tree for [build_site()]: home page, skills
#' reference index and per-skill pages, articles from `docs/`, news from
#' `NEWS.md` or `CHANGELOG.md`, and a generated `_quarto.yml`. The source
#' collection is never modified; all normalization happens in the working
#' copy.
#'
#' @param src Path to the skill collection.
#' @param work Path of the working directory to (re)generate.
#' @return Invisibly, a manifest list: `pages` (root-relative rendered
#'   paths), `skills`, `notes` (normalization and validation report),
#'   `broken_links` (relative links whose target does not exist in the
#'   source tree, one row per link with `file`, `target` and `resolved`)
#'   and `title`.
#' @export
generate_site <- function(src, work = fs::path(src, ".skilldown", "site")) {
  src <- fs::path_abs(src)
  work <- fs::path_abs(work)
  if (fs::dir_exists(work)) fs::dir_delete(work)
  fs::dir_create(work)

  collection <- read_collection(src)
  skills <- collection$skills
  notes <- collection$notes
  repo_url <- repo_browse_url(src)
  title <- fs::path_file(src)
  # Missing link targets, collected across every rewritten page
  # (issue #11).
  report <- new.env(parent = emptyenv())
  report$links <- data.frame(
    file = character(), target = character(), resolved = character(),
    stringsAsFactors = FALSE
  )

  # --- what will exist as rendered pages (root-relative), and how
  # SKILL.md links map onto generated pages
  pages <- character()
  aliases <- character()
  home_src <- NULL
  for (cand in c("index.md", "README.md")) {
    if (fs::file_exists(fs::path(src, cand))) {
      home_src <- cand
      break
    }
  }
  pages <- c(pages, "index.md")
  if (identical(home_src, "README.md")) {
    aliases["README.md"] <- "index.md"
  }
  news_file <- NULL
  for (cand in c("NEWS.md", "CHANGELOG.md")) {
    if (fs::file_exists(fs::path(src, cand))) {
      news_file <- cand
      break
    }
  }
  if (!is.null(news_file)) pages <- c(pages, news_file)

  articles <- character()
  if (fs::dir_exists(fs::path(src, "docs"))) {
    articles <- as.character(fs::path_rel(
      fs::dir_ls(fs::path(src, "docs"), type = "file", glob = "*.md"),
      src
    ))
    pages <- c(pages, articles)
  }

  skill_pages <- vapply(skills, function(s) as.character(skill_page_path(s)), character(1))
  pages <- c(pages, "reference/skills.md", if (length(articles) > 0) "reference/articles.md")
  reference_pages <- list()
  for (i in seq_along(skills)) {
    s <- skills[[i]]
    pages <- c(pages, skill_pages[i])
    aliases[as.character(fs::path_rel(fs::path(s$dir, "SKILL.md"), src))] <- skill_pages[i]
    refs <- skill_bundled(s, src)
    refs <- refs[grepl("(^|/)references/", refs) & fs::path_ext(refs) == "md"]
    reference_pages[[i]] <- refs
    pages <- c(pages, refs)
  }

  # Shared-conventions directories: a directory that sits next to
  # discovered skills, has no SKILL.md of its own, but carries
  # references/*.md that skill bodies link to (the wiki-core pattern in
  # larnsce/llm-wiki). Its reference pages are rendered so those links
  # resolve as pages rather than blob URLs.
  shared_dirs <- character()
  skill_parents <- unique(vapply(
    skills[vapply(skills, function(s) s$rel_dir != ".", logical(1))],
    function(s) as.character(fs::path_dir(s$dir)), character(1)
  ))
  for (parent in skill_parents) {
    siblings <- fs::dir_ls(parent, type = "directory")
    for (sib in siblings) {
      rel_sib <- as.character(fs::path_rel(sib, src))
      if (rel_sib %in% vapply(skills, `[[`, character(1), "rel_dir")) next
      refs_dir <- fs::path(sib, "references")
      if (fs::dir_exists(refs_dir)) {
        refs <- as.character(fs::path_rel(
          fs::dir_ls(refs_dir, type = "file", glob = "*.md", recurse = TRUE), src
        ))
        if (length(refs) > 0) {
          shared_dirs <- c(shared_dirs, rel_sib)
          pages <- c(pages, refs)
        }
      }
    }
  }
  pages <- unique(pages)

  n_normalized <- 0L

  # --- home
  if (!is.null(home_src)) {
    n_normalized <- n_normalized + normalize_page(
      fs::path(src, home_src), fs::path(work, "index.md"),
      page_rel_dir = ".", rendered = pages, aliases = aliases,
      repo_url = repo_url, root = src, fallback_title = title,
      report = report
    )
  } else {
    writeLines(c("---", sprintf("title: %s", title), "---"), fs::path(work, "index.md"))
  }

  # --- news and articles
  for (f in c(news_file, articles)) {
    if (is.null(f)) next
    n_normalized <- n_normalized + normalize_page(
      fs::path(src, f), fs::path(work, f),
      page_rel_dir = as.character(fs::path_dir(f)), rendered = pages,
      aliases = aliases, repo_url = repo_url, root = src,
      fallback_title = fs::path_ext_remove(fs::path_file(f)),
      report = report
    )
  }

  # --- skills: copy each skill directory, then write the generated page
  for (i in seq_along(skills)) {
    s <- skills[[i]]
    dest_dir <- if (s$rel_dir == ".") work else fs::path(work, s$rel_dir)
    if (s$rel_dir != ".") {
      fs::dir_create(fs::path_dir(dest_dir))
      fs::dir_copy(s$dir, dest_dir)
    } else {
      # A root skill: copy only its bundled subdirectories, never the
      # whole repository, into the working directory.
      for (sub in c("scripts", "references", "assets")) {
        if (fs::dir_exists(fs::path(s$dir, sub))) {
          fs::dir_copy(fs::path(s$dir, sub), fs::path(work, sub))
        }
      }
    }
    page <- render_skill_page(s, src, rendered = pages, aliases = aliases,
                              repo_url = repo_url, report = report)
    writeLines(page, fs::path(work, skill_pages[i]), useBytes = TRUE)
    # Normalize the frontmatter of rendered reference pages in place.
    for (ref in reference_pages[[i]]) {
      n_normalized <- n_normalized + normalize_page(
        fs::path(src, ref), fs::path(work, ref),
        page_rel_dir = as.character(fs::path_dir(ref)), rendered = pages,
        aliases = aliases, repo_url = repo_url, root = src,
        fallback_title = fs::path_ext_remove(fs::path_file(ref)),
        report = report
      )
    }
  }

  # --- shared-conventions directories (the wiki-core pattern)
  for (rel_sib in shared_dirs) {
    dest_dir <- fs::path(work, rel_sib)
    if (!fs::dir_exists(dest_dir)) {
      fs::dir_create(fs::path_dir(dest_dir))
      fs::dir_copy(fs::path(src, rel_sib), dest_dir)
    }
    refs <- pages[startsWith(pages, paste0(rel_sib, "/references/"))]
    for (ref in refs) {
      n_normalized <- n_normalized + normalize_page(
        fs::path(src, ref), fs::path(work, ref),
        page_rel_dir = as.character(fs::path_dir(ref)), rendered = pages,
        aliases = aliases, repo_url = repo_url, root = src,
        fallback_title = fs::path_ext_remove(fs::path_file(ref)),
        report = report
      )
    }
  }

  # --- reference indexes
  fs::dir_create(fs::path(work, "reference"))
  index_rows <- vapply(seq_along(skills), function(i) {
    s <- skills[[i]]
    link <- as.character(fs::path_rel(skill_pages[i], "reference"))
    sprintf(
      "| [%s](%s) | %s |",
      s$name, link, cell(first_sentence(s$meta$description))
    )
  }, character(1))
  writeLines(c(
    "---", "title: Skills", "---", "",
    sprintf("%d skills in this collection.", length(skills)), "",
    "| Skill | Description |",
    "|-------|-------------|",
    index_rows
  ), fs::path(work, "reference", "skills.md"), useBytes = TRUE)

  if (length(articles) > 0) {
    article_rows <- vapply(articles, function(f) {
      sprintf(
        "- [%s](%s)",
        page_title(fs::path(src, f)),
        as.character(fs::path_rel(f, "reference"))
      )
    }, character(1), USE.NAMES = FALSE)
    writeLines(c(
      "---", "title: Articles", "---", "", article_rows
    ), fs::path(work, "reference", "articles.md"), useBytes = TRUE)
  }

  # --- _quarto.yml from the template
  template_file <- fs::path(src, "skilldown", "_quarto.yml")
  if (!fs::file_exists(template_file)) {
    template_file <- system.file("templates", "_quarto.yml", package = "skilldown")
  }
  template <- readLines(template_file, warn = FALSE)

  navbar_left <- list(list(text = "Skills", href = "reference/skills.md"))
  if (length(articles) > 0) {
    navbar_left <- c(navbar_left, list(list(text = "Articles", href = "reference/articles.md")))
  }
  if (!is.null(news_file)) {
    navbar_left <- c(navbar_left, list(list(text = "News", href = news_file)))
  }
  website <- list(
    title = title,
    `page-navigation` = TRUE,
    navbar = c(
      list(left = navbar_left),
      if (!is.na(repo_url)) list(right = list(list(icon = "github", href = repo_url))),
      list(search = TRUE)
    )
  )
  if (!is.na(repo_url)) {
    website$`repo-url` <- repo_url
    website$`repo-actions` <- list("source", "issue")
  }
  website_yaml <- sd_yaml(list(website = website))

  config <- paste(template, collapse = "\n")
  config <- sub("$SKILLDOWN_RENDER",
                paste(sprintf("    - %s", pages), collapse = "\n"),
                config, fixed = TRUE)
  config <- sub("$SKILLDOWN_WEBSITE", website_yaml, config, fixed = TRUE)
  config <- sub("$SKILLDOWN_THEME", sd_theme_default, config, fixed = TRUE)
  writeLines(config, fs::path(work, "_quarto.yml"), useBytes = TRUE)

  invisible(list(
    pages = pages,
    skills = vapply(skills, `[[`, character(1), "name"),
    notes = notes,
    broken_links = report$links,
    n_normalized = n_normalized,
    title = title,
    work = as.character(work)
  ))
}
