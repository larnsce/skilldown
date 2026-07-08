# v0.1 parity checklist: skilldown output vs the hand-built llm-wiki site

Operationalizes "parity" for the v0.1 acceptance test (issue #4, as
amended by the premortem on 2026-07-08). Target: larnsce/llm-wiki,
hand-built site at commit 11825b9 (_quarto.yml plus
tools/build_doc_indexes.py). Verified 2026-07-08 against a local
`build_site()` run: 48 pages, 0 normalization notes, 583 internal links
checked.

## Checklist

- [x] Every skill with a SKILL.md gets a page: 10/10 discovered and
  rendered (wiki-core has no SKILL.md; the hand-built site renders no
  page for it either).
- [x] Skills reference index lists every skill with a first-sentence
  description and links to its page.
- [x] Home page renders (llm-wiki's own index.md; README.md is the
  fallback when no index.md exists).
- [x] Articles: all docs/*.md render, with a generated articles index.
- [x] News: CHANGELOG.md renders and is linked from the navbar
  (NEWS.md preferred when both exist).
- [x] Bundled references render as pages: skills/*/references/*.md,
  including the shared wiki-core/references/ pages that skill bodies
  link to (sibling-resource rule).
- [x] Navbar: Skills / Articles / News, search, GitHub icon,
  repo-actions (source, issue), page-navigation, cosmo theme.
- [x] Link resolution: SKILL.md links redirect to generated pages;
  links to non-rendered files (openspec/specs, prompts, scripts)
  rewrite to repository blob URLs; zero broken internal links
  introduced by generation. One pre-existing broken link
  (docs/faq.md -> ../SECURITY.md, file absent from the repo) is broken
  on the hand-built site too; fix upstream in llm-wiki.
- [x] Sources untouched: generation happens in .skilldown/site; the
  collection tree stays clean.

## Accepted differences (recorded on issue #4)

- Specs section (openspec/specs/*.md and its index): llm-wiki-specific
  content outside the v0.1 site model. Links to specs resolve to blob
  URLs, not 404s. Revisit with the v0.2 surfaces.
- Agents section (agents/*.md and its index): a v0.2 surface per
  issue #8.
- CONTRIBUTING.md page: not part of the v0.1 site model; links to it
  rewrite to the blob URL.
- site-url / sitemap: needs the _skilldown.yml config surface (v0.2,
  issue #5).

## Open items for the maintainer (premortem revised plan)

- Value test before announcing anything: check traffic on the
  hand-built site, watch whether you send collaborators to the site or
  the repo, ask 3 skill authors what a site would give them over
  GitHub rendering. Write the answer into the README.
- Retirement of the hand-built llm-wiki setup happens one release
  cycle after parity, not now (amendment on issue #8).
