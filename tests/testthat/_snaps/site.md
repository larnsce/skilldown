# generation snapshot: basic collection

    Code
      cat(sort(x$manifest$pages), sep = "\n")
    Output
      NEWS.md
      docs/getting-started.md
      index.md
      reference/articles.md
      reference/skills.md
      skills/alpha/index.md
      skills/alpha/references/usage.md
      skills/beta/index.md

---

    Code
      cat(read_work(x, "_quarto.yml"))
    Output
      # Quarto configuration template used by skilldown::build_site().
      # $SKILLDOWN_* variables are substituted on every render (altdoc-style).
      # Power users can edit a copy of this template in the collection's
      # skilldown/ settings directory (created by skilldown_setup()).
      
      project:
        type: website
        output-dir: _site
        render:
          - index.md
          - NEWS.md
          - docs/getting-started.md
          - reference/skills.md
          - reference/articles.md
          - skills/alpha/index.md
          - skills/alpha/references/usage.md
          - skills/beta/index.md
      
      website:
        title: collection-basic
        page-navigation: true
        navbar:
          left:
          - text: Skills
            href: reference/skills.md
          - text: Articles
            href: reference/articles.md
          - text: News
            href: NEWS.md
          search: true
      
      format:
        html:
          theme: cosmo
          toc: true
          code-copy: true

---

    Code
      cat(read_work(x, "reference/skills.md"))
    Output
      ---
      title: Skills
      ---
      
      2 skills in this collection.
      
      | Skill | Description |
      |-------|-------------|
      | [alpha](../skills/alpha/index.md) | Fetches upstream data and validates it. |
      | [beta](../skills/beta/index.md) | Summarizes validated data into a short report. |

---

    Code
      cat(read_work(x, "skills/alpha/index.md"))
    Output
      ---
      title: alpha
      ---
      
      Fetches upstream data and validates it. Second sentence with more detail.
      
      | Field | Value |
      |-------|-------|
      | Name | `alpha` |
      | License | MIT |
      | Allowed tools | Read, Bash |
      | Metadata | version: 1.2.0 |
      
      ::: {.callout-note}
      This page publishes the skill body verbatim. It is the text the model executes, not a user guide.
      :::
      
      
      
      Run [the helper](scripts/run.sh) after reading the
      [usage notes](references/usage.md). See also [beta](../beta/index.md).
      
      ## Bundled files
      
      - `scripts/run.sh`
      - [`references/usage.md`](references/usage.md)

