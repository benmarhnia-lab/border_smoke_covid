*** Wildfire smoke and COVID-19 in the border region ***
*** United States data set *************************************
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

use "D:\Lara\Border\Data\US_COVID_19\Covid_smoke_by_county.dta"

*==============================================================================
* Prepare the mobility data
*==============================================================================
	 
 import delimited "$datain\Mobility_data\2020_US_Region_Mobility_Report.csv", clear

 drop if sub_region_1==""
  drop if sub_region_2==""
 
 drop  metro_area  place_id 
 
  rename date date2
  
   gen date=date(date2, "YMD")
   
   rename census_fips_code county_fips_code
   
   rename sub_region_1 state
   
   rename parks_percent_change_from_baseli mobility_parks
   rename grocery_and_pharmacy_percent_cha mobility_grocery
   rename transit_stations_percent_change_ mobility_transit
   rename workplaces_percent_change_from_b mobility_work
   rename residential_percent_change_from_ mobility_residence
   
   collapse (mean) mobility_parks mobility_grocery mobility_transit mobility_work mobility_residence, by(state date)
   
   
merge m:1 state using "D:\Lara\Border\Data\US_COVID_19\US_state_two_letter_codes.dta"

keep if _merge==3

drop _merge
 
 save  "$datain\Mobility_data\Mobility_data_US.dta", replace

*==============================================================================
* Merging in the smoke and mobility data 
*==============================================================================

use "D:\Lara\Border\Data\US_COVID_19\Covid_smoke_by_county.dta"

gen year=year(date)
keep if year==2020


gen county_fips_code = countyfips
merge 1:1 county_fips_code date using "$datain\smoke\Smoke_data\US_smoke_by_county"
		
keep if _merge==3
		
drop _merge


save "$datain\US_COVID_19\Data_jan_2022\COVID_US_mortality.dta", replace


gen res_state= state
 
merge m:1 res_state using "D:\Lara\Border\Data\US_COVID_19\US_state_two_letter_codes.dta"

 ** This excludes Guam, Puerto Rico and Northern Mariana Islands
keep if _merge==3

drop _merge

drop state

 rename abbrev state

		merge m:1 res_state date using "$datain\Mobility_data\Mobility_data_US.dta", force

		keep if _merge==3
		
		
		drop _merge
		 
	save "$dataout\US_covid_smoke_by_county_mort.dta", replace		
		
*==============================================================================
* Prepare the data for analysis 
*============================================================================== 
	
	use "$dataout\US_covid_smoke_by_county_mort.dta", clear
	
	** calculating moving averages
	
sort countyfips day
bysort countyfips: gen cases_lag1 = cases[_n - 1]

	
	bys countyfips : asrol cases, stat(sd) window(week 4)
	
	gen time = date-21914
	drop if time<214 //Restricting to start on July 1st 
	drop if time>305 //Restricting to end Nov 1st 
	
	
	gen p90=0
	replace p90=1 if light_pct>90 | medium_pct>90 | heavy_pct>90
	
	gen pheavy90=0
	replace pheavy90=1 if heavy_pct>90
	
	
*****
foreach var in  p90 pheavy90  {
sort county_fips_code date
by county_fips_code (time), sort: gen byte smoke_`var'_day1 = sum(`var') == 1  & sum(`var'[_n - 1]) == 0  

 gen first_smoke_`var'=.
 replace first_smoke_`var' = time if smoke_`var'_day1==1
}
*****
** problem with cases variables in one county_fips_code- remove this county
drop if countyfips==28021
	save "$dataout\US_covid_smoke_by_county_mort_all.dta", replace
		
		
*** LOOPS START
				
foreach exp in pheavy90  {  
		
	foreach CFR in total_d  {    
 
			use "$dataout\US_covid_smoke_by_county_mort_all.dta", clear
	
				sort time
				gen day_smoke_treated = first_smoke_`exp'  if   county_fips_code== 6073 &  smoke_`exp'_day1==1 
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				gsort -time 
				replace day_smoke_treated = day_smoke_treated[_n-1] if missing(day_smoke_treated)
				sort county_fips_code time

				gen X=.
				replace X=0 if time<day_smoke_treated
				replace X=1 if time>=day_smoke_treated
	 
				gen Y= `CFR'
				
				bysort county_fips_code: replace Y= (Y[_n-1] + Y[_n+1])/2 if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n-1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n-1] ) if missing(Y) 

				
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
	 			
				
				gen miss=.                                                  //remove donor counties with missing observations 
				replace miss=1 if missing(Y) 
				egen miss_by_mun=sum(miss), by(county_fips_code)
				drop if miss_by_mun>0 // Delete any municipalities that have more than 5 days missing
				
	
				
			 // drop municipality with missing information

				 drop miss miss_by_mun
				gen miss=.   
				replace miss=1 if missing(Y) 
				egen miss_by_mun=sum(miss) if Y!=0, by(county_fips_code)
				
				
						
				//remove donor counties with missing mobility data
				* focusing on residential mobility
				gen mobility= mobility_residence
				replace miss=1 if missing(mobility) 
				egen miss_by_county=mean(miss), by(county_fips_code)
				drop if miss_by_county==1 
				drop miss miss_by_county
				
				
				
				gen miss=.
			
				replace miss=1 if missing(cases) 
				bysort county_fips_code: replace cases= (cases[_n-1] + cases[_n+1])/2 if miss==1
				
				drop miss
				gen miss=.
				
				replace miss=1 if missing(cases_lag1) 
				bysort county_fips_code: replace cases_lag1= (cases_lag1[_n-1] + cases_lag1[_n+1])/2 if miss==1
				
				drop miss
				gen miss=.
				
				replace miss=1 if missing(cases_sd4) 
				bysort county_fips_code: replace cases_sd4= (cases_sd4[_n-1] + cases_sd4[_n+1])/2 if miss==1
				
		
				gen t=time                                                         
				
				sort county_fips_code time
	 
				gen treated=.
				replace treated=1 if county_fips_code==6073
				replace treated=0 if county_fips_code!=6073		

				egen avg_smoke=mean(`exp'), by(county_fips_code)              //remove donor counties which received more that 1% smoke and all CA counties
				
				drop if avg_smoke>0.01 & treated!=1     
				drop if res_state=="CA" & treated!=1 
				  

				egen id = group(county_fips_code)	
				
				egen day_one= min(t)  
						
				
	
				
				save "$dataout\US_covid_smoke_by_county_mort_all_`exp'_`CFR'.dta", replace 
	
	
		}	
			
	  }
				
			

		
		
*==============================================================================
* Analysis 
*============================================================================== 

		*** LOOPS START    
		
		foreach exp in pheavy90 {
		
		
		foreach CFR in total_d  {   
 
 		macro drop Ypre week_first week_exp  Y* day_first day_exp

		use "$dataout\US_covid_smoke_by_county_mort_all_`exp'_`CFR'.dta", clear 
			
			
			replace countyname = subinstr(countyname, " ", "", .)
			gen countstate= countyname+ res_state

			replace countstate = subinstr(countstate,"County", "", .)
				replace countstate = subinstr(countstate,".", "", .)
				replace countstate = subinstr(countstate,"'", "", .)
							
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
						global cases $cases  cases(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global cases_lag1 $cases_lag1  cases_lag1(`i')  
						}
				
				forvalue i = $day_first / $day_exp {
						global cases_sd4 $cases_sd4  cases_sd4(`i')  
						}	
						
				forvalue i = $day_first / $day_exp {
						global mobility $mobility  mobility(`i')  
						}
						
				
			
				macro list		
				
				replace id=0 if treated==1
					

				tsset id t
				
			
						
				synth Y  $mobility $cases $cases_lag1 $cases_sd4,  trunit(0) trperiod($day_exp) pvals1s  gen_vars unitnames(countstate) figure  keep("$results\synth_runner\SD_res_mort_`exp'_`CFR'") replace   
				 
				graph save "$results\figures_gph\SD_mort_`exp'_`CFR'.gph", replace
				
		}
		
		}
				