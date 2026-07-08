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
