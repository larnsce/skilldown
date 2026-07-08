# SKILL.md frontmatter parsing, validation and normalization
# (issues #3 and #6).

# Split a markdown file into frontmatter text and body lines. Returns a
# list with `yaml_text` (NULL when the file has no frontmatter fence) and
# `body` (character vector of lines).
split_frontmatter <- function(lines) {
  if (length(lines) == 0 || trimws(lines[1]) != "---") {
    return(list(yaml_text = NULL, body = lines))
  }
  closers <- which(trimws(lines[-1]) %in% c("---", "...")) + 1
  if (length(closers) == 0) {
    return(list(yaml_text = NULL, body = lines))
  }
  end <- closers[1]
  yaml_text <- paste(lines[seq(2, end - 1)], collapse = "\n")
  body <- if (end == length(lines)) character() else lines[seq(end + 1, length(lines))]
  list(yaml_text = yaml_text, body = body)
}

# Strict parse; NULL on failure (the caller falls back to the tolerant
# parser and records a normalization note).
parse_yaml_strict <- function(yaml_text) {
  tryCatch(
    yaml::yaml.load(yaml_text),
    error = function(e) NULL
  )
}

# Tolerant line-wise parser for frontmatter that Claude Code accepts but
# strict YAML rejects (the unquoted ": " case from issue #6). Handles
# top-level scalars, one level of nested maps (metadata:) and block lists.
parse_yaml_tolerant <- function(yaml_text) {
  lines <- strsplit(yaml_text, "\n", fixed = TRUE)[[1]]
  out <- list()
  key <- NULL
  key_rx <- "^([A-Za-z0-9_.-]+):[ \t]*(.*)$"

  strip_quotes <- function(x) {
    x <- trimws(x)
    if (nchar(x) >= 2 &&
        substr(x, 1, 1) %in% c('"', "'") &&
        substr(x, nchar(x), nchar(x)) == substr(x, 1, 1)) {
      x <- substr(x, 2, nchar(x) - 1)
    }
    x
  }

  for (line in lines) {
    if (grepl("^[ \t]*$", line)) next
    indented <- grepl("^[ \t]", line)
    if (!indented && grepl(key_rx, line)) {
      key <- sub(key_rx, "\\1", line)
      value <- sub(key_rx, "\\2", line)
      out[[key]] <- if (trimws(value) == "") list() else strip_quotes(value)
    } else if (indented && !is.null(key)) {
      item <- trimws(line)
      if (grepl("^-[ \t]*", item)) {
        entry <- strip_quotes(sub("^-[ \t]*", "", item))
        out[[key]] <- c(if (is.character(out[[key]])) out[[key]], entry)
      } else if (grepl(key_rx, item) && is.list(out[[key]])) {
        subkey <- sub(key_rx, "\\1", item)
        out[[key]][[subkey]] <- strip_quotes(sub(key_rx, "\\2", item))
      } else if (is.character(out[[key]])) {
        # Continuation line of a folded scalar.
        out[[key]] <- paste(out[[key]], item)
      }
    }
  }
  out
}

# The name rule from the agentskills.io specification: 1-64 characters,
# lowercase alphanumeric plus hyphens, no consecutive hyphens.
valid_skill_name <- function(name) {
  is.character(name) && length(name) == 1 && !is.na(name) &&
    nchar(name) >= 1 && nchar(name) <= 64 &&
    grepl("^[a-z0-9]+(-[a-z0-9]+)*$", name)
}

# First sentence of a description, for reference-index one-liners
# (pkgdown convention, issue #6).
first_sentence <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(trimws(x))) {
    return("")
  }
  x <- trimws(gsub("[ \t\n]+", " ", x))
  m <- regexpr("^.*?[.!?](?=[ \t]|$)", x, perl = TRUE)
  if (m > 0) {
    substr(x, 1, attr(m, "match.length"))
  } else {
    x
  }
}

# First level-one heading of a markdown body, or NA.
first_h1 <- function(body) {
  hits <- grep("^#[ \t]+", body)
  if (length(hits) == 0) {
    return(NA_character_)
  }
  trimws(sub("^#[ \t]+", "", body[hits[1]]))
}

#' Read one skill
#'
#' Parses and validates a `SKILL.md` file. Parsing is strict YAML first,
#' with a tolerant line-wise fallback for frontmatter that agent runtimes
#' accept but strict YAML rejects. Validation reports and never fails the
#' build: a skill missing its required fields is skipped with a warning,
#' everything else becomes a note (issue #3).
#'
#' @param skill_md Path to a `SKILL.md` file.
#' @param dir_name Directory name the spec requires `name` to match.
#'   Defaults to the name of the directory containing `skill_md`.
#' @return A list with `name`, `meta` (frontmatter as a list), `body`
#'   (lines), `title` (title fallback chain: frontmatter `title`, first
#'   `# h1`, skill `name`), `notes` (character vector) and `skipped`.
#' @export
read_skill <- function(skill_md, dir_name = fs::path_file(fs::path_dir(skill_md))) {
  lines <- readLines(skill_md, warn = FALSE, encoding = "UTF-8")
  parts <- split_frontmatter(lines)
  notes <- character()
  meta <- list()

  if (is.null(parts$yaml_text)) {
    notes <- c(notes, "no frontmatter found")
  } else {
    meta <- parse_yaml_strict(parts$yaml_text)
    if (is.null(meta)) {
      meta <- parse_yaml_tolerant(parts$yaml_text)
      notes <- c(notes, "frontmatter is not strict YAML; normalized in the working copy")
    }
    if (!is.list(meta)) {
      meta <- list()
      notes <- c(notes, "frontmatter could not be parsed as a mapping")
    }
  }

  name <- meta[["name"]]
  description <- meta[["description"]]
  skipped <- FALSE

  if (is.null(name) || !nzchar(trimws(as.character(name)[1]))) {
    notes <- c(notes, "required field `name` is missing; skill skipped")
    skipped <- TRUE
  } else {
    name <- as.character(name)[1]
    if (!valid_skill_name(name)) {
      notes <- c(notes, sprintf("`name` (%s) violates the spec name rule", name))
    }
    if (!identical(name, dir_name)) {
      notes <- c(notes, sprintf(
        "`name` (%s) does not match its directory name (%s)", name, dir_name
      ))
    }
  }
  if (is.null(description) || !nzchar(trimws(as.character(description)[1]))) {
    notes <- c(notes, "required field `description` is missing; skill skipped")
    skipped <- TRUE
  } else {
    description <- as.character(description)[1]
    if (nchar(description) > 1024) {
      notes <- c(notes, "`description` exceeds 1024 characters")
    }
    meta[["description"]] <- description
  }
  compat <- meta[["compatibility"]]
  if (!is.null(compat) && nchar(as.character(compat)[1]) > 500) {
    notes <- c(notes, "`compatibility` exceeds 500 characters")
  }

  title <- meta[["title"]]
  if (is.null(title) || !nzchar(trimws(as.character(title)[1]))) {
    title <- first_h1(parts$body)
  }
  if (is.na(title) || is.null(title) || !nzchar(trimws(as.character(title)[1]))) {
    title <- if (!skipped && !is.null(name)) as.character(name) else dir_name
  }

  list(
    name = if (skipped) NA_character_ else as.character(name),
    meta = meta,
    body = parts$body,
    title = as.character(title)[1],
    notes = notes,
    skipped = skipped
  )
}
