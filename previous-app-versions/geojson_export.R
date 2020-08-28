library(sf)
library(cartography)
library(leaflet)
library(tidyverse)
library(withr)

USA <- st_read(dsn = './data/county data/cb_2018_us_county_500k.shp')

auction_data <- read.csv("./data/5G auction results/county_status-filtered.csv",
                         stringsAsFactors = FALSE)

#pad the numbers on GeoID/census ID & rename
auction_data$census_id = with_options(c(scipen = 999), str_pad(auction_data$census_id, 5, pad = "0"))
auction_data <- auction_data %>% rename("GEOID" = census_id)

states_st_5g <- left_join(USA, auction_data, by="GEOID")

plot(st_geometry(states_st_5g), col = NA, border = NA, bg = "#aadaff")

choroLayer(
  x = states_st_5g$, 
  var = "posted_price",
  method = "geom",
  nclass=5,
  col = carto.pal(pal1 = "sand.pal", n1 = 5),
  border = "white", 
  lwd = 0.5,
  legend.pos = "topright", 
  legend.title.txt = "Population Density\n(people per km2)",
  add = TRUE
) 

layoutLayer(title = "Population Distribution in Martinique", 
            sources = "Sources: Insee and IGN, 2018",
            author = paste0("cartography ", packageVersion("cartography")), 
            frame = FALSE, north = FALSE, tabtitle = TRUE, theme= "sand.pal") 
# north arrow
north(pos = "topleft")

st_write(obj = states_st_5g, "./data/auction_results.geojson")


# # create sf object from st 
# states_sf <- st_as_sf(USA)
# 
# 
# #left join
# states_sf_5g <- left_join(states_sf, auction_data, by="GEOID")
# states_sf_5g <- st_transform(states_sf_5g, 4326)  # reproject to 4326
