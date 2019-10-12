library(shiny)
library(leaflet)
library(data.table)
library(lubridate)
library(dplyr)
library(ggplot2)
library(plotly)
library(gridExtra)
library(ggmap)
library(stringr)
library(treemap)
library(RColorBrewer)

set.seed(100)
data=fread("MovieInPark14-19.csv")
yearlist<-c("2014","2015","2016","2017","2018","2019")
wdlist=c("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")

shinyServer(function(input,output){
  ## the interactive map
  output$map<-renderLeaflet({
    
    tmp=data
    ## filter the data based on input$year
    
    for (i in 1:6) {
      if (!(yearlist[i] %in% input$year)){
        tmp=tmp[Year!=yearlist[i]]
      }
    }
    
    ## filter data based on input$weekday
    
    for (i in 1:7) {
      if (!(wdlist[i] %in% input$weekday)){
        tmp=tmp[Weekday!=wdlist[i]]
      }
    }
    
    countdata<-tmp[, .(count = .N, val = list(MovieName)), 
                   by = c("ParkName","longitude","latitude")]  # the subset for "parks" map
    countdata$information=paste("<h4>","<b>",countdata$ParkName,"</b>","</h4>",
                                "<h6>Holding events frequency:", "<b>",
                                countdata$count,".","</b>","</h6>",
                                "Movies include:","</br>",
                                "<em>",countdata$val)
    countdata$information=str_remove(countdata$information,"c\\(")
    countdata1=countdata[countdata$count==1]
    countdata2=countdata[countdata$count>1]
    countdata2$information=substr(countdata2$information, 1, nchar(countdata2$information)-1)
    countdata=rbind(countdata1,countdata2)
    
    max=max(countdata$count)
    
    getColor <- function(countdata) {
      sapply(countdata$count, function(count) {
        if(count == 1) {
          "green"
        } else if(count==max){
          "red"
        } else {
          "orange"
        } })
    }
    
    icons <- awesomeIcons(
      icon = 'ios-close',
      iconColor = 'black',
      library = 'ion',
      markerColor = getColor(countdata)
    )
    
    leaflet(countdata)%>%
      setView(lng = -87.62, lat = 41.9, zoom = 11)%>% 
      addTiles()%>%
      addProviderTiles(providers$Hydda.Full)%>%
      addAwesomeMarkers(~longitude, ~latitude, icon=icons,popup = ~information)%>%
      addLegend(position="bottomright",colors = c("red","orange","green"),
                labels=c(" Frequency = highest","1 < Frequency < highest","  Frequency = 1"),
                title = "Color of Park Markers",opacity = 1)
    
    

    
    
    
    
  })
  
  ## statistics
  output$year_count<-renderPlot({
    data$Year=as.character(data$Year)
    data %>%
      select(Year)%>%
      group_by(Year)%>%
      ggplot(aes(x=Year))+
      geom_bar(fill="#FF9999")+
      scale_x_discrete(limits=c("2014","2015","2016","2017", "2018","2019"))+
      ggtitle("Number of Movie Events from 2014 to 2019")+
      theme(axis.text.x = element_text(angle = 60, hjust = 1))
    })
  
  output$month_count<-renderPlot({
    tmp=data
    
    tmp=tmp[Year==as.numeric(input$select_year)]
    tmp %>%
      select(month)%>%
      group_by(month)%>%
      ggplot(aes(x=month))+
      geom_bar(fill="#FF9999")+
      scale_x_discrete(limits=c("Jan","Feb","Mar","Apr", "May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"))+
      ggtitle("Number of Movie Events in Each Month")+
      theme(axis.text.x = element_text(angle = 60, hjust = 1))+
      theme(plot.title = element_text(hjust = 0.5))
  })
  
  output$weekday_count<-renderPlot({
    tmp=data
    tmp=tmp[Year==input$select_year]
    tmp %>%
      select(Weekday)%>%
      group_by(Weekday)%>%
      ggplot(aes(x=Weekday))+
      geom_bar(fill="#FF9999")+
      scale_x_discrete(limits=c("Monday","Tuesday","Wednesday","Thursday", "Friday","Saturday","Sunday"))+
      ggtitle("Number of Movie Events in Each Weekday")+
      theme(axis.text.x = element_text(angle = 60, hjust = 1))+
      theme(plot.title = element_text(hjust = 0.5))
  })
  
  output$treemap<-renderPlot({
    tmp=data
    for (i in 1:6) {
      if (!(yearlist[i] %in% input$year_treemap)){
        tmp=tmp[Year!=yearlist[i]]
      }
    }
    tmp=tmp[, .(count=.N),by="CommunityAreas"]
    tmp=tmp[CommunityAreas!=""]
    tmp$info=paste("Area No.",tmp$CommunityAreas,", ","Events: ",tmp$count,sep="")
    tmp$CommunityAreas=as.character(tmp$CommunityAreas)
    treemap(tmp,index="info",vSize="count",vColor="CommunityAreas",type="categorical",
            title="Number of Events in Each Community Areas",palette="RdYlBu",
            drop.unused.levels = FALSE, position.legend="none",fontsize.labels=8)
  })
  
  output$rating_caption<-renderPlot({
    ## MovieRating
    p1<-data %>%
      select(MovieRating)%>%
      filter(MovieRating!="N/A" & MovieRating != "")%>%
      group_by(MovieRating)%>%
      ggplot(aes(x=MovieRating))+
      geom_bar(fill="#FF9999")+
      theme(axis.text.x = element_text(angle = 60, hjust = 1))
    
    ## MovieClosedCaption
    p2<-data %>%
      select(MovieClosedCaption)%>%
      filter(MovieClosedCaption!="N/A" & MovieClosedCaption != "")%>%
      group_by(MovieClosedCaption)%>%
      ggplot(aes(x=MovieClosedCaption))+
      geom_bar(fill="#FF9999")+
      theme(axis.text.x = element_text(angle = 60, hjust = 1))
    
    grid.arrange(p1, p2, nrow = 1)
  })
  
  output$topmovies<-renderPlot({
    tmp=data[, .(count=.N),by=MovieName]
    top=as.numeric(input$top_movie)
    
    nb.cols <- top
    mycolors <- colorRampPalette(brewer.pal(8, "Set2"))(nb.cols)
    
    tmp%>%
      arrange(desc(count)) %>%
      slice(1:top)%>%
      ggplot(aes(x=reorder(MovieName,count), y=count,fill=factor(MovieName)))+
      geom_bar(stat='identity')+coord_flip()+theme_light()+theme(legend.position="none")+
      ggtitle("The Most Popular Movies in the Events")+
      theme(plot.title = element_text(hjust = 0.5))+
      scale_fill_manual(values = mycolors) 
  })
  
  output$items_dt = DT::renderDataTable(
    data[,c(1:9,13,14)],
    filter = 'top',
    options = list(scrollX = TRUE)
  )
  
})