*** Wildfire smoke and COVID-19 in the border region ***
*** Mexico data set *************************************
*** Version: June 6th, 2022 **********************************

*==============================================================================
* Setting working directories
*==============================================================================

//Lara's working directories	
	global datain "D:\Lara\Border\Data"                           
	global dataout "D:\Lara\Border\Data_prep"
	global results "D:\Lara\Border\results"
				
*==============================================================================
* Data Prep
*==============================================================================

 import delimited "$datain\Mexico_COVID_19\211013COVID19MEXICO.csv", encoding(UTF-8) 

save "$datain\Mexico_COVID_19\Mexico_covid.dta", replace

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

* generate variable for positive cases from clinics
gen case=.
replace case=0 if clinic==0 & hosp==0
replace case=1 if clinic==1|hosp==1

* mortality information
gen death=.
replace death=0 if fecha_def=="9999-99-99"|fecha_def==""
replace death=1 if fecha_def!="9999-99-99"

gen date=date(fecha_ingreso, "YMD")

save "$datain\Mexico_COVID_19\Mexico_covid_data.dta", replace

save "$datain\Mexico_COVID_19\Mex_covid_deaths.dta", replace

** using death data on date of death

keep  entidad_res municipio_res fecha_def death

keep if death==1
gen date=date(fecha_def, "YMD")


collapse (sum) death, by(date municipio_res entidad_res)
save "$datain\Mexico_COVID_19\Mex_covid_deaths.dta", replace

use "$datain\Mexico_COVID_19\Mexico_covid_data.dta"

** make dataset for total daily count hospitalizations and cases by entidad
collapse (sum) hosp case death, by(date municipio_res entidad_res)

** make sure there are no missing dates for municipalities that have missing data
save "$datain\Mexico_COVID_19\Mexico_covid_data.dta", replace

use "$datain\Mexico_COVID_19\Mexico_covid_data.dta" 
save "$datain\Mexico_COVID_19\Mex_empty_data.dta", replace

keep  municipio_res entidad_res
duplicates drop  municipio_res entidad_res, force
expand 594
bysort municipio_res entidad_res:gen date=21971+_n
sort municipio_res entidad_res date
merge 1:1 entidad_res municipio_res date using "$datain\Mexico_COVID_19\Mexico_covid_data.dta"

drop if _merge==2
drop _merge

** merging death data back in 

drop death 
merge 1:1 entidad_res municipio_res date using "$datain\Mexico_COVID_19\Mex_covid_deaths.dta"

drop _merge

**generate cumulative deaths
 bysort  municipio_res entidad_res (date): gen cum_death =sum(death)
  
  ** interpolate missing case datain
  mipolate case date , by(entidad_res municipio_res) nearest generate(cases)

 * making stata formatted date
 gen year=year( date)
 gen month=month(date)
 
 ** save stata file
 save "$dataout\Mexico_covid_case_mort.dta", replace
 
*==============================================================================
* Prepare the smoke data (from R) 
*==============================================================================

import delimited "$datain\smoke\Smoke_data\smk_intsct_Mex.csv"

save "$datain\smoke\Smoke_data\Mex_smoke_by_munic", replace

*fixing issue with July 8th data
collapse date, by(adm2_pcode)
		replace date=20200708
		
		save "$datain\Smoke\Mex_mun_july8.dta", replace
		
		use "$datain\smoke\Smoke_data\Mex_smoke_by_munic"		
		append using "$datain\Smoke\Mex_mun_july8.dta"
		
		tostring dates, generate(date)
 
		gen date2=date( date, "YMD")
		sort adm2_pcode date2
		
bysort adm2_pcode: replace light_pct= ((light_pct[_n-1] +light_pct[_n+1])/2 ) if light_pct==.
bysort adm2_pcode: replace medium_pct= ((medium_pct[_n-1] +medium_pct[_n+1])/2) if medium_pct==.
bysort adm2_pcode: replace heavy_pct= ((heavy_pct[_n-1] +heavy_pct[_n+1])/2) if heavy_pct==.


 drop date
 gen date=date2
 
		format date %td
		drop if date2==.
		
		
		 save "$datain\smoke\Smoke_data\Mex_smoke_by_munic", replace

  *==============================================================================
* Process the mobility data and save
*==============================================================================
	 
 import delimited "$datain\Mobility_data\2020_MX_Region_Mobility_Report.csv", clear
 
  rename parks_percent_change_from_baseli mobility_parks
   rename grocery_and_pharmacy_percent_cha mobility_grocery
   rename transit_stations_percent_change_ mobility_transit
   rename workplaces_percent_change_from_b mobility_work
   rename residential_percent_change_from_ mobility_residence

 drop if sub_region_1==""
 
 drop sub_region_2 metro_area census_fips_code
 
  rename date date2
  
   gen date=date(date2, "YMD")
 
 save  "$datain\Mobility_data\Mobility_data_Mex.dta", replace

   
*==============================================================================
* Merge the health and smoke and mobility data and save
*==============================================================================
	
	use   "$dataout\Mexico_covid_case_mort.dta", clear


	gen adm2_pcode=""
	
	replace adm2_pcode="MX"+string(entidad_res,"%02.0f")+ string(municipio_res ,"%03.0f")
	
		bysort adm2_pcode: egen sum_case_hosp_rate=mean( case_hosp_rate)
		
		drop if sum_case_hosp_rate==0
		 drop if sum_case_hosp_rate==.
		 gen date2=date
	
	keep if year==2020
	
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


		merge 1:1 adm2_pcode date using "$datain\smoke\Smoke_data\Mex_smoke_by_munic.dta"
		
		
		keep if _merge==3
		
		
		drop _merge
		
		merge m:1 iso_3166_2_code date using "$datain\Mobility_data\Mobility_data_Mex.dta", force

		keep if _merge==3
		
		drop _merge
		
		 
	save "$dataout\Mex_covid_smoke_by_munic.dta", replace
	

*==============================================================================
* Prepare the data for analysis 
*============================================================================== 
	
	use "$dataout\Mex_covid_smoke_by_munic.dta", clear
	
		
sort adm2_pcode date
bysort adm2_pcode: gen case_lag1 = cases[_n - 1]

gen week=week(date)

	
	bys adm2_pcode : asrol cases, stat(sd) window(week 4)
	
	gen time = date-21914
	

	gen p90=0
	replace p90=1 if light_pct>90 | medium_pct>90 | heavy_pct>90
	
	gen pheavy90=0
	replace pheavy90=1 if heavy_pct>90
	
	
*****
foreach var in p90 pheavy90  {
sort adm2_pcode date2
by adm2_pcode (time), sort: gen byte smoke_`var'_day1 = sum(`var') == 1  & sum(`var'[_n - 1]) == 0  

 gen first_smoke_`var'=.
 replace first_smoke_`var' = time if smoke_`var'_day1==1
 

}
 
*****
		
	save "$dataout\Mex_covid_smoke_by_munic_all.dta", replace			
  *==============================================================================
* Analysis
*============================================================================== 
		
				
	foreach exp in pheavy90   {  
		
		foreach CFR in  cum_death  {    
 
			use "$dataout\Mex_covid_smoke_by_munic_all.dta", clear
	
				sort time
				gen day_smoke_treated = first_smoke_`exp'  if  adm2_pcode=="MX02004" &  smoke_`exp'_day1==1 //change based on percentile wanted
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				gsort -time 
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				sort adm2_pcode time

				gen X=.
				replace X=0 if time<day_smoke_treated
				replace X=1 if time>=day_smoke_treated
	 
				gen Y= `CFR'
				
				rename Y Y_mis
				
				** interpolate missing case Y data
  
  	mipolate Y_mis date , by(entidad_res municipio_res) nearest generate(Y)
	
	
				** interpolate missing mobility datain
				
	mipolate mobility_residence date , by(entidad_res municipio_res) nearest generate(mobility)

				

	 			drop if adm2_pcode=="MX02999" // drop municipality with missing information

		
				gen t=time                                                         
				
				sort adm2_pcode time
	 
				gen treated=.
				replace treated=1 if adm2_pcode=="MX02004"
				replace treated=0 if adm2_pcode!="MX02004"		

				egen avg_smoke=mean(`exp'), by(adm2_pcode)              
				
				//remove donor counties which had smoke exposure
				drop if avg_smoke>0 & treated!=1   
				
			   
				egen id = group(adm2_pcode)	
				
drop if time<214 //Restricting to start on July 1st 
drop if time>305 //Restricting to end Nov 1st				
				egen day_one= min(t)  		
				
				save "$dataout\Mex_covid_smoke_`exp'_`CFR'.dta", replace 
	
	
			}	
			
		  }
				
			
			
			
  		
		
		
*==============================================================================
* Analysis 
*============================================================================== 

		*** LOOPS START    
		
		foreach exp in pheavy90 {
		
		
		foreach CFR in  cum_death  {   
 
 		macro drop Ypre week_first week_exp  Y* day_first day_exp mobility cases cases_lag1

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
						global cases $cases  cases(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global case_lag1 $case_lag1  case_lag1(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global cases_sd4 $cases_sd4  cases_sd4(`i')  
						}
				
				
				
				macro list		
				
				replace id=0 if treated==1
				

				tsset id t
				
				
		
						
			synth Y $mobility $cases $cases_lag1 $cases_sd4, trunit(0) trperiod($day_exp )  figure   unitnames(adm2_pcode) keep("$results\synth_runner\TJ_res_`exp'_`CFR'") replace
				
				graph save "$results\figures_gph\TJ_`exp'_`CFR.gph", replace
		
		} 
		}
		
		