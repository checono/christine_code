#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh#
# Name: Christine Herlihy
# Date Last Modified: 12/19 by Christine Herlihy
# Objective: Generate a bubble chart overlaying the US map; make bubbles = pie charts
#
#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh#

#Required packages
require("plyr")
require("tidyr")
require("dplyr")
require("ggplot2")
require("gridExtra")
require("stringr")
require("scales")
require("xlsx")
require("maptools")
require("mapproj")
require("rgeos")
require("rgdal")
require("devtools")
require("pacman")
require("reshape")


input <- read.xlsx("//Econo-file1/users/Shares/ZJ5586B/R/FNS_pieChartsMap.xlsx",1, stringsAsFactors=FALSE)

input2 <- input[,c(1:8)]

input3  <- melt(input2, id=c("States","Capital", "long", "lat", "Group"))

pickColors <-function(tempData){
     if(tempData$Group[1] == "Pilot States (Delayed)"){
          pal <- colorRampPalette(c("cyan2", "blue3"))
          colors <- pal(3)
          
     }
     else if(tempData$Group[1] == "Non Pilot States"){
          pal <- colorRampPalette(c("tomato1", "tomato4"))
          colors <- pal(3)
          
     }
     
     else if(tempData$Group[1]== "SY 2014-2015 Pilot States"){
          pal <- colorRampPalette(c("gold", "goldenrod3"))
          colors <- pal(3)
     }
     return(colors)
}




for(i in 1:length(input$States)){
     temp <- input3[which(input3$States==input$States[[i]] & input3$value !=0),]

     varlist <- c(temp$variable)
     print(paste("varlist len", length(varlist), sep=" "))
# 
     for(j in 1:length(varlist)){
          if(temp$variable[j] == "Grower.Packer")
               {temp$label[j] <- paste("Grower", "Packer", sep= " ")}
          else if(temp$variable[j] == "Distributor")
               {temp$label[j] <- paste("Distributor", sep= " ")}
          else if(temp$variable[j] == "Grower")
               {temp$label[j] <- paste("Grower", sep= " ")}
     }
     
     print(head(temp))
    
     # Use a color ramp
     tempColors <-pickColors(temp)
     tempPie <-  
     
     jpgfilename <- paste("//Econo-file1/users/Shares/ZJ5586B/R/FNS_pieCharts/", input$States[[i]], ".png", sep="")
     png(filename=jpgfilename,width=480,height=480)
     pie(temp$value, clockwise=TRUE, border="black", labels=temp$label,
         col=tempColors)
  #   ggsave(filename=jpgfilename, plot=tempPie, width=12,height=8, dpi=300)
     dev.off()
}

ggplot() +
     geom_path(data = usa, aes(x = long, y = lat, group = group)) +
     geom_point(data = input, aes(x = long, y = lat, size = Total), color = "gray") 

# Get US map
usa <- map_data("state")

# Draw the map and add the data points in myData

jpgfilename <- paste("//Econo-file1/users/Shares/ZJ5586B/R/FNS_pieCharts/", "BubbleMap.png", sep="")
png(filename=jpgfilename, width=1000)
ggplot() +
     geom_path(data = usa, aes(x = long, y = lat, group = group)) +
     geom_point(data = input, aes(x = long, y = lat, size = Total, color=factor(input$Group))) + 
     scale_size_continuous(range=c(14,20)) 
#   ggsave(filename=jpgfilename, plot=tempPie, width=12,height=8, dpi=300)
dev.off()

