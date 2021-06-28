#' Example OD Table for Montlake
#'
#' Each row of this table contains a count of how many trips started in
#' column `o_id` and ended in column `d_id` according to different modes.
#' This example table has modes that match what A/B Street currently uses:
#' "Drive", "Transit", "Bike", and "Walk".
#'
#' See the code used to create this data in "data-raw/montlake-test-data.R"
#'
#' @format A data frame with columns:
#' \describe{
#' \item{o_id}{Trip origin zone ID (must match an ID in `montlake_zone`).}
#' \item{d_id}{Trip destination zone ID (must match an ID in `montlake_zone`).}
#' \item{Drive}{Count of how many trips were made using cars.}
#' \item{Transit}{Count of how many trips were made using public transit.}
#' \item{Bike}{Count of how many trips were made using bikes.}
#' \item{Walk}{Count of how many trips were made on foot.}
#' }
"montlake_od"
