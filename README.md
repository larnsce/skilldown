# skilldown

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Generate a documentation website for a collection of AI agent skills,
the way [pkgdown](https://pkgdown.r-lib.org) does for R packages.

> [!WARNING]
> **Experimental. Not intended for general use.** This package is an
> experiment, coded end to end by [Claude](https://www.anthropic.com/claude-code)
> under my direction. The idea: skill collections today ship a README and
> nothing else, and no tool introspects a collection to render a browsable
> reference site the way pkgdown does for R packages. skilldown explores
> whether that gap is worth filling. The API, the output, and the internals
> may change or break without notice, and nothing here is production ready.
> If the idea interests you, or you have thoughts on where it should go,
> [opening an issue](https://github.com/larnsce/skilldown/issues) is very
> welcome.

Agent skills (the [agentskills.io](https://agentskills.io/specification)
open standard, used by Claude Code and other agents) are directories
with a `SKILL.md` carrying YAML frontmatter (`name`, `description`) and
a markdown body, often shipped in collections alongside supporting
scripts, reference docs, subagents, and slash commands. Skill
collections today publish a README and nothing else; no tool introspects
the collection and renders a browsable reference site. skilldown is that
tool: an R package that reads a skill repo, generates a
[Quarto](https://quarto.org) website configuration around it (Home from
the README, a Skills reference index from the frontmatter, Articles from
`docs/`, News from the changelog), and drives Quarto to render and
publish it.

## Status: early proof of concept (dev branch)

An end-to-end pipeline runs at the proof-of-concept level: discovery and
spec validation, tolerant frontmatter normalization, site generation and
rendering, and the publish workflow helper. As one exploratory check, the
pipeline rendered larnsce/llm-wiki (48 pages) without introducing broken
links; the comparison it was measured against lives in
`dev/parity-checklist.md`. Treat all of this as provisional and subject to
change. The design so far is recorded as issues; start at the
[roadmap issue](https://github.com/larnsce/skilldown/issues) for scope and
current thinking.

## Usage

```r
# install.packages("pak")
pak::pak("larnsce/skilldown")

skilldown::build_site("path/to/skill-collection")
skilldown::preview_site("path/to/skill-collection")

# optional, run once:
skilldown::skilldown_setup()            # editable site template
skilldown::use_skilldown_github_pages() # publish workflow
```

### Configuration

`build_site()` needs no configuration. An optional `_skilldown.yml` at
the root of the collection overrides the defaults, with keys that mirror
`_pkgdown.yml` where they transfer: `title`, `url` (Quarto's `site-url`),
`theme` (or `bootswatch`), `news` (the changelog page), `exclude` (globs
dropped from discovery and rendering), `navbar` (`left` and `right`
entries added to, or replacing, the generated ones), and `reference` and
`articles` (sections of the two index pages, each with a `title`, an
optional `desc` and `contents` selectors). See `?skilldown_config` for
the schema.

```yaml
title: My skills
url: https://example.org/skills
theme: flatly
exclude:
  - skills/wip-*
reference:
  - title: Core
    desc: The skills to start with.
    contents: [alpha, beta]
  - title: Data
    contents: [data-*]
```

Requires the Quarto command line tool. If it is not on the PATH, point
the `QUARTO_PATH` environment variable at a bundled binary (RStudio
ships one under `Contents/Resources/app/quarto/bin/quarto`). The prior art the design leans on: pkgdown's API and
site structure, [altdoc](https://altdoc.etiennebacher.com)'s
architecture for driving external generators from R, the
[quarto](https://quarto-dev.github.io/quarto-r/) R package as the CLI
bridge, and a hand-built prototype of the target output at
[larnsce/llm-wiki](https://github.com/larnsce/llm-wiki) (a Quarto site
over an eleven-skill collection).
