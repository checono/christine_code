
#install.packages("xlsx") #install 
install.packages("quandmod")
require(xlsx)
require(ggplot2)
require(RColorBrewer)
require(quandmod)

#Import data
Oct2014 <-data.frame(read.xlsx("R/CBOs_number_of_active_months_in_CCTP_as_of Jul_2015.xlsx", 1))
OctMin <-min(Oct2014$Updated_Implementation_Date)
OctMax <-max(Oct2014$Updated_Implementation_Date)

Jul2015 <-data.frame(read.xlsx("R/CBOs_number_of_active_months_in_CCTP_as_of Jul_2015.xlsx", 2))
JulMin <-min(Jul2015$Updated_Implementation_Date)
JulMax <-max(Jul2015$Updated_Implementation_Date)

#Make a vector to display N=x for duplicate counts (this will become the label for each bubble)
for(i in 1:length(Oct2014$count.duplicates)){
     Oct2014$dupsCharVector[i] <- paste("N=",Oct2014$count.duplicates[i])
}

for(i in 1:length(Jul2015$Count.duplicates)){
     Jul2015$dupsCharVector[i] <- paste("N=",Jul2015$Count.duplicates[i])
     print(paste(Jul2015$Count.duplicates,Jul2015$dupsCharVector))
}






###---------October 2014 Bubble Chart--------------------------------------------------------------------------------------------------#

myPaletteEconoHex <-colorRampPalette(c("#FFFF00", "#00AEEF", "#25408F", "#002D73"), bias=1)  #yellow, cyan, med blue, dark blue HEX

Oct2014Plot<-ggplot(Oct2014, aes(x=Updated_Implementation_Date, y=Duration.Days_asofOct2014,label=dupsCharVector), guide=FALSE)+
     geom_point(aes(size=sqrt(count.duplicates/pi), fill=Oct2014$count.duplicates), alpha=0.7,colour="grey", shape=21,  guide=FALSE)+ #controls the circles
     scale_size_area(max_size = 20)+ #scales the circles
     scale_fill_gradientn(colours= myPaletteEconoHex(5), name= "Count Duplicates",values=NULL, space="Lab", na.value= "grey50", guide=FALSE)+ #color
     scale_x_date(name="Implementation Date", limits=c(JulMin, JulMax))+ #x-axis contains dates
     scale_y_continuous(name="Duration Days", limits=c(0,1250))+ #y-axis=duration days (counts)
     geom_text(size=3)+ #set the size of the circle labels
     annotate("text", label="*N identifies the number of hospitals in a CBO", x=as.Date(mean.Date(Oct2014$Updated_Implementation_Date)), y=1, colour="black")+
     guides(size=FALSE)+ #supress legend for SIZE
     guides(scale_fill_gradientn=FALSE)+ #suppress legend for COLOR SCALE
     theme_bw()#get rid of gray background 

plot(Oct2014Plot) #display plot 


#------------July 2015 Bubble Chart--------------------------------------------------------------------------------------------------------#

Jul2015Plot<-ggplot(Jul2015, aes(x=Updated_Implementation_Date, y=Duration.Days,label=dupsCharVector),guide=FALSE)+
     geom_point(aes(size=sqrt(Count.duplicates/pi), fill=Jul2015$Count.duplicates), alpha=0.7, colour="grey", shape=21, guide=FALSE)+ 
     scale_size_area(max_size = 17)+
     scale_fill_gradientn(colours= myPaletteEconoHex(5), name= "Count Duplicates",values=NULL, space="Lab", na.value= "grey50", guide=FALSE)+
     scale_x_date(name="Implementation Date", limits=c(JulMin, JulMax))+
     scale_y_continuous(name="Duration Days", limits=c(0,1500))+
     geom_text(size=2)+
     annotate("text", label="*N identifies the number of hospitals in a CBO", x=as.Date(mean.Date(Jul2015$Updated_Implementation_Date)), y=1)+
     guides(size=FALSE)+
     guides(scale_fill_gradientn=FALSE)+
     theme_bw()

plot(Jul2015Plot) 

#Save both plots as PDFs; specify path & fileName
ggsave(Oct2014Plot, file = "CCTP_Oct2014_BubbleChart.pdf", path="//Econo-file1/users/Shares/ZJ5586B/R" ,width=15, height=11, scale=0.75)
ggsave(Jul2015Plot, file = "CCTP_Jul2015_BubbleChart.pdf", path="//Econo-file1/users/Shares/ZJ5586B/R" ,width=15, height=11, scale=0.75)
