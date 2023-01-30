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

  # sha_file <- fs::path(qfs, ".ecodown")
  # if (fs::ile_exists(sha_file)) {
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
  file.rename(md_files, r_md_files)

  fs::dir_copy(fs::path(r_sub_folder, quarto_sub_folder), fs::path(quarto_sub_folder), overwrite = T)

  ecodown:::msg_color_title("Copying/Convering Python Files to Quarto")
  ## generate python docs
  python_package_path <- fs::path(package_source_folder, python_sub_folder)

  if(!fs::dir_exists(fs::path(python_package_path, reference_folder))){
    fs::dir_create(fs::path(python_package_path, reference_folder))
  }

  python_files <- filter_python_file(
    fs::dir_ls(fs::path(python_package_path, package_name),  type = "file")
  )

  ecodown:::msg_color("Converting module files to Markdown files:")

  ecodown:::file_tree(python_files,
                      base_folder = package_source_folder,
                      command_name = "generate_python_md_modules",
                      addl_entries = list(base_folder = package_source_folder,
                                          python_pkg = python_sub_folder,
                                          python_module = package_name,
                                          reference_folder = reference_folder,
                                          reference_output = reference_output),
                      verbosity = verbosity)

  ecodown:::msg_color("Splitting modular Markdown files per function:")

  if(!fs::dir_exists(fs::path(package_source_folder, reference_folder))){
    fs::dir_create(fs::path(package_source_folder, reference_folder))
  }

  md_files <- filter_md_file(
    fs::dir_ls(fs::path(package_source_folder, python_sub_folder, reference_folder), type = "file")
  )

  ecodown:::file_tree(md_files,
                      base_folder = package_source_folder,
                      command_name = "split_python_md_modules",
                      addl_entries = list(base_folder = package_source_folder,
                                          python_pkg = python_sub_folder,
                                          python_module = package_name,
                                          quarto_folder = package_source_folder,
                                          quarto_sub_folder = quarto_sub_folder,
                                          reference_folder = reference_folder),
                      verbosity = verbosity)

  if(isTRUE(fs::file_exists("README.md"))){
    fs::file_move("README.md", fs::path(quarto_sub_folder, "index.md"))
  }
  ecodown:::msg_color_title(paste0("Compiled Markdown documents can be accessed at ", crayon::blue(fs::path_file(fs::path(here::here(), quarto_sub_folder)))))

}
