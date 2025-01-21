*8_ ----------------------------------------------------------------------------
* Drop de variables auxiliares
*drop variables intermedias generadas para desagregar por fuentes
*drop cuotas_tot cuot_emp_d cuot_emp cuot_emp_tot pt2priv pt2pub pt2nodep pt1_1 emer_emp emer_emp_tot emer_emp_d ytransf_1 filtas* suma* bpc asig_jefe* asig_con* asig_otro* ytransf_2 ytransf_3 desay almuer comescol comehog canasta yaliment ytransf_4 ytransf_5 ytransf_6 pt2priv_1 pt2priv_2 pt2nodep_1 pt2nodep_2 men18 menor18 men18s cuot_otrohog_d cuot_otrohog cuot_otrohog_tot emer_otro_d emer_otro emer_otro_tot cuotmilit_otro_d cuotmilit_otro cuotmilit_otro_tot yaliment_men1 yaliment_men ht11_iecon_1 cuota_p cuota_o aux_cuotmilit seguro salud_aux ingre_ciud 

*drop variables generadas para el hogar que se usan solo a los efectos de calcular ht11_nuev_cf y ht11_nuev
*drop as_privadosh as_publicosh as_otrosh as_agropech patronesh pat_agropech cpropiaslh cpropiaclh cp_agropech cooperath ot_agropech otros_labh ing_labh utilidadesh alqh interesesh ut_agropech otras_utilidadesh ot_utilidadesh otras_capitalh ing_caph jub_penh jub_peneh bs_socialesh ingre_ciudh transf_hogh beneficiosh val_loc val_loch otrh otrosh
*drop otras variables
*drop bc_cuotmilit1 bc_otros bc_otros_ing bc_benef_ocup_secund

sort bc_correlat bc_nper

rename saludh bc_salud
g bc_afam = monto_afam_pe + monto_afam_cont

bysort bc_correlat: egen bc_yciudada= sum(bc_ing_ciud)
replace bc_yciudada=0 if bc_nper!=1

*- Arreglos finales

rename yhog_iecon bc_yhog
rename cuotmilit1 bc_cuotmilit

g bc_ht11_sss = bc_ht11_sss_corr*bc_ipc
g bc_ht11_css = (bc_ht11_sss_corr + bc_salud)*bc_ipc
bysort bc_correlat: gen max_nper = _N
bysort bc_correlat: gen bc_percap_iecon = bc_ht11_sss/max_nper

foreach var in bc_pg14 bc_ht11_sss bc_ht11_css bc_percap_iecon bc_ht11_sss_corr bc_salud { 	// Esto es para corregir variables a nivel de hogar
																							// que varían a nivel de personas. Se asigna el valor 
																							// que toma para el jefe de hogar
bysort bc_correlat: egen `var'_aux = max(`var')
replace `var' = `var'_aux
drop `var'_aux
}


*-------------------------------------------------------------------------------
* Append servicio doméstico y sin hogar

append using "$rutacom/servdom20", nol
sort bc_correlat bc_nper

*-------------------------------------------------------------------------------
*- Se retoman etiquetas originales de variables de ingreso de INE 
*- que fueron previamente cambiadas en el paso 2.

rename ine_pt1 pt1
rename ine_pt2 pt2
rename ine_pt4 pt4
rename ine_ht13 ht13
rename ine_yhog yhog
rename ine_ysvl ysvl