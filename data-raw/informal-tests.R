# remotes::install_github("tnederlof/abstr", "fix_scenario_output_format")
# library(abstr)
devtools::load_all()

od = leeds_od
od[[1]] = c("E02006876")
zones = leeds_zones
ablines = ab_scenario(od, zones = zones)
plot(ablines)
ab_list = ab_json(ablines, mode_column = "mode")
ab_save(ab_list, f = "test.json")
file.edit("test.json")
writeLines(ab_list)
