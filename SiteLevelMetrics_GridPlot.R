#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh#
# Name: Christine Herlihy
# Date Last Modified: 3/3/16 by Christine Herlihy
# Objective: Generate a grid of horizontal bar plots for graphically displaying DiD impact estimates (% and $)
#
# Specs for INPUT data set (from left to right):
#
# Need a data set with each hospital's % of enrollment goal met (here, dummy data is used)
# Need a flag for cohort? (CTI??)
# Need a HOSPTIAL-LEVEL DiD data set for each measure we want a horizontal bar plot for
#
#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh#

#Required packages
require("tidyr")
require("dplyr")
require("plyr")
require(ggplot2)
require(gridExtra)

#Import data
graphpath<-'K:/CMS/Bundle Payments/5.Data/arGraphics/output/Hospital_lvl_visualResults/'
filepath<-'K:/CMS/Bundle Payments/5.Data/arGraphics/data/'
statType <-'ra'
dataname<-'ra_1516_all_hlvl.csv' 
datafile<-paste(filepath,dataname, sep='')
indata<-read.csv(datafile)

#Group measures by type and scale
measures <- c("los","ed30")

### identify binary variables
bvars <- c("mort", "ed30","icu")

days_lab <- c("los")
percent_lab <- c("icu", "mort", "readmit30", "ed30", "enrollment")
dollar_lab <- c("mpaypost30_n_allother", "mpaypost30_n", "mpaypost30_n_snf", "mpaypost30_n_ltchs", "mpaypost30_n_readm", "mpaypost30_allother", "mpaypost30", "mpaypost30_snf", "mpaypost30_inp_ltchs", "mpaypost30_inp_readm", "mpayinp", "mpayinp_ndsct", "mpayinp_hp", "mpayinp_hp_ndsct", "mpayinp_hp_std_wdsct","mpayinp_hp_std_w", "mpayinp_hp_std", "mpayinp_nhp")
plot_list = list()

#Keep only BPCI hospitals
indata <- indata[which(indata$HBPCI==0),]

#Create a significance flag for determining the color of each hospital's bar
indata$sigFlag <- "black"
indata$enrollment <-0.0



for(i in 1:length(indata$HBPCI)){
     
     if(indata$pp_did_pval[i] >= 0.10){indata$sigFlag[i] <- "Not sig"} #NOT statistically significant
     else if(indata$pp_did_pval[i] < 0.10 & indata$pp_did_rate[i] > 0){indata$sigFlag[i] <- "Sig pos"} #significant positive result
     else if(indata$pp_did_pval[i] < 0.10 & indata$pp_did_rate[i] < 0){indata$sigFlag[i] <- "Sig neg"}#significant negative result
     indata$enrollment[i] <- indata$enrollment[i] + runif(1, min=0.01, max=1)
}

#Make separate enrollment plot
jpgfilename <- paste(graphpath, statType, enrollment, ".jpg",sep="")
graphdata <-indata
graphdata$enrollment <- graphdata$enrollment*100

p2<-ggplot(data=graphdata,aes(x= factor(cohort), y=enrollment)) +
     geom_bar(stat="identity", aes(fill= typez ))+
     scale_fill_manual(values=c("#F9A200"))+
     scale_y_continuous(limits = c(0, 100))+
     ylab("Enrollment as a % of goal")+
     xlab("")+
     ggtitle("Enrollment goal met (%)")+
     theme(legend.position="none")+
     theme(legend.text=element_text(size=19))+
     theme(axis.text.x = element_text(colour="grey20",size=15,angle=0,hjust=.5,vjust=.5,face="bold"),axis.text.y = element_text(colour="grey20",size=15,angle=0,hjust=1,vjust=0,face="bold"), axis.title.x = element_text(colour="grey20",size=15,angle=0,hjust=.5,vjust=0,face="bold"), axis.title.y = element_text(colour="grey20",size=15,angle=90,hjust=.5,vjust=.5,face="bold"),axis.title  = element_text(size=15, face="bold"))+
     theme(plot.title=element_text(size=20, face="bold"))+
     coord_flip()

print(p2)
plot_list[[1]] <-p2
ggsave(filename=jpgfilename, plot=p2, width=18,height=8, dpi=300)


for(i in 1:length(measures)) 
{
     
     jpgfilename <- paste(graphpath, statType, "_did_", measures, ".jpg",sep="")
     graphdata <- indata[which(indata$ms_actual==measures[i]),]
     
     #Set up axes and scales depending on the units of each measure 
     graphdata$isBinary <- ifelse(is.element(graphdata$ms_actual,bvars),1,0)
     graphdata$ylab <- ifelse(is.element(graphdata$ms_actual, days_lab),"DiD Estimate (Days)",
                              ifelse(is.element(graphdata$ms_actual, percent_lab),"DiD Estimate (%)",
                                     ifelse(is.element(graphdata$ms_actual, dollar_lab), "DiD Estimate ($)", "NA"))) 
     
     graphdata$pp_did_rate <-ifelse(is.element(graphdata$ms_actual, percent_lab), graphdata$pp_did_rate*100, graphdata$pp_did_rate)

     p<-ggplot(data=graphdata,aes(x= factor(cohort), y=pp_did_rate)) +
          geom_bar(stat="identity", aes(fill=factor(sigFlag)))+
          scale_fill_manual(values=c("#F9A200","#1F3BA1","#E4132B"), name="", guide = guide_legend(direction = "horizontal"))+
          ylab(graphdata$ylab)+
          xlab("")+
          ggtitle(measures[i])+
          #theme(legend.position="none")+
          theme(legend.title=element_text(size=17, face="bold"))+
          theme(legend.text=element_text(size=19))+
          theme(axis.text.x = element_text(colour="grey20",size=15,angle=0,hjust=.5,vjust=.5,face="bold"),axis.title.x = element_text(colour="grey20",size=15,angle=0,hjust=.5,vjust=0,face="bold"), axis.title.y = element_text(colour="grey20",size=15,angle=90,hjust=.5,vjust=.5,face="bold"),axis.title  = element_text(size=15, face="bold"))+
          theme(plot.title=element_text(size=20, face="bold"))+
          theme(axis.text.y=element_blank())+
          theme(axis.ticks.y=element_blank())+
          coord_flip()

     print(p)
     plot_list[[i+1]] <-p
     ggsave(filename=jpgfilename, plot=p, width=18,height=8, dpi=300)
     
}

g_legend <-function(a.gplot){
     tmp <- ggplot_gtable(ggplot_build(a.gplot))
     leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
     legend <- tmp$grobs[[leg]]
     return(legend)}

mylegend<-g_legend(plot_list[[2]])  #Pick a plot that has values from all 3 categories 

png(filename=paste(graphpath,statType,"_SiteLevelMetricsPlot.png", sep=''), width=2000, height=1000)
grid.arrange(arrangeGrob(plot_list[[1]] + theme(legend.position="none"),
                         plot_list[[2]] + theme(legend.position="none"),
                         plot_list[[3]] + theme(legend.position="none"),
                         nrow=1),mylegend, nrow=2,heights=c(10, 1))
dev.off()



          
