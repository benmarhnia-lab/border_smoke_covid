#------------------------------------------------------------------------------#
#------------------Wildfire smoke and COVID in border--------------------------#   
#-------------------------R code-----------------------------------------------#
#------------------------------Date: 11/21/22-------------------------------------#
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
library(panelView)
library(devtools)
library(Synth)
#-------------------------------------Data Import------------------------------#
Mex_covid_smoke_pheavy30_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/Mex_covid_smoke_pheavy30_cum_death.dta")
Mex_covid_smoke_pheavy90_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/Mex_covid_smoke_pheavy90_cum_death.dta")
Mex_covid_smoke_pheavy70_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/Mex_covid_smoke_pheavy70_cum_death.dta")
Mex_covid_smoke_pheavy100_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/Mex_covid_smoke_pheavy100_cum_death.dta")


#df<-Mex_covid_smoke_pheavy90_cum_death
#df<-Mex_covid_smoke_pheavy70_cum_death
df<-Mex_covid_smoke_pheavy100_cum_death



US_covid_smoke_pheavy90_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/US_covid_smoke_pheavy90_cum_death.dta")
US_covid_smoke_pheavy100_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/US_covid_smoke_pheavy100_cum_death.dta")
US_covid_smoke_pheavy70_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/US_covid_smoke_pheavy70_cum_death.dta")
#US_covid_smoke_pheavy30_cum_death <- read_dta("D:/Lara/Border/Code/covid/Github/Data_prep/US_covid_smoke_pheavy30_cum_death.dta")


View(US_covid_smoke_pheavy90_cum_death)

df_us<-US_covid_smoke_pheavy90_cum_death
#df_us<-US_covid_smoke_pheavy100_cum_death
#df_us<-US_covid_smoke_pheavy70_cum_death


#---------------------------------Generalized synthetic control-Mexico------------------------------
## keep only variables that are needed
set.seed(1234)
df2 <- df %>%
  select(X, t, Y, treated, id, mobility, case, case_sd4, case_lag1, adm2_pcode, death)

### create new exposure indicator
### 0 for all weeks prior to fire week and 1 only if exposed and during fire week

df2$exp_daily <- ifelse(df2$treated==1& df2$t>=251,1,0)


### check missingness
missing <- df2[!complete.cases(df2),]
### exclude those with missing
df2 <- df2[complete.cases(df2),]
### check number of unique municipalities
length(unique(df2$id))

### factor id
df2$id <- as.factor(df2$id)

df2$adm2_pcode <- as.factor(df2$adm2_pcode)


gsynth.out_TJ <- gsynth(Y ~ exp_daily + mobility +case +case_sd4 + case_lag1 , data = df2, index = c("adm2_pcode","t"), 
                        nboots = 500, inference="parametric",  se = TRUE, parallel = TRUE )



### treated average and estimated counterfactual average outcomes
plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="Cumulative mortality", xlab = "Day", ylab="Cum. Mortality")


##for 70% coverage
#TJ_plot70<-plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="TJ: 70% Smoke", xlab = "Day", ylab="Cumulative mortality")
##for 90% coverage
#TJ_plot90<-plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="TJ: 90% Smoke", xlab = "Day", ylab="Cumulative mortality")
##for 100% coverage
TJ_plot100<-plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="TJ: 100% Smoke", xlab = "Day", ylab="Cumulative mortality")

# TJ_control_weights<-gsynth.out_TJ$wgt.implied 
# 
# TJ_control_weights<-as.data.frame(TJ_control_weights)
# TJ_control_weights$adm2_pcode<-rownames(TJ_control_weights)
# 
# 
# TJ_treated<-gsynth.out_TJ$id.tr 
# TJ_control<-gsynth.out_TJ$id.co
# 
# gsynth.out_TJ$index
# gsynth.out_TJ$I.tr

  #---------------------------------Generalized synthetic control-US------------------------------
  ## keep only variables that are needed
  
  df_us2 <- df_us %>%
    select(X, t, Y, treated, id, mobility, case_sd4, case, case_lag1, death)
  
  
  
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
  
  #panelView(Y ~ exp_daily, data = df_us2, index = c("id","t"), pre.post = TRUE)
  
  ### implement generalized synthetic control
  #foCV = TRUE, r = c(0,5), se = TRUE,, cores = 4
  
  gsynth.out_SD <- gsynth(Y ~ exp_daily +case+ mobility +case_sd4 + case_lag1 , data = df_us2, index = c("id","t"), 
                       nboots = 500, inference="parametric",  se = TRUE, parallel = TRUE)
  
  
 
### gaps plot - difference between treated and counterfactual SD_plot <-
SD_plot2 <-plot(gsynth.out_SD, type = "gap" , xlab = "Time to relative treatment", raw = "all", ylab="Difference Between Treated and Counterfactual", main="San Diego", legendOff = TRUE)

#plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="cum. mortality", xlab = "Day", ylab="cumulative")

##for 70% coverage
#SD_plot70<-plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="SD: 70% Smoke", xlab = "Day", ylab="Cumulative. Mortality")
##for 90% coverage
SD_plot90<-plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="SD: 90% Smoke", xlab = "Day", ylab="Cumulative mortality")
##for 100% coverage
#SD_plot100<-plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="SD: 100% Smoke", xlab = "Day", ylab="Cumulative mortality")

#---------------------------------Plotting results and combining------------------------------




## getting weights tables

SD_control_weights<-gsynth.out_SD$wgt.implied 
 TJ_control_weights<-gsynth.out_TJ$wgt.implied 

  ### treated average and estimated counterfactual average outcomes SD_plot2<-
 SD_plot1 <- plot(gsynth.out_SD, type = "counterfactual", raw = "none", main="", xlab = "Day", ylab="Cum. Mortality")

 ### treated average and estimated counterfactual average outcomes SD_plot2<-
 TJ_plot1 <- plot(gsynth.out_TJ, type = "counterfactual", raw = "none", main="", xlab = "Day", ylab="Cum. Mortality")

 ## TJ figure
 ### gaps plot - difference between treated and counterfactual SD_plot <-
 TJ_plot2 <-plot(gsynth.out_TJ, type = "gap" , xlab = "Time to relative treatment", raw = "all", ylab="Difference Between Treated and Counterfactual", main="Tijuana", legendOff = TRUE)
 
 #For combining plots later
 TJ_plot2<- TJ_plot2+theme(axis.title.x=element_blank(),
                           axis.title.y=element_blank())
 
# for combining plots later
SD_plot2<- SD_plot2+theme(axis.title.x=element_blank(),
                          axis.title.y=element_blank())

#combining plots for SD & TJ with confidence intervals

gsynth_TJ_SD<-ggarrange(SD_plot2, TJ_plot2, 
                      ncol = 2)

annotate_figure(gsynth_TJ_SD, left = textGrob("Difference between treated and counterfactual", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("days relative to start of wildfire smoke", gp = gpar(cex = 1.3)))
 

## combining plots with different percentile smoke exposure


TJ_SD_smoke_perc<-ggarrange(TJ_plot70, TJ_plot90, TJ_plot100, SD_plot70, SD_plot90, SD_plot100,
                        ncol = 3, nrow=2)
