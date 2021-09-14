library(dplyr)
library(foreign)

temp = tempfile()
download.file("https://transparencia.metrosp.com.br/node/3322/download", temp, mode="wb")
OD_SP_2017 = read.dbf(unzip(temp, "OD-2017/Banco de Dados-OD2017/OD_2017_v1.dbf"), as.is = FALSE)
# unlink(temp, recursive = T, force = T) # uncomment to remove temp file

# just São Paulo municipality with short trips
OD_SP_2017 = OD_SP_2017 %>%
  filter(ZONA_O %in% c(1:9, 18:19, 24:26) & ZONA_D %in% c(1:9, 18:19, 24:26))

head(OD_SP_2017)
sapply(OD_SP_2017, class)
people = unique(OD_SP_2017$ID_PESS)

set.seed(42)

sao_paulo_activity_df_20 = OD_SP_2017 %>%
  filter(ID_PESS %in% sample(people, 20))

# generate smaller subset of data
sao_paulo_activity_df_20 = sao_paulo_activity_df_20 %>%
  dplyr::select(ID_PESS, CO_O_X, CO_O_Y, CO_D_X, CO_D_Y, MODOPRIN, H_SAIDA, MIN_SAIDA) %>%
  dplyr::mutate(
    departure = round(H_SAIDA + MIN_SAIDA/60, digits = 2),
    mode = dplyr::case_when(
      MODOPRIN %in% 1:4  ~ "Transit",
      MODOPRIN %in% 8:12  ~ "Car",
      MODOPRIN == 15 ~ "Bike",
      MODOPRIN == 16 ~ "Walk"
    )
    ) %>%
  dplyr::rename(person = ID_PESS)

matrix = sao_paulo_activity_df_20 %>% dplyr::select(CO_O_X, CO_O_Y, CO_D_X, CO_D_Y)

table(sao_paulo_activity_df_20$MODOPRIN)

sao_paulo_activity_sf_20 = sao_paulo_activity_df_20 %>%
  select(-matches("CO")) %>%
  dplyr::mutate(
    geometry = od::odc_to_sfc(matrix)
  ) %>%
  sf::st_sf(crs = 22523) %>% # the local projection
  sf::st_transform(crs = 4326)

sao_paulo_activity_df_2 = sao_paulo_activity_df_20 %>%
  filter(person %in% sample(person, 2))

sao_paulo_activity_sf_2 = sao_paulo_activity_sf_20 %>%
  filter(person %in% sample(person, 2))


table(sao_paulo_activity_df_20$mode)
table(sao_paulo_activity_df_2$mode)

usethis::use_data(sao_paulo_activity_df_2, overwrite = T)
usethis::use_data(sao_paulo_activity_df_20, overwrite = T)
usethis::use_data(sao_paulo_activity_sf_2, overwrite = T)
usethis::use_data(sao_paulo_activity_sf_20, overwrite = T)
