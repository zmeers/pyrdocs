pyrdocs_convert <- function(package_source_folder = here::here(),
                            r_sub_folder = "R_package",
                            python_sub_folder = "python_package",
                            branch = "main",
                            quarto_sub_folder = "quarto_docs",
                            version_folder = "",
                            package_name = fs::path_file(package_source_folder),
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
                            reference_template = system.file("function_child_reference.md", package = "pyrdocs"),
                            build_parent_and_child_reference_pages = TRUE,
                            reference_template_parent = system.file("function_parent_reference.md", package = "pyrdocs"),
                            reference_template_child = system.file("function_child_reference.md", package = "pyrdocs"),
                            commit = c("latest_tag", "latest_commit"),
                            package_description = NULL
){

  r_package_path <- paste0(package_source_folder, "/", r_sub_folder)
  python_package_path <- paste0(package_source_folder, "/", python_sub_folder)

  ## generate R docs
  ecodown::ecodown_convert(package_source_folder = r_package_path,
                           branch = branch,
                           quarto_folder = r_package_path,
                           quarto_sub_folder = quarto_sub_folder,
                           reference_folder = reference_folder,
                           r_reference_folder = r_reference_folder,
                           python_reference_folder = python_reference_folder,
                           reference_output = reference_output,
                           build_parent_and_child_reference_pages = build_parent_and_child_reference_pages,
                           reference_template = reference_template,
                           reference_template_parent = reference_template_parent
  )
  ecodown::ecodown_build(quarto_folder = paste0(r_package_path, "/", quarto_sub_folder))

  setwd(path='..')
  if (!dir.exists(quarto_sub_folder) {
    dir.create(path = quarto_sub_folder)
  }
  file.move(paste0(r_package_path, quarto_sub_folder), quarto_sub_folder))
  ## generate python docs
  if(!dir.exists(paste0(quarto_folder, quarto_sub_folder, reference_folder, python_reference_folder, collapse = "/"))){
    dir.create(paste0(quarto_folder, quarto_sub_folder, reference_folder, collapse = "/"))
    dir.create(paste0(quarto_folder, quarto_sub_folder, reference_folder, python_reference_folder, collapse = "/"))
  }
  generate_python_md_modules(python_package_path, "canviz", reference_folder, python_reference_folder)
  split_and_clean_python_md_modules(python_package_path,
                                    "canviz",
                                    quarto_folder = package_source_folder,
                                    quarto_sub_folder = quarto_sub_folder,
                                    reference_folder = reference_folder,
                                    python_reference_folder = python_reference_folder)

}
