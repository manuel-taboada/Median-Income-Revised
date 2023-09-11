clear all

cd "C:\Users\manue\Documents\Magister\De Gregorio\Tesis\Bases\Encuestas\Finales\Segunda etrega\2011"

***archivo original descargado de MDS
use "casen2011stata"


gen str_folio = string(int(folio),"%12.0f")

gen str_o = string(int(o),"%02.0f") 
egen id_ind = concat(str_folio str_o)
*destring id_hogar, replace float

duplicates report id_ind
***hay 60 observaciones, de aprox 270.000, repetidas (error de codificación)

save "casen 2011 main", replace

use "ingresos_originales_casen_2011_stata"
gen str_folio = string(int(folio),"%12.0f")

gen str_o = string(int(o),"%02.0f") 
egen id_ind = concat(str_folio str_o)


*destring id_hogar, replace float





duplicates report id_ind 

save "Ingresos originales casen 2011", replace

use "casen 2011 main", clear

merge 1:1 id_ind using "Ingresos originales casen 2011"

save "Casen 2011", replace
