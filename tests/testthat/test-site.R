generate_fixture <- function(name, env = parent.frame()) {
  src <- local_fixture(name, env = env)
  work <- fs::path(withr::local_tempdir(.local_envir = env), "site")
  manifest <- suppressWarnings(generate_site(src, work = work))
  list(src = src, work = work, manifest = manifest)
}

read_work <- function(x, rel) {
  paste(readLines(fs::path(x$work, rel), warn = FALSE), collapse = "\n")
}

test_that("generation snapshot: basic collection", {
  x <- generate_fixture("collection-basic")
  expect_snapshot(cat(sort(x$manifest$pages), sep = "\n"))
  expect_snapshot(cat(read_work(x, "_quarto.yml")))
  expect_snapshot(cat(read_work(x, "reference/skills.md")))
  expect_snapshot(cat(read_work(x, "skills/alpha/index.md")))
})

test_that("home falls back to README and links to it resolve home", {
  x <- generate_fixture("collection-basic")
  home <- read_work(x, "index.md")
  expect_match(home, "A tidy little skill collection", fixed = TRUE)
  # README.md link on the getting-started page must not 404; CONTRIBUTING
  # is not rendered and has no repo URL here, so it stays as-is.
  expect_true(fs::file_exists(fs::path(x$work, "docs", "getting-started.md")))
})

test_that("messy collection: reported, normalized, never fatal", {
  x <- generate_fixture("collection-messy")
  expect_setequal(x$manifest$skills, c("colon-notes", "other-name"))
  expect_true(any(grepl("not strict YAML", x$manifest$notes$note)))
  expect_true(any(grepl("does not match its directory", x$manifest$notes$note)))
  expect_true(any(grepl("skill skipped", x$manifest$notes$note)))
  # The bare skill produced no page.
  expect_false(fs::file_exists(fs::path(x$work, "skills", "bare", "index.md")))
  # The colon description survived normalization intact.
  page <- read_work(x, "skills/colon-notes/index.md")
  expect_match(page, "Collect notes: fetch, sort: then file them by topic.", fixed = TRUE)
})

test_that("nested layout renders one page per skill (flat index in v0.1)", {
  x <- generate_fixture("collection-nested")
  expect_true(fs::file_exists(fs::path(x$work, "skills/data/wrangle/index.md")))
  expect_true(fs::file_exists(fs::path(x$work, "skills/web/scrape/index.md")))
  index <- read_work(x, "reference/skills.md")
  expect_match(index, "wrangle", fixed = TRUE)
  expect_match(index, "scrape", fixed = TRUE)
})

test_that("root skill renders to skill.md next to the home page", {
  x <- generate_fixture("skill-root")
  expect_true("skill.md" %in% x$manifest$pages)
  expect_true(fs::file_exists(fs::path(x$work, "skill.md")))
  expect_true(fs::file_exists(fs::path(x$work, "references", "notes.md")))
  index <- read_work(x, "reference/skills.md")
  expect_match(index, "](../skill.md)", fixed = TRUE)
})

test_that("build_site renders end to end", {
  skip_if_no_quarto()
  src <- local_fixture("collection-basic")
  manifest <- build_site(src, quiet = TRUE)
  expect_true(fs::file_exists(fs::path(src, "_site", "index.html")))
  expect_true(fs::file_exists(fs::path(src, "_site", "skills", "alpha", "index.html")))
  expect_true(fs::file_exists(fs::path(src, "_site", "reference", "skills.html")))
  expect_gt(length(manifest$pages), 5)
})
