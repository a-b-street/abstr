## code to prepare `leeds_od` dataset goes here

library(tidyverse)
site_name = "lcid"

sites = sf::read_sf("~/cyipt/actdev/data-small/all-sites.geojson")
site = sites[sites$site_name == site_name, ]
path = file.path("~/cyipt/actdev/data-small", site_name)
buffer_distance_m = 500 # buffer to catch residential buildings

# input data: we should probably have naming conventions for these
site_area = sf::read_sf(file.path(path, "site.geojson"))
desire_lines = sf::read_sf(file.path(path, "desire-lines-few.geojson"))	# TODO or many?
study_area = sf::read_sf(file.path(path, "small-study-area.geojson"))	# TODO or large?
# buildings = osmextract::oe_get(study_area, layer = "multipolygons")
osm_polygons = osmextract::oe_get(sf::st_centroid(study_area), layer = "multipolygons")
# mapview::mapview(study_area) +
#   mapview::mapview(osmextract::geofabrik_zones)

# from od/data-raw folder
building_types = c(
  "office",
  "industrial",
  "commercial",
  "retail",
  "warehouse",
  "civic",
  "public"
)
osm_buildigs = osm_polygons %>%
  filter(building %in% building_types)
pct_zone = pct::pct_regions[site_area %>% sf::st_centroid(), ]
zones = pct::get_pct_zones(pct_zone$region_name)
zones = pct::get_pct_zones(pct_zone$region_name, geography = "msoa")
zones_of_interest = zones[zones$geo_code %in% c(desire_lines$geo_code1, desire_lines$geo_code2), ]
buildings_in_zones = osm_buildigs[zones_of_interest, , op = sf::st_within]

if(site_name == "chapelford") {
  u = "http://abstreet.s3-website.us-east-2.amazonaws.com/dev/data/input/cheshire/procgen_houses.json.gz"
  download.file(u, "procgen_houses.json.gz")
  system("gunzip procgen_houses.json.gz")
  procgen_houses = sf::read_sf("procgen_houses.json")
}

mapview::mapview(zones_of_interest) +
  mapview::mapview(buildings_in_zones)
buildings_in_zones = buildings_in_zones %>%
  filter(!is.na(osm_way_id)) %>%
  select(osm_way_id, building)

library(sf)
if(!is.null(buffer_distance_m)) {
  site_area = stplanr::geo_buffer(site_area, dist = buffer_distance_m)
}
osm_polygons_in_site = osm_polygons[site_area, , op = sf::st_within]
osm_polygons_resi_site = osm_polygons_in_site %>%
  filter(building == "residential") %>%
  select(osm_way_id, building)

if(exists("procgen_houses")) {
  procgen_site = procgen_houses[site_area, , op = sf::st_within]
  procgen_osm = sf::st_sf(
    data.frame(
      osm_way_id = rep(NA, nrow(procgen_site)),
      building = rep(NA, nrow(procgen_site))
    ),
    geometry = procgen_site$geometry
  )
  osm_polygons_resi_site = rbind(osm_polygons_resi_site, procgen_osm)
}

mapview::mapview(osm_polygons_resi_site)

leeds_houses = osm_polygons_resi_site
leeds_buildings = buildings_in_zones
leeds_desire_lines = desire_lines
leeds_zones = zones_of_interest
leeds_site_area = site_area

usethis::use_data(leeds_houses, overwrite = TRUE)
usethis::use_data(leeds_buildings, overwrite = TRUE)
usethis::use_data(leeds_desire_lines, overwrite = TRUE)
usethis::use_data(leeds_zones, overwrite = TRUE)
usethis::use_data(leeds_site_area, overwrite = TRUE)

# loop over each desire line
i = 1
for(i in seq(nrow(desire_lines))) {
  pop = desire_lines$all_base[i]
  origins = osm_polygons_resi_site %>% sample_n(size = pop, replace = TRUE)
  destination_zone = zones_of_interest %>% filter(geo_code == desire_lines$geo_code2[i])
  destination_buildings = buildings_in_zones[destination_zone, , op = sf::st_within]
  destinations = destination_buildings %>% sample_n(size = pop, replace = TRUE)
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

  # table(desire_lines_disag$mode_baseline)
  # desire_lines[i, ]
}

mapview::mapview(desire_lines_out)

sf::write_sf(desire_lines_out, "desire_lines_out.geojson")
piggyback::pb_upload("desire_lines_out.geojson")

json = '{
  "scenario_name": "monday",
  "people": [
    {
      "origin": {
        "Position": {
          "longitude": -122.303723,
          "latitude": 47.6372834
        }
      },
      "trips": [
        {
          "departure": 10800.0,
          "destination": {
            "Position": {
              "longitude": -122.3075948,
              "latitude": 47.6394773
        }
          },
          "mode": "Drive"
        }
      ]
    },
{
      "origin": {
        "Position": {
          "longitude": -122.303723,
          "latitude": 47.6372834
        }
      },
      "trips": [
        {
          "departure": 10800.0,
          "destination": {
            "Position": {
              "longitude": -122.3075948,
              "latitude": 47.6394773
        }
          },
          "mode": "Drive"
        }
      ]
    }
  ]
}'

  json_r = jsonlite::fromJSON(json)
  str(json_r)
  jsonlite::toJSON(json_r)

  mapview::mapview(desire_lines_out)

  i = 1
  desire_lines_out = desire_lines_out %>% slice(1:3) # for testing
  names(json_r$people)
  json_r$people$origin
  json_r$people$trips[[1]]
  class(json_r$people$trips[[1]])
  n = nrow(desire_lines_out)
  people = data.frame(origin = rep(NA, n), trips = rep(NA, n))

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
    destination = tibble(Position = Position)
    tibble::tibble(
      departure = round(rnorm(n = 1, mean = 8 * 60^2, sd = 0.5 * 60^2)),
      destination = destination,
      mode = desire_lines_out$mode_baseline[i]
    )
  })

  people = tibble::tibble(origin = origin, trips)
  people$origin$Position$longitude
  people$trips[[1]]$departure
  people$trips[[3]]$departure
  json_r$people$origin$Position$longitude
  json_r$people$trips[[1]]$departure
  json_r$scenario_name

  json_r2 = list(scenario_name = "baseline", people = people)
  jsonlite::write_json(json_r2, "desire_line_out_test_3.json", pretty = TRUE)
  file.edit("desire_line_out_test_3.json")
  piggyback::pb_upload("desire_line_out_test.json")
  piggyback::pb_download_url("desire_line_out_test.json")
  piggyback::pb_download_url("desire_line_out_test_3.json")




usethis::use_data(DATASET, overwrite = TRUE)
