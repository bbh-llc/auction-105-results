# Load all libraries

library(leaflet)
library(tidyverse)
library(sf)
library(shiny)
library(withr)

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

#shiny app

ui <- fluidPage(
    # Application title
    titlePanel("5G Spectrum auction results"),
    
    tags$head(
        tags$script(src="https://cdnjs.cloudflare.com/ajax/libs/iframe-resizer/3.5.16/iframeResizer.contentWindow.min.js",
                    type="text/javascript")
    ),
    
    # Header
    headerPanel(
        title=tags$a(href='https://www.bbh-llc.com/',tags$img(src='bbh-logo-cropped.png', height = 75), target="_blank"),
        tags$head(tags$link(rel = "icon", type = "image/png", href = "bbh-logo-cropped.png"), windowTitle="5G auction results")
    ),
    
    
    #leaflet options
    leafletOutput("map")
    # height = "100vh"
)

# bins_auction = list(states_sf_5g$bin_lengths)

server <- function(input, output, session){
    # # Loading modal to keep user out of trouble while map draws...
    # showModal(modalDialog(title="MAP LOADING - PLEASE WAIT...","Please wait for map to load.",size="l",footer=NULL))
    # 
    # # Remove modal when app is ready
    # observe({
    #     req(output$map)
    #     removeModal()
    # })
    # resources: https://stackoverflow.com/questions/5812493/how-to-add-leading-zeros
    
    
    # bins_auction = c(1e+03,1.7e+03,3.4e+03,5.4e+03,8.5e+03,1.4e+04,2.1e+04,3.3e+04,5.7e+04,1.09e+05,5.21e+07)
    bins_auction = c(1e+03,3.4e+03,5.4e+03,8.5e+03,1.4e+04,2.1e+04,3.3e+04,5.7e+04,1.09e+05,5.21e+07)
    mypal <- colorBin("YlOrBr", domain = states_sf_5g$posted_price, bins = bins_auction )
    
    output$map <- renderLeaflet({
        leaflet() %>%
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
    })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)


#convert to geojson
# install.packages("geojsonsf")
# 
# library(geojsonsf)
# export_file <- sf_geojson(states_sf_5g, atomise = T)
# 
# # reprojection
# states_sf_5g_transformed <- st_transform(states_sf_5g, 4326)
# st_crs(states_sf_5g_transformed) # confirmation on reprojection



# # Define UI for application that draws a histogram
# ui <- fluidPage(
# 
#     # Application title
#     titlePanel("5G Spectrum auction results"),
# 
#     # Sidebar with a slider input for number of bins 
#     sidebarLayout(
#         sidebarPanel(
#             sliderInput("bins",
#                         "Number of bins:",
#                         min = 1,
#                         max = 50,
#                         value = 30)
#         ),
# 
#         # Show a plot of the generated distribution
#         mainPanel(
#            plotOutput("distPlot")
#         )
#     )
# )
# 
# # Define server logic required to draw a histogram
# server <- function(input, output) {
# 
#     output$distPlot <- renderPlot({
#         # generate bins based on input$bins from ui.R
#         x    <- faithful[, 2]
#         bins <- seq(min(x), max(x), length.out = input$bins + 1)
# 
#         # draw the histogram with the specified number of bins
#         hist(x, breaks = bins, col = 'darkgray', border = 'white')
#     })
# }
# 
# # Run the application 
# shinyApp(ui = ui, server = server)
