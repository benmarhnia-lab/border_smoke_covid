*** Wildfire smoke and COVID-19 in the border region ***
*** Mexico data set *************************************
*** Version: November 20th, 2022 **********************************

*==============================================================================
* Setting working directories
*==============================================================================

//Lara's working directories	
	global datain "D:\Lara\Border\Code\covid\Github\data"                      
	global dataout "D:\Lara\Border\Code\covid\Github\Data_prep"
	global results "D:\Lara\Border\Code\covid\Github\results"
				
*==============================================================================
* Data Prep
*==============================================================================
* This dataset is from the COVID-19: Mexican Secretary of Health Epidemiological Surveillance System for Viral Respiratory Diseases Bases de datos covid 19 en méxico. https://datos.gob.mx/busca/dataset/informacion-referente-a-casos-covid-19-en-mexico Información del Sistema de Vigilancia Epidemiológica de Enfermedades Respiratoria Viral. -Mexico-

*Information about the dataset and variables can be found in the following:
*data_info\201128 Catalogos
*data_info\201128 Descriptores_

import delimited "$datain\211013COVID19MEXICO.csv", encoding(UTF-8) 
save "$dataout\Mexico_covid.dta", replace

* keep only confirmed SARS-Cov2 cases
keep if clasificacion_final==3

*generate variable for hospitalized covid cases
gen hosp=.
replace hosp=1 if tipo_paciente==2
replace hosp=0 if tipo_paciente==1

* generate variable for positive cases from clinics
gen clinic=.
replace clinic=0 if tipo_paciente==2
replace clinic=1 if tipo_paciente==1

* generate variable for positive cases from clinics & hospitals (all)
gen case=.
replace case=0 if clinic==0 & hosp==0
replace case=1 if clinic==1|hosp==1

* mortality information
gen death=.
replace death=0 if fecha_def=="9999-99-99"|fecha_def==""
replace death=1 if fecha_def!="9999-99-99" & fecha_def!=""

gen date=date(fecha_ingreso, "YMD")

save "$dataout\Mexico_covid_data.dta", replace

** Since data is formatted with each day a patient, when they were diagnosed and if/when they died, the format of the death data has to be changed and merged back in. Need to generate new death variable considering total deaths on each day and merge in.

keep  entidad_res municipio_res fecha_def death

keep if death==1
gen date=date(fecha_def, "YMD")


collapse (sum) death, by(date municipio_res entidad_res)
save "$dataout\Mex_covid_deaths.dta", replace

use "$dataout\Mexico_covid_data.dta"

** make dataset for total daily  cases by entidad
collapse (sum) case, by(date municipio_res entidad_res)

** make sure there are no missing dates for municipalities that have missing data by creating new empty dataset and merging in
save "$dataout\Mexico_covid_cases.dta", replace

use "$dataout\Mexico_covid_cases.dta" 
save "$dataout\Mex_empty_data.dta", replace

keep  municipio_res entidad_res
duplicates drop  municipio_res entidad_res, force
expand 594
bysort municipio_res entidad_res:gen date=21971+_n
sort municipio_res entidad_res date
merge 1:1 entidad_res municipio_res date using "$dataout\Mexico_covid_cases.dta"

drop if _merge==2
drop _merge

** merging death data back in 
merge 1:1 entidad_res municipio_res date using "$dataout\Mex_covid_deaths.dta"

drop _merge

**generate cumulative deaths
 bysort  municipio_res entidad_res (date): gen cum_death =sum(death)
  
  ** if the day has missing case/death data we assume there were none
replace case=0 if case==.
replace death=0 if death==.



 * making stata formatted date
 gen year=year( date)
 gen month=month(date)
 
 ** save stata file
 save "$dataout\Mexico_covid_case_mort.dta", replace
 clear
*==============================================================================
* Prepare the smoke data (from R) 
*==============================================================================

import delimited "$datain\smk_intsct_Mex.csv"

tostring dates, generate(date)
 
gen date2=date( date, "YMD")
sort adm2_pcode date2

drop date
gen date=date2
 
format date %td
			
save "$dataout\Mex_smoke_by_munic", replace

  *==============================================================================
* Process the mobility data and save
*==============================================================================
	 
 import delimited "$datain\2020_MX_Region_Mobility_Report.csv", clear
 
  * we chose residential mobility as the variable for this analysis but other mobility measures can be used 
  rename residential_percent_change_from_ mobility_residence
  *rename parks_percent_change_from_baseli mobility_parks
  *rename grocery_and_pharmacy_percent_cha mobility_grocery
  *rename transit_stations_percent_change_ mobility_transit
  *rename workplaces_percent_change_from_b mobility_work
  
 drop if sub_region_1==""
 
 drop sub_region_2 metro_area census_fips_code
 
  rename date date2
  
   gen date=date(date2, "YMD")
   
   ** interpolate missing mobility data
				
	mipolate mobility_residence date , by(iso_3166_2_code) nearest generate(mobility)
	
	*saving only variables used in later analysis
	keep mobility date date2 iso_3166_2_code
	
 save  "$dataout\Mobility_data_Mex.dta", replace

   
*==============================================================================
* Merge the health and smoke and mobility data and save
*==============================================================================
	
	use   "$dataout\Mexico_covid_case_mort.dta", clear


	gen adm2_pcode=""
	
	replace adm2_pcode="MX"+string(entidad_res,"%02.0f")+ string(municipio_res ,"%03.0f")
	
	gen date2=date
	
	keep if year==2020
	
	* manually entered iso codes to merge in mobility information
	
	gen iso_3166_2_code=""
	replace iso_3166_2_code="MX-AGU" if entidad_res==1
	replace iso_3166_2_code="MX-BCN" if entidad_res==2
	replace iso_3166_2_code="MX-BCS" if entidad_res==3
	replace iso_3166_2_code="MX-CAM" if entidad_res==4
	replace iso_3166_2_code="MX-CHH" if entidad_res==8
	replace iso_3166_2_code="MX-CHP" if entidad_res==7
	replace iso_3166_2_code="MX-CMX" if entidad_res==9
	replace iso_3166_2_code="MX-COA" if entidad_res==5
	replace iso_3166_2_code="MX-COL" if entidad_res==6
	replace iso_3166_2_code="MX-DUR" if entidad_res==10
	
	replace iso_3166_2_code="MX-GRO" if entidad_res==12
	replace iso_3166_2_code="MX-GUA" if entidad_res==11
	replace iso_3166_2_code="MX-HID" if entidad_res==13
	replace iso_3166_2_code="MX-JAL" if entidad_res==14
	replace iso_3166_2_code="MX-MEX" if entidad_res==15
	replace iso_3166_2_code="MX-MIC" if entidad_res==16
	replace iso_3166_2_code="MX-MOR" if entidad_res==17
	replace iso_3166_2_code="MX-NAY" if entidad_res==18
	replace iso_3166_2_code="MX-NLE" if entidad_res==19
	replace iso_3166_2_code="MX-OAX" if entidad_res==20

	replace iso_3166_2_code="MX-PUE" if entidad_res==21
	replace iso_3166_2_code="MX-QUE" if entidad_res==22
	replace iso_3166_2_code="MX-ROO" if entidad_res==23
	replace iso_3166_2_code="MX-SIN" if entidad_res==25
	replace iso_3166_2_code="MX-SLP" if entidad_res==24
	replace iso_3166_2_code="MX-SON" if entidad_res==26
	replace iso_3166_2_code="MX-TAB" if entidad_res==27
	replace iso_3166_2_code="MX-TAM" if entidad_res==28
	replace iso_3166_2_code="MX-TLA" if entidad_res==29
	replace iso_3166_2_code="MX-VER" if entidad_res==30

	replace iso_3166_2_code="MX-YUC" if entidad_res==31
	replace iso_3166_2_code="MX-ZAC" if entidad_res==32


		merge 1:1 adm2_pcode date using "$dataout\Mex_smoke_by_munic.dta"
		
		keep if _merge==3
		
		drop _merge
		
		merge m:1 iso_3166_2_code date using "$dataout\Mobility_data_Mex.dta", force

		keep if _merge==3
		
		drop _merge
		 
		
		 
	save "$dataout\Mex_covid_smoke_by_munic.dta", replace
	

*==============================================================================
* Prepare the data for analysis 
*==============================================================================
use "$dataout\Mex_covid_smoke_by_munic.dta", clear
		
sort adm2_pcode date
bysort adm2_pcode: gen case_lag1 = case[_n - 1]

gen week=week(date)

*creating variable for standard deviation  of cases for 4 weeks prior
bys adm2_pcode : asrol case, stat(sd) window(week 4)
	
	*creating time variable for days since January 1st, 2020 (stata formatted is 21914)
	gen time = date-21914
	
	
	gen pheavy70=0
	replace pheavy70=1 if heavy_pct>=70
	replace pheavy70=. if heavy_pct==.
	
	gen pheavy90=0
	replace pheavy90=1 if heavy_pct>=90
	replace pheavy90=. if heavy_pct==.
	
	gen pheavy100=0
	replace pheavy100=1 if heavy_pct==100
	replace pheavy100=. if heavy_pct==.


	
***** Loop that creates new variable for each smoke exposure that represents the first smoke and a binary variable for when the smoke started. For this specific analysis it will be the same for all exposure measures in the exposed Municipality
foreach var in  pheavy70 pheavy90 pheavy100 {
sort adm2_pcode date2
by adm2_pcode (time), sort: gen byte smoke_`var'_day1 = sum(`var') == 1  & sum(`var'[_n - 1]) == 0  

 gen first_smoke_`var'=.
 replace first_smoke_`var' = time if smoke_`var'_day1==1
 
 

}
** Restricting to study period (August 1st to September 30th, 2020)
* drop if time<214 //Restricting to start on August 1st 
*drop if time>274 //Restricting to end September 30th	
 
 
 * removing any Municipality that had no deaths during the entire study period
 bysort adm2_pcode : egen deaths_tot = max( cum_death)
 *drop if deaths_tot==0

 *Tijuana has 1491 deaths total during study period so thought it was reasonable to restrict to municipalities at least 10 deaths during study period- THis is simply to reduce number of possible control units as memory usage was exceeding stata limits
 
* drop if deaths_tot<10
		
 
save "$dataout\Mex_covid_smoke_by_munic_all.dta", replace			
  *==============================================================================
* Analysis
*============================================================================== 

	* 	
	foreach exp in pheavy30 pheavy70	pheavy100 pheavy90  {  
		
		foreach CFR in  cum_death  {    
 
			use "$dataout\Mex_covid_smoke_by_munic_all.dta", clear
	
			drop if deaths_tot<10
			
				sort time
				gen day_smoke_treated = first_smoke_`exp'  if  adm2_pcode=="MX02004" &  smoke_`exp'_day1==1 // this will change based on percentile wanted
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				gsort -time 
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				sort adm2_pcode time

				gen X=.
				replace X=0 if time<day_smoke_treated
				replace X=1 if time>=day_smoke_treated
	 
				gen Y= `CFR'
				
				*rename Y Y_mis
				
				** interpolate missing case Y data
  
  	*mipolate Y_mis date , by(entidad_res municipio_res) nearest generate(Y)
	
	
				
				
				gen t=time                                                         
				
				sort adm2_pcode time
	 ** "MX02004" is the adm2_pcode for Tijuana, the treated unit in this analysis
				gen treated=.
				replace treated=1 if adm2_pcode=="MX02004"
				replace treated=0 if adm2_pcode!="MX02004"		

				egen avg_smoke=mean(`exp'), by(adm2_pcode)              
				
				//remove donor counties which had more than 1% smoke exposure
				drop if avg_smoke>0 & treated!=1   
				
			   
				egen id = group(adm2_pcode)	
				
				** Restricting to study period (August 1st to September 30th, 2020)
 drop if time<183 //Restricting to start on July 1st 
drop if time>274 //Restricting to end September 30th	
 

			
				egen day_one= min(t)  		
				
				save "$dataout\Mex_covid_smoke_`exp'_`CFR'.dta", replace 
	
	
			}	
			
		  }
				
			
			
			
  		
		
		
*==============================================================================
* Analysis 
*==============================================================================  *pheavy70 pheavy100 

		*** LOOPS START    
		
		foreach exp in pheavy90 {
		
		
		foreach CFR in  cum_death  {   
 
 		macro drop Ypre  Y* day_first day_exp mobility case case_lag1 case_sd4

		use "$dataout\Mex_covid_smoke_`exp'_`CFR'.dta", clear 
			
							
				summarize day_one
				display r(min)
				global day_first = r(min)
				
				summarize day_smoke_treated
				display r(min)
				global day_exp = r(min)
				
								
				display $day_first
				display $day_exp
				
				
					
				forvalue i = $day_first / $day_exp {
						global Ypre $Ypre  Y(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global mobility $mobility  mobility(`i')  
						}
						
						
				forvalue i = $day_first / $day_exp {
						global case $case  case(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global case_lag1 $case_lag1  case_lag1(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global case_sd4 $cases_sd4  case_sd4(`i')  
						}
				
				
				
				macro list		
				
				replace id=0 if treated==1
				

				tsset id t
				
			*$mobility $case $case_lag1 $case_sd4	
		
						
			synth Y $Ypre $mobility $case $case_lag1 $case_sd4, trunit(0) trperiod($day_exp )  figure   unitnames(adm2_pcode) keep("$results\TJ_res__test_`exp'_`CFR'") replace
				
				graph save "$results\figures\TJ__test_`exp'_`CFR.gph'", replace
		
		} 
		}
		
		