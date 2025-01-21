*1_ compatibilización 2021 -----------------------------------------------------

/*------------------------------------------------------------------------------
2_correc_datos
	*- Abre base original y arma fusionada con hogares (si es necesario)
	*- Renombra y recodifica variables y casos de la encuesta
*/	
run "$rutacom\2_correc_datos.do"

/*------------------------------------------------------------------------------
3_compatibilizacion_mod_1_4
	*- Hace compatibles variables de los módulos 1 a 4:
		1- Características generales y de las personas
		2- Atención de la salud
		3- Educación
		4- Mercado de trabajo
*/
run "$rutacom\3_compatibilizacion_mod_1_4.do"

/*------------------------------------------------------------------------------
4_ingreso_ht11_iecon
	*- Genera un ingreso del hogar (ht11_iecon) sumando todos los ingresos que se 
	declaran en la encuesta, sin descomponer por fuentes, que incluye seguro 
	de salud (si corresponde).
	*- Genera variables intermedias como cuotas militares, ingresos por alimentos
	transferidos a menores, etc. que luego se utilizan para la descomposiciÃ³n 
	por fuentes.
*/
run "$rutacom\4_ingreso_ht11_iecon.do"

/*------------------------------------------------------------------------------
5_descomp_fuentes
	*- Genera variables de ingresos descomponiendo por fuentes y sin incluir 
	seguro de salud.
*/
run "$rutacom\5_descomp_fuentes.do"

/*------------------------------------------------------------------------------
6_ingreso_ht11_sss
	*- Genera variables de ingresos agregadas como ingresos laborales, ingresos
	por capital, jubilaciones y pensiones, etc.
	*- Genera un ingreso del hogar como resultado de sumar las distintas fuentes
	de ingresos.
	*- Imputa seguro de salud para el hogar y se genera ht11_css para comparar 
	con el ht11_iecon.
	*- Genera ingresos per cÃ¡pita incluyendo seguro y sin incluir
*/
run "$rutacom\6_ingreso_ht11_sss.do"

/*------------------------------------------------------------------------------
7_arregla_base_comp
	*- Drop de variables intermedias.
*/
run "$rutacom\7_arregla_base_comp.do"

/*------------------------------------------------------------------------------
8_labels
	*- Etiquetas de valores de variables compatibles.
*/
run "$rutacom\8_labels.do"

