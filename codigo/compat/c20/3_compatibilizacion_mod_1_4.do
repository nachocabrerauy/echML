*-------------------------------------------------------------------------------
* Variables de identificación general
rename numero bc_correlat
rename nper bc_nper
rename pesomen bc_pesomen

* no viene pesoan, lo aproximamos con pesomen
gen bc_pesoan = bc_pesomen/12
replace bc_pesoan = floor(bc_pesoan)

g bc_area=.
replace bc_area=1 if region_4==1 // Montevideo
replace bc_area=2 if region_4==2 // Interior mayores de 5000
replace bc_area=3 if region_4==3 // Interior menores de 5000
replace bc_area=4 if region_4==4 // rurales - rural dispersa

g bc_filtloc=(region_4<3) // localidades de más de 5000 
recode bc_filtloc (0=2)

*-------------------------------------------------------------------------------
* 1- Características generales y de las personas

* sexo
g bc_pe2=e26

* edad
g bc_pe3=e27

* parentesco
g bc_pe4=-9
	replace bc_pe4=1 if e30==1 
	replace bc_pe4=2 if e30==2 
	replace bc_pe4=3 if e30==3 | e30==4 | e30==5  
	replace bc_pe4=4 if e30==7 | e30==8 
	replace bc_pe4=5 if e30==6 | e30==9 | e30==10 | e30==11 | e30==12  
	replace bc_pe4=6 if e30==13
	replace bc_pe4=7 if e30==14 
	
* estado civil.  

* No hay info en 2020 

*-------------------------------------------------------------------------------
* 2- Atención de la Salud

g bc_pe6a=-15
	replace bc_pe6a=4 if (e45_cv==1 & (e45_1_1_cv !=1 | e45_1_1_cv!=4)) | e45_cv==4 | e45_cv==5 | e45_cv==6
	replace bc_pe6a=2 if e45_cv==2 & e45_2_1_cv!=1 & e45_2_1_cv!=6
	replace bc_pe6a=3 if (e45_cv==1 & (e45_1_1_cv==1 | e45_1_1_cv==4)) | (e45_cv==2 & (e45_2_1_cv==1 |e45_2_1_cv==6)) | (e45_cv==3 & (e45_3_1_cv==1 | e45_3_1_cv ==6))
	replace bc_pe6a=5 if ((e45_cv==3 & (e45_3_1_cv!=1 | e45_3_1_cv!=6)) | e46_cv==1) & bc_pe6a!=3
	replace bc_pe6a=1 if e45_cv==7
	
g bc_pe6a1=-15
	replace bc_pe6a1=1 if bc_pe6a==3 & ((pobpcoac==2 & (f82==1|f96==1)) | pobpcoac==5)
	replace bc_pe6a1=2 if bc_pe6a==3 & bc_pe6a1!=1
	replace bc_pe6a1=-9 if bc_pe6a!=3

recode bc_pe6a (2=2) (3=-9) (4=3) (5=4), gen(bc_pe6b)
 

*-------------------------------------------------------------------------------
* 3- Educacion

*asiste
g bc_pe11=2 
	replace bc_pe11=1 if (e193==1|e197==1|e201==1|e212==1|e215==1|e218==1|e221==1|e224==1) 
	replace bc_pe11=-9 if bc_pe3<3 & bc_pe3!=.

*asistio
g bc_pe12=e49
	replace bc_pe12=-9 if (e193==1|e197==1|e201==1|e212==1|e215==1|e218==1|e221==1|e224==1) 
	replace bc_pe12=-9 if bc_pe3<3 & bc_pe3!=.
*asistencia actual pco o privada
g bc_pe13=-13

forvalues i =2/11 { 
	
	recode e51_`i' 0.1=9
	
	}
	
	
*nivel
g bc_nivel=-13
g nivel_aux=-15
 
replace nivel_aux=0 if ((e51_2==0 & e51_3==0) | ((e193==1 | e193==2) & e51_2==9))  

replace nivel_aux=1  if ((((e51_2>0 & e51_2<=6) | (e51_3>0 & e51_3<=6)) &  e51_4==0) | (e51_2==6 & e51_4==9))  /* //Primaria */

replace nivel_aux=2 if ((((e51_4>0 & e51_4<=3) | (e51_5>0 & e51_5<=3) | (e51_6>0 & e51_4<=6)) & (e51_8==0 & e51_9==0 & e51_10==0)) | (e51_7!=0 & e51_7_1==3) | (e51_4==3 & e51_8==9) | (e51_5==3 & e51_8==9)) // Secundaria 
 
replace nivel_aux=3  if  ((e51_7>0 &  e51_7<=9 & e51_7_1<3) | (e51_7!=0 & e51_4==0 & e51_5==0 & e51_6==0) /* // UTU
*/ & e51_8==0 & e51_9==0 & e51_10==0 )

replace nivel_aux=4  if (e51_8>0 & e51_8<=5) &  e51_9==0 &  e51_10==0 &  e51_11==0  // magisterio o profesorado

replace nivel_aux=5  if ((e51_9>0 & e51_9<=9) | (e51_10>0 & e51_10<=9) | (e51_11>0 & e51_11<=9)) // universidad o similar

replace nivel_aux=0 if nivel_aux==-15 & (e51_2==9 | e51_3==9)

*anios de bc_educacion
g bc_edu=-15

*Primaria
replace bc_edu=0 if nivel_aux==0
replace bc_edu= e51_2 if nivel_aux==1 & ((e51_2>=e51_3 & e51_2<9) | (e51_2>0 & e51_2<9 & e51_3==9))
replace bc_edu= e51_3 if nivel_aux==1 & ((e51_3>e51_2 & e51_3<9)  | (e51_3>0 & e51_3<9 & e51_2==9))

*Secundaria
replace bc_edu=6+e51_4 if nivel_aux==2 & e51_4<=3 & e51_4>0 // Secundaria hasta ciclo basico
replace bc_edu=9+e51_5 if nivel_aux==2 & e51_4==3 & e51_5<9 & e51_5>0 // Bachillerato comun
replace bc_edu=9+e51_6 if nivel_aux==2 & e51_4==3 & e51_6<9 &  e51_6>0 // Bachillerato tecnologico
replace bc_edu=9 if nivel_aux==2 & e51_4==3 & e51_5==9 // Termino CB pero no tiene informacion de secundaria
replace bc_edu=12 if nivel_aux==2 & e51_4==3 & e51_5==9 & e212_1==1 // Completa secundaria mediante UTU
replace bc_edu=9 if nivel_aux==2 & e51_4==3 & e51_6==9 // Tiene los 3 anios de CB pero no hizo bachillerato tecnologico
replace bc_edu=12 if nivel_aux==2 & e51_4==3 & e51_6==9 & e212_1==1 
replace bc_edu=6 if nivel_aux==2 & e51_4==9 // No tiene anios aprobados en secundaria
replace bc_edu=9+e51_5 if bc_edu==. & nivel_aux==2  & e51_5!=0 
replace bc_edu=9+e51_6 if bc_edu==. & nivel_aux==2 

* UTU actual
replace bc_edu=6+e51_7 if nivel_aux==3 & e51_7<9
replace bc_edu=6 if nivel_aux==3 & e51_7==9

*magisterio
replace bc_edu=e51_8+12 if nivel_aux==4 & e51_8<9 & e51_8>0
replace bc_edu=12 if nivel_aux==4 & e51_8==9 
replace bc_edu=15 if nivel_aux==4 & e51_8==9 & e215_1==1 
*Terciaria
replace bc_edu=e51_9+12 if nivel_aux==5 & e51_9<9  &  e51_9>0 // Se suman los anios aprobados
replace bc_edu=e51_10+12 if nivel_aux==5 & e51_10<9  &  e51_10>0 // Se suman los anios aprobados en terciaria no universitaria
replace bc_edu=e51_11+12+e51_9 if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9>=e51_10  // Agrega anios de posgrado
replace bc_edu=e51_11+12+e51_10 if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9<e51_10  // Agrega anios de posgrado para los terciarios no universitaria
replace bc_edu=12 if nivel_aux==5 & e51_9==9 // No tiene anios aprobados en el nivel
replace bc_edu=12 if nivel_aux==5 & e51_10==9 // No tiene anios aprobados en el nivel
replace bc_edu=15 if nivel_aux==5 & e51_9==9 & e218_1==1 // No licenciaturas
replace bc_edu=16 if nivel_aux==5 & e51_10==9 & e218_1==1 // No universitaria completa 
replace bc_edu=12+e51_9 if nivel_aux==5 & e51_11==9  & e51_9>=e51_10 // Desempate asignado a universidad y no a terciaria
replace bc_edu=12+e51_10 if nivel_aux==5 & e51_11==9  & e51_9<e51_10 // Desempate asignado a terciaria y no a universidad

recode bc_edu 23/38=22

*-------------------------------------------------------------------------------
* 4- Mercado de trabajo

* Condición de actividad
g bc_pobp = pobpcoac
recode bc_pobp (10=9)

* Categoría de ocupación
g bc_pf41=f73
	replace bc_pf41=7 if f73==8 // 
	replace bc_pf41=-9 if f73==0

g bc_cat2=-9
	replace bc_cat2=1 if f73==1
	replace bc_cat2=2 if f73==2
	replace bc_cat2=3 if f73==4
	replace bc_cat2=4 if f73==5|f73==6
	replace bc_cat2=5 if f73==3|f73==7|f73==8
	
* Tamaño del establecimiento
g bc_pf081=-9
	replace bc_pf081=1 if (f77==1 | f77==2 | f77==3) //tamaño chico. Sin info 2020
	replace bc_pf081=2 if (f77==5 | f77==6 | f77==7) //tamaño grande. Sin info 2020

g bc_pf082=-9
	replace bc_pf082=1 if f77==1 // no hay info en 2020
	replace bc_pf082=2 if f77==2
	replace bc_pf082=3 if f77==3

* Rama del establecimiento 
g bc_pf40=f72_2  

g bc_rama=-9

	replace bc_rama=1 if f72_2>0000 & f72_2<1000
	replace bc_rama=2 if f72_2>1000 & f72_2<3500
	replace bc_rama=3 if f72_2>3500 & f72_2<3700
	replace bc_rama=4 if f72_2>4000 & f72_2<4500
	replace bc_rama=5 if (f72_2>=4500&f72_2<4900)|(f72_2>=5500&f72_2<5700)
	replace bc_rama=6 if (f72_2>=4900&f72_2<5500)|(f72_2>=5800&f72_2<6400)
	replace bc_rama=7 if f72_2>=6400&f72_2<8300
	replace bc_rama=8 if f72_2>=8300&f72_2<9910 | (f72_2>= 3700 & f72_2<=3900)

* Tipo de ocupación 
 
g bc_pf39=f71_2
	replace bc_pf39=-9 if bc_pf39==.&bc_pobp!=2
	replace bc_pf39=-15 if bc_pf39==.&bc_pobp==2
	


cap drop pf39aux
g pf39aux=bc_pf39
	replace pf39aux=0 if bc_pf39>0 & bc_pf39<130

cap drop bc_tipo_ocup
g bc_tipo_ocup=trunc(pf39aux/1000)
	replace bc_tipo_ocup=-9 if bc_tipo_ocup==0&bc_pobp!=2
drop pf39aux


* Cantidad de empleos
g bc_pf07=f70
recode bc_pf07 (0=-9)

* Horas trabajadas 

g bc_horas_hab=f85+f98 // horas semanales trabajadas habitualmente en total
recode bc_horas_hab (0=-9)
g bc_horas_hab_1=f85   // horas semanales trabajadas habitualmente en trabajo principal
recode bc_horas_hab_1 (0=-9)

g bc_horas_sp=-13 // horas semanales trabajadas semana pasada en total
g bc_horas_sp_1=-13 // horas semanales trabajadas semana pasada en trabajo principal

* Motivo por el que no trabaja
g bc_pf04=f69
recode bc_pf04 (3=4) (4=3) (5/6=4) (0=-9) 
* Busqueda de trabajo
 
g bc_pf21= f107 // buscó trabajo la semana pasada
recode bc_pf21 (0=-9)
 
g bc_pf22=f108 // causa por la que no buscó trabajo 
recode bc_pf22 (1=4) (2=1) (3=2) (4=3) (5/6=4) (0=-9)

* Duración desempleo (semanas)
 
g bc_pf26=f113
replace bc_pf26=-9 if bc_pobp<3|bc_pobp>5
 
 g bc_pf34=f122 // causas por las que dejó último trabajo
recode bc_pf34 (1=2) (2=1) (4/9=3) (0=-9)
 
* Trabajo registrado
 g bc_reg_disse=-9
	replace bc_reg_disse=2 if bc_pobp==2
	replace bc_reg_disse=1 if (e45_1_1_cv==1 | e45_2_1_cv==1 | e45_3_1_cv==1 | bc_pf41==2) & bc_pobp==2
 
g bc_register=-9
	replace bc_register=2 if bc_pobp==2
	replace bc_register=1 if bc_pobp==2&f82==1

g bc_register2=-9
	replace bc_register2=2 if bc_pobp==2
	replace bc_register2=1 if bc_pobp==2&(f82==1|f96==1)

* Subocupado
g bc_subocupado=-9
	replace bc_subocupado=2 if bc_pobp==2
	replace bc_subocupado=1 if f102==1&f104==5&bc_horas_hab>0&bc_horas_hab<40&bc_horas_hab!=.

g bc_subocupado1=-9
	replace bc_subocupado1=2 if bc_pobp==2
	replace bc_subocupado1=1 if (f101==1|f102==1)&f103==1&f104==5&f105!=7&bc_horas_hab>0&bc_horas_hab<40&bc_horas_hab!=.

*-------------------------------------------------------------------------------
* ipc

cap drop bc_ipc
g bc_ipc=.

replace bc_ipc=0.36059001 if bc_mes==1&bc_anio==2020
replace bc_ipc=0.35334197 if bc_mes==2&bc_anio==2020
replace bc_ipc=0.35086361 if bc_mes==3&bc_anio==2020
replace bc_ipc=0.34697619 if bc_mes==4&bc_anio==2020
replace bc_ipc=0.34116334 if bc_mes==5&bc_anio==2020
replace bc_ipc=0.33934600 if bc_mes==6&bc_anio==2020
replace bc_ipc=0.33951604 if bc_mes==7&bc_anio==2020
replace bc_ipc=0.33722720  if bc_mes==8&bc_anio==2020
replace bc_ipc=0.33493891  if bc_mes==9&bc_anio==2020
replace bc_ipc=0.33247371 if bc_mes==10&bc_anio==2020
replace bc_ipc=0.33051286 if bc_mes==11&bc_anio==2020
replace bc_ipc=0.32932997 if bc_mes==12&bc_anio==2020

*-------------------------------------------------------------------------------
* BPC

cap drop bpc
gen bpc=.
replace bpc = 4519 if bc_mes>1	& bc_anio==2020
replace bpc = 4154 if bc_mes==1	& bc_anio==2020


*-------------------------------------------------------------------------------
* Drop servicio doméstico
preserve
keep if e30==14
save "$rutacom/servdom20.dta", replace
restore
drop if e30==14
