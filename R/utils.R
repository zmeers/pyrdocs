filter_python_file <- function(x) {
  x <- x[!startsWith(fs::path_file(x), "_")]
  x[endsWith(fs::path_file(x), "py")]
}

filter_r_file <- function(x, convert_child_pages_to_parent_pages = NULL) {
  x <- x[!endsWith(fs::path_file(x), "py.md")]
  y <- x[!endsWith(fs::path_file(x), "qmd")]
  z <- y[!endsWith(fs::path_file(y), "index.md")]
  if(!is.null(convert_child_pages_to_parent_pages)){
    z <- z[!endsWith(fs::path_file(z), convert_child_pages_to_parent_pages)]
  }
  z
}

filter_md_file <- function(x) {
  x <- x[!startsWith(fs::path_file(x), "_")]
  x[endsWith(fs::path_file(x), "md")]
}

grab_output_py_docstrings <- function(md_files){

  all_output_md_files <- lapply(md_files, function(x){
    md_files_long <- parsermd::parse_rmd(x) |>
      parsermd::as_tibble()
    md_files_filtered <- md_files_long[md_files_long$type == "rmd_markdown", ]
    md_files <- md_files_long[1]
    md_file_functions <- md_files[grepl("^`.*?`$", md_files$sec_h4), ]
    if(nrow(md_file_functions)==0){
      replace <- paste0('"Module `', "canviz", ".")
      md_file_functions_modules <- md_files[grepl("Module .*", md_files$sec_h4), ]
      md_file_functions <- md_file_functions_modules[gsub(replace, "", md_file_functions_modules$sec_h4), ]
    }
    md_file_functions
  } ) |>
    cbind() |>
    as.data.frame() |>
    unlist() |>
    as.data.frame()


  colnames(all_output_md_files) <- "result"
  all_output_md_files$path_files <- fs::path_ext_remove(rownames(all_output_md_files))
  all_output_md_files$files <- fs::path_ext_remove(fs::path_file(all_output_md_files$path_files))
  rownames(all_output_md_files) <- NULL
  all_output_md_files$path_files <- gsub("V1.", "", all_output_md_files$path_files)
  output_md_files <- unique(all_output_md_files)
  final_result <- ifelse(is.na(output_md_files$result), output_md_files$files, output_md_files$result)
  functions <- c(gsub("`", "", final_result))
  path_files <- c(output_md_files$path_files)

  cbind(functions, path_files) |> as.data.frame()

}

build_python_md_files <- function(package_source_folder = package_source_folder,
                                  python_sub_folder = python_sub_folder,
                                  package_name = package_name,
                                  reference_folder = reference,
                                  reference_output = reference_output,
                                  verbosity = "verbose"){

  python_files <- filter_python_file(
    fs::dir_ls(fs::path(package_source_folder, python_sub_folder, package_name),  type = "file")
  )

  ecodown:::file_tree(python_files,
                      base_folder = package_source_folder,
                      command_name = "generate_python_md_modules",
                      addl_entries = list(base_folder = package_source_folder,
                                          python_pkg = python_sub_folder,
                                          python_module = package_name,
                                          reference_folder = reference_folder,
                                          reference_output = reference_output),
                      verbosity = verbosity)
}

clean_r_files <- function(r_files){
  new_r_file_names <- paste0(fs::path_ext_remove(fs::path_file(r_files)), "_r")

  r_file_exists <- fs::file_exists(fs::path(fs::path_dir(r_files), new_r_file_names, ext = "md")) |> as.data.frame()
  colnames(r_file_exists) <- "file_exists"
  r_file_exists$file <- rownames(r_file_exists)
  rownames(r_file_exists) <- NULL
  r_file_exists$old_file <- as.character(r_files)

  for (i in 1:nrow(r_file_exists)){
    if(isFALSE(r_file_exists$file_exists[i])) {
      fs::file_copy(r_file_exists$old_file[i], r_file_exists$file[i])
      fs::file_delete(r_file_exists$old_file[i])
    }
  }

}
