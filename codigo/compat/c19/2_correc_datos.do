
* Arreglos de nombres de variables por .sav
cap rename e45_1__a e45_1_1_1
cap rename e45_1__b e45_1_2_1
cap rename e45_2__a e45_2_1_1
cap rename e45_2__b e45_2_2_1
cap rename e45_3__a e45_3_1_1
cap rename e45_3__b e45_3_2_1
cap rename e45_4__a e45_4_3_1
cap rename e45_5__a e45_5_1_1

cap rename g148_1_a g148_1_10
cap rename g148_1_b g148_1_11
cap rename g148_1_c g148_1_12
cap rename g148_2_a g148_2_10
cap rename g148_2_b g148_2_11
cap rename g148_2_c g148_2_12

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
cap rename mes bc_mes
cap rename anio bc_anio
cap rename dpto bc_dpto
cap rename ccz bc_ccz
recode bc_ccz (0=-9)

recode mto_cuot (.=0)  
recode mto_emer (.=0)
recode mto_hogc (.=0)

*-------------------------------------------------------------------------------
* Recodificación de datos

*-------------------------------------------------------------------------------
* Cambios de variables
destring region_4, replace
destring bc_dpto, replace
destring bc_mes, replace
destring bc_anio, replace
destring bc_ccz, replace
destring f72_2, replace force
destring f91_2, replace
destring f71_2, replace force
