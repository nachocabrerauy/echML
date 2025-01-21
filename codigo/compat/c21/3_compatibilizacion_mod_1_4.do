*-------------------------------------------------------------------------------
* Variables de identificación general

rename numero bc_correlat
rename nper bc_nper

*-------------------------------------------------------------------------------
* En 2021 hay problemas con la relación de parentesco y algunos hogares no tienen jefe
* Genero un conteo de miembros del hogar para cuando haya que asignar un valor 
* a un solo miembro
sort bc_correlat bc_nper
by bc_correlat: egen n_miembro = seq()

* tenemos pesos mensuales para el primer semestre y pesos trimestrales y semestrales para el segundo
* vamos a crear pesoan, pesosem y pesotri pero no podemos crear pesomen para todo el año

* bc_pesoan
* para el primer sem 
gen bc_pesoan = pesomen/12 if bc_mes < 7
* para el segundo sem
replace bc_pesoan = w_sem/2 if bc_mes > 6
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

* No hay info en el primer semestre de 2021 

g bc_pe5=-13
	replace bc_pe5=1 if e35==2 | e35==3
	replace bc_pe5=2 if e35==4 | e35==5
	replace bc_pe5=3 if e35==0 & (e36==1 | e36==2 | e36==3)
	replace bc_pe5=4 if e35==0 & (e36==4 | e36==6)
	replace bc_pe5=5 if e35==0 & (e36==5)
 

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
* 3- Educación
** Acá hay cambios grandes entre el primer y segundo semestre

*asiste
g bc_pe11=2 
	replace bc_pe11=1 if (e193==1|e197==1|e201==1|e212==1|e215==1|e218==1|e221==1|e224==1) & inrange(bc_mes,1,6)
	replace bc_pe11=1 if e49==3 & inrange(bc_mes,7,12)
	replace bc_pe11=-9 if bc_pe3<3 & bc_pe3!=.

*asistió
g bc_pe12=2
	replace bc_pe12=1 if e49==1
	replace bc_pe12=-15 if e49==99 & inrange(bc_mes,1,6)
	replace bc_pe12=-9 if bc_pe11==1 | bc_pe11==-9

* Nivel

g bc_nivel=-13
g nivel_aux=-15

forvalues i =2/11 { 
	
g bc_e51_`i' = e51_`i'
	recode  bc_e51_`i' (0.1 = 9) 			if inrange(bc_mes,1,6)
}

g bc_e51_4_a = e51_4_a
g bc_e51_4_b = e51_4_b
g bc_e51_6a = e51_6a	

** Armo una variable similar a la que hacía el INE sobre la exigencia del curso de UTU
destring e214_1, replace force

g bc_e51_7_1=.
replace bc_e51_7_1=1 if inrange(e214_1,50000,59999) // requisito: secundaria completa
replace bc_e51_7_1=2 if inrange(e214_1,30000,39999) // requisito: ciclo basico
replace bc_e51_7_1=3 if inrange(e214_1,20000,29999) // requisito: primaria completa
replace bc_e51_7_1=4 if inrange(e214_1,1,19999) // requisito: nada

replace nivel_aux=0 	if bc_pe11==2 & bc_pe12==2 // nunca asistió

replace nivel_aux=0 	if inrange(bc_mes,1,6) 	& ( (bc_e51_2==0 & bc_e51_3==0) | ((e193==1 | e193==2) & bc_e51_2==9) )

replace nivel_aux=0 	if inrange(bc_mes,7,12)	& ( (bc_e51_2==0 & bc_e51_3==0) | ((e197_1==2) & bc_e51_2==9) ) // Por qué no ponemos la primaria especial??

replace nivel_aux=1  	if inrange(bc_mes,1,6) 	& ( ( ( (bc_e51_2>0 & bc_e51_2<=6) | (bc_e51_3>0 & bc_e51_3<=6) ) &  bc_e51_4==0 ) | (bc_e51_2==6 & bc_e51_4==9) )  /* //Primaria */

replace nivel_aux=1  	if inrange(bc_mes,7,12)	& ( ( ((bc_e51_2>0 & bc_e51_2<=6) | (bc_e51_3>0 & bc_e51_3<=6)) &  (bc_e51_4_a==0 & bc_e51_4_b==0) ) | (bc_e51_2==6 & (bc_e51_4_a==9 | bc_e51_4_b==9)) )  /* //Primaria */

replace nivel_aux=2  	if inrange(bc_mes,1,6) 	&  ((((bc_e51_4>0 & bc_e51_4<=3) | (bc_e51_5>0 & bc_e51_5<=3) | (bc_e51_6>0 & bc_e51_4<=6)) & (bc_e51_7==0 & bc_e51_8==0 & bc_e51_9==0 & bc_e51_10==0)) | (bc_e51_7!=0 & e51_7_1==3) | (bc_e51_4==3 & bc_e51_8==9) | (bc_e51_5==3 & bc_e51_8==9))

replace nivel_aux=2  	if inrange(bc_mes,7,12) 	&  ( ( ( (bc_e51_4_a>0 & bc_e51_4_a<=3) | (bc_e51_4_b>0 & bc_e51_4_b<=3) | (bc_e51_5>0 & bc_e51_5<=3) | (bc_e51_6>0 & bc_e51_6<=3)) & (bc_e51_8==0 & bc_e51_9==0 & bc_e51_10==0)) | (e51_6a!=0 & bc_e51_7_1==3) | (bc_e51_4_a==3 & bc_e51_8==9) | (bc_e51_4_b==3 & bc_e51_8==9) | (bc_e51_5==3 & bc_e51_8==9))


replace nivel_aux=3  	if inrange(bc_mes,1,6) 	&  ((bc_e51_7>0 &  bc_e51_7<=9 & e51_7_1<3) | (bc_e51_7!=0 & bc_e51_4==0 & bc_e51_5==0 & bc_e51_6==0) /* // UTU
*/ & bc_e51_8==0 & bc_e51_9==0 & bc_e51_10==0 )

replace nivel_aux=3  	if inrange(bc_mes,7,12)	&  ( (bc_e51_6a>0 & bc_e51_6a<=9 & e51_7_1<3) | (bc_e51_6a!=0 & bc_e51_4_a==0 & bc_e51_4_b==0 & bc_e51_5==0 & bc_e51_6==0) /* // UTU
*/ & bc_e51_8==0 & bc_e51_9==0 & bc_e51_10==0 )

replace nivel_aux=4  	if (bc_e51_8>0 & bc_e51_8<=5) &  bc_e51_9==0 &  bc_e51_10==0 &  bc_e51_11==0  // magisterio o profesorado

replace nivel_aux=5  	if ( (bc_e51_9>0 & bc_e51_9<=9) | (bc_e51_10>0 & bc_e51_10<=9) | (bc_e51_11>0 & bc_e51_11<=9) ) // universidad o similar

replace nivel_aux=0 	if nivel_aux==-15 & (bc_e51_2==9 | bc_e51_3==9)

* Años de bc_educación

g bc_edu=-15


*Primaria
replace bc_edu=0 			if nivel_aux==0
replace bc_edu=bc_e51_2 	if nivel_aux==1 & ((bc_e51_2>=bc_e51_3 & bc_e51_2!=9) | (bc_e51_2>0 & bc_e51_2!=9 & bc_e51_3==9))
replace bc_edu=bc_e51_3 	if nivel_aux==1 & ((bc_e51_3>bc_e51_2 & bc_e51_3!=9)  | (bc_e51_3>0 & bc_e51_3!=9 & bc_e51_2==9))

*Secundaria
	*1er semestre
replace bc_edu=6+bc_e51_4 	if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4<=3 & bc_e51_4>0
replace bc_edu=9+bc_e51_5 	if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_5<9 & bc_e51_5>0
replace bc_edu=9+bc_e51_6 	if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_6<9 & bc_e51_6>0
replace bc_edu=9 			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4>0 & bc_e51_4!=. & bc_e51_5==0 & bc_e51_6==0 & e201_1==1
replace bc_edu=9			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_5==9
replace bc_edu=12			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_5==9 & e212_1==1
replace bc_edu=9 			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_6==9
replace bc_edu=12 			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==3 & bc_e51_6==9 & e212_1==1
replace bc_edu=6 			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==9 
replace bc_edu=9 			if inrange(bc_mes,1,6) & nivel_aux==2 & bc_e51_4==9 & e201_1==1
	*2do semestre
replace bc_edu=6+bc_e51_4_a 	if inrange(bc_mes,7,12) & nivel_aux==2 & bc_e51_4_a<=3 & bc_e51_4_a>0
replace bc_edu=6+bc_e51_4_b 	if inrange(bc_mes,7,12) & nivel_aux==2 & bc_e51_4_b<=3 & bc_e51_4_b>0
replace bc_edu=9				if inrange(bc_mes,7,12) & nivel_aux==2 & bc_e51_4_a!=0 & bc_e51_4_b!=0 & bc_edu>9
replace bc_edu=9+bc_e51_5 		if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a==3 | bc_e51_4_b==3 | bc_e51_4_a+bc_e51_4_b==3) & bc_e51_5<9 & bc_e51_5>0
replace bc_edu=9+bc_e51_6 		if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a==3 | bc_e51_4_b==3 | bc_e51_4_a+bc_e51_4_b==3) & bc_e51_6<9 & bc_e51_6>0
replace bc_edu=9 				if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a+bc_e51_4_b>0) & (bc_e51_4_a!=. | bc_e51_4_b!=.) & bc_e51_5==0 & bc_e51_6==0 & (e201_1c==1 | e201_1d==1)
replace bc_edu=9				if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a==3 | bc_e51_4_b==3 | bc_e51_4_a+bc_e51_4_b==3) & bc_e51_5==9
replace bc_edu=9 				if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a==3 | bc_e51_4_b==3 | bc_e51_4_a+bc_e51_4_b==3) & bc_e51_6==9
replace bc_edu=6 				if inrange(bc_mes,7,12) & nivel_aux==2 & ( (bc_e51_4_a==9 & bc_e51_4_b==0) | (bc_e51_4_b==9 & bc_e51_4_a==0) )
replace bc_edu=9 				if inrange(bc_mes,7,12) & nivel_aux==2 & (bc_e51_4_a==9 & bc_e51_4_b==9) & (e201_1a==1 | e201_1b==1)
replace bc_edu=9+bc_e51_5 		if inrange(bc_mes,7,12) & nivel_aux==2 & bc_edu==. & bc_e51_5!=0
replace bc_edu=9+bc_e51_6 		if inrange(bc_mes,7,12) & nivel_aux==2 & bc_edu==. & bc_e51_6!=0

* UTU actual
replace bc_edu=6+bc_e51_7 	if inrange(bc_mes,1,6) & nivel_aux==3 & bc_e51_7<9
replace bc_edu=6 			if inrange(bc_mes,1,6) & nivel_aux==3 & bc_e51_7==9
replace bc_edu=6+bc_e51_6a 	if inrange(bc_mes,7,12) & nivel_aux==3 & bc_e51_6a<9
replace bc_edu=6 			if inrange(bc_mes,7,12) & nivel_aux==3 & bc_e51_6a==9

*magisterio
replace bc_edu=12+bc_e51_8 	if nivel_aux==4 & bc_e51_8<9 & bc_e51_8>0
replace bc_edu=12 			if nivel_aux==4 & bc_e51_8==9
replace bc_edu=15 			if nivel_aux==4 & bc_e51_8==9 & e215_1==1

*Terciaria
replace bc_edu=12+bc_e51_9				if nivel_aux==5 & bc_e51_9<9 & bc_e51_9>0
replace bc_edu=12+bc_e51_10 			if nivel_aux==5 & bc_e51_10<9 & bc_e51_10>0
replace bc_edu=12+bc_e51_9+bc_e51_11 	if nivel_aux==5 & bc_e51_11<9 & bc_e51_11>0 & bc_e51_9>=bc_e51_10 & bc_e51_9!=9
replace bc_edu=12+bc_e51_10+bc_e51_11	if nivel_aux==5 & bc_e51_11<9 & bc_e51_11>0 & bc_e51_9<bc_e51_10 & bc_e51_10!=9
replace bc_edu=12 						if nivel_aux==5 & bc_e51_9==9
replace bc_edu=12 						if nivel_aux==5 & bc_e51_10==9
replace bc_edu=15						if nivel_aux==5 & bc_e51_10==9 & e221_1==1
replace bc_edu=16						if nivel_aux==5 & bc_e51_9==9 & e218_1==1
replace bc_edu=12+bc_e51_9 				if nivel_aux==5 & bc_e51_11==9 & bc_e51_9>=bc_e51_10 & bc_e51_9!=9
replace bc_edu=12+bc_e51_10 			if nivel_aux==5 & bc_e51_11==9 & bc_e51_9<bc_e51_10 & bc_e51_10!=9

recode bc_edu 23/38=22

drop bc_e51_*

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* 4- Mercado de trabajo

* Condición de actividad
g bc_pobp = pobpcoac
recode bc_pobp (10=9)

* Categoría de ocupación
g bc_pf41= -9 // en el segundo semestre no se pregunta por separado si el/la cuenta propia es con o sin local
	replace bc_pf41=1 if f73==1
	replace bc_pf41=2 if f73==2
	replace bc_pf41=3 if f73==3
	replace bc_pf41=4 if f73==4
	replace bc_pf41=5 if (f73==5 & inrange(bc_mes,1,6)) | (f73==9 & (f281_1==2 & f281_2==2 & f281_3==2 & f281_4==2) & inrange(bc_mes,7,12))
	replace bc_pf41=6 if (f73==6 & inrange(bc_mes,1,6)) | (f73==9 & (f281_1==1 | f281_2==1 | f281_3==1 | f281_4==1) & inrange(bc_mes,7,12))
	replace bc_pf41=7 if f73==7|f73==8

g bc_cat2=-9
	replace bc_cat2=1 if f73==1
	replace bc_cat2=2 if f73==2
	replace bc_cat2=3 if f73==4
	replace bc_cat2=4 if f73==5|f73==6|f73==9
	replace bc_cat2=5 if f73==3|f73==7|f73==8

* Tamaño del establecimiento
g bc_pf081=-9
	replace bc_pf081=1 if (f77==1 | f77==2 | f77==3) //tamaño chico
	replace bc_pf081=2 if inrange(f77,4,9) //tamaño grande

g bc_pf082=-9
	replace bc_pf082=1 if f77==1
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
destring f98, replace force
recode f85 f98 (.=0)
g bc_horas_hab=f85+f98 // horas semanales trabajadas habitualmente en total
recode bc_horas_hab (0=-9)
g bc_horas_hab_1=f85   // horas semanales trabajadas habitualmente en trabajo principal
recode bc_horas_hab_1 (0=-9)

g bc_horas_sp=-13 // horas semanales trabajadas semana pasada en total
g bc_horas_sp_1=-13 // horas semanales trabajadas semana pasada en trabajo principal

* Motivo por el que no trabaja
g bc_pf04=f69
recode bc_pf04 (3=4) (7/8=3) (5/6=4) (9/14=4) (0=-9) 
* Busqueda de trabajo
g bc_pf21= -13 // buscó trabajo la semana pasada -- no se pregunta en el segundo semestre, lo que si se pregunta en ambos es si buscó en las últimas 4 semanas
 
g bc_pf22= -13 // causa por la que no buscó trabajo // En segundo semestre de 2021 no existe el f108=2

* Duración desempleo (semanas)
destring f113, replace force
g bc_pf26=f113
replace bc_pf26=-9 if bc_pobp<3|bc_pobp>5
 
* Causas por las que dejó último trabajo
g bc_pf34=f122
recode bc_pf34 (1=2) (2=1) (4/9=3) (0=-9) (99=-15)

* Trabajo registrado
 g bc_reg_disse=-9
	replace bc_reg_disse=2 if bc_pobp==2
	replace bc_reg_disse=1 if (e45_1_1_cv==1 | e45_2_1_cv==1 | e45_3_1_cv==1 | bc_cat2==2) & bc_pobp==2
 
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
* ipc: IPC para montevideo a diciembre 2006

cap drop bc_ipc
g bc_ipc=.
replace	bc_ipc=	0.329708731	if	bc_mes==	1	&	bc_anio==	2021
replace	bc_ipc=	0.325120854	if	bc_mes==	2	&	bc_anio==	2021
replace	bc_ipc=	0.32193312	if	bc_mes==	3	&	bc_anio==	2021
replace	bc_ipc=	0.320163041	if	bc_mes==	4	&	bc_anio==	2021
replace	bc_ipc=	0.318357918	if	bc_mes==	5	&	bc_anio==	2021
replace	bc_ipc=	0.316774856	if	bc_mes==	6	&	bc_anio==	2021
replace	bc_ipc=	0.314794762	if	bc_mes==	7	&	bc_anio==	2021
replace	bc_ipc=	0.31306265	if	bc_mes==	8	&	bc_anio==	2021
replace	bc_ipc=	0.310558149	if	bc_mes==	9	&	bc_anio==	2021
replace	bc_ipc=	0.309320866	if	bc_mes==	10	&	bc_anio==	2021
replace	bc_ipc=	0.306270364	if	bc_mes==	11	&	bc_anio==	2021
replace	bc_ipc=	0.305191859	if	bc_mes==	12	&	bc_anio==	2021

*-------------------------------------------------------------------------------
* BPC

cap drop bpc
gen bpc=.
replace bpc = 4870 if bc_mes>1	& bc_anio==2021
replace bpc = 4519 if bc_mes==1	& bc_anio==2021

*-------------------------------------------------------------------------------
* Drop servicio doméstico
preserve
keep if e30==14
destring h163_1 h163_2 h166 h167_2_1 h170_1 h170_2 h252_1, replace force
destring e45_4_1_1_cv e45_3_1_1_cv, replace force
destring e45_3_1_1_cv, replace force
destring g127_1 g127_2 g127_3 g132_1 g132_2 g132_3 g133_1 g133_2, replace force
destring g135_1 g135_2 g135_3 g138_1 g139_1 g140_1 g140_2 g140_3 g141_1 g141_2, replace force
destring g144_1 g145 g146 g147, replace force
destring g257, replace force
destring e196_1 e196_2 e196_3 e247, replace force
destring g148_1_1 g148_1_2 g148_1_3 g148_1_4 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_12 g148_1_10 g148_1_11 g148_2_1 g148_2_2 g148_2_3  g148_2_4 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9  g148_2_12 g148_2_10 g148_2_11 g148_3, replace force
destring h163_1 h163_2 h166 h167_2_1 h170_1 h170_2 h252_1, replace force

save "$rutacom/servdom21.dta", replace
restore
drop if e30==14

