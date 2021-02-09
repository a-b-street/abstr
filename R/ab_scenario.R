#' Generate A/B Street Scenario files/objects
#'
#' @param houses Polygons where trips will originate (`sf` object)
#' @param buildings Buildings where trips will end
#' @param desire_lines Origin-Destination data represented as straight lines
#' @param zones Zones with IDs that match the desire lines
#' @param output_format Which output format? `"sf"` (default) or `"json_list"`?
#'
#' @export
#' @examples
#' dslines = leeds_desire_lines
#' ablines = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   dslines,
#'   leeds_zones,
#'   output_format = "sf"
#' )
#' plot(dslines$geometry, lwd = dslines[[3]] / 30)
#' plot(leeds_site_area$geometry, add = TRUE)
#' plot(leeds_buildings$geometry, add = TRUE)
#' plot(ablines$geometry, col = "blue", add = TRUE)
ab_scenario = function(houses, buildings, desire_lines, zones, output_format = "sf") {

  requireNamespace("sf", quietly = TRUE)
  # input data from data-raw/cambridge.R for testing
  # houses = osm_polygons_resi_site
  # buildings = buildings_in_zones
  # desire_lines = desire_lines
  # zones = zones_of_interest

  # loop over each desire line
  i = 1
  for(i in seq(nrow(desire_lines))) {
    pop = desire_lines$all_base[i]
    origins = houses %>% dplyr::sample_n(size = pop, replace = TRUE)
    destination_zone = zones %>% dplyr::filter(geo_code == desire_lines$geo_code2[i])
    destination_buildings = buildings[destination_zone, , op = sf::st_within]
    destinations = destination_buildings %>% dplyr::sample_n(size = pop, replace = TRUE)
    origin_coords = origins %>% sf::st_centroid() %>% sf::st_coordinates()
    destination_coords = destinations %>% sf::st_centroid() %>% sf::st_coordinates()
    desire_lines_disag = od::odc_to_sf(odc = cbind(origin_coords, destination_coords))
    # mapview::mapview(desire_lines_disag) + mapview::mapview(destination_zone)
    desire_lines_disag$mode_baseline = desire_lines_disag$mode_godutch = NA
    n_walk = desire_lines$walk_base[i]
    desire_lines_disag$mode_baseline[sample(nrow(desire_lines_disag), size = n_walk)] = "walk"
    no_mode = which(is.na(desire_lines_disag$mode_baseline))
    desire_lines_disag$mode_baseline[sample(no_mode, size = desire_lines$cycle_base[i])] = "cycle"
    no_mode = which(is.na(desire_lines_disag$mode_baseline))
    desire_lines_disag$mode_baseline[sample(no_mode, size = desire_lines$drive_base[i])] = "drive"
    desire_lines_disag$mode_baseline[is.na(desire_lines_disag$mode_baseline)] = "other"
    if(i == 1) {
      desire_lines_out = desire_lines_disag
    } else {
      desire_lines_out = rbind(desire_lines_out, desire_lines_disag)
    }
  }
  if(output_format == "sf") return(desire_lines_out)

  # create json version

  # i = 1
  # desire_lines_out = desire_lines_out %>% slice(1:3) # for testing
  n = nrow(desire_lines_out)

  start_points = lwgeom::st_startpoint(desire_lines_out) %>% sf::st_coordinates()
  end_points = lwgeom::st_endpoint(desire_lines_out) %>% sf::st_coordinates()
  Position = data.frame(
    longitude = start_points[, "X"],
    latitude = start_points[, "Y"]
  )
  origin = tibble::tibble(Position = Position)

  trips = lapply(seq(nrow(desire_lines_out)), function(i) {
    Position = data.frame(
      longitude = end_points[i, "X"],
      latitude = end_points[i, "Y"]
    )
    destination = tibble::tibble(Position = Position)
    tibble::tibble(
      departure = round(stats::rnorm(n = 1, mean = 8 * 60^2, sd = 0.5 * 60^2)),
      destination = destination,
      mode = desire_lines_out$mode_baseline[i]
    )
  })

  people = tibble::tibble(origin = origin, trips)

  json_r = list(scenario_name = "baseline", people = people)

  json_r

  # table(desire_lines_disag$mode_baseline)
  # desire_lines[i, ]
}

