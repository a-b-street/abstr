
<!-- README.md is generated from README.Rmd. Please edit that file -->

# abstr

<!-- badges: start -->

[![R-CMD-check](https://github.com/a-b-street/abstr/workflows/R-CMD-check/badge.svg)](https://github.com/a-b-street/abstr/actions)
<!-- badges: end -->

The goal of abstr is to provide an R interface to the [A/B
Street](https://github.com/a-b-street/abstreet#ab-street) transport
planning/simulation game. Currently it provides a way to convert
aggregated origin-destination data, combined with data on buildings
representing origin and destination locations, into `.json` files that
can be directly imported into the A/B Street game. See
<https://a-b-street.github.io/docs/dev/formats/scenarios.html#example>
for details of the schema that the package outputs.

## Installation

You can install the released version of abstr from
<!-- [CRAN](https://CRAN.R-project.org) with: --> GitHub as follows:

``` r
remotes::install_github("a-b-street/abstr")
```

## Example

``` r
library(abstr)

ablines = ab_scenario(
 houses = leeds_houses,
 buildings = leeds_buildings,
 desire_lines = leeds_desire_lines,
 zones = leeds_zones,
 output_format = "sf"
)
plot(leeds_desire_lines$geometry, lwd = leeds_desire_lines[[3]] / 30)
plot(leeds_site_area$geometry, add = TRUE)
plot(leeds_buildings$geometry, add = TRUE)
plot(ablines, add = TRUE)
```

<img src="man/figures/README-output-sf-1.png" width="100%" />

Each line in the plot above represents a single trip, color representing
mode. Each trip has an associated departure time, that can be
represented in A/B Street.

You can output the result as a list object that can be saved as a JSON
file as follows, taking only one of the desire lines (desire line 7,
which has only 9 trips for ease of viewing the results) as an example:

``` r
library(abstr)
ab_scenario_list = ab_scenario(
 leeds_houses,
 leeds_buildings,
 leeds_desire_lines,
 leeds_zones,
 output_format = "json_list"
)
ab_scenario_list
#> $scenario_name
#> [1] "base"
#> 
#> $people
#> # A tibble: 185 x 2
#>    origin$Position$longitude $$latitude trips           
#>                        <dbl>      <dbl> <list>          
#>  1                     -1.53       53.8 <tibble [1 × 3]>
#>  2                     -1.53       53.8 <tibble [1 × 3]>
#>  3                     -1.53       53.8 <tibble [1 × 3]>
#>  4                     -1.53       53.8 <tibble [1 × 3]>
#>  5                     -1.53       53.8 <tibble [1 × 3]>
#>  6                     -1.53       53.8 <tibble [1 × 3]>
#>  7                     -1.53       53.8 <tibble [1 × 3]>
#>  8                     -1.53       53.8 <tibble [1 × 3]>
#>  9                     -1.53       53.8 <tibble [1 × 3]>
#> 10                     -1.53       53.8 <tibble [1 × 3]>
#> # … with 175 more rows
ab_save(ab_scenario_list, "ab_scenario.json")
```

Let’s see what is in the file:

``` r
file.edit("ab_scenario.json")
```

The first trip schedule should look something like this, matching [A/B
Street’s
schema](https://a-b-street.github.io/docs/dev/formats/scenarios.html#example).

``` json
{
  "scenario_name": "base",
  "people": [
    {
      "origin": {
        "Position": {
          "longitude": -1.5278,
          "latitude": 53.7888
        }
      },
      "trips": [
        {
          "departure": 28236,
          "destination": {
            "Position": {
              "longitude": -1.5717,
              "latitude": 53.8039
            }
          },
          "mode": "Walk"
        }
      ]
    }
```
