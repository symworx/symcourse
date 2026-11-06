# Fill gaps after Debian r-cran-* packages. Skip anything already installed.
need <- c(
  "ggplot2",
  "dplyr",
  "tidyr",
  "readr",
  "tibble",
  "plotly",
  "patchwork",
  "scales",
  "viridis",
  "ggrepel",
  "knitr",
  "rmarkdown",
  "palmerpenguins",
  "gapminder",
  "IRkernel"
)
inst <- rownames(installed.packages())
todo <- setdiff(need, inst)
if (length(todo) > 0) {
  install.packages(todo, repos = "https://cloud.r-project.org", Ncpus = max(1L, parallel::detectCores() - 1L))
}
if (requireNamespace("IRkernel", quietly = TRUE) && nzchar(Sys.which("jupyter"))) {
  IRkernel::installspec(user = FALSE)
}
