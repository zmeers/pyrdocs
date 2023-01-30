filter_python_file <- function(x) {
  x <- x[!startsWith(fs::path_file(x), "_")]
  x[endsWith(fs::path_file(x), "py")]
}

filter_md_file <- function(x) {
  x <- x[!startsWith(fs::path_file(x), "_")]
  x[endsWith(fs::path_file(x), "md")]
}

