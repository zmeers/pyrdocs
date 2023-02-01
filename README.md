# pyrdocs

`pyrdocs` is a WIP `R` package to generate `Python` and `R` documentation for a Quarto or Hugo website. The main function `pyrdocs_convert` converts and builds Markdown files for `R` documentation and `Python` docstrings. If the `Python` and `R` files are similarly named, they will be added as tabs in a parent reference page.

It works as follows:
```
pyrdocs::pyrdocs_convert(branch = "main",
                         package_source_folder = here::here(),
                         r_sub_folder = "R_package",
                         python_sub_folder = "python_package",
                         quarto_folder = here::here(),
                         quarto_sub_folder = "docs"
                         ...)
```
where package source folder points to a higher level folder and the `R` and `Python` packages are subdirectories of the package source folder. The branch pulls from a GitHub branch, and the quarto folders and sub folders refer to the output directory.

To render the site in an `R` session, you can then use `quarto`: `quarto::quarto_render("docs")` from the package source folder.

