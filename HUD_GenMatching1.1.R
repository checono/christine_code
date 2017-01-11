
install.packages("sas7bdat")
install.packages("Matching", dependencies=TRUE)
install.packages("dplyr")

#initiate sas7bdat library for reading in foreign file
library("sas7bdat")
library("Matching")
library("dplyr")

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

#run logit on ALL variables 
dim(radDS) #5507   35

logit_allVars <- glm(RAD ~ p_Elder+ Project_ID + p_Black + p_Disabled + p_Single +m_adj_inc+ m_members+m_BRs+m_age+st+ZIP_c+TOTAL_UNIT_CNT+ACC_UNIT_CNT+ cap_fund+PASS_Score+bldg_age+scattered+p_ACC+p_Elder_dev+
                     vacancy_rt+pers_per_BR+PHA_size_code+Vacant_Rate+Percent_renters_GRAPI_35__or_mor+Percent_White_Asian+Percent_Black+Percent_HISPANIC+
                     Poverty_rate+LFPR_+U_+Mean_household_income+Median_household_income+ Overcrowd_rate_1+ Overcrowd_rate_1_5, data=radDS, family = binomial())

summary(logit_allVars)
radDS$logitResults  <-logit_allVars$fitted.values

corrDf <-cor(radDS)
write.matrix(corrDf ,'~/CH_RAD-CorrelationMatrix2.csv', sep=",")

#select only the variables that are needed for matching


#----------------------------------Model 1: Includes 23 vars------------------------------------------------------------------------------------------#

#I included the ones highlighted by Dennis, excluding any for which we had more than 43 NAs. I also included logit results. Total #vars=23 
z <- radDS     %>%
     select(logitResults, Project_ID, RAD, bldg_age, m_age, m_BRs, m_members, Median_household_income, Overcrowd_rate_1_5, p_ACC, p_Black, p_Disabled, p_Elder, p_Elder_dev, p_Single, PASS_Score, Percent_Black, Percent_HISPANIC, Percent_renters_GRAPI_35__or_mor, pers_per_BR, Poverty_rate,vacancy_rt, Vacant_Rate)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(z) #5507   23


#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=z)  #5287  220 

#separate matrix by treatment and all other variable 
x  <- z %>% select(-RAD) %>% as.matrix()


#check dimensions
dim(x) #5507   22 


#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutputSep21.txt') 


#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

gen1 <- GenMatch(Tr = z$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 

#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgen1 <- Match(Tr=z$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=gen1)
summary(mgen1)
mbgen1 <- MatchBalance(logitResults, Project_ID, RAD, bldg_age, m_age, m_BRs, m_members, Median_household_income, Overcrowd_rate_1_5, p_ACC, p_Black, p_Disabled, p_Elder, p_Elder_dev, p_Single, PASS_Score, Percent_Black, Percent_HISPANIC, Percent_renters_GRAPI_35__or_mor, pers_per_BR, Poverty_rate,vacancy_rt, Vacant_Rate, data=radDS, match.out=mgen1, nboots=1000)

mlob1 <-Match(Tr=z$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlob1)
mblob1 <- MatchBalance(logitResults, Project_ID, RAD, bldg_age, m_age, m_BRs, m_members, Median_household_income, Overcrowd_rate_1_5, p_ACC, p_Black, p_Disabled, p_Elder, p_Elder_dev, p_Single, PASS_Score, Percent_Black, Percent_HISPANIC, Percent_renters_GRAPI_35__or_mor, pers_per_BR, Poverty_rate,vacancy_rt, Vacant_Rate, data=radDS, match.out=mlob1, nboots=1000)


#redirect output back to console
sink()
#unlink('~/CH_RAD-GenMatchingOutput1.txt')
#unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')

summary(gen1)
matches(gen1)

#SHOULD SEE: 24 treated, 96 matched
summary(mgen1)
summary(mlob1)

#----------------------------------Model 2: Top 10 most highly correlated (in abs val terms) ------------------------------------------------------------------------------------------#

#Includes the top ten vars that are most correlated (in abs val terms) w/ RAD
Model2 <- radDS     %>%
     select(logitResults, Project_ID, RAD, p_ACC, p_Black, PASS_Score, Percent_Black,Percent_renters_GRAPI_35__or_mor, vacancy_rt, st, Percent_White_Asian)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(Model2) 


#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=Model2)  

#separate matrix by treatment and all other variable 
x <- Model2 %>% select(-RAD) %>% as.matrix()


#check dimensions
dim(x) 


#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutput_Model2_Sep21.txt') 


#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

gen2 <- GenMatch(Tr = Model2$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 

#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgen2 <- Match(Tr=Model2$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=gen2)
summary(mgen2)
mbgen2 <- MatchBalance(radDS$RAD~radDS$ACC_UNIT_CNT+ radDS$p_1_2BR+ radDS$PHA_size_code+radDS$PASS_score+ radDS$Vacant_Rate+ radDS$vacancy_rt+radDS$Percent_renters_GRAPI_35__or_mor+radDS$Overcrowd_rate_1+radDS$Poverty_rate, data=radDS, match.out=mgen2, nboots=1000)

mlob2 <-Match(Tr=Model2$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlob2)
mblob2 <- MatchBalance(radDS$ACC_UNIT_CNT,radDS$p_1_2BR,radDS$PHA_size_code,radDS$PASS_score, radDS$Vacant_Rate, radDS$vacancy_rt,radDS$Percent_renters_GRAPI_35__or_mor,radDS$Overcrowd_rate_1,radDS$Poverty_rate, data=radDS, match.out=mlob2, nboots=1000)


#redirect output back to console
sink()
#unlink('~/CH_RAD-GenMatchingOutput1.txt')
#unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')

summary(gen2)
matches(gen2)

#SHOULD SEE: 24 treated, 96 matched
summary(mgen2)
summary(mlob2)
#----------------------------------Model 3: David's original vals  ------------------------------------------------------------------------------------------#

logit_DenisVars <- glm(RAD ~ m_age + m_TPP+ m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC , data=radDS, family = binomial())

summary(logit_logit_DenisVars)
radDS$logitDennisResults  <-logit_DenisVars$fitted.values


#Includes vals from David's original matching code 
Model3 <- radDS     %>%
     select(logitDennisResults, Project_ID, RAD, ACC_UNIT_CNT, PHA_size_code, PASS_Score, Vacant_Rate, vacancy_rt, Percent_renters_GRAPI_35__or_mor,  Overcrowd_rate_1_5, Poverty_rate)  %>%
     na.omit()     %>%
     mutate_each(funs(as.numeric))

dim(Model3) 


#check to see how many RAD and Non-RAD remain based on the above variable selection
xtabs(~ RAD, data=Model3)  

#separate matrix by treatment and all other variable 
x <- Model3 %>% select(-RAD, -Project_ID) %>% as.matrix()


#check dimensions
dim(x) 


#sink file so that output can later be retrieved 
sink(file='~/CH_RAD-GenMatchingOutput_Model3_Sep21.txt') 


#establish balanceMatrix for the actual model
BalanceMat <- as.matrix(x)

gen3 <- GenMatch(Tr = Model3$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

#Generate output 

#running MATCH is not necessary since I do not care about causal inference; this matching is for analytic purposes 
#run the match WITHOUT an outcome that uses genMatch weighting matrix; kept all parameters - e.g., 4 controls per treatment, deterministic ties, replacement
mgen3 <- Match(Tr=Model3$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=gen3)
summary(mgen3)
mbgen3 <- MatchBalance(radDS$RAD ~ m_age + m_TPP+ m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mgen3, nboots=1000)

mlob3 <-Match(Tr=Model3$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
summary(mlob3)
mblob3 <- MatchBalance(radDS$RAD ~ m_age + m_TPP+ m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mlob3, nboots=1000)


#redirect output back to console
sink()
#unlink('~/CH_RAD-GenMatchingOutput1.txt')
#unlink('C:\\Users\\druiz\\Dropbox\\RAD\\rad.txt')

sink(file='~/HUD_MatchBalance_Output.txt')

#mgen3 <- Match(Tr=Model3$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=gen3)
#summary(mgen3)
mbgen3 <- MatchBalance(radDS$RAD ~ m_age +  m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mgen3, nboots=1000)


#mlob3 <-Match(Tr=Model3$RAD, X=x, M=4, replace=TRUE, ties=TRUE, Weight=2)
#summary(mlob3)
mblob3 <- MatchBalance(radDS$RAD ~ m_age +  m_members + p_ACC + p_Black + p_Disabled + p_Elder + p_Single + bldg_age+ PASS_Score + p_Elder_dev + m_BRs + vacancy_rt+ pers_per_BR + Median_household_income + Poverty_rate+ Overcrowd_rate_1_5+ Vacant_Rate+ Percent_renters_GRAPI_35__or_mor + Percent_Black + Percent_HISPANIC+ radDS$ACC_UNIT_CNT+ radDS$PHA_size_code+ radDS$PASS_Score+ radDS$Vacant_Rate+ radDS$vacancy_rt+ radDS$Percent_renters_GRAPI_35__or_mor+ radDS$Overcrowd_rate_1_5+ radDS$Poverty_rate, data=radDS, match.out=mlob3, nboots=1000)




# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 

dd = as.numeric(mgen3$index.control)
dim(dd) <- c(4,220) #4 controls for each of the 220 matched RADs
dd <- t(dd)  #transpose the matrix 

dt = as.numeric(mgen3$index.treat)
dim(dt) <- c(4,220) 
dt <- t(dt)

ds = cbind(dt[,1],dd)
df = matrix("",nrow=220,ncol=5)

df[,1] <- as.character(radDS$Project_ID[ds[,1]])
df[,2] <- as.character(radDS$Project_ID[ds[,2]])
df[,3] <- as.character(radDS$Project_ID[ds[,3]])
df[,4] <- as.character(radDS$Project_ID[ds[,4]])
df[,5] <- as.character(radDS$Project_ID[ds[,5]])

write.matrix(df,'~CH_RAD-match_rad_gen_Model3.csv', sep=",")
#print("GenMatch")
#df


#a <-data.frame(matrix("",nrow=220,ncol=1))

#----------------------------------------------------------------------------------------

# Get get a simple matrix showing the RAD property IDs and their 4 matched counterparts. 

dd2 = as.numeric(mlob3$index.control)
dim(dd2) <- c(4,220) #4 controls for each of the 220 matched RADs
dd2 <- t(dd2)  #transpose the matrix 

dt2 = as.numeric(mlob3$index.treat)
dim(dt2) <- c(4,220) 
dt2 <- t(dt2)

ds2 = cbind(dt2[,1],dd2)
df2 = matrix("",nrow=220,ncol=5)

df2[,1] <- as.character(radDS$Project_ID[ds2[,1]])
df2[,2] <- as.character(radDS$Project_ID[ds2[,2]])
df2[,3] <- as.character(radDS$Project_ID[ds2[,3]])
df2[,4] <- as.character(radDS$Project_ID[ds2[,4]])
df2[,5] <- as.character(radDS$Project_ID[ds2[,5]])

write.matrix(df,'~CH_RAD-match_rad_gen_Model3_mlob.csv', sep=",")
#print("Mahalonobis")
#df2
#a <-data.frame(matrix("",nrow=220,ncol=1))

sink()