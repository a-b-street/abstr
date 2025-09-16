## Resubmission
This is a resubmission. In this version I have:

* Fixed pkgdown GitHub Actions workflow by updating action versions and fixing gfortran removal error

## R CMD check results

There were no ERRORs.

There were 4 WARNINGs:
* Files in the 'vignettes' directory but no files in 'inst/doc' (normal for vignette packages)
* Package vignettes without corresponding single PDF/HTML (normal for vignette packages)
* LaTeX errors when creating PDF version (pdflatex not available in test environment)
* PDF version of manual without index (pdflatex not available in test environment)

There were 3 NOTEs:
* Found hidden files and directories (.github, .git, etc.) - normal for git repositories
* Namespace in Imports field not imported from: 'tibble' - will be addressed in future version
* Checking should be performed on sources prepared by 'R CMD build' - normal for source check

## Downstream dependencies

No downstream dependencies

## Test Environments

* MacOS-latest, R (release)
* Windows-latest, R (release)
* Ubuntu-latest, R (develop and release)
* Local: Ubuntu 24.04.3 LTS, R 4.5.1

