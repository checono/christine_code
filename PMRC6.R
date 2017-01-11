require("stringr")
require("plyr")
require("xlsx")

data <- data.frame(read.csv("BPCI_PMRC6_DataForR.csv"))


for(i in 1:length(data$n)){
     data$DiD[i] <- ""

     temp <- toString(data$A15_pls_PQ910[i])
     temp2 <-substr(temp, 1, 10)
     
     #Check to see if the DiD string contains star(s), and put in appropriate p-value
     if(grepl(pattern="***", temp2,fixed=TRUE)){data$P.value[i]<-"(p<0.01)"}
     else if(grepl(pattern="**", temp2,fixed=TRUE)){data$P.value[i]<-"(p<0.05)"}
     else if(grepl(pattern="*", temp2,fixed=TRUE)){data$P.value[i]<-"(p<0.10)"}
     else(data$P.value[i]<-"")
     
     #Then, get rid of the stars, and deString the DiD value, for plotting
     temp2 <- gsub("*", "", temp2, fixed=TRUE)
     
     data$DiD[i] <-temp2
     
     #Concatenate the alpha ID for the hospital and the pval string 
     data$alpha_and_pval[i]<-paste(data$alphaCode[i], " ", data$P.value[i])
}    

write.xlsx(data, "BPCI_PMRC6_DataForR_Out.xlsx")


