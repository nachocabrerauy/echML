*---------------------------------------------------------

* echML: Replicacion de graficos DT_14-24 - IECON, Udelar.

*---------------------------------------------------------
* 0- Master
*---------------------------

clear all
set more off

* Direccion de la carpeta principal del repositorio (usar "\")
gl ruta "" 
* ejemplo:
* gl ruta "C:\Users\Ignacio Cabrera\Desktop\echML" 

gl rutacod "$ruta\codigo"
gl rutaori "$ruta\datos_originales"
gl rutapro "$ruta\datos_procesados"
gl rutares "$ruta\resultados"

/*---------------------------------------------------------
* 1_orig_a_dta.do
*	Importa datos descargados de web INE y genera bases en formato DTA.
*	Hasta 2020 descargar datos en formato SAV, desde 2021 estan en csv.
*/
run "$rutacod\1_orig_a_dta.do"

/*---------------------------------------------------------
* 2_pesos_replicados.do
*	Importa pesos replicados descargados de web INE y los guarda en formato DTA.
*/
run "$rutacod\2_pesos_replicados.do"

/*---------------------------------------------------------
* 3_procesa_orig.do
*	Homogeniza las bases y crea algunas variables necesarias.
*/
run "$rutacod\3_procesa_orig.do"

/*---------------------------------------------------------
* 4_graph_con_IC.do
*	Genera matrices con la evolución de las variables e intervalos de confianza.
*	Genera los gráficos del Documento de Trabajo	
*/
run "$rutacod\4_graph_con_IC.do"

clear all
exit