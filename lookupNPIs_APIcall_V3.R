require(xlsx)
require(jsonlite)
require(XML)
require(RCurl)
library(plyr)
require(reshape)
#install.packages("dplyr")
require(dplyr)

# Input data (the list of NPI numbers you sent me)
data <- data.frame(read.xlsx("//Econo-file1/users/Shares/ZJ5586B/R/NPIs_to_Check_20161118.xlsx", 1))

output <- data.frame(matrix(nrow= 70000, ncol= 8))
colnames(output) <- c("key", "NPI", "credential", "desc", "license", "primary", "code", "multipleEntriesFlag")
lengths <- list()
outputRow <- 1


for(i in 1:length(data$NPI)){
     
     NPInum <- data$NPI[i]
     
     address <- paste("https://npiregistry.cms.hhs.gov/api/?number=", NPInum, "&enumeration_type=&taxonomy_description=&first_name=&last_name=&organization_name=&address_purpose=&city=&state=&postal_code=&country_code=&limit=&skip=&pretty=on", sep="")
     
     npiData = fromJSON(address)  # this is the output of the API call
     
     taxdata <- data.frame(npiData$results[["taxonomies"]][[1]]) # this is the piece of it we need to get the fields we want
     counter <- nrow(taxdata) # nrow = number of rows; it is, h/e, possible that an NPI w/NO taxonomy data would get counter == 0
     
     #  print(counter)
     
     multipleEntries <- FALSE
     
     if(counter > 1){multipleEntries <- TRUE}
     
     queryRow <- 1
     
     if(counter == 0){
          
          print("counter == 0")
          
          output$key[outputRow] <- i
          
          output$NPI[outputRow] <- NPInum
          output$multipleEntriesFlag[outputRow] <- multipleEntries
          credential <- npiData$results[["basic"]][["credential"]]
          
          if(length(credential) >0){
               output$credential[outputRow] <- credential
          }
          else{
               output$credential[outputRow] <- "Missing"
          }
          output$desc[outputRow] <- "Missing"
          output$license[outputRow] <- "Missing"
          output$primary[outputRow] <- "Missing"
          output$code[outputRow] <- "Missing"

          outputRow <- outputRow + 1
     }
     
     else if(counter > 0){
     
          while(counter > 0){
               
               output$key[outputRow] <- i
               
               output$NPI[outputRow] <- NPInum
               output$multipleEntriesFlag[outputRow] <- multipleEntries
               
               credential <- npiData$results[["basic"]][["credential"]]
               
               desc <- taxdata$desc[queryRow]
               license <- taxdata$license[queryRow]
               primary <- taxdata$primary[queryRow]
               code <- taxdata$code[queryRow]
               
               queryRow <- queryRow + 1
               
               if(length(credential) >0){
                    output$credential[outputRow] <- credential
               }
               else{
                    output$credential[outputRow] <- "Missing"
               }
               
               
               if(length(desc) >0){
                    output$desc[outputRow] <- desc
               }
               
               else{
                    output$desc[outputRow] <- "Missing"
               }
               
               
               if(length(license)>0){
                    output$license[outputRow] <- license
               }
               
               else{
                    output$license[outputRow] <- "Missing"
               }
               
               
               if(length(primary) >0){
                    output$primary[outputRow] <- primary
                    # print(length(npiData$results[["taxonomies"]][[1]][["primary"]]))
               }
               
               else{
                    output$primary[outputRow] <- "Missing"
               }
               
               if(length(code) >0){
                    output$code[outputRow] <- code
               }
               else{
                    output$code[outputRow] <- "Missing"
               }
               
               counter <- counter - 1
               outputRow <- outputRow + 1
          }
     }
     
}




write.csv(output, "//Econo-file1/users/Shares/ZJ5586B/R/NPIs_to_Check_2016121_output_v3.csv")



output2 <- output %>%
     group_by(NPI, credential, code) %>%
     summarise(license=paste((unique(license)), primary=primary, collapse=' '))

write.csv(output2, "//Econo-file1/users/Shares/ZJ5586B/R/NPIs_to_Check_2016121_checkCodes.csv")

creds = count(output, "credential")
creds[order(-creds$freq),]

