clear all

cd "C:\Users\manue\Documents\Magister\De Gregorio\Tesis\Bases\Encuestas\Finales\Segunda etrega\2009"

***archivo original descargado de MDS
use "casen2009stata"

gen str_seg = string(int(segmento),"%08.0f") 
gen str_idviv = string(int(idviv),"%03.0f")
gen str_hog = string(int(hogar),"%02.0f")
gen str_o = string(int(o),"%02.0f") 
egen id_ind = concat(str_seg str_idviv str_hog str_o)
*destring id_ind, replace float





duplicates report id_ind
***hay 60 observaciones, de aprox 270.000, repetidas (error de codificación)
duplicates drop id_ind, force

save "casen 2009 main", replace

use "ingresos_originales_casen_2009", clear
gen str_seg = string(int(segmento),"%08.0f") 
gen str_idviv = string(int(idviv),"%03.0f")
gen str_hog = string(int(hogar),"%02.0f")
gen str_o = string(int(o),"%02.0f") 
egen id_ind = concat(str_seg str_idviv str_hog str_o)
*destring id_ind, replace float



duplicates report id_ind
***hay 60 observaciones, de aprox 270.000, repetidas (error de codificación)
duplicates drop id_ind, force

save "Ingresos originales casen 2009", replace

use "casen 2009 main", clear

merge 1:1 id_ind using "Ingresos originales casen 2009"

save "Casen 2009", replace
