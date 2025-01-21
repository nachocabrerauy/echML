*-------------------------------------------------------------------------------
* Tramo de compatibilización para estadísticas ML
*-------------------------------------------------------------------------------


*-------------------------------------------------------------------------------
* 2_correcc_datos.do
*-------------------------------------------------------------------------------

* Se renombran variables del ine (para variables de ingreso se deshace el rename
* en paso 8.)
cap rename ytdop ine_ytdop 
cap rename ytdos ine_ytdos 
cap rename ytinde ine_ytinde 
cap rename ytransf ine_ytransf 
cap rename pt1 ine_pt1
cap rename pt2 ine_pt2
cap rename pt4 ine_pt4
cap rename ht13 ine_ht13
cap rename yhog ine_yhog
cap rename ysvl ine_ysvl
cap rename ysvl_sag ine_ysvl_sag
cap rename ypat_tot ine_ypat_tot
cap rename ytot_sinagui ine_ytot_sinagui
cap rename ypas_tot ine_ypas_tot
cap rename mes bc_mes
cap rename anio bc_anio
cap replace bc_anio=2021 if bc_anio==.
cap rename dpto bc_dpto
cap rename ccz bc_ccz
cap rename INDAEMER indaemer
recode bc_ccz (0=-9)

cap recode mto_cuot (.=0)  
cap recode mto_emer (.=0)
cap recode mto_hogc (.=0)
	
*-------------------------------------------------------------------------------
* Recodificación de datos

destring region_4, replace
destring bc_dpto, replace
destring bc_mes, replace
destring bc_anio, replace
destring bc_ccz, replace
cap destring f72_2, replace force
cap destring f91_2, replace 
cap destring f71_2, replace force 
cap destring e49, replace force

*-------------------------------------------------------------------------------
* 3_compatibilizacion_mod_1_4.do
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Variables de identificación general
rename id bc_correlat
rename nper bc_nper

* En las bases mensuales no hay relación de parentesco
* Genero un conteo de miembros del hogar para cuando haya que asignar un valor 
* a un solo miembro

sort bc_correlat bc_nper
by bc_correlat: egen n_miembro = seq()

g bc_pesomen=w


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

*-------------------------------------------------------------------------------
* 3- Educación

*asiste
g bc_pe11=2 
	replace bc_pe11=1 if e49==3
	replace bc_pe11=-9 if bc_pe3<3 & bc_pe3!=.

*asistió
g bc_pe12=2
	replace bc_pe12=1 if e49==1
	replace bc_pe12=-9 if bc_pe11==1 | bc_pe11==-9

* Nivel
g bc_nivel=-13
g nivel_aux=-15

** Armo una variable similar a la que hacía el INE sobre la exigencia del curso de UTU
g bc_e51_7_1=.
replace bc_e51_7_1=1 if inrange(e214_1,50000,59999) // requisito: secundaria completa
replace bc_e51_7_1=2 if inrange(e214_1,30000,39999) // requisito: ciclo basico
replace bc_e51_7_1=3 if inrange(e214_1,20000,29999) // requisito: secundaria completa
replace bc_e51_7_1=4 if inrange(e214_1,1,19999) // requisito: nada

** Nunca asistió
replace nivel_aux=0 	if bc_pe11==2 & bc_pe12==2
replace nivel_aux=0 	if ((e51_2==0 & e51_3==0) | ((e197_1==2) & e51_2==9)) // Por qué no ponemos la primaria especial??
** Primaria
replace nivel_aux=1  	if ((((e51_2>0 & e51_2<=6) | (e51_3>0 & e51_3<=6)) &  (e51_4_a==0 & e51_4_b==0)) | (e51_2==6 & (e51_4_a==9 | e51_4_b==9)))
** Secundaria
replace nivel_aux=2 	if (((((e51_4_a>0 & e51_4_a<=3) | (e51_4_b>0 & e51_4_b<=3)) | (e51_5>0 & e51_5<=3) | (e51_6>0 & e51_6<=3)) & (e51_8==0 & e51_9==0 & e51_10==0)) | (e51_6a!=0 & bc_e51_7_1==3) | (e51_4_a==3 & e51_8==9) | (e51_4_b==3 & e51_8==9) | (e51_5==3 & e51_8==9))
** UTU
replace nivel_aux=3  	if ((e51_6a>0 & e51_6a<=9 & bc_e51_7_1<3) | (e51_6a!=0 & e51_4_a==0 & e51_4_b==0 & e51_5==0 & e51_6==0) & e51_8==0 & e51_9==0 & e51_10==0)
** Magisterio o profesorado
replace nivel_aux=4  	if (e51_8>0 & e51_8<=5) & e51_9==0 & e51_10==0 & e51_11==0
** Universidad o similar
replace nivel_aux=5  	if ((e51_9>0 & e51_9<=9) | (e51_10>0 & e51_10<=9) | (e51_11>0 & e51_11<=9))

replace nivel_aux=0 	if nivel_aux==-15 & (e51_2==9 | e51_3==9)


*# Años de bc_educación
g bc_edu=-15

*Primaria
replace bc_edu=0 			if nivel_aux==0
replace bc_edu=e51_2 		if nivel_aux==1 & ((e51_2>=e51_3 & e51_2!=9) | (e51_2>0 & e51_2!=9 & e51_3==9))
replace bc_edu=e51_3 		if nivel_aux==1 & ((e51_3>e51_2 & e51_3!=9)  | (e51_3>0 & e51_3!=9 & e51_2==9))

*Secundaria
replace bc_edu=6+e51_4_a 	if nivel_aux==2 & e51_4_a<=3 & e51_4_a>0
replace bc_edu=6+e51_4_b 	if nivel_aux==2 & e51_4_b<=3 & e51_4_b>0
replace bc_edu=9			if nivel_aux==2 & e51_4_a!=0 & e51_4_b!=0 & bc_edu>9
replace bc_edu=9+e51_5 		if nivel_aux==2 & (e51_4_a==3 | e51_4_b==3 | e51_4_a+e51_4_b==3) & e51_5<9 & e51_5>0
replace bc_edu=9+e51_6 		if nivel_aux==2 & (e51_4_a==3 | e51_4_b==3 | e51_4_a+e51_4_b==3) & e51_6<9 & e51_6>0
replace bc_edu=9 			if nivel_aux==2 & (e51_4_a+e51_4_b>0) & (e51_4_a!=. | e51_4_b!=.) & e51_5==0 & e51_6==0 & (e201_1c==1 | e201_1d==1)
replace bc_edu=9			if nivel_aux==2 & (e51_4_a==3 | e51_4_b==3 | e51_4_a+e51_4_b==3) & e51_5==9
replace bc_edu=9 			if nivel_aux==2 & (e51_4_a==3 | e51_4_b==3 | e51_4_a+e51_4_b==3) & e51_6==9
replace bc_edu=6 			if nivel_aux==2 & ((e51_4_a==9 & e51_4_b==0) | (e51_4_b==9 & e51_4_a==0))
replace bc_edu=9 			if nivel_aux==2 & (e51_4_a==9 & e51_4_b==9) & (e201_1a==1 | e201_1b==1)
replace bc_edu=9+e51_5 		if nivel_aux==2 & bc_edu==-15 & e51_5!=0
replace bc_edu=9+e51_6 		if nivel_aux==2 & bc_edu==-15 & e51_6!=0

* UTU actual
replace bc_edu=6+e51_6a 	if nivel_aux==3 & e51_6a<9
replace bc_edu=6 			if nivel_aux==3 & e51_6a==9

*magisterio
replace bc_edu=12+e51_8 	if nivel_aux==4 & e51_8<9 & e51_8>0
replace bc_edu=12 			if nivel_aux==4 & e51_8==9
replace bc_edu=15 			if nivel_aux==4 & e51_8==9 & e215_1==1

*Terciaria
replace bc_edu=12+e51_9				if nivel_aux==5 & e51_9<9 & e51_9>0
replace bc_edu=12+e51_10 			if nivel_aux==5 & e51_10<9 & e51_10>0
replace bc_edu=12+e51_9+e51_11 		if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9>=e51_10 & e51_9!=9
replace bc_edu=12+e51_10+e51_11		if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9<e51_10 & e51_10!=9
replace bc_edu=12 					if nivel_aux==5 & e51_9==9
replace bc_edu=12 					if nivel_aux==5 & e51_10==9
replace bc_edu=12+e51_9 			if nivel_aux==5 & e51_11==9 & e51_9>=e51_10 & e51_9!=9
replace bc_edu=12+e51_10 			if nivel_aux==5 & e51_11==9 & e51_9<e51_10 & e51_10!=9

recode bc_edu 23/38=22

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* 4- Mercado de trabajo

* Condición de actividad
g bc_pobp = pobpcoac
recode bc_pobp (10=9)

* Categoría de ocupación
g bc_pf41= -9 // no se pregunta por separado si el/la cuenta propia es con o sin local
			  // además en la encuesta de seguimiento no tenemos f281_
	replace bc_pf41=1 if f73==1
	replace bc_pf41=2 if f73==2
	replace bc_pf41=3 if f73==3
	replace bc_pf41=4 if f73==4
	*replace bc_pf41=5 if (f73==9 /*& (f281_1==2 & f281_2==2 & f281_3==2 & f281_4==2)*/)
	replace bc_pf41=6 if (f73==9) // & (f281_1==1 | f281_2==1 | f281_3==1 | f281_4==1))
	replace bc_pf41=7 if f73==7|f73==8

g bc_cat2=-9
	replace bc_cat2=1 if f73==1
	replace bc_cat2=2 if f73==2
	replace bc_cat2=3 if f73==4
	replace bc_cat2=4 if f73==9
	replace bc_cat2=5 if f73==3|f73==7|f73==8

* Rama del establecimiento 
g bc_pf40=f72_2  

g bc_rama=-9
	replace bc_rama=1 if f72_2>0000 & f72_2<1000 & bc_pobp==2
	replace bc_rama=2 if f72_2>1000 & f72_2<3500
	replace bc_rama=3 if f72_2>3500 & f72_2<3700
	replace bc_rama=4 if f72_2>4000 & f72_2<4500
	replace bc_rama=5 if (f72_2>=4500&f72_2<4900)|(f72_2>=5500&f72_2<5700)
	replace bc_rama=6 if (f72_2>=4900&f72_2<5500)|(f72_2>=5800&f72_2<6400)
	replace bc_rama=7 if f72_2>=6400&f72_2<8300
	replace bc_rama=8 if f72_2>=8300&f72_2<9910 | (f72_2>= 3700 & f72_2<=3900)

* Tipo de ocupación 
g bc_pf39=f71_2
	replace bc_pf39=-9  if bc_pf39==. & bc_pobp!=2
	replace bc_pf39=-9  if bc_pf39==0 & bc_pobp!=2
	replace bc_pf39=-15 if bc_pf39==. & bc_pobp==2
	
g bc_tipo_ocup=trunc(bc_pf39/1000)
	replace bc_tipo_ocup=-9 if bc_tipo_ocup==0&bc_pobp!=2

* Cantidad de empleos
g bc_pf07=f70
recode bc_pf07 (0=-9)

* Horas trabajadas
g bc_pf051=-13
g bc_pf052=-13
g bc_pf053=-13
g bc_pf06=-13
g bc_horas_sp=-13
g bc_horas_sp_1=-13

recode f85 f98 (.=0)
g bc_horas_hab=f85+f98 // horas semanales trabajadas habitualmente en total
replace bc_horas_hab=-9 if bc_pobp!=2
g bc_horas_hab_1=f85   // horas semanales trabajadas habitualmente en trabajo principal
replace bc_horas_hab_1=-9 if bc_pobp!=2

* Motivo por el que no trabaja
g bc_pf04=f69
recode bc_pf04 (3=4) (7/8=3) (5/6=4) (9/14=4) (0=-9)

* Busqueda de trabajo
g bc_pf21= -13 // buscó trabajo la semana pasada -- no se pregunta, lo que si se pregunta en ambos es si buscó en las últimas 4 semanas
 
g bc_pf22= -13 // causa por la que no buscó trabajo // Chequear que hacer con nuevas cat en 2020-2021 // En segundo semestre de 2021 no existe el f108=2

* Duración desempleo (semanas)
g bc_pf26=f113
replace bc_pf26=-9 if bc_pobp<3|bc_pobp>5
 
* Causas por las que dejó último trabajo
g bc_pf34=f122
recode bc_pf34 (1=2) (2=1) (4/9=3) (0=-9) (99=-15)

/* Trabajo registrado // no está  e45_x_1_cv en seguimiento
 g bc_reg_disse=-9
	replace bc_reg_disse=2 if bc_pobp==2
	replace bc_reg_disse=1 if (e45_1_1_cv==1 | e45_2_1_cv==1 | e45_3_1_cv==1 | bc_cat2==2) & bc_pobp==2
 */
g bc_register=-9
	replace bc_register=2 if bc_pobp==2
	replace bc_register=1 if bc_pobp==2 & f82==1

/* no está f96 en seguimiento 
g bc_register2=-9
	replace bc_register2=2 if bc_pobp==2
	replace bc_register2=1 if bc_pobp==2 & (f82==1|f96==1)
*/
* Subocupado
g bc_subocupado=-9
	replace bc_subocupado=2 if bc_pobp==2
	replace bc_subocupado=1 if f102==1 & f104==5 & bc_horas_hab>0 & bc_horas_hab<40 & bc_horas_hab!=.

g bc_subocupado1=-9
	replace bc_subocupado1=2 if bc_pobp==2
	replace bc_subocupado1=1 if (f101==1|f102==1) & f103==1 & f104==5 & bc_horas_hab>0 & bc_horas_hab<40 & bc_horas_hab!=.
