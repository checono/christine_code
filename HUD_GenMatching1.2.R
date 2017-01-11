
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
radDS = read.sas7bdat('K:/RAD_Evaluation_2014-2017/Task15/Data/rad_match_data1.sas7bdat')
dim(radDS)

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

dim(radDS)  #5119 36

#--------------Model Set A (no logit p-values) ---------------------------------------------------------------------------------------------------------------------#

#A ==NO logit p-values are included 
print("Model set A: No p-values are included; variables included = those from David's original code")
ModelA <- radDS     %>%
     select(Project_ID, RAD, ACC_UNIT_CNT, PHA_size_code, PASS_Score, Vacant_Rate, vacancy_rt, Percent_renters_GRAPI_35__or_mor,  Overcrowd_rate_1_5, Poverty_rate)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(ModelA) 

#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=ModelA)  

#separate matrix by treatment and all other variables 
x <- ModelA %>% select(-RAD, -Project_ID) %>% as.matrix()

#check dimensions
dim(x) 

#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

genA <- GenMatch(Tr = ModelA$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 

#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutput_Model3_ModelsA.txt') 

#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgenA <- Match(Tr=ModelA$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=genA)
summary(mgenA)
mbgenA <- MatchBalance(radDS$RAD ~ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mgenA, nboots=1000)

mlobA <-Match(Tr=ModelA$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlobA)
mblobA<- MatchBalance(radDS$RAD ~  radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mlobA, nboots=1000)


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

#--------------Model Set B (includes logit p-values) ---------------------------------------------------------------------------------------------------------------------#
sink(file='~/CH_RAD-GenMatchingOutput_Model3_ModelsB.txt') 



#B logit p-values ARE included 
print("Model set B: p-values are included; NAs are dropped; variables included = those from David's original code")

#took out TPP 

logit_DenisVars <- glm(RAD ~ m_age + m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC , data=radDS, family = binomial())

summary(logit_logit_DenisVars)
radDS$logitDennisResults  <-logit_DenisVars$fitted.values


#Includes vals from David's original matching code 
ModelB <- radDS     %>%
     select(logitDennisResults, Project_ID, RAD, ACC_UNIT_CNT, PHA_size_code, PASS_Score, Vacant_Rate, vacancy_rt, Percent_renters_GRAPI_35__or_mor,  Overcrowd_rate_1_5, Poverty_rate)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))


dim(ModelB) 

#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=ModelB)  

#separate matrix by treatment and all other variables 
x <- ModelB %>% select(-RAD, -Project_ID) %>% as.matrix()

#check dimensions
dim(x) 

#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

genB <- GenMatch(Tr = ModelB$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 
sink(file='~/CH_RAD-GenMatchingOutput_Model3_ModelsB.txt') 
#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgenB <- Match(Tr=ModelB$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=genB)
summary(mgenB)
mbgenB <- MatchBalance(radDS$RAD ~ m_age +  m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mgenB, nboots=1000)

mlobB <-Match(Tr=ModelB$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlobB)
mblobB<- MatchBalance(radDS$RAD ~ m_age +  m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mlobB, nboots=1000)


# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 
dd = as.numeric(mgenB$index.control)
dim(dd) <- c(4,201) #4 controls for each of the 220 matched RADs
dd <- t(dd)  #transpose the matrix 

dt = as.numeric(mgenB$index.treat)
dim(dt) <- c(4,201) 
dt <- t(dt)

ds = cbind(dt[,1],dd)
df3 = matrix("",nrow=201,ncol=5)

df3[,1] <- as.character(radDS$Project_ID[ds[,1]])
df3[,2] <- as.character(radDS$Project_ID[ds[,2]])
df3[,3] <- as.character(radDS$Project_ID[ds[,3]])
df3[,4] <- as.character(radDS$Project_ID[ds[,4]])
df3[,5] <- as.character(radDS$Project_ID[ds[,5]])

print(df3)
#----------------------------------------------------------------------------------------

# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 

dd4 = as.numeric(mlobB$index.control) 
dim(dd4) <- c(4,201) #4 controls for each of the 220 matched RADs
dd2 <- t(dd4)  #transpose the matrix 

dt4 = as.numeric(mlobB$index.treat)
dim(dt4) <- c(4,201) 
dt4 <- t(dt4)

ds4 = cbind(dt4[,1],dd4)
df4 = matrix("",nrow=201,ncol=5)

df4[,1] <- as.character(radDS$Project_ID[ds2[,1]])
df4[,2] <- as.character(radDS$Project_ID[ds2[,2]])
df4[,3] <- as.character(radDS$Project_ID[ds2[,3]])
df4[,4] <- as.character(radDS$Project_ID[ds2[,4]])
df4[,5] <- as.character(radDS$Project_ID[ds2[,5]])

print(df4)
sink()
#----------------------------------------------------------------------------------------------------------------------------------------------------------------#





#break A# 

