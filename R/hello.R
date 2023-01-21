# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Cmd + Shift + B'
#   Check Package:             'Cmd + Shift + E'
#   Test Package:              'Cmd + Shift + T'

hello <- function() {
  print("Hello, world!")
}


reference_convert(x, output = "qmd")
{
  res <- list()
  for (i in seq_along(x)) {
    curr <- x[[i]]
    curr_name <- names(x[i])
    out <- NULL
    # if (curr_name == "examples") {
    #   run_examples <- FALSE
    #   if (output == "md") {
    #     out <- map(curr, reference_qmd_example, FALSE)
    #     out <- flatten(out)
    #   }
    #   else {
    #     out <- list()
    #     if (!is.null(curr$code_run)) {
    #       out <- c(out, "```{r, eval=ecodown::examples_run()}",
    #                curr$code_run, "```")
    #     }
    #     if (!is.null(curr$code_dont_run)) {
    #       out <- c(out, "```{r, eval=ecodown::examples_not_run()}",
    #                curr$code_dont_run, "```")
    #     }
    #   }
    # }
    if (curr_name == "usage") {
      out <- reference_qmd_example(curr, FALSE)
    }
    if (curr_name == "arguments")
      out <- reference_arguments(curr)
    if (curr_name == "section") {
      out <- curr %>% map(~c(paste("##", .x$title), .x$contents)) %>%
        flatten() %>% reduce(function(x, y) c(x, "",
                                              y), .init = NULL)
    }
    if (is.null(out)) {
      out <- curr
      if (is.list(out))
        out <- flatten(out)
      if (length(out) > 1)
        out <- reduce(out, function(x, y) c(x, "", y),
                      .init = NULL)
    }
    out <- list(out)
    names(out) <- curr_name
    res <- c(res, out)
  }
  res
}
