# Aim: generate a minimal dataset corresponding to a minimal example scenario

json = jsonlite::read_json("inst/extdata/minimal_scenario2.json")
json$scenario_name
json_df = jsonlite::read_json("inst/extdata/minimal_scenario2.json", simplifyVector = TRUE)
# Try importing the data into abstreet
json_df$people$trips[[1]]
trip_data = dplyr::bind_rows(json_df$people$trips, .id = "id")
trip_data
# unhelpful flat format
# trip_data_unnested = tidyr::unnest(trip_data, cols = c(origin, destination))
names(trip_data)

# code below could be generalised to a json_to_sf() function
linestrings = od::odc_to_sfc(cbind(
  trip_data$origin$Position$longitude,
  trip_data$origin$Position$latitude,
  trip_data$destination$Position$longitude,
  trip_data$destination$Position$latitude
))
# mapview::mapview(linestrings)


sf_data = subset(trip_data, select = -c(origin, destination))
sf_linestring = sf::st_sf(
  sf_data,
  geometry = linestrings
)

plot(sf_linestring)

json2 = ab_json(desire_lines_out = sf_linestring, scenario_name = "minimal2")
identical(json, json2)
waldo::compare(json, json2)

ab_save(json2, "test.json")
waldo::compare(readLines("test.json"), readLines("inst/extdata/minimal_scenario2.json"))

json3 = jsonlite::toJSON(json_df)
unclass(json3)
class(.Last.value) # character
json4 = jsonlite::serializeJSON(x = json_df)
class(json4)
unclass(json4)
