# Quarto project for lecture notes + Reveal slides (one .qmd per module).
# Render locally; output is gitignored (`lectures/_built/`).
#
#   cd lectures && quarto render
#
# Add module-NN/index.qmd files to `render:` as you write them.
project:
  type: default
  output-dir: _built
  render: []

format:
  html:
    toc: true
    toc-depth: 3
    theme: cosmo
    embed-resources: true
  revealjs:
    slide-level: 2
    slide-number: true
    embed-resources: true
    preview-links: true
