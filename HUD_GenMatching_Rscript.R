#    createdBy: Christine Herlihy           #
#    lastModified: 20150914                 #
#    lastUpdate:                            #
#    Description:                           #
#-------------------------------------------#

#install.packages("sas7bdat")
#install.packages("Matching", dependencies=TRUE)


#initiate sas7bdat library for reading in foreign file
library(sas7bdat)
library("Matching")
#library(gmodels)

#read in SAS DS with the read.sas7bsdat() function
radDS = read.sas7bdat('K:/RAD_Evaluation_2014-2017/Task15/Data/rad_match_data1.sas7bdat')
dim(radDS) # 5581   42

#validate input frame
is.data.frame(radDS) #TRUE

#cross tab; control (i.e., non-RAD) versus RAD
xtabs(~ RAD+RAD, data=radDS)  #5349 non-RAD; 232 RAD; 5581 TOTAL 

#init treatment dummy for the 5,581 (= potential controls + treatment) observations 
radDS$FLAG_TRUE <- rep(0,5581)

#Assign a binary value for all 232 RAD projects versus non-RAD projects in sample 
radDS$FLAG_TRUE <-  radDS$RAD==1 
radDS$FLAG_TRUE <- radDS$FLAG_TRUE * 1 #everywhere that the flag == true, puts a 1 instead of TRUE

#test flag
xtabs(~ FLAG_TRUE, data=radDS)
summary(radDS)

#Subset the dataframe so we only keep columns of the vars we want to balance on 
radDS_NAout_KeyVars <-subset(radDS, select=c(ACC_UNIT_CNT, p_1_2BR,PHA_size_code, PASS_Score, Vacant_Rate, vacancy_rt,  Percent_renters_GRAPI_35__or_mor, Overcrowd_rate_1, Poverty_rate, FLAG_TRUE))
dim(radDS_NAout_KeyVars) #5581    10

radDS<-na.omit(radDS_NAout_KeyVars) #DROP NAs and then rename w/name of original 
dim(radDS_NAout_KeyVars) #5581   10


#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutput1.txt') 

#establish the weighing matrix with relevant variable columns
#DR's original: 
# x <- cbind(radDS$ACC_UNIT_CNT, radDS$BLDG_TYPE_CODE,radDS$DEV_TYPE_CODE,radDS$DOFA,radDS$PERCENT_1_2_BED,radDS$PHA_SIZE_CODE,radDS$Rounded_Inspection_score,radDS$VACANCY_RATE,radDS$cost_burden_rate,radDS$overcrowd_rate,radDS$poverty_rate,radDS$renter_rate,radDS$vacant_rate )#deparse.level=2)
#x_vector <- c("ACC_UNIT_CNT", "p_1_2BR", "PHA_size_code", "PASS_Score", "Vacant_Rate", "vacancy_rt",  "Percent_renters_GRAPI_35__or_mor", "Overcrowd_rate_1", "Poverty_rate")
x <- cbind(radDS$ACC_UNIT_CNT,radDS$p_1_2BR,radDS$PHA_size_code,radDS$PASS_score, radDS$Vacant_Rate, radDS$vacancy_rt,radDS$Percent_renters_GRAPI_35__or_mor,radDS$Overcrowd_rate_1,radDS$Poverty_rate)#deparse.level=2)

#establish balanceMatrix for the actual model
BalanceMatrix <- cbind(radDS$ACC_UNIT_CNT,radDS$p_1_2BR,radDS$PHA_size_code,radDS$PASS_score, radDS$Vacant_Rate, radDS$vacancy_rt,radDS$Percent_renters_GRAPI_35__or_mor,radDS$Overcrowd_rate_1,radDS$Poverty_rate) #deparse.level = 2)#deparse.level=2)

#CHECK for missing values
# bool1 <- any(is.na(radDS))   
# bool2<-any(is.na(x))
# bool3<-any(is.na(BalanceMatrix))

#checkSum <- (bool1 + bool2 + bool3) #Should sum to 0 if there are no NAs

#If NAs exist, this code will help to identify which variable(s) are the source and how these impact the control and treatment pops
# if(checkSum != 0){
#      
#      #drop ALL NAs from the radDS and see how many are left
#      radDS_DROPNA <-na.omit(radDS)
#      dim(radDS_DROPNA) #4944   43
#      
#      radDF_RAD_ONLY_ORIG <- radDS[which(radDS$FLAG_TRUE==1),]
#      radDF_RAD_ONLY_DROPNA <-na.omit(radDF_RAD_ONLY_ORIG) #keep 174 out of original 232
#      
#      radDF_NON_RAD_ORIG <- radDS[which(radDS$FLAG_TRUE==0),]
#      radDF_NON_RAD_DROPNA <-na.omit(radDF_NON_RAD) #keep 4770 out of original 5349
#      
#      checkVarsALL <- sapply(radDS_DROPNA, function(x) sum(is.na(x))) #for entire sample
#      checkVarsRAD <- sapply(radDF_RAD_ONLY_DROPNA, function(x) sum(is.na(x))) #for RAD only
#      checkVarsNON_RAD <-sapply(radDF_NON_RAD_DROPNA, function(x) sum(is.na(x))) # for non-RAD only 
#      assessImpactNA <-data.frame(matrix(ncol = 4, nrow=length(checkVarsALL)))
#      colnames(assessImpactNA) <-c("Index","Total_NAs_WHOLE_SAMPLE", "RAD_NA_Count", "NON_RAD_NA_Count")
#      
#      for(i in 1:length(checkVarsALL))
#       {
# 
#           a<- (checkVarsALL[i] - radDF_NON_RAD_DROPNA[i])
#           b<- (checkVarsALL[i] - radDF_RAD_ONLY_DROPNA[i])
#           
#           assessImpactNA$Index[i] <- i
#           assessImpactNA$Total_NAs_WHOLE_SAMPLE[i] <- checkVarsALL[i]
#           assessImpactNA$RAD_NA_Count[i] <-a
#           assessImpactNA$NON_RAD_NA_Count[i] <-b
#           #print(paste(checkVarsALL[i], a, b))
#      }
#      
#      print(assessImpactNA)
# 
#      
# } else{
#      if (checkSum == 0){
    
     #TR = vector for the treatment indicator = FLAG_TRUE for this DS 
     #X = covariates that we will match on 
     #balanceMatrix = the variables we want to achieve balance on
     #M = the number of matches; here, 1:4
     #replace: boolean; here TRUE, for w/replacement 
     gen1 <- GenMatch(Tr = radDS$FLAG_TRUE, X = x, BalanceMatrix = BalanceMatrix, M=4, pop.size = 7000, ties=TRUE, replace=TRUE)

     
     #Generate output 
     
     #running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
     #run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
     mgen1 <- Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=gen1)
     summary(mgen1)
     mbgen1 <- MatchBalance(radDS$ACC_UNIT_CNT,radDS$p_1_2BR,radDS$PHA_size_code,radDS$PASS_score, radDS$Vacant_Rate, radDS$vacancy_rt,radDS$Percent_renters_GRAPI_35__or_mor,radDS$Overcrowd_rate_1,radDS$Poverty_rate, data=radDS, match.out=mgen1, nboots=1000)
     
     mlob1 <-Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
     summary(mlob1)
     mblob1 <- MatchBalance(radDS$ACC_UNIT_CNT,radDS$p_1_2BR,radDS$PHA_size_code,radDS$PASS_score, radDS$Vacant_Rate, radDS$vacancy_rt,radDS$Percent_renters_GRAPI_35__or_mor,radDS$Overcrowd_rate_1,radDS$Poverty_rate, data=radDS, match.out=mlob1, nboots=1000)
     
     
     #redirect output back to console
     sink()
     #unlink('~/CH_RAD-GenMatchingOutput1.txt')
     #unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')
     
     summary(gen1)
     
     #SHOULD SEE: 24 treated, 96 matched
     summary(mgen1)
     summary(mlob1)
#} #close if 
#} #close else 



#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mgen1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mgen1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$Project_ID[ds[,1]])
df[,2] <- as.character(radDS$Project_ID[ds[,2]])
df[,3] <- as.character(radDS$Project_ID[ds[,3]])
df[,4] <- as.character(radDS$Project_ID[ds[,4]])
df[,5] <- as.character(radDS$Project_ID[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/CH_RAD-GenMatchingOutputMatrix.csv', sep=",")

############ mahanolobas

#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mlob1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mlob1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$Project_ID[ds[,1]])
df[,2] <- as.character(radDS$Project_ID[ds[,2]])
df[,3] <- as.character(radDS$Project_ID[ds[,3]])
df[,4] <- as.character(radDS$Project_ID[ds[,4]])
df[,5] <- as.character(radDS$Project_ID[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/CH_RAD-GenMatchingOutputMatrix.csv2', sep=",") #https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/write.matrix.html

#----------------------------------------------------------------------------------------------------------------#

##OLD code: 

#yes, attach() can be dangerous but i will be super careful  
#names(radDS)   #https://stat.ethz.ch/R-manual/R-devel/library/base/html/  
#attach(radDS) #http://www.r-bloggers.com/to-attach-or-not-attach-that-is-the-question/  ;; https://stat.ethz.ch/R-manual/R-devel/library/base/html/attach.html

#attach alters the R search path. be careful w/var names (esp. global ones) and detach when done. 


#summary(radDS)


#sink(file='C:\\Users\\druiz\\Dropbox\\RAD\\acc.txt')
#sink(file='~/CH_RAD_code_template.txt')  #https://stat.ethz.ch/R-manual/R-devel/library/base/html/sink.html  #sinks output to specified file 

#establish the weighing matrix with relevant variable columns
x <- cbind(radDS$ACC_UNIT_CNT, radDS$BLDG_TYPE_CODE,radDS$DEV_TYPE_CODE,radDS$DOFA,radDS$PERCENT_1_2_BED,radDS$PHA_SIZE_CODE,radDS$Rounded_Inspection_score,radDS$VACANCY_RATE,radDS$cost_burden_rate,radDS$overcrowd_rate,radDS$poverty_rate,radDS$renter_rate,radDS$vacant_rate )#deparse.level=2)

#establish balanceMatrix for the actual model
BalanceMatrix <- cbind(radDS$ACC_UNIT_CNT, radDS$BLDG_TYPE_CODE,radDS$DEV_TYPE_CODE,radDS$DOFA,radDS$PERCENT_1_2_BED,radDS$PHA_SIZE_CODE,radDS$Rounded_Inspection_score,radDS$VACANCY_RATE,radDS$cost_burden_rate,radDS$overcrowd_rate,radDS$poverty_rate,radDS$renter_rate,radDS$vacant_rate )#deparse.level=2)

#Check for missing values 
any(is.na(radDS$FLAG_TRUE))  #https://stat.ethz.ch/R-manual/R-devel/library/base/html/any.html
any(is.na(x))
any(is.na(BalanceMatrix))

gen1 <- GenMatch(Tr = radDS$FLAG_TRUE, X = x, BalanceMatrix = BalanceMatrix, M=4, pop.size = 7000, ties=TRUE, replace=FALSE)
#TR = vector for the treatment indicator = FLAG_TRUE for this DS 
#X = covariates that we will match on 
#balanceMatrix = the variables we want to achieve balance on

#outputs 

#running MATCH is not necessary since I do not care about causal inference; this matching is for site visits apparently 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, no-replacement
mgen1 <- Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=FALSE, ties=TRUE, Weight=3, Weight.matrix=gen1)
summary(mgen1)
mbgen1 <- MatchBalance(radDS$FLAG_TRUE~radDS$ACC_UNIT_CNT + radDS$BLDG_TYPE_CODE + radDS$DEV_TYPE_CODE + radDS$DOFA + radDS$PERCENT_1_2_BED + radDS$PHA_SIZE_CODE + radDS$Rounded_Inspection_score + radDS$VACANCY_RATE + radDS$cost_burden_rate + radDS$overcrowd_rate + radDS$poverty_rate + radDS$renter_rate + radDS$vacant_rate, data=radDS, match.out=mgen1, nboots=1000)

mlob1 <-Match(Tr=radDS$FLAG_TRUE, X=x, M=4, replace=FALSE, ties=TRUE, Weight=2)
summary(mlob1)
mblob1 <- MatchBalance(radDS$FLAG_TRUE~radDS$ACC_UNIT_CNT + radDS$BLDG_TYPE_CODE + radDS$DEV_TYPE_CODE + radDS$DOFA + radDS$PERCENT_1_2_BED + radDS$PHA_SIZE_CODE + radDS$Rounded_Inspection_score + radDS$VACANCY_RATE + radDS$cost_burden_rate + radDS$overcrowd_rate + radDS$poverty_rate + radDS$renter_rate + radDS$vacant_rate, data=radDS, match.out=mlob1, nboots=1000)


#redirect output back to console
sink()
#unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')

summary(gen1)

#SHOULD SEE: 24 treated, 96 matched
summary(mgen1)
summary(mlob1)





#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mgen1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mgen1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$development_code[ds[,1]])
df[,2] <- as.character(radDS$development_code[ds[,2]])
df[,3] <- as.character(radDS$development_code[ds[,3]])
df[,4] <- as.character(radDS$development_code[ds[,4]])
df[,5] <- as.character(radDS$development_code[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/Dropbox/Econometrica/RAD/match_rad_gen_150221.csv', sep=",")

############ mahanolobas

#now do some matrix magic to get a simple matrix showing the RAD propertie IDs and their 4 matched counterparts. 
dd = as.numeric(mlob1$index.control)
dim(dd) <- c(4,12)
dd <- t(dd)

dt = as.numeric(mlob1$index.treat)
dim(dt) <- c(4,12)
dt <- t(dt)
ds = cbind(dt[,1],dd)
df = matrix("",nrow=12,ncol=5)

df[,1] <- as.character(radDS$development_code[ds[,1]])
df[,2] <- as.character(radDS$development_code[ds[,2]])
df[,3] <- as.character(radDS$development_code[ds[,3]])
df[,4] <- as.character(radDS$development_code[ds[,4]])
df[,5] <- as.character(radDS$development_code[ds[,5]])

#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_acc.csv', sep=",")
#write.matrix(df,'C:\\Users\\druiz\\Dropbox\\RAD\\match_rad.csv', sep=",")
write.matrix(df,'~/Dropbox/Econometrica/RAD/match_rad_md_150221.csv', sep=",") #https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/write.matrix.html

detach(radDS)  #follow up to attach 


