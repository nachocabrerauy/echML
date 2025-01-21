*---------------------------------------------------------
* 1- orig a dta
* 	Importa datos descargados de web INE y genera bases en formato DTA.
*	Hasta 2020 descargar datos en formato SAV, desde 2021 estan en csv.
*---------------------------

import spss using "$rutaori\HyP_2018_Terceros.sav", clear
save "$rutapro\ech18.dta", replace

import spss using "$rutaori\HyP_2019_Terceros.sav", clear
save "$rutapro\ech19.dta", replace

import spss using "$rutaori\HyP_2020_Terceros.sav", clear
save "$rutapro\ech20.dta", replace


*-------------------------------------------------------------------------------
* Base segundo semestre 2021
import delimited "$rutaori\ECH_implantacion_sem2_2021.csv", clear
*-------------------------------------------------------------------------------
* Arreglos de variables que están en string, y en el primer semestre no (no es necesario en otros años)
tostring e558 e45_3_1_1_cv e45_4_1_1_cv e209_1 e217_1 e220_1 e223_1 e226_1 e220_1 e247, replace
destring e30 f70 f76_2 f80_2, replace force
tostring f98 f113 f118_1 f118_2 f119_2 f120_2 f121 g127_1 g127_2 g127_3 g132_1 g132_2 g132_3 g133_1 g133_2, replace
destring g251_1 g251_2 g251_3 g251_4 g251_5 g135 g136 g136_1 g137 g137_1 g137_2 g138 g139 g_itnd_1 g142 g_itnd_2 e558, replace force
tostring g144_1 g145 g146 g147 g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_10 g148_1_11 g148_1_12 g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9 g148_2_10 g148_2_11 g148_2_12 g148_3 g257 h252_1 h163_1 h163_2 h166 h167_2_1 h170_1 h170_2, replace
tostring yhog, replace force
* En el primer semestre no están d8_*. Vamos a usar h5_cv en lugar de d8_1 y valor locativo (ht13) en lugar de d8_3 
gen d8_1_aux = d8_1
gen d8_3_aux = d8_3

destring d8_1_aux, force

save "$rutapro\semestre2.dta", replace
*-------------------------------------------------------------------------------
* Base primer semestre 2021
import delimited "$rutaori\ECH_2021_sem1_terceros.csv", clear
*-------------------------------------------------------------------------------
* Arreglos de variables que están en string, y en el segundo semestre no (no es necesario en otros años)
destring secc segm e30 f71_2 f72_2 f76_2 f90_2 f91_2 estred13, replace force
* En el primer semestre no están d8_*. Vamos a usar h5_cv en lugar de d8_1 y valor locativo (ht13) en lugar de d8_3 
gen d8_1_aux = h5_cv
gen d8_3_aux =.
replace d8_3_aux = ht13
destring d8_1_aux, force replace

save "$rutapro\semestre1.dta", replace

u "$rutapro\semestre1.dta", clear
append using "$rutapro\semestre2.dta", force

tostring numero id, replace // acá tengo que hacer unas líneas de más porque las variables tienen nombres diferentes, y si las junto me quedan numeros repetidos (dos hogares con el número 1, por ejemplo)
g aux="20210"
egen id1=concat(aux id)
replace numero=id1 if numero=="."
destring numero, replace
drop aux id id1

save "$rutapro\ech21.dta", replace
*-------------------------------------------------------------------------------

import delimited "$rutaori\ECH_2022.csv", clear
save "$rutapro\ech22.dta", replace

import delimited "$rutaori\ECH_implantacion_2023.csv", clear
save "$rutapro\ech23.dta", replace


*-------------------------------------------------------------------------------
* bases mensuales
*-------------------------------------------------------------------------------

foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
import delimited "$rutaori\ECH_`x'_22.csv", clear
save "$rutapro\ECH_`x'_22.dta", replace
}

clear all
foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
append using "$rutapro\ECH_`x'_22.dta", force
}
save "$rutapro\ech_mens_22.dta", replace


foreach x in "01" "02" "03" "04" "05" "06" {
import delimited "$rutaori\ECH_`x'_23.csv", clear
save "$rutapro\ECH_`x'_23.dta", replace
}

foreach x in "07" "08" "09" "10" "11" "12" {
import delimited "$rutaori\ECH_`x'_2023.csv", clear
save "$rutapro\ECH_`x'_23.dta", replace
}

clear all

foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
append using "$rutapro\ECH_`x'_23.dta", force
}
save "$rutapro\ech_mens_23.dta", replace
