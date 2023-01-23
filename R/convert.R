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
                            build_parent_and_child_reference_pages = TRUE,
                            reference_template_parent = system.file("templates/function_parent_reference.qmd", package = "pyrdocs"),
                            reference_template_child = system.file("templates/function_child_reference.qmd", package = "pyrdocs"),
                            reference_template = system.file("templates/function_child_reference.qmd", package = "pyrdocs"),
                            commit = c("latest_tag", "latest_commit"),
                            package_description = NULL
){

  if(!fs::dir_exists(fs::path(r_sub_folder, quarto_sub_folder))){
    fs::dir_create(fs::path(r_sub_folder,quarto_sub_folder))
  }

  ## generate R docs
  ecodown::ecodown_convert(package_source_folder = r_sub_folder,
                           branch = branch,
                           quarto_folder = r_sub_folder,
                           quarto_sub_folder = quarto_sub_folder,
                           reference_folder = reference_folder,
                           reference_output = reference_output,
                           build_parent_and_child_reference_pages = build_parent_and_child_reference_pages,
                           reference_template = reference_template,
                           reference_template_parent = reference_template_parent
  )

  md_files <- fs::dir_ls(fs::path(r_sub_folder, quarto_sub_folder, reference_folder), glob = "*.md")
  md_files <- md_files[md_files != paste0(fs::path(r_sub_folder, quarto_sub_folder, reference_folder), 'index.md')]
  r_md_files <- sub(".md", "_r.md", md_files)
  file.rename(md_files, new_names)

  setwd(dirname(here::here()))

  fs::dir_copy(fs::path(r_sub_folder, quarto_sub_folder), fs::path(quarto_sub_folder))

  ## generate python docs
  generate_python_md_modules(python_package_path, "canviz", reference_folder)
  split_and_clean_python_md_modules(python_package_path,
                                    "canviz",
                                    quarto_folder = package_source_folder,
                                    quarto_sub_folder = quarto_sub_folder,
                                    reference_folder = reference_folder)

}
