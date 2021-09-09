#' Example Activity data for São Paulo (2 agents)
#'
#' Each row of this table contains a single trip of 2 different agents in the São Paulo city.
#'
#' See the code used to create this data in "data-raw/sao-paulo-activity-data.R"
#'
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
#' }
"sao_paulo_activity_df_2"
