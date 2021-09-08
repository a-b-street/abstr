library(dplyr)
library(foreign)

temp = tempfile()
download.file("https://transparencia.metrosp.com.br/node/3322/download", temp, mode="wb")
OD_SP_2017 = read.dbf(unzip(temp, "OD-2017/Banco de Dados-OD2017/OD_2017_v1.dbf"), as.is = FALSE)
unlink(temp, recursive = T, force = T)
unlink("OD-2017", recursive = T, force = T)

# just São Paulo municipality with short trips
OD_SP_2017 = OD_SP_2017 %>%
  filter(MUNI_DOM == 36 & DISTANCIA <= 5000)

people = unique(OD_SP_2017$ID_PESS)

sao_paulo_activity_df_2 = OD_SP_2017 %>%
  filter(ID_PESS %in% sample(people, 2))

sao_paulo_activity_df_20 = OD_SP_2017 %>%
  filter(ID_PESS %in% sample(people, 20))

usethis::use_data(sao_paulo_activity_df_2, overwrite = T)
usethis::use_data(sao_paulo_activity_df_20, overwrite = T)
