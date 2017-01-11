#    For each year, we want the hospital-level medicare spending per patient data. 
#    This data is indexed relative to the national average; thus, for each year, need to multiply each hospital's "score" value 
#    by the national average to get a dollar amount 

#    2012-2015

#    Medicare Hospital Spending Per Patient - Hospital level 
#    Source: https://data.medicare.gov/data/archives/hospital-compare


#install.packages("plyr") #import plyr
setwd("//Econo-file1/users/Shares/ZJ5586B/Medicare_Spending_Hospital_and_NationalData") #remember to reverse the backslash for windows path names

#HOSPITAL-LEVEL DATA (2012) from archive

hospitalLevelSpending12DF <- data.frame(read.csv("Medicare_Spending_Per_Patient_Hospital_from2012Archived.csv")) #read in as DF
names(hospitalLevelSpending12DF)[names(hospitalLevelSpending12DF) == "Spending.per.Hospital.Patient.with.Medicare"] <- "Score" #rename column
typeof(hospitalLevelSpending12DF$Score) #check type; = integer
numericHospScores12 <- as.numeric(as.character(hospitalLevelSpending12DF$Score)) #cast integer to double
hospitalLevelSpending12DF$NumericScore <- numericHospScores12 #add numeric values to DF as new column

hist(hospitalLevelSpending12DF$NumericScore) #histogram of scores
mean(hospitalLevelSpending12DF$NumericScore, na.rm=TRUE)   # = 0.9829414
summary.data.frame(hospitalLevelSpending12DF) #summarize dataframe

#2012 national average for 2012 is "number of cases" by diagnosis type; there is no national average payment metric on CMS site

#--------------------------------------------------------------------------------------------------------------------------#


#HOSPITAL-LEVEL DATA (2013) from archive

hospitalLevelSpending13DF <-data.frame(read.csv("Medicare_Spending_Per_Patient_Hospital_from2013Archived.csv")) #import csv file
names(hospitalLevelSpending13DF)[names(hospitalLevelSpending13DF) == "Spending.per.Hospital.Patient.with.Medicare"] <- "Score" #rename column
typeof(hospitalLevelSpending13DF$Score) #check type; = integer
numericHospScores13 <- as.numeric(as.character(hospitalLevelSpending13DF$Score)) #cast integer to double
hospitalLevelSpending13DF$NumericScore <- numericHospScores13 #add numeric values to DF as new column
hist(hospitalLevelSpending13DF$NumericScore) #plot histogram 

mean(hospitalLevelSpending13DF$NumericScore, na.rm=TRUE)
summary.data.frame(hospitalLevelSpending13DF)

#2013 national averag payment is an indexed value; no dollar value on CMS site

#--------------------------------------------------------------------------------------------------------------------------#

#HOSPITAL-LEVEL DATA (2014) from archive

hospitalLevelSpending14DF <- data.frame(read.csv("Medicare_Spending_Per_Patient_Hospital_from2014Archived.csv"))


typeof(hospitalLevelSpending14DF$Score) #check type; = integer
numericHospScores14 <- as.numeric(as.character(hospitalLevelSpending14DF$Score)) #cast integer to double
hospitalLevelSpending14DF$NumericScore <- numericHospScores14 #add numeric values to DF as new column
hist(hospitalLevelSpending13DF$NumericScore) #plot histogram

mean(hospitalLevelSpending14DF$NumericScore, na.rm=TRUE) # = 0.9847609
medicareSpendingNational14 <- data.frame(read.csv("MedicareSpendingNational14.csv"))

#I converted the national median from currency to regular number type in the original excel file 
#Medicare national spending for 2014 has a value for score of 0.98 (?) and a national median in dollars of $19,546.98

nationalMedian14Num <- as.numeric(as.character(medicareSpendingNational14$National.Median)) #a double
hospitalLevelSpending14DF$ScoreInDollars <- (hospitalLevelSpending14DF$NumericScore * nationalMedian14Num) #multiply each hospital's indexVal by ntlMedian
      
summary.data.frame(hospitalLevelSpending14DF) #summary stats
hist(hospitalLevelSpending14DF$ScoreInDollars) #plot

#--------------------------------------------------------------------------------------------------------------------------#

#HOSPITAL-LEVEL DATA (2015) from archive
hospitalLevelSpending15DF <- data.frame(read.csv("Medicare_Spending_Per_Patient_Hospital_from2015Archived.csv"))


typeof(hospitalLevelSpending15DF$Score) #check type; = integer
numericHospScores15 <- as.numeric(as.character(hospitalLevelSpending15DF$Score)) #cast integer to double
hospitalLevelSpending15DF$NumericScore <- numericHospScores15 #add numeric values to DF as new column
hist(hospitalLevelSpending15DF$NumericScore) #plot histogram

mean(hospitalLevelSpending15DF$NumericScore, na.rm=TRUE) # =0.9847619
medicareSpendingNational15 <- data.frame(read.csv("MedicarSpendingNational15.csv"))
nationalMedian15Num <- as.numeric(as.character(medicareSpendingNational15$National.Median)) #a double
hospitalLevelSpending15DF$ScoreInDollars <- (hospitalLevelSpending15DF$NumericScore * nationalMedian15Num) #multiply each hospital's indexVal by ntlMedian

summary.data.frame(hospitalLevelSpending15DF) #summary stats
hist(hospitalLevelSpending15DF$ScoreInDollars) #plot


#--------------------------------------------------------------------------------------------------------------------------#

#MEDICARE HOSPITAL SPENDING BY CLAIM (2014) from archive; start/end dates are for calendar year 2013

spendByClaim14DF <- data.frame(read.csv("MedicareHosSpendbyClaim14.csv"))

#get number of unique provider IDs in original dataset
numUniqueIDs<- length((unique(spendByClaim14DF$Provider.Number))) # = 3230

#select subset of original DF where the period = during index hospital admin and claim type = inpatient 
smallSpendClaimDF14 <- spendByClaim14DF[which(spendByClaim14DF$Period=='During Index Hospital Admission' & spendByClaim14DF$Claim.Type=='Inpatient'), ]

length(smallSpendClaimDF14$Provider.Number) #should be equal to numUniqueIDs

smallSpendClaimDF14$Avg.Spending.Per.Episode..Hospital. <- as.numeric(as.character(smallSpendClaimDF14$Avg.Spending.Per.Episode..Hospital.)) #cast from int to double
smallSpendClaimDF14$Avg.Spending.Per.Episode..State. <- as.numeric(as.character(smallSpendClaimDF14$Avg.Spending.Per.Episode..State.)) #cast from int to double
smallSpendClaimDF14$Avg.Spending.Per.Episode..Nation. <- as.numeric(as.character(smallSpendClaimDF14$Avg.Spending.Per.Episode..Nation.)) #cast from int to double

summary.data.frame(smallSpendClaimDF14) #avg. spending per episode (national) will be same for all entries 


#--------------------------------------------------------------------------------------------------------------------------#

#MEDICARE HOSPITAL SPENDING BY CLAIM (2015) from archive; start/end dates are ALSO for calendar year 2013 (this section = identical to above section)

spendByClaim15DF <- data.frame(read.csv("MedicareHosSpendbyClaim15.csv"))

#get number of unique provider IDs in original dataset
numUniqueIDsB<- length((unique(spendByClaim15DF$Provider.Number))) # = 

#select subset of original DF where the period = during index hospital admin and claim type = inpatient 
smallSpendClaimDF15 <- spendByClaim15DF[which(spendByClaim15DF$Period=='During Index Hospital Admission' & spendByClaim14DF$Claim.Type=='Inpatient'), ]

length(smallSpendClaimDF15$Provider.Number) #should be equal to numUniqueIDs

smallSpendClaimDF15$Avg.Spending.Per.Episode..Hospital. <- as.numeric(as.character(smallSpendClaimDF15$Avg.Spending.Per.Episode..Hospital.)) #cast from int to double
smallSpendClaimDF15$Avg.Spending.Per.Episode..State. <- as.numeric(as.character(smallSpendClaimDF15$Avg.Spending.Per.Episode..State.)) #cast from int to double
smallSpendClaimDF15$Avg.Spending.Per.Episode..Nation. <- as.numeric(as.character(smallSpendClaimDF15$Avg.Spending.Per.Episode..Nation.)) #cast from int to double

summary.data.frame(smallSpendClaimDF15) #avg. spending per episode per nation will be same for all entries 


