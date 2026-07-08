test_that("strict frontmatter parses without notes", {
  src <- local_fixture("collection-basic")
  skill <- read_skill(fs::path(src, "skills", "alpha", "SKILL.md"))
  expect_equal(skill$name, "alpha")
  expect_equal(skill$title, "alpha")
  expect_equal(skill$meta$metadata$version, "1.2.0")
  expect_equal(skill$notes, character())
  expect_false(skill$skipped)
})

test_that("unquoted colon falls back to the tolerant parser", {
  src <- local_fixture("collection-messy")
  skill <- read_skill(fs::path(src, "skills", "colon-notes", "SKILL.md"))
  expect_false(skill$skipped)
  expect_equal(skill$name, "colon-notes")
  expect_equal(
    skill$meta$description,
    "Collect notes: fetch, sort: then file them by topic."
  )
  expect_match(skill$notes, "not strict YAML", all = FALSE)
})

test_that("name/directory mismatch is reported, not fatal", {
  src <- local_fixture("collection-messy")
  skill <- read_skill(fs::path(src, "skills", "mismatch", "SKILL.md"))
  expect_false(skill$skipped)
  expect_match(skill$notes, "does not match its directory", all = FALSE)
})

test_that("missing frontmatter skips the skill with notes", {
  src <- local_fixture("collection-messy")
  skill <- read_skill(fs::path(src, "skills", "bare", "SKILL.md"))
  expect_true(skill$skipped)
  expect_match(skill$notes, "no frontmatter", all = FALSE)
  expect_match(skill$notes, "`name` is missing", all = FALSE)
  # Title still falls back to the first h1.
  expect_equal(skill$title, "bare")
})

test_that("the spec name rule is enforced", {
  expect_true(valid_skill_name("alpha-two"))
  expect_false(valid_skill_name("Alpha"))
  expect_false(valid_skill_name("a--b"))
  expect_false(valid_skill_name("-a"))
  expect_false(valid_skill_name(strrep("a", 65)))
})

test_that("first_sentence trims to the pkgdown one-liner", {
  expect_equal(
    first_sentence("Fetches data. Second sentence."),
    "Fetches data."
  )
  expect_equal(first_sentence("No terminal period"), "No terminal period")
  expect_equal(first_sentence(NULL), "")
})
