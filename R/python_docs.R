generate_python_md_modules <- function(python_pkg, python_module){

   python_files <- as.vector(
     dir(paste0(python_pkg, "/", python_module),
                pattern = "^[a-z].*.py$",
                ignore.case = T,
                full.names = F)
   )


   for (i in python_files){
     i <- tools::file_path_sans_ext(i)
     print(paste0("Converting docstrings in ", i, ".py to markdown"))

     system(
       paste("chmod +x",
             system.file("shell_scripts/python_pydocs_to_md.sh",
                         package = "pyrdocs")
             )
       )

     system(
       paste(
         system.file("shell_scripts/python_pydocs_to_md.sh",
                     package = "pyrdocs"),
         python_pkg,
         python_module,
         i
         )
       )
   }
}

split_and_clean_python_md_modules <- function(python_pkg, python_module){

  markdown_files <- as.vector(
    dir(paste0(python_pkg, "/docs"),
        pattern = "^[a-z].*.md$",
        ignore.case = T,
        full.names = F)
  )

  for (i in markdown_files){
    print(paste("Splitting markdown docstrings for each function in", i, "to separate file."))
    md_file <-parsermd::parse_rmd(paste0(python_pkg, "/docs/", i))
    function_module_src <- parsermd::rmd_select(md_file, parsermd::by_section(c("Module *"))) |> parsermd::as_tibble()
    function_parent_class <- parsermd::rmd_select(md_file, parsermd::by_section(c("* Objects"))) |> parsermd::as_tibble()
    functions_sans_module <- parsermd::rmd_select(md_file, !parsermd::by_section(c("Module *")))
    functions_sans_class <- parsermd::rmd_select(functions_sans_module, !parsermd::by_section(c("* Objects")))
    functions_table <- functions_sans_class |> parsermd::as_tibble()

    functions <- functions_table[functions_table$type == "rmd_markdown", ]
    function_module_src <- function_module_src[function_module_src$type == "rmd_heading", ]
    function_parent_class <- function_parent_class[function_parent_class$type == "rmd_markdown", ]

    if(nrow(functions) == 1 && functions$type == "rmd_yaml_list"){
      functions_table <- md_file |> parsermd::as_tibble()
      functions <- functions_table[functions_table$type == "rmd_markdown", ]
    }
    functions$ast <- lapply(functions$ast, function(x) {
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
      # remove description as it'll be in the parent file (before the tab switching)
      description <- header_id - 2
      x <- x[-c(description)]
      # convert table rows to rows and columns
      x <- sapply(x,function(y) sub("([(]`)"," | `",as.character(y)))
      x <- sapply(x,function(y) sub("(`[)]:)","` | ",as.character(y)))
      x <- sapply(x,function(y) sub("(^- )","",as.character(y)))
      x
    })
    for(j in 1:nrow(functions)){
      # write each row out to separate file
      file_name <- gsub("`", "", functions[[1]][[j]])
      if(!dir.exists(paste0(python_pkg, '/docs/py_docs'))){
        dir.create(paste0(python_pkg, "/docs/py_docs"))
      }
        sink(paste0(python_pkg,"/docs/py_docs/",  file_name, ".md"))
        cat(functions$ast[[j]], sep = "\n")
        cat("#### Class \n", sep = "\n")
        cat(function_parent_class$ast[[1]], sep = "\n")
        cat("#### Module Source \n", sep = "\n")
        cat(function_module_src[[1]][[1]], sep = "\n")
        sink()
    }
  }
}

