options(stringsAsFactors = FALSE)

# pkgs
library(shiny)
library(leaflet)
library(tidyverse)
library(sf)
library(withr)
library(readr)

USA <- st_read(dsn = './data/county data/cb_2018_us_county_500k.shp')

auction_data <- read.csv("./data/5G auction results/county_status-filtered.csv",
                         stringsAsFactors = FALSE)

#pad the numbers on GeoID/census ID & rename
auction_data$census_id = with_options(c(scipen = 999), str_pad(auction_data$census_id, 5, pad = "0"))
auction_data <- auction_data %>% rename("GEOID" = census_id)

# create sf object from st 
states_sf <- st_as_sf(USA)


#left join
states_sf_5g <- left_join(states_sf, auction_data, by="GEOID")
states_sf_5g <- st_transform(states_sf_5g, 4326)  # reproject to 4326


us_state_fips <- read_csv("data/county data/us_state_fips.csv")
us_state_fips <- us_state_fips %>% rename(STATEFP='FIPS')
us_state_fips$STATEFP = with_options(c(scipen = 999), str_pad(us_state_fips$STATEFP, 2, pad="0"))

states_sf_5g <- left_join(states_sf_5g, us_state_fips, by="STATEFP")

# show handler
show_loading <- function(elem) {
  session <- shiny::getDefaultReactiveDomain()
  session$sendCustomMessage("show_loading", elem)
}

# hide handler
hide_loading <- function(elem) {
  session <- shiny::getDefaultReactiveDomain()
  session$sendCustomMessage("hide_loading", elem)
}

# loading screen functional component: child element
loading_elem <- function(id, text = NULL) {
  stopifnot(!is.null(id))
  
  # generate element with dots
  el <- tags$div(
    id = id,
    class = "loading-ui loading-dots",
    `aria-hidden` = "true",
    tags$div(
      class = "dots-container",
      tags$span(class = "dots", id = "dot1"),
      tags$span(class = "dots", id = "dot2"),
      tags$span(class = "dots", id = "dot3")
    )
  )
  
  # add message if specified + update attribs
  if (length(text) > 0) {
    el$attribs$class <- "loading-ui loading-text"
    el$children <- tags$p(
      class = "loading-message",
      as.character(text)
    )
  }
  
  # return
  return(el)
}

#' loading screen: primary component wrapper around child
#' and leafletOuput
loading_message <- function(..., id, text = NULL) {
  tags$div(
    class = "loading-container",
    loading_elem(id = id, text = text),
    ...
  )
}

#'/////////////////////////////////////

# ui
ui <- tagList(
  tags$head(
    tags$link(rel = "stylesheet", href = "styles.css")
  ),
  tags$main(
    tags$h2("5G auction results"),
    tags$h4("Please wait for the map to load...it may take upto 30s"),
    
    # Header
    headerPanel(
      title=tags$a(href='https://www.bbh-llc.com/',tags$img(src='bbh-logo-cropped.png', height = 50), target="_blank"),
      tags$head(tags$link(rel = "icon", type = "image/png", href = "bbh-logo-transparent.png"), windowTitle="5G auction results")
    ),

    # init loading ui
    loading_message(
      id = "leafletBusy",
      leafletOutput("map", height = "70vh")
    )
  ),
  tags$script(src = "index.js")
)

#'/////////////////////////////////////

# server
server <- function(input, output, session) {
  
  bins_auction = c(1e+03,3.4e+03,5.4e+03,8.5e+03,1.4e+04,2.1e+04,3.3e+04,5.7e+04,1.09e+05,5.21e+07)
  mypal <- colorBin("YlOrBr", domain = states_sf_5g$posted_price, bins = bins_auction )

  output$map <- renderLeaflet({
    show_loading(elem = "leafletBusy")
    
    m <- leaflet() %>%
      addProviderTiles("OpenStreetMap.Mapnik")%>%
      setView(lat = 39.8283, lng = -98.5795, zoom = 4) %>%
      addPolygons(
        data = states_sf_5g,
        fillColor = ~mypal(states_sf_5g$posted_price),
        stroke = FALSE,
        smoothFactor = 0.2,
        fillOpacity = 0.7,
        popup = paste("<b>County:</b> ", states_sf_5g$county_name, "<br>",
                      "<i>Selling Price (in US $)</i>: ", states_sf_5g$posted_price, "<br>")) %>%
      addLegend(position = "bottomleft",
                pal = mypal,
                values = states_sf_5g$posted_price,
                title = "Selling Price, in USD",
                opacity = 0.7)
    
    # hide loading elem and return map
    Sys.sleep(10)
    hide_loading(elem = "leafletBusy")
    return(m)
  })
}

#'/////////////////////////////////////

# app
shinyApp(ui = ui, server = server)


