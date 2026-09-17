test_that("rewrite_links keeps rendered pages and rewrites the rest", {
  src <- local_fixture("collection-basic")
  rendered <- c("skills/alpha/index.md", "skills/alpha/references/usage.md")
  aliases <- c("skills/beta/SKILL.md" = "skills/beta/index.md")
  text <- paste(
    "[usage](references/usage.md)",
    "[beta](../beta/SKILL.md)",
    "[helper](scripts/run.sh)",
    "[outside](https://example.org/page.md)",
    "[anchor](references/usage.md#top)",
    sep = "\n"
  )
  out <- rewrite_links(
    text,
    page_rel_dir = "skills/alpha", rendered = rendered, aliases = aliases,
    repo_url = "https://example.org/owner/repo", root = src
  )
  lines <- strsplit(out, "\n")[[1]]
  expect_equal(lines[1], "[usage](references/usage.md)")
  expect_equal(lines[2], "[beta](../beta/index.md)")
  expect_equal(
    lines[3],
    "[helper](https://example.org/owner/repo/blob/HEAD/skills/alpha/scripts/run.sh)"
  )
  expect_equal(lines[4], "[outside](https://example.org/page.md)")
  expect_equal(lines[5], "[anchor](references/usage.md#top)")
})

test_that("without a repo URL, unresolved links are left alone", {
  src <- local_fixture("collection-basic")
  out <- rewrite_links(
    "[helper](scripts/run.sh)",
    page_rel_dir = "skills/alpha", rendered = character(),
    repo_url = NA_character_, root = src
  )
  expect_equal(out, "[helper](scripts/run.sh)")
})

test_that("relative links whose target does not exist are reported, not rewritten", {
  src <- local_fixture("collection-basic")
  report <- new.env()
  report$links <- data.frame(
    file = character(), target = character(), resolved = character(),
    stringsAsFactors = FALSE
  )
  text <- paste(
    "[policy](../SECURITY.md)",
    "[gone](nope.md#section)",
    "[figure](figure.png)",
    "[escape](../../outside.md)",
    "[present](../README.md)",
    sep = "\n"
  )
  out <- rewrite_links(
    text,
    page_rel_dir = "docs", rendered = character(),
    repo_url = "https://example.org/owner/repo", root = src,
    report = report, page = "docs/getting-started.md"
  )
  lines <- strsplit(out, "\n")[[1]]
  # Left as written: there is nothing to link to.
  expect_equal(lines[1], "[policy](../SECURITY.md)")
  expect_equal(lines[2], "[gone](nope.md#section)")
  expect_equal(lines[3], "[figure](figure.png)")
  expect_equal(lines[4], "[escape](../../outside.md)")
  # An existing file still gets the blob URL.
  expect_equal(lines[5], "[present](https://example.org/owner/repo/blob/HEAD/README.md)")
  expect_equal(report$links$file, rep("docs/getting-started.md", 4))
  expect_equal(
    report$links$target,
    c("../SECURITY.md", "nope.md#section", "figure.png", "../../outside.md")
  )
  expect_equal(
    report$links$resolved,
    c("SECURITY.md", "docs/nope.md", "docs/figure.png", "../outside.md")
  )
})

test_that("rewrite_links works without a report collector", {
  src <- local_fixture("collection-basic")
  expect_equal(
    rewrite_links(
      "[policy](../SECURITY.md)",
      page_rel_dir = "docs", rendered = character(),
      repo_url = NA_character_, root = src
    ),
    "[policy](../SECURITY.md)"
  )
})
