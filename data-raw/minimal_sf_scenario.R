# Aim: generate a minimal dataset corresponding to a minimal example scenario

json_df = jsonlite::read_json("inst/extdata/minimal_scenario2.json", simplifyVector = TRUE)
json_df$scenario_name
# Try importing the data into abstreet
json_df$people$trips[[1]]
trip_data = dplyr::bind_rows(json_df$people$trips, .id = "person")
trip_data
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
# in bash
# diff test.json inst/extdata/minimal_scenario2.json
# file.edit("test.json") # in early versions, each trip was treated as a new person...

json3 = jsonlite::toJSON(json_df)
unclass(json3)
class(.Last.value) # character
json4 = jsonlite::serializeJSON(x = json_df)
class(json4)
unclass(json4)
