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
      md_file <-parsermd::parse_rmd(input)
      function_module_src <- parsermd::rmd_select(md_file, parsermd::by_section(c("Module *"))) |> parsermd::as_tibble()
      function_parent_class <- parsermd::rmd_select(md_file, parsermd::by_section(c("* Objects"))) |> parsermd::as_tibble()
      functions_sans_module <- parsermd::rmd_select(md_file, !parsermd::by_section(c("Module *")))
      functions_sans_class <- parsermd::rmd_select(functions_sans_module, !parsermd::by_section(c("* Objects")))
      functions_table <- functions_sans_class |> parsermd::as_tibble()

      functions <- functions_table[functions_table$type == "rmd_markdown", ]
      function_module_src <- function_module_src[function_module_src$type == "rmd_heading", ]
      function_module_src <- as.data.frame(lapply(function_module_src, rep, nrow(functions)))
      function_parent_class <- function_parent_class[function_parent_class$type == "rmd_markdown", ]
      function_parent_class <- as.data.frame(lapply(function_parent_class, rep, nrow(functions)))
      names(functions_module_src)[names(functions_module_src) == "ast"] <- "module_ast"
      names(functions_parent_class)[names(functions_parent_class) == "ast"] <- "class_ast"
      names(functions_module_src)[names(functions_module_src) == "sec_h4"] <- "module_sec_h4"
      names(functions_parent_class)[names(functions_parent_class) == "sec_h4"] <- "class_sec_h4"
      names(functions_parent_class)[names(functions_parent_class) == "type"] <- "class_type"
      names(functions_module_src)[names(functions_module_src) == "type"] <- "module_type"
      names(functions_parent_class)[names(functions_parent_class) == "label"] <- "class_label"
      names(functions_module_src)[names(functions_module_src) == "label"] <- "module_label"

      if((nrow(functions) == 1 && functions$type == "rmd_yaml_list")||(nrow(functions) == 0)){
        functions_table <- md_file |> parsermd::as_tibble()
        functions <- functions_table[functions_table$type == "rmd_markdown", ]
      }

      functions <- rbind(functions, functions_parent_class, functions_module_src)

      functions <- lapply(functions,
                          function(x) {
        id <- x == "**Arguments**:"
        x$ast[id] <- "#### Arguments"
        id <- x == "```python"
        x$ast[id] <- "#### Usage \n\n```python"
        header_id <- which(x$ast == "#### Arguments")
        # pydoc-markdown exports to list, convert this to a table so that it matches the ecodown R function args table.
        table_header_id <- header_id + 1
        table_header <- "|Argument      |Type hint      |Description     |\n|--------------|---------------|----------------|"
        if(length(table_header_id) > 0){
          x$ast <- append(x$ast, table_header, after = table_header_id)
        }
        # remove description as it'll be in the parent file (before the tab switching)
        description <- header_id - 2
        x$ast <- x$ast[-c(description)]
        # convert table rows to rows and columns
        x$ast <- sapply(x$ast,function(y) sub("([(]`)"," | `",as.character(y)))
        x$ast <- sapply(x$ast,function(y) sub("(`[)]:)","` | ",as.character(y)))
        x$ast <- sapply(x$ast,function(y) sub("(^- )","",as.character(y)))
        remove_empty_tables <- "Function(s) | Description\n|---|---|\n\n## NULL\n"
        x$ast[remove_empty_tables] <- ""
        x$ast <- cat(
          x$ast,
          "#### Class \n",
          x$class_ast,
          "#### Module Source \n",
          x$module_ast,
        )
      })
      if(nrow(functions)>0){
        for(j in 1:nrow(functions)){
          # write each row out to separate file
          file_name <- gsub("`", "", functions$sec_h4[[j]])
          cat(paste0(functions$ast[[j]]),
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

