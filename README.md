# Wildfire smoke impacts on COVID-19 in border region

This is the code and data for the following manuscript
Title: The differential impact of wildfire smoke on COVID-19 cumulative deaths in the San Diego-Tijuana border region
Authors: Lara Schwarz, Rosana Aguilera, Javier Emmanuel Castillo Quiñones, L.C. Aguilera-Dodier, María Evarista Arellano García and Tarik Benmarhnia

## Data

COVID-19:
Mexican Secretary of Health Epidemiological Surveillance System for Viral Respiratory Diseases
Bases de datos covid 19 en méxico. 
https://datos.gob.mx/busca/dataset/informacion-referente-a-casos-covid-19-en-mexico
Información del Sistema de Vigilancia Epidemiológica de Enfermedades Respiratoria Viral.
-Mexico- 211013COVID19MEXICO.csv

United states CDC. 2020. Cdc covid data tracker.
https://covid.cdc.gov/covid-data-tracker/#datatracker-home
-United States- Covid_smoke_by_county

Smoke: 
NOAA hazard mapping smoke product: https://www.ospo.noaa.gov/Products/land/hms.html
Processed at the County/Municipality level
-Mexico- smk_intsct_Mex.csv
-United States- Covid_smoke_by_county.dta

Mobility:
Google Community Mobility Reports: https://www.google.com/covid19/mobility/
-Mexico-2020_MX_Region_Mobility_Report.csv
-Unites States- 2020_US_Region_Mobility_Report.csv

## Code
Smoke estimation
Mexico: Wildfire_smoke_estimation_Mexico

STATA synthetic control analysis
San Diego- Wildfire_smoke_covid_San_Diego.do
Tijuana- Wildfire_smoke_covid_Tijuana.do

R gsynth analysis
San Diego and Tijuana: wildfires_covid_gsynth.R
