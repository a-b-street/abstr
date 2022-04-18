# Aim: test package against different versions of the od package


# Error message from CRAN
# Last published version on CRAN:

# CRAN Web: <https://cran.r-project.org/package=od>

# Best regards,
# CRAN teams' auto-check service
# Package check result: OK

# Changes to worse in reverse depends:

# Package: abstr
# Check: examples
# New result: ERROR
#   Running examples in ‘abstr-Ex.R’ failed
#   The error most likely occurred in:

#   > base::assign(".ptime", proc.time(), pos = "CheckExEnv")
#   > ### Name: ab_json
#   > ### Title: Convert geographic ('sf') representation of OD data to 'JSON
#   > ###   list' structure
#   > ### Aliases: ab_json
#   >
#   > ### ** Examples
#   >
#   > # Starting with tabular data
#   > od = leeds_od
#   > od[[1]] = c("E02006876")
#   > zones = leeds_zones
#   > ablines = ab_scenario(od, zones = zones)
#   0 origins with no match in zone ids
#   0 destinations with no match in zone ids
#    points not in od data removed.
#   Using od_disaggregate
#   Error in od[[population_column]]/max_per_od :
#     non-numeric argument to binary operator
#   Calls: ab_scenario -> <Anonymous> -> od_disaggregate -> od_nrows
#   Execution halted


# test with released version on CRAN
install.packages("od")
# After that tests pass...
remotes::install_github("itsleeds/od")
