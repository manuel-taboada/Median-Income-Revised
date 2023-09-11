clear all
cd "C:\Users\manue\Documents\Magister\De Gregorio\Tesis\Bases\Encuestas\Finales\Segunda etrega\2006"

***archivo original descargado de MDS
use "casen2006", clear
gen str_o = string(int(o),"%02.0f")
egen id_ind = concat(f str_o)

duplicates report id_ind

duplicates drop id_hogar, force

save "casen 2006 main", replace

use "Ingresos originales casen 2006_stata"
gen str_o = string(int(o),"%02.0f")
egen id_ind = concat(f str_o)

duplicates report id_hogar

duplicates drop id_ind, force

save "Ingresos originales casen 2006", replace

use "casen 2006 main"

merge 1:1 id_ind using "Ingresos originales casen 2006"

save "Casen 2006", replace
