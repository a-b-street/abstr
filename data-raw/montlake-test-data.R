library(tidyverse)
library(sf)

## determine the bounding box of the test area
montlake_poly_url <- "https://raw.githubusercontent.com/a-b-street/abstreet/master/importer/config/us/seattle/montlake.poly"

raw_boundary_vec <- readr::read_lines(montlake_poly_url)
boundary_matrix <- raw_boundary_vec[(raw_boundary_vec != "boundary") & (raw_boundary_vec != "1") & (raw_boundary_vec != "END")] %>%
  stringr::str_trim() %>%
  tibble::as_tibble() %>%
  dplyr::mutate(y_boundary = as.numeric(lapply(stringr::str_split(value, "    "), `[[`, 1)),
                x_boundary = as.numeric(lapply(stringr::str_split(value, "    "), `[[`, 2))) %>%
  dplyr::select(-value) %>%
  as.matrix()
boundary_sf_poly <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(boundary_matrix)), crs = 4326))

## parse the zone file
all_zones_tbl <- sf::st_read("https://raw.githubusercontent.com/psrc/soundcast/master/inputs/base_year/taz2010.geojson") %>% sf::st_transform(4326)
zones_in_boundary_tbl <- all_zones_tbl[sf::st_intersects(all_zones_tbl, boundary_sf_poly, sparse = F),]

# # use to visually verify the correct zones are identified within the bounding box
# zones_in_boundary_tbl$col <- sf.colors(22, categorical = TRUE, alpha = .3)
# plot(st_geometry(boundary_sf_poly))
# plot(st_geometry(zones_in_boundary_tbl), add = TRUE, col = zones_in_boundary_tbl$col)

## process the disagreggated soundcast trips data
all_trips_tbl <- readr::read_csv("http://abstreet.s3-website.us-east-2.amazonaws.com/dev/data/input/us/seattle/trips_2014.csv.gz")

## create a OD matrix
od_tbl_long <- dplyr::select(all_trips_tbl, otaz, dtaz, mode) %>%
  dplyr::mutate(mode = dplyr::case_when(mode %in% c(1, 9) ~ "Walk",
                                        mode == 2 ~ "Bike",
                                        mode %in% c(3, 4, 5) ~ "Drive",
                                        mode %in% c(6, 7, 8) ~ "Transit",
                                        TRUE ~ as.character(NA))) %>%
  dplyr::filter(!is.na(mode)) %>%
  dplyr::group_by(otaz, dtaz, mode) %>%
  dplyr::summarize(n = n()) %>%
  dplyr::ungroup() %>%
  # only keep an entry if the origin or destination is in a Montlake zone
  dplyr::filter((otaz %in% zones_in_boundary_tbl$TAZ) | (dtaz %in% zones_in_boundary_tbl$TAZ))

# create a wide OD matrix and filter out any OD entries with under 10 trips in it
montlake_od_tbl <- tidyr::pivot_wider(od_tbl_long, names_from = mode, values_from = n, values_fill = 0) %>%
  dplyr::rename(o_id = otaz, d_id = dtaz) %>%
  dplyr::mutate(total = Drive + Transit + Bike + Walk) %>%
  dplyr::filter(total >= 10) %>%
  dplyr::select(-total)

montlake_zone_tbl <- dplyr::right_join(all_zones_tbl,
                                        tibble::tibble("TAZ" = unique(c(montlake_od_tbl$o_id, montlake_od_tbl$d_id))),
                                        by = "TAZ") %>%
  dplyr::select(TAZ) %>%
  dplyr::rename(id = TAZ)

## Collect building data from OSM
osm_polygons <- osmextract::oe_read("http://download.geofabrik.de/north-america/us/washington-latest.osm.pbf", layer = "multipolygons")

building_types <- c("yes", "house", "detached", "residential", "apartments",
                    "commercial", "retail", "school", "industrial", "semidetached_house",
                    "church", "hangar", "mobile_home", "warehouse", "office",
                    "college", "university", "public", "garages", "cabin", "hospital",
                    "dormitory", "hotel", "service", "parking", "manufactured",
                    "civic", "farm", "manufacturing", "floating_home", "government",
                    "bungalow", "transportation", "motel", "manufacture", "kindergarten",
                    "house_boat", "sports_centre")
osm_buildings <- osm_polygons %>%
  dplyr::filter(building %in% building_types)

montlake_osm_buildings <- osm_buildings[sf::st_intersects(sf::st_make_valid(osm_buildings), sf::st_union(montlake_zone_tbl), sparse = F),] %>%
  dplyr::select(osm_id, osm_way_id, name, type, building, land_area, landuse) %>%
  sf::st_make_valid()


# # use to visualize the building data
# tmap::tm_shape(boundary_sf_poly) + tmap::tm_borders() +
#   tmap::tm_shape(montlake_osm_buildings) + tmap::tm_polygons(col = "building")

## Save example data to the package
usethis::use_data(montlake_od_tbl, overwrite = T)
usethis::use_data(montlake_zone_tbl, overwrite = T)
usethis::use_data(montlake_osm_buildings, overwrite = T)


## Test the package functions with the test data
# od <- montlake_od_tbl
# zones <- montlake_zone_tbl
# zones_d = NULL
# origin_buildings = montlake_osm_buildings
# destination_buildings = montlake_osm_buildings
# pop_var = 3
# time_fun = ab_time_normal
# output = "json_file"
# modes = c("Walk", "Bike", "Drive", "Transit")

res <- ab_scenario(
  od = montlake_od_tbl,
  zones = montlake_zone_tbl,
  zones_d = NULL,
  origin_buildings = montlake_osm_buildings,
  destination_buildings = montlake_osm_buildings,
  # destinations2 = NULL,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("Walk", "Bike", "Drive", "Transit"))

# visualize the results
tmap::tm_shape(res) + tmap::tm_lines(col="mode") +
  tmap::tm_shape(montlake_zone_tbl) + tmap::tm_borders()

# build json output
ab_scenario(
  od = montlake_od_tbl,
  zones = montlake_zone_tbl,
  zones_d = NULL,
  origin_buildings = montlake_osm_buildings,
  destination_buildings = montlake_osm_buildings,
  # destinations2 = NULL,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "json_file",
  modes = c("Walk", "Bike", "Drive", "Transit"))
