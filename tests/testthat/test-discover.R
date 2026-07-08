test_that("discovers skills/<name> layout and ignores excluded dirs", {
  src <- local_fixture("collection-basic")
  fs::dir_create(fs::path(src, "node_modules", "junk"))
  fs::file_copy(
    fs::path(src, "skills", "alpha", "SKILL.md"),
    fs::path(src, "node_modules", "junk", "SKILL.md")
  )
  found <- discover_skills(src)
  expect_equal(found$rel_dir, c("skills/alpha", "skills/beta"))
  expect_equal(found$dir_name, c("alpha", "beta"))
})

test_that("discovers category-nested layout (posit-dev shape)", {
  src <- local_fixture("collection-nested")
  found <- discover_skills(src)
  expect_equal(found$rel_dir, c("skills/data/wrangle", "skills/web/scrape"))
  expect_equal(found$dir_name, c("wrangle", "scrape"))
})

test_that("discovers a root skill (anthropics shape)", {
  src <- local_fixture("skill-root")
  found <- discover_skills(src)
  expect_equal(found$rel_dir, ".")
  expect_equal(found$dir_name, "skill-root")
})

test_that("errors on a path that is not a directory", {
  expect_error(discover_skills(tempfile()), "not a directory")
})
