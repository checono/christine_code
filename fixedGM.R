#install.packages("sas7bdat")
#install.packages("Matching", dependencies=TRUE)
#install.packages("dplyr")

#initiate sas7bdat library for reading in foreign file
library("sas7bdat")
library("Matching")
library("dplyr")

#read in SAS DS with the read.sas7bsdat() function
  radDS = read.sas7bdat('K:/RAD_Evaluation_2014-2017/Task15/Data/rad_match_data1.sas7bdat')
  dim(radDS)

#cross tab; control (i.e., non-RAD) versus RAD
  xtabs(~ RAD, data=radDS)  #232 RADS


#--------------Model Set A (no logit p-values) ---------------------------------------------------------------------------------------------------------------------#

#A ==NO logit p-values are included 
  print("Model set A: No pscore values are included; variables included = those from David's original code")
  ModelA <- radDS     %>%
            select(Project_ID, RAD, ACC_UNIT_CNT, PHA_size_code, PASS_Score, Vacant_Rate, vacancy_rt, Percent_renters_GRAPI_35__or_mor,  Overcrowd_rate_1_5, Poverty_rate)  %>%
            na.omit()     %>%
            mutate_each(funs(as.numeric))

  dim(ModelA) 

#check to see how many RAD and Non-RAD remain based on the above variable selection
  xtabs(~ RAD, data=ModelA)    #221 RADs

#separate matrix by treatment and all other variables 
  x <- ModelA %>% select(-RAD, -Project_ID) %>% as.matrix()

#check dimensions
  dim(x) 

#establish balanceMatrix for the actual model
  BalanceMat <- as.matrix(x)


#sink file so that output can later be retrieved 
  sink(file='~/ModelA_DR.txt', split=TRUE) 

#setup GenMatch
  genA <- GenMatch(Tr = ModelA$RAD, X = x, BalanceMatrix = BalanceMat, M=4, pop.size=7000, ties=TRUE, replace=TRUE)

  mgenA <-   Match(Tr = ModelA$RAD, X = x, M=4, replace=TRUE, ties=TRUE, Weight=3, Weight.matrix=genA)

  summary(mgenA)

#assess match
  mbgenA <- MatchBalance(ModelA$RAD ~ ModelA$ACC_UNIT_CNT+ ModelA$PHA_size_code+ ModelA$PASS_Score+ ModelA$Vacant_Rate+ ModelA$vacancy_rt+ ModelA$Percent_renters_GRAPI_35__or_mor + ModelA$Overcrowd_rate_1_5 + ModelA$Poverty_rate, data=ModelA, match.out=mgenA, nboots=1000)

  summary(mbgenA)

sink()

