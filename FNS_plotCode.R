require(xlsx)
require(plyr)
library(knitr)
require(ggplot2)
require(scales)
require(stringr)
require(reshape2)


input <- data.frame(read.xlsx("//Econo-file1/users/Shares/ZJ5586B/FNS_out_Edited.xlsx",1, stringsAsFactors=FALSE))
barsInput <- data.frame(read.xlsx("//Econo-file1/users/Shares/ZJ5586B/sample_fruitsVeg_chart_v2_Edited.xlsx",2, stringsAsFactors=FALSE))
variety <- data.frame(read.xlsx("//Econo-file1/users/Shares/ZJ5586B/pilot_product_variety_Edited.xlsx",2, stringsAsFactors=FALSE))
variety <- data.frame(read.csv("//Econo-file1/users/Shares/ZJ5586B/pilot_product_variety_Edited.csv", stringsAsFactors=FALSE))

input[is.na(input)] <- 0

colnames(input) <- c("A", "B", "C", "D", "E", "F")

topTenB <- tail(sort(input$B), 10)
topTenC <- tail(sort(input$C), 10)
topTenD <- tail(sort(input$D), 10)
topTenE <- tail(sort(input$E), 10)
topTenF <- tail(sort(input$F), 10)


for(i in 1:length(input$A)){
     
     # Create boolean for if item was in top 10 in ALL other programs 
     inAllOthers <- (input$B[i] %in% topTenB & input$C[i] %in% topTenC & input$E[i] %in% topTenE & input$F[i] %in% topTenF)
     
     # If item is in top 10 in the pilot and in NO OTHER program, put a 1
     if(input$D[i] %in% topTenD & !inAllOthers){
          input$inPilotNotOthers[i] <- 1
     }
     else{
          input$inPilotNotOthers[i] <- 0
     }
     
     # Add a flag if item was purchased in pilot and in NO OTHER program
     if(input$D[i] > 0 & (input$B[i] == 0 & input$C[i] ==0 & input$E[i] ==0 & input$F[i] ==0)){
          print("occurs")
          input$inPilotNotOthers[i] <- 2
     }
}

for(i in 1:length(input$A)){
     
     input$freq[i] <- 0
     
     for(x in 2:6){
          if(input[i,x] != 0)
               input$freq[i] <- input$freq[i] + 1
     }
}



write.xlsx(input, "//Econo-file1/users/Shares/ZJ5586B/FNS_final_Edited.xlsx")



#------------------------------------------------------------------------------#

# Work with variety data

for(i in 1:length(variety$Food_Group)){
     
     # Create boolean for if item was in top 10 in ALL other programs 
     variety$onlyPilot[i] <- (variety$SY.2014.2015.UFV.Pilot[i] == 1 & (variety$SY.2013.2014.DoD.Fresh[i] == 0 & 
                                                             variety$SY.2014.2015.DoD.Fresh[i] == 0 &
                                                             variety$SY.2013.2014.USDA.Foods[i] ==0 &
                                                             variety$SY.2014.2015.USDA.Foods[i] ==0 ))

}

variety <- variety[1:26,]

# Reshape data from wide to long
variety2 <- reshape(variety, varying=c("SY.2013.2014.DoD.Fresh", "SY.2014.2015.DoD.Fresh","SY.2014.2015.UFV.Pilot", "SY.2013.2014.USDA.Foods", "SY.2014.2015.USDA.Foods"), v.names="value", 
                    timevar = "program", times= str_wrap(c("SY 2013-2014 DoD Fresh", "SY 2014-2015 DoD Fresh","SY 2014-2015 UFV Pilot", "SY 2013-2014 USDA Foods","SY 2014-2015 USDA Foods")),
                    new.row.names= 1:130, direction="long")

# only show fruits that were purchased for each program 
vargraphdata <- variety2[which(variety2$value==1),]


for(i in 1:length(vargraphdata$Food_Group)){
     
     if(vargraphdata$program[i]== "SY 2013-2014 DoD Fresh"){
          vargraphdata$count[i] <- 12
          vargraphdata$sort[i] <- 1
          
     }
     
     else if (vargraphdata$program[i]== "SY 2014-2015 DoD Fresh"){
          vargraphdata$count[i] <- 12
          vargraphdata$sort[i] <- 2
     }
     
     else if(vargraphdata$program[i]== "SY 2014-2015 UFV Pilot"){
          vargraphdata$count[i] <- 22
          vargraphdata$sort[i] <- 3
     }
     
     else if(vargraphdata$program[i]== "SY 2013-2014 USDA Foods"){
          vargraphdata$count[i] <- 6
          vargraphdata$sort[i] <- 4
     }
     
     else if(vargraphdata$program[i]== "SY 2014-2015 USDA Foods"){
          vargraphdata$count[i] <- 4
          vargraphdata$sort[i] <- 5
     }

     vargraphdata$title[i] <- paste(str_wrap(vargraphdata$program[i], width=12), "\n", "Variety Count: ", vargraphdata$count[i], sep="")
}


varietyPlot <- ggplot(data=vargraphdata, aes(x=factor(sort), y=factor(Variety_Group), color=factor(onlyPilot)))+
     geom_point(stat = "identity", position = "identity")+
     scale_x_discrete(labels =  c(unique(vargraphdata$title)))+
     scale_colour_manual(values = c("black","red"))+
     ylab("")+
     xlab("")+
     theme(axis.text.x = element_text(colour="grey20",size=7,angle=0.1,hjust=0.1,vjust=0,face="plain"))+
     theme(legend.position="none")+
     facet_wrap(~Food_Group, scales = "free_y", ncol=1)+
     theme(strip.text.x= element_text(size = 12, colour = "black", face="bold"))

print(varietyPlot)


jpgfilenameVar <- "//Econo-file1/users/Shares/ZJ5586B/plot3_Huifen_final.png"
ggsave(filename=jpgfilenameVar, plot=varietyPlot, width=8,height=6, dpi=300)


#------------------------------------------------------------------------------#
# Make scatterplot of fruits
temp <- ggplot(data=input, aes(x=factor(A), y=freq, color=factor(inPilotNotOthers)))+
    geom_point(stat = "identity", position = "identity")+
     scale_colour_manual(values = c("black","blue", "red"))+
     ylab(paste("Appearance counts of produce items purchased in SY 2014-2015 Pilot, DoD Fresh, ",  "\n", "and USDA Foods; SY 2013-2014 DoD Fresh, and USDA Foods", sep=""))+
     scale_y_continuous(limits=c(1,5.5))+
     xlab("")+
     theme(axis.text.x = element_text(colour="grey20",size=7,angle=0.1,hjust=0.1,vjust=0,face="plain"))+
     theme(axis.text.y=element_blank())+
     theme(axis.ticks.y=element_blank())+
     theme(legend.position="none")+
     geom_text(aes(x=factor(A), y=freq, ymax=freq, label=A, hjust=-0.1),size=2)+
    coord_flip()

print(temp)

jpgfilename <- "//Econo-file1/users/Shares/ZJ5586B/plot1_Huifen_final.png"
ggsave(filename=jpgfilename, plot=temp, width=6,height=6, dpi=300)

#------------------------------------------------------------------------------#

# Make bar graph of fruits/vegetables
fruits <- barsInput[which(barsInput$Type=="fruit"),]
veg <- barsInput[which(barsInput$Type=="veg"),]

temp2 <- ggplot(data=barsInput, aes(x=factor(Sort), y=Value, fill=Type))+
     geom_bar(stat="identity", position="identity")+
     xlab("")+
     theme(axis.text.y=element_blank())+
     theme(axis.ticks.y=element_blank())+
     geom_text(aes(x=factor(Sort), y=Value, ymax=Value+15000, label=paste(Name, dollar(Value), sep=":  "), hjust=-0.1),size=4)+
     coord_flip()

print(temp2)
jpgfilename2 <- "//Econo-file1/users/Shares/ZJ5586B/plot2_Huifen_final.png"

ggsave(filename=jpgfilename2, plot=temp2, width=16,height=9, dpi=300)

