#' Generate A/B Street Scenario files/objects
#'
#' @param houses Polygons where trips will originate (`sf` object)
#' @param buildings Buildings where trips will end represented as `sf` object
#' @param desire_lines Origin-Destination data represented as `sf`
#'   objects with `LINESTRING` geometries with 2 vertices, start point and
#'   end point.
#' @param zones Zones with IDs that match the desire lines and class `sf`
#' @param scenario The name of the scenario, used to match column names.
#'   `"base"` by default.
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
#' ablines_dutch = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   dslines,
#'   leeds_zones,
#'   scenario = "dutch",
#'   output_format = "sf"
#' )
#' library(sf)
#' plot(ablines["mode_base"], key.pos = 1, reset = FALSE)
#' plot(dslines$geometry, lwd = dslines[[3]] / 30, add = TRUE)
#' plot(leeds_site_area$geometry, add = TRUE)
#' plot(leeds_buildings$geometry, add = TRUE)
#' plot(ablines_dutch["mode_dutch"], key.pos = 1)
ab_scenario = function(houses, buildings, desire_lines, zones, scenario = "base", output_format = "sf") {

  requireNamespace("sf", quietly = TRUE)

  # loop over each desire line
  i = 1
  for(i in seq(nrow(desire_lines))) {
    # todo: allow the user to choose the 'pop var' or document (RL 2020-02-10)
    pop = desire_lines$all_base[i]
    cnames = names(desire_lines)

    # todo: split out the lines to odc_to_sf as function? (RL 2020-02-10)
    origins = houses %>% dplyr::sample_n(size = pop, replace = TRUE)
    destination_zone = zones %>% dplyr::filter(geo_code == desire_lines$geo_code2[i])
    destination_buildings = buildings[destination_zone, , op = sf::st_within]
    destinations = destination_buildings %>% dplyr::sample_n(size = pop, replace = TRUE)
    origin_coords = origins %>% sf::st_centroid() %>% sf::st_coordinates()
    destination_coords = destinations %>% sf::st_centroid() %>% sf::st_coordinates()
    desire_lines_disag = od::odc_to_sf(odc = cbind(origin_coords, destination_coords))

    # todo: Allow multiple scenarios to be calculated here? (RL 2020-02-10)
    mode_cname = paste0("mode_", scenario)
    desire_lines_disag[[mode_cname]] = NA
    n_walk = desire_lines[[match_scenario_mode(cnames, scenario, mode = "Walk")]][i]
    n_bike = desire_lines[[match_scenario_mode(cnames, scenario, mode = "Bike|cycle")]][i]
    n_drive = desire_lines[[match_scenario_mode(cnames, scenario, mode = "car_d|drive")]][i]
    if(any(grepl(pattern = "transit|bus|rail", x = cnames))) {
      n_transit = desire_lines[[match_scenario_mode(cnames, scenario, mode = "transit|bus|rail")]][i]
    } else {
      n_transit = 0
    }

    # fix edge cases where n. people travelling by modes do not match population
    # todo: update input data (RL)
    n_mismatch = nrow(desire_lines_disag) -  sum(n_walk, n_bike, n_drive, n_transit)
    if(n_mismatch != 0) {
      warning("Mismatch between n. trips and population. Check your data")
      n_walk = n_walk + n_mismatch
    }

    # todo: update this next line? (RL)
    desire_lines_disag[[mode_cname]][sample(nrow(desire_lines_disag), size = n_walk)] = "Walk"
    no_mode = which(is.na(desire_lines_disag[[mode_cname]]))
    desire_lines_disag[[mode_cname]][sample(no_mode, size = n_bike)] = "Bike"
    no_mode = which(is.na(desire_lines_disag[[mode_cname]]))
    desire_lines_disag[[mode_cname]][sample(no_mode, size = n_drive)] = "Drive"
    # Other modes include taking public transit and being a passenger in a car. A/B Street doesn't
    # model the latter, so for now map all of these to transit. Also note that bus routes are mostly
    # not imported yet, so transit trips will wind up walking.
    desire_lines_disag[[mode_cname]][is.na(desire_lines_disag[[mode_cname]])] = "Transit"
    if(i == 1) {
      desire_lines_out = desire_lines_disag
    } else {
      desire_lines_out = rbind(desire_lines_out, desire_lines_disag)
    }
  }
  if(output_format == "sf") {
    return(desire_lines_out)
  } else {
    return(ab_sf_to_json(desire_lines_out))
  }
}

#' Convert geographic ('sf') representation of OD data to 'JSON list' structure
#'
#' This function takes outputs from [ab_scenario()] and returns a list that
#' can be saved as a JSON file for import into A/B Street.
#'
#' @param desire_lines_out OD data represented as geographic lines created by
#'   [ab_scenario()].
#' @param mode_column The column name in the desire lines data that contains
#'   the mode of transport. `"mode_baseline"` by default.
#'
#' @return A list that can be saved as a JSON file with [ab_save()]
#' @export
#'
#' @examples
#' library(sf) # for subsetting lines
#' ablines = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   leeds_desire_lines[7, ],
#'   leeds_zones,
#'   output_format = "sf"
#' )
#' ab_list = ab_sf_to_json(ablines, mode_column = "mode_base")
#' ab_list$scenario
#' ab_list$people$trips[[1]]
#' ablines_dutch = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   leeds_desire_lines[7, ],
#'   leeds_zones,
#'   scenario = "godutch",
#'   output_format = "sf"
#' )
#' ab_list = ab_sf_to_json(ablines_dutch, mode_column = "mode_godutch")
#' ab_list$scenario
#' ab_list$people$trips[[9]]
ab_sf_to_json = function(desire_lines_out, mode_column = "mode_base") {
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
      mode = desire_lines_out[[mode_column]][i]
    )
  })

  people = tibble::tibble(origin = origin, trips)

  scenario_name = gsub(pattern = "mode_", replacement = "", x = mode_column)
  json_r = list(scenario_name = scenario_name, people = people)

  json_r
}

#' Save OD data as JSON files for import into A/B Street
#'
#' Save scenarios with this function
#'
#' @param x A list object produced by [ab_scenario()]
#' @param f A filename, e.g. `new_scenario.json`
#' @export
ab_save = function(x, f) {
  jsonlite::write_json(x, f, pretty = TRUE, auto_unbox = TRUE)
}

# cnames = names(leeds_desire_lines)
match_scenario_mode = function(cnames, scenario = "base", mode = "Walk") {
  cnames_match_scenario = grepl(pattern = scenario, x = cnames, ignore.case = TRUE)
  cnames_match_mode = grepl(pattern = mode, x = cnames, ignore.case = TRUE)
  cname_matching = cnames[cnames_match_scenario & cnames_match_mode]
  # todo: add warning message if there's more than 1 (RL 2020-02-10)?
  cname_matching
}
