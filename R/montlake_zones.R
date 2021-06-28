#' Example Zones Table for Montlake
#'
#' Each row of this table contains the zone ID and geometry for a TAZ near
#' Montlake. Includes all zones that start or end within the Montlake
#' boundary and have at least 25 trips across all modes of transit in
#' `montlake_od`.
#'
#' See the code used to create this data in "data-raw/montlake-test-data.R"
#'
#' @format A sf dataframe with columns:
#' \describe{
#' \item{id}{Zone ID (must match `o_id` or `d_id` in `montlake_od`).}
#' \item{geometry}{Simple feature collection (sfc) contain multipolygons,
#'   each representing the boundaries of a TAZ near Montlake.}
#' }
"montlake_zones"
