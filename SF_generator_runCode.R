require(xlsx)
require(plyr)

#ORDER MATTERS! Input data needs to be in xlsx, with each tab corresponding to 1 hospital ID, in the following order:
prvdrList <- c("310010", "310038", "310110", "310024", "310050", "310070", "310069", "310032", "310081", "310019", "310006", "170183")
hospList <-c("UMCPP","RWJUH","RWJUHamilton", "RWJURahway", "SCH","SPUH" ,"IMCElmer", "IMCVineland", "IMCWoodbury","SJRMC" , "SMHP", "KSRC")
test <- data.frame(read.xlsx("K:/CMS/Bundle Payments/3.Deliverables/Task 5_3 Preparation of Site FB Reports/Site Feedback Reports #6/data/SF_Tables_160204.xlsx", 4))




for(i in 1:length(prvdrList)){
     
tempName <- paste(prvdrList[i], "_test.Rmd", sep="")  
print(tempName)
rmarkdown::render("//Econo-file1/users/Shares/ZJ5586B/R/SF_generator_Test.Rmd", params = list(hospital = prvdrList[i], data=test),
output_file =  paste(prvdrList[i], "_test_.docx", sep=''), 
output_dir = '//Econo-file1/users/Shares/ZJ5586B/R/RmdTest')
}
