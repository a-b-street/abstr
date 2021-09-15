#' Example Activity data for São Paulo
#'
#' Each row of this table contains a single trip of people in the São Paulo city.
#' `sao_paulo_activity_df_2` represents the movement of 2 people,
#' `sao_paulo_activity_df_20` represents the movement of 20 people.
#'
#' See the code used to create this data, and the full open dataset with
#' 128 variables, the file
#' [data-raw/sao-paulo-activity-data.R](https://github.com/a-b-street/abstr/blob/main/data-raw/sao-paulo-activity-data.R)
#' in the package's GitHub repo.
#'
#' @format A data frame with columns:
#' \describe{
#' \item{ID_PESS}{Person identifier.}
#' \item{CO_O_X}{Origin coordinate X.}
#' \item{CO_O_Y}{Origin coordinate Y.}
#' \item{CO_D_X}{Destination coordinate X.}
#' \item{CO_D_Y}{Destination coordinate Y.}
#' \item{MODOPRIN}{Main mode.}
#' \item{H_SAIDA}{Departure hour.}
#' \item{MIN_SAIDA}{Departure minute.}
#' }
#' @aliases sao_paulo_activity_df_2
#' @examples
#' dim(sao_paulo_activity_df_20)
#' names(sao_paulo_activity_df_20)
#' head(sao_paulo_activity_df_20)
#' dim(sao_paulo_activity_df_2)
#' names(sao_paulo_activity_df_2)
#' head(sao_paulo_activity_df_2)
"sao_paulo_activity_df_20"

#' Example Activity data for São Paulo
#'
#' Each row of this table contains a single trip of people in the São Paulo city.
#' `sao_paulo_activity_sf_2` represents the movement of 2 people,
#' `sao_paulo_activity_sf_20` represents the movement of 20 people.
#'
#' See the code used to create this data, and the full open dataset with
#' 128 variables, the file
#' [data-raw/sao-paulo-activity-data.R](https://github.com/a-b-street/abstr/blob/main/data-raw/sao-paulo-activity-data.R)
#' in the package's GitHub repo.
#'
#' @format A data frame with columns:
#' \describe{
#' \item{person}{Person identifier.}
#' \item{departure}{Departure time in seconds past midnight}
#' \item{mode}{Mode of travel in A/B Street terms}
#' \item{purpose}{Purpose of travel in A/B Street terms}
#' \item{geometry}{Geometry of the linestring representing the OD pair}
#' }
#' @aliases sao_paulo_activity_sf_2
#' @examples
#' dim(sao_paulo_activity_sf_20)
#' names(sao_paulo_activity_sf_20)
#' head(sao_paulo_activity_sf_20)
#' table(sao_paulo_activity_sf_20$mode)
#' table(sao_paulo_activity_sf_20$purpose)
#' dim(sao_paulo_activity_sf_2)
#' names(sao_paulo_activity_sf_2)
#' head(sao_paulo_activity_sf_2)
"sao_paulo_activity_sf_20"
