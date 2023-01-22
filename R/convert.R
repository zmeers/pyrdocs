pyrdocs_convert <- function(base_folder = "",
                            r_sub_folder = "",
                            python_sub_folder = "",
                            branch = "main",
                            quarto_sub_folder = package_name,
                            version_folder = "",
                            package_name = fs::path_file(base_directory),
                            quarto_folder = here::here(),
                            downlit_options = TRUE,
                            site_url = qe(quarto_folder, "site", "site-url"),
                            verbosity = c("verbose", "summary", "silent"),
                            convert_readme = TRUE,
                            convert_news = TRUE,
                            convert_articles = TRUE,
                            convert_reference = TRUE,
                            reference_folder = "reference",
                            python_reference_folder = "py_docs",
                            r_reference_folder = "r_docs",
                            vignettes_folder = "articles",
                            reference_examples = FALSE,
                            reference_examples_not_run = FALSE,
                            reference_output = "md",
                            reference_qmd_options = NULL,
                            reference_template = NULL,
                            commit = c("latest_tag", "latest_commit"),
                            package_description = NULL
){

  r_package_path <- paste0(base_folder, "/", r_sub_folder)
  python_package_path <- paste0(base_folder, "/", python_sub_folder)

  ## create directories
  if(!dir.exists(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder))){
    dir.create(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder))
  }
  if(!dir.exists(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder, "/", r_reference_folder))){
    dir.create(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder, "/", r_reference_folder))
  }
  if(!dir.exists(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder, "/", python_reference_folder))){
    dir.create(paste0(quarto_folder, "/", quarto_sub_folder, "/", reference_folder, "/", python_reference_folder))
  }
  ## generate R child docs
  if(reference_output == "qmd"){
    ecodown::ecodown_convert(r_package_path,
                     branch = branch,
                     quarto_folder = base_folder,
                     quarto_sub_folder = "docs",
                     reference_folder = "reference/r_docs",
                     reference_output = "qmd",
                     reference_template = system.file("function_child_reference.qmd", package = "pyrdocs")
                     )
  } else {
    ecodown::ecodown_convert(r_package_path,
                     branch = branch,
                     quarto_folder = base_folder,
                     quarto_sub_folder = "docs",
                     reference_folder = "reference/r_docs",
                     reference_output = "md",
                     reference_template = system.file("function_child_reference.md", package = "pyrdocs")
    )
  }

  ## generate parent docs for each function
  if(reference_output == "qmd"){
   ecodown::ecodown_convert(r_package_path,
                   branch = branch,
                   quarto_folder = base_folder,
                   quarto_sub_folder = "docs",
                   reference_folder = "reference",
                   convert_articles = F,
                   convert_readme = F,
                   convert_news = F,
                   convert_reference = T,
                   reference_output = "qmd",
                   reference_template = system.file("function_parent_reference.qmd", package = "pyrdocs"))
  } else {
    ecodown::ecodown_convert(r_package_path,
                     branch = branch,
                     quarto_folder = base_folder,
                     quarto_sub_folder = "docs",
                     reference_folder = "reference",
                     convert_articles = F,
                     convert_readme = F,
                     convert_news = F,
                     convert_reference = T,
                     reference_output = "md",
                     reference_template = system.file("function_parent_reference.md", package = "pyrdocs"))
  }

  ## generate python docs
  generate_python_md_modules(python_package_path, "canviz")
  split_and_clean_python_md_modules(python_package_path,
                                    "canviz",
                                    quarto_folder = base_folder,
                                    quarto_sub_folder = quarto_sub_folder,
                                    reference_folder = reference_folder,
                                    python_reference_folder = python_reference_folder)

}
