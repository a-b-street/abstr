library(abstr)
library(osrm)
library(stplanr)
library(sf)

places = tibble::tribble(
  ~name, ~x, ~y,
  "Home", -1.524, 53.819,
  "Work", -1.552, 53.807,
  "Park", -1.560, 53.812,
  "Cafe", -1.556, 53.802
)
places_sf = sf::st_as_sf(places, coords = c("x", "y"), crs = 4326)
plot(places_sf, pch = places$name)
od = tibble::tribble(
  ~o, ~d, ~mode, ~departure, ~person,
  "Home", "Work", "Bike", "08:30", 1,
  "Work", "Park", "Walk", "11:30", 1,
  "Park", "Cafe", "Walk", "12:15", 1,
  "Cafe", "Work", "Walk", "12:45", 1,
  "Work", "Home", "Bike", "17:00", 1
)

#> Calculate trip route from geometry
calculate_routes = function(o,d,name){
  trips = route(
    from = unlist(o),
    to = unlist(d),
    route_fun = osrmRoute,
    returnclass = "sf"
  )

  route_geom = as.data.frame(trips$geometry)
  route_geom = st_as_sf(route_geom)
  route_geom$name = name

  return(route_geom)
}

# calculate robin activity
home_to_work = calculate_routes(o = places_sf$geometry[1], d = places_sf$geometry[2], name = "Robin")
work_to__park = calculate_routes(o = places_sf$geometry[2], d = places_sf$geometry[3],  name = "Robin")
park_to_cafe = calculate_routes(o = places_sf$geometry[3], d = places_sf$geometry[4],  name = "Robin")
cafe_to_work = calculate_routes(o = places_sf$geometry[4], d = places_sf$geometry[2],  name = "Robin")
work_to_home = calculate_routes(o = places_sf$geometry[2], d = places_sf$geometry[1],  name = "Robin")


robin_activity = rbind(home_to_work,work_to__park,park_to_cafe,cafe_to_work,work_to_home)

# calculate a neighbours activity
places_neighbour = tibble::tribble(
  ~name, ~x, ~y,
  "Home", -1.524, 53.822,
  "Work", -1.552, 53.814,
  "Park", -1.560, 53.812,
  "Cafe", -1.556, 53.802
)
places_neighbour_sf = sf::st_as_sf(places_neighbour, coords = c("x", "y"), crs = 4326)

home_to_work_neighbour = calculate_routes(o = places_neighbour_sf$geometry[1], d = places_neighbour_sf$geometry[2], name = "Neighbour")
work_to__park_neighbour = calculate_routes(o = places_neighbour_sf$geometry[2], d = places_neighbour_sf$geometry[3],  name = "Neighbour")
park_to_cafe_neighbour = calculate_routes(o = places_neighbour_sf$geometry[3], d = places_neighbour_sf$geometry[4],  name = "Neighbour")
cafe_to_work_neighbour = calculate_routes(o = places_neighbour_sf$geometry[4], d = places_neighbour_sf$geometry[2],  name = "Neighbour")
work_to_home_neighbour = calculate_routes(o = places_neighbour_sf$geometry[2], d = places_neighbour_sf$geometry[1],  name = "Neighbour")

neighbour_activity = rbind(home_to_work_neighbour,work_to__park_neighbour,park_to_cafe_neighbour, cafe_to_work_neighbour, work_to_home_neighbour)

# bind activities
activity_all = rbind(neighbour_activity,robin_activity)
activity_all$name = as.character(activity_all$name)

# convert data into list format for playback function (note: for the leaflet playback to work a point must be cast + far from ideal but estimates an eprox journey)
activity_cast = st_cast(activity_all, "POINT")
activity_cast = split(activity_cast, f = activity_cast$name)
lapply(1:length(activity_cast), function(x) {
  activity_cast[[x]]$time <<- as.POSIXct(
    seq.POSIXt(Sys.time() - 2500, Sys.time(), length.out = nrow(activity_cast[[x]])))
})

# agent icon
agent = makeIcon(
  iconUrl = "https://www.freepnglogos.com/uploads/circle-png/orange-circle-icons-and-png-31.png",
  iconWidth = 14, iconHeight = 14
)

# plot map
leaflet() %>%
  addTiles() %>%
  addPlayback(data = activity_cast,
              icon = agent,
              options = playbackOptions(radius = 3,
                                        speed = 8,tickLen = 50, tracksLayer = TRUE),
              pathOpts = pathOptions(weight = 8))

