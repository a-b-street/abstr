#' Example OSM Buildings Table for Montlake
#'
#' Each row of this table contains a building that exists within a
#' zone in the `montlake_zones` table.
#'
#' These buildings were retrieved using osmextract::oe_read(). See the code used to
#' create this data in "data-raw/montlake-test-data.R"
#'
#' @source OpenStreetMap,
#'   <www.openstreetmap.org>
#' @format A sf dataframe with columns:
#' \describe{
#' \item{osm_way_id}{OSM ID assigned to each building.}
#' \item{name}{OSM name assigned to each building (might by <NA>).}
#' \item{building}{OSM building category assigned to each building.}
#' \item{geometry}{Simple feature collection (sfc) contain multipolygons,
#'   each representing the boundaries of a building.}
#' }
#' @examples
#' library(sf)
#' names(montlake_buildings)
#' head(montlake_buildings$osm_way_id)
#' head(montlake_buildings$name)
#' head(montlake_buildings$building)
#' nrow(montlake_buildings)
#' plot(montlake_buildings)
"montlake_buildings"
