*---------------------------------------------------------
* 3- procesa orig
*	Homogeniza las bases y crea algunas variables necesarias.
*---------------------------

cd "$ruta"

foreach x in "18" "19" "20" "21" "22" "23" "_mens_22" "_mens_23" {

use "datos_originales\ech`x'.dta", clear

rename *, lower

* genero peso anual en años que es necesario

if "`x'"=="20" {
	gen pesoano = pesomen / 12
	egen hhinc = max(ht11), by(numero)
	drop ht11
}

if "`x'"=="21" {
	gen pesoano = pesomen/12 if mes < 7
	* para el segundo sem
	replace pesoano = w_sem/2 if mes > 6
	replace pesoano = floor(pesoano)
}

if "`x'"=="22" {
	egen hhinc = max(ht11), by(id)
	drop ht11
}
cap rename w_ano pesoano
cap destring dpto, replace
cap destring anio, replace 
cap destring mes, replace 

* genero ingreso percapita
cap rename numero id
bysort id: gen max_nper = _N
cap gen percap = ht11 / max_nper
cap gen percap = hhinc / max_nper

g bc_nivel=-13
g nivel_aux=-15

* genero variables de educación
if "`x'"=="18" | "`x'"=="19" | "`x'"=="20" {
    if "`x'"=="20" {
        forvalues i =2/11 { 
	        recode e51_`i' 0.1=9
    	}
    }
    replace nivel_aux=0 if ((e51_2==0 & e51_3==0) | ((e193==1 | e193==2) & e51_2==9))  

    replace nivel_aux=1  if ((((e51_2>0 & e51_2<=6) | (e51_3>0 & e51_3<=6)) &  e51_4==0) | (e51_2==6 & e51_4==9))  /* //Primaria */

    replace nivel_aux=2 if ((((e51_4>0 & e51_4<=3) | (e51_5>0 & e51_5<=3) | (e51_6>0 & e51_4<=6)) & (e51_8==0 & e51_9==0 & e51_10==0)) | (e51_7!=0 & e51_7_1==3) | (e51_4==3 & e51_8==9) | (e51_5==3 & e51_8==9)) // Secundaria 
    
    replace nivel_aux=3  if  ((e51_7>0 &  e51_7<=9 & e51_7_1<3) | (e51_7!=0 & e51_4==0 & e51_5==0 & e51_6==0) /* // UTU
    */ & e51_8==0 & e51_9==0 & e51_10==0 )

    replace nivel_aux=4  if (e51_8>0 & e51_8<=5) &  e51_9==0 &  e51_10==0 &  e51_11==0  // magisterio o profesorado

    replace nivel_aux=5  if ((e51_9>0 & e51_9<=9) | (e51_10>0 & e51_10<=9) | (e51_11>0 & e51_11<=9)) // universidad o similar

    replace nivel_aux=0 if nivel_aux==-15 & (e51_2==9 | e51_3==9)

    *aÃ±os de bc_educaciÃ³n
    g bc_edu=-15

    *Primaria
    replace bc_edu=0 if nivel_aux==0
    replace bc_edu= e51_2 if nivel_aux==1 & ((e51_2>=e51_3 & e51_2<9) | (e51_2>0 & e51_2<9 & e51_3==9))
    replace bc_edu= e51_3 if nivel_aux==1 & ((e51_3>e51_2 & e51_3<9)  | (e51_3>0 & e51_3<9 & e51_2==9))

    *Secundaria
    replace bc_edu=6+e51_4 if nivel_aux==2 & e51_4<=3 & e51_4>0 // Secundaria hasta ciclo bÃ¡sico
    replace bc_edu=9+e51_5 if nivel_aux==2 & e51_4==3 & e51_5<9 & e51_5>0 // Bachillerato comÃºn
    replace bc_edu=9+e51_6 if nivel_aux==2 & e51_4==3 & e51_6<9 &  e51_6>0 // Bachillerato tecnolÃ³gico
    *replace bc_edu=9 if nivel_aux==2 & e51_4>0 &  e51_5==0 & e51_6==0  & e201_1==1 // Falta la var e201_1 en ECH2020. Pedir a INE. TerminÃ³ ciclo bÃ¡sico pero no tiene aÃ±os aprobados en otro nivel
    replace bc_edu=9 if nivel_aux==2 & e51_4==3 & e51_5==9 // TerminÃ³ CB pero no tiene informaciÃ³n de secundaria
    replace bc_edu=12 if nivel_aux==2 & e51_4==3 & e51_5==9 & e212_1==1 // Completa secundaria mediante UTU
    replace bc_edu=9 if nivel_aux==2 & e51_4==3 & e51_6==9 // Tiene los 3 aÃ±os de CB pero no hizo bachillerato tecnolÃ³gico
    replace bc_edu=12 if nivel_aux==2 & e51_4==3 & e51_6==9 & e212_1==1 // Consultar a Alejandra
    replace bc_edu=6 if nivel_aux==2 & e51_4==9 // No tiene aÃ±os aprobados en secundaria
    *replace bc_edu=9 if nivel_aux==2 & e51_4==9 & e201_1==1 // Falta la var e201_1 en ECH2020 CompletÃ³ ciclo bÃ¡sico de UTU
    replace bc_edu=9+e51_5 if bc_edu==. & nivel_aux==2  & e51_5!=0 // DeberÃ­amos borrar?
    replace bc_edu=9+e51_6 if bc_edu==. & nivel_aux==2 // DeberÃ­amos borrar?

    * UTU actual
    replace bc_edu=6+e51_7 if nivel_aux==3 & e51_7<9
    replace bc_edu=6 if nivel_aux==3 & e51_7==9

    *magisterio
    replace bc_edu=e51_8+12 if nivel_aux==4 & e51_8<9 & e51_8>0
    replace bc_edu=12 if nivel_aux==4 & e51_8==9 // No deberÃ­amos poner este caso en secundaria?
    replace bc_edu=15 if nivel_aux==4 & e51_8==9 & e215_1==1 // Nos parece que es el caso de magisterio/profesorado cuya duraciÃ³n duraciÃ³n es de 3 aÃ±os

    *Terciaria
    replace bc_edu=e51_9+12 if nivel_aux==5 & e51_9<9  &  e51_9>0 // Se suman los aÃ±os aprobados
    replace bc_edu=e51_10+12 if nivel_aux==5 & e51_10<9  &  e51_10>0 // Se suman los aÃ±os aprobados en terciaria no universitaria
    replace bc_edu=e51_11+12+e51_9 if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9>=e51_10  // Agrega aÃ±os de posgrado
    replace bc_edu=e51_11+12+e51_10 if nivel_aux==5 & e51_11<9 & e51_11>0 & e51_9<e51_10  // Agrega aÃ±os de posgrado para los terciarios no universitaria
    replace bc_edu=12 if nivel_aux==5 & e51_9==9 // No tiene aÃ±os aprobados en el nivel
    replace bc_edu=12 if nivel_aux==5 & e51_10==9 // No tiene aÃ±os aprobados en el nivel
    replace bc_edu=15 if nivel_aux==5 & e51_9==9 & e218_1==1 // No licenciaturas
    replace bc_edu=16 if nivel_aux==5 & e51_10==9 & e218_1==1 // No universitaria completa 
    replace bc_edu=12+e51_9 if nivel_aux==5 & e51_11==9  & e51_9>=e51_10 // Desempate asignado a universidad y no a terciaria
    replace bc_edu=12+e51_10 if nivel_aux==5 & e51_11==9  & e51_9<e51_10 // Desempate asignado a terciaria y no a universidad

    recode bc_edu 23/38=22


}

if "`x'"=="21" | "`x'"=="22" | "`x'"=="23" | "`x'"=="_mens_22" | "`x'"=="_mens_23" {
    
	cap destring e201_1a e201_1b e201_1c e201_1d e214_1 e51_2 e49 e197_1 e51_6a e51_11 e215_1 , replace force

	*asiste
    g bc_pe11=2 
	replace bc_pe11=1 if e49==3
	replace bc_pe11=-9 if e27<3 & e27!=.
    *asistió
    g bc_pe12=2
	replace bc_pe12=1 if e49==1
	replace bc_pe12=-9 if bc_pe11==1 | bc_pe11==-9
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
}

save "datos_procesados\ech`x'_procesada.dta", replace

}