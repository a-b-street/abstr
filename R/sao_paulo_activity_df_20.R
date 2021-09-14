#' Example Activity data for São Paulo (20 agents)
#'
#' Each row of this table contains a single trip of 20 different agents in the São Paulo city.
#'
#' See the code used to create this data, and the full open dataset with
#' 128 variables, the file
#' [data-raw/sao-paulo-activity-data.R](https://github.com/a-b-street/abstr/blob/main/data-raw/sao-paulo-activity-data.R)
#' in the package's GitHub repo.
#'
#' @format A data frame with columns:
#' \describe{
#' \item{person}{Person identifier.}
#' \item{CO_O_X}{Origin coordinate X.}
#' \item{CO_O_Y}{Origin coordinate Y.}
#' \item{CO_D_X}{Destination coordinate X.}
#' \item{CO_D_Y}{Destination coordinate Y.}
#' \item{MODOPRIN}{Main mode.}
#' \item{H_SAIDA}{Departure hour.}
#' \item{MIN_SAIDA}{Departure minute.}
#' }
#' @examples
#' dim(sao_paulo_activity_df_20)
#' names(sao_paulo_activity_df_20)
#' head(sao_paulo_activity_df_20)
"sao_paulo_activity_df_20"
