
#--------------Set up-----------------------------------------------------------------------------------------------------------------------------------------------#

install.packages("sas7bdat")
install.packages("Matching", dependencies=TRUE)
install.packages("dplyr")
install.packages("stats")

#initiate sas7bdat library for reading in foreign file
library("sas7bdat")
library("Matching")
library("dplyr")
library("stats")

#read in SAS DS with the read.sas7bsdat() function
radDS = read.sas7bdat('K:/RAD_Evaluation_2014-2017/Task15/Data/rad_balanced1b.sas7bdat')
dim(radDS) #6488   43

checkVarsALL <- data.frame(sapply(radDS, function(x,y) sum(is.na(x))), y=colnames(radDS))#for entire sample
write.matrix(checkVarsALL ,'~/GetNACounts.csv', sep=",")
FortyThreeNA_OrLess<- data.frame(checkVarsALL[which(checkVarsALL[1]<=43),])
dim(FortyThreeNA_OrLess) # 35; includes RAD 
write.matrix(FortyThreeNA_OrLess ,'~/CH_RAD-Vars_43NAs_OrLess.csv', sep=",")

#cross tab; control (i.e., non-RAD) versus RAD
xtabs(~ RAD, data=radDS)  

#Subset the data frame to select only cols w/ <=43 NAs; omit NAs from the remaining cols 
radDS <- radDS     %>%
     select(RAD, Project_ID, p_Elder, m_TTP, p_Black, p_Disabled,p_Single, m_adj_inc, m_members,m_BRs,m_age,st,ZIP_c,TOTAL_UNIT_CNT, ACC_UNIT_CNT, cap_fund,PASS_Score,bldg_age,scattered,p_ACC,p_Elder_dev,
            vacancy_rt,pers_per_BR,PHA_size_code,Vacant_Rate,Percent_renters_GRAPI_35__or_mor,Percent_White_Asian,Percent_Black,Percent_HISPANIC,
            Poverty_rate,LFPR_,U_,Mean_household_income,Median_household_income, Overcrowd_rate_1, Overcrowd_rate_1_5) %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(radDS)  #5799   36

#--------------Model Set A (no logit p-values) ---------------------------------------------------------------------------------------------------------------------#

#A ==NO logit p-values are included 
print("Model set A: No p-values are included; variables included = those from David's original code")
ModelA <- radDS     %>%
     select(Project_ID, RAD, m_adj_inc, p_Black, p_Disabled, p_Elder, p_Single, PASS_Score, m_BRs, vacancy_rt, Overcrowd_rate_1, Percent_Black, Percent_HISPANIC, Vacant_Rate)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(ModelA) #5799   14

#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=ModelA)  

#separate matrix by treatment and all other variables 
x <- ModelA %>% select(-RAD, -Project_ID) %>% as.matrix()

#check dimensions
dim(x) #5799   12

#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

genA <- GenMatch(Tr = ModelA$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 

#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutput_1.3_9_24.txt') 

#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgenA <- Match(Tr=ModelA$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=genA)
summary(mgenA)
mbgenA <- MatchBalance(ModelA$RAD ~ ModelA$m_adj_inc+ ModelA$p_Black + ModelA$p_Disabled+ ModelA$p_Elder + ModelA$p_Single + ModelA$PASS_Score + ModelA$m_BRs + ModelA$vacancy_rt + ModelA$Overcrowd_rate_1 + ModelA$Percent_Black + ModelA$Percent_HISPANIC + ModelA$Vacant_Rate, data=ModelA, match.out=mgenA, nboots=1000)

mlobA <-Match(Tr=ModelA$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlobA)
mblobA<- MatchBalance(ModelA$RAD ~ ModelA$m_adj_inc+ ModelA$p_Black + ModelA$p_Disabled+ ModelA$p_Elder + ModelA$p_Single + ModelA$PASS_Score + ModelA$m_BRs + ModelA$vacancy_rt + ModelA$Overcrowd_rate_1 + ModelA$Percent_Black + ModelA$Percent_HISPANIC + ModelA$Vacant_Rate, data=ModelA, match.out=mlobA, nboots=1000)





sink(file='~/CH_RAD-GenMatchingOutput_1.3_9_24_PAIRS.txt')
length(mgenA$index.treated)
length(mgenA$index.control)


# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 
ddA = as.numeric(mgenA$index.control)
dim(ddA) <- c(4,201) #4 controls for each of the 220 matched RADs
ddA <- t(ddA)  #transpose the matrix 

dtA = as.numeric(mgenA$index.treat)
dim(dtA) <- c(4,201) 
dtA <- t(dtA)

dsA = cbind(dtA[,1],ddA)
dfA = matrix("",nrow=201,ncol=5)

dfA[,1] <- as.character(radDS$Project_ID[dsA[,1]])
dfA[,2] <- as.character(radDS$Project_ID[dsA[,2]])
dfA[,3] <- as.character(radDS$Project_ID[dsA[,3]])
dfA[,4] <- as.character(radDS$Project_ID[dsA[,4]])
dfA[,5] <- as.character(radDS$Project_ID[dsA[,5]])

print(dfA)
#----------------------------------------------------------------------------------------

# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 

ddA2 = as.numeric(mlobA$index.control)
dim(ddA2) <- c(4,201) #4 controls for each of the 220 matched RADs
ddA2 <- t(ddA2)  #transpose the matrix 

dtA2 = as.numeric(mlobA$index.treat)
dim(dtA2) <- c(4,201) 
dtA2 <- t(dtA2)

dsA2 = cbind(dtA2[,1],ddA2)
dfA2 = matrix("",nrow=201,ncol=5)

dfA2[,1] <- as.character(radDS$Project_ID[ds2[,1]])
dfA2[,2] <- as.character(radDS$Project_ID[ds2[,2]])
dfA2[,3] <- as.character(radDS$Project_ID[ds2[,3]])
dfA2[,4] <- as.character(radDS$Project_ID[ds2[,4]])
dfA2[,5] <- as.character(radDS$Project_ID[ds2[,5]])

print(dfA2)

sink()
