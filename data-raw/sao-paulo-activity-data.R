library(dplyr)
library(foreign)

temp = tempfile()
download.file("https://transparencia.metrosp.com.br/node/3322/download", temp, mode="wb")
OD_SP_2017_ALL = read.dbf(unzip(temp, "OD-2017/Banco de Dados-OD2017/OD_2017_v1.dbf"), as.is = FALSE)
# unlink(temp, recursive = T, force = T) # uncomment to remove temp file

# just São Paulo municipality with short trips
OD_SP_2017_OUTSIDE = OD_SP_2017_ALL %>%
  filter(!ZONA_O %in% c(1:9, 18:19, 24:26) | !ZONA_D %in% c(1:9, 18:19, 24:26))
agents_who_stay_inside_sp_center = setdiff(OD_SP_2017_ALL$ID_PESS, OD_SP_2017_OUTSIDE$ID_PESS)
OD_SP_2017 = OD_SP_2017_ALL %>%
  filter(ID_PESS %in% agents_who_stay_inside_sp_center) %>%
  group_by(ID_PESS) %>%
  filter(n() > 2) %>%
  ungroup()
  # filter(ZONA_O %in% c(1:9, 18:19, 24:26) & ZONA_D %in% c(1:9, 18:19, 24:26))

table(OD_SP_2017$MOTIVO_O)
table(OD_SP_2017$MOTIVO_D)

head(OD_SP_2017)
sapply(OD_SP_2017, class)
people = unique(OD_SP_2017$ID_PESS)

set.seed(2021) # for reproducible results
sao_paulo_activity_df_20 = OD_SP_2017 %>%
  filter(ID_PESS %in% sample(people, 20))

# generate smaller subset of data
sao_paulo_activity_df_20 = sao_paulo_activity_df_20 %>%
  dplyr::select(ID_PESS, CO_O_X, CO_O_Y, CO_D_X, CO_D_Y, MODOPRIN, MOTIVO_O, H_SAIDA, MIN_SAIDA) %>%
  mutate(ID_PESS = as.character(ID_PESS))

matrix = sao_paulo_activity_df_20 %>% dplyr::select(CO_O_X, CO_O_Y, CO_D_X, CO_D_Y)

table(sao_paulo_activity_df_20$MODOPRIN)

sao_paulo_activity_sf_20 = sao_paulo_activity_df_20 %>%
  select(-matches("CO")) %>%
  dplyr::transmute(
    person = ID_PESS,
    departure = H_SAIDA * 3600 + MIN_SAIDA * 60,
    mode = dplyr::case_when(
      MODOPRIN %in% 1:4  ~ "Transit",
      MODOPRIN %in% 8:12  ~ "Car",
      MODOPRIN == 15 ~ "Bike",
      MODOPRIN == 16 ~ "Walk"
    ),
    purpose = dplyr::case_when(
      MOTIVO_O %in% 1:3  ~ "Work",
      MOTIVO_O %in% 4  ~ "School",
      MOTIVO_O %in% 5  ~ "Shopping",
      MOTIVO_O %in% 6  ~ "Medical",
      MOTIVO_O %in% 7  ~ "Recreation",
      MOTIVO_O %in% 8  ~ "Home",
      MOTIVO_O %in% 9  ~ "Work",
      MOTIVO_O %in% 10  ~ "PersonalBusiness",
      MOTIVO_O %in% 11  ~ "Food"
    ),
    geometry = od::odc_to_sfc(matrix)
  ) %>%
  sf::st_sf(crs = 22523) %>% # the local projection
  sf::st_transform(crs = 4326)

# people2 = sample(sao_paulo_activity_df_20$ID_PESS, 2)
mapview::mapview(sao_paulo_activity_sf_20)
people2 = c("00241455101", "00240507101") # 2 interesting people found on the map
sao_paulo_activity_df_2 = sao_paulo_activity_df_20 %>%
  filter(ID_PESS %in% people2)

sao_paulo_activity_sf_2 = sao_paulo_activity_sf_20 %>%
  filter(person %in% people2)

table(sao_paulo_activity_sf_20$mode)
table(sao_paulo_activity_sf_2$mode)

mapview::mapview(sao_paulo_activity_sf_2)

usethis::use_data(sao_paulo_activity_df_2, overwrite = T)
usethis::use_data(sao_paulo_activity_df_20, overwrite = T)
usethis::use_data(sao_paulo_activity_sf_2, overwrite = T)
usethis::use_data(sao_paulo_activity_sf_20, overwrite = T)

# Note: the column definitions are as follows:
#' @format A data frame with columns:
#' \describe{
#' \item{ZONA}{Household zone.}
#' \item{MUNI_DOM}{Household municipality.}
#' \item{CO_DOM_X}{Household coordinate X.}
#' \item{CO_DOM_Y}{Household coordinate Y.}
#' \item{ID_DOM}{Household identifier.}
#' \item{F_DOM}{Identify first household record.}
#' \item{FE_DOM}{Household expansion factor.}
#' \item{DOM}{Household number.}
#' \item{CD_ENTRE}{Interview code.}
#' \item{DATA}{Date of interview.}
#' \item{TIPO_DOM}{Type of household.}
#' \item{AGUA}{Do you have piped water?.}
#' \item{RUA_PAVI}{Is the street paved?.}
#' \item{NO_MORAD}{Household size.}
#' \item{TOT_FAM}{Total families in the household.}
#' \item{ID_FAM}{Family identifier.}
#' \item{F_FAM}{Identify first family record.}
#' \item{FE_FAM}{Famiy expansion factor.}
#' \item{FAMILIA}{Family number}
#' \item{NO_MORAF}{Family size.}
#' \item{CONDMORA}{Housing condition.}
#' \item{QT_BANHO}{Bathrooms.}
#' \item{QT_EMPRE}{Domestic workers.}
#' \item{QT_AUTO}{Automobiles.}
#' \item{QT_MICRO}{Microcomputers.}
#' \item{QT_LAVALOU}{Dishwashers.}
#' \item{QT_GEL1}{One door refrigerator.}
#' \item{QT_GEL2}{Two door refrigerator.}
#' \item{QT_FREEZ}{Frezers.}
#' \item{QT_MLAVA}{Washing machines.}
#' \item{QT_DVD}{DVDs.}
#' \item{QT_MICROON}{Microwave oven.}
#' \item{QT_MOTO}{Motorcycles.}
#' \item{QT_SECAROU}{Clothes dryer.}
#' \item{QT_BICICLE}{Bikes.}
#' \item{NAO_DCL_IT}{Comfort item declaration code.}
#' \item{CRITERIOBR}{Critério de Classificação Econômica Brasil.}
#' \item{PONTO_BR}{Critério Brasil points.}
#' \item{ANO_AUTO1}{Year of manufacture of Auto 1.}
#' \item{ANO_AUTO2}{Year of manufacture of Auto 2.}
#' \item{ANO_AUTO3}{Year of manufacture of Auto 3.}
#' \item{RENDA_FA}{Monthly family income.}
#' \item{CD_RENFA}{Monthly family income code.}
#' \item{ID_PESS}{Person identifier.}
#' \item{F_PESS}{Identifies first person record.}
#' \item{FE_PESS}{Person expansion factor.}
#' \item{PESSOA}{Person number.}
#' \item{SIT_FAM}{Family situation.}
#' \item{IDADE}{Age.}
#' \item{SEXO}{Sex.}
#' \item{ESTUDA}{Are you currently studying?}
#' \item{GRAU_INS}{Education.}
#' \item{CD_ATIVI}{Labor market status.}
#' \item{CO_REN_I}{Individual income condition.}
#' \item{VL_REN_I}{Individual income.}
#' \item{ZONA_ESC}{School zone.}
#' \item{MUNIESC}{School municipality.}
#' \item{CO_ESC_X}{School coordinate X.}
#' \item{CO_ESC_Y}{School coordinate Y.}
#' \item{TIPO_ESC}{Type of school.}
#' \item{ZONATRA1}{Zone of 1st job.}
#' \item{MUNITRA1}{Municipality of 1st job.}
#' \item{CO_TR1_X}{1st job coordinate X.}
#' \item{CO_TR1_Y}{1st job coordinate Y.}
#' \item{TRAB1_RE}{Does 1st job equal residency?}
#' \item{TRABEXT1}{Performs outside work - 1st job.}
#' \item{OCUP1}{1st job occupation.}
#' \item{SETOR1}{1st job activity sector.}
#' \item{VINC1}{1st job employment relationship}
#' \item{ZONATRA2}{Zone of the 2nd job.}
#' \item{MUNITRA2}{Municipality of the 2nd job.}
#' \item{CO_TR2_X}{2nd job coordinate X.}
#' \item{CO_TR2_Y}{2nd job coordinate Y.}
#' \item{TRAB2_RE}{Does 2nd job equal residency?}
#' \item{TRABEXT2}{Performs outside work - 2nd job.}
#' \item{OCUP2}{2nd job occupation.}
#' \item{SETOR2}{2nd job activity sector.}
#' \item{VINC2}{2nd job employment relationship.}
#' \item{N_VIAG}{Trip number.}
#' \item{FE_VIA}{Trip expansion factor.}
#' \item{DIA_SEM}{Day of the week.}
#' \item{TOT_VIAG}{Total person's trip.}
#' \item{ZONA_O}{Zone of origin.}
#' \item{MUNI_O}{Municipality of origin.}
#' \item{CO_O_X}{Origin coordinate X.}
#' \item{CO_O_Y}{Origin coordinate Y.}
#' \item{ZONA_D}{Zone of destination.}
#' \item{MUNI_D}{Municipality of destination.}
#' \item{CO_D_X}{Destination coordinate X.}
#' \item{CO_D_Y}{Destination coordinate Y.}
#' \item{ZONA_T1}{Zone of the 1st transfer.}
#' \item{MUNI_T1}{Municipality of the 1st transfer.}
#' \item{CO_T1_X}{1st transfer coordinate X.}
#' \item{CO_T1_Y}{1st transfer coordinate Y.}
#' \item{ZONA_T2}{Zone of the 2nd transfer.}
#' \item{MUNI_T2}{Municipality of the 2nd transfer.}
#' \item{CO_T2_X}{2nd transfer coordinate X.}
#' \item{CO_T2_Y}{2nd transfer coordinate Y.}
#' \item{ZONA_T3}{Zone of the third transfer.}
#' \item{MUNI_T3}{Municipality of the 3rd transfer.}
#' \item{CO_T3_X}{3rd transfer coordinate X.}
#' \item{CO_T3_Y}{3rd transfer coordinate Y.}
#' \item{MOTIVO_O}{Reason at origin.}
#' \item{MOTIVO_D}{Reason at destination.}
#' \item{MOT_SRES}{Reason at destination without residence.}
#' \item{SERVIR_O}{Serving passenger at origin.}
#' \item{SERVIR_D}{Serving passenger at destination.}
#' \item{MODO1}{Mode 1.}
#' \item{MODO2}{Mode 2.}
#' \item{MODO3}{Mode 3.}
#' \item{MODO4}{Mode 4.}
#' \item{H_SAIDA}{Departure hour.}
#' \item{MIN_SAIDA}{Departure minute.}
#' \item{ANDA_O}{Time walking in origin.}
#' \item{H_CHEG}{Arrival hour.}
#' \item{MIN_CHEG}{Arrival minute.}
#' \item{ANDA_D}{Time walking in destination.}
#' \item{DURACAO}{Duration.}
#' \item{MODOPRIN}{Main mode.}
#' \item{TIPVG}{Type of trip.}
#' \item{PAG_VIAG}{Who paid for the trip.}
#' \item{TP_ESAUTO}{Type of car or motorcycle parking.}
#' \item{VL_EST}{Car or motorcycle parking value.}
#' \item{PE_BICI}{Why did you travel by foot or bike?}
#' \item{VIA_BICI}{If you traveled by bicycle, did you use the segregated route?}
#' \item{TP_ESBICI}{Bike parking.}
#' \item{DISTANCIA}{Distance (meters).}
#' \item{ID_ORDEM}{Registration order number.}
