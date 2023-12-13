

** IMPUTACION DE IMPUESTOS **
clear all
set rmsg on
set more off
set linesize 250
cap log close
clear matrix




*************************************************************************************************************************************;
*************************************************************************************************************************************;

#delimit ;

***************************************************  0  - Definicion de Globales  ************************************************************************
*************************************************************************************************************************************

* Definimos la encuesta CASEN a utilizar;
global year_casen = 2020;

* Ajuste por tamano del hogar (ajuste utilizado por la OECD);
scalar eqv = 0.5;	

* Se definen los siguientes parametros:;

	* Variable de ingresos del trabajo a utilizar;
	global ingreso = "ytrabajocor";
	

	*#delimit ;
	local UF = 29070.33;
	local ipc = 1.084261412;
	local tramo_ss = 75.7*`UF'; // 75,7 es el tope imponible mensual para calcular las cotizaciones obligatorias del sistema de AFP, de salud y de ley de accidentes del trabajo;
	global corte_ss = `tramo_ss';



*************************************;
**Se seleccionan los párametros para el capital imputado k_i y el percentil desde el que se ajustan los datos con el registro de impuestos;

    global p_bfm  = 0.95;
	
	global k_i = 0.9;
   
	* Tramos de impuestos a considerar para la construccion de la funcion inversa del impuesto de segunda categoría(Las tasas y tramos son mensuales):;
	*#delimit ;
	
	global utm = 51029;
	global tramo1_sc = 13.5 * ${utm}; global tramo2_sc = 30 * ${utm};  global tramo3_sc = 50 * ${utm};
	global tramo4_sc =70 * ${utm};	global tramo5_sc = 90 * ${utm}; global tramo6_sc = 120 * ${utm};
	
	global tramo7_sc = 310 * ${utm}; global tramo8_sc = 100000000000000;

	// http://www.sii.cl/valores_y_fechas/impuesto_2da_categoria/impuesto2017.htm
	

	* Tramos de impuestos a considerar para la construccion de la funcion inversa del global complementario(año tributario 2018);
	global tramo1 = 13.5 * ${utm}; global tramo2 = 30 * ${utm};  global tramo3_sc = 50 * ${utm};
	global tramo4 =70 * ${utm};	global tramo5 = 90 * ${utm}; global tramo6 = 120 * ${utm};
		global tramo7 = 310 * ${utm}; global tramo8 = 100000000000000;
	
	// http://www.sii.cl/valores_y_fechas/renta/2018/personas_naturales.html
************parámetros a ajustar tci tasa capital imputado
	
  
  
	


	* Nombre del factor de expancion;
	global fac_exp		=	"expr";

	* Nombre del identificador de hogar;
	global id_h			=	"id_hogar";
	global id_dep		=	"o15";



	global no_boleteo	= 	"o34!=1";
	global da_boleta	=	"o34==1";	
	
	global no_tiene_afp	=	"o32!=1";
	global cot_pension	=	"o32==1";
	global k_imponible	=	"yrut yah1 yah2";
	
	
	* Tasas de impuesto (mensuales) asociadas a cada tramo año tributario 2017 (Segunda Categoria);

	global tasa1_sc = .04;			        global tasa2_sc = .08;		    global tasa3_sc = .135;
	global tasa4_sc = .23;		            global tasa5_sc = .304;		    global tasa6_sc = .35;
		global tasa7_sc = .40;

	* Tasas de impuesto (anuales) asociadas a cada tramo año tributario 2018 (Global Complementario);

	global tasa1 = .04;			global tasa2 = .08;				global tasa3 = .135;
	global tasa4 = .23;		    global tasa5 = .304;		    global tasa6 = .35;
	global tasa7 = .40;

	/* ACTUALIZAR
	Cobrar 20% de seguridad social a trabajadores y 7% a pensionados;
	*/

	* Tasa de seguridad social descontada a los trabajadores asalariados para calcular el impuesto de segunda categoria;
	global tasa_ss  = 0.2126; // tasa_ss = salud (7%) + previson (10%) comision promedio AFP (1.18%) + seguro cesantia (0.6%) + seguro de accidente (0.95%) + seguro de invalidez (1.53%)
	global tasa_ss2	= 0.07;	// ACTUALIZAR


	******************** Globales: agregados para ajustes a cuentas nacionales y registros administrativos;
	global indep_cn = 18099814190242.5/`ipc';
    global capital_CN =15578591196964.8/`ipc';
	global rec_sii = 4275072700000/`ipc';
   	global sal_cn = 77538181669885.5/`ipc';
	global cot_dep = 2994035961000/`ipc';


    global cot_indep = 110830491000/`ipc';
	
	
	
	** Tasas y Descuento Impuesto de Segunda Categoria **
	
	* Los siguientes globales contienen los coeficientes de cada tramo de la funcion que transforma ingresos asalariados brutos en ingresos asalariados netos.;
	* Dado que cada tramos es una funcion lineal, "ai"_sc corresponde a la constante y "bi_sc" a la pendiente del tramo i-esimo.; 
	
	*#delimit ;
	global a1_sc = ${tramo1_sc}*${tasa1_sc};
	global b1_sc = (1 - ${tasa1_sc});

	global a2_sc = ${tramo2_sc} * ${tasa2_sc} - (${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc}; 
	global b2_sc = (1 - ${tasa2_sc});

	global a3_sc = ${tramo3_sc} * ${tasa3_sc} - (${tramo3_sc} - ${tramo2_sc}) * ${tasa2_sc} - (${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc} ;
	global b3_sc = (1 - ${tasa3_sc});

	global a4_sc = ${tramo4_sc} * ${tasa4_sc} - (${tramo4_sc} - ${tramo3_sc}) * ${tasa3_sc} - (${tramo3_sc} - ${tramo2_sc}) * ${tasa2_sc} - (${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc} ;
	global b4_sc = (1 - ${tasa4_sc});

	global a5_sc = ${tramo5_sc} * ${tasa5_sc} - (${tramo5_sc} - ${tramo4_sc}) * ${tasa4_sc} - (${tramo4_sc} - ${tramo3_sc}) * ${tasa3_sc} - (${tramo3_sc} - ${tramo2_sc}) * ${tasa2_sc} - (${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc} ;
	global b5_sc = (1 - ${tasa5_sc});

	global a6_sc = ${tramo6_sc} * ${tasa6_sc} - (${tramo6_sc} - ${tramo5_sc}) * ${tasa5_sc} - (${tramo5_sc} - ${tramo4_sc}) * ${tasa4_sc} - (${tramo4_sc} - ${tramo3_sc}) * ${tasa3_sc} - (${tramo3_sc} - ${tramo2_sc}) * ${tasa2_sc} - (${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc} ;
	global b6_sc = (1 - ${tasa6_sc});

	global a7_sc = ${tramo7_sc} * ${tasa7_sc} - (${tramo7_sc} - ${tramo6_sc}) * ${tasa6_sc} - (${tramo6_sc} - ${tramo5_sc}) * ${tasa5_sc} - (${tramo5_sc} - ${tramo4_sc}) * ${tasa4_sc} - (${tramo4_sc} - ${tramo3_sc}) * ${tasa3_sc} - (${tramo3_sc} - ${tramo2_sc}) * ${tasa2_sc}-(${tramo2_sc} - ${tramo1_sc}) * ${tasa1_sc} ;
	global b6_sc = (1 - ${tasa6_sc}); 
	global b7_sc = (1 - ${tasa7_sc});

	** Tasas y Descuento Impuesto Global Complementario ** 
	
	* Los siguientes globales contienen los coeficientes de cada tramo de la funcion que transforma ingresos brutos en ingresos netos.;
	* Dado que cada tramos es una funcion lineal, "ai" corresponde a la constante y "bi" a la pendiente del tramo i-esimo.; 

	*#delimit ;
	global a1 = ${tramo1}*${tasa1};
	global b1 = (1 - ${tasa1});

	global a2 = ${tramo2} * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1}; 
	global b2 = (1 - ${tasa2});

	global a3 = ${tramo3} * ${tasa3} - (${tramo3} - ${tramo2}) * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1} ;
	global b3 = (1 - ${tasa3});

	global a4 = ${tramo4} * ${tasa4} - (${tramo4} - ${tramo3}) * ${tasa3} - (${tramo3} - ${tramo2}) * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1} ;
	global b4 = (1 - ${tasa4});

	global a5 = ${tramo5} * ${tasa5} - (${tramo5} - ${tramo4}) * ${tasa4} - (${tramo4} - ${tramo3}) * ${tasa3} - (${tramo3} - ${tramo2}) * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1} ;
	global b5 = (1 - ${tasa5});

	global a6 = ${tramo6} * ${tasa6} - (${tramo6} - ${tramo5}) * ${tasa5} - (${tramo5} - ${tramo4}) * ${tasa4} - (${tramo4} - ${tramo3}) * ${tasa3} - (${tramo3} - ${tramo2}) * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1} ;
	global b6 = (1 - ${tasa6});

	global a7 = ${tramo7} * ${tasa7} - (${tramo7} - ${tramo6}) * ${tasa6} - (${tramo6} - ${tramo5}) * ${tasa5} - (${tramo5} - ${tramo4}) * ${tasa4} - (${tramo4} - ${tramo3}) * ${tasa3} - (${tramo3} - ${tramo2}) * ${tasa2} - (${tramo2} - ${tramo1}) * ${tasa1};
	global b7 = (1 - ${tasa7});

	
	
*************************************************************************************************************************************;
*************************************************************************************************************************************;






#delimit cr

*************************************************** 1 - Definicion de Funciones **********************************************************************
*************************************************************************************************************************************

* Funcion Inversa (Brutificadora) del Impuesto de Segunda Categoria
cap program drop brutificar_sc
program brutificar_sc
	args ing
	
	************** Funcion Inversa del impuesto segunda categoria. Genera el ingreso bruto teorico en base al salario reportado, falta restar colacion y transporte (sobre datos reales de CASEN) ***********

	global ingreso = "yautt_sc"
	* La funcion es lineal por tramos.
	
	* En terminos del codigo la operacionalizacion es la siguiente:
	

	
	gen double 	`ing'_sc =  .
	* 2 - El ingreso bruto es igual al ingreso neto para el primer intervalo de  ingresos netos [ 0 , ${tramo1_sc} ) esta exento 
	replace `ing'_sc = `ing' 						if `ing' >= 0 							& 	`ing' < ${tramo1_sc} 
	* 3 - Para cada intervalo calculamos el ingreso bruto con la respectiva la inversa de la funcion 
	*	  del impuesto a la renta para cada intervalo 
	*	  tramo ( (y_n - ai)/bi) ). 
	*	  Esto siempre y cuando el ingreso neto se encuentre dentro del intervalo definido 
	*	  por las cotas "k" y "k+1" 
	
	replace `ing'_sc = (`ing' - ${a1_sc}) / ${b1_sc}	if `ing' >= ${a1_sc} + ${tramo1_sc} * ${b1_sc}   	& 	`ing' < ${a1_sc} + ${tramo2_sc} * ${b1_sc}
	replace `ing'_sc = (`ing' - ${a2_sc}) / ${b2_sc} 	if `ing' >= ${a2_sc} + ${tramo2_sc} * ${b2_sc}		& 	`ing' < ${a2_sc} + ${tramo3_sc} * ${b2_sc}
	replace `ing'_sc = (`ing' - ${a3_sc}) / ${b3_sc} 	if `ing' >= ${a3_sc} + ${tramo3_sc} * ${b3_sc}		& 	`ing' < ${a3_sc} + ${tramo4_sc} * ${b3_sc}
	replace `ing'_sc = (`ing' - ${a4_sc}) / ${b4_sc} 	if `ing' >= ${a4_sc} + ${tramo4_sc} * ${b4_sc}		& 	`ing' < ${a4_sc} + ${tramo5_sc} * ${b4_sc}
	replace `ing'_sc = (`ing' - ${a5_sc}) / ${b5_sc} 	if `ing' >= ${a5_sc} + ${tramo5_sc} * ${b5_sc}		& 	`ing' < ${a5_sc} + ${tramo6_sc} * ${b5_sc}
	replace `ing'_sc = (`ing' - ${a6_sc}) / ${b6_sc} 	if `ing' >= ${a6_sc} + ${tramo6_sc} * ${b6_sc}		& 	`ing' < ${a6_sc} + ${tramo7_sc} * ${b6_sc}
	replace `ing'_sc = (`ing' - ${a7_sc}) / ${b7_sc} 	if `ing' >= ${a7_sc} + ${tramo7_sc} * ${b7_sc}		& 	`ing' < ${a7_sc} + ${tramo8_sc} * ${b7_sc}
	replace `ing'_sc = 0 		if `ing'_sc	  < 0
	*label var `ing'_sc "ingreso `ing' bruto antes impuesto a segunda categoria"
	end
*************************************************************************************************************************************


** Funcion (Netificadora) del Impuesto Global Complementario 
cap program drop netificar
program netificar 

	args ing
	***************** Funcion del impuesto a la renta y generacion un ingreso neto ficticio **************
	*	2.1	- Generamos una variable ingreso neto (y_n) donde almacenaremos los ingresos netos a calcular
	gen double `ing'_n =  .
	*	2.2	- Para el primer intervalo (ingresos brutos entre 0 y ${tramo1} ) el ingreso neto es igual al bruto.		
	replace `ing'_n = `ing' 								if `ing' >= 0 									& 	`ing' < ${tramo1}
	*	2.3	- Para los intervalos 2 a 7 identificamos con "k" a la cota minima (de ingreso bruto) del intervalo d
	foreach k of numlist 1/7 {
		* He identificamos con "k+1" a la cota maxima del intervalo (de ingreso bruto)
		local k_1 = `k' + 1
		* Y para cada intervalo calculamos el ingreso neto con la respectiva funcion lineal de ese intervalo (ai+bi*y_b). 
		* Esto siempre y cuando el ingreso bruto se encuentre dentro del intervalo definido por las cotas "k" y "k+1"
		replace `ing'_n = ${a`k'} + ${b`k'} * `ing' 		if `ing' >= ${tramo`k'} 						& 	`ing' < ${tramo`k_1'}
	}
    *****************************************************************************************************		
end

** Funcion Inversa (Brutificadora) del Impuesto Global Complementario
cap program drop brutificar
program brutificar 
	args ing
	************** Funcion Inversa del impuesto a la renta. Genera el ingreso bruto teorico (sobre datos reales de CASEN) ***********

	* Antes de aplicar la funcion que transforma ingresos netos de impuestos en ingresos brutos sobre los datos CASEN, 
	* aplicamos la misma funcion pero sobre los ingresos netos ficticios arriva generados. Si nuestra formula esta
	* correcta, el ingreso bruto obtenido aqui (y_b1) y el generado ficticiamente mas arriba (y_b)
	global ingreso = "yautt"
	* La funcion es lineal por tramos y su derivacion puede ser encontrada en el documento homonimo a este "do" [PAG ????].
	* En terminos del codigo la operacionalizacion es la siguiente:
	
	* 1 - Generamos un variable donde se iran almacenando los ingresos brutos calculados (y_b1)
	gen double 	`ing'_b =  .
	* 2 - El ingreso bruto es igual al ingreso neto para el primer intervalo de  ingresos netos [ 0 , ${tramo1} )
	replace `ing'_b = `ing' 						if `ing' >= 0 							& 	`ing' < ${tramo1} 
	* 3 - Para cada intervalo calculamos el ingreso bruto con la respectiva la inversa de la funcion 
	*	  del impuesto a la renta para cada intervalo 
	*	  tramo ( (y_n - ai)/bi) ). 
	*	  Esto siempre y cuando el ingreso neto se encuentre dentro del intervalo definido 
	*	  por las cotas "k" y "k+1" 
	replace `ing'_b = (`ing' - ${a1}) / ${b1}	if `ing' >= ${a1} + ${tramo1} * ${b1}   	& 	`ing' < ${a1} + ${tramo2} * ${b1}
	replace `ing'_b = (`ing' - ${a2}) / ${b2} 	if `ing' >= ${a2} + ${tramo2} * ${b2}		& 	`ing' < ${a2} + ${tramo3} * ${b2}
	replace `ing'_b = (`ing' - ${a3}) / ${b3} 	if `ing' >= ${a3} + ${tramo3} * ${b3}		& 	`ing' < ${a3} + ${tramo4} * ${b3}
	replace `ing'_b = (`ing' - ${a4}) / ${b4} 	if `ing' >= ${a4} + ${tramo4} * ${b4}		& 	`ing' < ${a4} + ${tramo5} * ${b4}
	replace `ing'_b = (`ing' - ${a5}) / ${b5} 	if `ing' >= ${a5} + ${tramo5} * ${b5}		& 	`ing' < ${a5} + ${tramo6} * ${b5}
	replace `ing'_b = (`ing' - ${a6}) / ${b6} 	if `ing' >= ${a6} + ${tramo6} * ${b6}		& 	`ing' < ${a6} + ${tramo7} * ${b6}
	replace `ing'_b = (`ing' - ${a7}) / ${b7} 	if `ing' >= ${a7} + ${tramo7} * ${b7}		& 	`ing' < ${a7} + ${tramo8} * ${b7}
	replace `ing'_b = 0 		if `ing'_b	  < 0
	label var `ing'_b "ingreso (`ing') bruto antes impuesto a la renta y despues de impuestos previsionales"
	end
	
*************************************************************************************************************************************
*************************************************************************************************************************************

************************************************* 2 - Construccion de Variables *****************************************************
*************************************************************************************************************************************

*************************************************************************************************************************************
*************************************************************************************************************************************

************************************************* 2 - Construccion de Variables *****************************************************
*************************************************************************************************************************************

cd "C:\Users\manue\Documents\Banco Central\Trabajo\tesis\Replicability\CASEN\2020"
use "Casen2020"

keep folio o id_vivienda hogar expr o* edad y* activ dau qaut numper  pco1


* 2.1 - Poblacion en edad de trabajar (wap): distingue entre menores de 18 años (wap=0), 
*		edad entre 18 y 65 (wap=1) y mayores de 65 años (wap=2)
gen 	wap		=	0
replace wap		=	1 		if edad >= 18 & edad <= 65		/* Working Age Population */
replace wap		=	2 		if edad >  65					/* Retirement Age Population */

* 2.2 - Poblacion de trabajadores dependientes (dep): distingue entre trabajadores asalariados (dep=1)
*		y quienes no (dep=0)[ESTA VARIABLE YA NO LA OCUPAMOS] // activ==1 -> ocupado

gen 	dep		=	0		if ${id_dep} <=2 & ${id_dep} != . & activ==1
replace dep		=	1 		if ${id_dep} > 2 & ${id_dep} != 9 &${id_dep} != . & activ==1




***************************************************************************************************

* 2.3 - Se definen las diferentes partidas de ingreso antes y despues de impuestos que, ya existen o serán
*		construidas en este "do". 

***** Variables a almacenar los INGRESOS NETOS DE IMPUESTOS y SS ********

gen y_n1		=	.
label var y_n1 	"Partida de Ingresos Asalariados, Neto de Impuestos y SS"
gen y_n2		=	.
label var y_n2 	"Partida de Ingresos Como Independiente, Neto de Impuestos y SS"
gen y_n3		=	.
label var y_n3 	"Partida de Ingresos del Capital, Neto de Impuestos y SS"
gen y_n4		=	.
label var y_n4 	"Partida de Ingresos de las Pensiones, Neto de Impuestos y SS"


***** Variables a almacenar los INGRESOS BRUTOS DE IMPUESTOS y NETOS SS ********

gen y_ns1		=	.
label var y_ns1 	"Partida de Ingresos Asalariados, Bruto de Impuestos y Neto SS"
gen y_ns2		=	.
label var y_ns2 	"Partida de Ingresos Como Independiente, Bruto de Impuestos y Neto SS"
gen y_ns3		=	.
label var y_ns3 	"Partida de Ingresos del Capital, Bruto de Impuestos y Neto SS"
gen y_ns4		=	.
label var y_ns4 	"Partida de Ingresos de las Pensiones, Bruto de Impuestos y Neto SS"

***********************************************************************************

***** Variables a almacenar los INGRESOS BRUTOS DE IMPUESTOS y SS ********

gen y_bb1		=	. // Ahora podemos recuperar esta variable (y_sc)
label var y_bb1	"Partida de Ingresos Asalariados, Brutos de Impuestos y SS"
gen y_bb2		=	.
label var y_bb2	"Partida de Ingresos Como Independiente, Brutos de Impuestos y SS"
gen y_bb3		=	.
label var y_bb3	"Partida de Ingresos del Capital, Brutos de Impuestos y SS"
gen y_bb4		=	.
label var y_bb4	"Partida de Ingresos de las Pensiones, Brutos de Impuestos y SS"

*******************************************************************************************************************


* 2.4 - Se generan las corrientes de ingreso año 2017 **************************************************************

* ytrabajocor es una variable que crea la CEPAL y contiene todos los ingresos provenientes del trabajo (asalariado, independiente y otros)
* La variable es computada segun: ytrabajocor = sum(y0101c, y0301, y0302, y0303, y0304, y0305, y0306, y0401, y0402, y0403, y0404, y0501, y0502, y0503, y0504, y0505, y0506, y0507, y0508, y0509, y0510, y0511, y0512, y0701c, y0801, y0901, y1101, yosa, yosi, yta1, yta2, ytro, yac2)

	* Generamos el ingreso de los asalariados
	****modificar según año

	egen aux1 = rsum(y0101c y0301 y0302 y0303 y0304 y0305 y0306 y0401 y0402 y0403 y0404 y0501 y0502 y0503 y0504 y0505 y0506 y0507 y0508 y0509 y0510 y0511 y0512 y1101 yosa yta1)
	
	replace y_n1 = aux1  //ingreso de los asalariados neto incluyendo especies
	
    * Restamos ingresos en especies de los asalariados, ya que no pagan impuesto a la renta
	egen especies_em = rsum(y0501 y0502 y0503 y0504 y0505 y0506 y0507 y0508 y0509 y0510 y0511  y0512) // detalles de estas variables en el libro de codigos 
	gen y_ne1	=	y_n1 - especies_em
	
	sum y_ne1 [w=expr] if y_ne1>0, detail
	
	sum y_n1 if y_n1>0 [w=expr], detail
	
	
	drop if edad<20
	
* Generamos el ingreso de los independientes

	egen aux2 = rsum(y0701c y0801 y0901 yac2 yosi yta2)
	egen especies_se = rsum(y0801 yac2)
	replace y_n2 =	aux2 
	gen y_ne2=y_n2-especies_se
	
	replace y_bb2 =	aux2 
 
	replace y_bb2 =(aux2-especies_se)/0.9+especies_se if ${da_boleta}
	
	sum y_bb2 if y_bb2>0&dep==0 [w=expr], detail

	
	   * Partida de Ingresos de las Pensiones Neto
	* egen aux1 = rsum(y260201c y2603c  yinv01 yinv03 ymon yorf yotp)
	egen aux3 = rsum(y2801 y280201 y2803 y2804  yinv01 yinv02 yinv03 ymon yorf yotp)
	replace y_n4 = aux3
	

	
	****** Partida de Ingresos del Capital Neto
	
	
	***ingresos totales del capital (dividendos, retiro de utilidades, intereses. Incluye arriendos que no están en la frontera de cn). Netos de impuesto.
	
	egen cap_tot= rsum(yrut yah1 yah2 yre1 yama yre2 yre3)
	
	
 
 
	sum cap_tot [w=expr] if cap_tot>0, detail

	******Generamos ingresos del capital imputado 
	gen aux1235=yautcor*expr
	egen yaut_tot =total(aux1235)
    gen kshare = ${capital_CN}/yaut_tot/12
	
	***capital de CN respecto a ingreso autónomo casen
	sum kshare
	
	sort yautcor
		xtile p_yaut = yautcor [pweight=expr],nq(1000)

    gen cap_imputado =( ${k_i}* kshare* yautcor)*(p_yaut-800)/200 if p_yaut>800
	sum cap_imputado if cap_imputado>0 [w=expr], detail
		
	
	egen aux4 = rsum(cap_tot cap_imputado)
	replace y_n3 = aux4
	
	
	

******generamos ingreso sujeto a IGC, neto

	egen y_gc =rsum(y_ne1 y_ne2 y_n3 y_n4)
	
	sum y_gc [w=expr] if y_gc>0, detail
	
	sum y_gc [w=expr] if y_gc>0, detail
    	
	*****************************	REPORTAR LOS INGRESOS NETOS ORIGINALES DE CASEN, GUARDAR EN EXCEL "resultados_casen_stata.xlsx"
	
	******salarios totales
	sum y_n1 [w=expr] if y_n1>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify
	putexcel B1 = "Media", overwritefmt
	putexcel C1 = "Mediana", overwritefmt
	putexcel D1 = "P90", overwritefmt
	putexcel E1 = "N", overwritefmt
	
	putexcel A2 = "y_n1 CASEN", overwritefmt
	putexcel B2 = `r(mean)', overwritefmt
	putexcel C2 = `r(p50)', overwritefmt
	putexcel D2 = `r(p90)', overwritefmt
	putexcel E2 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_n1 [w=expr] if y_n1>0&dep==1, detail
	
	putexcel A3 = "y_n1_dep CASEN", overwritefmt
	putexcel B3 = `r(mean)', overwritefmt
	putexcel C3 = `r(p50)', overwritefmt
	putexcel D3 = `r(p90)', overwritefmt
	putexcel E3 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_n2 [w=expr] if y_n2>0, detail

	putexcel A4 = "y_n2 CASEN", overwritefmt
	putexcel B4 = `r(mean)', overwritefmt
	putexcel C4 = `r(p50)', overwritefmt
	putexcel D4 = `r(p90)', overwritefmt
	putexcel E4 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_n2 [w=expr] if y_n2>0&dep==0, detail

	putexcel A5 = "y_n2_indep CASEN", overwritefmt
	putexcel B5 = `r(mean)', overwritefmt
	putexcel C5 = `r(p50)', overwritefmt
	putexcel D5 = `r(p90)', overwritefmt
	putexcel E5 = `r(sum_w)', overwritefmt
	
	
		*********Ingreso imponible neto
	
	sum y_gc [w=expr] if y_gc>0, detail

	putexcel A6 = "y_gc CASEN", overwritefmt
	putexcel B6 = `r(mean)', overwritefmt
	putexcel C6 = `r(p50)', overwritefmt
	putexcel D6 = `r(p90)', overwritefmt
	putexcel E6 = `r(sum_w)', overwritefmt
	
	
	
	egen y_ntrab =rsum(y_n1 y_n2)
	
	sum y_ntrab [w=expr] if y_ntrab>0&(dep==0|dep==1), detail

	putexcel A35 = "y_ntrab", overwritefmt
	putexcel B35 = `r(mean)', overwritefmt
	putexcel C35 = `r(p50)', overwritefmt
	putexcel D35 = `r(p90)', overwritefmt
	putexcel E35 = `r(sum_w)', overwritefmt
	
	
		*******Brutificamos el ingreso sujeto al IGC
		
	
	
	brutificar_sc y_gc
	
	
	
	sum y_gc_sc [w=expr] if y_gc_sc>0, detail
	
	
	*****Para aquéllos que pagan impuestos, construimos ingresos brutos según tasa media
	
	***** y_ns serán brutos de impuestos, netos de cotizaciones. y_bb brutos de ambos
		
	gen tasa_media = (y_gc_sc-y_gc)/y_gc_sc
	replace y_ns1 = y_n1
	
	replace y_ns1=y_ne1/(1-tasa_media)+especies_em 
	
	*if ${firmo}
	
	replace y_ns2 = y_n2
	
	replace y_ns2		=	(y_bb2-	especies_se)*(1-(tasa_media/100))+especies_se if ${da_boleta}
	sum y_ns1 [w=expr] if y_ns1>0&dep==1, detail
	
	
	
	**********************CAPITAL Y PENSIONES NO EVADEN, REVISAR
	replace y_ns3=y_n3/(1-tasa_media) 
	
	replace y_ns4=y_n4/(1-tasa_media) 
	
	
	********ingreso bruto de impuestos, neto de seguridad social
	egen y_ns =rsum(y_ns1 y_ns2 y_ns3 y_ns4)
		
	sum y_ns [w=expr] if y_ns>0, detail
	*******recaudación simulada IGC
	gen igc = y_ns-y_gc -especies_em -especies_se
	
	sum igc [w=expr] if igc>0, detail
	
	gen aux222=igc*expr
	
	egen rec_igc=total(aux222)
		
	gen f_recigc= ${rec_sii} / rec_igc/12
	tab f_recigc
	
	sum y_ns [w=expr] if y_ns>${tramo1}, detail
	**********incorporamos evasión proporcional
	********Generar cotizaciones previsionales


gen 	cot		=	( y_ns1 * ${tasa_ss} ) / (1 - ${tasa_ss})
replace cot		=	${corte_ss} * ${tasa_ss}		 			if cot > ${corte_ss} * ${tasa_ss}
replace cot=0 if (${no_tiene_afp}|~${cot_pension})
*|${no_firmo}
label var  cot "Cotizaciones previsionales de los asalariados"

gen cot_salud= cot*${tasa_ss2}/${tasa_ss}
label var  cot_salud "Cotizaciones de salud de los asalariados"

sum cot [w=expr] if cot>0, detail

gen aux1111=cot_salud*expr
egen tot_salud=total(aux1111)

gen aux2222=y_ns1*expr
egen tot_salneto =total(aux2222)


***888 HACER LO MISMO CON LOS INDEP
gen f_salnet = (${sal_cn}-${cot_dep}*${tasa_ss}/${tasa_ss2})/tot_salneto/12
tab f_salnet
gen f_cots = ${cot_dep} /tot_salud/f_salnet/12

gen ev_ss_dep= 1 - f_cots*f_salnet

tab f_cots
replace cot= cot*f_cots
replace cot_salud=cot_salud*f_cots
sum cot [w=expr] if cot>0, detail



*******de los independientes
gen 	cot_i	=	( y_ns2 * ${tasa_ss2} ) / (1 - ${tasa_ss2}) 
replace cot_i	=	${corte_ss} * ${tasa_ss2}		 			if cot > ${corte_ss} * ${tasa_ss}
replace cot_i=0 if (${no_tiene_afp})
label var  cot_i "Cotizaciones previsionales de los independientes"

sum cot_i [w=expr] if cot_i>0, detail

gen aux2323=cot_i*expr
egen tot_salud_i=total(aux2323)
gen aux2223=y_ns2*expr
egen tot_indneto =total(aux2223)

gen f_indepnet = (${indep_cn}-${cot_indep})/tot_indneto/12

gen f_cots_i = ${cot_indep}/tot_salud_i/f_indepnet/12
gen ev_ss_indep= 1 - f_cots_i*f_indepnet

replace cot_i=cot_i*f_cots_i 
	
sum cot_i [w=expr] if cot_i>0, detail

***Salarios brutos de impuestos y SS

sum y_ns1 [w=expr] if y_ns1>0, detail

replace y_bb1=y_ns1+ cot

sum y_bb1 [w=expr] if y_bb1>0, detail
sum y_bb1 [w=expr] if y_bb1>0&dep==1, detail


egen y_bb2b = rsum(y_ns2 cot_i)
replace y_bb2=y_bb2b
drop y_bb2b

replace y_bb3 = y_n3/(1-tasa_media)
replace y_bb4 = y_n4/(1-tasa_media)

egen y_bbtrab=rsum(y_bb1 y_bb2)

sum y_bbtrab [w=expr] if y_bbtrab>0&(dep==0|dep==1),detail

egen y_bb =rsum(y_bb1 y_bb2 y_bb3 y_bb4)
egen y_bb22 =rsum(y_bb1 y_bb2 y_bb3)



sum y_bb22 [w=expr] if y_bb22>0, detail
sum y_bb [w=expr] if y_bb>0, detail

***************************************************************************
	*****************************	REPORTAR LOS INGRESOS NETOS ORIGINALES DE CASEN, GUARDAR EN EXCEL "resultados_casen_stata.xlsx"
	
	******salarios totales
	sum y_bb1 [w=expr] if y_bb1>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify
	putexcel A7 = "y_bb1 CASEN", overwritefmt
	putexcel B7 = `r(mean)', overwritefmt
	putexcel C7 = `r(p50)', overwritefmt
	putexcel D7 = `r(p90)', overwritefmt
	putexcel E7 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_bb1 [w=expr] if y_bb1>0&dep==1, detail
	
	putexcel A8 = "y_bb1_dep CASEN", overwritefmt
	putexcel B8 = `r(mean)', overwritefmt
	putexcel C8 = `r(p50)', overwritefmt
	putexcel D8 = `r(p90)', overwritefmt
	putexcel E8 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_bb2 [w=expr] if y_bb2>0, detail

	putexcel A9 = "y_bb2 CASEN", overwritefmt
	putexcel B9= `r(mean)', overwritefmt
	putexcel C9= `r(p50)', overwritefmt
	putexcel D9= `r(p90)', overwritefmt
	putexcel E9= `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_bb2 [w=expr] if y_bb2>0&dep==0, detail

	putexcel A10 = "y_b2_indep CASEN", overwritefmt
	putexcel B10 = `r(mean)', overwritefmt
	putexcel C10 = `r(p50)', overwritefmt
	putexcel D10 = `r(p90)', overwritefmt
	putexcel E10 = `r(sum_w)', overwritefmt
	
	
		*********Ingreso imponible neto
	
	sum y_bb [w=expr] if y_gc>0, detail

	putexcel A11 = "y_bb CASEN", overwritefmt
	putexcel B11 = `r(mean)', overwritefmt
	putexcel C11 = `r(p50)', overwritefmt
	putexcel D11= `r(p90)', overwritefmt
	putexcel E11 = `r(sum_w)', overwritefmt
	
	

	
	sum y_bbtrab [w=expr] if y_bbtrab>0&(dep==0|dep==1), detail

	putexcel A36 = "y_bbtrab", overwritefmt
	putexcel B36 = `r(mean)', overwritefmt
	putexcel C36 = `r(p50)', overwritefmt
	putexcel D36 = `r(p90)', overwritefmt
	putexcel E36 = `r(sum_w)', overwritefmt






	
******

***datos de Banco Central, ver excel



gen aux11=y_bb1*expr
gen aux12=y_bb2*expr

gen aux13=cot_salud*expr
gen aux14=cot_i*expr

gen aux15=y_bb3*expr
egen cap_CASEN=total(aux15)

egen sal_casen =total(aux11)
egen indep_casen =total(aux12)

egen cotdep_casen =total(aux13)
egen cotindep_casen =total(aux14)

gen f_rem = ( ${sal_cn})/ (sal_casen)/12

gen f_indep = ( ${indep_cn})/ (indep_casen)/12

gen f_cotd=${cot_dep} / cotdep_casen/12
gen f_cotind=${cot_indep} / cotindep_casen/12
gen f_cap =${capital_CN}/cap_CASEN/12

sum f_rem

sum f_cotd
sum f_indep
sum f_cotind
sum f_cap


gen y_b1CN=y_bb1*f_rem
gen y_b2CN=y_bb2*f_indep


***88888
gen y_ns1CN= y_ns1*f_rem 

gen y_ns2CN= y_ns2*f_indep 



gen y_b3CN=y_bb3*f_cap
gen y_b4CN=y_bb4
egen y_gc_CN = rsum(y_b1CN y_b2CN y_b3CN y_b4CN)


*********************REPORTE DE INGRESOS BRUTOS, CON AJUSTE A CN
**************************************************************************************************

	*****************************	REPORTAR, GUARDAR EN EXCEL "resultados_casen_stata.xlsx"
	
	******salarios totales
	sum y_b1CN [w=expr] if y_b1CN>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify

	putexcel A12 = "y_b1 CN", overwritefmt
	putexcel B12 = `r(mean)', overwritefmt
	putexcel C12= `r(p50)', overwritefmt
	putexcel D12 = `r(p90)', overwritefmt
	putexcel E12 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_b1CN [w=expr] if y_b1CN>0&dep==1, detail
	
	putexcel A13 = "y_b1_dep CN", overwritefmt
	putexcel B13 = `r(mean)', overwritefmt
	putexcel C13= `r(p50)', overwritefmt
	putexcel D13 = `r(p90)', overwritefmt
	putexcel E13 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_b2CN [w=expr] if y_b2CN>0, detail

	putexcel A14 = "y_b2 CN", overwritefmt
	putexcel B14 = `r(mean)', overwritefmt
	putexcel C14 = `r(p50)', overwritefmt
	putexcel D14 = `r(p90)', overwritefmt
	putexcel E14 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_b2CN [w=expr] if y_b2CN>0&dep==0, detail

	putexcel A15 = "y_b2_indep CN", overwritefmt
	putexcel B15= `r(mean)', overwritefmt
	putexcel C15= `r(p50)', overwritefmt
	putexcel D15= `r(p90)', overwritefmt
	putexcel E15= `r(sum_w)', overwritefmt
	
	
	*****trabajadores total
	
	egen y_btrabCN= rsum(y_b2CN y_b1CN)
	
	sum y_btrabCN [w=expr] if y_btrabCN>0&(dep==0|dep==1), detail
	putexcel A37 = "y_trabCN", overwritefmt
	putexcel B37 = `r(mean)', overwritefmt
	putexcel C37= `r(p50)', overwritefmt
	putexcel D37 = `r(p90)', overwritefmt
	putexcel E37 = `r(sum_w)', overwritefmt
	
	******salarios totales
	sum y_ns1CN [w=expr] if y_ns1CN>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify

	putexcel A16 = "y_ns1 CN", overwritefmt
	putexcel B16 = `r(mean)', overwritefmt
	putexcel C16= `r(p50)', overwritefmt
	putexcel D16 = `r(p90)', overwritefmt
	putexcel E16 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_ns1CN [w=expr] if y_ns1CN>0&dep==1, detail
	
	putexcel A17 = "y_ns1_dep CN", overwritefmt
	putexcel B17 = `r(mean)', overwritefmt
	putexcel C17= `r(p50)', overwritefmt
	putexcel D17 = `r(p90)', overwritefmt
	putexcel E17 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_ns2CN [w=expr] if y_ns2CN>0, detail

	putexcel A18 = "y_ns2 CN", overwritefmt
	putexcel B18 = `r(mean)', overwritefmt
	putexcel C18 = `r(p50)', overwritefmt
	putexcel D18 = `r(p90)', overwritefmt
	putexcel E18 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_ns2CN [w=expr] if y_ns2CN>0&dep==0, detail

	putexcel A19 = "y_ns2_indep CN", overwritefmt
	putexcel B19= `r(mean)', overwritefmt
	putexcel C19= `r(p50)', overwritefmt
	putexcel D19= `r(p90)', overwritefmt
	putexcel E19= `r(sum_w)', overwritefmt
	
		*********Ingreso imponible neto
	
	sum y_gc_CN [w=expr] if y_gc_CN>0, detail

	putexcel A20 = "y_bb CN", overwritefmt
	putexcel B20= `r(mean)', overwritefmt
	putexcel C20= `r(p50)', overwritefmt
	putexcel D20= `r(p90)', overwritefmt
	putexcel E20= `r(sum_w)', overwritefmt
	
	
	******trabajadores neto
	
	egen y_nstrabCN =rsum(y_ns1CN y_ns2CN)
	
	sum y_nstrabCN [w=expr] if y_nstrabCN>0&(dep==0|dep==1), detail
	putexcel A38 = "y_nstrabCN", overwritefmt
	putexcel B38 = `r(mean)', overwritefmt
	putexcel C38= `r(p50)', overwritefmt
	putexcel D38 = `r(p90)', overwritefmt
	putexcel E38 = `r(sum_w)', overwritefmt
	




****************************************************

**CORRECCIÓN BFM PARA AJUSTAR POR MISSING RICH


************************************ VARIABLE DE AJUSTE, A CORREGIR CON DATOS ADMINISTRATIVOS, ES EL INGRESO IMPONIBLE NETO
gen y_gc1=y_gc*12




egen tot_exp=total(expr)

gen trabajador=1 if dep!=.
replace trabajador=0 if dep==.
gen contrib=1 if y_gc>0
replace contrib=0 if contrib==.

gen cotiza=0
replace cotiza=1 if ${cot_pension}

replace cap_imputado=0 if cap_imputado==.
gen y_bbb= y_bb- cap_imputado
	putexcel set resultados_casen_stata.xlsx, sheet(Figure 10) modify
ineqdeco y_bbb [w=expr] if  y_bbb>0 

	putexcel L8 =`r(gini)', overwritefmt
	
sum y_bbb [w=expr] if  y_bbb>0, detail

	putexcel H8 =`r(mean)', overwritefmt
    putexcel I8 =`r(p50)', overwritefmt
	
	


drop aux*
bfmcorr using "C:\Users\manue\Documents\Banco Central\Trabajo\tesis\Replicability\CASEN\2020\gpinter 2020 out.xlsx", weight(expr) income(y_gc1) households(id_vivienda) taxunit(i) merg(${p_bfm} ) holdmar(dep cotiza trabajador contrib)

egen tot_cw=total(_weight)

gen cweight =_weight*tot_exp/tot_cw


*ineqerr y_gc1 [w=cweight] if y_gc1>0
*****Para verificar concordancia a base sintética de impuestos

	*****************************	REPORTAR LOS NETOS, GUARDAR EN EXCEL "resultados_casen_stata.xlsx"
	
	******salarios totales
	sum y_n1 [w=cweight] if y_n1>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify

	putexcel A21 = "y_n1BFM CASEN", overwritefmt
	putexcel B21 = `r(mean)', overwritefmt
	putexcel C21 = `r(p50)', overwritefmt
	putexcel D21 = `r(p90)', overwritefmt
	putexcel E21 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_n1 [w=cweight] if y_n1>0&dep==1, detail
	
	putexcel A22 = "y_n1_depBFM CASEN", overwritefmt
	putexcel B22 = `r(mean)', overwritefmt
	putexcel C22 = `r(p50)', overwritefmt
	putexcel D22 = `r(p90)', overwritefmt
	putexcel E22 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_n2 [w=cweight] if y_n2>0, detail

	putexcel A23 = "y_n2BFM CASEN", overwritefmt
	putexcel B23 = `r(mean)', overwritefmt
	putexcel C23 = `r(p50)', overwritefmt
	putexcel D23 = `r(p90)', overwritefmt
	putexcel E23 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_n2 [w=cweight] if y_n2>0&dep==0, detail

	putexcel A24 = "y_n2_indepBFM CASEN", overwritefmt
	putexcel B24 = `r(mean)', overwritefmt
	putexcel C24 = `r(p50)', overwritefmt
	putexcel D24 = `r(p90)', overwritefmt
	putexcel E24 = `r(sum_w)', overwritefmt
	
	
		*********Ingreso imponible neto
	
	sum y_gc [w=cweight] if y_gc>0, detail

	putexcel A25 = "y_gcBFM CASEN", overwritefmt
	putexcel B25 = `r(mean)', overwritefmt
	putexcel C25 = `r(p50)', overwritefmt
	putexcel D25 = `r(p90)', overwritefmt
	putexcel E25 = `r(sum_w)', overwritefmt
	
	
	
	

drop cot
gen 	cot		=	( y_ns1 * ${tasa_ss} ) / (1 - ${tasa_ss})
replace cot		=	${corte_ss} * ${tasa_ss}		 			if cot > ${corte_ss} * ${tasa_ss}
replace cot=0 if (${no_tiene_afp}|~${cot_pension})
*|${no_firmo}
label var  cot "Cotizaciones previsionales de los asalariados"

drop cot_salud
gen cot_salud= cot*${tasa_ss2}/${tasa_ss}
label var  cot_salud "Cotizaciones de salud de los asalariados"

	
	
	
gen aux1111=cot_salud*cweight
egen tot_saludbf=total(aux1111)

gen aux2222=y_ns1*cweight
egen tot_salnetobf =total(aux2222)



gen f_salnetbf = (${sal_cn}-${cot_dep}*${tasa_ss}/${tasa_ss2})/tot_salnetobf/12
tab f_salnetbf
gen f_cotsbf = ${cot_dep} /tot_salud/f_salnetbf/12

gen ev_ss_depbf= 1 - f_cotsbf*f_salnetbf
tab f_cotsbf
replace cot= cot*f_cots
replace cot_salud=cot_salud*f_cots
sum cot [w=expr] if cot>0, detail

replace y_bb1=y_ns1+ cot
	
******************************888cotizaciones independientes
	drop cot_i
gen 	cot_i	=	( y_ns2 * ${tasa_ss2} ) / (1 - ${tasa_ss2}) 
replace cot_i	=	${corte_ss} * ${tasa_ss2}		 			if cot > ${corte_ss} * ${tasa_ss}
replace cot_i=0 if (${no_tiene_afp})
label var  cot_i "Cotizaciones previsionales de los independientes"

sum cot_i [w=cweight] if cot_i>0, detail

gen aux2323=cot_i*cweight
egen tot_salud_ibfm=total(aux2323)
gen aux2223=y_ns2*cweight
egen tot_indnetobfm =total(aux2223)
gen f_indepnetbfm = (${indep_cn}-${cot_indep})/tot_indnetobfm/12

gen f_cots_ibfm = ${cot_indep}/tot_salud_ibfm/f_indepnetbfm/12
gen ev_ss_indepbf= 1 - f_cots_ibf*f_indepnetbf
replace cot_i=cot_i*f_cots_ibfm 
	
sum cot_i [w=expr] if cot_i>0, detail
	
	
	
******Totales y factores de ajuste

gen aux333=igc*cweight

egen rec_igcbf=total(aux333)
gen f_recigc_bfm= ${rec_sii} / rec_igcbf/12
tab f_recigc_bfm

*******
gen aux21=y_bb1*cweight
gen aux22=y_bb2*cweight

gen aux23=cot_salud*cweight
gen aux24=cot_i*cweight

egen salarios_casenbf=total(aux21)
egen indep_casenbf =total(aux22)

egen cotdep_casenbf =total(aux23)
egen cotindep_casenbf =total(aux24)

gen f_rembf =(${sal_cn})/(salarios_casenbf)/12

gen f_indepbf=(${indep_cn}-${cot_indep})/(indep_casenbf-cotindep_casenbf)/12

gen f_cotdbf=${cot_dep}/cotdep_casenbf/12
gen f_cotindbf=${cot_indep}/cotindep_casenbf/12

gen aux15=y_bb3*cweight
egen cap_CASENbfm=total(aux15)
gen f_capbfm =${capital_CN}/cap_CASENbfm/12


sum f_rembf
sum f_capbfm
sum f_indepbf
sum f_cotdbf
sum f_cotindbf



gen y_b1cn=y_bb1*f_rembf
gen y_b2cn=y_bb2*f_indepbf

gen y_ns1cn= y_ns1*f_rembf

gen y_ns2cn= y_ns2*f_indepbf


gen y_b3cn=y_bb3*f_capbfm

sum y_b1cn [w=cweight] if y_b1cn>0&dep==1, detail


sum y_b2cn [w=cweight] if y_b2cn>0&dep==0, detail


******

egen y_bbcn=rsum(y_b1cn y_b2cn y_b3cn y_bb4)


	*****************************	REPORTAR, GUARDAR EN EXCEL "resultados_casen_stata.xlsx"
	
	******salarios totales
	sum y_b1cn [w=cweight] if y_b1cn>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify

	putexcel A26 = "y_b1 bfm CN", overwritefmt
	putexcel B26 = `r(mean)', overwritefmt
	putexcel C26= `r(p50)', overwritefmt
	putexcel D26 = `r(p90)', overwritefmt
	putexcel E26 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_b1cn [w=cweight] if y_b1cn>0&dep==1, detail
	
	putexcel A27 = "y_b1_dep bfm CN", overwritefmt
	putexcel B27 = `r(mean)', overwritefmt
	putexcel C27= `r(p50)', overwritefmt
	putexcel D27 = `r(p90)', overwritefmt
	putexcel E27 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_b2cn [w=cweight] if y_b2cn>0, detail

	putexcel A28 = "y_b2 bfm CN", overwritefmt
	putexcel B28 = `r(mean)', overwritefmt
	putexcel C28 = `r(p50)', overwritefmt
	putexcel D28 = `r(p90)', overwritefmt
	putexcel E28 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_b2cn [w=cweight] if y_b2cn>0&dep==0, detail

	putexcel A29 = "y_b2_indep bfm CN", overwritefmt
	putexcel B29= `r(mean)', overwritefmt
	putexcel C29= `r(p50)', overwritefmt
	putexcel D29= `r(p90)', overwritefmt
	putexcel E29= `r(sum_w)', overwritefmt
	
	
	
		egen y_btrabcn =rsum(y_b2cn y_b1cn)
	
	sum y_btrabcn [w=cweight] if y_btrabcn>0&(dep==0|dep==1), detail
	putexcel A39 = "y_btrabcn", overwritefmt
	putexcel B39 = `r(mean)', overwritefmt
	putexcel C39= `r(p50)', overwritefmt
	putexcel D39 = `r(p90)', overwritefmt
	putexcel E39 = `r(sum_w)', overwritefmt
	
	
		******salarios totales
	sum y_ns1cn [w=cweight] if y_ns1cn>0, detail
	putexcel set resultados_casen_stata.xlsx, sheet(${year_casen}) modify

	putexcel A30 = "y_ns1 bfm CN", overwritefmt
	putexcel B30 = `r(mean)', overwritefmt
	putexcel C30= `r(p50)', overwritefmt
	putexcel D30 = `r(p90)', overwritefmt
	putexcel E30 = `r(sum_w)', overwritefmt
	
	******salarios dep==1
	sum y_ns1cn [w=cweight] if y_ns1cn>0&dep==1, detail
	
	putexcel A31 = "y_ns1_dep bfm CN", overwritefmt
	putexcel B31 = `r(mean)', overwritefmt
	putexcel C31= `r(p50)', overwritefmt
	putexcel D31 = `r(p90)', overwritefmt
	putexcel E31 = `r(sum_w)', overwritefmt
	
	
	
	
	*********cuenta propia total
	
	sum y_ns2cn [w=cweight] if y_ns2cn>0, detail

	putexcel A32 = "y_ns2 bfm CN", overwritefmt
	putexcel B32 = `r(mean)', overwritefmt
	putexcel C32 = `r(p50)', overwritefmt
	putexcel D32 = `r(p90)', overwritefmt
	putexcel E32 = `r(sum_w)', overwritefmt
	
	
		*********cuenta propia de dep==0
	
	sum y_ns2cn [w=cweight] if y_ns2cn>0&dep==0, detail

	putexcel A33 = "y_ns2_indep bfm CN", overwritefmt
	putexcel B33= `r(mean)', overwritefmt
	putexcel C33= `r(p50)', overwritefmt
	putexcel D33= `r(p90)', overwritefmt
	putexcel E33= `r(sum_w)', overwritefmt
	
		egen y_nstrabcn =rsum(y_ns1cn y_ns2cn)
	
	sum y_nstrabcn [w=cweight] if y_nstrabcn>0&(dep==0|dep==1), detail
	putexcel A40 = "y_nstrabcn", overwritefmt
	putexcel B40 = `r(mean)', overwritefmt
	putexcel C40= `r(p50)', overwritefmt
	putexcel D40 = `r(p90)', overwritefmt
	putexcel E40 = `r(sum_w)', overwritefmt
	

	
	
	
	
	
	
	
	
	
	
	sum y_bbcn [w=cweight] if y_bbcn>0, detail

	putexcel A34 = "y_bb bfm CN", overwritefmt
	putexcel B34= `r(mean)', overwritefmt
	putexcel C34= `r(p50)', overwritefmt
	putexcel D34= `r(p90)', overwritefmt
	putexcel E34= `r(sum_w)', overwritefmt
	
	
	*****************REPORTAR FACTORES
	
	putexcel set resultados_casen_stata.xlsx, sheet(factors) modify
	
	putexcel A2 ="f_recigc", overwritefmt
	putexcel A3 ="f_cots", overwritefmt
	putexcel A4 ="f_cots_i", overwritefmt
	putexcel A5 ="f_rem", overwritefmt
	putexcel A6 ="f_indep", overwritefmt
	putexcel A7 ="f_cap", overwritefmt
	putexcel A8 ="f_recigc_bfm", overwritefmt
	putexcel A9 ="f_rembf", overwritefmt
	putexcel A10 ="f_indepbf", overwritefmt
	putexcel A11 ="f_capbfm", overwritefmt
	putexcel A12 ="f_cotsbf", overwritefmt
	putexcel A13 ="f_cots_ibf", overwritefmt
	
	putexcel h1 = ${year_casen} , overwritefmt
	sum f_recigc
	putexcel h2 =`r(mean)', overwritefmt
	sum f_cots
	putexcel h3 =`r(mean)', overwritefmt
	sum f_cots_i
	putexcel h4 =`r(mean)', overwritefmt
	sum f_rem
	putexcel h5 =`r(mean)', overwritefmt
	sum f_indep
	putexcel h6 =`r(mean)', overwritefmt
	sum f_cap
	putexcel h7 =`r(mean)', overwritefmt
	sum f_recigc_bfm
	putexcel h8 =`r(mean)', overwritefmt
	sum f_rembf
	putexcel h9 =`r(mean)', overwritefmt
	sum f_indepbf
	putexcel h10 =`r(mean)', overwritefmt
	sum f_capbfm
	putexcel h11 =`r(mean)', overwritefmt
	sum f_cotsbf
	putexcel h12 =`r(mean)', overwritefmt
	sum f_cots_ibf
	putexcel h13 =`r(mean)', overwritefmt
	

putexcel set resultados_casen_stata.xlsx, sheet(Figure 10) modify
	
ineqdeco y_bbcn [w=cweight] if  y_bbcn>0 

	putexcel M8 =`r(gini)', overwritefmt
	
sum y_bbcn [w=cweight] if  y_bbcn>0, detail

	putexcel J8 =`r(mean)', overwritefmt
    putexcel K8 =`r(p50)', overwritefmt

	



