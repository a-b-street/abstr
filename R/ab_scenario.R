#' Generate A/B Street Scenario files/objects
#'
#' @param od Origin destination data
#' @param houses Polygons where trips will originate (`sf` object)
#' @param buildings Buildings where trips will end represented as `sf` object
#' @param desire_lines Origin-Destination data represented as `sf`
#'   objects with `LINESTRING` geometries with 2 vertices, start point and
#'   end point.
#' @param pop_var The variable containing the total population of each desire line.
#' @param zones Zones with IDs that match the desire lines and class `sf`
#' @param scenario The name of the scenario, used to match column names.
#'   `"base"` by default.
#' @param time_fun The function used to calculate departure times.
#'   `ab_time_normal()` by default.
#' @param output_format Which output format? `"sf"` (default) or `"json_list"`?
#' @param op The binary predicate used to assign `buildings` to `zones`.
#' See online documentation on binary predicates for further details, e.g.
#' [Spatial Data Science](https://keen-swartz-3146c4.netlify.app/geommanip.html)
#' @param ... Additional arguments to pass to `time_fun`
#'
#' @export
#' @examples
#' od = leeds_od
#' zones = leeds_zones
#' zones_d = leeds_zones
#' od[[1]] = c("E02006876")
#' ablines = ab_scenario(od, zones = zones)
#' plot(ablines)
#' table(ablines$mode)
#' colSums(od[3:7]) # 0.17 vs 0.05 for ab_scenario
#' origins = sf::st_centroid(leeds_buildings)
#' ablines = ab_scenario(od, zones = zones, origins = origins)
#' plot(leeds_zones$geometry)
#' plot(leeds_buildings$geometry, add = TRUE)
#' plot(ablines["mode"], add = TRUE)
#' ablines_json = ab_json(ablines)
#' # ablines = ab_scenario(
#' #   leeds_houses,
#' #   leeds_buildings,
#' #   leeds_desire_lines,
#' #   leeds_zones,
#' #   output_format = "sf"
#' # )
#' # dutch = ab_scenario(
#' #   leeds_houses,
#' #   leeds_buildings,
#' #   leeds_desire_lines,
#' #   leeds_zones,
#' #   scenario = "dutch",
#' #   output_format = "sf"
#' # )
#' # plot(ablines, key.pos = 1, reset = FALSE)
#' # plot(leeds_site_area$geometry, add = TRUE)
#' # plot(leeds_buildings$geometry, add = TRUE)
#' # plot(dutch, key.pos = 1, reset = FALSE)
#' # plot(leeds_site_area$geometry, add = TRUE)
#' # plot(leeds_buildings$geometry, add = TRUE)
#' # dutch$departure = ab_time_normal(hr = 8, sd = 0.5, n = nrow(dutch))
#' # ab_evening_dutch = ab_scenario(
#' #   leeds_houses,
#' #   leeds_buildings,
#' #   leeds_desire_lines,
#' #   leeds_zones,
#' #   scenario = "dutch",
#' #   output_format = "json_list",
#' #   hr = 20, # representing 8 pm
#' #   sd = 0
#' # )
#' # f = tempfile(fileext = ".json")
#' # ab_save(ab_evening_dutch, f)
#' # readLines(f)[13]
#' # 20 * 60^2
ab_scenario = function(
  od,
  zones,
  zones_d = NULL,
  origins = NULL,
  destinations1 = NULL,
  destinations2 = NULL,
  pop_var = 3,
  time_fun = ab_time_normal,
  output_format = "sf",
  op = sf::st_intersects,
  modes = c("Walk", "Bike", "Drive", "Transit"),
  ...
) {
  if(methods::is(od, class2 = "sf")) {
    od = sf::st_drop_geometry(od)
  }
  # minimise n. columns:
  od = od[c(names(od)[1:2], modes)]
  od_long = tidyr::pivot_longer(od, cols = modes, names_to = "mode")
  repeat_indices = rep(seq(nrow(od_long)), od_long$value)
  od_longer = od_long[repeat_indices, 1:3]
  # summary(od_longer$geo_code1 %in% zones$geo_code)
  od::od_jitter(od = od_longer, z = zones, subpoints = origins, subpoints_d = destinations1)

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
#' @param scenario_name The name of the scenario to appear in A/B Street
#' @inheritParams ab_scenario
#'
#' @return A list that can be saved as a JSON file with [ab_save()]
#' @export
#'
#' @examples
#' ablines = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   leeds_desire_lines,
#'   leeds_zones,
#'   output_format = "sf"
#' )
#' ab_list = ab_json(ablines, mode_column = "mode_base")
#' ab_list$scenario
#' ab_list$people$trips[[1]]
#' dutch = ab_scenario(
#'   leeds_houses,
#'   leeds_buildings,
#'   leeds_desire_lines,
#'   leeds_zones,
#'   scenario = "godutch",
#'   output_format = "sf"
#' )
#' ab_list = ab_json(dutch, mode_column = "mode_godutch")
#' ab_list$scenario
#' str(ab_list$people$trips[[9]])
#' # add times
#' dutch$departure = ab_time_normal(hr = 1, sd = 0, n = nrow(dutch))
#' ab_list_times = ab_json(dutch)
#' str(ab_list_times$people$trips[[9]])
#' f = tempfile(fileext = ".json")
#' ab_save(ab_list_times, f)
#' readLines(f)[1:30]
#' 60^2
ab_json = function(
  desire_lines_out,
  mode_column = NULL,
  time_fun = ab_time_normal,
  scenario_name = NULL,
  ...
  ) {

  if(is.null(mode_column)) {
    mode_column = names(desire_lines_out)[1]
  }
  n = nrow(desire_lines_out)

  if(is.null(desire_lines_out$departure)) {
    desire_lines_out$departure = time_fun(n = n, ...)
  }

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
      departure = desire_lines_out$departure[i],
      destination = destination,
      mode = desire_lines_out[[mode_column]][i],
      # Other values at
      # https://a-b-street.github.io/abstreet/rustdoc/sim/enum.TripPurpose.html.
      # The simulation doesn't make use of this yet.
      purpose = "Shopping"
    )
  })

  people = tibble::tibble(origin = origin, trips)

  if(is.null(scenario_name)) {
    scenario_name = gsub(pattern = "mode_", replacement = "", x = mode_column)
  }

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

#' Generate times for A/B scenarios
#'
#' @return An integer representing the time since midnight in seconds
#'
#' @param hr Number representing the hour of day of departure (on average).
#'   8.5, for example represents 08:30.
#' @param sd The standard deviation in hours of the distribution
#' @param n The number of numbers representing times to return
#'
#' @export
#' @examples
#' time_lunch = ab_time_normal(hr = 12.5, sd = 0.25)
#' time_lunch
#' # Back to a formal time class
#' as.POSIXct(trunc(Sys.time(), units="days") + time_lunch)
#' time_morning = ab_time_normal(hr = 8.5, sd = 0.5)
#' as.POSIXct(trunc(Sys.time(), units="days") + time_morning)
#' time_afternoon = ab_time_normal(hr = 17, sd = 0.75)
#' as.POSIXct(trunc(Sys.time(), units="days") + time_afternoon)
ab_time_normal = function(hr = 8.5, sd = 0.5, n = 1) {
  round(stats::rnorm(n = n, mean = hr * 60^2, sd = sd * 60^2))
}

# cnames = names(leeds_desire_lines)
match_scenario_mode = function(cnames, scenario = "base", mode = "Walk") {
  cnames_match_scenario = grepl(pattern = scenario, x = cnames, ignore.case = TRUE)
  cnames_match_mode = grepl(pattern = mode, x = cnames, ignore.case = TRUE)
  cname_matching = cnames[cnames_match_scenario & cnames_match_mode]
  # todo: add warning message if there's more than 1 (RL 2020-02-10)?
  cname_matching
}
