#' Generate A/B Street Scenario objects by disaggregating aggregate OD data
#'
#' This function takes a data frame representing origin-destination trip data
#' in 'long' form, zones and, optionally, buildings from where trips can
#' start and end as inputs.
#'
#' It returns an `sf` object by default representing individual trips
#' between randomly selected points (or buildings when available)
#' between the zones represented in the OD data.
#'
#' @param od Origin destination data with the first 2 columns containing
#'   zone code of origin and zone code of destination. Subsequent
#'   columns should be mode names such as All and Walk, Bike, Transit, Drive,
#'   representing the number of trips made by each mode of transport
#'   for use in A/B Street.
#' @param zones Pologons containing an id column that match the `od` data. Class: `sf`.
#' @param buildings Polygons where trips will originate or end (`sf` object)
#' @param scenario_name Character describing the scenario being created.
#' @param time_fun The function used to calculate departure times.
#'   `ab_time_normal()` by default.
#' @param output Which output format?
#'   `"sf"` (default) and `"json_list"` return R objects.
#'   `"json_file"` will save a .json file for the scenario based on the `scenario_name`.
#' @param modes The modes of travel to include,
#'   `c("Walk", "Bike", "Drive", "Transit")` by default.
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
#' # ablines = ab_scenario(
#' #   leeds_houses,
#' #   leeds_buildings,
#' #   leeds_desire_lines,
#' #   leeds_zones,
#' #   output = "sf"
#' # )
#' # plot(ablines, key.pos = 1, reset = FALSE)
#' # plot(leeds_site_area$geometry, add = TRUE)
#' # plot(leeds_buildings$geometry, add = TRUE)
#' # plot(dutch, key.pos = 1, reset = FALSE)
ab_scenario = function(
  od,
  zones,
  buildings = NULL,
  scenario_name,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("Walk", "Bike", "Drive", "Transit"),
  ...
) {
  if(methods::is(od, class2 = "sf")) {
    od = sf::st_drop_geometry(od)
  }
  # minimize n. columns:
  od = od[c(names(od)[1:2], modes)]
  od_long = tidyr::pivot_longer(od, cols = dplyr::all_of(modes), names_to = "mode")
  repeat_indices = rep(seq(nrow(od_long)), od_long$value)
  od_longer = od_long[repeat_indices, 1:3]
  # summary(od_longer$geo_code1 %in% zones$geo_code)
  if(!is.null(buildings)) {
    suppressMessages({
      buildings_centroids = sf::st_centroid(buildings)
    })
  }
  # if no buildings are provided, jitter within each zone
  # if buildings are provided then randomly select across buildings in each zone
  if (is.null(buildings)) {
    res = od::od_jitter(
      od = od_longer,
      z = zones,
      subpoints = buildings_centroids,
      subpoints_d = NULL
    )
  } else {
    # group buildings by zone
    zones_tbl <- dplyr::right_join(zones, tibble::tibble("id" = unique(c(od_longer[[1]], od_longer[[2]]))) , by = "id")
    zones_tbl[["buildings"]] <- lapply(zones_tbl$geometry, function(x) {
      buildings_centroids[sf::st_intersects(buildings_centroids, sf::st_sf(geometry = sf::st_sfc(x), crs = sf::st_crs(zones_tbl)), sparse = F),]
    })

    # for each trip pick a random building in the origin and destination zones and record a
    # desire line between them
    res <- mapply(function(origin, dest, mode) {
      origin_tbl <- zones_tbl[match(origin, zones_tbl$id),]$buildings[[1]]
      dest_tbl <- zones_tbl[match(dest, zones_tbl$id),]$buildings[[1]]
      if ((nrow(origin_tbl) > 0) & (nrow(dest_tbl) > 0)) {
        origin_coords <- as.data.frame(sf::st_coordinates(origin_tbl[sample(1:nrow(origin_tbl), 1),]))
        dest_coords <- as.data.frame(sf::st_coordinates(dest_tbl[sample(1:nrow(dest_tbl), 1),]))
        return_tbl <- dplyr::bind_rows(sf::st_as_sf(origin_coords, coords = c("X", "Y"), crs = sf::st_crs(zones_tbl)),
                                       sf::st_as_sf(dest_coords, coords = c("X", "Y"), crs = sf::st_crs(zones_tbl))) %>%
          dplyr::mutate(group = 1) %>%
          dplyr::group_by(group) %>%
          dplyr::summarise() %>%
          sf::st_cast("LINESTRING") %>%
          dplyr::select(-group) %>%
          dplyr::mutate(o_id = origin, d_id = dest, mode = mode)
      } else {
        return_tbl <- NULL
      }
    }, origin = od_longer$o_id, dest = od_longer$d_id, mode = od_longer$mode, SIMPLIFY = F) %>%
      dplyr::bind_rows() %>%
      dplyr::select(o_id, d_id, mode, geometry)
  }

  if(output == "sf") {
    return(res)
  } else if(output == "json_list") {
    return(ab_json(res, time_fun = time_fun, scenario_name = scenario_name, ...))
  } else if (output == "json_file") {
    ab_save(ab_json(res, time_fun = time_fun, scenario_name = scenario_name, ...),
            f = paste0(scenario_name, ".json"))
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
#' @param scenario_name The name of the scenario to appear in A/B Street
#' @inheritParams ab_scenario
#'
#' @return A list that can be saved as a JSON file with [ab_save()]
#' @export
#'
#' @examples
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
#' # Legacy code from ActDev project commented out
#' # ab_list$people$trips[[1]]
#' # dutch = ab_scenario(
#' #   leeds_houses,
#' #   leeds_buildings,
#' #   leeds_desire_lines,
#' #   leeds_zones,
#' #   scenario = "godutch",
#' #   output = "sf"
#' # )
#' # ab_list = ab_json(dutch, mode_column = "mode_godutch")
#' # ab_list$scenario
#' # str(ab_list$people$trips[[9]])
#' # # add times
#' # dutch$departure = ab_time_normal(hr = 1, sd = 0, n = nrow(dutch))
#' # ab_list_times = ab_json(dutch)
#' # str(ab_list_times$people$trips[[9]])
#' # ab_save(ab_list_times, f)
#' # readLines(f)[1:30]
#' # 60^2
ab_json = function(
  desire_lines_out,
  mode_column = NULL,
  time_fun = ab_time_normal,
  scenario_name,
  ...
  ) {

  if(is.null(mode_column)) {
    mode_column = "mode"
  }
  n = nrow(desire_lines_out)

  if(is.null(desire_lines_out$departure)) {
    desire_lines_out$departure = time_fun(n = n, ...)
  }

  start_points = lwgeom::st_startpoint(desire_lines_out) %>% sf::st_coordinates()
  end_points = lwgeom::st_endpoint(desire_lines_out) %>% sf::st_coordinates()


  trips = lapply(seq(nrow(desire_lines_out)), function(i) {
    Position_origin = data.frame(
      longitude = start_points[i, "X"],
      latitude = start_points[i, "Y"]
    )
    Position_destination = data.frame(
      longitude = end_points[i, "X"],
      latitude = end_points[i, "Y"]
    )
    origin = tibble::tibble(Position = Position_origin)
    destination = tibble::tibble(Position = Position_destination)
    tibble::tibble(
      departure = desire_lines_out$departure[i],
      origin = origin,
      destination = destination,
      mode = desire_lines_out[[mode_column]][i],
      # Other values at
      # https://a-b-street.github.io/abstreet/rustdoc/sim/enum.TripPurpose.html.
      # The simulation doesn't make use of this yet.
      purpose = "Shopping"
    )
  })

  people = tibble::tibble(trips)

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
