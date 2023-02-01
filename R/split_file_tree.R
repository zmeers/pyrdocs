split_file_tree <- function(file_list,
                            output_file_list,
                            file_type = "",
                            base_folder,
                            command_name = "",
                            entry_value = NULL,
                            addl_entries = list(),
                            verbosity = "verbose") {
  tree_start <- Sys.time()
  file_unique <- unique(fs::path_dir(file_list))
  file_sort <- sort(file_unique)
  output_file_unique <- unique(fs::path_dir(output_file_list))
  output_file_sort <- sort(output_file_unique)
  rel_sort <- substr(
    output_file_sort,
    nchar(fs::path_dir(base_folder)),
    nchar(output_file_sort)
  )
  for (i in seq_along(rel_sort)) {
    matched_files <- fs::path_dir(file_list) == file_sort[i]
    matched_files_actual <- fs::path_dir(file_list) == file_sort[i]
    no_files <- sum(matched_files)
    no_caption <- ifelse(no_files > 1, "files", "file")
    curr_sort <- rel_sort[i]
    pss <- ""
    if (i > 1) {
      pc <- fs::path_common(rel_sort[c(i, i - 1)])
      fln <- fs::path_file(curr_sort)
      ps <- fs::path_split(curr_sort)[[1]]
      pss <- paste0(rep("|-- ", times = length(ps) - 1), collapse = "")
      psc <- crayon::silver(pss)
      flc <- crayon::black(fln)
    }
    no_cat <- crayon::magenta(paste0(" (", no_files, " ", file_type, no_caption, ")"))
    cat_msg <- paste0(curr_sort, no_cat)
    if (verbosity == "verbose") cat_msg <- paste0(cat_msg, "\n")
    section_start <- Sys.time()
    cat(cat_msg)
    if (command_name != "") {
      purrr::walk2(
        file_list[matched_files_actual],
        output_file_list,
        ~ {
          start_time <- Sys.time()
          if (verbosity == "verbose") {
            cat(paste0(crayon::silver(paste0(pss, "|-- ")), fs::path_file(.x)))
          }
          res <- ecodown:::exec_command(
            command_name = command_name,
            entry_value = entry_value,
            addl_entries = c(addl_entries, list(input = .x))
          )
          res_msg <- ""
          if (!is.null(res)) {
            res_msg <- crayon::blue(" =>", paste0(.y, ".md"))
          }
          stop_time <- Sys.time()
          if (verbosity == "verbose") {
            doc_time <- ecodown:::cat_time(start_time, stop_time)
            cat(paste0(res_msg, crayon::silver(doc_time), "\n"))
          }
        }
      )
    }
    section_end <- Sys.time()
    section_time <- ecodown:::cat_time(section_start, section_end)
    if (verbosity == "summary") cat(paste0(section_time, "\n"))
  }
  sep_cat <- paste0(rep("=", times = 46), collapse = "")
  cat(crayon::silver(sep_cat, "\n"))

  tree_time <- ecodown:::cat_time(tree_start, Sys.time(), add_brackets = FALSE)

  cat(crayon::silver("Total files: ", length(output_file_list), " ---- Total time: ", tree_time, "\n"))
}

