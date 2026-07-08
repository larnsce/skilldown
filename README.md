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

## Status: design phase

Nothing is implemented yet. The design was researched first and is
recorded as issues; start at the
[roadmap issue](https://github.com/larnsce/skilldown/issues) for scope
and sequencing. The prior art the design leans on: pkgdown's API and
site structure, [altdoc](https://altdoc.etiennebacher.com)'s
architecture for driving external generators from R, the
[quarto](https://quarto-dev.github.io/quarto-r/) R package as the CLI
bridge, and a hand-built prototype of the target output at
[larnsce/llm-wiki](https://github.com/larnsce/llm-wiki) (a Quarto site
over an eleven-skill collection).
