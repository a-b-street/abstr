# Aim: generate a minimal dataset corresponding to a minimal example scenario
json = jsonlite::read_json("inst/extdata/minimal_scenario2.json")
json_df = jsonlite::read_json("inst/extdata/minimal_scenario.json", simplifyVector = TRUE)
# Try importing the data into abstreet
json_df$people$trips[[1]]
data.table::rbindlist(json_df$people$trips)
trip_data = dplyr::bind_rows(json_df$people$trips, .id = "id")

# code below could be generalised to a json_to_sf() function
linestrings = od::odc_to_sf(cbind(
  trip_data$origin$Position$longitude,
  trip_data$origin$Position$latitude,
  trip_data$destination$Position$longitude,
  trip_data$destination$Position$latitude
))
mapview::mapview(linestrings)
od::odc_to_sf()
sf_data =
sf_linestring = sf::st_sf(

)

