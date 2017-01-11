require(xlsx)
require(jsonlite)
require(XML)
require(RCurl)
library(plyr)

data <- read.xlsx("//Econo-file1/users/Shares/ZJ5586B/R/NPIs_to_Check_20161118.xlsx", 1)

output <- data.frame(matrix( nrow= length(data$NPI), ncol= 6))
colnames(output) <- c("NPI", "credential", "desc", "license", "primary", "code")
lengths <- list()

for(i in 1:length(data$NPI)){

     
     NPInum <- data$NPI[i]
  #   print(NPInum)
 
     address <- paste("https://npiregistry.cms.hhs.gov/api/?number=", NPInum, "&enumeration_type=&taxonomy_description=&first_name=&last_name=&organization_name=&address_purpose=&city=&state=&postal_code=&country_code=&limit=&skip=&pretty=on", sep="")

     npiData = fromJSON(address)
     
  #   print(npiData$results[["taxonomies"]])
   
#      credential <- npiData$results[["basic"]][["credential"]]
#      desc <- npiData$results[["taxonomies"]][[1]][["desc"]]
#      license <- npiData$results[["taxonomies"]][[1]][["license"]]
#      primary <- npiData$results[["taxonomies"]][[1]][["primary"]]
#      code <- npiData$results[["taxonomies"]][[1]][["code"]]

     if(length(npiData$results[["taxonomies"]][[1]][[1]])>0){
          lengths[[i]] <- length(npiData$results[["taxonomies"]][[1]][[1]])
     }
     
     
   #  output$NPI[i] <- NPInum
     
     
     
#      
#      
#      
#      if(length(credential) >0){
#           output$credential[i] <- credential
#      }
#      if(length(desc) >0){
#           output$desc[i] <- desc
#      }
#      if(length(license)>0){
#           output$license[i] <- license
#      }
#      if(length(primary) >0){
#      output$primary[i] <- primary
#     # print(length(npiData$results[["taxonomies"]][[1]][["primary"]]))
#      }
#      
#      if(length(code) >0){
#           output$code[i] <- code
#      }
#      
#      
#      if(length(primary) > 0 & output$primary[i] == FALSE){
#           print("FALSE")
#         #  print(length(npiData$results[["taxonomies"]][[1]][["primary"]]))
#         #  print(length(npiData$results[["taxonomies"]][[1]][["primary"]][[1]]))
#      }
#           
     

}




write.csv(output, "//Econo-file1/users/Shares/ZJ5586B/R/NPIs_to_Check_2016123_output.csv")

creds = count(output, "credential")
creds[order(-creds$freq),]

