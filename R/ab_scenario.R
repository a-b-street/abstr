#' Generate A/B Street Scenario objects by disaggregating aggregate OD data
#'
#' This function takes a data frame representing origin-destination trip data
#' in 'long' form, zones and, optionally, buildings from where trips can
#' start and end as inputs.
#'
#' @return An `sf` object by default representing individual trips
#' between randomly selected points (or buildings when available)
#' between the zones represented in the OD data.
#'
#' @param od Origin destination data with the first 2 columns containing
#'   zone code of origin and zone code of destination. Subsequent
#'   columns should be mode names such as All and Walk, Bike, Transit, Drive,
#'   representing the number of trips made by each mode of transport
#'   for use in A/B Street.
#' @param zones Zones with IDs that match the desire lines. Class: `sf`.
#' @param zones_d Optional destination zones with IDs
#'   that match the second column of the `od` data frame (work in progress)
#' @param origin_buildings Polygons where trips will originate (`sf` object)
#' @param destination_buildings Polygons where trips can end, represented as `sf` object
#' @param pop_var The variable containing the total population of each desire line.
#' @param time_fun The function used to calculate departure times.
#'   `ab_time_normal()` by default.
#' @param output Which output format?
#'   `"sf"` (default) and `"json_list"` return R objects.
#'   A file name such as `"baseline.json"` will save the resulting scenario
#'   to a file.
#' @param modes Character string containing the names of the modes of travel to
#'   include in the outputs. These must match column names in the `od` input
#'   data frame. The default is `c("Walk", "Bike", "Drive", "Transit")`,
#'   matching the mode names allowed in the A/B Street scenario schema.
#' @param ... Additional arguments to pass to [ab_json()]
#'
#' @export
#' @examples
#' od = leeds_od
#' zones = leeds_zones
#' od[[1]] = c("E02006876")
#' ablines = ab_scenario(od, zones = zones)
#' plot(ablines)
#' table(ablines$mode)
#' colSums(od[3:7]) # 0.17 vs 0.05 for ab_scenario
#' ablines = ab_scenario(od, zones = zones, origin_buildings = leeds_buildings)
#' plot(leeds_zones$geometry)
#' plot(leeds_buildings$geometry, add = TRUE)
#' plot(ablines["mode"], add = TRUE)
#' ablines_json = ab_json(ablines, scenario_name = "test")
#' od = leeds_desire_lines
#' names(od)[4:6] = c("Walk", "Bike", "Drive")
#' ablines = ab_scenario(
#'   od = od,
#'   zones = leeds_site_area,
#'   zones_d = leeds_zones,
#'   origin_buildings = leeds_houses,
#'   destination_buildings = leeds_buildings,
#'   output = "sf"
#' )
#' plot(ablines)
#' plot(ablines$geometry)
#' plot(leeds_site_area$geometry, add = TRUE)
#' plot(leeds_buildings$geometry, add = TRUE)
ab_scenario = function(
  od,
  zones,
  zones_d = NULL,
  origin_buildings = NULL,
  destination_buildings = NULL,
  # destinations2 = NULL,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("Walk", "Bike", "Transit", "Drive"),
  ...
) {

  # Checks: defensive programming
  if(methods::is(od, class2 = "sf")) {
    od = sf::st_drop_geometry(od)
  }
  if(!any(modes %in% names(od))) {
    message("Column names, at least on of: ", paste0(modes, collapse = ", "))
    message("Column names in od object: ", paste0(names(od), collapse = ", "))
    stop("Column names in od data do not match modes. Try renaming od columns")
  }
  # minimise n. columns:
  modes_in_od = modes[modes %in% names(od)]
  od = od[c(names(od)[1:2], modes_in_od)]
  od_long = tidyr::pivot_longer(od, cols = modes_in_od, names_to = "mode")
  repeat_indices = rep(seq(nrow(od_long)), od_long$value)
  od_longer = od_long[repeat_indices, 1:3]
  # summary(od_longer$geo_code1 %in% zones$geo_code)
  if(!is.null(origin_buildings)) {
    suppressMessages({
      origin_buildings = sf::st_centroid(origin_buildings)
    })
  }
  if(!is.null(destination_buildings)) {
    suppressMessages({
      destination_buildings = sf::st_centroid(destination_buildings)
    })
  }
  if(utils::packageVersion("od") < "0.4.0") {
    res = od::od_jitter(
    od = od_longer,
    z = zones,
    zd = zones_d,
    subpoints_o = origin_buildings,
    subpoints_d = destination_buildings
    )
  } else {
    res = od::od_jitter(
    od = od_longer,
    z = zones,
    zd = zones_d,
    subpoints_o = origin_buildings,
    subpoints_d = destination_buildings,
    disag = FALSE
    )
  }
  

  if(output == "sf") {
    return(res)
  } else if(output == "json_list") {
    return(ab_json(res, time_fun = time_fun, ...))
  } else {
    ab_save(ab_json(res, time_fun = time_fun, ...), f = output)
  }

}

#' Convert geographic ('sf') representation of OD data to 'JSON list' structure
#'
#' This function takes outputs from [ab_scenario()] and returns a list that
#' can be saved as a JSON file for import into A/B Street.
#'
#' Note: the departure time in seconds is multiplied by 10000 on conversion
#' to a .json list object for compatibility with the A/B Street schema.
#'
#' @param desire_lines OD data represented as geographic lines created by
#'   [ab_scenario()].
#' @param mode_column The column name in the desire lines data that contains
#'   the mode of transport. `"mode_baseline"` by default.
#' @param scenario_name The name of the scenario to appear in A/B Street.
#'   The default value is `"test"`, which generates a message to tell you to
#'   think of a more imaginative scenario name!
#' @param default_purpose In case a `purpose` column is not present in the input,
#'   or there are missing values in the `purpose` column, this argument sets
#'   the default, fallback purpose, as `"Work"` by default, reflecting the
#'   prevalence of work-based data and thinking in transport models.
#' @inheritParams ab_scenario
#'
#' @return A list that can be saved as a JSON file with [ab_save()]
#' @export
#'
#' @examples
#' # Starting with tabular data
#' od = leeds_od
#' od[[1]] = c("E02006876")
#' zones = leeds_zones
#' ablines = ab_scenario(od, zones = zones)
#' ab_list = ab_json(ablines, mode_column = "mode", scenario_name = "test")
#' ab_list$scenario
#' f = tempfile(fileext = ".json")
#' ab_save(ab_list, f)
#' readLines(f)[1:30]
#'
#' # Starting with JSON data from A/B Street (multiple trips per person)
#' f = system.file("extdata/minimal_scenario2.json", package = "abstr")
#' desire_lines = ab_sf(f)
#' desire_lines
#' json_list = ab_json(desire_lines)
#' json_list
ab_json = function(
  desire_lines,
  mode_column = NULL,
  time_fun = ab_time_normal,
  scenario_name = "test",
  default_purpose = "Work",
  ...
  ) {

  if(scenario_name == "test") {
    message("Default scenario name of 'test' used.")
  }

  if(is.null(mode_column)) {
    mode_column = "mode"
  }
  n = nrow(desire_lines)

  if(is.null(desire_lines$departure)) {
    desire_lines$departure = time_fun(n = n, ...)
  }

  # Do not multiply by 10k if the maximum number is already greater than 7 days
  if(max(desire_lines$departure) > 7 * 24 * 60 * 60) {
    stop(
      "Values greater than 604800 found in the input for departure timesT Try:\n",
      "desire_lines$departure = desire_lines$departure / 10000 \n",
      "if the original input was in 10,000th of a second (used internally by A/B Street)"
      )
  }
  desire_lines$departure = round(desire_lines$departure * 10000)

  start_points = lwgeom::st_startpoint(desire_lines) %>% sf::st_coordinates()
  end_points = lwgeom::st_endpoint(desire_lines) %>% sf::st_coordinates()
  colnames(start_points) = c("ox", "oy")
  colnames(end_points) = c("dx", "dy")


  ddf = cbind(
    sf::st_drop_geometry(desire_lines),
    start_points,
    end_points
  )
  if(is.null(desire_lines$person)) {
    ddf$person = seq(nrow(desire_lines))
  }
  if(is.null(desire_lines$purpose)) {
    ddf$purpose = default_purpose
  }
  # Base R approach (tried tidyverse briefly to no avail)
  people = lapply(unique(ddf$person), function(p) {
    ddfp = ddf[ddf$person == p, ]
    # trips = list(origin = list(Position = list(longitude = 1)))
    list(
      trips = lapply(seq(nrow(ddfp)), function(i) {
        list(
          departure = ddfp$departure[i],
          origin = list(Position = list(
            longitude = ddfp$ox[i],
            latitude = ddfp$oy[i]
          )),
          destination = list(Position = list(
            longitude = ddfp$dx[i],
            latitude = ddfp$dy[i]
          )),
          mode = ddfp$mode[i],
          purpose = ddfp$purpose[i]
        )
      } )
    )
  } )

  if(is.null(scenario_name)) {
    scenario_name = gsub(pattern = "mode_", replacement = "", x = mode_column)
  }

  json_r = list(scenario_name = scenario_name, people = people)
  json_r
}

#' Convert JSON representation of trips from A/B Street into an 'sf' object
#'
#' This function takes a path to a JSON file representing an A/B Street
#' scenario, or an R representation of the JSON in a list, and returns
#' an `sf` object with the same structure as objects returned by
#' [ab_scenario()].
#'
#' Note: the departure time in seconds is divided by 10000 on conversion
#' to represent seconds, which are easier to work with that 10,000th of
#' a second units.
#'
#' @param json Character string or list representing a JSON file or list that
#'   has been read into R and converted to a data frame.
#'
#' @return An `sf` data frame representing travel behaviour scenarios
#'   from, and which can be fed into, A/B Street. Contains the following
#'   columns: person (the ID of each agent in the simulation),
#'   departure (seconds after midnight of the travel starting),
#'   mode (the mode of transport, being `Walk`, `Bike`, `Transit` and `Drive`),
#'   purpose (what the trip was for, e.g. `Work`), and
#'   geometry (a linestring showing the start and end point of the trip/stage).
#' @export
#' @examples
#' file_name = system.file("extdata/minimal_scenario2.json", package = "abstr")
#' ab_sf(file_name)
#' json = jsonlite::read_json(file_name, simplifyVector = TRUE)
#' ab_sf(json)
ab_sf = function(
  json
) {

  if(is.character(json))  {
    json = jsonlite::read_json(json, simplifyVector = TRUE)
  }

  trip_data = dplyr::bind_rows(json$people$trips, .id = "person")
  linestrings = od::odc_to_sfc(cbind(
    trip_data$origin$Position$longitude,
    trip_data$origin$Position$latitude,
    trip_data$destination$Position$longitude,
    trip_data$destination$Position$latitude
  ))
  sf_data = subset(trip_data, select = -c(origin, destination))
  sf_linestring = sf::st_sf(
    sf_data,
    geometry = linestrings,
    crs = 4326
  )
  # Give departure time more user friendly units:
  sf_linestring$departure = sf_linestring$departure / 10000
  sf_linestring
}



#' Save OD data as JSON files for import into A/B Street
#'
#' @return A JSON file containing scenarios from ab_scenario()
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

globalVariables(names = c("origin", "destination"))
