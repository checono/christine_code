#install.packages("colorspace")
#install.packages("ggplot2")
#install.packages("reshape")
library("ggplot2")
require("reshape")
library("scales")
require("cowplot")
library("gridExtra")
library("zoo")

filepath <-"K:/CMS/Bundle Payments/3.Deliverables/Task 5_1 Preparation of Annual Reports/AROY2/DensityPlots/Stacked_densityPlots/"


#Load in master data sets
all <- data.frame(read.csv("//Econo-file1/users/Shares/ZJ5586B/R/22U_New_all.csv"))
all$cohort_flag = 1
active <- data.frame(read.csv("//Econo-file1/users/Shares/ZJ5586B/R/22U_New_active.csv"))
active$cohort_flag = 2
exiting <-data.frame(read.csv("//Econo-file1/users/Shares/ZJ5586B/R/22U_New_exits.csv"))
exiting$cohort_flag=3
phc <-data.frame(read.csv("//Econo-file1/users/Shares/ZJ5586B/R/22U_New_PHC.csv"))
phc$cohort_flag=4


#Econometrica Palette colors
myPaletteEconoHex <-colorRampPalette(c("darkgoldenrod2", "#00AEEF","#25408F", "darkblue"), bias=0.1, space="rgb")  #yellow, c

jointData <- rbind(all, active, exiting, phc)
colnames(jointData) <- c("qtr", "hbpci", "discharge_SNF", "discharge_HSP","discharge_HHA", "discharge_IRF", "discharge_LTCH", "discharge_OTHR",
                         "DT", "SNF", "HSP", "HHA", "IRF", "LTCH", "OTHER", "cohort_flag" )

# quarter       <- seq(17)
# starting.year <- 2011
# 
# #Create function for generating quarters
# convertToQ <- function(qs, s) {
#      d <- c()
#      for(q in qs){
#           qtr <- (q-1)%%4 +1
#           d <- c(d, (paste(s, "-Q", qtr, sep = "")))
#           if(qtr == 4) s <- s +1
#      }
#      return(d)
# }
# 
# quarterlyTicks<- data.frame(quarters= convertToQ(quarter, starting.year),
#                    stringsAsFactors=FALSE)


######################################
plot_list=list()

for(i in 1:4){
     tempDF <- jointData[jointData$cohort_flag==i,]
     tempFlag <- ""
     
     if(i == 1){
          tempFlag <- "Full"
     } else if(i==2){
          tempFlag <- "Active"
     } else if(i==3){
          tempFlag <- "Exiting"
     } else if(i==4){
          tempFlag <- "PHC"
     }

     #This set of functions should be applied first to each data frame, and then to each subset:
    tempTreatDF <-  tempDF[tempDF$hbpci==1, c(1, 10:15)]
    tempControlDF <-tempDF[tempDF$hbpci==0, c(1, 10:15)]
     
     
     #Need to make horizontal df into a vertical one to do stacked area plot: 
     tempTreatDF <-melt(tempTreatDF, id.vars="qtr")
     tempControlDF <-melt(tempControlDF, id.vars="qtr")
     
     #Stacked area plot option 
     treat_Plot <- ggplot(tempTreatDF,aes(x = qtr, y = value, fill=variable)) + 
          scale_x_discrete(labels=c("2011-Q1", "2011-Q2","2011-Q3","2011-Q4", "2012-Q1", "2012-Q2", "2012-Q3", "2012-Q4",
                                   "2013-Q1", "2013-Q2", "2013-Q3", "2013-Q4", "2014-Q1", "2014-Q2","2014-Q3", "2014-Q4",
                                    "2015-Q1"))+
          scale_y_continuous(labels = percent_format())+
          ylab("Discharge Destination (%)")+
          xlab("Quarter")+
          ggtitle("BPCI")+
          geom_area()+
          scale_fill_brewer(palette= "Blues")+ #can change the color scheme here.
          theme(axis.title.y =element_text(vjust=1.5, size=11))+
          theme(axis.title.x =element_text(vjust=0.1, size=11))+
          theme(axis.text.x = element_text(size=10,angle=-45,hjust=.5,vjust=.5))+
          theme(axis.text.y = element_text(size=10,angle=0,hjust=1,vjust=0))+
          theme(legend.position="none")
          

     #Stacked area plot option 
     control_Plot <- ggplot(tempControlDF,aes(x = qtr, y =value, fill=variable)) + 
     scale_x_discrete(labels=c("2011-Q1", "2011-Q2","2011-Q3","2011-Q4", "2012-Q1", "2012-Q2", "2012-Q3", "2012-Q4",
                                    "2013-Q1", "2013-Q2", "2013-Q3", "2013-Q4", "2014-Q1", "2014-Q2","2014-Q3", "2014-Q4",
                                    "2015-Q1"))+
     scale_y_continuous(labels = percent_format())+
     ggtitle("Comparison")+
     ylab("Discharge Destination (%)")+
     xlab("Quarter")+
     geom_area()+
     scale_fill_brewer(palette= "Blues", name="Discharge Destinations")+ #can change the color scheme here.
     theme(axis.title.y =element_text(vjust=1.5, size=11))+
     theme(axis.title.x =element_text(vjust=0.1, size=11))+
     theme(axis.text.x = element_text(size=10,angle=-45,hjust=.5,vjust=.5))+
     theme(axis.text.y = element_text(size=10,angle=0,hjust=1,vjust=0))+
     theme(legend.direction = "horizontal", legend.position =  c(0.7,.9), legend.justification = "right")

     #Get the legend of the plot on the right as an object, to call later as shared legend for both plots 
     library(gridExtra)
     get_legend<-function(myggplot){
          tmp <- ggplot_gtable(ggplot_build(myggplot))
          leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
          legend <- tmp$grobs[[leg]]
          return(legend)
     }
     
     dummyLegend <- get_legend(control_Plot)
     
     #Re-do control_Plot to get a plot where legend is suppressed
     control_PlotB <- control_Plot + theme(legend.position="none")
     
     dummyTitle <- paste(tempFlag, " Cohort")
     
     #Put both plots into the plot list
     plot_list[[i]] <- plot_grid(treat_Plot, control_PlotB, ncol = 2, nrow = 1, scale = 0.95, labels=c("  ", dummyTitle), label_size=17, hjust=0.2, vjust=-0.2)
     #pngfilename <-paste(tempFlag, "plot.png")
     #ggsave(filename=pngfilename, plot=plot_list[[i]], width=18,height=8, dpi=300)
}

#Place the full and active cohort plots in a panel graph
png(filename=paste(filepath,"full_and_active_plot2.png", sep=''), width=2000, height=900)
grid.arrange(plot_list[[1]], plot_list[[2]], dummyLegend, ncol=2, nrow=2, 
             layout_matrix= rbind(c(1,2), c(3,3)))
dev.off()


#Place the Exiting and PHC cohort plots in a panel graph 
png(filename=paste(filepath,"exiting_and_phc.png", sep=''), width=2000, height=900)
grid.arrange(plot_list[[3]], plot_list[[4]], dummyLegend, ncol=2,  nrow=2, 
             layout_matrix= rbind(c(1,2), c(3,3)))
dev.off()


## Stacked grid plots, 2r * 1c
#Place the full and active cohort plots in a panel graph
png(filename=paste(filepath,"full_and_active_plot_STACKED2.png", sep=''), width=1000, height=1000)
grid.arrange(plot_list[[1]], plot_list[[2]], dummyLegend, ncol=1, nrow=3,
            layout_matrix= rbind(c(1), c(2), c(3)))
dev.off()


#Place the Exiting and PHC cohort plots in a panel graph 
png(filename=paste(filepath,"exiting_and_phc_STACKED2.png", sep=''), width=1000, height=1000)
grid.arrange(plot_list[[3]], plot_list[[4]], dummyLegend, ncol=1,  nrow=3, 
             layout_matrix= rbind(c(1), c(2), c(3)))
dev.off()
