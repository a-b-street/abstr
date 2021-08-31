
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
  desire_lines_out$departure = desire_lines_out$departure * 10000.0

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

  if(is.null(scenario_name)) {
    scenario_name = gsub(pattern = "mode_", replacement = "", x = mode_column)
  }

  json_r = list(scenario_name = scenario_name, people = people)
  json_r
}
