generate_python_md_modules <- function(input,
                                       base_folder,
                                       python_pkg,
                                       python_module,
                                       reference_folder,
                                       reference_output){

  i <- fs::path_ext_remove(fs::path_file(input))

  fs::file_chmod(system.file("shell_scripts/python_pydocs_to_md.sh", package = "pyrdocs"), "+x")

  j <- system(
    paste(
      system.file("shell_scripts/python_pydocs_to_md.sh",
                  package = "pyrdocs"),
      base_folder,
      python_pkg,
      python_module,
      i,
      reference_folder
    )
  )
  return(fs::path_ext_set(fs::path_file(input), ext = reference_output))
}



split_python_md_modules <- function(input,
                                    base_folder,
                                    python_pkg,
                                    python_module,
                                    quarto_folder,
                                    quarto_sub_folder,
                                    reference_folder,
                                    reference_output){

  if(isTRUE(file.info(input)$size>0)){

    md_file <-parsermd::parse_rmd(input) |>parsermd::as_tibble()
    function_heading <-  parsermd::as_tibble(md_file)[parsermd::as_tibble(md_file)$type == "rmd_heading",]
    function_module_src <- function_heading[grepl("Module .*" , function_heading$sec_h4),]
    function_parent_class <- function_heading[grep(".* Objects$" , function_heading$sec_h4),]
    functions_markdown <- parsermd::as_tibble(md_file)[parsermd::as_tibble(md_file)$type == "rmd_markdown",]
    functions_markdown_sans_obj_module <- functions_markdown[!grepl('(.* Objects$)|(^Module .*)', functions_markdown$sec_h4),]
    functions_markdown_clean <- functions_markdown_sans_obj_module

    if((nrow(functions_markdown_clean) == 1 && functions_markdown_clean$type == "rmd_yaml_list")||(nrow(functions_markdown_clean) == 0)){
      functions_markdown <- md_file[md_file$type == "rmd_markdown",]
      functions_markdown_clean <- functions_markdown[grepl(".* Objects$", functions_markdown$sec_h4),]
    }

    function_module_src <- dplyr::as_tibble(lapply(function_module_src, rep, nrow(functions_markdown_clean)))
    function_parent_class <- dplyr::as_tibble(lapply(function_parent_class, rep, nrow(functions_markdown_clean)))

    names(function_module_src)[names(function_module_src) == "ast"] <- "module_ast"
    names(function_parent_class)[names(function_parent_class) == "ast"] <- "class_ast"

    names(function_module_src)[names(function_module_src) == "sec_h4"] <- "module_sec_h4"
    names(function_parent_class)[names(function_parent_class) == "sec_h4"] <- "class_sec_h4"

    names(function_parent_class)[names(function_parent_class) == "type"] <- "class_type"
    names(function_module_src)[names(function_module_src) == "type"] <- "module_type"

    names(function_parent_class)[names(function_parent_class) == "label"] <- "class_label"
    names(function_module_src)[names(function_module_src) == "label"] <- "module_label"


    functions <- cbind(functions_markdown_clean, function_parent_class, function_module_src)

    functions_result <- mapply(c,
                               functions$ast,
                               "#### Class \n",
                               functions$class_sec_h4,
                               "\n",
                               "#### Module Source \n",
                               functions$module_sec_h4, SIMPLIFY = F)


    functions_result <- lapply(functions_result,
                               function(x) {
                                 id <- x == "**Arguments**:"
                                 x[id] <- "#### Arguments"
                                 id <- x == "```python"
                                 x[id] <- "#### Usage \n\n```python"
                                 header_id <- which(x == "#### Arguments")
                                 # pydoc-markdown exports to list, convert this to a table so that it matches the ecodown R function args table.
                                 table_header_id <- header_id + 1
                                 table_header <- "|Argument      |Type hint      |Description     |\n|--------------|---------------|----------------|"
                                 if(length(table_header_id) > 0){
                                   x <- append(x, table_header, after = table_header_id)
                                 }
                                 # split up the function so that each argument is on a new line
                                 x <- ifelse(grepl("(^def.*)|(^@.*)|(^class.*)", x), lapply(x,function(y) gsub(", ",",\n    ", as.character(y))), x)
                                 x <- ifelse(grepl("(^def.*)|(^@.*)|(^class.*)", x), lapply(x,function(y) gsub("([(])","(\n    ", as.character(y))), x)
                                 x <- ifelse(grepl("(^def.*)|(^@.*)|(^class.*)", x), lapply(x,function(y) gsub("([)])","\n)", as.character(y))), x)
                                 
                                 # remove description as it'll be in the parent file (before the tab switching)
                                 description <- header_id - 2
                                 x <- x[-c(description)]
                                 # convert table rows to rows and columns
                                 x <- lapply(x,function(y) sub("([(]`)"," | `", as.character(y)))
                                 x <- lapply(x,function(y) sub("(`[)]:)","` | ", as.character(y)))
                                 x <- lapply(x,function(y) sub("(^- )","", as.character(y)))
                                 return(x)
                               })

    functions_result_df <- cbind(functions_result) |> as.data.frame()
    rownames(functions_result_df) <- NULL
    colnames(functions_result_df) <- "result"

    functions <- cbind(functions, functions_result_df)

    if(nrow(functions)>0){
      for(j in 1:nrow(functions)){
        # write each row out to separate file
        file_name <- tolower(gsub("(`)|([ ].*$)", "", functions$sec_h4[[j]]))
        cat(paste0(functions$result[[j]]), sep = '\n',
            file = paste0(base_folder, '/',
                          quarto_sub_folder, '/',
                          reference_folder, '/',
                          file_name, '_py.md')
        )
      }
      return(fs::path_ext_set(fs::path_file(file_name), ext = reference_output))
    }
  }
}


clean_parent_to_child_functions <- function(input,
                                            package_source_folder,
                                            quarto_sub_folder,
                                            reference_folder){
  input <- fs::path(package_source_folder, quarto_sub_folder, reference_folder, input, ext = "md")
  input_description <- input <- fs::path(package_source_folder, quarto_sub_folder, reference_folder, input, ext = "qmd")
  if(isTRUE(file.info(input)$size>0)){
    md_file_header <- parsermd::parse_rmd(input_description) |>parsermd::as_tibble()
    md_file_header <- md_file_header[!md_file_header$sec_h3 %in% c("R", "Python", "See also"), ]
    md_file_header <- md_file_header[!is.na(md_file_header$sec_h3), ]
    names(md_file_header)[names(md_file_header) == "sec_h3"] <- "sec"

    md_file <- parsermd::parse_rmd(input) |>parsermd::as_tibble()
    md_file <- md_file[md_file$sec_h4 != "Source", ]
    md_file <- md_file[!is.na(md_file$sec_h4), ]
    names(md_file)[names(md_file) == "sec_h4"] <- "sec"

    md_file_joined <- rbind(md_file_header, md_file)
    md_file_markdown <- md_file_joined[md_file_joined$type != "rmd_markdown", ]

    cat(paste("### ", md_file_markdown$sec[[1]], "\n"),
        paste("#### ", md_file_markdown$sec[[2]], "\n"),
        md_file_markdown$ast[[2]],
        sep = "\n",
        file = paste0(package_source_folder,"/",
                      quarto_sub_folder, "/",
                      reference_folder, "/",
                      input, ".md")
        )
  }
}
