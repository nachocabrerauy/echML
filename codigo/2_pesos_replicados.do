*---------------------------------------------------------
* 2- pesos replicados
*	Importa pesos replicados descargados de web INE y los guarda en formato DTA.
*---------------------------

clear all
set more off

*-------------------------------------------------------------------------------
* Importa datos originales INE 
*-------------------------------------------------------------------------------

foreach num of numlist 2022/2023 {
	foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
		import excel "$rutaori\pesos_replicados_`x'-`num'.xlsx", firstrow clear
		gen bc_anio = `num'
		gen bc_mes = `x'
		destring bc_mes, replace
		rename ID bc_correlat
		save "$rutaori\pesos_replicados_`x'_`num'.dta", replace
	}
}

clear 

foreach num of numlist 2022/2023 {
	foreach x in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" {
		append using "$rutaori\pesos_replicados_`x'_`num'.dta", force
	}
}

save "$rutapro\pesos_replicados_22_23.dta", replace

import delimited "$rutaori\pesos replicados Bootstrap anual 2022.csv", clear
gen bc_anio = 2022
cap rename id bc_correlat
save "$rutapro\pesos_anuales_22.dta", replace

import excel "$rutaori\pesos replicados Bootstrap anual 2023.xlsx", firstrow clear
gen bc_anio = 2023
cap rename ID bc_correlat
save "$rutapro\pesos_anuales_23.dta", replace
