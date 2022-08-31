#------------------------------------------------------------------------------#
#------------------Wildfire smoke and COVID in border--------------------------#   
#-------------------------R code-----------------------------------------------#
#------------------------------Date:6/6/22-------------------------------------#
#-----------------------------Lara Schwarz-------------------------------------#
#------------------------------------------------------------------------------#

#------------------------------------Check and set the directory--------------------#
getwd()
setwd("D:/Lara/Border/Data_prep")

#-------------------------------------Installing packages----------------------#
library(haven)
library(gsynth)
library(ggplot2)
library(dplyr)
library(ggpubr)

#-------------------------------------Data Import------------------------------#

Mex_covid_smoke_pheavy90_cum_death <- read_dta("D:/Lara/Border/Data_prep/Mex_covid_smoke_pheavy90_cum_death.dta")
View(Mex_covid_smoke_pheavy90_cum_death)
df<-Mex_covid_smoke_pheavy90_cum_death

US_covid_smoke_by_county_mort_all_pheavy90_total_d <- read_dta("US_covid_smoke_by_county_mort_all_pheavy90_total_d.dta")
View(US_covid_smoke_by_county_mort_all_pheavy90_total_d)

df_us<-US_covid_smoke_by_county_mort_all_pheavy90_total_d


#---------------------------------Generalized synthetic control-Mexico------------------------------
## keep only variables that are needed

df2 <- df %>%
  select(X, t, Y, treated, id, mobility, cases, cases_sd4, case_lag1)




  ### create new exposure indicator
  ### 0 for all weeks prior to fire week and 1 only if exposed and during fire week
  
  df2$exp_daily <- ifelse(df2$treated==1& df2$t>=251,1,0)
  
  
  ### check missingness
  missing <- df2[!complete.cases(df2),]
  ### exclude those with missing
  #df2 <- df[complete.cases(df),]
  ### check number of unique zip codes
  length(unique(df2$id))
  ### factor zip id
  df2$id <- as.factor(df2$id)
  
  panelView(Y ~ exp_daily, data = df2, index = c("id","t"), pre.post = TRUE)
  
  ### implement generalized synthetic control
  #foCV = TRUE, r = c(0,5), se = TRUE,, cores = 4
  
  gsynth.out_TJ <- gsynth(Y ~ exp_daily + mobility +cases +cases_sd4 + case_lag1 , data = df2, index = c("id","t"), 
                       nboots = 500, inference="parametric",  se = TRUE, parallel = TRUE)
  
  
  
  ### gaps plot - difference between treated and counterfactual
  plot(gsynth.out_TJ, type = "gap" , xlab = "Day", ylab="Difference Between Treated and Counterfactual")
  

  ### treated average and estimated counterfactual average outcomes
  plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="", xlab = "Day", ylab="Cum. Mortality")

  #---------------------------------Generalized synthetic control-US------------------------------
  ## keep only variables that are needed
  
  df_us2 <- df_us %>%
    select(X, t, Y, treated, id, mobility, cases_sd4, cases, cases_lag1)
  
  
  
  
  ### create new exposure indicator
  ### 0 for all weeks prior to fire week and 1 only if exposed and during fire week
  
  df_us2$exp_daily <- ifelse(df_us2$treated==1& df_us2$t>=251,1,0)
  
  
  ### check missingness
  missing <- df_us2[!complete.cases(df_us2),]
  ### exclude those with missing
  #df2 <- df[complete.cases(df),]
  ### check number of unique zip codes
  length(unique(df_us2$id))
  ### factor zip id
  df_us2$id <- as.factor(df_us2$id)
  
  panelView(Y ~ exp_daily, data = df_us2, index = c("id","t"), pre.post = TRUE)
  
  ### implement generalized synthetic control
  #foCV = TRUE, r = c(0,5), se = TRUE,, cores = 4
  
  gsynth.out_SD <- gsynth(Y ~ exp_daily +cases+ mobility +cases_sd4 + cases_lag1 , data = df_us2, index = c("id","t"), 
                       nboots = 500, inference="parametric",  se = TRUE, parallel = TRUE)
 
    ### gaps plot - difference between treated and counterfactual SD_plot <-
SD_plot2 <-plot(gsynth.out_SD, type = "gap" , xlab = "Time to relative treatment", raw = "all", ylab="Difference Between Treated and Counterfactual", main="", legendOff = TRUE)
  



  ### treated average and estimated counterfactual average outcomes SD_plot2<-
 SD_plot1 <- plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="", xlab = "Day", ylab="Cum. Mortality")
SD_plot1_ed<-SD_plot1 + theme(
  legend.position = c(.95, .1),
  legend.justification = c("right", "top"),
  legend.box.just = "right",
  legend.margin = margin(6, 6, 6, 6)
)
  
 SD<-ggarrange(SD_plot1_ed, SD_plot2, 
           ncol = 2)
 
 annotate_figure(SD, top=text_grob("San Diego", face = "bold", size = 14))
 
 
 ## TJ figure
 ### gaps plot - difference between treated and counterfactual SD_plot <-
 TJ_plot2 <-plot(gsynth.out_TJ, type = "gap" , xlab = "Time to relative treatment", raw = "all", ylab="Difference Between Treated and Counterfactual", main="", legendOff = TRUE)
 
 
 
 
 ### treated average and estimated counterfactual average outcomes SD_plot2<-
 TJ_plot1 <- plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="", xlab = "Day", ylab="Cum. Mortality")
 TJ_plot1_ed<-TJ_plot1 + theme(
   legend.position = c(.95, .1),
   legend.justification = c("right", "top"),
   legend.box.just = "right",
   legend.margin = margin(6, 6, 6, 6)
 )
 
 TJ<-ggarrange(TJ_plot1_ed, TJ_plot2, 
               ncol = 2)
 
 annotate_figure(TJ, top=text_grob("Tijuana", face = "bold", size = 14))
 