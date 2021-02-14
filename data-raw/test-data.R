## code to prepare `leeds_od` dataset goes here

library(tidyverse)
site_name = "lcid"

# see https://github.com/cyipt/actdev
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

summary(desire_lines)

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
osm_buildings = osm_polygons %>%
  filter(building %in% building_types)
pct_zone = pct::pct_regions[site_area %>% sf::st_centroid(), ]
zones = pct::get_pct_zones(pct_zone$region_name)
zones = pct::get_pct_zones(pct_zone$region_name, geography = "msoa")
zones_of_interest = zones[zones$geo_code %in% c(desire_lines$geo_code1, desire_lines$geo_code2), ] %>%
  select(1:10)
buildings_in_zones = osm_buildings[zones_of_interest, , op = sf::st_within]

mapview::mapview(zones_of_interest) +
  mapview::mapview(buildings_in_zones)
buildings_in_zones = buildings_in_zones %>%
  filter(!is.na(osm_way_id)) %>%
  select(osm_way_id, building)

osm_polygons_in_site = osm_polygons[site_area, , op = sf::st_within]
nrow(osm_polygons_in_site)
osm_polygons_resi_site = osm_polygons_in_site %>%
  # filter(building == "residential") %>%
  select(osm_way_id, building)
nrow(osm_polygons_resi_site)

mapview::mapview(osm_polygons_resi_site) +
  site_area +
  zones_of_interest +
  buildings_in_zones

# # sanity check scenario data
summary(desire_lines)
sum(desire_lines$trimode_base)
sum(desire_lines$walk_base, desire_lines$cycle_base, desire_lines$drive_base)
sum(desire_lines$walk_godutch, desire_lines$cycle_godutch, desire_lines$drive_godutch)

leeds_desire_lines = desire_lines %>%
  select(geo_code1, geo_code2, all_base = trimode_base, walk_base:drive_godutch) %>%
  slice(1:3)
leeds_houses = osm_polygons_resi_site
leeds_buildings = buildings_in_zones
leeds_zones = zones_of_interest
leeds_site_area = site_area

usethis::use_data(leeds_houses, overwrite = TRUE)
usethis::use_data(leeds_buildings, overwrite = TRUE)
usethis::use_data(leeds_desire_lines, overwrite = TRUE)
usethis::use_data(leeds_zones, overwrite = TRUE)
usethis::use_data(leeds_site_area, overwrite = TRUE)

ablines = ab_scenario(
  houses = leeds_houses,
  buildings = leeds_buildings,
  desire_lines = leeds_desire_lines,
  zones = leeds_zones,
  scenario = "base",
  output_format = "sf"
)
plot(ablines)
plot(leeds_desire_lines$geometry, lwd = leeds_desire_lines[[3]] / 5)
plot(leeds_site_area$geometry, add = TRUE)
plot(leeds_buildings$geometry, add = TRUE)
plot(ablines, add = TRUE)

ablines = ab_scenario(
  houses = leeds_houses,
  buildings = leeds_buildings,
  desire_lines = leeds_desire_lines,
  zones = leeds_zones,
  scenario = "godutch",
  output_format = "sf"
)
plot(ablines)


mapview::mapview(leeds_desire_lines)

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
