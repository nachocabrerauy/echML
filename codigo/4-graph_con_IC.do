
*---------------------------------------------------------
* 4- graficos con IC
*	Genera matrices con la evolución de las variables e intervalos de confianza.
*	Genera los gráficos del Documento de Trabajo
*---------------------------
* Variables de interes: "des" (tasa de desempleo) "emp" (tasa de empleo) "act" (tasa de actividad) "nor" (tasa de no registro a la seguridad social) "hor" (horas trabajadas por ocupados en promedio)

* Grupos: mujeres/varones, montevideo/interior, franjas etareas, niveles educativos y cuartiles de ingreso per capita del hogar

clear all
set mem 700m
set matsize 2000
set more off

cd "$ruta"


* para 2022/2023 generamos bases auxiliares con id del hogar y percap para pegar a las bases mensuales
foreach num of numlist 22/23 { 
    use "datos_procesados\ech`num'_procesada.dta", clear
    keep id percap pesoano
    duplicates drop
    xtile cuartil = percap [pw=pesoano], nq(4)
    keep id cuartil
    save "datos_procesados\ech`num'_cuartil.dta", replace
}

use "datos_procesados\ech22_cuartil.dta", clear
append using "datos_procesados\ech23_cuartil.dta"
bysort id:  gen dup = cond(_N==1,0,_n)
bysort id: egen cuartil_pc = max(cuartil)
keep id cuartil_pc
duplicates drop
save "datos_procesados\cuartil_aux.dta", replace

clear

foreach top in "des" "emp" "act" "nor" "hor" {

foreach tipo in "a" "m" {

	foreach num of numlist 18/23 {

		* load the data: if a, then annual, if m, then monthly
		* cargar los datos: cuando "a", datos anuales, cuando "m", datos mensuales
		if "`tipo'"=="a" {
			use "datos_procesados\ech`num'_procesada.dta", clear
            xtile cuartil_pc = percap[pw=pesoano], nq(4)
			if `num' <= 21 {
				* hasta 2021 usamos pesos "normales"
				svyset [pweight=pesoano]
			}
			else { 
				merge m:1 id anio using "datos_originales\pesos_anuales_`num'.dta"
				drop _merge 
				* desde 2022 usamos matriz de pesos replicados
				svyset [pweight=pesoano], bsrweight(wr*)
			}
		}
		else {
			if `num' <= 21 {
				*hasta 2021 no hay mensuales
				continue
			}
			use "datos_procesados\ech_mens_`num'_procesada.dta", clear
            merge m:1 id using "datos_procesados\cuartil_aux.dta"
			drop _merge
			merge m:1 id anio mes using "datos_originales\pesos_replicados_22_23.dta" 
			drop if _merge != 3
			drop _merge
			svyset [pweight=w], bsrweight(wr*)
		}



* gen variables necesarias

cap g pet=(e27>13 & e27!=.)
cap drop pea
gen pea=.
replace pea=0 if pet==1

replace pea=1 if (pobpcoac>1 & pobpcoac<6)& pet==1
cap drop  desocu
g  desocu=.
replace  desocu=0 if pea==1 
replace  desocu=1 if pobpcoac>2 & pobpcoac<6

cap drop ocup
gen ocup=.
replace ocup=0 if pet==1
replace ocup=1 if pobpcoac==2 & pet==1

* dejamos horas solo para los ocupados
cap replace f85 =. if ocup!=1

gen register=-9
replace register=2 if pobpcoac==2
replace register=1 if pobpcoac==2 & f82==1
recode register (-9=.) (2=0), gen(register_alt)
gen noregister= 1 - register_alt

* now create a variable name that depends on top and saves the variable we need

if "`top'" == "des" {
    gen descvar = desocu
}
else if "`top'" == "emp" {
    gen descvar = ocup
}
else if "`top'" == "act" {
    gen descvar = pea
}
else if "`top'" == "nor" {
    gen descvar = noregister
}
else if "`top'" == "hor" {
    gen descvar = f85
}

* comenzamos a crear las matrices

* 1- totales

disp "`top' no group, `num' `tipo'"
svy: mean  descvar
matrix M = r(table)
scalar  `top'_b = M[1, 1]
scalar  `top'_lb = M[5, 1]
scalar  `top'_ub = M[6, 1]

scalar  desocu_b = M[1, 1]
scalar  desocu_lb = M[5, 1]
scalar  desocu_ub = M[6, 1]

scalar anio_s = anio

matrix  `top'A`num'_`tipo'=(anio_s, `top'_b, `top'_lb, `top'_ub)
matrix colnames  `top'A`num'_`tipo' = anio_`tipo'  `top'_b_`tipo'  `top'_lb_`tipo'  `top'_ub_`tipo'

* 2- mujeres/varones

disp "`top' sex, `num' `tipo'"

svy: mean  descvar if e26==2
matrix M = r(table)
scalar  `top'fem_b = M[1, 1]
scalar  `top'fem_lb = M[5, 1]
scalar  `top'fem_ub = M[6, 1]

svy: mean  descvar if e26==1
matrix M = r(table)
scalar  `top'masc_b = M[1, 1]
scalar  `top'masc_lb = M[5, 1]
scalar  `top'masc_ub = M[6, 1]

matrix  `top'B`num'_`tipo'=(anio_s, `top'fem_b, `top'fem_lb, `top'fem_ub, `top'masc_b, `top'masc_lb, `top'masc_ub)
matrix colnames  `top'B`num'_`tipo'= anio_`tipo'  `top'fem_b_`tipo'  `top'fem_lb_`tipo'  `top'fem_ub_`tipo'  `top'masc_b_`tipo'  `top'masc_lb_`tipo'  `top'masc_ub_`tipo'

* 3- mvd/interior
disp "`top' region, `num' `tipo'"

svy: mean  descvar if dpto==1
matrix M = r(table)
scalar  `top'mdeo_b = M[1, 1]
scalar  `top'mdeo_lb = M[5, 1]
scalar  `top'mdeo_ub = M[6, 1]

svy: mean  descvar if dpto!=1
matrix M = r(table)
scalar  `top'int_b = M[1, 1]
scalar  `top'int_lb = M[5, 1]
scalar  `top'int_ub = M[6, 1]

matrix  `top'C`num'_`tipo'=(anio_s, `top'mdeo_b, `top'mdeo_lb, `top'mdeo_ub, `top'int_b, `top'int_lb, `top'int_ub)
matrix colnames  `top'C`num'_`tipo'= anio_`tipo'  `top'mdeo_b_`tipo'  `top'mdeo_lb_`tipo'  `top'mdeo_ub_`tipo'  `top'int_b_`tipo'  `top'int_lb_`tipo'  `top'int_ub_`tipo'

* 4- grupos etarios
disp "`top' edad, `num' `tipo'"

svy: mean  descvar if e27<18 & e27>13
matrix M = r(table)
scalar  `top'edad1_b = M[1, 1]
scalar  `top'edad1_lb = M[5, 1]
scalar  `top'edad1_ub = M[6, 1]

svy: mean  descvar if e27<25 & e27>17
matrix M = r(table)
scalar  `top'edad2_b = M[1, 1]
scalar  `top'edad2_lb = M[5, 1]
scalar  `top'edad2_ub = M[6, 1]

svy: mean  descvar if e27<35 & e27>24
matrix M = r(table)
scalar  `top'edad3_b = M[1, 1]
scalar  `top'edad3_lb = M[5, 1]
scalar  `top'edad3_ub = M[6, 1]

svy: mean  descvar if e27<45 & e27>34
matrix M = r(table)
scalar  `top'edad4_b = M[1, 1]
scalar  `top'edad4_lb = M[5, 1]
scalar  `top'edad4_ub = M[6, 1]

svy: mean  descvar if e27<61 & e27>44
matrix M = r(table)
scalar  `top'edad5_b = M[1, 1]
scalar  `top'edad5_lb = M[5, 1]
scalar  `top'edad5_ub = M[6, 1]

svy: mean  descvar if e27>60
matrix M = r(table)
scalar  `top'edad6_b = M[1, 1]
scalar  `top'edad6_lb = M[5, 1]
scalar  `top'edad6_ub = M[6, 1]

matrix  `top'D`num'_`tipo'=(anio_s, `top'edad1_b, `top'edad1_lb, `top'edad1_ub, `top'edad2_b, `top'edad2_lb, `top'edad2_ub, `top'edad3_b, `top'edad3_lb, `top'edad3_ub, `top'edad4_b, `top'edad4_lb, `top'edad4_ub, `top'edad5_b, `top'edad5_lb, `top'edad5_ub, `top'edad6_b, `top'edad6_lb, `top'edad6_ub)
matrix colnames  `top'D`num'_`tipo'= anio_`tipo'  `top'edad1_b_`tipo'  `top'edad1_lb_`tipo'  `top'edad1_ub_`tipo'  `top'edad2_b_`tipo'  `top'edad2_lb_`tipo'  `top'edad2_ub_`tipo'  `top'edad3_b_`tipo'  `top'edad3_lb_`tipo'  `top'edad3_ub_`tipo'  `top'edad4_b_`tipo'  `top'edad4_lb_`tipo'  `top'edad4_ub_`tipo'  `top'edad5_b_`tipo'  `top'edad5_lb_`tipo'  `top'edad5_ub_`tipo'  `top'edad6_b_`tipo'  `top'edad6_lb_`tipo'  `top'edad6_ub_`tipo'

* 5- nivel educativo
disp "`top' educ, `num' `tipo'"

svy: mean  descvar if nivel_aux<2
matrix M = r(table)
scalar  `top'bc_educ1_b = M[1, 1]
scalar  `top'bc_educ1_lb = M[5, 1]
scalar  `top'bc_educ1_ub = M[6, 1]

svy: mean  descvar if nivel_aux==2 & bc_edu<12
matrix M = r(table)
scalar  `top'bc_educ2_b = M[1, 1]
scalar  `top'bc_educ2_lb = M[5, 1]
scalar  `top'bc_educ2_ub = M[6, 1]
svy: mean  descvar if nivel_aux==2 & bc_edu>11
matrix M = r(table)
scalar  `top'bc_educ3_b = M[1, 1]
scalar  `top'bc_educ3_lb = M[5, 1]
scalar  `top'bc_educ3_ub = M[6, 1]
svy: mean  descvar if nivel_aux==3 & bc_edu<13
matrix M = r(table)
scalar  `top'bc_educ4_b = M[1, 1]
scalar  `top'bc_educ4_lb = M[5, 1]
scalar  `top'bc_educ4_ub = M[6, 1]
svy: mean  descvar if nivel_aux==4 
matrix M = r(table)
scalar  `top'bc_educ5_b = M[1, 1]
scalar  `top'bc_educ5_lb = M[5, 1]
scalar  `top'bc_educ5_ub = M[6, 1]
cap g univcomp=0
cap g univincomp=0
replace univcomp=1 if (nivel_aux==5 & bc_edu>16)| (nivel_aux==3 & bc_edu>13)
replace univincomp=1 if (nivel_aux==5 & bc_edu<17)| (nivel_aux==3 & bc_edu>12 & bc_edu<14)

svy: mean  descvar if univincomp==1
matrix M = r(table)
scalar  `top'bc_educ6_b = M[1, 1]
scalar  `top'bc_educ6_lb = M[5, 1]
scalar  `top'bc_educ6_ub = M[6, 1]
svy: mean  descvar if univcomp==1
matrix M = r(table)
scalar  `top'bc_educ7_b = M[1, 1]
scalar  `top'bc_educ7_lb = M[5, 1]
scalar  `top'bc_educ7_ub = M[6, 1]
*****universidad en general (completa a incompleta)
svy: mean  descvar if nivel_aux==5|(nivel_aux==3 & bc_edu>12)
matrix M = r(table)
scalar  `top'univgral_b = M[1, 1]
scalar  `top'univgral_lb = M[5, 1]
scalar  `top'univgral_ub = M[6, 1]

matrix  `top'E`num'_`tipo'=(anio_s, `top'bc_educ1_b, `top'bc_educ1_lb, `top'bc_educ1_ub, `top'bc_educ2_b, `top'bc_educ2_lb, `top'bc_educ2_ub, `top'bc_educ3_b, `top'bc_educ3_lb, `top'bc_educ3_ub, `top'bc_educ4_b, `top'bc_educ4_lb, `top'bc_educ4_ub, `top'bc_educ5_b, `top'bc_educ5_lb, `top'bc_educ5_ub, `top'bc_educ6_b, `top'bc_educ6_lb, `top'bc_educ6_ub, `top'bc_educ7_b, `top'bc_educ7_lb, `top'bc_educ7_ub, `top'univgral_b, `top'univgral_lb, `top'univgral_ub)
matrix colnames  `top'E`num'_`tipo'= anio_`tipo'  `top'bc_educ1_b_`tipo'  `top'bc_educ1_lb_`tipo'  `top'bc_educ1_ub_`tipo'  `top'bc_educ2_b_`tipo'  `top'bc_educ2_lb_`tipo'  `top'bc_educ2_ub_`tipo'  `top'bc_educ3_b_`tipo'  `top'bc_educ3_lb_`tipo'  `top'bc_educ3_ub_`tipo'  `top'bc_educ4_b_`tipo'  `top'bc_educ4_lb_`tipo'  `top'bc_educ4_ub_`tipo'  `top'bc_educ5_b_`tipo'  `top'bc_educ5_lb_`tipo'  `top'bc_educ5_ub_`tipo'  `top'bc_educ6_b_`tipo'  `top'bc_educ6_lb_`tipo'  `top'bc_educ6_ub_`tipo'  `top'bc_educ7_b_`tipo'  `top'bc_educ7_lb_`tipo'  `top'bc_educ7_ub_`tipo'  `top'univgral_b_`tipo'  `top'univgral_lb_`tipo'  `top'univgral_ub_`tipo'

* 6- quartiles of percapita income
disp "`top' ingreso, `num' `tipo'"

svy: mean  descvar if cuartil_pc==1
matrix M = r(table)
scalar  `top'q1_b = M[1, 1]
scalar  `top'q1_lb = M[5, 1]
scalar  `top'q1_ub = M[6, 1]

svy: mean  descvar if cuartil_pc==2
matrix M = r(table)
scalar  `top'q2_b = M[1, 1]
scalar  `top'q2_lb = M[5, 1]
scalar  `top'q2_ub = M[6, 1]

svy: mean  descvar if cuartil_pc==3
matrix M = r(table)
scalar  `top'q3_b = M[1, 1]
scalar  `top'q3_lb = M[5, 1]
scalar  `top'q3_ub = M[6, 1]

svy: mean  descvar if cuartil_pc==4
matrix M = r(table)
scalar  `top'q4_b = M[1, 1]
scalar  `top'q4_lb = M[5, 1]
scalar  `top'q4_ub = M[6, 1]

matrix  `top'F`num'_`tipo'=(anio_s, `top'q1_b, `top'q1_lb, `top'q1_ub, `top'q2_b, `top'q2_lb, `top'q2_ub, `top'q3_b, `top'q3_lb, `top'q3_ub, `top'q4_b, `top'q4_lb, `top'q4_ub)
matrix colnames `top'F`num'_`tipo'= anio_`tipo'  `top'q1_b_`tipo'  `top'q1_lb_`tipo'  `top'q1_ub_`tipo'  `top'q2_b_`tipo'  `top'q2_lb_`tipo'  `top'q2_ub_`tipo'  `top'q3_b_`tipo'  `top'q3_lb_`tipo'  `top'q3_ub_`tipo'  `top'q4_b_`tipo'  `top'q4_lb_`tipo'  `top'q4_ub_`tipo'
	}
}


mat  `top'A_a= `top'A18_a
mat  `top'B_a= `top'B18_a
mat  `top'C_a= `top'C18_a
mat  `top'D_a= `top'D18_a
mat  `top'E_a= `top'E18_a
mat  `top'F_a= `top'F18_a

foreach i of numlist 19/23 {
mat  `top'A_a=  `top'A_a\ `top'A`i'_a
mat  `top'B_a=  `top'B_a\ `top'B`i'_a
mat  `top'C_a=  `top'C_a\ `top'C`i'_a
mat  `top'D_a=  `top'D_a\ `top'D`i'_a
mat  `top'E_a=  `top'E_a\ `top'E`i'_a
mat  `top'F_a=  `top'F_a\ `top'F`i'_a
}

local ncolsA = colsof( `top'A_a)
local ncolsB = colsof( `top'B_a)
local ncolsC = colsof( `top'C_a)
local ncolsD = colsof( `top'D_a)
local ncolsE = colsof( `top'E_a)
local ncolsF = colsof( `top'F_a)

mat  `top'A_m = J(3, `ncolsA', .)
mat  `top'B_m = J(3, `ncolsB', .) 
mat  `top'C_m = J(3, `ncolsC', .)
mat  `top'D_m = J(3, `ncolsD', .) 
mat  `top'E_m = J(3, `ncolsE', .) 
mat  `top'F_m = J(3, `ncolsF', .) 


mat `top'A_m= `top'A_m \ `top'A21_a
mat `top'B_m= `top'B_m \ `top'B21_a
mat `top'C_m= `top'C_m \ `top'C21_a
mat `top'D_m= `top'D_m \ `top'D21_a
mat `top'E_m= `top'E_m \ `top'E21_a
mat `top'F_m= `top'F_m \ `top'F21_a

local colnamesA : colnames  `top'A22_m
local colnamesB : colnames  `top'B22_m
local colnamesC : colnames  `top'C22_m
local colnamesD : colnames  `top'D22_m
local colnamesE : colnames  `top'E22_m
local colnamesF : colnames  `top'F22_m

mat colnames  `top'A_m = `colnamesA'
mat colnames  `top'B_m = `colnamesB'
mat colnames  `top'C_m = `colnamesC'
mat colnames  `top'D_m = `colnamesD'
mat colnames  `top'E_m = `colnamesE'
mat colnames  `top'F_m = `colnamesF'

foreach i of numlist 22/23 {
mat  `top'A_m=  `top'A_m\ `top'A`i'_m
mat  `top'B_m=  `top'B_m\ `top'B`i'_m
mat  `top'C_m=  `top'C_m\ `top'C`i'_m
mat  `top'D_m=  `top'D_m\ `top'D`i'_m
mat  `top'E_m=  `top'E_m\ `top'E`i'_m
mat  `top'F_m=  `top'F_m\ `top'F`i'_m
}

mat  `top'A =  `top'A_a,  `top'A_m
mat  `top'B =  `top'B_a,  `top'B_m
mat  `top'C =  `top'C_a,  `top'C_m
mat  `top'D =  `top'D_a,  `top'D_m
mat  `top'E =  `top'E_a,  `top'E_m
mat  `top'F =  `top'F_a,  `top'F_m

matlist  `top'A
matlist  `top'B
matlist  `top'C
matlist  `top'D
matlist  `top'E
matlist  `top'F
}

local lab_fem " mujeres"
local lab_masc " varones"
local lab_mdeo " Montevideo"
local lab_int " interior"
local lab_edad1 " 14-17 años"
local lab_edad2 " 18-24 años"
local lab_edad3 " 25-34 años"
local lab_edad4 " 35-44 años"
local lab_edad5 " 45-60 años"
local lab_edad6 " 61 años o más"
local lab_bc_educ1 " hasta prim."
local lab_bc_educ2 " sec. incompleta"
local lab_bc_educ3 " sec. completa"
local lab_bc_educ4 " UTU"
local lab_bc_educ5 " mae/prof."
local lab_bc_educ6 " univ. incompleta"
local lab_bc_educ7 " univ. completa"
local lab_univgral " univ. comp/inc."
local lab_q1 " primer cuartil"
local lab_q2 " segundo cuartil"
local lab_q3 " tercer cuartil"
local lab_q4 " cuarto cuartil"
local lab_des "Desempleo" 
local lab_emp "Empleo" 
local lab_act "Actividad" 
local lab_nor "No registro" 
local lab_hor "Horas"

cd "$ruta\resultados"

* comenzamos a crear los graficos
foreach top in des emp act nor  hor {

clear
matsave  `top'A, replace

local X = "`top'"
local label1 = "`lab_`top''"

qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'") ///
	   name(`X'_graph, replace)
	  

graph export "`top'.png", name( `top'_graph) replace

clear
matsave  `top'B, replace

foreach suf in fem masc {

local X = "`top'`suf'"
local label1 = "`lab_`top''"
local label2 = "`lab_`suf''"
			
qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'`label2'") ///
	   name(`X'_graph, replace)
graph export "`X'.png", name(`X'_graph) replace
	   }

qui graph combine  `top'fem_graph  `top'masc_graph, rows(1) cols(2) xsize(15) ysize(6) name(combined_graph, replace)
graph export "`top'_sexo.png", name(combined_graph) replace

clear
matsave  `top'C, replace

foreach suf in mdeo int {

local X = "`top'`suf'"
local label1 = "`lab_`top''"
local label2 = "`lab_`suf''"
			
qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'`label2'") ///
	   name(`X'_graph, replace)
graph export "`X'.png", name(`X'_graph) replace

	   }


qui graph combine  `top'mdeo_graph  `top'int_graph, rows(1) cols(2) xsize(15) ysize(6) name(combined_graph, replace)
graph export "`top'_mvd_int.png", name(combined_graph) replace

clear
matsave  `top'D, replace

foreach suf in edad1 edad2 edad3 edad4 edad5 edad6 {

local X = "`top'`suf'"
local label1 = "`lab_`top''"
local label2 = "`lab_`suf''"
			
qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'`label2'") ///
	   name(`X'_graph, replace)
graph export "`X'.png", name(`X'_graph) replace
	   }


qui graph combine  `top'edad1_graph  `top'edad2_graph  `top'edad3_graph  `top'edad4_graph  `top'edad5_graph  `top'edad6_graph, rows(1) cols(2) xsize(15) ysize(18) name(combined_graph, replace)
graph export "`top'_edad.png", name(combined_graph) replace

clear
matsave  `top'E, replace

foreach suf in bc_educ1 bc_educ2 bc_educ3 bc_educ4 bc_educ5 bc_educ6 bc_educ7 univgral {

local X = "`top'`suf'"
local label1 = "`lab_`top''"
local label2 = "`lab_`suf''"
			
qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'`label2'") ///
	   name(`X'_graph, replace)
	  
graph export "`X'.png", name(`X'_graph) replace
	   }

qui graph combine  `top'bc_educ1_graph  `top'bc_educ2_graph  `top'bc_educ3_graph  `top'bc_educ4_graph  `top'bc_educ5_graph  `top'bc_educ6_graph  `top'bc_educ7_graph  `top'univgral_graph, rows(1) cols(2) xsize(15) ysize(24) name(combined_graph, replace)
graph export "`top'_educ.png", name(combined_graph) replace


clear
matsave  `top'F, replace

foreach suf in q1 q2 q3 q4 {


local X = "`top'`suf'"
local label1 = "`lab_`top''"
local label2 = "`lab_`suf''"
			
qui twoway (rarea `X'_lb_a `X'_ub_a anio_a, color(blue%10) lwidth(none)) ///
       (line `X'_b_a anio_a, lcolor(blue) lwidth(medium)) ///
       (rarea `X'_lb_m `X'_ub_m anio_a, color(red%10) lwidth(none)) ///
       (line `X'_b_m anio_a, lcolor(red) lwidth(medium)), ///
               legend(order(2 "Implantación" 4 "Seguimiento") position(6) cols(2)) ///
       xtitle("") ytitle("") ///
       title("`label1'`label2'") ///
	   name(`X'_graph, replace)
graph export "`X'.png", name(`X'_graph) replace
	   }


qui graph combine `top'q1_graph  `top'q2_graph  `top'q3_graph  `top'q4_graph, rows(1) cols(2) xsize(15) ysize(12) name(combined_graph, replace)
graph export "`top'_cuartil.png", name(combined_graph) replace

}