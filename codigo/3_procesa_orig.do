*---------------------------------------------------------
* 3- procesa orig
*	Homogeniza las bases y crea algunas variables necesarias.
*---------------------------

foreach x in "18" "19" "20" "21" "22" "23" "_mens_22" "_mens_23" {

use "$rutapro\ech`x'.dta", clear
rename *, lower

gl rutacom "$rutacod\compat\c`x'"
run "$rutacom\1_principal_compat.do"

save "$rutapro\ech`x'_procesada.dta", replace

}