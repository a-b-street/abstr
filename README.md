
<!-- README.md is generated from README.Rmd. Please edit that file -->

# abstr

<!-- badges: start -->

[![R-CMD-check](https://github.com/a-b-street/abstr/workflows/R-CMD-check/badge.svg)](https://github.com/a-b-street/abstr/actions)
<!-- badges: end -->

## <img src="https://user-images.githubusercontent.com/22789869/129973263-5fc74ae3-ed17-4155-9a8c-7f382f7796cc.png" align="left" height="164px" width="164px" margin="10%" />

**abstr provide an R interface to the [A/B
Street](https://github.com/a-b-street/abstreet#ab-street) transport system
and network editing software. It provides functions for converting
origin-destination data, combined with data on buildings
representing origin and destination locations, into `.json` files that
can be directly imported into the A/B Street city simulation.**

See the formats page in the [A/B Street
documentation](https://a-b-street.github.io/docs/tech/dev/formats/scenarios.html)
for details of the schema that the package outputs.

## Installation

You can install the released version of abstr from
<!-- [CRAN](https://CRAN.R-project.org) with: --> GitHub as follows:

``` r
remotes::install_github("a-b-street/abstr")
```

## Example

The example below shows how `abstr` can be used. The input datasets
include `sf` objects representing buildings, origin-destination (OD)
data represented as desire lines and administrative zones representing
the areas within which trips in the desire lines start and end. With the
exception of OD data, each of the input datasets is readily available
for most cities. The input datasets are illustrated in the plots below,
which show example data shipped in the package, taken from the Seattle,
U.S.

``` r
library(abstr)
library(tmap) # for map making
#> Warning: package 'tmap' was built under R version 4.0.5
tm_shape(montlake_zones) + tm_polygons(col = "grey") +
  tm_shape(montlake_buildings) + tm_polygons(col = "blue")  +
tm_style("classic")
```

<div class="figure">

<img src="man/figures/README-input-1.png" alt="Example data that can be used as an input by functions in abstr to generate trip-level scenarios that can be imported by A/B Street." width="100%" />
<p class="caption">
Example data that can be used as an input by functions in abstr to
generate trip-level scenarios that can be imported by A/B Street.
</p>

</div>

The map above is a graphical representation of the Montlake residential
neighborhood in central Seattle, Washington. Here, `montlake_zones`
represents neighborhood residential zones declared by Seattle local
government and `montlake_buildings` being the accumulation of buildings
listed in
<a link href="https://www.openstreetmap.org/#map=5/54.910/-3.432">
OpenStreetMap</a>

The final piece of the `abstr` puzzle is OD data.

``` r
head(montlake_od)
#> # A tibble: 6 x 6
#>    o_id  d_id Drive Transit  Bike  Walk
#>   <dbl> <dbl> <int>   <int> <int> <int>
#> 1   281   361    23       1     2    14
#> 2   282   361    37       4     0    11
#> 3   282   369    14       3     0     8
#> 4   301   361    27       4     3    15
#> 5   301   368     6       2     1    16
#> 6   301   369    14       2     0    13
```

In this example, the first two columns correspond to the origin and
destination zones in Montlake, with the subsequent columns representing
the transport mode share between these zones.

Let’s combine each of the elements outlined above, the zone, building
and OD data. We do this using the `ab_scenario()` function in the
`abstr` package, which generates a data frame representing tavel between
the `montlake_buildings`. While the OD data contains information on
origin and destination zone, `ab_scenario()` ‘disaggregates’ the data
and randomly selects building within each origin and destination zone to
simulate travel at the individual level, as illustrated in the chunk
below which uses only a sample of the `montlake_od` data, showing travel
between three pairs of zones, to illustrate the process:

``` r
set.seed(42)
montlake_od_minimal = subset(montlake_od, o_id == "373" |o_id == "402" | o_id == "281" | o_id == "588" | o_id == "301" | o_id == "314")
output_sf = ab_scenario(
  od = montlake_od_minimal,
  zones = montlake_zones,
  zones_d = NULL,
  origin_buildings = montlake_buildings,
  destination_buildings = montlake_buildings,
  pop_var = 3,
  time_fun = ab_time_normal,
  output = "sf",
  modes = c("Walk", "Bike", "Drive", "Transit")
)
```

The `output_sf` object created above can be further transformed to match
[A/B Street’s
schema](https://a-b-street.github.io/docs/tech/dev/formats/scenarios.html)
and visualised in A/B Street, or visualised in R (using the `tmap`
package in the code chunk below):

``` r
tm_shape(output_sf) + tmap::tm_lines(col = "mode", lwd = .8, lwd.legeld.col = "black") +
  tm_shape(montlake_zones) + tmap::tm_borders(lwd = 1.2, col = "gray") +
  tm_text("id", size = 0.6) +
tm_style("cobalt")
```

<img src="man/figures/README-outputplot-1.png" width="100%" />

Each line in the plot above represents a single trip, with the color
representing each transport mode. Moreover, each trip is configured with
an associated departure time, that can be represented in A/B Street.

The `ab_save` and `ab_json` functions conclude the `abstr` workflow by
outputting a local JSON file, matching the [A/B Street’s
schema](https://a-b-street.github.io/docs/tech/dev/formats/scenarios.html).

``` r
output_json = ab_json(output_sf, time_fun = ab_time_normal, scenario_name = "Montlake Example")
ab_save(output_json, f = "montlake_scenarios.json")
```

Let’s see what is in the file:

``` r
file.edit("ab_scenario.json")
```

The first trip schedule should look something like this, matching [A/B
Street’s schema](https://a-b-street.github.io/docs/tech/dev/formats/).

``` json
{
  "scenario_name": "Montlake Example",
  "people": [
    {
      "trips": [
        {
          "departure": 317760000,
          "origin": {
            "Position": {
              "longitude": -122.3139,
              "latitude": 47.667
            }
          },
          "destination": {
            "Position": {
              "longitude": -122.3187,
              "latitude": 47.6484
            }
          },
          "mode": "Walk",
          "purpose": "Shopping"
        }
      ]
    }
```

## Importing scenario files into A/B Street

![](https://user-images.githubusercontent.com/22789869/128907563-4aa95b30-a98d-4fbc-9275-97e0b30dd227.gif)

In order to import scenario files into A/B Street, you will need to:

-   Install a stable version of
    [Rust](https://www.rust-lang.org/tools/install)
    -   On Windows, you will also need [Visual Code
        Studio](https://code.visualstudio.com/) and [Visual Studio c++
        build tools](https://visualstudio.microsoft.com/downloads/)
        prior to installing Rust.
-   On Linux, run
    `sudo apt-get install libasound2-dev libxcb-shape0-dev libxcb-xfixes0-dev libpango1.0-dev libgtk-3-dev`
    or the equivalent for your distribution.
-   Download the A/B Street repo
    `git clone https://github.com/a-b-street/abstreet.git`
-   Fetch the minimal amount of data needed to get started
    `cargo run --bin updater -- --minimal`

Once you have all of this up and running, you will be able to run the
scenario import. To start, open up a terminal in Visual Studio or your
chosen IDE. Next edit the following command to include the local path of
your scenario.json file.

    cargo run --bin import_traffic -- --map=data/system/us/seattle/maps/montlake.bin --input=/path/to/input.json

Given you have correctly set the file path, the scenario should now be
imported into your local version of the Montlake map. Next you can run
the following command to start the A/B Street simulation in Montlake.

    cargo run --bin game -- --dev data/system/us/seattle/maps/montlake.bin

Once the game has booted up click on the `scenarios` tab in the top
right, it will currently be set as “none”. Change this to the first
option “Montlake Example” which will be the scenario we have just
uploaded. Alternatively, you can skip the first import command and use
the GUI to select a scenario file to import.

## Next steps

For a more comprehensive guide in the art of collecting, transforming
and saving data for A/B Street, check out the `abstr`
[documentation](https://a-b-street.github.io/abstr/).
