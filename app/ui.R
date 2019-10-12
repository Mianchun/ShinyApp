library(shiny)
library(shinydashboard)
library(leaflet)
library(shinythemes)
library(dplyr)
library(ggplot2)
library(plotly)
library(gridExtra)
library(ggmap)
library(stringr)
library(treemap)

years<-c("2014","2015","2016","2017","2018","2019")
weekdays<-c("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")

shinyUI(
  navbarPage("Enjoy a movie in the parks!", id="nav",
             #theme="bootstrap.css",
             #shinythemes::themeSelector(),
             theme=shinytheme("journal"),
             tabPanel("Events Records",
                      class="outer",
                      leafletOutput("map", width="100%", height=550),
                      absolutePanel(id = "controls",class = "panel panel-default",fixed = TRUE,
                                    draggable = TRUE,top = 100,left = "auto",right = 25,
                                    bottom = "auto",width = 210,height = "auto",
                                    h4("  In Chicago, 2014-2019"),
                                    checkboxGroupInput("year", "Select Years:", 
                                                       choices=years,
                                                       selected="2019",inline=TRUE,
                                                       width = "100%"),
                                    checkboxGroupInput("weekday","Select Weekdays:",
                                                       choices=weekdays,
                                                       selected=weekdays,inline=TRUE,
                                                       width = "100%"),
                                    titlePanel(
                                      tags$div(id="infomarion",tags$h5("Join us in the parks for anything from classics from the Golden Age of Hollywood and retro childhood favorites, to the best family-friendly box office favorites from recent years.",tags$a(href="https://www.chicagoparkdistrict.com/movies-parks","For more informatin."))))
                                    
                      ),
                      tags$div(id="cite",'Sources: ', tags$em('U.S. government open data released on the '), tags$a(href="https://catalog.data.gov/dataset", "DATA.GOV")
                      )),
             
             navbarMenu("Statistics",
                        ## events related 
                        tabPanel("Event Related",
                                 tabsetPanel(
                                   tabPanel("Date Frequency",
                                            titlePanel("Date & the Number of Events"),
                                            sidebarLayout(
                                              sidebarPanel(
                                                selectInput("select_year", "Select Years:", 
                                                            choices=
                                                              c("2014","2015","2017","2018","2019"),
                                                            selected="2019",
                                                            width = "100%")
                                              ),
                                              mainPanel(
                                                plotOutput("month_count",height = "250px"),
                                                plotOutput("weekday_count",height = "250px"),
                                                absolutePanel(id = "controls", 
                                                              class = "panel panel-default", 
                                                              fixed = TRUE,
                                                              draggable = TRUE, 
                                                              top = 400, left = 20, right = "auto",
                                                              bottom = "auto",
                                                              width = 350, height = "auto",
                                                              plotOutput("year_count",
                                                                         width="100%",
                                                                         height="250px")
                                                )
                                              )
                                            )),
                                   
                                   tabPanel("Location Frequency",
                                            titlePanel("Location & the Number of Events"),
                                            sidebarLayout(
                                              sidebarPanel(
                                                checkboxGroupInput("year_treemap", "Select Years:", 
                                                                   choices=years,
                                                                   selected="2019",inline=F,
                                                                   width = "100%"),
                                                width=2
                                              ),
                                              mainPanel(
                                                plotOutput("treemap",width=700,height=450),
                                                absolutePanel(id = "controls", 
                                                              class = "panel panel-default", 
                                                              fixed = TRUE,
                                                              draggable = TRUE, 
                                                              top = 200, left = "auto", right =30,
                                                              bottom = "auto",
                                                              width = 350, height = "auto",
                                                              img(src = "community_areas.png",width="100%"))
                                                
                                              )
                                            )
                                            
                                   ))),
                        
                        ## movies related
                        tabPanel("Movie Related",
                                 titlePanel("The Movies Shown in the Events"),
                                 sidebarLayout(
                                   sidebarPanel(
                                     sliderInput("top_movie",
                                                 label=
                                                   "Most Popular Movies",
                                                 value=25,min=1,max=50)),
                                     mainPanel(
                                       absolutePanel(id = "controls", 
                                                     class = "panel panel-default", 
                                                     fixed = TRUE,
                                                     draggable = TRUE, 
                                                     top = 380, left = 20, right = "auto",
                                                     bottom = "auto",
                                                     width = 350, height = "auto",
                                                     plotOutput("rating_caption",
                                                                width="100%",
                                                                height="250px")),
                                       plotOutput(outputId="topmovies",height = "520px")
                                     )
                                   )
                                 )
             ),
             tabPanel("Data",
                      titlePanel("Original Data"),
                      DT::dataTableOutput('items_dt'))
  )
)