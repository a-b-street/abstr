library(pct)
library(sf)
library(tidyverse)
library(abstr)
# Get zones
devon_zones = pct::get_pct_zones(region = "devon", geography = "msoa")
exeter_zones = devon_zones %>% filter(lad_name == "Exeter") %>% select(geo_code)
# Get od data
devon_od = pct::get_od(region = "devon", )
exeter_od = devon_od %>% filter(la_1 == "Exeter" & la_2 == "Exeter")

# Transform od data to abstr format
exeter_od$Transit = apply(( exeter_od[ , c(5,6,7) ]), 1 ,sum ) # calculate transit (light_rail + train + bus)
exeter_od$Drive = apply(( exeter_od[ , c(8,9,10,11) ]), 1 ,sum ) # calculate drive (motobike, taxi, car driver, car passenger)

exeter_od = exeter_od %>%
  mutate(Bike = bicycle) %>%
  mutate(All = all) %>%
  mutate(Walk = foot) %>%
  select(geo_code1,geo_code2,All,Bike,Transit, Drive, Walk)

# Generate buildings
osm_polygons = osmextract::oe_read(
  "https://download.geofabrik.de/europe/great-britain/england/devon-latest.osm.pbf",
  layer = "multipolygons"
)

building_types = c(
  "yes",
  "house",
  "detached",
  "residential",
  "apartments",
  "commercial",
  "retail",
  "school",
  "industrial",
  "semidetached_house",
  "church",
  "hangar",
  "mobile_home",
  "warehouse",
  "office",
  "college",
  "university",
  "public",
  "garages",
  "cabin",
  "hospital",
  "dormitory",
  "hotel",
  "service",
  "parking",
  "manufactured",
  "civic",
  "farm",
  "manufacturing",
  "floating_home",
  "government",
  "bungalow",
  "transportation",
  "motel",
  "manufacture",
  "kindergarten",
  "house_boat",
  "sports_centre"
)
osm_buildings  = osm_polygons %>%
  dplyr::filter(building %in% building_types) %>%
  dplyr::select(osm_way_id, name, building)

osm_buildings_valid = osm_buildings[sf::st_is_valid(osm_buildings), ]

exeter_osm_buildings_all = osm_buildings_valid[exeter_zones, ]

#mapview(exeter_osm_buildings_all)

# Filter down large objects for package -----------------------------------
exeter_osm_buildings_all_joined = exeter_osm_buildings_all %>%
  sf::st_join(exeter_zones)

set.seed(2021)
# select 20% of buildings in each zone to reduce file size for this example
# remove this filter or increase the sampling to include more buildings
exeter_osm_buildings_sample = exeter_osm_buildings_all_joined %>%
  dplyr::filter(!is.na(osm_way_id))

exeter_osm_buildings_tbl = exeter_osm_buildings_all %>%
  dplyr::filter(osm_way_id %in% exeter_osm_buildings_sample$osm_way_id)

# abstr
output_sf = ab_scenario(
  od = exeter_od,
  zones = exeter_zones,
  zones_d = NULL,
  origin_buildings = exeter_osm_buildings_tbl,
  destination_buildings = exeter_osm_buildings_tbl,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("All", "Walk", "Bike", "Drive", "Transit")
)

# tmap::tmap_mode("view")
# tm_basemap()
# tm_shape(output_sf) + tmap::tm_lines(col = "mode", lwd = .8, lwd.legeld.col = "black") +
#   tm_shape(exeter_zones) + tmap::tm_borders(lwd = 1.2, col = "gray") +
#   tm_text("geo_code", size = 0.6) +
#   tm_style("cobalt")
output_json = ab_json(output_sf, time_fun = ab_time_normal, scenario_name = "Exeter Example")
ab_save(output_json, f = "../../Desktop/exeter.json")

