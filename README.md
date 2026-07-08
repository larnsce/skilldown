# skilldown

Generate a documentation website for a collection of AI agent skills,
the way [pkgdown](https://pkgdown.r-lib.org) does for R packages.

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

## Status: v0.1 pipeline working (dev branch)

The end-to-end pipeline is implemented: discovery and spec validation,
tolerant frontmatter normalization, site generation and rendering, and
the publish workflow helper. The v0.1 acceptance run renders
larnsce/llm-wiki (48 pages) with zero broken links introduced by
generation; the operationalized comparison lives in
`dev/parity-checklist.md`. The design is recorded as issues; start at
the [roadmap issue](https://github.com/larnsce/skilldown/issues) for
scope and sequencing.

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

Requires the Quarto command line tool. If it is not on the PATH, point
the `QUARTO_PATH` environment variable at a bundled binary (RStudio
ships one under `Contents/Resources/app/quarto/bin/quarto`). The prior art the design leans on: pkgdown's API and
site structure, [altdoc](https://altdoc.etiennebacher.com)'s
architecture for driving external generators from R, the
[quarto](https://quarto-dev.github.io/quarto-r/) R package as the CLI
bridge, and a hand-built prototype of the target output at
[larnsce/llm-wiki](https://github.com/larnsce/llm-wiki) (a Quarto site
over an eleven-skill collection).
