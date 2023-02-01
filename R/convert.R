pyrdocs_convert <- function(package_source_folder = here::here(),
                            r_sub_folder = "R_package",
                            python_sub_folder = "python_package",
                            branch = "main",
                            quarto_sub_folder = "docs",
                            version_folder = "",
                            package_name = fs::path_file(package_source_folder),
                            downlit_options = TRUE,
                            site_url = qe(quarto_folder, "site", "site-url"),
                            verbosity = "verbose",
                            convert_readme = TRUE,
                            convert_news = TRUE,
                            convert_articles = TRUE,
                            convert_reference = TRUE,
                            reference_folder = "reference",
                            vignettes_folder = "articles",
                            reference_examples = FALSE,
                            reference_examples_not_run = FALSE,
                            reference_output = "md",
                            reference_qmd_options = NULL,
                            build_parent_and_child_reference_pages = TRUE,
                            convert_child_pages_to_parent_pages = NULL,
                            reference_template_parent = system.file("templates/function_parent_reference.qmd", package = "pyrdocs"),
                            reference_template_child = system.file("templates/function_child_reference.qmd", package = "pyrdocs"),
                            reference_template = system.file("templates/function_child_reference.qmd", package = "pyrdocs"),
                            commit = c("latest_tag", "latest_commit"),
                            package_description = NULL,
                            site_yml_file = system.file("templates/_quarto.yml", package = "pyrdocs"),
                            site_docs = NULL
){

  # sha_file <- fs::path(qfs, ".ecodown")
  # if (fs::file_exists(sha_file)) {
  #   sha_existing <- readLines(sha_file)
  #   if (sha_existing == sha) {
  #     ecodown::downlit_options(
  #       package = package_name,
  #       url = quarto_sub_folder,
  #       site_url = site_url
  #     )
  #     ecodown:::msg_summary_entry("| 0 0   0   0 0 |\n")
  #     ecodown:::msg_color("Commit already copied...skipping", color = yellow)
  #     return()
  #   }
  # }

  ## generate R docs

  ecodown::ecodown_convert(package_source_folder = r_sub_folder,
                           branch = branch,
                           quarto_folder = package_source_folder,
                           quarto_sub_folder = quarto_sub_folder,
                           reference_folder = reference_folder,
                           reference_output = reference_output,
                           build_parent_and_child_reference_pages = build_parent_and_child_reference_pages,
                           reference_template = reference_template,
                           reference_template_parent = reference_template_parent,
                           verbosity = verbosity
  )

  ## generate python docs
  ecodown:::msg_color_title("Copying/Convering Python Files to Quarto")

  ecodown:::msg_color("Converting module files to Markdown files:")

  python_package_path <- fs::path(package_source_folder, python_sub_folder)

  if(!fs::dir_exists(fs::path(python_package_path, reference_folder))){
    fs::dir_create(fs::path(python_package_path, reference_folder))
  }

  build_python_md_files(package_source_folder = package_source_folder,
                        python_sub_folder = python_sub_folder,
                        package_name = package_name,
                        reference_folder = reference_folder,
                        reference_output = reference_output,
                        verbosity = verbosity)

  ecodown:::msg_color("Splitting modular Markdown files per function:")

  if(!fs::dir_exists(fs::path(package_source_folder, quarto_sub_folder, reference_folder))){
    fs::dir_create(fs::path(package_source_folder, quarto_sub_folder, reference_folder))
  }

  md_files <- filter_md_file(
    fs::dir_ls(fs::path(package_source_folder, python_sub_folder, reference_folder), type = "file")
  )

  all_output_md_files <- grab_output_py_docstrings(md_files)

  split_file_tree(all_output_md_files$path_files,
                  all_output_md_files$functions,
                  base_folder = package_source_folder,
                  command_name = "split_python_md_modules",
                  addl_entries = list(base_folder = package_source_folder,
                                      python_pkg = python_sub_folder,
                                      python_module = package_name,
                                      quarto_folder = package_source_folder,
                                      quarto_sub_folder = quarto_sub_folder,
                                      reference_folder = reference_folder,
                                      reference_output = reference_output),
                  verbosity = verbosity)

  if(fs::file_exists(fs::path(package_source_folder,"README.md"))){
    fs::file_copy(fs::path(package_source_folder,"README.md"),
                  fs::path(package_source_folder, quarto_sub_folder, "index.md"),
                  overwrite = T)
  }

  if(fs::dir_exists(fs::path(package_source_folder, python_sub_folder, reference_folder))){
    fs::dir_delete(fs::path(package_source_folder, python_sub_folder, reference_folder))
  }

  if(!is.null(convert_child_pages_to_parent_pages)){
    for(i in convert_child_pages_to_parent_pages){
      if(fs::file_exists(fs::path(package_source_folder, quarto_sub_folder, reference_folder, i, ext = "qmd"))){
        clean_parent_to_child_functions(
          input = i,
          package_source_folder,
          quarto_sub_folder,
          reference_folder
        )
        fs::file_delete(fs::path(package_source_folder, quarto_sub_folder, reference_folder, i, ext = "qmd"))
      }
    }

    r_files <- filter_r_file(
      fs::dir_ls(fs::path(package_source_folder, quarto_sub_folder, reference_folder),  type = "file"),
      convert_child_pages_to_parent_pages
    )

  } else {

    r_files <- filter_r_file(
      fs::dir_ls(fs::path(package_source_folder, quarto_sub_folder, reference_folder),  type = "file")
    )

  }


  clean_r_files(r_files)

  fs::file_copy(
    site_yml_file,
    fs::path(here::here(), quarto_sub_folder, fs::path_file(site_yml_file))
  )

  if(fs::dir_exists(fs::path(here::here(), quarto_sub_folder, "html"))) fs::dir_delete(fs::path(here::here(), quarto_sub_folder, "html"))

  if(!is.null(site_docs)){
    fs::dir_copy(
      site_docs,
      fs::path(here::here(), quarto_sub_folder, fs::path_file(site_docs))
    )
  }


  ecodown:::msg_color_title(paste0("Compiled Markdown documents can be accessed at ", crayon::blue(fs::path_file(fs::path(package_source_folder, quarto_sub_folder)))))

}
