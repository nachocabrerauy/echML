*---------------------------------------------------------
* 2- pesos replicados
*	Importa pesos replicados descargados de web INE y los guarda en formato DTA.
*---------------------------

clear all
set more off

cd "$ruta"

*-------------------------------------------------------------------------------
* Importa datos originales INE 
*-------------------------------------------------------------------------------

foreach num of numlist 2022/2023 {
	foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
		import excel "datos_originales\pesos_replicados_`x'-`num'.xlsx", firstrow clear
		gen anio = `num'
		gen mes = `x'
		destring mes, replace
		rename ID id
		save "datos_originales\pesos_replicados_`x'_`num'.dta", replace
	}
}

clear 

foreach num of numlist 2022/2023 {
	foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
		append using "datos_originales\pesos_replicados_`x'_`num'.dta", force
	}
}

save "datos_originales\pesos_replicados_22_23.dta", replace

import delimited "datos_originales\pesos replicados Bootstrap anual 2022.csv", clear
gen anio = 2022
cap rename ID id
save "datos_originales\pesos_anuales_22.dta", replace

import excel "datos_originales\pesos replicados Bootstrap anual 2023.xlsx", firstrow clear
gen anio = 2023
cap rename ID id
save "datos_originales\pesos_anuales_23.dta", replace
