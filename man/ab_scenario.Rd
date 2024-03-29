% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ab_scenario.R
\name{ab_scenario}
\alias{ab_scenario}
\title{Generate A/B Street Scenario objects by disaggregating aggregate OD data}
\usage{
ab_scenario(
  od,
  zones,
  zones_d = NULL,
  origin_buildings = NULL,
  destination_buildings = NULL,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("Walk", "Bike", "Transit", "Drive"),
  ...
)
}
\arguments{
\item{od}{Origin destination data with the first 2 columns containing
zone code of origin and zone code of destination. Subsequent
columns should be mode names such as All and Walk, Bike, Transit, Drive,
representing the number of trips made by each mode of transport
for use in A/B Street.}

\item{zones}{Zones with IDs that match the desire lines. Class: \code{sf}.}

\item{zones_d}{Optional destination zones with IDs
that match the second column of the \code{od} data frame (work in progress)}

\item{origin_buildings}{Polygons where trips will originate (\code{sf} object)}

\item{destination_buildings}{Polygons where trips can end, represented as \code{sf} object}

\item{pop_var}{The variable containing the total population of each desire line.}

\item{time_fun}{The function used to calculate departure times.
\code{ab_time_normal()} by default.}

\item{output}{Which output format?
\code{"sf"} (default) and \code{"json_list"} return R objects.
A file name such as \code{"baseline.json"} will save the resulting scenario
to a file.}

\item{modes}{Character string containing the names of the modes of travel to
include in the outputs. These must match column names in the \code{od} input
data frame. The default is \code{c("Walk", "Bike", "Drive", "Transit")},
matching the mode names allowed in the A/B Street scenario schema.}

\item{...}{Additional arguments to pass to \code{\link[=ab_json]{ab_json()}}}
}
\value{
An \code{sf} object by default representing individual trips
between randomly selected points (or buildings when available)
between the zones represented in the OD data.
}
\description{
This function takes a data frame representing origin-destination trip data
in 'long' form, zones and, optionally, buildings from where trips can
start and end as inputs.
}
\examples{
od = leeds_od
zones = leeds_zones
od[[1]] = c("E02006876")
ablines = ab_scenario(od, zones = zones)
plot(ablines)
table(ablines$mode)
colSums(od[3:7]) # 0.17 vs 0.05 for ab_scenario
ablines = ab_scenario(od, zones = zones, origin_buildings = leeds_buildings)
plot(leeds_zones$geometry)
plot(leeds_buildings$geometry, add = TRUE)
plot(ablines["mode"], add = TRUE)
ablines_json = ab_json(ablines, scenario_name = "test")
od = leeds_desire_lines
names(od)[4:6] = c("Walk", "Bike", "Drive")
ablines = ab_scenario(
  od = od,
  zones = leeds_site_area,
  zones_d = leeds_zones,
  origin_buildings = leeds_houses,
  destination_buildings = leeds_buildings,
  output = "sf"
)
plot(ablines)
plot(ablines$geometry)
plot(leeds_site_area$geometry, add = TRUE)
plot(leeds_buildings$geometry, add = TRUE)
}
