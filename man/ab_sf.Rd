% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ab_scenario.R
\name{ab_sf}
\alias{ab_sf}
\title{Convert JSON representation of trips from A/B Street into an 'sf' object}
\usage{
ab_sf(json)
}
\arguments{
\item{json}{Character string or list representing a JSON file or list that
has been read into R and converted to a data frame.}
}
\value{
An \code{sf} data frame representing travel behaviour scenarios
from, and which can be fed into, A/B Street. Contains the following
columns: person (the ID of each agent in the simulation),
departure (seconds after midnight of the travel starting),
mode (the mode of transport, being \code{Walk}, \code{Bike}, \code{Transit} and \code{Drive}),
purpose (what the trip was for, e.g. \code{Work}), and
geometry (a linestring showing the start and end point of the trip/stage).
}
\description{
This function takes a path to a JSON file representing an A/B Street
scenario, or an R representation of the JSON in a list, and returns
an \code{sf} object with the same structure as objects returned by
\code{\link[=ab_scenario]{ab_scenario()}}.
}
\details{
Note: the departure time in seconds is divided by 10000 on conversion
to represent seconds, which are easier to work with that 10,000th of
a second units.
}
\examples{
file_name = system.file("extdata/minimal_scenario2.json", package = "abstr")
ab_sf(file_name)
json = jsonlite::read_json(file_name, simplifyVector = TRUE)
ab_sf(json)
}
