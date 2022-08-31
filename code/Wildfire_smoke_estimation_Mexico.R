install.packages("rgdal")
library(tools)
library(sf)
library(lwgeom)
library(dplyr)
library(tidyr)
library(magrittr)
library(rgdal)

# read HMS files
shp <-list.files(path= "D:/DATA/HMS Smoke Plumes/2020")
s <- unique(sapply(shp,  file_path_sans_ext))

#s <- s[250:256]  # September 1-11, 2020: plumes for testing
#s

# read polygons
setwd("D:/Lara/Border/Data/Mexico_shapefile/shapefile")
##setwd("C:/Users/Rosana/Documents/UCSD-Scripps/R Files 2021/Mexico/mex_admbnda_govmex_20210618_shp")
munic <- st_read(dsn = ".", layer = "mex_admbnda_adm2_govmex_20210618")

st_crs(munic) # WGS 84 (in degrees lat/lon) --> transform to spatial reference in m (below)

municipality <- st_transform(munic, crs = 4269) # NAD83 (ESPG = 4269), unit = m

#municipality <- spTransform(munic, CRSobj = "+proj=longlat +datum=NAD83") # NAD83 (ESPG = 4269), unit = m
plot(st_geometry(municipality))

st_crs(municipality) #  LENGTHUNIT["metre",1]]]


length(unique(municipality$ADM2_ES)) # 2318
length(unique(municipality$ADM2_PCODE)) # 2457

# Calculate area of polygons (m2)
munic.area <- municipality %>% 
  mutate(munic_area = st_area(municipality)) %>%   # create new column with zip area
  dplyr::select(ADM2_PCODE, munic_area) %>%   # select columns of interest
  st_drop_geometry()

summary(munic.area) 



# Loop and intersect plume with municipalities

datalist = list() # create empty list to store results

for (i in 1:length(s)){
   
setwd("D:/DATA/HMS Smoke Plumes/2019")  # set working directory to folder where HMS downloaded files are stored
  
  ### setwd("C:/Users/Rosana/Documents/UCSD-Scripps/GIS/Fire/HMS/2020")
  
smoke <- st_read(dsn = ".", layer = s[i]) %>%  st_set_crs(st_crs(municipality)) %>%
  mutate(
    year = substr(s[i], 10, 13),
    month = substr(s[i], 14, 15),
    day = substr(s[i], 16, 17),
    date = paste0(year, month, day),
    density = factor(
      ifelse(
        Density %in% c(5, "5.000"),
        "light",
        ifelse(
          Density %in% c(27, "27.000") ,
          "heavy",
          ifelse(Density %in% c(16, "16.000"), "medium", "missing")
        )
      ),
      levels = c("light", "medium", "heavy", "missing")
    )
  )


any(is.na(st_dimension(smoke)))
any(is.na(st_is_valid(smoke)))
any(na.omit(st_is_valid(smoke)) == FALSE)

valid = st_is_valid(smoke, reason = TRUE)

smoke_valid<- st_make_valid(smoke)

#munic_valid <- sf::st_buffer(municipality, dist = 0)  ### DELETE THIS, REPLACED WITH LINE BELOW
munic_valid <- st_make_valid(municipality)

# intersect HMS smoke plumes and zip polygons and calculate area of intersection
intersect_pct <- st_intersection(munic_valid, smoke_valid) %>% 
  mutate(intersect_area = st_area(.)) %>%   # create new column with intersection area
  dplyr::select(ADM2_PCODE, date, Density, density, intersect_area) %>%   # select columns of interest
  st_drop_geometry()  

#selected maximum coverage on a given day for each of the three smoke density categories
intersect_coverage <- intersect_pct %>%
  group_by(ADM2_PCODE, density) %>%
  summarize(date = max(date), intsct_area = max(intersect_area))


# reshape data frame
munic.coverage <- pivot_wider(intersect_coverage, 
            id_cols = ADM2_PCODE,
            names_from = density,
            values_from = intsct_area)

# merge results with data of zip polygon area
munic_smk_coverage <- merge(munic.area, munic.coverage, by = "ADM2_PCODE", all.x = TRUE)

datalist[[i]] = munic_smk_coverage

} # end loop

###############################################
### Check crs and plot polygons overlapping ###
### This will take the last objects produced in the loop ###

st_crs(smoke_valid) # same crs as municipality
st_crs(munic_valid) 


plot(st_geometry(munic_valid))
plot(st_geometry(smoke_valid), add = TRUE, col = "gray")


# combine results from list

library(data.table)
df <- rbindlist(datalist, fill = TRUE)


# add dates
dates <- rep(sub('.*e([0-9]+)*','\\1', s), each = 2457)  # 1719 = number of zip codes

smk_intsct_mun <- cbind(dates, df)

# Calculate % smoke coverage
smk_intsct_mun$light_pct <- as.numeric((smk_intsct_mun$light / smk_intsct_mun$munic_area) * 100)

smk_intsct_mun$medium_pct <- as.numeric((smk_intsct_mun$medium / smk_intsct_mun$munic_area) * 100)

smk_intsct_mun$heavy_pct <- as.numeric((smk_intsct_mun$heavy / smk_intsct_mun$munic_area) * 100)

smk_intsct_mun[is.na(smk_intsct_mun)] <- 0   # change NAs to 0

summary(smk_intsct_mun)

# save output
 setwd("D:/Lara/Border/Data/smoke/Smoke_data")

 write.csv(smk_intsct_mun, "smk_intsct_mun_2020.csv", row.names = FALSE)

 
