# generation applies the configuration

    Code
      cat(config)
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
          - HISTORY.md
          - docs/advanced.md
          - docs/getting-started.md
          - reference/skills.md
          - reference/articles.md
          - skills/alpha/index.md
          - skills/alpha/references/usage.md
          - skills/beta/index.md
          - skills/delta/index.md
      
      website:
        title: Configured Collection
        site-url: https://example.org/configured
        page-navigation: true
        navbar:
          left:
          - text: Skills
            href: reference/skills.md
          - text: Articles
            href: reference/articles.md
          - text: News
            href: HISTORY.md
            icon: bi-clock-history
          right:
          - text: Docs
            href: https://example.org/docs
          search: true
      
      format:
        html:
          theme: flatly
          toc: true
          code-copy: true

---

    Code
      cat(read_work(x, "reference/skills.md"))
    Output
      ---
      title: Skills
      ---
      
      3 skills in this collection.
      
      ## Core
      
      The skills to start with.
      
      | Skill | Description |
      |-------|-------------|
      | [alpha](../skills/alpha/index.md) | Fetches upstream data and validates it. |
      
      ## Reporting
      
      | Skill | Description |
      |-------|-------------|
      | [beta](../skills/beta/index.md) | Summarizes validated data into a short report. |
      
      ## Other skills
      
      | Skill | Description |
      |-------|-------------|
      | [delta](../skills/delta/index.md) | Listed by no reference section. |

---

    Code
      cat(read_work(x, "reference/articles.md"))
    Output
      ---
      title: Articles
      ---
      
      ## Start here
      
      - [Getting started](../docs/getting-started.md)
      
      ## Other articles
      
      - [Advanced use](../docs/advanced.md)

