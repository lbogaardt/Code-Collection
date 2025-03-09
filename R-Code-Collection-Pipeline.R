library(xfun)
library(rmarkdown)
library(tidyverse)

rmarkdown.documents <- tibble(
  file.path = list.files(
    path = "R-Code-Collection",
    pattern = "\\.Rmd?$",
    full.names = TRUE
  )
) %>%
  group_by(file.path) %>%
  mutate(
    directory.name = dirname(file.path),
    file.name = basename(file.path),
    source.code = paste(readLines(file.path, warn = FALSE), collapse = "\n")
  ) %>%
  ungroup()
rmarkdown.documents

packages.per.file <- rmarkdown.documents %>%
  group_by(file.name) %>%
  reframe(packages = gsub("library\\(\"?([^\\)]*?)\"?\\)", "\\1", str_extract_all(source.code, "library\\(\"?([^\\)]*?)\"?\\)")[[1]]))
packages.per.file

required.packages <- packages.per.file %>%
  pull(packages) %>%
  unique() %>%
  sort()
required.packages

missing.packages <- required.packages[sapply(required.packages, function(x){length(find.package(x, quiet = TRUE)) == 0})]
if (length(missing.packages) > 0) {
  cat(paste0("You are currently missing some packages. Please install these using:\ninstall.packages(c(\"", paste(missing.packages, collapse = "\", \""), "\"))"))
} else {
  cat("All required packages are installed.")
}

computation.time.per.file <- rmarkdown.documents %>%
  group_by(file.name) %>%
  reframe(
    computation.time = system.time(
      Rscript_call(
        fun = render,
        args = list(
          input = file.path,
          output_dir = directory.name,
          intermediates_dir = directory.name
        )
      )
    )[[3]]
  )
computation.time.per.file

write(
  x = paste0(
    "Click [here](./) to go back.\n\n# R Code Collection\n\nThe following pieces of code are available:\n\n",
    paste(
      rmarkdown.documents %>%
        mutate(x = paste0("- [", gsub(".Rmd", ".html", file.name), "](", gsub(".Rmd", ".html", file.path), ")\n  - download the notebook *[", file.name, "](", file.path, ")*\n")) %>%
        pull(x),
      collapse = ""
    )
  ),
  file = "R-Code-Collection.md"
)
