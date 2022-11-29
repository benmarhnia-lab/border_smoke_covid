*** Wildfire smoke and COVID-19 in the border region ***
*** United States data set *************************************
*** Version: October 31st, 2022 **********************************

*==============================================================================
* Setting working directories
*==============================================================================

//Lara's working directories	
	global datain "D:\Lara\Border\Data"                           
	global dataout "D:\Lara\Border\Data_prep"
	global results "D:\Lara\Border\results"
	
//GitHub working directories	
	global datain "D:\Lara\Border\Code\covid\Github\data"                      
	global dataout "D:\Lara\Border\Code\covid\Github\Data_prep"
	global results "D:\Lara\Border\Code\covid\Github\results"
					
	
	
	/* Data prep code from previous project
	
*==============================================================================
* Import the mortality data 
*==============================================================================

	* You can set the working directories in advance with global macros:
	
	//Anna's working directories
	global datain "C:\Users\annak\Dropbox\Projects\2020_San Diego\Wildfire smoke and COVID-19\Data"     
	global dataout "C:\Users\annak\Dropbox\Projects\2020_San Diego\Wildfire smoke and COVID-19\Data\Data_for_analysis"
	global results "C:\Users\annak\Dropbox\Projects\2020_San Diego\Wildfire smoke and COVID-19\Results"

	//Lara's working directories	
	global datain "F:\Lara\Projects\Wildfire smoke\Data"                                                 
	global dataout "F:\Lara\Projects\Wildfire smoke\Data_for_analysis"
	global results "F:\Lara\Projects\Wildfire smoke\Results"
				
	
	
	import delimited "$datain\covid\covid_deaths_usafacts.csv", clear encoding(UTF-8) 

		reshape long v, i(countyname state) j(day)  

		gen date= 21931 + day	
		gen date2= date
		format date2 %d
		 
		sort state countyname day
		 
		rename v total_d
		  
		by state countyname: gen death=total_d-total_d[_n-1]                    //daily covid deaths

		replace death=total_d if date==21936
		
		
		
		sum death if death < 0
		list state day countyfips date date2 total_d death if death < 0
		


	save "$datain\covid\Covid_deaths_by_county.dta", replace

*==============================================================================
* Import the case data 
*==============================================================================

	import delimited "$datain\covid\covid_confirmed_usafacts.csv", clear encoding(UTF-8) 

		reshape long v, i(countyname state) j(day)  

		gen date= 21931 + day
		gen date2= date
		format date2 %d
		 
		sort state countyname day
		 
		rename v total_cases
		 
		by state countyname: gen cases = total_cases-total_cases[_n-1]           //daily covid cases 

		replace cases=total_cases if date==21936
		
		
		sum cases if cases < 0
		list state day countyfips total_cases date date2 total_cases cases if cases < 0
		
		
		gen cases_neg=.
		replace cases_neg=1 if cases<0
		replace cases_neg=0 if cases>=0
		
		by state countyname: replace cases= cases[_n-1] if cases_neg==1
		by state countyname: replace cases= cases[_n-1] if cases_neg==1

		replace cases=. if cases_neg==1
			 
		by state countyname: gen cases_2wks = cases[_n-14]                       //daily covid cases lagged 2 weeks
		by state countyname: gen cases_avg7_14 = (cases[_n-14] +  ///              //rolling mean of daily covid cases (7 to 14 days earlier)
												  cases[_n-13] +  ///
												  cases[_n-12] +  ///
												  cases[_n-11] +  ///
												  cases[_n-10] +  ///
												  cases[_n-9 ] +  ///
												  cases[_n-8 ])/7 

	save "$datain\covid\Covid_cases_by_county.dta", replace


*==============================================================================
* Merge the covid deaths and hospitalization data 
*==============================================================================
	
	 use "$datain\covid\Covid_cases_by_county.dta", clear

		 replace countyname="Alexandria city" if countyname=="Alexandria City"
		 replace countyname="Broomfield County" if countyname=="Broomfield County and City"
		 replace countyname="Charlottesville city" if countyname=="Charlottesville City"
		 replace countyname="Chesapeake city" if countyname=="Chesapeake City"
		 replace countyname="Danville city" if countyname=="Danville City"
		 replace countyname="Fredericksburg city" if countyname=="Fredericksburg City"
		 replace countyname="Harrisonburg city" if countyname=="Harrisonburg City"
		 replace countyname="Lac qui Parle County" if countyname=="Lac Qui Parle County"
		 replace countyname="Manassas city" if countyname=="Manassas City"
		 replace countyname="Mathews County" if countyname=="Matthews County"
		 replace countyname="Norfolk city" if countyname=="Norfolk City"
		 replace countyname="Portsmouth city" if countyname=="Portsmouth City"
		 replace countyname="Richmond city" if countyname=="Richmond City"
		 replace countyname="Suffolk city" if countyname=="Suffolk City"
		 replace countyname="Virginia Beach city" if countyname=="Virginia Beach City"

		 merge 1:1 state countyname day using "$datain\covid\Covid_deaths_by_county.dta"
		 drop _merge
		 
	 save "$datain\covid\Covid_by_county.dta", replace

	 	 
*-------------------------Generate output measures (these are not used in this study) ------------------------------

		gen CFR_14dys=death/cases_2wks          		//daily deaths devided by diagnosed cases two weeks earlier
		
	
		sum CFR_14dys  if CFR_14dys<0
		list state day total_cases date2 cases total_cases cases death CFR_14dys if CFR_14dys < 0
		
		
		gen CFR_14dys_neg=.
		replace CFR_14dys_neg=1 if CFR_14dys<0
		replace CFR_14dys_neg=0 if CFR_14dys>=0
		replace CFR_14dys=. if CFR_14dys_neg==1      	
		
		gen CFR_same_day=death/cases                    //daily deaths devided by daily diagnosed cases
		gen CFR_same_day_neg=.
		replace CFR_same_day_neg=1 if CFR_same_day<0
		replace CFR_same_day_neg=0 if CFR_same_day>=0
		replace CFR_same_day=. if CFR_same_day_neg==1   //dropping negative ratios 

		gen CFR_7_14days=death/cases_avg7_14            //daily deaths devided by average daily diagnosed cases 7 to 14 days ago
		gen CFR_7_14days_neg=.
		replace CFR_7_14days_neg=1 if CFR_7_14days<0
		replace CFR_7_14days_neg=0 if CFR_7_14days>=0
		replace CFR_7_14days=. if CFR_7_14days_neg==1   //dropping negative ratios


	save "$datain\covid\Covid_by_county.dta", replace


	
*==============================================================================
* Prepare the smoke data (from R) 
*==============================================================================
	
	import delimited "$datain\Smoke_county_bin\smk_intsct_county_area_2020.csv", clear

		tostring dates, replace
		
		gen date2=date(dates, "YMD")
		gen date=date2
		format date %td
 
		rename geoid countyfips
		
		 save "$datain\Smoke\smoke_by_county", replace

		
		collapse date2, by( countyfips)
		replace date=22104
		
		save "$datain\Smoke\county_july8.dta", replace
		
		use "$datain\Smoke\smoke_by_county"
		
		append using "$datain\Smoke\county_july8.dta"

		sort countyfips date2
		
		by countyfips: replace medium_pct = (medium_pct[_n-1] + medium_pct[_n+1])/2 if medium_pct==.
		by countyfips: replace light_pct = (light_pct[_n-1] + light_pct[_n+1])/2 if light_pct==.
		by countyfips: replace heavy_pct = (heavy_pct[_n-1] + heavy_pct[_n+1])/2 if heavy_pct==.
		
		
		by countyfips: replace medium = (medium[_n-1] + medium[_n+1])/2 if medium==.
		by countyfips: replace light = (light[_n-1] + light[_n+1])/2 if light==.
		by countyfips: replace heavy = (heavy[_n-1] + heavy[_n+1])/2 if heavy==.


		replace date=date2 if date==.
  
   save "$datain\Smoke\smoke_by_county", replace

  *==============================================================================
* Merge the mobility data and save
*==============================================================================
	 
 import delimited "$datain\Mobility_data\Trips_by_Distance.csv" 
 keep if level=="County"
 
 gen date2=date( date, "YMD")
  drop if date2<21936  //restricting to same time period as other datasets Jan 22-Nov 10 2020
  drop if date2>22229
  
   rename date date3
   rename date2 date
   
   rename statepostalcode state

keep state countyname populationstayingathome populationnotstayingathome date
 
 
 save "$datain\Mobility_data\US_transportation_mobility.dta", replace
 


   
*==============================================================================
* Merge the health and smoke and mobility data and save
*==============================================================================
	
	use "$datain\covid\Covid_by_county.dta", clear

		drop if countyfips==0                        

		merge 1:1 countyfips date using "$datain\Smoke\smoke_by_county.dta"
		keep if _merge==3
		drop _merge
		
		merge 1:1 state countyname date using "F:\Lara\Projects\Wildfire smoke\Data\Mobility_data\US_transportation_mobility.dta"

		 drop if _merge==2
		 
		 drop _merge
		 
	save "$datain\Full_data\Covid_smoke_by_county.dta", replace
*/
				
*==============================================================================
* Data Prep: using dataset prepared for previous work 
* Schwarz, L., Dimitrova, A., Aguilera, R., Basu, R., Gershunov, A., & Benmarhnia, T. (2022). Smoke and COVID-19 case fatality ratios during California wildfires. Environmental Research Letters, 17(1), 014054.
*==============================================================================

use "D:\Lara\Border\Data\US_COVID_19\Covid_smoke_by_county.dta"

*==============================================================================
* Prepare the mobility data
*==============================================================================
	 
 import delimited "$datain\2020_US_Region_Mobility_Report.csv", clear

 drop if sub_region_1==""
 drop if sub_region_2==""
 
 drop  metro_area  place_id 
 
  rename date date2
  
   gen date=date(date2, "YMD")
   
   rename census_fips_code county_fips_code
   
   rename sub_region_1 state
     
	 * we chose residential mobility as the variable for this analysis but other mobility measures can be used 
   rename residential_percent_change_from_ mobility_residence
   *rename parks_percent_change_from_baseli mobility_parks
   *rename grocery_and_pharmacy_percent_cha mobility_grocery
   *rename transit_stations_percent_change_ mobility_transit
   *rename workplaces_percent_change_from_b mobility_work
   
   collapse (mean) mobility_residence, by(state date)
 
 ** interpolate missing mobility data
				
	mipolate mobility_residence date , by(state) nearest generate(mobility)
	
	*saving only variables used in later analysis
	keep mobility date date state
	
merge m:1 state using "D:\Lara\Border\Data\US_COVID_19\US_state_two_letter_codes.dta"

keep if _merge==3

drop _merge
 
 save  "$datain\Mobility_data_US.dta", replace

*==============================================================================
* Merging in the smoke and mobility data 
*==============================================================================

use "$datain\Covid_smoke_by_county.dta"

gen year=year(date)
keep if year==2020

gen county_fips_code = countyfips
merge 1:1 county_fips_code date using "$datain\US_smoke_by_county"
		
keep if _merge==3
		
drop _merge

gen res_state= state
 
merge m:1 res_state using "D:\Lara\Border\Data\US_COVID_19\US_state_two_letter_codes.dta"


drop _merge

drop state

 rename abbrev state

merge m:1 res_state date using "$datain\Mobility_data_US.dta", force

** There are missing days in mobility dataset from Jan-March 20202
** This won't be important for this analsysis as study period focuses on Aug-Sep 2020
		keep if _merge==3
		
		drop _merge
		
		
		 
	save "$dataout\US_covid_smoke_by_county_all.dta", replace		
		
*==============================================================================
* Prepare the data for analysis 
*============================================================================== 
	
	use "$dataout\US_covid_smoke_by_county_all.dta", clear
	
	
	
	** calculating moving averages
	
sort countyfips day
*interpolate missing case data
	mipolate cases date , by(county_fips_code) nearest generate(case)
	
	* created lagged case variables
	bysort countyfips: gen case_lag1 = case[_n - 1]

	gen week=week(date)
	bys countyfips : asrol case, stat(sd) window(week 4)
	
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



***** Loop that creates new variable for each smoke exposure that represents the first smoke and a binary variable for when the smoke started. For this specific analysis it will be the same for all exposure measures in the exposed County
foreach var in  pheavy70 pheavy90 pheavy100 {
sort county_fips_code date
by county_fips_code (time), sort: gen byte smoke_`var'_day1 = sum(`var') == 1  & sum(`var'[_n - 1]) == 0  

 gen first_smoke_`var'=.
 replace first_smoke_`var' = time if smoke_`var'_day1==1
}
*****
** Restricting to study period (August 1st to September 30th, 2020)
 drop if time<183 //Restricting to start on July 1st 
drop if time>274 //Restricting to end September 30th
 
gen cum_death =total_d

* removing any County that had no deaths during the entire study period
 bysort county_fips_code : egen deaths_tot = max( cum_death)
 drop if deaths_tot==0
 
** problem with cases variables in one county_fips_code- remove this county
*drop if countyfips==28021
	save "$dataout\US_covid_smoke_by_county_mort_all.dta", replace
		
		
*** LOOPS START
				
foreach exp in  pheavy70 pheavy90 pheavy100 {  
		
	foreach CFR in cum_death  {    
 
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
				
				* code added Nov 7
				
				rename Y Y_mis
				
				*interpolate missing  Y data
  
  	mipolate Y_mis date , by(county_fips_code) nearest generate(Y)
	
				
				
				
				*bysort county_fips_code: replace Y= (Y[_n-1] + Y[_n+1])/2 if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n-1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n-1] ) if missing(Y) 

				
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
				*bysort county_fips_code: replace Y= (Y[_n+1] ) if missing(Y) 
	 			
				
			*	gen miss=.                                                  //remove donor counties with missing observations 
				*replace miss=1 if missing(Y) 
				*egen miss_by_mun=sum(miss), by(county_fips_code)
				 // Delete any municipalities that have more than 5 days missing
				
	
				
			 // drop municipality with missing information

				* drop miss miss_by_mun if Y!=0
				gen miss=.   
				replace miss=1 if missing(Y) 
				egen miss_by_mun=sum(miss), by(county_fips_code)
				drop if miss_by_mun>0
				
						
				//remove donor counties with missing mobility data
				* focusing on residential mobility
				*gen mobility= mobility_residence
				*replace miss=1 if missing(mobility) 
				*egen miss_by_county=mean(miss), by(county_fips_code)
				*drop if miss_by_county==1 
				*drop miss miss_by_county
				
				
				/*
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
				
		*/
				gen t=time                                                         
				
				sort county_fips_code time
	 
				gen treated=.
				replace treated=1 if county_fips_code==6073
				replace treated=0 if county_fips_code!=6073		

				egen avg_smoke=mean(`exp'), by(county_fips_code)              //remove donor counties which received more that 1% smoke and all CA counties
				
				drop if avg_smoke>0 & treated!=1     
				drop if res_state=="CA" & treated!=1 
				  

				egen id = group(county_fips_code)	
				
				egen day_one= min(t)  
						
				
	
				
				save "$dataout\US_covid_smoke_`exp'_`CFR'.dta", replace 
	
	
		}	
			
	  }
				
	
*==============================================================================
* Analysis 
*============================================================================== 

		*** LOOPS START    
		
		foreach exp in pheavy90 pheavy70 pheavy100 {
		
		
		foreach CFR in cum_death  {   
 
 		macro drop Ypre week_first week_exp  Y* day_first day_exp

		use "$dataout\US_covid_smoke_`exp'_`CFR'.dta", clear 
			
			
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
						global case $case  case(`i')  
						}
						
				forvalue i = $day_first / $day_exp {
						global case_lag1 $case_lag1  case_lag1(`i')  
						}
				
				forvalue i = $day_first / $day_exp {
						global case_sd4 $case_sd4  case_sd4(`i')  
						}	
						
				forvalue i = $day_first / $day_exp {
						global mobility $mobility  mobility(`i')  
						}
						
				
			
				macro list		
				
				replace id=0 if treated==1
					

				tsset id t
				
			
						
				synth Y $Ypre  $mobility $case $case_lag1 $case_sd4,  trunit(0) trperiod($day_exp) pvals1s  gen_vars unitnames(countstate) figure  keep("$results\SD_res_`exp'_`CFR'") replace   
				 
				graph save "$results\figures\SD_mort_`exp'_`CFR'.gph", replace
				
		}	
		}
				